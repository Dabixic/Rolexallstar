--[[
    Rolex.gg Whitelist System
    Auto HWID + WindUI Key Input
    ใส่ Key ครั้งเดียว → HWID ลงทะเบียนอัตโนมัติ → ครั้งต่อไปเข้าเลย
]]

-- ═══════════════════════════════════════════════════
--  CONFIG
-- ═══════════════════════════════════════════════════
local API_URL = "http://localhost:8080"
local API_KEY = "Rolex"
local SCRIPT_NAME = "Deepwoken"

-- ═══════════════════════════════════════════════════
--  SERVICES
-- ═══════════════════════════════════════════════════
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-- ═══════════════════════════════════════════════════
--  GET HWID
-- ═══════════════════════════════════════════════════
local function getHWID()
    local ok, hwid

    ok, hwid = pcall(function() return game:GetService("RbxAnalyticsService"):GetClientId() end)
    if ok and hwid and #hwid > 5 then return hwid end

    ok, hwid = pcall(function() return gethwid() end)
    if ok and hwid and #hwid > 5 then return hwid end

    ok, hwid = pcall(function() return getexecutorname() .. "_" .. Players.LocalPlayer.UserId end)
    if ok and hwid then return hwid end

    return "ROBLOX_" .. tostring(Players.LocalPlayer.UserId)
end

-- ═══════════════════════════════════════════════════
--  SAVED KEY
-- ═══════════════════════════════════════════════════
local SAVE_FILE = SCRIPT_NAME .. "_key.txt"

local function loadSavedKey()
    local ok, data = pcall(function()
        if isfile and isfile(SAVE_FILE) then
            return readfile(SAVE_FILE)
        end
        return nil
    end)
    if ok and data and #data > 3 then
        return data:gsub("%s+", "")
    end
    return nil
end

local function saveKey(key)
    pcall(function()
        if writefile then
            writefile(SAVE_FILE, key)
        end
    end)
end

-- ═══════════════════════════════════════════════════
--  API CALL
-- ═══════════════════════════════════════════════════
local function apiAuth(hwid, key)
    local body = { hwid = hwid }
    if key then body.key = key end

    local ok, response = pcall(function()
        return request({
            Url = API_URL .. "/api/auth",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["X-API-Key"] = API_KEY
            },
            Body = HttpService:JSONEncode(body)
        })
    end)

    if not ok then
        return { whitelisted = false, error = "Cannot connect to server" }
    end

    local success, data = pcall(function()
        return HttpService:JSONDecode(response.Body)
    end)

    if not success then
        return { whitelisted = false, error = "Invalid response" }
    end

    return data
end

-- ═══════════════════════════════════════════════════
--  NOTIFICATION
-- ═══════════════════════════════════════════════════
local function notify(title, text, duration)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 5
        })
    end)
end

