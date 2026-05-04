--[[
    PeleccosSoftwares v15.0  (BlockCore Edition)
    ─────────────────────────────────────────────────────────────
    • Strictly blocky 0px CornerRadius on every element
    • Rectangular slider thumb (no circles anywhere)
    • Full watermark: Name | Player | Game (ID) | FPS | Ping | Build | Config
    • Anonymizer / Streamer Mode toggle in Settings
    • Anti-AFK built-in toggle in Settings
    • Player List Tab — distance in Studs or Meters
    • Library:GetDistance(a, b) and utility helpers
    • Logo Image (Asset ID) support in CreateWindow
    • Auto-flag generation — Flag= is optional
    • Config system with "Open Folder" button
    • Group Boxes, Sub-tabs
    • Right-click context popup: Toggle / Hold / Always + Keybind
]]

-- ═══════════════════════════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════════════════════════
local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")
local HttpService  = game:GetService("HttpService")
local LP           = Players.LocalPlayer

-- ═══════════════════════════════════════════════════════════════
-- FOLDERS
-- ═══════════════════════════════════════════════════════════════
local _DIR = "PeleccosSoftwares"
pcall(function() if not isfolder(_DIR)             then makefolder(_DIR)             end end)
pcall(function() if not isfolder(_DIR.."/configs") then makefolder(_DIR.."/configs") end end)

-- ═══════════════════════════════════════════════════════════════
-- PRIMITIVE HELPERS
-- ═══════════════════════════════════════════════════════════════
local rgb  = Color3.fromRGB
local dim2 = UDim2.new
local dim  = UDim.new

