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
    lngx = { header={}, say=print }
else
    lngx = { header=ngx.header, say=ngx.say }
end
local templateloaded, template = pcall(require, "resty_template")

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
            return self.results[self.dates[i]]
        end
    end
end

-- random json response
function mryw:random_json_response()
    lngx.header['Content-Type'] = 'application/json; charset=utf-8'
    local data = { data=self:get_random_result() }
    lngx.say(json.encode(data))
end

-- random html response
mryw.HTML_template = [[
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta http-equiv="content-type" content="text/html; charset=UTF-8">
<meta name="referrer" content="no-referrer" />
<style type="text/css">
body{background-image:url(https://wx2.sinaimg.cn/mw2000/785894d3ly1gzt7zjs6q5j20u014ngvw.jpg);background-size:100%;}#article_show{background-color:rgba(255,255,255,0.98);border-radius:50px;margin:50px auto;min-height:300px;padding:60px 50px;position:relative;width:62%;max-width:700px;z-index:0}#article_show h1{color:#000;font-weight:normal;letter-spacing:4px;position:relative;text-align:center;text-transform:uppercase}#article_show p{color:#000;font-size:16px;font-weight:normal;line-height:36px;margin-bottom:30px;text-align:justify}#article_author{color:#999!important;text-align:center!important}
</style>
<title>{*title*} {*author*} | 每日一文</title>
</head>
<body>   
<div id="article_show">
    <h1>{*title*}</h1>
    <p id="article_author"><span>{*author*}</span></p>
    <div class="article_text">
    {*content*}
    </div>
</div>
</body>
</html>
]]

function mryw:random_html_response()
    lngx.header['Content-Type'] = 'text/html; charset=utf-8'
    local data = self:get_random_result()
    if templateloaded then
        template.render(self.HTML_template, data)
    else
        local html = string.gsub(self.HTML_template, "{%*title%*}", data.title)
        html = string.gsub(html, "{%*author%*}", data.author)
        html = string.gsub(html, "{%*content%*}", data.content)
        lngx.say(html)
    end
end

return mryw
