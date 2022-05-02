--  Copyright (c) 2022 shmilee

local table = { insert=table.insert, sort=table.sort }
local math = { randomseed=math.randomseed, random=math.random }
local os = { time=os.time }
local io = { open=io.open }
local tostring = tostring
local string = { gsub=string.gsub }
local jsonloaded, json = pcall(require, "cjson")
if not jsonloaded then
    json = require("dkjson")
end
local lngx
if ngx == nil then
    lngx = { exec=print }
else
    lngx = { exec=ngx.exec }
end

local mryw = { path=nil, N=0, dates=nil }

-- set valid dates, path: absolute path of dates.json
function mryw:set_dates_info(path)
    local f = io.open(path, "r")
    if f then
        --print('Reading', path)
        local data = f:read("*all")
        f:close()
        data = json.decode(data)
        self.path = path
        self.N = #data
        self.dates = data
    end
end

-- update valid dates table if needed
function mryw:update_dates_info(path)
    if self.path ~= path or self.dates == nil then
        self:set_dates_info(path)
    end
end

-- get random date
function mryw:get_random_day()
    math.randomseed(tostring(os.time()):reverse())
    if self.N > 0 then
        return self.dates[math.random(1, self.N)]
    end
    return nil
end

-- random json response, json file in location loc
function mryw:random_json_response(loc)
    local day = self:get_random_day()
    if day then
        local path = loc .. '/' .. day .. '.json'
        lngx.exec(path)
    end
end

return mryw