-- ═══════════════════════════════════════════════════
--  MAIN WHITELIST CHECK
-- ═══════════════════════════════════════════════════
local function main()
    local hwid = getHWID()
    print("[Whitelist] HWID: " .. hwid:sub(1, 16) .. "...")

    -- Step 1: ลองเช็ค HWID (ครั้งต่อไป ไม่ต้องใส่ Key)
    notify("⏳ " .. SCRIPT_NAME, "กำลังตรวจสอบ Whitelist...", 3)
    local result = apiAuth(hwid, nil)

    if result.whitelisted then
        notify("✅ " .. SCRIPT_NAME, "Whitelist Active!\nหมดอายุ: " .. (result.expiry_date or "N/A"), 5)
        print("[Whitelist] ✅ Active! Expiry: " .. (result.expiry_date or "N/A"))
        return true
    end

    -- Step 2: ลองใช้ Key ที่เคยบันทึกไว้
    local savedKey = loadSavedKey()
    if savedKey then
        print("[Whitelist] Found saved key, trying...")
        result = apiAuth(hwid, savedKey)
        if result.whitelisted then
            notify("✅ " .. SCRIPT_NAME, "Whitelist Active!\nหมดอายุ: " .. (result.expiry_date or "N/A"), 5)
            print("[Whitelist] ✅ Active via saved key!")
            return true
        end
    end

    -- Step 3: ไม่มี Key → เปิด WindUI ถาม Key
    print("[Whitelist] No valid key, loading key input UI...")
    
    local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dabixic/windmodv4/refs/heads/main/lua"))()
    wait(1)

    local KeyWindow = WindUI:CreateWindow({
        Title = "Rolex.gg — Key System",
        Icon = "key-round",
        Author = "Rolex.gg",
        Folder = "RolexKey",
        Size = UDim2.fromOffset(420, 280),
        Transparent = true,
        Theme = "Midnight",
        SideBarWidth = 0,
        HasOutline = true,
    })

    KeyWindow:EditOpenButton({
        Title = "Key System",
        Icon = "key-round",
        CornerRadius = UDim.new(0, 16),
        StrokeThickness = 2,
        Color = ColorSequence.new(
            Color3.fromHex("FF0F7B"),
            Color3.fromHex("F89B29")
        ),
        Draggable = true,
    })

    local KeyTab = KeyWindow:Tab({ Title = "🔑 Key System", Icon = "shield-check", ShowTabTitle = true })
    KeyWindow:SelectTab(1)

    KeyTab:Paragraph({
        Title = "Rolex.gg Whitelist",
        Desc = "กรุณาใส่ Key ที่ได้รับจาก Discord เพื่อเปิดใช้งานสคริปต์\nHWID ของคุณจะถูกผูกอัตโนมัติ",
        Image = "shield-check",
        ImageSize = 26,
    })

    local enteredKey = ""
    local authDone = false
    local authResult = false

    KeyTab:Input({
        Title = "License Key",
        PlaceholderText = "Rolex-XXXXXXXXXXXXXXXX",
        Callback = function(text)
            enteredKey = text
        end
    })

    KeyTab:Button({
        Title = "✅ ยืนยัน & เปิดใช้งาน",
        Callback = function()
            if #enteredKey < 5 then
                WindUI:Notify({
                    Title = "❌ Error",
                    Content = "กรุณาใส่ Key ที่ถูกต้อง",
                    Duration = 3,
                })
                return
            end

            WindUI:Notify({
                Title = "⏳ กำลังตรวจสอบ...",
                Content = "รอสักครู่...",
                Duration = 3,
            })

            local res = apiAuth(hwid, enteredKey)
            if res.whitelisted then
                saveKey(enteredKey)
                WindUI:Notify({
                    Title = "✅ สำเร็จ!",
                    Content = "เปิดใช้งานแล้ว!\nHWID: " .. hwid:sub(1,10) .. "...\nKey: " .. enteredKey .. "\nเวลา: " .. (res.days or "?") .. " วัน",
                    Duration = 8,
                })
                print("[Whitelist] ✅ Key redeemed! HWID auto-registered!")
                authResult = true
                authDone = true
                
                -- ปิดหน้าต่าง Key
                task.delay(1.5, function()
                    KeyWindow:Destroy()
                end)
            else
                WindUI:Notify({
                    Title = "❌ Key ไม่ถูกต้อง",
                    Content = res.error or "Key ไม่ถูกต้องหรือหมดอายุ",
                    Duration = 5,
                })
                print("[Whitelist] ❌ " .. (res.error or "Failed"))
            end
        end
    })

    KeyTab:Button({
        Title = "📋 วิธีรับ Key",
        Callback = function()
            WindUI:Notify({
                Title = "📋 วิธีรับ Key",
                Content = "1. เข้า Discord Server\n2. ใช้คำสั่ง /buy เพื่อซื้อ\n3. ชำระเงิน → ได้รับ Key\n4. นำ Key มาใส่ที่นี่",
                Duration = 10,
            })
        end
    })

    -- รอจนกว่า user จะกดยืนยันสำเร็จ
    while not authDone do
        task.wait(0.2)
    end

    return authResult
end

-- ═══════════════════════════════════════════════════
--  RUN
-- ═══════════════════════════════════════════════════
if not main() then
    print("[Whitelist] ❌ Script stopped — not whitelisted")
    return
end

-- ═══════════════════════════════════════════════════
--  ✅ WHITELIST PASSED — โหลด Main Script
-- ═══════════════════════════════════════════════════
print("[Whitelist] ✅ Loading main script...")

-- โหลดสคริปต์หลักของคุณตรงนี้
loadstring(game:HttpGet("https://raw.githubusercontent.com/Dabixic/Rolexallstar/refs/heads/main/allstar.lua"))()
