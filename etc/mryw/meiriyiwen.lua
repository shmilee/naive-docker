--  Copyright (c) 2022 shmilee

local table = { insert=table.insert, sort=table.sort }
local math = { randomseed=math.randomseed, random=math.random }
local os = { time=os.time }
local io = { open=io.open }
local tostring = tostring

local jsonloaded, json = pcall(require, "cjson")
if not jsonloaded then
    json = require("dkjson")
end
local lngx
if ngx == nil then
    lngx = { header={}, say=print }
else
    lngx = { header=ngx.header, say=ngx.say }
end

local mryw = { path=nil, N=0, dates=nil, results=nil}

-- set valid dates and results table
function mryw:set_data_results(path)
    local f = io.open(path, "r")
    if f then
        --print('Reading', path)
        local data = f:read("*all")
        f:close()
        data = json.decode(data)
        local keys, results, n404 = {}, {}, 0
        for k, v in pairs(data) do
            --print(k,v, type(v))
            if v ~= 40404 then
                table.insert(keys, k)
                results[k] = v
            else
                n404 = n404 + 1
            end
        end
        --print("n404=", n404)
        table.sort(keys, function(a,b) return a < b end)
        self.path = path
        self.N = #keys
        self.dates = keys
        self.results = results
    end
end

-- update valid dates and results table if needed
function mryw:update_data_results(path)
    if self.path ~= path or self.dates == nil then
        self:set_data_results(path)
    end
end

-- get random result
function mryw:get_random_result()
    math.randomseed(tostring(os.time()):reverse())
    if self.N > 0 then
        local i = math.random(1, self.N)
        if self.dates[i] then
            return json.encode(self.results[self.dates[i]])
        end
    end
end

-- random response
function mryw:random_response()
    lngx.header['Content-Type'] = 'application/json; charset=utf-8'
    lngx.say(self:get_random_result())
end

return mryw
