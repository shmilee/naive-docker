---------------------------------------------------------------------------
--
--  Read jsonlines format file https://jsonlines.org
--
--  1. Each record can be any JSON types.
--  2. Input 'index key' can be string or int.
--     But all 'index key' in jsonl is treated as string.
--     Duplicate key is named as 'key-backup-0', 'key-backup-1', etc.
-- 
--      {1st record}
--      {2nd record}
--      ......
--      {last record}
--      {index key: (absolute position, line number), ..., __RecordCount__: N}
--
--  3. TODO write: http://peterodding.com/code/lua/apr/docs/#file:truncate
--
--  Copyright (c) 2023 shmilee
--  Licensed under GNU General Public License v2:
--  https://opensource.org/licenses/GPL-2.0
--
---------------------------------------------------------------------------

local io = { open=io.open }
local math = { min=math.min, max=math.max, floor=math.floor }
local table = { insert=table.insert }
local string = { gsub=string.gsub }
local type, pairs, tostring = type, pairs, tostring
local jsonloaded, json = pcall(require, "cjson")
if not jsonloaded then
    json = require("dkjson")
end

local jsonlines = { cache={}, mt={} }

function jsonlines:set_index()
    --print('Reading ', self.path)
    local f = io.open(self.path, "r")
    if f then
         -- ref: http://www.lua.org/manual/5.4/manual.html#pdf-io.open
        self.size = f:seek("end")
        local step = math.min(math.max(128, math.floor(self.size/1024)), 4096*8)
        local offset = f:seek("end", -step-1)
        local str = f:read(step)
        while (str ~= nil and str:find('\n') == nil  -- not found & pos>0
                and offset ~= nil and offset > 0) do
            offset = f:seek("cur", -step*2)
            str = f:read(step)
        end
        f:seek("set", offset or 0)
        -- get last line
        local data, pos, err
        for l in f:lines("*l") do
            data = l
        end
        f:close()
        --print( 'Get ' .. data:sub(0,2^6) .. ' .... ' .. data:sub(-2^6))
        data, pos, err = json.decode(data)  -- , 1, nil) for dkjson
        if not err and type(data) == "table" then
            self.index = data
            self.N = data["__RecordCount__"] or 0
        end
    end
end

local function get_file_size(path)
    local file = io.open(path, "rb")
    if file then
        local size = file:seek("end")
        file:close()
        return size
    end
    return nil
end

-- return true if need to update
function jsonlines:update_index()
    if self.size == nil or get_file_size(self.path) ~= self.size then
        self:set_index()
        return true
    end    
end

function jsonlines:keys()
    local keys = {}
    for  k, v in pairs(self.index) do
        if k ~= '__RecordCount__' then
            table.insert(keys, k)
        end
    end
    return keys
end

local function string_split(str, rep)
    local res = {}
    string.gsub(str, '[^'..rep..']+', function (s)
        table.insert(res, s)
    end)
    return res
end

function jsonlines:keys_without_backup()
    local keys = {}
    for  k, v in pairs(self.index) do
        if k ~= '__RecordCount__' then
            local karr = string_split(k, '-')
            if not (#karr >=3 and karr[#karr-1] == 'backup') then
                table.insert(keys, k)
            end
        end
    end
    return keys
end

function jsonlines:get_raw_record(key)
    local pos = self.index[tostring(key)]
    if pos then
        local f = io.open(self.path, "r")
        if f then
            f:seek("set", pos[1])
            return f:read("*l")
        end
    end
end

function jsonlines.json_decode(raw)
    if raw then
        local rc, pos, err = json.decode(raw)
        if not err then
            return rc
        end
    end
end

function jsonlines:get_record(key)
    local raw = self.get_raw_record(key)
    return jsonlines.json_decode(raw)
end

function jsonlines.new(path)
    local jl = jsonlines.cache[path]
    if jl then
        jl:update_index()
    else
        jl = { path=path, size=nil, index={}, N=0,
               set_index=jsonlines.set_index,
               update_index=jsonlines.update_index,
               keys=jsonlines.keys,
               keys_without_backup=jsonlines.keys_without_backup,
               get_raw_record=jsonlines.get_raw_record,
               get_record=jsonlines.get_record }
        jl:set_index()
        jsonlines.cache[path] = jl
    end
    return jl
end

function jsonlines.mt:__call(...)
    return jsonlines.new(...)
end

return setmetatable(jsonlines, jsonlines.mt)
