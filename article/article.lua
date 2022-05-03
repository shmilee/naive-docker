--  Copyright (c) 2022 shmilee

local io = { open=io.open }
local math = { randomseed=math.randomseed, random=math.random }
local os = { time=os.time }
local tostring, pairs, setmetatable = tostring, pairs, setmetatable
local jsonloaded, json = pcall(require, "cjson")
if not jsonloaded then
    json = require("dkjson")
end
local lngx
if ngx == nil then
    lngx = { exec=print, print=print }
else
    lngx = { exec=ngx.exec, print=ngx.print }
end

-- get *path* file size
local function get_file_size(path)
    local file = io.open(path, "rb")
    if file then
        local size = file:seek("end")
        file:close()
        return size
    end
    return nil
end

-- read file
local function read_file(path)
    local f = io.open(path, "r")
    if f then
        print('Reading', path)
        local data = f:read("*all")
        f:close()
        return data
    end
    return nil
end

-- read and decode json in *path*
local function read_json(path)
    local data = read_file(path)
    if data then
        return json.decode(data)
    end
    return nil
end

local article = { cache={}, mt={} }

-- set valid keys
-- self data: path=path, size=nil, N=0, keys=nil
function article:set_keys()
    local data = read_json(self.path)
    if data then
        self.size = get_file_size(self.path)
        self.N = #data
        self.keys = data
    end
end

-- update keys table if needed
function article:update_keys()
    if self.keys == nil or get_file_size(self.path) ~= self.size then
        self:set_keys()
    end
end

-- Return the index of element in the table *tab*
local function table_index(tab, el)
    for i, v in pairs(tab) do
        if v == el then
            return i
        end
    end
    return nil
end

-- get random key in *keys*, *N* shall satisfy 0<N<=#keys
local function get_random_key(keys, N)
    math.randomseed(tostring(os.time()):reverse())
    if N > 0 then
        return keys[math.random(1, N)]
    end
    return nil
end

-- get json response, json file in location *loc*
-- if no *args.key*, return random one
function article:get_json_response(loc, args)
    local key = args and args.key
    if self.keys then
        if not (key and table_index(self.keys, key)) then
            key = get_random_key(self.keys, self.N)
        end
        if key then
            local jpath = loc .. '/' .. key .. '.json'
            lngx.exec(jpath)
        end
    end
end

-- get html response, html template in *hpath*
-- if no *args.key*, return random one
function article:get_html_response(hpath, args)
    local key = args and args.key
    if self.keys then
        if not (key and table_index(self.keys, key)) then
            key = get_random_key(self.keys, self.N)
        end
        local html = read_file(hpath)
        if key and html then
            html = string.gsub(html, '{{{KEYKEY}}}', 'key=' .. key)
            lngx.print(html)
        end
    end
end

-- path: absolute path of keys.json
function article.new(path)
    -- check cache
    local art = article.cache[path]
    if art then
        art:update_keys()
    else
        art = { path=path, size=nil, N=0, keys=nil,
                set_keys=article.set_keys, update_keys=article.update_keys,
                get_json_response=article.get_json_response,
                get_html_response=article.get_html_response }
        art:set_keys()
        article.cache[path] = art
    end
    return art
end

function article.mt:__call(...)
    return article.new(...)
end

return setmetatable(article, article.mt)
