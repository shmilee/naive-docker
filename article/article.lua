--  Copyright (c) 2023 shmilee

local math = { randomseed=math.randomseed, random=math.random }
local os = { time=os.time }
local lngx = ngx or { print=print }  --{ exec=ngx.exec, print=ngx.print }
local tostring, pairs = tostring, pairs
local jsonlines = require("jsonlines")

local article = { cache={}, mt={} }

-- set valid keys
-- self data=jsonlines(xx), keys=keys_without_backup(), N
function article:set_keys()
    if self.data then
        self.keys = self.data:keys_without_backup()
        self.N = #self.keys
    end
end

-- update keys table if needed
function article:update_keys()
    if self.keys == nil or self.data:update_index() then
        self:set_keys()
    end
end

-- Return the index of element in the table *tab*
function article.table_index(tab, el)
    for i, v in pairs(tab) do
        if v == el then
            return i
        end
    end
    return nil
end

-- get random key in *keys*, *N* shall satisfy 0<N<=#keys
function article.get_random_key(keys, N)
    math.randomseed(tostring(os.time()):reverse())
    if N > 0 then
        return keys[math.random(1, N)]
    end
    return nil
end

-- get json response, json raw string
-- ?key=xxx&nck
-- if no *args.key*, return random one
-- *args.nck*, do not check the input *args.key*, default false
function article:get_json_response(args)
    local key = args and args.key
    local nck = args and args.nck
    if self.keys then
        if key and not nck then
            --print('CHECK key: ', key)
            if not article.table_index(self.keys, key) then
                key = nil
            end
        end
        if not key then
            key = article.get_random_key(self.keys, self.N)
        end
        if key then
            local rc = self.data:get_raw_record(key)
            if rc:find('"__LINK__"', 1) then
                local dest_key = jsonlines.json_decode(rc)["__LINK__"]
                --print('Get link key:', key, '-->', dest_key)
                rc = self.data:get_raw_record(dest_key)
            end
            lngx.print(rc)
        end
    end
end

-- get html response, html template in *hpath*
-- ?key=xxx
-- if no *args.key*, return random one
function article:get_html_response(hpath, args)
    local key = args and args.key
    if self.keys then
        local f = io.open(hpath, "r")
        if f then
            --print('Reading ', hpath)
            local html = f:read("*all")
            f:close()
            if not (key and article.table_index(self.keys, key)) then
                key = article.get_random_key(self.keys, self.N)
            end
            if key and html then
                html = string.gsub(html, '{{{KEYKEY}}}', 'key=' .. key)
                lngx.print(html)
            end
        end
    end
end

-- path: absolute path of data.jsonl
function article.new(path)
    -- check cache
    local art = article.cache[path]
    if art then
        art:update_keys()
    else
        art = { data=jsonlines(path), N=0, keys=nil,
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
