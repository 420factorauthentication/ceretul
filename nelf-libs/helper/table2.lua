--=============--
local table2 = {}
--=============--



--================================================--
-- indexPairs()                                   --
--   t: table                                     --
--                                                --
-- Loop iterator that points to a tables __index. --
--================================================--
table2.indexPairs = function(t)
    local newT = getmetatable(t).__index
    local iter = function(tbl, k)
        local v
        k, v = next(tbl, k)
        if (v ~= nil) then
            return k, v
        end
    end
    return iter, newT, nil
end



--=======================================================================================--
-- class supaTable                                                                       --
-- A supa hot table.                                                                     --
-- Copies a table passed to the constructor.                                             --
-- Creates a proxy table and sets its __index to that copied table.                      --
-- The proxy table is technically empty, to allow helper functions to run on __newindex. --
-- All actual values are stored in and gotten from the copied table.                     --
--=======================================================================================--
table2.supaTable = setmetatable({
    --=============--
    -- Constructor --
    --=============--
    new = function(self, o)
        -- If supplied a table, copy its properties over to the new table --
        -- If its already a supaTable, just return that table --
        o = o or {}
        if (type(o) ~= "table") then
            print("ERROR: supaTable invalid input")
        elseif (o._IsSupaTable == true) then
            return o
        end

        -- Create proxy table --
        local proxy = {
            _IsSupaTable = true,
            _ReadOnly = {},
            _MappedFuncs = {},
            _UnmappedFuncs = {},
        }

        -- Copy all supaTable methods except constructors to proxy table --
        for k, v in pairs(self) do
            if ((k ~= "new") and (k ~= "newClass")) then
                proxy[k] = v
            end
        end

        -- Copy supaTable class metatable to proxy table --
        local proxyMt = {}
        if (getmetatable(self) ~= nil) then 
            for k, v in pairs(getmetatable(self)) do
                proxyMt[k] = v
            end
        end

        -- Copy original table if constructor was passed one --
        local tblCopy = {}
        for k, v in pairs(o) do
            tblCopy[k] = v
        end

        -- Copy metatable of original table --
        local mtCopy = {}
        if (getmetatable(o) ~= nil) then 
            for k, v in pairs(getmetatable(o)) do
                mtCopy[k] = v
            end
        end
        setmetatable(tblCopy, mtCopy)

        -- Set up read-only and watch functionality with __newindex --
        proxyMt.__newindex = function(t,k,v)
            if (t._ReadOnly[k] ~= true) then
                mt = getmetatable(t)

                -- Helper func: Runs watchProp() on subtables if checkSubTables --
                local function regFuncs(tbl, funcTbl)
                    for key, val in pairs(funcTbl) do
                        if (val.checkSubTables == true) then
                            tbl[key] = table2.supaTable:new(tbl[key])
                            tbl[key]:watchProp(val.func, nil, true)
                        end
                    end
                end

                -- Helper func: Runs functions from watchProp() --
                local function runFuncs(funcTbl, tab, key, val)
                    for x, d in pairs(funcTbl) do
                        d.func(tab, key, val)
                    end
                end

                -- Set the property in the hidden copied table, instead of the proxy table --
                mt.__index[k] = v

                -- Updates subtables with watched functions for individual properties --
                -- Runs watched functions for individual properties --
                for prop, funcs in pairs(t._MappedFuncs) do
                    if (prop == k) then
                        if (type(v) == "table") then
                            regFuncs(mt.__index[k], funcs)
                        end
                        runFuncs(funcs, t, k, v)
                        break
                    end
                end
                
                -- Updates subtables with watched functions for all properties globally --
                -- Runs watched functions for all properties globally --
                if (type(v) == "table") then
                    regFuncs(mt.__index[k], t._UnmappedFuncs)
                end
                runFuncs(t._UnmappedFuncs, t, k, v)

            else
                print("WARNING: Tried to edit read-only value: " .. k)
            end
        end

        -- Link proxy table to actual table with __index --
        proxyMt.__index = tblCopy
        setmetatable(proxy, proxyMt)
        return proxy
    end,

    --===============================================================================================================--
    -- supaTable:watchProp()                                                                                         --
    --   func: function                                                                                              --
    --   prop: any                                                                                                   --
    --   checkSubTables: boolean = true                                                                              --
    --                                                                                                               --
    -- Watches a property in this table. Whenever it's changed at all, calls the specified function.                 --
    -- Passes (t, k, v) to the called function.                                                                      --
    -- If prop == nil, that function is called whenever anything in this table is changed.                           --
    -- All registered functions are kept in a table. Multiple functions are allowed.                                 --
    -- If checkSubTables is true, recursively converts all subtables to supaTables and watches all their properties. --
    --===============================================================================================================--
    watchProp = function(self, func, prop, checkSubTables)
        if (checkSubTables == nil) then checkSubTables = true end
        local tbl = getmetatable(self).__index  --Used to set read-only props

        if (checkSubTables == true) then
            if (prop ~= nil) then                      --If a child prop is specified and is a table,
                if (type(self[prop]) == "table") then  --watch all grandchildren props of that table
                    tbl[prop] = table2.supaTable:new(self[prop])
                    for key, val in pairs(getmetatable(self[prop]).__index) do  --for loop on the actual table of child prop,
                        self[prop]:watchProp(func, key, true)                   --not the supaTable proxy
                    end
                end
            else  -- If a child property isnt specified, check all children
                for k, v in pairs(tbl) do  --for loop on the actual table, not the supaTable proxy
                    if (type(v) == "table") then
                        tbl[k] = table2.supaTable:new(v)
                        for key, val in pairs(getmetatable(tbl[k]).__index) do  --for loop on the actual table of child prop,
                            self[k]:watchProp(func, key, true)                  --not the supaTable proxy
                        end
                    end
                end
            end
        end
        
        if (prop ~= nil) then  --If a property is specified, add a key-{function,flags} pair to _MappedFuncs
            if (self._MappedFuncs[prop] == nil) then  --Init empty table if doesnt exist
                self._MappedFuncs[prop] = {}
            end
            table.insert(self._MappedFuncs[prop], {func = func, checkSubTables = checkSubTables})
        else  --If a property isnt specified, append {function,flags} to _UnmappedFuncs
            table.insert(self._UnmappedFuncs, {func = func, checkSubTables = checkSubTables})
        end
    end,

    --=====================================================================--
    -- supaTable:unwatchProp()                                             --
    --   func: function                                                    --
    --   prop: any                                                         --
    --   checkSubTables: boolean = true                                    --
    --                                                                     --
    -- Removes a function from a propertys watchlist.                      --
    -- If func == nil, removes all functions from that list.               --
    -- If prop == nil, removes functions from the tables global watchlist. --
    -- If checkSubTables == true, checks function lists of all subtables.  --
    --=====================================================================--
    unwatchProp = function(self, func, prop, checkSubTables)
        if (checkSubTables == nil) then checkSubTables = true end

        if (checkSubTables == true) then  --If a child prop is specified and is a supaTable,
            if (prop ~= nil) then         --unwatch func from all grandchildren of that child
                if (type(self[prop]) == "table") and (self[prop]._IsSupaTable == true) then
                    self[prop]:unwatchProp(func, nil, true)
                end
            else --If a child isnt specified, unwatch func from all grandchildren of every child
                for k, v in pairs(getmetatable(self).__index) do  --for loop on the actual table, not the supaTable proxy
                    if (type(v) == "table") and (v._IsSupaTable == true) then
                        v:unwatchProp(func, nil, true)
                    end
                end
            end
        end

        -- If the table isnt a supaTable, then its already not watching any properties --
        if (self._IsSupaTable ~= true) then
            return
        end

        -- Helper func:
        -- If a function is specified, remove function from _MappedFuncs or _UnmappedFuncs
        -- If a function isnt specified, remove all functions from _MappedFuncs or _UnmappedFuncs
        local function clearFunc(funcTbl, func0)
            if (func0 == nil) then
                for k, v in pairs(funcTbl) do
                    funcTbl[k] = nil
                end
            else
                for k, v in pairs(funcTbl) do
                    if (v.func == func0) then
                        funcTbl[k] = nil
                        break
                    end
                end
            end
        end

        -- Unwatch the funcs --
        if (prop ~= nil) then
            if (self._MappedFuncs[prop] ~= nil) then
                clearFunc(self._MappedFuncs[prop], func)
            end
        else
            clearFunc(self._UnmappedFuncs, func)
        end
    end,

    --=================================================================--
    -- supaTable:setReadOnly()                                         --
    --   readOnly: boolean                                             --
    --   prop: any                                                     --
    --   checkSubTables: boolean = true                                --
    --   watch: boolean = true                                         --
    --                                                                 --
    -- Sets a property in this table to read-only or not read-only.    --
    -- If prop == nil, sets all current properties in this table.      --
    -- If checkSubTables == true, sets subtables immediately.          --
    -- If watch == true, sets subtables whenever the property changes. --
    --=================================================================--
    setReadOnly = function(self, readOnly, prop, checkSubTables, watch)
        if (checkSubTables == nil) then checkSubTables = true end
        if (watch == nil) then watch = true end
        local tbl = getmetatable(self).__index  --Used to set read-only props
        
        if (readOnly == true) then
            -- If a child property is specified, set it to read-only --
            -- If enabled, convert child to a supaTable and set all grandchildren props of that child to read-only --
            if (prop ~= nil) then
                self._ReadOnly[prop] = true
                if (type(self[prop]) == "table") and (checkSubTables == true) then
                    tbl[prop] = table2.supaTable:new(self[prop])
                    self[prop]:setReadOnly(true, nil, true, watch)
                end
            -- If a property isnt specified, set all child properties to read-only --
            -- If enabled, convert all children to supaTables and set all grandchildren to read-only --
            else
                for k, v in pairs(tbl) do  --for loop on the actual table, not the supaTable proxy
                    self._ReadOnly[k] = true
                    if (type(v) == "table") and (checkSubTables == true) then
                        tbl[k] = table2.supaTable:new(v)
                        tbl[k]:setReadOnly(true, nil, true, watch)
                    end
                end
            end
        else
            -- If a child property is specified, set it to not read-only --
            -- If enabled, check grandchildren of that child too: --
            --   If a grandchild isnt a supaTable, then its already not read-only --
            --   If a grandchild is a supaTable, then set it to not read-only --
            if (prop ~= nil) then
                self._ReadOnly[prop] = nil
                if (type(self[prop]) == "table") and (checkSubTables == true) and (self[prop]._IsSupaTable == true) then
                    self[prop]:setReadOnly(false, nil, true, watch)
                end
            -- If a child isnt specified, set all children to not read-only --
            -- If enabled, check grandchildren of all children too: --
            --   If a grandchild isnt a supaTable, then its already not read-only --
            --   If a grandchild is a supaTable, then set it to not read-only --
            else
                for k, v in pairs(tbl) do  --for loop on the actual table, not the supaTable proxy
                    self._ReadOnly[k] = nil
                    if (type(v) == "table") and (checkSubTables == true) and (v._IsSupaTable == true) then
                        self[k]:setReadOnly(false, nil, true, watch)
                    end
                end
            end
        end

        -- Helper functions used to watch properties with Lua metatables --
        local function coldTake(t, k, v)
            t:setReadOnly(true, k, true, true)
        end

        local function hotTake(t, k, v)
            t:setReadOnly(false, k, true, true)
        end
 
        -- If enabled, update read-only status of subtables whenever a property changes to a table --
        if (watch == true) then
            if (readOnly == true) then
                self:watchProp(coldTake, prop, true)
            else
                self:watchProp(hotTake, prop, true)
            end
        else
            if (readOnly == true) then
                self:unwatchProp(coldTake, prop, true)
            else
                self:unwatchProp(hotTake, prop, true)
            end
        end
    end
    },{
    
    --===========--
    -- Metatable --
    --===========--
    -- Make pairs() point to __index, since it contains the actual values --
    __pairs = function(t)
        local infiniteLoopCounter = 0
        local newT = t

        while (newT._IsSupaTable == true) do
            newT = getmetatable(newT).__index
            infiniteLoopCounter = infiniteLoopCounter + 1
            if (infiniteLoopCounter >= 42069) then
                print("ERROR: supaTable pairs() infinite loop")
            end
        end
    
        local iter = function(tbl, k)
            local v
            k, v = next(tbl, k)
            if (v ~= nil) then
                return k, v
            end
        end
        
        return iter, newT, nil
    end,

    -- Make ipairs() point to __index, since it contains the actual values --
    __ipairs = function(t)
        local infiniteLoopCounter = 0
        local newT = t

        while (newT._IsSupaTable == true) do
            newT = getmetatable(newT).__index
            infiniteLoopCounter = infiniteLoopCounter + 1
            if (infiniteLoopCounter >= 42069) then
                print("ERROR: supaTable ipairs() infinite loop")
            end
        end
    
        local iter = function(tbl, i)
            i = i + 1
            local v = tbl[i]
            if (v ~= nil) then
                return i, v
            end
        end
        
        return iter, newT, 0
    end
})



--=========--
return table2
--=========--