local function tw(obj, props, t, style, dir)
    TweenService:Create(obj,
        TweenInfo.new(t or 0.14, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
        props):Play()
end

local function mk(cls, props)
    local o = Instance.new(cls)
    for k, v in pairs(props or {}) do if k ~= "Parent" then o[k] = v end end
    if props and props.Parent then o.Parent = props.Parent end
    return o
end


local function padding(p, t, r, b, l)
    local u = Instance.new("UIPadding")
    u.PaddingTop    = dim(0, t or 0)
    u.PaddingRight  = dim(0, r or 0)
    u.PaddingBottom = dim(0, b or 0)
    u.PaddingLeft   = dim(0, l or 0)
    u.Parent = p
end

local function layout(p, dir, gap, ha, va)
    local l = Instance.new("UIListLayout")
    l.FillDirection       = dir or Enum.FillDirection.Vertical
    l.Padding             = dim(0, gap or 0)
    l.HorizontalAlignment = ha  or Enum.HorizontalAlignment.Left
    l.VerticalAlignment   = va  or Enum.VerticalAlignment.Top
    l.SortOrder           = Enum.SortOrder.LayoutOrder
    l.Parent = p
    return l
end

local function autoCanvas(sf, ll)
    ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        task.defer(function()
            if sf and sf.Parent then
                sf.CanvasSize = dim2(0, 0, 0, ll.AbsoluteContentSize.Y + 8)
            end
        end)
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- THEME
-- ═══════════════════════════════════════════════════════════════
local C = {
    BgOuter  = rgb(14,  16,  18),
    BgSide   = rgb(10,  12,  14),
    BgSideBd = rgb(22,  25,  28),
    BgMain   = rgb(10,  12,  14),
    BgMainBd = rgb(22,  25,  28),
    BgGroup  = rgb(12,  14,  17),
    BgGroupH = rgb(26,  30,  35),
    BgRow    = rgb(20,  25,  30),
    BgHover  = rgb(18,  22,  27),
    BgActive = rgb(18,  22,  27),
    Tx0      = rgb(220, 220, 220),
    Tx1      = rgb(140, 140, 140),
    Tx2      = rgb(70,  80,  90),
    TxSub    = rgb(80,  100, 120),
    Toggle   = rgb(42,  52,  62),
    White    = rgb(255, 255, 255),
    nOk      = rgb(50,  200, 100),
    nWarn    = rgb(255, 185, 0),
    nErr     = rgb(255, 60,  60),
    nInfo    = rgb(0,   130, 255),
    Popup    = rgb(20,  24,  28),
    PopupBd  = rgb(36,  42,  48),
}

-- ═══════════════════════════════════════════════════════════════
-- FPS / PING
-- ═══════════════════════════════════════════════════════════════
local _fps, _ping = 60, 0
RunService.Heartbeat:Connect(function(dt)
    _fps = math.clamp(math.floor(1 / math.max(dt, 0.001)), 0, 999)
end)
task.spawn(function()
    while true do
        local ok1 = false
        pcall(function()
            local dp = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]
            if dp then _ping = math.floor(dp:GetValue()); ok1 = true end
        end)
        if not ok1 then
            pcall(function()
                local t0 = tick()
                RunService.Heartbeat:Wait()
                _ping = math.clamp(math.floor((tick() - t0) * 1000) - 16, 0, 999)
            end)
        end
        task.wait(1)
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════
local MOUSE_BUTTONS = {
    Enum.UserInputType.MouseButton1,
    Enum.UserInputType.MouseButton2,
    Enum.UserInputType.MouseButton3,
}
-- M4/M5 are not in vanilla Roblox but some executors expose them
pcall(function() table.insert(MOUSE_BUTTONS, Enum.UserInputType.MouseButton4) end)
pcall(function() table.insert(MOUSE_BUTTONS, Enum.UserInputType.MouseButton5) end)

local function isMouseButton(uit)
    for _, mb in ipairs(MOUSE_BUTTONS) do
        if uit == mb then return true end
    end
    return false
end

local _usedFlags = {}
local function autoFlag(name)
    if not name or name == "" then name = "unnamed" end
    local f = name:gsub("^%l", string.upper):gsub("%s+(%a)", string.upper):gsub("%s+", "")
    f = f:sub(1, 1):lower() .. f:sub(2)
    f = f:gsub("[^%w]", "")
    if f == "" then f = "flag" end
    local base, i = f, 0
    while _usedFlags[f] do i = i + 1; f = base .. i end
    _usedFlags[f] = true
    return f
end

-- ═══════════════════════════════════════════════════════════════
-- CONFIG SYSTEM
-- ═══════════════════════════════════════════════════════════════
local function makeConfigSystem(scriptName)
    local cfgDir = _DIR .. "/configs/" .. scriptName .. "/"
    pcall(function()
        if not isfolder(_DIR .. "/configs") then makefolder(_DIR .. "/configs") end
        if not isfolder(cfgDir) then makefolder(cfgDir) end
    end)
    local _flags = {}

    local function reg(flag, getFn, setFn, ftype)
        if flag then _flags[flag] = {get = getFn, set = setFn, ftype = ftype or "any"} end
    end
    local function listCfgs()
        local list = {}
        pcall(function()
            if typeof(listfiles) == "function" then
                for _, f in ipairs(listfiles(cfgDir)) do
                    local name = tostring(f):match("([^/\\]+)%.json$")
                    if name then table.insert(list, name) end
                end
            end
        end)
        return list
    end
    local function saveCfg(name)
        local data = {}
        for flag, info in pairs(_flags) do
            pcall(function()
                local v = info.get(); local ftype = info.ftype
                if     ftype == "bool"   then data[flag] = v and "true" or "false"
                elseif ftype == "number" then data[flag] = tostring(v)
                elseif ftype == "color"  then
                    data[flag] = math.floor(v.R*255)..","..math.floor(v.G*255)..","..math.floor(v.B*255)
                elseif ftype == "key"    then
                    data[flag] = tostring(v):gsub("Enum%.KeyCode%.",""):gsub("Enum%.UserInputType%.","")
                elseif ftype == "mode"   then data[flag] = tostring(v)
                else                          data[flag] = tostring(v) end
            end)
        end
        local json = ""; local ok = pcall(function() json = HttpService:JSONEncode(data) end)
        if not ok then return false end
        return pcall(function() writefile(cfgDir .. name .. ".json", json) end)
    end
    local function loadCfg(name)
        local ok, data = pcall(function()
            return HttpService:JSONDecode(readfile(cfgDir .. name .. ".json"))
        end)
        if not ok or type(data) ~= "table" then return false end
        for flag, val in pairs(data) do
            local info = _flags[flag]
            if info then pcall(function()
                local ftype = info.ftype
                if     ftype == "bool"   then info.set(val == "true")
                elseif ftype == "number" then info.set(tonumber(val) or 0)
                elseif ftype == "color"  then
                    local r, g, b = val:match("(%d+),(%d+),(%d+)")
                    if r then info.set(rgb(tonumber(r), tonumber(g), tonumber(b))) end
                elseif ftype == "key"    then
                    local s = pcall(function() info.set(Enum.KeyCode[val]) end)
                    if not s then pcall(function() info.set(Enum.UserInputType[val]) end) end
                elseif ftype == "mode"   then info.set(val)
                else info.set(val) end
            end) end
        end
        return true
    end
    local function delCfg(name)
        pcall(function() delfile(cfgDir .. name .. ".json") end)
    end
    local function openDir()
        pcall(function() if syn and syn.open_file_in_desktop then syn.open_file_in_desktop(cfgDir) end end)
        pcall(function()
            if KRNL_ENV and KRNL_ENV.open_file_in_desktop then
                KRNL_ENV.open_file_in_desktop(cfgDir)
            end
        end)
        pcall(function()
            if typeof(open_file_in_desktop) == "function" then
                open_file_in_desktop(cfgDir)
            end
        end)
    end
    return {
        register = reg, list = listCfgs, save = saveCfg,
        load = loadCfg, delete = delCfg, openDir = openDir, dir = cfgDir,
    }
end

-- ═══════════════════════════════════════════════════════════════
-- LIBRARY TABLE
-- ═══════════════════════════════════════════════════════════════
local Peleccos = {}
Peleccos.__index = Peleccos

function Peleccos:GetDistance(a, b)
    local function getPos(obj)
        if typeof(obj) == "Vector3" then return obj end
        if typeof(obj) == "CFrame"  then return obj.Position end
        if typeof(obj) == "Instance" then
            if obj:IsA("Model") then
                local root = obj:FindFirstChild("HumanoidRootPart")
                    or obj:FindFirstChildWhichIsA("BasePart")
                if root then return root.Position end
            elseif obj:IsA("BasePart") then
                return obj.Position
            end
        end
        return Vector3.new(0, 0, 0)
    end
    return (getPos(a) - getPos(b)).Magnitude
end

function Peleccos:StudsToMeters(studs)  return studs * 0.28 end
function Peleccos:MetersToStuds(meters) return meters / 0.28 end
function Peleccos:GetLocalPlayer()      return LP end

function Peleccos:CreateWindow(o)
    o = o or {}

    -- Cleanup previous instance
    pcall(function() game:GetService("CoreGui"):FindFirstChild("PeleccosV15"):Destroy() end)
    pcall(function()
        local pg = LP:FindFirstChild("PlayerGui")
        if pg then local x = pg:FindFirstChild("PeleccosV15"); if x then x:Destroy() end end
    end)

    local AC  = o.AccentColor or o.DefaultColor or rgb(81, 14, 119)
    local KEY = o.Key or Enum.KeyCode.Insert

    local MenuFont = Enum.Font.GothamBold
    if o.DefaultFont then
        MenuFont = Enum.Font[o.DefaultFont] or Enum.Font.GothamBold
    end
    local VisFont = Enum.Font.Code

    -- State
    local _anon          = false
    local ShowWatermark  = true
    local _activeCfgName = o.ConfigName or "Default"

    -- Accent callbacks
    local _acCBs = {}
    local function onAC(fn)      table.insert(_acCBs, fn) end
    local function fireAC(c)     for _, fn in ipairs(_acCBs) do pcall(fn, c) end end
    local function setAC(c)      AC = c; fireAC(c) end

    -- Font callbacks
    local _fontCBs = {}
    local function onFont(fn)    table.insert(_fontCBs, fn) end
    local function fireFont(mf, vf)
        for _, fn in ipairs(_fontCBs) do pcall(fn, mf, vf) end
    end

    local CFG = {
        ScriptName = o.Title     or "PeleccosSoftwares",
        BuildType  = o.BuildType or "Public",
        LogoImage  = o.LogoImage or "",
    }

    local CFGSYS = makeConfigSystem(CFG.ScriptName)

    -- ── ScreenGui
    local SG = mk("ScreenGui", {
        Name="PeleccosV15", ResetOnSpawn=false,
        ZIndexBehavior=Enum.ZIndexBehavior.Global,
        IgnoreGuiInset=true, DisplayOrder=999,
    })
    local ok = pcall(function() SG.Parent = game:GetService("CoreGui") end)
    if not ok then SG.Parent = LP:WaitForChild("PlayerGui") end

    -- ── Notification holder
    local NotifHolder = mk("Frame", {
        Size=dim2(0, 280, 1, -20), Position=dim2(1, -292, 0, 10),
        BackgroundTransparency=1, ClipsDescendants=false, Parent=SG,
    })
    layout(NotifHolder, Enum.FillDirection.Vertical, 4,
        Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Bottom)

    local function notify(opts)
        opts = opts or {}
        local typeKey = opts.Type or "Info"
        local ac2     = ({Success=C.nOk, Warning=C.nWarn, Error=C.nErr, Info=C.nInfo})[typeKey] or C.nInfo
        local typeTxt = ({Success="OK", Warning="!!", Error="ERR", Info="INF"})[typeKey] or "INF"

        local Card = mk("Frame", {
            Size=dim2(0,280,0,46), BackgroundColor3=C.BgSideBd,
            BorderSizePixel=0, ClipsDescendants=false, Parent=NotifHolder,
        })
        mk("UICorner",{CornerRadius=dim(0,4),Parent=Card})
        mk("Frame", {Size=dim2(0,3,1,0), BackgroundColor3=ac2, BorderSizePixel=0, Parent=Card})
        local BadgeFr = mk("Frame", {
            Size=dim2(0,22,0,14), Position=dim2(0,10,0,16),
            BackgroundColor3=ac2, BorderSizePixel=0, Parent=Card,
        })
        mk("TextLabel", {
            Size=dim2(1,0,1,0), BackgroundTransparency=1,
            Text=typeTxt, TextColor3=C.White, TextSize=7,
            Font=Enum.Font.GothamBold, Parent=BadgeFr,
        })
        mk("TextLabel", {
            Size=dim2(1,-46,0,15), Position=dim2(0,40,0,7),
            BackgroundTransparency=1, Text=opts.Title or "Notice",
            TextColor3=C.Tx0, TextSize=12, Font=Enum.Font.GothamBold,
            TextXAlignment=Enum.TextXAlignment.Left, Parent=Card,
        })
        if opts.Desc and opts.Desc ~= "" then
            mk("TextLabel", {
                Size=dim2(1,-46,0,13), Position=dim2(0,40,0,24),
                BackgroundTransparency=1, Text=opts.Desc,
                TextColor3=C.Tx1, TextSize=10, Font=Enum.Font.Gotham,
                TextXAlignment=Enum.TextXAlignment.Left,
                TextTruncate=Enum.TextTruncate.AtEnd, Parent=Card,
            })
        end
        Card.BackgroundTransparency = 1
        tw(Card, {BackgroundTransparency=0}, 0.16)
        task.delay(opts.Duration or 4, function()
            tw(Card, {BackgroundTransparency=1, Size=dim2(0,280,0,0)}, 0.18)
            task.wait(0.2)
            pcall(function() Card:Destroy() end)
        end)
    end

    -- ── Watermark
    local WatermarkFrame = mk("Frame", {
        Size=dim2(0, 8, 0, 20), Position=dim2(0, 8, 0, 8),
        BackgroundColor3=C.BgSideBd, BorderSizePixel=0,
        AutomaticSize=Enum.AutomaticSize.X,
        ZIndex=500,
        Visible=ShowWatermark, Parent=SG,
    })
    mk("UICorner",{CornerRadius=dim(0,3),Parent=WatermarkFrame})
    local WmBar = mk("Frame", {
        Name="AccentBar", Size=dim2(0,2,1,0),
        BackgroundColor3=AC, BorderSizePixel=0, ZIndex=500, Parent=WatermarkFrame,
    })
    onAC(function(c) WmBar.BackgroundColor3 = c end)
    local WmText = mk("TextLabel", {
        Size=dim2(1,-10,1,0), Position=dim2(0,8,0,0),
        BackgroundTransparency=1, Text="",
        TextColor3=C.Tx1, TextSize=10, Font=Enum.Font.Code,
        TextXAlignment=Enum.TextXAlignment.Left,
        AutomaticSize=Enum.AutomaticSize.X,
        ZIndex=501, Parent=WatermarkFrame,
    })

    -- Watermark drag — only while GUI open, ZIndex above everything
    do
        local _wmDrag, _wmDs, _wmSp = false, nil, nil
        local WmHit = mk("TextButton", {
            Size=dim2(1,0,1,0), BackgroundTransparency=1,
            Text="", BorderSizePixel=0, ZIndex=502, Parent=WatermarkFrame,
        })
        WmHit.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 and _vis then
                _wmDrag=true; _wmDs=i.Position; _wmSp=WatermarkFrame.Position
            end
        end)
        UIS.InputChanged:Connect(function(i)
            if _wmDrag and i.UserInputType == Enum.UserInputType.MouseMovement then
                local d = i.Position - _wmDs
                WatermarkFrame.Position = dim2(
                    _wmSp.X.Scale, _wmSp.X.Offset + d.X,
                    _wmSp.Y.Scale, _wmSp.Y.Offset + d.Y)
            end
        end)
        UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then _wmDrag=false end
        end)
    end

    -- Game name (fetched once async)
    local _gameName = tostring(game.Name ~= "" and game.Name or game.PlaceId)
    task.spawn(function()
        pcall(function()
            local info = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
            if info and info.Name then _gameName = info.Name end
        end)
    end)

    RunService.Heartbeat:Connect(function()
        if not ShowWatermark then return end
        pcall(function()
            local pName = _anon and "[ANON]" or LP.Name
            WmText.Text = string.format(
                " %s | %s | %s (%d) | %dfps | %dms | %s | cfg:%s",
                CFG.ScriptName, pName, _gameName, game.PlaceId,
                _fps, _ping, CFG.BuildType, _activeCfgName
            )
        end)
    end)

    -- ── Main window
    local WIN_W, WIN_H = 860, 560
    local SIDE_W       = 188

    local Main = mk("Frame", {
        Name="Main", Size=dim2(0,WIN_W,0,WIN_H),
        Position=dim2(0.5,-WIN_W/2,0.5,-WIN_H/2),
        BackgroundColor3=C.BgOuter, BorderSizePixel=0,
        Visible=false, Parent=SG,
    })
    mk("UICorner",{CornerRadius=dim(0,6),Parent=Main})
    -- subtle outline frame — also needs corner to match
    local _outlineF = mk("Frame", {
        Size=dim2(1,2,1,2), Position=dim2(0,-1,0,-1),
        BackgroundColor3=C.BgGroupH, BorderSizePixel=0, ZIndex=-1, Parent=Main,
    })
    mk("UICorner",{CornerRadius=dim(0,7),Parent=_outlineF})

    -- Drag zone (header region)
    local _drag, _ds, _sp = false, nil, nil
    local DragZone = mk("TextButton", {
        Size=dim2(0,SIDE_W+16,0,52), BackgroundTransparency=1,
        Text="", BorderSizePixel=0, ZIndex=10, Parent=Main,
    })
    DragZone.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            _drag=true; _ds=i.Position; _sp=Main.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if _drag and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - _ds
            Main.Position = dim2(_sp.X.Scale, _sp.X.Offset+d.X, _sp.Y.Scale, _sp.Y.Offset+d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then _drag=false end
    end)

    -- ── Sidebar
    local SideBd = mk("Frame", {
        Size=dim2(0,SIDE_W,1,-16), Position=dim2(0,8,0,8),
        BackgroundColor3=C.BgSideBd, BorderSizePixel=0, Parent=Main,
    })
    local Sidebar = mk("Frame", {
        Size=dim2(1,-1,1,-1), Position=dim2(0,1,0,0),
        BackgroundColor3=C.BgSide, BorderSizePixel=0, Parent=SideBd,
    })

    -- Sidebar header
    local LogoBox = mk("Frame", {
        Size=dim2(0,30,0,30), Position=dim2(0,8,0,10),
        BackgroundColor3=rgb(20,20,22), BorderSizePixel=0, Parent=Sidebar,
    })
    if CFG.LogoImage ~= "" then
        mk("ImageLabel", {
            Size=dim2(1,0,1,0), BackgroundTransparency=1, BorderSizePixel=0,
            Image=CFG.LogoImage, ScaleType=Enum.ScaleType.Fit, Parent=LogoBox,
        })
    else
        local LogoLbl = mk("TextLabel", {
            Size=dim2(1,0,1,0), BackgroundTransparency=1,
            Text="X", TextColor3=AC, TextSize=15, Font=Enum.Font.GothamBold, Parent=LogoBox,
        })
        onAC(function(c) LogoLbl.TextColor3 = c end)
    end
    mk("TextLabel", {
        Size=dim2(0,128,0,15), Position=dim2(0,44,0,11),
        BackgroundTransparency=1, Text=CFG.ScriptName,
        TextColor3=C.Tx0, TextSize=12, Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=Sidebar,
    })
    local BuildLbl = mk("TextLabel", {
        Size=dim2(0,128,0,12), Position=dim2(0,44,0,28),
        BackgroundTransparency=1, Text=CFG.BuildType,
        TextColor3=AC, TextSize=9, Font=Enum.Font.Code,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=Sidebar,
    })
    onAC(function(c) BuildLbl.TextColor3 = c end)
    mk("Frame", {
        Size=dim2(1,-16,0,1), Position=dim2(0,8,0,52),
        BackgroundColor3=C.BgGroupH, BorderSizePixel=0, Parent=Sidebar,
    })

    -- User tab list scroll (leaves room for pinned tabs + player card below)
    local TabScroll = mk("ScrollingFrame", {
        Size=dim2(1,0,1,-206), Position=dim2(0,0,0,58),
        BackgroundTransparency=1, ScrollBarThickness=0,
        BorderSizePixel=0, CanvasSize=dim2(0,0,0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y, Parent=Sidebar,
    })
    layout(TabScroll, Enum.FillDirection.Vertical, 0)

    -- ── Pinned tabs section (Settings + Players) — above the player card
    mk("Frame", {
        Size=dim2(1,-16,0,1), Position=dim2(0,8,1,-148),
        BackgroundColor3=C.BgGroupH, BorderSizePixel=0, Parent=Sidebar,
    })
    local PinnedScroll = mk("Frame", {
        Size=dim2(1,0,0,62), Position=dim2(0,0,1,-148),
        BackgroundTransparency=1, Parent=Sidebar,
    })
    layout(PinnedScroll, Enum.FillDirection.Vertical, 0)

    -- Player card (bottom of sidebar)
    mk("Frame", {
        Size=dim2(1,-16,0,1), Position=dim2(0,8,1,-84),
        BackgroundColor3=C.BgGroupH, BorderSizePixel=0, Parent=Sidebar,
    })
    local PCard = mk("Frame", {
        Size=dim2(1,0,0,84), Position=dim2(0,0,1,-84),
        BackgroundTransparency=1, Parent=Sidebar,
    })
    mk("Frame", {
        Size=dim2(0,30,0,30), Position=dim2(0,8,0,10),
        BackgroundColor3=C.BgRow, BorderSizePixel=0, Parent=PCard,
    })
    mk("ImageLabel", {
        Size=dim2(0,30,0,30), Position=dim2(0,8,0,10),
        BackgroundTransparency=1, BorderSizePixel=0,
        Image="https://www.roblox.com/headshot-thumbnail/image?userId="..LP.UserId.."&width=48&height=48&format=png",
        Parent=PCard,
    })
    local PDispName = mk("TextLabel", {
        Size=dim2(0,120,0,14), Position=dim2(0,44,0,11),
        BackgroundTransparency=1, Text=LP.DisplayName,
        TextColor3=C.Tx0, TextSize=11, Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd, Parent=PCard,
    })
    local PUserName = mk("TextLabel", {
        Size=dim2(0,120,0,12), Position=dim2(0,44,0,27),
        BackgroundTransparency=1, Text="@"..LP.Name,
        TextColor3=C.TxSub, TextSize=9, Font=Enum.Font.Code,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd, Parent=PCard,
    })
    local wFps = mk("TextLabel", {
        Size=dim2(0.5,0,0,12), Position=dim2(0,8,0,52),
        BackgroundTransparency=1, Text="--fps",
        TextColor3=C.TxSub, TextSize=9, Font=Enum.Font.Code,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=PCard,
    })
    local wPing = mk("TextLabel", {
        Size=dim2(0.5,0,0,12), Position=dim2(0.5,0,0,52),
        BackgroundTransparency=1, Text="--ms",
        TextColor3=C.TxSub, TextSize=9, Font=Enum.Font.Code,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=PCard,
    })
    RunService.Heartbeat:Connect(function()
        pcall(function()
            wFps.Text  = _fps.."fps"
            wPing.Text = _ping.."ms"
            PDispName.Text = _anon and "[ANON]"   or LP.DisplayName
            PUserName.Text = _anon and "[HIDDEN]" or "@"..LP.Name
        end)
    end)

    -- ── Content area
    local ContentBd = mk("Frame", {
        Size=dim2(1,-(SIDE_W+24),1,-16), Position=dim2(0,SIDE_W+16,0,8),
        BackgroundColor3=C.BgMainBd, BorderSizePixel=0, Parent=Main,
    })
    local ContentArea = mk("Frame", {
        Size=dim2(1,-1,1,-1), Position=dim2(0,1,0,0),
        BackgroundColor3=C.BgMain, BorderSizePixel=0, Parent=ContentBd,
    })

    -- Sub-tab bar
    local SubTabBar = mk("Frame", {
        Size=dim2(1,0,0,34), BackgroundColor3=C.BgMain,
        BorderSizePixel=0, ClipsDescendants=true, Parent=ContentArea,
    })
    mk("Frame", {
        Size=dim2(1,0,0,1), Position=dim2(0,0,1,-1),
        BackgroundColor3=C.BgGroupH, BorderSizePixel=0, Parent=SubTabBar,
    })

    -- Panel scroll
    local PanelArea = mk("Frame", {
        Size=dim2(1,0,1,-35), Position=dim2(0,0,0,35),
        BackgroundTransparency=1, ClipsDescendants=true, Parent=ContentArea,
    })
    local PanelScroll = mk("ScrollingFrame", {
        Size=dim2(1,0,1,0), BackgroundTransparency=1,
        ScrollBarThickness=2, ScrollBarImageColor3=C.Toggle,
        BorderSizePixel=0, CanvasSize=dim2(0,0,0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y, Parent=PanelArea,
    })
    onAC(function(c) PanelScroll.ScrollBarImageColor3 = c end)

    -- ── Overlay root
    local _ovRoot   = mk("Frame", {Name="OvRoot",Size=dim2(1,0,1,0),BackgroundTransparency=1,ZIndex=200,Parent=SG})
    local _ovActive = nil
    local function closeOV()
        if _ovActive then _ovActive:Destroy(); _ovActive=nil end
    end
    local function openOV(fn)
        closeOV()
        local f  = mk("Frame",{Size=dim2(1,0,1,0),BackgroundTransparency=1,ZIndex=200,Parent=_ovRoot})
        local bg = mk("TextButton",{Size=dim2(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=200,Parent=f})
        local rdy = false; task.delay(0.08, function() rdy=true end)
        bg.MouseButton1Click:Connect(function() if rdy then closeOV() end end)
        _ovActive = f; fn(f)
    end

    -- ── Tab state
    local Tabs          = {}
    local SubTabScrolls = {}
    local TabFrames     = {}
    local SubTabsMap    = {}
    local ActiveTab     = nil
    local ActiveSubs    = {}

    local DynFills, DynTexts = {}, {}
    local function regFill(f) table.insert(DynFills, f) end
    local function regText(t) table.insert(DynTexts, t) end

    local function applyAccent(c)
        for _, f in ipairs(DynFills) do pcall(function() f.BackgroundColor3 = c end) end
        for _, t in ipairs(DynTexts) do pcall(function() t.TextColor3       = c end) end
        for k, btn in pairs(Tabs) do
            if k == ActiveTab then
                local ind = btn:FindFirstChild("Ind"); if ind then ind.BackgroundColor3 = c end
                local ico = btn:FindFirstChild("Ico"); if ico then ico.TextColor3 = c end
            end
        end
        for _, stMap in pairs(SubTabsMap) do
            for _, st in pairs(stMap) do
                if st.under.Visible then
                    st.under.BackgroundColor3 = c
                    st.lbl.TextColor3         = c
                end
            end
        end
    end
    onAC(applyAccent)

    local function SetActiveTab(key)
        for _, scr in pairs(SubTabScrolls) do scr.Visible = false end
        for _, tf  in pairs(TabFrames)     do tf.Visible  = false end
        for k, b   in pairs(Tabs) do
            local ind = b:FindFirstChild("Ind"); if ind then ind.Visible = false end
            local lbl = b:FindFirstChild("Lbl"); if lbl then lbl.TextColor3 = C.Tx2 end
            local ico = b:FindFirstChild("Ico"); if ico then ico.TextColor3 = C.Tx2 end
            b.BackgroundTransparency = 1
        end
        ActiveTab = key
        local btn = Tabs[key]; if not btn then return end
        local ind = btn:FindFirstChild("Ind")
        if ind then ind.Visible=true; ind.BackgroundColor3=AC end
        local lbl = btn:FindFirstChild("Lbl"); if lbl then lbl.TextColor3=C.Tx0 end
        local ico = btn:FindFirstChild("Ico"); if ico then ico.TextColor3=AC end
        btn.BackgroundColor3=C.BgActive; btn.BackgroundTransparency=0
        if SubTabScrolls[key] then SubTabScrolls[key].Visible=true end
        local activeSub = ActiveSubs[key]
        if activeSub and SubTabsMap[key] and SubTabsMap[key][activeSub] then
            local st = SubTabsMap[key][activeSub]
            st.frame.Visible=true; st.lbl.TextColor3=AC
            st.under.Visible=true; st.under.BackgroundColor3=AC
        end
        PanelScroll.CanvasPosition = Vector2.new(0,0)
    end

    -- Key toggle visibility
    local _vis = true
    UIS.InputBegan:Connect(function(i, gpe)
        if not gpe and i.KeyCode == KEY then
            _vis = not _vis; Main.Visible = _vis
        end
    end)

    -- Key name helper
    local KEYS_SHORT = {
        [Enum.KeyCode.LeftShift]="LSH",   [Enum.KeyCode.RightShift]="RSH",
        [Enum.KeyCode.LeftControl]="LCT", [Enum.KeyCode.RightControl]="RCT",
        [Enum.KeyCode.Insert]="INS",      [Enum.KeyCode.Backspace]="BS",
        [Enum.KeyCode.Return]="ENT",      [Enum.KeyCode.CapsLock]="CAP",
        [Enum.KeyCode.Escape]="ESC",      [Enum.KeyCode.Space]="SPC",
        [Enum.UserInputType.MouseButton1]="MB1",
        [Enum.UserInputType.MouseButton2]="MB2",
        [Enum.UserInputType.MouseButton3]="MB3",
    }
    pcall(function() KEYS_SHORT[Enum.UserInputType.MouseButton4]="MB4" end)
    pcall(function() KEYS_SHORT[Enum.UserInputType.MouseButton5]="MB5" end)
    local function keyName(k)
        if not k or k == Enum.KeyCode.Unknown then return "NONE" end
        return KEYS_SHORT[k] or tostring(k):gsub("Enum%.KeyCode%.",""):gsub("Enum%.UserInputType%.","")
    end

    -- ─────────────────────────────────────────────────────────
    -- COLOR PICKER (window-level so Settings can reuse it)
    -- ─────────────────────────────────────────────────────────
    local function openColorPicker(anchorPos, anchorH, getCol, onChange)
        openOV(function(ov)
            local ch2, cs2, cv2 = Color3.toHSV(getCol())
            local pw, ph = 210, 148
            local px = math.min(anchorPos.X, SG.AbsoluteSize.X - pw - 10)
            local py = anchorPos.Y + anchorH + 4
            if py + ph > SG.AbsoluteSize.Y - 10 then py = anchorPos.Y - ph - 4 end

            local pan = mk("Frame",{Size=dim2(0,pw,0,ph),Position=dim2(0,px,0,py),
                BackgroundColor3=C.BgSideBd,BorderSizePixel=1,ZIndex=220,Parent=ov})
            local svbg = mk("Frame",{Size=dim2(1,-10,0,86),Position=dim2(0,5,0,5),
                BackgroundColor3=Color3.fromHSV(ch2,1,1),ZIndex=221,Parent=pan})
            local wg = mk("Frame",{Size=dim2(1,0,1,0),BackgroundColor3=rgb(255,255,255),ZIndex=222,Parent=svbg})
            mk("UIGradient",{Transparency=NumberSequence.new({
                NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)}),Parent=wg})
            local bgf = mk("Frame",{Size=dim2(1,0,1,0),BackgroundColor3=rgb(0,0,0),ZIndex=223,Parent=svbg})
            mk("UIGradient",{Transparency=NumberSequence.new({
                NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)}),Rotation=90,Parent=bgf})
            -- Blocky square crosshair (no circle)
            local svc = mk("TextButton",{AutoButtonColor=false,Text="+",
                AnchorPoint=Vector2.new(.5,.5),Size=dim2(0,10,0,10),
                Position=dim2(cs2,0,1-cv2,0),TextColor3=rgb(255,255,255),TextSize=10,
                Font=Enum.Font.GothamBold,BackgroundTransparency=1,ZIndex=226,Parent=svbg})

            local hueBar = mk("TextButton",{AutoButtonColor=false,Text="",
                Size=dim2(1,-10,0,10),Position=dim2(0,5,0,97),ZIndex=221,Parent=pan})
            mk("UIGradient",{Color=ColorSequence.new({
                ColorSequenceKeypoint.new(0,    rgb(255,0,0)),
                ColorSequenceKeypoint.new(0.17, rgb(255,255,0)),
                ColorSequenceKeypoint.new(0.33, rgb(0,255,0)),
                ColorSequenceKeypoint.new(0.5,  rgb(0,255,255)),
                ColorSequenceKeypoint.new(0.67, rgb(0,0,255)),
                ColorSequenceKeypoint.new(0.83, rgb(255,0,255)),
                ColorSequenceKeypoint.new(1,    rgb(255,0,0))}),Parent=hueBar})
            -- Blocky hue cursor (rectangle)
            local hueCur = mk("Frame",{AnchorPoint=Vector2.new(.5,.5),
                Size=dim2(0,4,1,2),Position=dim2(ch2,0,.5,0),
                BackgroundColor3=rgb(255,255,255),ZIndex=223,Parent=hueBar})
            local prev = mk("Frame",{Size=dim2(1,-10,0,14),Position=dim2(0,5,0,113),
                BackgroundColor3=Color3.fromHSV(ch2,cs2,cv2),ZIndex=221,Parent=pan})

            local function updPicker()
                local nc = Color3.fromHSV(ch2, cs2, cv2)
                svbg.BackgroundColor3 = Color3.fromHSV(ch2,1,1)
                svc.Position          = dim2(cs2,0,1-cv2,0)
                hueCur.Position       = dim2(ch2,0,.5,0)
                prev.BackgroundColor3 = nc
                pcall(onChange, nc)
            end
            local dSV, dHue = false, false
            svbg.InputBegan:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 then
                    dSV = true
                    cs2 = math.clamp((i.Position.X-svbg.AbsolutePosition.X)/svbg.AbsoluteSize.X,0,1)
                    cv2 = 1-math.clamp((i.Position.Y-svbg.AbsolutePosition.Y)/svbg.AbsoluteSize.Y,0,1)
                    updPicker()
                end
            end)
            hueBar.InputBegan:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 then
                    dHue = true
                    ch2  = math.clamp((i.Position.X-hueBar.AbsolutePosition.X)/hueBar.AbsoluteSize.X,0,1)
                    updPicker()
                end
            end)
            UIS.InputChanged:Connect(function(i)
                if i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
                if dSV then
                    cs2 = math.clamp((i.Position.X-svbg.AbsolutePosition.X)/svbg.AbsoluteSize.X,0,1)
                    cv2 = 1-math.clamp((i.Position.Y-svbg.AbsolutePosition.Y)/svbg.AbsoluteSize.Y,0,1)
                    updPicker()
                end
                if dHue then
                    ch2 = math.clamp((i.Position.X-hueBar.AbsolutePosition.X)/hueBar.AbsoluteSize.X,0,1)
                    updPicker()
                end
            end)
            UIS.InputEnded:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 then dSV=false; dHue=false end
            end)
        end)
    end

    -- ─────────────────────────────────────────────────────────
    -- CONTEXT POPUP (right-click on toggle)
    -- ─────────────────────────────────────────────────────────
    -- Only one popup keybind listener lives at a time — avoids leaking
    -- persistent UIS connections every time the popup is opened.
    local _popupKbConn = nil
    local function openContextPopup(opts)
        openOV(function(ov)
            local mp     = UIS:GetMouseLocation()
            local pw, ph = 190, 78
            local px = math.min(mp.X, SG.AbsoluteSize.X - pw - 4)
            local py = math.min(mp.Y, SG.AbsoluteSize.Y - ph - 4)

            local Pop = mk("Frame",{Size=dim2(0,pw,0,ph),Position=dim2(0,px,0,py),
                BackgroundColor3=C.Popup,BorderSizePixel=1,ZIndex=250,Parent=ov})

            -- Mode selector row
            local ModeRow = mk("Frame",{Size=dim2(1,-12,0,28),Position=dim2(0,6,0,8),
                BackgroundColor3=C.BgRow,BorderSizePixel=0,ZIndex=251,Parent=Pop})
            layout(ModeRow, Enum.FillDirection.Horizontal, 0)
            local MODES   = {"Toggle","Hold","Always"}
            local modeBtns = {}
            local function refreshModes()
                for _, info in ipairs(modeBtns) do
                    local active = info.mode == opts.getMode()
                    info.btn.BackgroundColor3 = active and AC or C.BgRow
                    info.btn.TextColor3       = active and C.White or C.Tx2
                end
            end
            for mi, mOpt in ipairs(MODES) do
                local MB = mk("TextButton",{Size=dim2(1/3,0,1,0),BackgroundColor3=C.BgRow,
                    Text=mOpt,TextColor3=C.Tx2,TextSize=9,Font=Enum.Font.GothamBold,
                    AutoButtonColor=false,BorderSizePixel=0,ZIndex=252,LayoutOrder=mi,Parent=ModeRow})
                table.insert(modeBtns,{btn=MB,mode=mOpt})
                MB.MouseButton1Click:Connect(function() opts.setMode(mOpt); refreshModes() end)
            end
            refreshModes()

            -- Keybind row
            local KbRow = mk("Frame",{Size=dim2(1,-12,0,26),Position=dim2(0,6,0,44),
                BackgroundTransparency=1,ZIndex=251,Parent=Pop})
            mk("TextLabel",{Size=dim2(0,52,1,0),BackgroundTransparency=1,Text="Keybind",
                TextColor3=C.Tx2,TextSize=9,Font=Enum.Font.Gotham,
                TextXAlignment=Enum.TextXAlignment.Left,ZIndex=252,Parent=KbRow})
            local kbBtn = mk("TextButton",{Size=dim2(1,-58,1,0),Position=dim2(0,56,0,0),
                BackgroundColor3=C.BgRow,Text=keyName(opts.getKey()),
                TextColor3=AC,TextSize=9,Font=Enum.Font.GothamBold,
                AutoButtonColor=false,BorderSizePixel=0,ZIndex=252,Parent=KbRow})
            onAC(function(c) kbBtn.TextColor3=c end)

            local listening = false

            -- Kill any previous popup keybind listener before making a new one
            if _popupKbConn then _popupKbConn:Disconnect(); _popupKbConn=nil end

            kbBtn.MouseButton1Click:Connect(function()
                if listening then return end
                listening=true
                kbBtn.Text="press a key..."; kbBtn.TextColor3=rgb(255,185,0)
            end)

            _popupKbConn = UIS.InputBegan:Connect(function(i, gpe)
                if not listening or gpe then return end
                -- Escape cancels without setting
                if i.KeyCode == Enum.KeyCode.Escape then
                    listening=false
                    kbBtn.Text=keyName(opts.getKey()); kbBtn.TextColor3=AC
                    return
                end
                local k
                if isMouseButton(i.UserInputType) then k=i.UserInputType
                elseif i.UserInputType==Enum.UserInputType.Keyboard then k=i.KeyCode end
                if not k then return end
                -- Capture key, disconnect immediately so no future leaks
                _popupKbConn:Disconnect(); _popupKbConn=nil
                listening=false
                opts.setKey(k)
                kbBtn.Text=keyName(k); kbBtn.TextColor3=AC
            end)

            -- Clean up listener when the overlay is dismissed
            ov.AncestryChanged:Connect(function()
                if _popupKbConn then _popupKbConn:Disconnect(); _popupKbConn=nil end
            end)
        end)
    end

    -- ═══════════════════════════════════════════════════════════
    -- WINDOW OBJECT
    -- ═══════════════════════════════════════════════════════════
    local WO = {_categories={}, _cfgsys=CFGSYS}
    setmetatable(WO, {__index=Peleccos})

    function WO:Notify(opts)   notify(opts)          end
    function WO:SetAccent(c)   setAC(c)              end
    function WO:Toggle()       _vis=not _vis; Main.Visible=_vis end
    function WO:Destroy()      SG:Destroy()          end
    function WO:GetVisFont()   return VisFont         end
    function WO:OnVisFont(fn)  onFont(function(_,vf) fn(vf) end) end
    function WO:SaveConfig(n)
        _activeCfgName = n or _activeCfgName
        return CFGSYS.save(_activeCfgName)
    end
    function WO:LoadConfig(n)
        _activeCfgName = n or _activeCfgName
        return CFGSYS.load(_activeCfgName)
    end

    -- ═══════════════════════════════════════════════════════════
    -- AddCategory
    -- ═══════════════════════════════════════════════════════════
    -- _pinned=true places the tab button in PinnedScroll instead of TabScroll
    function WO:AddCategory(name, _pinned)
        local isFirst = #self._categories == 0
        local catKey  = name:lower():gsub("[^%w]","_").."_"..tostring(#self._categories)
        local tabParent = _pinned and PinnedScroll or TabScroll

        -- Sidebar button
        local Btn = mk("TextButton",{Name=catKey,Size=dim2(1,0,0,29),
            BackgroundColor3=C.BgHover,BackgroundTransparency=1,
            Text="",BorderSizePixel=0,Parent=tabParent})
        -- Left accent bar (3px, shown when active)
        mk("Frame",{Name="Ind",Size=dim2(0,3,0,16),Position=dim2(0,0,0.5,-8),
            BackgroundColor3=AC,BorderSizePixel=0,Visible=false,Parent=Btn})
        local Lbl = mk("TextLabel",{Name="Lbl",Size=dim2(1,-16,1,0),Position=dim2(0,12,0,0),
            BackgroundTransparency=1,Text=name,TextColor3=C.Tx2,
            TextSize=11,Font=MenuFont,TextXAlignment=Enum.TextXAlignment.Left,Parent=Btn})
        onFont(function(mf,_) Lbl.Font=mf end)
        Btn.MouseEnter:Connect(function()
            if catKey~=ActiveTab then
                Btn.BackgroundTransparency=0; Btn.BackgroundColor3=C.BgHover
                Lbl.TextColor3=C.Tx1
            end
        end)
        Btn.MouseLeave:Connect(function()
            if catKey~=ActiveTab then
                tw(Btn,{BackgroundTransparency=1},0.1)
                Lbl.TextColor3=C.Tx2
            end
        end)
        Btn.MouseButton1Click:Connect(function() SetActiveTab(catKey) end)
        Tabs[catKey] = Btn

        -- Sub-tab scroll in subtab bar
        local StScroll = mk("ScrollingFrame",{Size=dim2(1,0,1,-1),BackgroundTransparency=1,
            ScrollBarThickness=0,BorderSizePixel=0,
            CanvasSize=dim2(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.X,
            Visible=false,Parent=SubTabBar})
        layout(StScroll,Enum.FillDirection.Horizontal,0,Enum.HorizontalAlignment.Left,Enum.VerticalAlignment.Center)
        padding(StScroll,0,0,0,6)
        SubTabScrolls[catKey] = StScroll
        SubTabsMap[catKey]    = {}
        ActiveSubs[catKey]    = nil

        local CAT = {_name=name, _key=catKey, _win=self, _subOrder=0}
        table.insert(self._categories, CAT)

        -- Internal addSubTab
        local _defaultPanel = nil
        local function addSubTab(label)
            CAT._subOrder = CAT._subOrder + 1
            local subKey  = catKey.."_s"..CAT._subOrder

            local StBtn = mk("TextButton",{Name=subKey,Size=dim2(0,0,1,-1),
                AutomaticSize=Enum.AutomaticSize.X,BackgroundTransparency=1,
                Text="",BorderSizePixel=0,LayoutOrder=CAT._subOrder,Parent=StScroll})
            padding(StBtn,0,10,0,10)
            local StLbl = mk("TextLabel",{Name="Lbl",Size=dim2(1,0,1,0),
                BackgroundTransparency=1,Text=label,TextColor3=C.Tx2,
                TextSize=10,Font=MenuFont,Parent=StBtn})
            onFont(function(mf,_) StLbl.Font=mf end)
            local StUnder = mk("Frame",{Name="Under",Size=dim2(1,0,0,2),Position=dim2(0,0,1,-2),
                BackgroundColor3=AC,BorderSizePixel=0,Visible=false,Parent=StBtn})

            local TF = mk("Frame",{Name=subKey,Size=dim2(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
                BackgroundTransparency=1,Visible=false,Parent=PanelScroll})
            layout(TF,Enum.FillDirection.Vertical,6)
            padding(TF,6,6,6,6)

            TabFrames[subKey]          = TF
            SubTabsMap[catKey][subKey] = {btn=StBtn,frame=TF,lbl=StLbl,under=StUnder}
            if ActiveSubs[catKey]==nil then ActiveSubs[catKey]=subKey end

            StBtn.MouseButton1Click:Connect(function()
                for _,st2 in pairs(SubTabsMap[catKey]) do
                    st2.frame.Visible=false; st2.lbl.TextColor3=C.Tx2; st2.under.Visible=false
                end
                TF.Visible=true; StLbl.TextColor3=AC
                StUnder.Visible=true; StUnder.BackgroundColor3=AC
                ActiveSubs[catKey]=subKey
                PanelScroll.CanvasPosition=Vector2.new(0,0)
            end)
            return TF
        end

        local function getDefault()
            if not _defaultPanel then _defaultPanel=addSubTab(name) end
            return _defaultPanel
        end

        -- Group box factory
        local function mkGroup(parent, title)
            local Card = mk("Frame",{Size=dim2(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
                BackgroundColor3=C.BgGroupH,BorderSizePixel=0,Parent=parent})
            mk("UICorner",{CornerRadius=dim(0,4),Parent=Card})
            local GBar = mk("Frame",{Size=dim2(0,2,1,0),BackgroundColor3=AC,BorderSizePixel=0,Parent=Card})
            onAC(function(c) GBar.BackgroundColor3=c end)
            local Inner = mk("Frame",{Size=dim2(1,-2,1,0),Position=dim2(0,2,0,0),
                BackgroundColor3=C.BgGroup,BorderSizePixel=0,AutomaticSize=Enum.AutomaticSize.Y,Parent=Card})
            mk("UICorner",{CornerRadius=dim(0,4),Parent=Inner})
            local Hdr = mk("Frame",{Size=dim2(1,0,0,22),BackgroundTransparency=1,Parent=Inner})
            local HdrL = mk("TextLabel",{Size=dim2(1,-14,1,0),Position=dim2(0,6,0,0),
                BackgroundTransparency=1,Text=title,TextColor3=AC,
                TextSize=10,Font=MenuFont,TextXAlignment=Enum.TextXAlignment.Left,Parent=Hdr})
            onFont(function(mf,_) HdrL.Font=mf end)
            onAC(function(c) HdrL.TextColor3=c end)
            mk("Frame",{Size=dim2(1,0,0,1),Position=dim2(0,0,0,22),
                BackgroundColor3=C.BgGroupH,BorderSizePixel=0,Parent=Inner})
            local Body = mk("Frame",{Size=dim2(1,0,0,0),Position=dim2(0,0,0,24),
                BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,Parent=Inner})
            layout(Body,Enum.FillDirection.Vertical,0)
            padding(Body,2,6,6,6)
            return Card, Body
        end

        local function mkRow(parent, h)
            return mk("Frame",{Size=dim2(1,0,0,h or 26),BackgroundTransparency=1,Parent=parent})
        end

        -- ──────────────────────────────────────────
        -- WIDGET BUILDERS
        -- ──────────────────────────────────────────

        function CAT:_AddToggle(o5, parentOverride)
            o5 = o5 or {}
            local parent = parentOverride or getDefault()
            local nm     = o5.Name or "Toggle"
            local flag   = o5.Flag or autoFlag(nm)
            local val    = o5.Default == true
            local cb     = o5.Callback or function() end
            local kbKey  = o5.Keybind  or Enum.KeyCode.Unknown
            local kbMode = "Toggle"

            local row = mkRow(parent, 27)
            local Lbl = mk("TextLabel",{Size=dim2(1,-20,1,0),BackgroundTransparency=1,Text=nm,
                TextColor3=val and C.Tx0 or C.Tx2,TextSize=11,Font=MenuFont,
                TextXAlignment=Enum.TextXAlignment.Left,Parent=row})
            onFont(function(mf,_) Lbl.Font=mf end)

            -- Checkbox: slightly rounded square
            local Box = mk("Frame",{Size=dim2(0,13,0,13),Position=dim2(1,-15,0.5,-6),
                BackgroundColor3=val and AC or C.Toggle,BorderSizePixel=0,Parent=row})
            mk("UICorner",{CornerRadius=dim(0,3),Parent=Box})
            onAC(function(c) if val then Box.BackgroundColor3=c end end)

            local function set(v, silent)
                val=v
                tw(Box,{BackgroundColor3=v and AC or C.Toggle},0.1)
                Lbl.TextColor3 = v and C.Tx0 or C.Tx2
                if not silent then pcall(cb,v) end
            end
            local function applyMode(m)
                kbMode=m; if m=="Always" and not val then set(true) end
            end
            local allowKeybind = o5.Keybind ~= nil

            -- Subtle right-click hint shown when Keybind is enabled
            if allowKeybind then
                mk("TextLabel",{
                    Size=dim2(0,28,0,10), Position=dim2(1,-32,1,-10),
                    BackgroundTransparency=1, Text="[RMB]",
                    TextColor3=C.Tx2, TextSize=7, Font=Enum.Font.Code,
                    TextXAlignment=Enum.TextXAlignment.Right, Parent=row,
                })
            end

            local Hit = mk("TextButton",{Size=dim2(1,0,1,0),BackgroundTransparency=1,
                Text="",AutoButtonColor=false,Parent=row})
            Hit.MouseEnter:Connect(function() if not val then Lbl.TextColor3=C.Tx1 end end)
            Hit.MouseLeave:Connect(function() if not val then Lbl.TextColor3=C.Tx2 end end)
            Hit.MouseButton1Click:Connect(function() if kbMode~="Always" then set(not val) end end)
            if allowKeybind then
                Hit.MouseButton2Click:Connect(function()
                    openContextPopup({
                        getMode=function() return kbMode end,
                        setMode=function(m) applyMode(m) end,
                        getKey =function() return kbKey  end,
                        setKey =function(k) kbKey=k       end,
                    })
                end)
            end
            local _holding=false
            UIS.InputBegan:Connect(function(i,gpe)
                if gpe or kbKey==Enum.KeyCode.Unknown then return end
                if i.KeyCode==kbKey or i.UserInputType==kbKey then
                    if kbMode=="Toggle" then set(not val)
                    elseif kbMode=="Hold" then _holding=true; set(true)
                    elseif kbMode=="Always" then set(true) end
                end
            end)
            UIS.InputEnded:Connect(function(i)
                if kbMode=="Hold" and _holding and (i.KeyCode==kbKey or i.UserInputType==kbKey) then
                    _holding=false; set(false)
                end
            end)
            CFGSYS.register(flag, function() return val end, function(v) set(v,false) end, "bool")
            CFGSYS.register(flag.."__mode", function() return kbMode end, function(v) applyMode(v) end, "mode")
            local r={Value=val}
            function r:Set(v) set(v,true) end
            function r:Get() return val end
            return r
        end

        function CAT:_AddSlider(o5, parentOverride)
            o5 = o5 or {}
            local parent = parentOverride or getDefault()
            local nm     = o5.Name    or "Slider"
            local flag   = o5.Flag    or autoFlag(nm)
            local mn     = o5.Min     or 0
            local mx     = o5.Max     or 100
            local step   = o5.Step    or 1
            local suf    = o5.Suffix  or ""
            local cb     = o5.Callback or function() end
            local val    = math.clamp(o5.Default or mn, mn, mx)

            local wrap = mk("Frame",{Size=dim2(1,0,0,40),BackgroundTransparency=1,Parent=parent})
            local topRow = mk("Frame",{Size=dim2(1,0,0,17),BackgroundTransparency=1,Parent=wrap})
            local NmLbl = mk("TextLabel",{Size=dim2(0.62,0,1,0),BackgroundTransparency=1,Text=nm,
                TextColor3=C.Tx1,TextSize=11,Font=MenuFont,
                TextXAlignment=Enum.TextXAlignment.Left,Parent=topRow})
            onFont(function(mf,_) NmLbl.Font=mf end)
            -- Value display (no box bg — just the number, dimmer)
            local ValBox = mk("Frame",{Size=dim2(0,46,0,14),Position=dim2(1,-48,0.5,-7),
                BackgroundColor3=C.BgRow,BorderSizePixel=0,Parent=topRow})
            local function fmtV(v)
                if step<1 then
                    local dec=math.max(0,math.ceil(-math.log10(step)))
                    return string.format("%."..dec.."f",v)..suf
                end
                return tostring(v)..suf
            end
            local vLbl = mk("TextLabel",{Size=dim2(1,0,1,0),BackgroundTransparency=1,
                Text=fmtV(val),TextColor3=AC,TextSize=9,Font=Enum.Font.Code,Parent=ValBox})
            regText(vLbl)

            local trackRow = mk("Frame",{Size=dim2(1,0,0,20),Position=dim2(0,0,0,18),
                BackgroundTransparency=1,Parent=wrap})
            local Track = mk("Frame",{Size=dim2(1,-42,0,5),Position=dim2(0,0,0.5,-2),
                BackgroundColor3=C.BgGroupH,BorderSizePixel=0,Parent=trackRow})
            local pct = (mn==mx) and 0 or (val-mn)/(mx-mn)
            local Fill = mk("Frame",{Size=dim2(pct,0,1,0),BackgroundColor3=AC,
                BorderSizePixel=0,Parent=Track})
            regFill(Fill)
            -- No thumb/knob — bar only

            local minusBtn = mk("TextButton",{Size=dim2(0,18,0,16),Position=dim2(1,-40,0.5,-8),
                BackgroundColor3=C.BgRow,Text="-",TextColor3=C.Tx1,TextSize=12,
                Font=Enum.Font.GothamBold,AutoButtonColor=false,BorderSizePixel=0,Parent=trackRow})
            local plusBtn = mk("TextButton",{Size=dim2(0,18,0,16),Position=dim2(1,-20,0.5,-8),
                BackgroundColor3=C.BgRow,Text="+",TextColor3=C.Tx1,TextSize=12,
                Font=Enum.Font.GothamBold,AutoButtonColor=false,BorderSizePixel=0,Parent=trackRow})

            local function sv(v, silent)
                v   = math.clamp(math.round(v/step)*step,mn,mx)
                val = tonumber(string.format("%.10g",v))
                local p = (mn==mx) and 0 or (val-mn)/(mx-mn)
                tw(Fill,{Size=dim2(p,0,1,0)},0.04,Enum.EasingStyle.Linear)
                vLbl.Text = fmtV(val)
                if not silent then pcall(cb,val) end
            end
            local dragging=false
            local Hit = mk("TextButton",{Size=dim2(1,0,4,0),Position=dim2(0,0,-0.5,-4),
                BackgroundTransparency=1,Text="",AutoButtonColor=false,Parent=Track})
            local function posToVal(absX)
                return mn+(mx-mn)*math.clamp((absX-Track.AbsolutePosition.X)/math.max(Track.AbsoluteSize.X,1),0,1)
            end
            Hit.InputBegan:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; sv(posToVal(i.Position.X)) end
            end)
            UIS.InputChanged:Connect(function(i)
                if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then sv(posToVal(i.Position.X)) end
            end)
            UIS.InputEnded:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
            end)
            minusBtn.MouseButton1Click:Connect(function()
                local m=UIS:IsKeyDown(Enum.KeyCode.LeftShift) and 10 or 1; sv(val-step*m)
            end)
            plusBtn.MouseButton1Click:Connect(function()
                local m=UIS:IsKeyDown(Enum.KeyCode.LeftShift) and 10 or 1; sv(val+step*m)
            end)
            CFGSYS.register(flag, function() return val end, function(v) sv(v,true) end, "number")
            local r={Value=val}
            function r:Set(v) sv(v,true) end
            function r:Get() return val end
            return r
        end

        function CAT:_AddDropdown(o5, parentOverride)
            o5 = o5 or {}
            local parent = parentOverride or getDefault()
            local nm     = o5.Name    or "Dropdown"
            local flag   = o5.Flag    or autoFlag(nm)
            local opts2  = o5.Options or {}
            local multi  = o5.Multi   or false
            local cb     = o5.Callback or function() end
            local sel    = o5.Default or (opts2[1] or "")
            local msel   = {}

            -- MOON-style: label on left, header bar on right half
            local ROW_H = 28
            local wrap = mk("Frame",{Size=dim2(1,0,0,ROW_H),BackgroundTransparency=1,Parent=parent})
            local NmLbl = mk("TextLabel",{Size=dim2(0.5,-4,1,0),BackgroundTransparency=1,Text=nm,
                TextColor3=C.Tx1,TextSize=11,Font=MenuFont,
                TextXAlignment=Enum.TextXAlignment.Left,Parent=wrap})
            onFont(function(mf,_) NmLbl.Font=mf end)

            -- Right-side header: value + arrow
            local Hd = mk("TextButton",{Size=dim2(0.5,-2,0,20),Position=dim2(0.5,0,0.5,-10),
                BackgroundColor3=rgb(22,26,30),Text="",AutoButtonColor=false,
                BorderSizePixel=0,Parent=wrap})
            mk("UICorner",{CornerRadius=dim(0,3),Parent=Hd})
            Hd.MouseEnter:Connect(function() tw(Hd,{BackgroundColor3=rgb(28,33,38)},0.07) end)
            Hd.MouseLeave:Connect(function() tw(Hd,{BackgroundColor3=rgb(22,26,30)},0.1) end)

            local SelLbl = mk("TextLabel",{Size=dim2(1,-20,1,0),Position=dim2(0,6,0,0),
                BackgroundTransparency=1,Text=multi and "None" or tostring(sel),
                TextColor3=C.Tx0,TextSize=10,Font=Enum.Font.Gotham,
                TextXAlignment=Enum.TextXAlignment.Left,Parent=Hd})
            -- Small caret — MOON uses a simple v-like arrow
            local ArrowLbl = mk("TextLabel",{Size=dim2(0,14,1,0),Position=dim2(1,-15,0,0),
                BackgroundTransparency=1,Text="▼",TextColor3=C.Tx2,TextSize=7,
                Font=Enum.Font.GothamBold,Parent=Hd})

            local isOpen=false
            local function closeDD() isOpen=false; ArrowLbl.Text="▼"; closeOV() end

            local function buildDD(ov)
                local ap     = Hd.AbsolutePosition
                local as     = Hd.AbsoluteSize
                local ITEM_H = 22
                local lh     = math.min(#opts2 * ITEM_H + 6, 180)
                local pw  = math.max(as.X, 120)
                local px  = math.min(ap.X, SG.AbsoluteSize.X - pw - 10)
                local py  = ap.Y + as.Y + 2
                if py + lh > SG.AbsoluteSize.Y - 10 then py = ap.Y - lh - 2 end

                -- Panel: very dark bg, 1px subtle border
                local pan = mk("Frame",{
                    Size=dim2(0,pw,0,0), Position=dim2(0,px,0,py),
                    BackgroundColor3=rgb(16,19,22), BorderSizePixel=0,
                    ClipsDescendants=true, ZIndex=220, Parent=ov,
                })
                mk("UICorner",{CornerRadius=dim(0,4),Parent=pan})
                mk("UIStroke",{Color=rgb(36,42,48),Thickness=1,Parent=pan})
                tw(pan, {Size=dim2(0,pw,0,lh)}, 0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

                local sc = mk("ScrollingFrame",{
                    Size=dim2(1,0,1,0), BackgroundTransparency=1,
                    ScrollBarThickness=2, ScrollBarImageColor3=rgb(40,50,60),
                    CanvasSize=dim2(0,0,0,0), BorderSizePixel=0,
                    ZIndex=221, Parent=pan,
                })
                local scLL = layout(sc, Enum.FillDirection.Vertical, 0)
                padding(sc, 3, 3, 3, 3)
                autoCanvas(sc, scLL)

                local itemFrames = {}

                local function refreshItems()
                    for _, info in ipairs(itemFrames) do
                        local isSel2 = multi and table.find(msel, info.op) ~= nil or info.op == sel
                        info.lbl.TextColor3        = isSel2 and C.Tx0 or C.Tx1
                        info.frame.BackgroundColor3 = isSel2 and rgb(28,34,40) or rgb(19,23,27)
                        info.dot.Visible = isSel2
                    end
                end

                for _, op in ipairs(opts2) do
                    local isSel = multi and table.find(msel, op) ~= nil or op == sel

                    local item = mk("Frame",{
                        Size=dim2(1,0,0,ITEM_H),
                        BackgroundColor3=isSel and rgb(28,34,40) or rgb(19,23,27),
                        BorderSizePixel=0, ZIndex=222, Parent=sc,
                    })
                    -- small dot on right when selected (MOON-ish indicator)
                    local dot = mk("Frame",{
                        Size=dim2(0,4,0,4),
                        AnchorPoint=Vector2.new(1,0.5),
                        Position=dim2(1,-6,0.5,0),
                        BackgroundColor3=AC, BorderSizePixel=0,
                        Visible=isSel, ZIndex=223, Parent=item,
                    })
                    onAC(function(c) dot.BackgroundColor3=c end)
                    local lbl = mk("TextLabel",{
                        Size=dim2(1,-20,1,0), Position=dim2(0,8,0,0),
                        BackgroundTransparency=1, Text=op,
                        TextColor3=isSel and C.Tx0 or C.Tx1,
                        TextSize=10, Font=Enum.Font.Gotham,
                        TextXAlignment=Enum.TextXAlignment.Left,
                        ZIndex=223, Parent=item,
                    })
                    local hitBtn = mk("TextButton",{
                        Size=dim2(1,0,1,0), BackgroundTransparency=1,
                        Text="", AutoButtonColor=false, ZIndex=224, Parent=item,
                    })
                    hitBtn.MouseEnter:Connect(function()
                        tw(item,{BackgroundColor3=rgb(32,38,46)},0.06)
                        lbl.TextColor3 = C.Tx0
                    end)
                    hitBtn.MouseLeave:Connect(function()
                        local s = multi and table.find(msel,op)~=nil or op==sel
                        tw(item,{BackgroundColor3=s and rgb(28,34,40) or rgb(19,23,27)},0.08)
                        lbl.TextColor3 = s and C.Tx0 or C.Tx1
                    end)
                    hitBtn.MouseButton1Click:Connect(function()
                        if multi then
                            local idx = table.find(msel, op)
                            if idx then table.remove(msel, idx) else table.insert(msel, op) end
                            SelLbl.Text = #msel > 0 and table.concat(msel, ", ") or "None"
                            refreshItems()
                            pcall(cb, msel)
                        else
                            sel = op
                            SelLbl.Text = op
                            pcall(cb, op)
                            closeDD()
                        end
                    end)
                    table.insert(itemFrames, {frame=item, dot=dot, lbl=lbl, op=op})
                end
            end

            Hd.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                if isOpen then
                    ArrowLbl.Text = "▲"
                    openOV(buildDD)
                else
                    closeDD()
                end
            end)
            CFGSYS.register(flag, function() return sel end, function(v) sel=v; SelLbl.Text=v end, "string")
            local r={Value=sel}
            function r:Set(v)         sel=v; SelLbl.Text=v end
            function r:SetOptions(t)  opts2=t end
            function r:Get()          return multi and msel or sel end
            return r
        end

        function CAT:_AddColorPicker(o5, parentOverride)
            o5 = o5 or {}
            local parent = parentOverride or getDefault()
            local nm     = o5.Name    or "Color"
            local flag   = o5.Flag    or autoFlag(nm)
            local col    = o5.Default or rgb(255,80,80)
            local cb     = o5.Callback or function() end
            local row = mkRow(parent, 26)
            local NmLbl = mk("TextLabel",{Size=dim2(1,-44,1,0),BackgroundTransparency=1,Text=nm,
                TextColor3=C.Tx1,TextSize=11,Font=MenuFont,
                TextXAlignment=Enum.TextXAlignment.Left,Parent=row})
            onFont(function(mf,_) NmLbl.Font=mf end)
            local Sw = mk("TextButton",{Size=dim2(0,36,0,18),Position=dim2(1,-38,0.5,-9),
                BackgroundColor3=col,Text="",AutoButtonColor=false,
                BorderSizePixel=1,Parent=row})
            local open2=false
            Sw.MouseButton1Click:Connect(function()
                open2=not open2
                if open2 then
                    openColorPicker(Sw.AbsolutePosition, Sw.AbsoluteSize.Y,
                        function() return col end,
                        function(nc) col=nc; Sw.BackgroundColor3=nc; pcall(cb,nc) end)
                else closeOV() end
            end)
            CFGSYS.register(flag,
                function() return col end,
                function(c2) col=c2; Sw.BackgroundColor3=c2; pcall(cb,c2) end, "color")
            local r={Value=col}
            function r:Set(c2) col=c2; Sw.BackgroundColor3=c2 end
            function r:Get()   return col end
            return r
        end

        function CAT:_AddKeybind(o5, parentOverride)
            o5 = o5 or {}
            local parent = parentOverride or getDefault()
            local nm     = o5.Name    or "Keybind"
            local flag   = o5.Flag    or autoFlag(nm)
            local key    = o5.Default or Enum.KeyCode.Unknown
            local cb     = o5.Callback or function() end
            local listen = false
            local kbMode = "Toggle"  -- Toggle | Hold | Always (same as toggle widget)
            local _holding = false

            local row = mkRow(parent, 27)

            -- Full-row hit area so the whole row reacts to hover/click
            local RowHit = mk("TextButton",{Size=dim2(1,0,1,0),BackgroundTransparency=1,
                Text="",AutoButtonColor=false,Parent=row})

            local NmLbl = mk("TextLabel",{Size=dim2(1,-88,1,0),BackgroundTransparency=1,Text=nm,
                TextColor3=C.Tx2,TextSize=11,Font=MenuFont,
                TextXAlignment=Enum.TextXAlignment.Left,Parent=row})
            onFont(function(mf,_) NmLbl.Font=mf end)

            local Kb = mk("TextButton",{Size=dim2(0,80,0,18),Position=dim2(1,-82,0.5,-9),
                BackgroundColor3=C.BgRow,TextColor3=AC,Text=keyName(key),
                TextSize=9,Font=Enum.Font.GothamBold,
                AutoButtonColor=false,BorderSizePixel=0,Parent=row})
            onAC(function(c) if not listen then Kb.TextColor3=c end end)

            -- Hover: brighten the name label and the key button together
            RowHit.MouseEnter:Connect(function()
                if listen then return end
                NmLbl.TextColor3 = C.Tx1
                tw(Kb,{BackgroundColor3=C.BgGroupH},0.07)
            end)
            RowHit.MouseLeave:Connect(function()
                if listen then return end
                NmLbl.TextColor3 = C.Tx2
                tw(Kb,{BackgroundColor3=C.BgRow},0.1)
            end)

            -- Left-click starts listening
            RowHit.MouseButton1Click:Connect(function()
                if listen then return end
                listen=true
                NmLbl.TextColor3 = rgb(255,185,0)
                Kb.Text="press key"
                Kb.TextColor3=rgb(255,185,0)
                Kb.BackgroundColor3=rgb(28,24,10)
            end)

            -- Right-click → Toggle/Hold/Always + keybind popup
            RowHit.MouseButton2Click:Connect(function()
                openContextPopup({
                    getMode = function() return kbMode end,
                    setMode = function(m) kbMode=m end,
                    getKey  = function() return key end,
                    setKey  = function(k)
                        key=k; Kb.Text=keyName(k)
                    end,
                })
            end)

            local _kbWidgetConn = nil
            local function startListening()
                if _kbWidgetConn then _kbWidgetConn:Disconnect() end
                _kbWidgetConn = UIS.InputBegan:Connect(function(i, gpe)
                    if listen then
                        if gpe then return end
                        if i.KeyCode == Enum.KeyCode.Escape then
                            listen=false
                            NmLbl.TextColor3=C.Tx2
                            Kb.Text=keyName(key); Kb.TextColor3=AC; Kb.BackgroundColor3=C.BgRow
                            return
                        end
                        if i.UserInputType==Enum.UserInputType.Keyboard or isMouseButton(i.UserInputType) then
                            key = isMouseButton(i.UserInputType) and i.UserInputType or i.KeyCode
                            listen=false
                            NmLbl.TextColor3=C.Tx2
                            Kb.Text=keyName(key); Kb.TextColor3=AC; Kb.BackgroundColor3=C.BgRow
                        end
                        return
                    end
                    -- Fire callback based on mode
                    if not gpe and key~=Enum.KeyCode.Unknown then
                        if i.KeyCode==key or i.UserInputType==key then
                            if kbMode=="Toggle" then
                                pcall(cb)
                            elseif kbMode=="Hold" then
                                _holding=true; pcall(cb, true)
                            elseif kbMode=="Always" then
                                pcall(cb)
                            end
                        end
                    end
                end)
            end
            -- Hold release
            UIS.InputEnded:Connect(function(i)
                if kbMode=="Hold" and _holding and (i.KeyCode==key or i.UserInputType==key) then
                    _holding=false; pcall(cb, false)
                end
            end)
            startListening()

            CFGSYS.register(flag, function() return key end, function(k) key=k; Kb.Text=keyName(k) end, "key")
            CFGSYS.register(flag.."__mode", function() return kbMode end, function(v) kbMode=v end, "mode")
            local r={Value=key}
            function r:Set(k) key=k; Kb.Text=keyName(k) end
            function r:Get()  return key end
            return r
        end

        function CAT:_AddButton(o5, parentOverride)
            o5 = o5 or {}
            local parent = parentOverride or getDefault()
            local nm     = o5.Name     or "Button"
            local cb     = o5.Callback or function() end
            local Btn = mk("TextButton",{Size=dim2(1,0,0,25),BackgroundColor3=C.BgGroupH,
                Text=nm,TextColor3=C.Tx1,TextSize=11,Font=MenuFont,
                TextXAlignment=Enum.TextXAlignment.Left,
                AutoButtonColor=false,BorderSizePixel=0,Parent=parent})
            mk("UICorner",{CornerRadius=dim(0,4),Parent=Btn})
            padding(Btn, 0, 0, 0, 8)
            onFont(function(mf,_) Btn.Font=mf end)
            Btn.MouseEnter:Connect(function()       tw(Btn,{BackgroundColor3=C.BgRow,TextColor3=C.Tx0},0.08) end)
            Btn.MouseLeave:Connect(function()       tw(Btn,{BackgroundColor3=C.BgGroupH,TextColor3=C.Tx1},0.1) end)
            Btn.MouseButton1Down:Connect(function() tw(Btn,{BackgroundColor3=AC,TextColor3=C.White},0.05) end)
            Btn.MouseButton1Up:Connect(function()   tw(Btn,{BackgroundColor3=C.BgRow,TextColor3=C.Tx0},0.1) end)
            Btn.MouseButton1Click:Connect(function()
                task.delay(0.16, function() tw(Btn,{BackgroundColor3=C.BgGroupH,TextColor3=C.Tx1},0.12) end)
                pcall(cb)
            end)
            local r={}; function r:SetText(t) Btn.Text=t end; return r
        end

        function CAT:_AddLabel(o5, parentOverride)
            o5 = o5 or {}
            local parent = parentOverride or getDefault()
            local Lbl = mk("TextLabel",{Size=dim2(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
                BackgroundTransparency=1,Text=o5.Text or "",
                TextColor3=o5.Color or C.Tx2,TextSize=o5.Size or 10,
                Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,
                TextWrapped=true,Parent=parent})
            local r={}; function r:Set(t) Lbl.Text=t end; function r:Get() return Lbl.Text end; return r
        end

        function CAT:_AddSeparator(parentOverride)
            local parent = parentOverride or getDefault()
            local sep = mk("Frame",{Size=dim2(1,0,0,1),BackgroundColor3=C.BgGroupH,
                BackgroundTransparency=0.5,Parent=parent})
            mk("UIGradient",{Transparency=NumberSequence.new({
                NumberSequenceKeypoint.new(0,1),
                NumberSequenceKeypoint.new(0.04,0),
                NumberSequenceKeypoint.new(0.96,0),
                NumberSequenceKeypoint.new(1,1)}),Parent=sep})
        end

        function CAT:_AddTextbox(o5, parentOverride)
            o5 = o5 or {}
            local parent = parentOverride or getDefault()
            local nm     = o5.Name     or "Input"
            local flag   = o5.Flag     or autoFlag(nm)
            local cb     = o5.Callback or function() end
            local wrap = mk("Frame",{Size=dim2(1,0,0,42),BackgroundTransparency=1,Parent=parent})
            local NmLbl = mk("TextLabel",{Size=dim2(1,0,0,13),BackgroundTransparency=1,Text=nm,
                TextColor3=C.Tx2,TextSize=9,Font=MenuFont,
                TextXAlignment=Enum.TextXAlignment.Left,Parent=wrap})
            onFont(function(mf,_) NmLbl.Font=mf end)
            local ifrm = mk("Frame",{Size=dim2(1,0,0,23),Position=dim2(0,0,0,15),
                BackgroundColor3=C.BgRow,BorderSizePixel=0,Parent=wrap})
            local tb = mk("TextBox",{Size=dim2(1,-10,1,0),Position=dim2(0,5,0,0),
                BackgroundTransparency=1,PlaceholderText=o5.Placeholder or "type here...",
                Text=o5.Default or "",TextColor3=C.Tx0,PlaceholderColor3=C.Tx2,
                TextSize=10,Font=Enum.Font.Gotham,
                TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false,Parent=ifrm})
            tb.Focused:Connect(function()   tw(ifrm,{BackgroundColor3=C.BgGroupH},0.08) end)
            tb.FocusLost:Connect(function() tw(ifrm,{BackgroundColor3=C.BgRow},0.08); pcall(cb,tb.Text) end)
            CFGSYS.register(flag, function() return tb.Text end, function(v) tb.Text=tostring(v) end, "string")
            local r={}; function r:Set(v) tb.Text=v end; function r:Get() return tb.Text end; return r
        end

        -- Public shortcuts
        function CAT:AddToggle(o5)      return self:_AddToggle(o5)       end
        function CAT:AddSlider(o5)      return self:_AddSlider(o5)       end
        function CAT:AddDropdown(o5)    return self:_AddDropdown(o5)     end
        function CAT:AddColorPicker(o5) return self:_AddColorPicker(o5)  end
        function CAT:AddKeybind(o5)     return self:_AddKeybind(o5)      end
        function CAT:AddButton(o5)      return self:_AddButton(o5)       end
        function CAT:AddLabel(o5)       return self:_AddLabel(o5)        end
        function CAT:AddSeparator()     return self:_AddSeparator()      end
        function CAT:AddTextbox(o5)     return self:_AddTextbox(o5)      end
        function CAT:AddSubTab(label)   return addSubTab(label)          end

        function CAT:AddGroup(title)
            local panel = getDefault()
            local _, Body = mkGroup(panel, title)
            local GRP = {}
            function GRP:AddToggle(o5)      return CAT:_AddToggle(o5, Body)      end
            function GRP:AddSlider(o5)      return CAT:_AddSlider(o5, Body)      end
            function GRP:AddDropdown(o5)    return CAT:_AddDropdown(o5, Body)    end
            function GRP:AddColorPicker(o5) return CAT:_AddColorPicker(o5, Body) end
            function GRP:AddKeybind(o5)     return CAT:_AddKeybind(o5, Body)     end
            function GRP:AddButton(o5)      return CAT:_AddButton(o5, Body)      end
            function GRP:AddLabel(o5)       return CAT:_AddLabel(o5, Body)       end
            function GRP:AddSeparator()     return CAT:_AddSeparator(Body)       end
            function GRP:AddTextbox(o5)     return CAT:_AddTextbox(o5, Body)     end
            return GRP
        end

        if isFirst then task.defer(function() SetActiveTab(catKey) end) end
        return CAT
    end

    -- ═══════════════════════════════════════════════════════════
    -- SETTINGS TAB (pinned)
    -- ═══════════════════════════════════════════════════════════
    local function buildSettings()
        local SetCat = WO:AddCategory("Settings", true)

        -- ── General sub-tab
        local GenPanel = SetCat:AddSubTab("General")

        local function stToggle(lbl, default, onChange)
            local row = mk("Frame",{Size=dim2(1,0,0,26),BackgroundTransparency=1,Parent=GenPanel})
            local TLbl = mk("TextLabel",{Size=dim2(1,-20,1,0),BackgroundTransparency=1,Text=lbl,
                TextColor3=default and C.Tx0 or C.Tx2,TextSize=10,Font=MenuFont,
                TextXAlignment=Enum.TextXAlignment.Left,Parent=row})
            local val = default
            local Box = mk("Frame",{Size=dim2(0,13,0,13),Position=dim2(1,-15,0.5,-6),
                BackgroundColor3=val and AC or C.Toggle,BorderSizePixel=0,Parent=row})
            onAC(function(c) if val then Box.BackgroundColor3=c end end)
            local Hit = mk("TextButton",{Size=dim2(1,0,1,0),BackgroundTransparency=1,
                Text="",AutoButtonColor=false,Parent=row})
            Hit.MouseEnter:Connect(function() if not val then TLbl.TextColor3=C.Tx1 end end)
            Hit.MouseLeave:Connect(function() if not val then TLbl.TextColor3=C.Tx2 end end)
            Hit.MouseButton1Click:Connect(function()
                val=not val
                tw(Box,{BackgroundColor3=val and AC or C.Toggle},0.1)
                TLbl.TextColor3 = val and C.Tx0 or C.Tx2
                pcall(onChange,val)
            end)
        end

        stToggle("Show Watermark", true, function(v)
            ShowWatermark=v; WatermarkFrame.Visible=v
        end)

        stToggle("Anonymizer Mode", false, function(v)
            _anon=v
        end)

        local afkConn = nil
        stToggle("Anti-AFK", false, function(v)
            if v and not afkConn then
                afkConn = LP.Idled:Connect(function()
                    local VU = game:GetService("VirtualUser")
                    VU:CaptureController(); VU:ClickButton2(Vector2.new())
                end)
            elseif not v and afkConn then
                afkConn:Disconnect(); afkConn=nil
            end
        end)

        -- Accent color
        local acRow = mk("Frame",{Size=dim2(1,0,0,24),BackgroundTransparency=1,Parent=GenPanel})
        mk("TextLabel",{Size=dim2(1,-44,1,0),BackgroundTransparency=1,Text="Accent Color",
            TextColor3=C.Tx1,TextSize=10,Font=MenuFont,
            TextXAlignment=Enum.TextXAlignment.Left,Parent=acRow})
        local AcSw = mk("TextButton",{Size=dim2(0,36,0,18),Position=dim2(1,-38,0.5,-9),
            BackgroundColor3=AC,Text="",AutoButtonColor=false,BorderSizePixel=1,Parent=acRow})
        onAC(function(c) AcSw.BackgroundColor3=c end)
        AcSw.MouseButton1Click:Connect(function()
            openColorPicker(AcSw.AbsolutePosition, AcSw.AbsoluteSize.Y,
                function() return AC end, setAC)
        end)

        -- Menu Font
        local FONTS = {"GothamBold","Gotham","Code","Arial","ArialBold","Roboto","Ubuntu","Inconsolata"}
        local fRow = mk("Frame",{Size=dim2(1,0,0,40),BackgroundTransparency=1,Parent=GenPanel})
        mk("TextLabel",{Size=dim2(1,0,0,13),BackgroundTransparency=1,Text="Menu Font",
            TextColor3=C.Tx2,TextSize=9,Font=Enum.Font.Gotham,
            TextXAlignment=Enum.TextXAlignment.Left,Parent=fRow})
        local fHd = mk("TextButton",{Size=dim2(1,0,0,22),Position=dim2(0,0,0,15),
            BackgroundColor3=C.BgRow,Text="",AutoButtonColor=false,BorderSizePixel=0,Parent=fRow})
        local fSelLbl = mk("TextLabel",{Size=dim2(1,-20,1,0),Position=dim2(0,5,0,0),
            BackgroundTransparency=1,Text="GothamBold",TextColor3=C.Tx1,TextSize=10,
            Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,Parent=fHd})
        mk("TextLabel",{Size=dim2(0,14,1,0),Position=dim2(1,-15,0,0),BackgroundTransparency=1,
            Text="▾",TextColor3=C.Tx2,TextSize=9,Font=Enum.Font.Gotham,Parent=fHd})
        local fOpen=false
        fHd.MouseButton1Click:Connect(function()
            fOpen=not fOpen
            if fOpen then
                openOV(function(ov)
                    local ap=fHd.AbsolutePosition; local as=fHd.AbsoluteSize
                    local lh=math.min(#FONTS*22+6,150)
                    local px=math.min(ap.X,SG.AbsoluteSize.X-as.X-10)
                    local py=ap.Y+as.Y+2
                    if py+lh>SG.AbsoluteSize.Y-10 then py=ap.Y-lh-2 end
                    local pan=mk("Frame",{Size=dim2(0,as.X,0,lh),Position=dim2(0,px,0,py),
                        BackgroundColor3=C.BgSideBd,BorderSizePixel=1,ZIndex=220,Parent=ov})
                    local sc=mk("ScrollingFrame",{Size=dim2(1,0,1,0),BackgroundTransparency=1,
                        ScrollBarThickness=2,CanvasSize=dim2(0,0,0,0),ZIndex=221,Parent=pan})
                    local scLL=layout(sc,Enum.FillDirection.Vertical,1); padding(sc,3,3,3,3)
                    autoCanvas(sc,scLL)
                    for _,fn2 in ipairs(FONTS) do
                        local ob=mk("TextButton",{Size=dim2(1,0,0,22),Text=fn2,
                            BackgroundColor3=C.BgRow,TextColor3=C.Tx1,
                            TextSize=10,Font=Enum.Font[fn2] or Enum.Font.GothamBold,
                            AutoButtonColor=false,BorderSizePixel=0,ZIndex=222,Parent=sc})
                        ob.MouseButton1Click:Connect(function()
                            MenuFont=Enum.Font[fn2] or Enum.Font.GothamBold
                            fSelLbl.Text=fn2; fireFont(MenuFont,VisFont)
                            fOpen=false; closeOV()
                        end)
                    end
                end)
            else closeOV() end
        end)

        -- ── Configs sub-tab
        local CfgPanel = SetCat:AddSubTab("Configs")

        local cfgInputRow = mk("Frame",{Size=dim2(1,0,0,24),BackgroundTransparency=1,Parent=CfgPanel})
        local cfgInputFr = mk("Frame",{Size=dim2(1,-68,1,0),BackgroundColor3=C.BgRow,
            BorderSizePixel=0,Parent=cfgInputRow})
        local cfgInput = mk("TextBox",{Size=dim2(1,-8,1,0),Position=dim2(0,4,0,0),
            BackgroundTransparency=1,PlaceholderText="config name...",
            Text="",TextColor3=C.Tx0,PlaceholderColor3=C.Tx2,
            TextSize=10,Font=Enum.Font.Gotham,ClearTextOnFocus=false,Parent=cfgInputFr})
        local cfgNewBtn = mk("TextButton",{Size=dim2(0,60,1,0),Position=dim2(1,-62,0,0),
            BackgroundColor3=AC,Text="+ New",TextColor3=C.White,TextSize=9,
            Font=Enum.Font.GothamBold,AutoButtonColor=false,BorderSizePixel=0,Parent=cfgInputRow})
        onAC(function(c) cfgNewBtn.BackgroundColor3=c end)

        local openDirBtn = mk("TextButton",{Size=dim2(1,0,0,20),BackgroundColor3=C.BgGroupH,
            Text="Open Config Folder",TextColor3=C.Tx1,TextSize=9,Font=Enum.Font.Gotham,
            AutoButtonColor=false,BorderSizePixel=0,Parent=CfgPanel})
        openDirBtn.MouseEnter:Connect(function() tw(openDirBtn,{BackgroundColor3=C.BgRow,TextColor3=C.Tx0},0.08) end)
        openDirBtn.MouseLeave:Connect(function() tw(openDirBtn,{BackgroundColor3=C.BgGroupH,TextColor3=C.Tx1},0.08) end)
        openDirBtn.MouseButton1Click:Connect(function() CFGSYS.openDir() end)

        local cfgListSF = mk("ScrollingFrame",{Size=dim2(1,0,1,-52),Position=dim2(0,0,0,50),
            BackgroundTransparency=1,ScrollBarThickness=2,ScrollBarImageColor3=C.Toggle,
            BorderSizePixel=0,CanvasSize=dim2(0,0,0,0),Parent=CfgPanel})
        local cfgLL = layout(cfgListSF,Enum.FillDirection.Vertical,3)
        autoCanvas(cfgListSF,cfgLL)

        local function refreshCfgList()
            for _,ch in ipairs(cfgListSF:GetChildren()) do
                if not ch:IsA("UIListLayout") then ch:Destroy() end
            end
            local list=CFGSYS.list()
            if #list==0 then
                mk("TextLabel",{Size=dim2(1,0,0,26),BackgroundTransparency=1,
                    Text="No configs yet.",TextColor3=C.Tx2,TextSize=9,
                    Font=Enum.Font.Gotham,TextWrapped=true,Parent=cfgListSF})
                return
            end
            for _,cname in ipairs(list) do
                local isAct=cname==_activeCfgName
                local row2=mk("Frame",{Size=dim2(1,0,0,26),BackgroundColor3=C.BgRow,
                    BorderSizePixel=0,Parent=cfgListSF})
                mk("TextLabel",{Size=dim2(1,-94,1,0),Position=dim2(0,5,0,0),
                    BackgroundTransparency=1,Text=cname..(isAct and " ●" or ""),
                    TextColor3=isAct and AC or C.Tx1,TextSize=9,Font=Enum.Font.Gotham,
                    TextXAlignment=Enum.TextXAlignment.Left,
                    TextTruncate=Enum.TextTruncate.AtEnd,Parent=row2})
                local function smBtn2(txt,xOff,col2,cb2)
                    local b=mk("TextButton",{Size=dim2(0,26,0,18),Position=dim2(1,xOff,0.5,-9),
                        BackgroundColor3=col2,Text=txt,TextColor3=C.Tx0,
                        TextSize=8,Font=Enum.Font.GothamBold,
                        AutoButtonColor=false,BorderSizePixel=0,Parent=row2})
                    b.MouseButton1Click:Connect(cb2)
                end
                smBtn2("L",-86,rgb(28,70,45),function()
                    if CFGSYS.load(cname) then
                        _activeCfgName=cname
                        notify({Title="Loaded",Desc=cname,Type="Success",Duration=2})
                        refreshCfgList()
                    else notify({Title="Load Failed",Desc=cname,Type="Error",Duration=2}) end
                end)
                smBtn2("S",-56,rgb(28,45,70),function()
                    if CFGSYS.save(cname) then notify({Title="Saved",Desc=cname,Type="Success",Duration=2})
                    else notify({Title="Save Failed",Type="Error",Duration=2}) end
                end)
                smBtn2("X",-26,rgb(70,28,28),function()
                    CFGSYS.delete(cname); refreshCfgList()
                    notify({Title="Deleted",Desc=cname,Type="Warning",Duration=2})
                end)
            end
        end

        cfgNewBtn.MouseButton1Click:Connect(function()
            local cname=cfgInput.Text~="" and cfgInput.Text or ("Config"..tostring(#CFGSYS.list()+1))
            cname=cname:gsub("[^%w%-%_]","_"); cfgInput.Text=""
            if CFGSYS.save(cname) then
                _activeCfgName=cname
                notify({Title="Config Created",Desc=cname,Type="Success",Duration=2})
                refreshCfgList()
            else notify({Title="Create Failed",Type="Error",Duration=3}) end
        end)

        task.defer(refreshCfgList)
    end

    -- ═══════════════════════════════════════════════════════════
    -- PLAYER LIST TAB (pinned at bottom)
    -- ═══════════════════════════════════════════════════════════
    local function buildPlayerList()
        local PlCat   = WO:AddCategory("Players", true)
        local PlPanel = PlCat:AddSubTab("Players")

        -- Stick-to and spectate state
        local _stickConn     = nil
        local _stickTarget   = nil
        local _spectating    = false
        local _specConn      = nil

        -- Unit toggle header
        local useMeter = false
        local hdrRow = mk("Frame",{Size=dim2(1,0,0,22),BackgroundTransparency=1,Parent=PlPanel})
        mk("TextLabel",{Size=dim2(1,-80,1,0),BackgroundTransparency=1,Text="Players",
            TextColor3=C.Tx2,TextSize=9,Font=Enum.Font.Gotham,
            TextXAlignment=Enum.TextXAlignment.Left,Parent=hdrRow})
        local unitBtn = mk("TextButton",{Size=dim2(0,72,1,0),Position=dim2(1,-74,0,0),
            BackgroundColor3=C.BgRow,Text="Studs",TextColor3=AC,TextSize=9,
            Font=Enum.Font.GothamBold,AutoButtonColor=false,BorderSizePixel=0,Parent=hdrRow})
        onAC(function(c) unitBtn.TextColor3=c end)
        unitBtn.MouseButton1Click:Connect(function()
            useMeter=not useMeter; unitBtn.Text=useMeter and "Meters" or "Studs"
        end)
        mk("Frame",{Size=dim2(1,0,0,1),BackgroundColor3=C.BgGroupH,Parent=PlPanel})

        local plScroll = mk("ScrollingFrame",{Size=dim2(1,0,1,-30),
            BackgroundTransparency=1,ScrollBarThickness=2,ScrollBarImageColor3=C.Toggle,
            CanvasSize=dim2(0,0,0,0),BorderSizePixel=0,Parent=PlPanel})
        local plLL = layout(plScroll,Enum.FillDirection.Vertical,2)
        autoCanvas(plScroll,plLL)

        -- Helper: small action button inside a player card
        local function mkActionBtn(parent, txt, col, xPos, w, cb2)
            local b = mk("TextButton",{Size=dim2(0,w or 48,0,18),Position=xPos,
                BackgroundColor3=col,Text=txt,TextColor3=C.White,TextSize=8,
                Font=Enum.Font.GothamBold,AutoButtonColor=false,BorderSizePixel=0,Parent=parent})
            b.MouseButton1Click:Connect(function() pcall(cb2) end)
            return b
        end

        local plRows  = {}
        local expanded = {}   -- uid → bool

        local function buildCard(p)
            -- Outer container (auto-sizes based on expanded state)
            local card = mk("Frame",{Size=dim2(1,0,0,32),BackgroundColor3=C.BgRow,
                BorderSizePixel=0,Parent=plScroll})

            -- ── Header row (always visible)
            local hdr = mk("Frame",{Size=dim2(1,0,0,32),BackgroundTransparency=1,Parent=card})
            mk("ImageLabel",{Size=dim2(0,24,0,24),Position=dim2(0,2,0,4),
                BackgroundColor3=C.BgGroupH,BorderSizePixel=0,
                Image="https://www.roblox.com/headshot-thumbnail/image?userId="..p.UserId.."&width=48&height=48&format=png",
                Parent=hdr})
            mk("TextLabel",{Size=dim2(0.45,0,0,13),Position=dim2(0,30,0,4),
                BackgroundTransparency=1,Text=p.DisplayName,TextColor3=C.Tx0,TextSize=10,
                Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,
                TextTruncate=Enum.TextTruncate.AtEnd,Parent=hdr})
            mk("TextLabel",{Size=dim2(0.45,0,0,11),Position=dim2(0,30,0,18),
                BackgroundTransparency=1,Text="@"..p.Name,TextColor3=C.TxSub,TextSize=8,
                Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,
                TextTruncate=Enum.TextTruncate.AtEnd,Parent=hdr})
            local distLbl = mk("TextLabel",{Size=dim2(0,50,0,13),Position=dim2(1,-82,0,4),
                BackgroundTransparency=1,Text="?",TextColor3=C.Tx2,TextSize=9,
                Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Right,Parent=hdr})
            local arrow = mk("TextLabel",{Size=dim2(0,14,0,14),Position=dim2(1,-16,0,9),
                BackgroundTransparency=1,Text="▸",TextColor3=C.Tx2,TextSize=9,
                Font=Enum.Font.GothamBold,Parent=hdr})

            -- ── Expanded panel (hidden by default)
            local expPanel = mk("Frame",{Size=dim2(1,0,0,0),Position=dim2(0,0,0,32),
                BackgroundColor3=C.BgGroup,BorderSizePixel=0,Visible=false,Parent=card})

            -- Account info section (3 lines: username, age, premium)
            local infoFr = mk("Frame",{Size=dim2(1,0,0,42),BackgroundTransparency=1,Parent=expPanel})
            padding(infoFr,3,6,0,6)
            local function infoLine(y,label,value)
                mk("TextLabel",{Size=dim2(0.42,0,0,11),Position=dim2(0,0,0,y),
                    BackgroundTransparency=1,Text=label,TextColor3=C.Tx2,TextSize=9,
                    Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,Parent=infoFr})
                mk("TextLabel",{Size=dim2(0.58,0,0,11),Position=dim2(0.42,0,0,y),
                    BackgroundTransparency=1,Text=value,TextColor3=C.Tx0,TextSize=9,
                    Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,
                    TextTruncate=Enum.TextTruncate.AtEnd,Parent=infoFr})
            end
            local premium = p.MembershipType == Enum.MembershipType.Premium and "Yes ★" or "No"
            local ageDays  = tostring(p.AccountAge).."d"
            infoLine(3,  "Username:", "@"..p.Name)
            infoLine(16, "Acct Age:", ageDays)
            infoLine(29, "Premium:",  premium)

            -- Separator
            mk("Frame",{Size=dim2(1,-10,0,1),Position=dim2(0,5,0,46),
                BackgroundColor3=C.BgGroupH,BorderSizePixel=0,Parent=expPanel})

            -- Action buttons row
            local actFr = mk("Frame",{Size=dim2(1,0,0,26),Position=dim2(0,0,0,49),
                BackgroundTransparency=1,Parent=expPanel})
            padding(actFr,0,4,0,4)

            -- Teleport To
            mkActionBtn(actFr,"TP TO",rgb(30,60,100),dim2(0,0,0.5,-9),40,function()
                local myChar   = LP.Character
                local tgtChar  = p.Character
                if not myChar or not tgtChar then return end
                local myRoot  = myChar:FindFirstChild("HumanoidRootPart")
                local tgtRoot = tgtChar:FindFirstChild("HumanoidRootPart")
                if myRoot and tgtRoot then
                    myRoot.CFrame = tgtRoot.CFrame + Vector3.new(3,0,0)
                end
            end)
            -- Spectate
            mkActionBtn(actFr,"SPEC",rgb(60,30,100),dim2(0,44,0.5,-9),38,function()
                local ws = game:GetService("Workspace")
                if _spectating and _specConn then
                    _specConn:Disconnect(); _specConn=nil; _spectating=false
                    ws.CurrentCamera.CameraSubject = LP.Character and
                        LP.Character:FindFirstChildOfClass("Humanoid") or nil
                else
                    _spectating = true
                    local function updateSpec()
                        local ch = p.Character
                        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
                        if hum then ws.CurrentCamera.CameraSubject = hum end
                    end
                    updateSpec()
                    _specConn = RunService.Heartbeat:Connect(updateSpec)
                end
            end)
            -- Stick To
            mkActionBtn(actFr,"STICK",rgb(80,50,20),dim2(0,86,0.5,-9),40,function()
                if _stickTarget == p.UserId then
                    if _stickConn then _stickConn:Disconnect(); _stickConn=nil end
                    _stickTarget=nil
                else
                    if _stickConn then _stickConn:Disconnect() end
                    _stickTarget = p.UserId
                    _stickConn = RunService.Heartbeat:Connect(function()
                        local myChar  = LP.Character
                        local tgtChar = p.Character
                        if not myChar or not tgtChar then return end
                        local myRoot  = myChar:FindFirstChild("HumanoidRootPart")
                        local tgtRoot = tgtChar:FindFirstChild("HumanoidRootPart")
                        if myRoot and tgtRoot then
                            myRoot.CFrame = tgtRoot.CFrame * CFrame.new(3,0,0)
                        end
                    end)
                end
            end)
            -- Mark Friend
            mkActionBtn(actFr,"FRIEND",rgb(20,80,40),dim2(0,130,0.5,-9),46,function()
                game:GetService("SocialService"):PromptSendFriendRequest(LP, p)
            end)

            expPanel.Size = dim2(1,0,0,77)

            -- Toggle expand
            local function setExpanded(isExp)
                expanded[p.UserId] = isExp
                expPanel.Visible   = isExp
                card.Size = dim2(1,0,0, isExp and 32+77 or 32)
                arrow.Text = isExp and "▾" or "▸"
            end

            local hdrBtn = mk("TextButton",{Size=dim2(1,0,1,0),BackgroundTransparency=1,
                Text="",AutoButtonColor=false,Parent=hdr})
            hdrBtn.MouseButton1Click:Connect(function()
                setExpanded(not expanded[p.UserId])
            end)

            return {frame=card, distLbl=distLbl, player=p}
        end

        local function refreshPlayers()
            -- Remove rows for players who left
            for uid,info in pairs(plRows) do
                if not Players:GetPlayerByUserId(uid) then
                    pcall(function() info.frame:Destroy() end); plRows[uid]=nil
                end
            end
            -- Add rows for new players
            for _,p in ipairs(Players:GetPlayers()) do
                if not plRows[p.UserId] and p ~= LP then
                    plRows[p.UserId] = buildCard(p)
                end
            end
        end

        -- Distance update loop
        local distTick = 0
        RunService.Heartbeat:Connect(function(dt)
            distTick = distTick + dt
            if distTick < 0.4 then return end
            distTick = 0
            pcall(function()
                local lpChar = LP.Character
                local lpRoot = lpChar and lpChar:FindFirstChild("HumanoidRootPart")
                for _,info in pairs(plRows) do
                    local ch   = info.player.Character
                    local root = ch and ch:FindFirstChild("HumanoidRootPart")
                    if root and lpRoot then
                        local d = (root.Position - lpRoot.Position).Magnitude
                        info.distLbl.Text = useMeter
                            and string.format("%.1fm", d*0.28)
                            or  string.format("%.0fst", d)
                    else
                        info.distLbl.Text = "N/A"
                    end
                end
            end)
        end)

        Players.PlayerAdded:Connect(function()
            task.wait(0.5); refreshPlayers()
        end)
        Players.PlayerRemoving:Connect(function(p)
            task.wait(0.1)
            if plRows[p.UserId] then
                pcall(function() plRows[p.UserId].frame:Destroy() end)
                plRows[p.UserId] = nil
            end
        end)

        task.defer(refreshPlayers)
    end

    -- ═══════════════════════════════════════════════════════════════
    -- TARGET HUD
    -- Always visible when GUI open.
    -- When GUI closed: only visible while a target is set.
    -- API: WO:SetTarget(player or nil)
    -- ═══════════════════════════════════════════════════════════════
    do
        local HUD_W, HUD_H = 220, 62
        local _hudTarget  = nil
        local _hudEnabled = true  -- can be toggled via WO:SetHudEnabled()

        local HudFrame = mk("Frame", {
            Size=dim2(0,HUD_W,0,HUD_H),
            Position=dim2(1,-HUD_W-8,0,34),
            BackgroundColor3=rgb(12,14,17),
            BorderSizePixel=0, Visible=false, Parent=SG,
        })
        mk("UICorner",{CornerRadius=dim(0,4),Parent=HudFrame})
        -- 1px left accent bar
        local HudBar = mk("Frame",{Size=dim2(0,2,1,0),BackgroundColor3=AC,BorderSizePixel=0,Parent=HudFrame})
        onAC(function(c) HudBar.BackgroundColor3=c end)

        -- Character thumbnail (HRP headshot)
        local HudThumb = mk("ImageLabel",{
            Size=dim2(0,42,0,42), Position=dim2(0,8,0,10),
            BackgroundColor3=rgb(20,24,28), BorderSizePixel=0,
            Image="", Parent=HudFrame,
        })
        mk("UICorner",{CornerRadius=dim(0,3),Parent=HudThumb})

        -- Name label
        local HudName = mk("TextLabel",{
            Size=dim2(1,-62,0,13), Position=dim2(0,56,0,6),
            BackgroundTransparency=1, Text="--",
            TextColor3=C.Tx0, TextSize=11, Font=Enum.Font.GothamBold,
            TextXAlignment=Enum.TextXAlignment.Left,
            TextTruncate=Enum.TextTruncate.AtEnd, Parent=HudFrame,
        })

        -- Health bar bg
        local HudHpBg = mk("Frame",{
            Size=dim2(1,-62,0,4), Position=dim2(0,56,0,22),
            BackgroundColor3=rgb(30,35,40), BorderSizePixel=0, Parent=HudFrame,
        })
        mk("UICorner",{CornerRadius=dim(0,2),Parent=HudHpBg})
        local HudHpFill = mk("Frame",{
            Size=dim2(1,0,1,0), BackgroundColor3=rgb(50,200,100),
            BorderSizePixel=0, Parent=HudHpBg,
        })
        mk("UICorner",{CornerRadius=dim(0,2),Parent=HudHpFill})

        -- Distance label
        local HudDist = mk("TextLabel",{
            Size=dim2(0.5,-4,0,11), Position=dim2(0,56,0,29),
            BackgroundTransparency=1, Text="? st",
            TextColor3=C.Tx2, TextSize=9, Font=Enum.Font.Code,
            TextXAlignment=Enum.TextXAlignment.Left, Parent=HudFrame,
        })

        -- Looking-at label
        local HudLook = mk("TextLabel",{
            Size=dim2(1,-62,0,11), Position=dim2(0,56,0,43),
            BackgroundTransparency=1, Text="not looking",
            TextColor3=C.Tx2, TextSize=9, Font=Enum.Font.Code,
            TextXAlignment=Enum.TextXAlignment.Left, Parent=HudFrame,
        })

        -- HUD drag — only while GUI is open
        do
            local _hd, _hds, _hsp = false, nil, nil
            local HudHit = mk("TextButton",{Size=dim2(1,0,1,0),BackgroundTransparency=1,
                Text="",BorderSizePixel=0,ZIndex=5,Parent=HudFrame})
            HudHit.InputBegan:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 and Main.Visible then
                    _hd=true; _hds=i.Position; _hsp=HudFrame.Position
                end
            end)
            UIS.InputChanged:Connect(function(i)
                if _hd and i.UserInputType==Enum.UserInputType.MouseMovement then
                    local d=i.Position-_hds
                    HudFrame.Position=dim2(_hsp.X.Scale,_hsp.X.Offset+d.X,_hsp.Y.Scale,_hsp.Y.Offset+d.Y)
                end
            end)
            UIS.InputEnded:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 then _hd=false end
            end)
        end

        local _lastThumbId = -1
        local _hudUseMeter = false

        local function hudUpdateVisibility()
            if not _hudEnabled then
                HudFrame.Visible = false; return
            end
            if Main.Visible then
                HudFrame.Visible = true
            else
                HudFrame.Visible = _hudTarget ~= nil
            end
        end

        -- Hook main visibility toggle to refresh HUD
        function WO:Toggle()
            _vis = not _vis; Main.Visible = _vis
            hudUpdateVisibility()
        end
        UIS.InputBegan:Connect(function(i, gpe)
            if not gpe and i.KeyCode == KEY then
                hudUpdateVisibility()
            end
        end)

        local function computeLookAt(tgtChar)
            -- Returns 0..1 probability that target is looking at local player
            local lpChar = LP.Character
            if not tgtChar or not lpChar then return 0 end
            local tgtHead = tgtChar:FindFirstChild("Head")
            local lpRoot  = lpChar:FindFirstChild("HumanoidRootPart")
            if not tgtHead or not lpRoot then return 0 end
            local tgtLook = tgtHead.CFrame.LookVector
            local toLP    = (lpRoot.Position - tgtHead.Position).Unit
            local dot     = tgtLook:Dot(toLP)  -- -1..1
            return math.clamp((dot + 1) / 2, 0, 1)  -- remap to 0..1
        end

        RunService.Heartbeat:Connect(function()
            pcall(function()
                hudUpdateVisibility()
                if not HudFrame.Visible then return end

                if not _hudTarget then
                    HudName.Text  = "No Target"
                    HudDist.Text  = "--"
                    HudLook.Text  = "--"
                    HudHpFill.Size = dim2(0,0,1,0)
                    HudThumb.Image = ""
                    return
                end

                -- Thumbnail (update when player changes)
                if _hudTarget.UserId ~= _lastThumbId then
                    _lastThumbId = _hudTarget.UserId
                    HudThumb.Image = "https://www.roblox.com/headshot-thumbnail/image?userId="
                        .._hudTarget.UserId.."&width=48&height=48&format=png"
                    HudName.Text = _hudTarget.DisplayName
                end

                local tgtChar  = _hudTarget.Character
                local tgtHum   = tgtChar and tgtChar:FindFirstChildOfClass("Humanoid")
                local tgtRoot  = tgtChar and tgtChar:FindFirstChild("HumanoidRootPart")
                local lpChar   = LP.Character
                local lpRoot   = lpChar and lpChar:FindFirstChild("HumanoidRootPart")

                -- Health bar
                if tgtHum then
                    local maxHp = math.max(tgtHum.MaxHealth, 1)
                    local pct   = math.clamp(tgtHum.Health / maxHp, 0, 1)
                    HudHpFill.Size = dim2(pct,0,1,0)
                    -- color: green → yellow → red
                    local r = math.floor(math.clamp(2*(1-pct),0,1)*200)
                    local g = math.floor(math.clamp(2*pct,0,1)*200)
                    HudHpFill.BackgroundColor3 = rgb(r+55, g+55, 55)
                else
                    HudHpFill.Size = dim2(0,0,1,0)
                end

                -- Distance
                if tgtRoot and lpRoot then
                    local d = (tgtRoot.Position - lpRoot.Position).Magnitude
                    if _hudUseMeter then
                        HudDist.Text = string.format("%.1f m", d*0.28)
                    else
                        HudDist.Text = string.format("%.0f st", d)
                    end
                else
                    HudDist.Text = "N/A"
                end

                -- Looking-at probability
                local prob = computeLookAt(tgtChar)
                local pct2 = math.floor(prob * 100)
                if prob >= 0.92 then
                    HudLook.Text  = "Looking at you!"
                    HudLook.TextColor3 = rgb(255,80,80)
                elseif prob >= 0.65 then
                    HudLook.Text  = "Watching ("..pct2.."%)"
                    HudLook.TextColor3 = rgb(255,185,0)
                else
                    HudLook.Text  = "Not looking ("..pct2.."%)"
                    HudLook.TextColor3 = C.Tx2
                end
            end)
        end)

        function WO:SetTarget(player)
            _hudTarget = player
            if player == nil then
                _lastThumbId = -1
                HudName.Text = "No Target"
                HudDist.Text = "--"
                HudLook.Text = "--"
                HudHpFill.Size = dim2(0,0,1,0)
                HudThumb.Image = ""
            end
            hudUpdateVisibility()
        end

        function WO:GetTarget()
            return _hudTarget
        end

        function WO:SetHudUnit(useMeters)
            _hudUseMeter = useMeters
        end

        function WO:SetHudEnabled(v)
            _hudEnabled = v
            hudUpdateVisibility()
        end

        function WO:IsHudEnabled()
            return _hudEnabled
        end
    end

    -- Build pinned tabs after user categories register
    task.defer(function()
        buildSettings()
        buildPlayerList()
    end)

    -- Animate in
    task.defer(function()
        Main.Visible = true
        Main.Size    = dim2(0, WIN_W*0.9, 0, WIN_H*0.9)
        tw(Main, {Size=dim2(0,WIN_W,0,WIN_H)}, 0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    end)

    return WO
end

return Peleccos
