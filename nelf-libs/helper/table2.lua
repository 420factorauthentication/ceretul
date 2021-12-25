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
            error("SupaTable: invalid input")
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
                error("Tried to edit read-only value: " .. k)
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
        checkSubTables = checkSubTables or true
        local tbl = getmetatable(self).__index

        -- If enabled, convert subtables to supaTables and watch their properties too --
        if (checkSubTables == true) then
            -- If a property is specified, only check that property for subtables --
            if (prop ~= nil) then
                if (type(tbl[prop]) == "table") then
                    tbl[prop] = table2.supaTable:new(tbl[prop])
                    tbl[prop]:watchProp(func, tbl[prop], true)
                end
            -- If a property isnt specified, check all properties for subtables --
            else
                for k, v in pairs(tbl) do
                    if (type(v) == "table") then
                        tbl[k] = table2.supaTable:new(tbl[k])
                        tbl[k]:watchProp(func, v, true)
                    end
                end
            end
        end
        
        -- If a property is specified, add a key-{function,flags} pair to _MappedFuncs --
        if (prop ~= nil) then
            -- Since the _MappedFuncs table is full of subtables, make sure that subtable exists --
            if (self._MappedFuncs[prop] == nil) then
                self._MappedFuncs[prop] = {}
            end
            table.insert(self._MappedFuncs[prop], {func = func, checkSubTables = checkSubTables})
        -- If a property isnt specified, append {function,flags} to _UnmappedFuncs --
        else 
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
        checkSubTables = checkSubTables or true
        local tbl = getmetatable(self).__index

        -- If enabled, convert subtables to supaTables and unwatch their properties too --
        if (checkSubTables == true) then
            -- If a property is specified, only check that property for subtables --
            if (prop ~= nil) then
                if (type(tbl[prop] == "table")) then
                    table2.supaTable.unwatchProp(tbl[prop], func, nil, true)
                end
            -- If a property isnt specified, check all properties for subtables --
            else
                for k, v in pairs(tbl) do
                    if (type(v) == "table") then
                        table2.supaTable.unwatchProp(v, func, nil, true)
                    end
                end
            end
        end

        -- If the table isnt a supaTable, then its already not watching any properties --
        if (self._IsSupaTable ~= true) then
            return
        end

        -- If a function is specified, remove function from _MappedFuncs or _UnmappedFuncs --
        -- If a function isnt specified, remove all functions from _MappedFuncs or _UnmappedFuncs --
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

        -- If a property is specified, unregister functions for only that property --
        if (prop ~= nil) then
            if (self._MappedFuncs[prop] ~= nil) then
                clearFunc(self._MappedFuncs[prop], func)
            end
        -- If a property isnt specified, unregister functions for all properties --
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
        checkSubTables = checkSubTables or true
        watch = watch or true
        local tbl = getmetatable(self).__index
        
        -- If flagged, set properties to read-only --
        if (readOnly == true) then
            -- If a property is specified, set it to read-only --
            -- If enabled, convert subtables to supaTables and set their props to read-only --
            if (prop ~= nil) then
                self._ReadOnly[prop] = true
                if (type(tbl[prop]) == "table") and (checkSubTables == true) then
                    tbl[prop] = table2.supaTable:new(tbl[prop])
                    tbl[prop]:setReadOnly(true, nil, true, watch)
                end
            -- If a property isnt specified, set all properties to read-only --
            -- If enabled, convert subtables to supaTables and set their props to read-only --
            else
                for k, v in pairs(tbl) do
                    if (type(v) ~= "function") then
                        self._ReadOnly[k] = true
                        if (type(v) == "table") and (checkSubTables == true) then
                            tbl[k] = table2.supaTable:new(v)
                            tbl[k]:setReadOnly(true, nil, true, watch)
                        end
                    end
                end
            end
        -- If flagged, set properties to not read-only --
        else
            -- If a property is specified, set it to not read-only --
            -- If enabled, check subTables too: --
            --   If a subtable isnt a supaTable, then its already not read-only --
            --   If a subtable is a supaTable, then set it to not read-only --
            if (prop ~= nil) then
                self._ReadOnly[prop] = nil
                if (type(tbl[prop]) == "table") and (checkSubTables == true) and (tbl[prop]._IsSupaTable == true) then
                    tbl[prop]:setReadOnly(false, nil, true, watch)
                end
            -- If a property isnt specified, set all properties to not read-only --
            -- If enabled, check subTables too: --
            --   If a subtable isnt a supaTable, then its already not read-only --
            --   If a subtable is a supaTable, then set it to not read-only --
            else
                for k, v in pairs(tbl) do
                    self._ReadOnly[k] = nil
                    if (type(v) == "table") and (checkSubTables == true) and (v._IsSupaTable == true) then
                        tbl[k]:setReadOnly(false, nil, true, watch)
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
                error("supaTable pairs() infinite loop")
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
                error("supaTable ipairs() infinite loop")
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
