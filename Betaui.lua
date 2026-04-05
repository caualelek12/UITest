--[[
╔══════════════════════════════════════════════════════════════════╗
║           PELECCOS SOFTWARES  v12.0  - NEW DESIGN               ║
╠══════════════════════════════════════════════════════════════════╣
║  LAYOUT (matches GUI-to-Lua design):                            ║
║    TOP BAR: EasterEGG btn | scrollable categories | Settings   ║
║    BACKGROUND: full image panel                                  ║
║    WATERMARK: draggable, shows all info                         ║
║                                                                  ║
║  Win:AddCategory("Name")       → scrollable top bar category   ║
║  Cat:AddButton(opts)                                            ║
║  Cat:AddToggle(opts)                                            ║
║  Cat:AddSlider(opts)                                            ║
║  Cat:AddLabel(opts)                                             ║
╚══════════════════════════════════════════════════════════════════╝

USAGE EXAMPLE:
    local Lib = loadstring(game:HttpGet("..."))()
    local Win = Lib:CreateWindow({
        Title       = "My Script",
        Background  = "rbxassetid://118298630077545",
        UserName    = "Player",
        ConfigName  = "Default",
        BuildType   = "Beta",
        AccentColor = Color3.fromRGB(80, 80, 92),
        Key         = Enum.KeyCode.Insert,
    })

    local Cat = Win:AddCategory("Combat")
    Cat:AddToggle({ Name = "Aimbot", Default = false, Callback = function(v) end })
    Cat:AddSlider({ Name = "FOV", Min = 0, Max = 360, Step = 1, Default = 90, Callback = function(v) end })
    Cat:AddButton({ Name = "Teleport", Callback = function() end })
    Cat:AddLabel({ Text = "Version 1.0" })
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
local _FOLDER = "PeleccosSoftwares"
pcall(function() if not isfolder(_FOLDER) then makefolder(_FOLDER) end end)
pcall(function()
    if not isfolder(_FOLDER.."/videos") then makefolder(_FOLDER.."/videos") end
end)

-- ═══════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════
local function tw(o, p, t, s, d)
    TweenService:Create(o, TweenInfo.new(t or .15, s or Enum.EasingStyle.Quart, d or Enum.EasingDirection.Out), p):Play()
end

local function new(cls, props)
    local o = Instance.new(cls)
    for k, v in pairs(props or {}) do if k ~= "Parent" then o[k] = v end end
    if props and props.Parent then o.Parent = props.Parent end
    return o
end

local function cor(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = r or UDim.new(0, 6)
    c.Parent = p
    return c
end

local function str(p, col, t)
    local s = Instance.new("UIStroke")
    s.Color = col or Color3.fromRGB(60, 60, 60)
    s.Thickness = t or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = p
    return s
end

local function pad(p, t, r, b, l)
    local u = Instance.new("UIPadding")
    u.PaddingTop    = UDim.new(0, t or 0)
    u.PaddingRight  = UDim.new(0, r or 0)
    u.PaddingBottom = UDim.new(0, b or 0)
    u.PaddingLeft   = UDim.new(0, l or 0)
    u.Parent = p
    return u
end

local function lst(p, dir, gap, ha, va)
    local l = Instance.new("UIListLayout")
    l.FillDirection      = dir or Enum.FillDirection.Vertical
    l.Padding            = UDim.new(0, gap or 0)
    l.HorizontalAlignment = ha or Enum.HorizontalAlignment.Left
    l.VerticalAlignment   = va or Enum.VerticalAlignment.Top
    l.SortOrder          = Enum.SortOrder.LayoutOrder
    l.Parent = p
    return l
end

local function drag(frame, handle)
    local dragging, dragStart, startPos = false, nil, nil
    handle = handle or frame
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = i.Position; startPos = frame.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = i.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                       startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- COLOR CONSTANTS (matching original dark theme)
-- ═══════════════════════════════════════════════════════════════
local C = {
    Bar      = Color3.fromRGB(0, 0, 0),        -- top bar (semi transparent)
    BtnBg    = Color3.fromRGB(55, 55, 55),      -- button bg
    BtnHover = Color3.fromRGB(75, 75, 75),
    BtnStroke= Color3.fromRGB(31, 31, 31),
    BgFrame  = Color3.fromRGB(35, 35, 35),      -- background border frame
    TextOn   = Color3.fromRGB(255, 255, 255),
    TextSub  = Color3.fromRGB(180, 180, 180),
    TextMuted= Color3.fromRGB(100, 100, 100),
    TrackOff = Color3.fromRGB(45, 45, 45),
    Input    = Color3.fromRGB(30, 30, 30),
    SliderBg = Color3.fromRGB(40, 40, 40),
    Dropdown = Color3.fromRGB(28, 28, 28),
    Separator= Color3.fromRGB(60, 60, 60),
    Notif    = Color3.fromRGB(24, 24, 24),
}

-- ═══════════════════════════════════════════════════════════════
-- NOTIFICATION SYSTEM
-- ═══════════════════════════════════════════════════════════════
local _NH
local NC = {
    Success = Color3.fromRGB(50, 200, 100),
    Warning = Color3.fromRGB(255, 185, 0),
    Error   = Color3.fromRGB(255, 65, 65),
    Info    = Color3.fromRGB(0, 135, 255),
}
local function initNotifs(sg)
    _NH = new("Frame", {
        Size = UDim2.new(0, 300, 1, 0),
        Position = UDim2.new(1, -310, 0, 0),
        BackgroundTransparency = 1,
        ZIndex = 400,
        Parent = sg,
    })
    lst(_NH, Enum.FillDirection.Vertical, 8)
    pad(_NH, 12, 0, 12, 0)
end

local function notify(o)
    if not _NH then return end
    o = o or {}
    local ac = NC[o.Type or "Info"] or NC.Info
    local card = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = C.Notif,
        BackgroundTransparency = 1,
        Position = UDim2.new(1.3, 0, 0, 0),
        ZIndex = 401,
        Parent = _NH,
    })
    cor(card, UDim.new(0, 10))
    str(card, Color3.fromRGB(50, 50, 50))
    local bar = new("Frame", { Size = UDim2.new(0, 4, 1, 0), BackgroundColor3 = ac, ZIndex = 402, Parent = card })
    cor(bar, UDim.new(0, 4))
    local inn = new("Frame", {
        Size = UDim2.new(1, -4, 1, 0),
        Position = UDim2.new(0, 4, 0, 0),
        BackgroundTransparency = 1,
        ZIndex = 402,
        Parent = card,
    })
    pad(inn, 8, 8, 8, 8)
    lst(inn, Enum.FillDirection.Vertical, 4)
    local icons = { Success = "✓", Warning = "⚠", Error = "✕", Info = "i" }
    local row = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, ZIndex = 403, Parent = inn })
    lst(row, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
    local ico = new("TextLabel", { Text = icons[o.Type or "Info"] or "i", Size = UDim2.new(0, 16, 0, 16), BackgroundColor3 = ac, TextColor3 = C.TextOn, TextSize = 10, Font = Enum.Font.GothamBold, ZIndex = 403, Parent = row })
    cor(ico, UDim.new(0, 8))
    new("TextLabel", { Text = o.Title or "Notice", Size = UDim2.new(1, -22, 0, 16), BackgroundTransparency = 1, TextColor3 = C.TextOn, TextSize = 13, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 403, Parent = row })
    if o.Desc and o.Desc ~= "" then
        new("TextLabel", { Text = o.Desc, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(145, 145, 158), TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, ZIndex = 403, Parent = inn })
    end
    tw(card, { BackgroundTransparency = 0, Position = UDim2.new(0, 0, 0, 0) }, .3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    local dur = o.Duration or 4
    task.delay(dur, function()
        tw(card, { BackgroundTransparency = 1, Position = UDim2.new(1.3, 0, 0, 0) }, .22)
        task.wait(.25)
        card:Destroy()
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- FPS / PING UTIL
-- ═══════════════════════════════════════════════════════════════
local _fps, _ping = 60, 0
RunService.Heartbeat:Connect(function(dt)
    _fps = math.floor(1 / dt)
end)
task.spawn(function()
    while true do
        local s = tick()
        pcall(function() game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() end)
        _ping = math.floor((tick() - s) * 1000)
        task.wait(2)
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- EASTER EGG VIDEOS
-- ═══════════════════════════════════════════════════════════════
local EASTER_VIDEOS = {
    { id = "MUwoJJNAwhI", loop = false, audioOnly = false },
    { id = "pKBTU3jTUQU", loop = false, audioOnly = false },
    { id = "KcrtcnvkcWQ", loop = true,  audioOnly = false },
    { id = "HnH1MgwJFvY", loop = false, audioOnly = false },
    { id = "igmpRziaOqc", loop = false, audioOnly = false },
    { id = "I0lA3rHbFuE", loop = false, audioOnly = true  },
    { id = "u-fOF9Wlpd8", loop = false, audioOnly = false },
    { id = "PHvhOPM_5ak", loop = true,  audioOnly = false },
    { id = "Fy69pNzf9iE", loop = false, audioOnly = false },
    { id = "7xO4u-lzsYU", loop = false, audioOnly = false },
    { id = "WnOWVSYNMFw", loop = false, audioOnly = false },
    { id = "1L1WkeRR-EQ", loop = true,  audioOnly = false },
    { id = "NoR9zrJiSLc", loop = false, audioOnly = false },
    { id = "JabG22Zl02I", loop = false, audioOnly = false },
    { id = "YmHZI03a_Yo", loop = false, audioOnly = false },
    { id = "mHJ3l18YqNM", loop = false, audioOnly = false },
}

-- Easter egg keyword detection
local EASTER_KEYWORDS = {
    "peleccos", "easter", "egg", "secret", "hidden",
    "password", "cheat", "hack", "admin", "god",
    "infinite", "unlimited", "special", "rare", "legendary",
}

-- ═══════════════════════════════════════════════════════════════
-- MAIN LIBRARY
-- ═══════════════════════════════════════════════════════════════
local Peleccos = {}
Peleccos.__index = Peleccos

function Peleccos:CreateWindow(o)
    o = o or {}

    -- cleanup old instance
    pcall(function()
        local pg = LP:FindFirstChild("PlayerGui")
        if pg then local x = pg:FindFirstChild("PeleccosV12") if x then x:Destroy() end end
    end)
    pcall(function()
        local cg = game:GetService("CoreGui")
        local x = cg:FindFirstChild("PeleccosV12") if x then x:Destroy() end
    end)

    local AC = o.AccentColor or Color3.fromRGB(80, 80, 92)
    local _acCBs = {}
    local function onAC(fn) table.insert(_acCBs, fn) end
    local function applyAC()
        for _, fn in pairs(_acCBs) do pcall(fn, AC) end
    end

    local KEY = o.Key or Enum.KeyCode.Insert
    local BG_IMAGE = o.Background or "rbxassetid://118298630077545"

    -- config for watermark/settings
    local CFG = {
        ScriptName = o.Title       or "PeleccosSoftwares",
        UserName   = o.UserName    or (LP and LP.Name or "User"),
        ConfigName = o.ConfigName  or "Default",
        BuildType  = o.BuildType   or "Public",
        GameName   = o.GameName    or (game.Name or "Unknown"),
        GameId     = o.GameId      or tostring(game.GameId or 0),
        BgColor    = o.BgColor     or Color3.fromRGB(35, 35, 35),
    }

    -- ── ScreenGui ────────────────────────────────────────────────
    local SG = new("ScreenGui", {
        Name            = "PeleccosV12",
        ResetOnSpawn    = false,
        ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
    })
    local ok = pcall(function()
        SG.Parent = game:GetService("CoreGui")
    end)
    if not ok then
        SG.Parent = LP:WaitForChild("PlayerGui")
    end

    initNotifs(SG)

    -- ── Background Frame (matches GUI-to-Lua exactly) ─────────────
    local BG = new("Frame", {
        Name            = "Background",
        ZIndex          = 2,
        BorderSizePixel = 0,
        BackgroundColor3 = CFG.BgColor,
        Size            = UDim2.new(0.32558, 0, 0.85044, 0),
        Position        = UDim2.new(0.35349, 0, 0.1076, 0),
        Parent          = SG,
    })

    local BG_IMG = new("ImageLabel", {
        Name            = "Image",
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        AnchorPoint     = Vector2.new(0.5, 0.5),
        Image           = BG_IMAGE,
        Size            = UDim2.new(0.98058, 0, 0.97555, 0),
        Position        = UDim2.new(0.5, 0, 0.5, 0),
        Parent          = BG,
    })
    cor(BG_IMG, UDim.new(0.015, 0))

    -- Dark overlay on image so elements are readable
    local overlay = new("Frame", {
        Size            = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.45,
        ZIndex          = 3,
        Parent          = BG_IMG,
    })
    cor(overlay, UDim.new(0.015, 0))

    -- Content panel ON TOP of image
    local CONTENT = new("ScrollingFrame", {
        Size            = UDim2.new(0.96, 0, 0.93, 0),
        Position        = UDim2.new(0.02, 0, 0.04, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = AC,
        CanvasSize      = UDim2.new(0, 0, 0, 0),
        ZIndex          = 5,
        Parent          = BG_IMG,
    })
    onAC(function(c) CONTENT.ScrollBarImageColor3 = c end)

    local contentList = lst(CONTENT, Enum.FillDirection.Vertical, 10)
    pad(CONTENT, 8, 4, 8, 4)

    -- auto canvas size
    contentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        task.defer(function()
            if CONTENT and CONTENT.Parent then
                CONTENT.CanvasSize = UDim2.new(0, 0, 0, contentList.AbsoluteContentSize.Y + 20)
            end
        end)
    end)

    -- ── TOP BAR (matches GUI-to-Lua: Bar) ─────────────────────────
    local BAR = new("Frame", {
        Name            = "Bar",
        BorderSizePixel = 0,
        BackgroundColor3 = C.Bar,
        BackgroundTransparency = 0.3,
        Size            = UDim2.new(1, 0, 0.03791, 0),
        ZIndex          = 10,
        Parent          = SG,
    })

    -- EasterEGG button (left) - matches original
    local EGG_BTN = new("TextButton", {
        Name            = "EasterEGG",
        Text            = "🥚 Easter Egg",
        TextColor3      = C.TextOn,
        TextSize        = 13,
        Font            = Enum.Font.GothamBold,
        BorderSizePixel = 0,
        BackgroundColor3 = C.BtnBg,
        Size            = UDim2.new(0, 110, 0.96, 0),
        Position        = UDim2.new(0, 0, 0.02, 0),
        AutoButtonColor = false,
        ZIndex          = 11,
        Visible         = false, -- hidden until keyword detected
        Parent          = BAR,
    })
    cor(EGG_BTN, UDim.new(0, 4))
    local eggStroke = str(EGG_BTN, C.BtnStroke, 2)
    EGG_BTN.MouseEnter:Connect(function() tw(EGG_BTN, { BackgroundColor3 = C.BtnHover }, .1) end)
    EGG_BTN.MouseLeave:Connect(function() tw(EGG_BTN, { BackgroundColor3 = C.BtnBg }, .1) end)

    -- Scrolling categories container (middle of bar)
    local CAT_SCROLL = new("ScrollingFrame", {
        Name                = "categorias",
        Active              = true,
        ScrollingDirection  = Enum.ScrollingDirection.X,
        BorderSizePixel     = 0,
        CanvasSize          = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        ScrollBarThickness  = 0,
        ZIndex              = 11,
        Parent              = BAR,
    })

    local catList = lst(CAT_SCROLL, Enum.FillDirection.Horizontal, 4, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)

    -- Settings button (right) - matches original
    local SETTINGS_BTN = new("TextButton", {
        Name            = "Settings",
        Text            = "⚙",
        TextColor3      = C.TextOn,
        TextSize        = 16,
        Font            = Enum.Font.Gotham,
        BorderSizePixel = 0,
        BackgroundColor3 = C.BtnBg,
        Size            = UDim2.new(0, 36, 0.96, 0),
        Position        = UDim2.new(1, -38, 0.02, 0),
        AutoButtonColor = false,
        ZIndex          = 11,
        Parent          = BAR,
    })
    cor(SETTINGS_BTN, UDim.new(0, 4))
    str(SETTINGS_BTN, C.BtnStroke, 2)
    SETTINGS_BTN.MouseEnter:Connect(function() tw(SETTINGS_BTN, { BackgroundColor3 = C.BtnHover }, .1) end)
    SETTINGS_BTN.MouseLeave:Connect(function() tw(SETTINGS_BTN, { BackgroundColor3 = C.BtnBg }, .1) end)

    -- Position cat scroll between egg btn and settings btn
    local function repositionBar()
        local eggW = EGG_BTN.Visible and 114 or 2
        CAT_SCROLL.Position = UDim2.new(0, eggW + 2, 0, 0)
        CAT_SCROLL.Size     = UDim2.new(1, -(eggW + 42), 1, 0)
    end
    repositionBar()
    EGG_BTN:GetPropertyChangedSignal("Visible"):Connect(repositionBar)

    -- ── WATERMARK (matches GUI-to-Lua: draggable) ─────────────────
    local WM = new("Frame", {
        Name            = "Watermark",
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
        BackgroundTransparency = 0.1,
        Size            = UDim2.new(0, 580, 0, 24),
        Position        = UDim2.new(0.006, 0, 0.056, 0),
        ZIndex          = 20,
        Parent          = SG,
    })
    cor(WM, UDim.new(0, 5))
    str(WM, Color3.fromRGB(50, 50, 50))

    local wmInner = new("Frame", {
        Size            = UDim2.new(1, -8, 1, 0),
        Position        = UDim2.new(0, 4, 0, 0),
        BackgroundTransparency = 1,
        ZIndex          = 21,
        Parent          = WM,
    })
    lst(wmInner, Enum.FillDirection.Horizontal, 0, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

    local function mkSep()
        new("TextLabel", {
            Text = " | ",
            Size = UDim2.new(0, 16, 1, 0),
            BackgroundTransparency = 1,
            TextColor3 = C.Separator,
            TextSize = 11,
            Font = Enum.Font.Gotham,
            ZIndex = 21,
            Parent = wmInner,
        })
    end
    local function mkWmLabel(key, val)
        local lbl = new("TextLabel", {
            Text = tostring(val or ""),
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            TextColor3 = key == "script" and AC or C.TextSub,
            TextSize = 10,
            Font = key == "script" and Enum.Font.GothamBold or Enum.Font.Gotham,
            ZIndex = 21,
            Parent = wmInner,
        })
        if key == "script" then
            onAC(function(c) lbl.TextColor3 = c end)
        end
        return lbl
    end

    local wmLabels = {}
    wmLabels.script = mkWmLabel("script", CFG.ScriptName)
    mkSep()
    wmLabels.user   = mkWmLabel("user",   "👤 " .. CFG.UserName)
    mkSep()
    wmLabels.config = mkWmLabel("config", "📁 " .. CFG.ConfigName)
    mkSep()
    wmLabels.fps    = mkWmLabel("fps",    "FPS: --")
    mkSep()
    wmLabels.ping   = mkWmLabel("ping",   "Ping: --ms")
    mkSep()
    wmLabels.build  = mkWmLabel("build",  "[" .. CFG.BuildType .. "]")
    mkSep()
    wmLabels.game   = mkWmLabel("game",   CFG.GameName .. " (" .. CFG.GameId .. ")")

    drag(WM, WM)

    -- Live FPS/Ping update
    RunService.Heartbeat:Connect(function()
        pcall(function()
            wmLabels.fps.Text  = "FPS: " .. tostring(_fps)
            wmLabels.ping.Text = "Ping: " .. tostring(_ping) .. "ms"
        end)
    end)

    -- ═══════════════════════════════════════════════════════════
    -- SETTINGS WINDOW
    -- ═══════════════════════════════════════════════════════════
    local SETTINGS_WIN = new("Frame", {
        Name            = "SettingsWin",
        Size            = UDim2.new(0, 340, 0, 420),
        Position        = UDim2.new(0.5, -170, 0.5, -210),
        BackgroundColor3 = Color3.fromRGB(22, 22, 22),
        BorderSizePixel = 0,
        ZIndex          = 100,
        Visible         = false,
        Parent          = SG,
    })
    cor(SETTINGS_WIN, UDim.new(0, 10))
    str(SETTINGS_WIN, Color3.fromRGB(50, 50, 50))

    local swHdr = new("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Color3.fromRGB(15, 15, 15),
        ZIndex = 101,
        Parent = SETTINGS_WIN,
    })
    cor(swHdr, UDim.new(0, 10))
    new("Frame", { Size = UDim2.new(1,0,.5,0), Position = UDim2.new(0,0,.5,0), BackgroundColor3 = Color3.fromRGB(15,15,15), ZIndex=100, Parent=swHdr })
    new("TextLabel", { Text = "⚙ Settings", Size = UDim2.new(1,-40,1,0), Position = UDim2.new(0,10,0,0), BackgroundTransparency=1, TextColor3=C.TextOn, TextSize=14, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=102, Parent=swHdr })
    local swClose = new("TextButton", { Text="✕", Size=UDim2.new(0,28,0,28), Position=UDim2.new(1,-32,0,4), BackgroundColor3=Color3.fromRGB(55,30,30), TextColor3=C.TextOn, TextSize=13, Font=Enum.Font.GothamBold, AutoButtonColor=false, ZIndex=103, Parent=swHdr })
    cor(swClose, UDim.new(0,6))
    swClose.MouseButton1Click:Connect(function() SETTINGS_WIN.Visible = false end)
    drag(SETTINGS_WIN, swHdr)

    local swScroll = new("ScrollingFrame", { Size=UDim2.new(1,0,1,-36), Position=UDim2.new(0,0,0,36), BackgroundTransparency=1, ScrollBarThickness=3, ScrollBarImageColor3=AC, CanvasSize=UDim2.new(0,0,0,0), ZIndex=101, Parent=SETTINGS_WIN })
    onAC(function(c) swScroll.ScrollBarImageColor3=c end)
    local swList = lst(swScroll, Enum.FillDirection.Vertical, 10)
    pad(swScroll, 10, 10, 10, 10)
    swList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        task.defer(function() if swScroll and swScroll.Parent then swScroll.CanvasSize=UDim2.new(0,0,0,swList.AbsoluteContentSize.Y+20) end end)
    end)

    -- helper to add settings row
    local function swLabel(t, col)
        new("TextLabel", { Text=t, Size=UDim2.new(1,0,0,14), AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1, TextColor3=col or C.TextSub, TextSize=11, Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true, ZIndex=102, Parent=swScroll })
    end
    local function swTextbox(placeholder, default, callback)
        local frm = new("Frame", { Size=UDim2.new(1,0,0,28), BackgroundColor3=C.Input, ZIndex=102, Parent=swScroll })
        cor(frm, UDim.new(0,6)); str(frm, Color3.fromRGB(55,55,55))
        local tb = new("TextBox", { PlaceholderText=placeholder, Text=default or "", Size=UDim2.new(1,-10,1,0), Position=UDim2.new(0,6,0,0), BackgroundTransparency=1, TextColor3=C.TextOn, PlaceholderColor3=C.TextMuted, TextSize=12, Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left, ClearTextOnFocus=false, ZIndex=103, Parent=frm })
        tb.FocusLost:Connect(function() if callback then callback(tb.Text) end end)
        return tb
    end
    local function swButton(text, callback)
        local btn = new("TextButton", { Text=text, Size=UDim2.new(1,0,0,28), BackgroundColor3=C.BtnBg, TextColor3=C.TextSub, TextSize=12, Font=Enum.Font.GothamSemibold, AutoButtonColor=false, ZIndex=102, Parent=swScroll })
        cor(btn, UDim.new(0,6)); str(btn, Color3.fromRGB(50,50,50))
        btn.MouseEnter:Connect(function() tw(btn,{BackgroundColor3=C.BtnHover,TextColor3=C.TextOn},.1) end)
        btn.MouseLeave:Connect(function() tw(btn,{BackgroundColor3=C.BtnBg,TextColor3=C.TextSub},.1) end)
        btn.MouseButton1Click:Connect(function() if callback then callback() end end)
        return btn
    end

    -- Section: Appearance
    swLabel("── Appearance ──", AC)
    swLabel("Background Color")

    -- Color picker for background
    local bgColorBtn = new("TextButton", { Text="Pick BG Color", Size=UDim2.new(1,0,0,28), BackgroundColor3=CFG.BgColor, TextColor3=C.TextOn, TextSize=11, Font=Enum.Font.Gotham, AutoButtonColor=false, ZIndex=102, Parent=swScroll })
    cor(bgColorBtn, UDim.new(0,6)); str(bgColorBtn, Color3.fromRGB(55,55,55))
    bgColorBtn.MouseButton1Click:Connect(function()
        -- simple R/G/B cycle for bg color (full picker would be very long)
        local colors = {
            Color3.fromRGB(35,35,35), Color3.fromRGB(20,20,40), Color3.fromRGB(40,20,20),
            Color3.fromRGB(20,40,20), Color3.fromRGB(30,25,40), Color3.fromRGB(0,0,0),
        }
        local idx = 1
        for i, c in ipairs(colors) do
            if c == CFG.BgColor then idx = i break end
        end
        idx = (idx % #colors) + 1
        CFG.BgColor = colors[idx]
        BG.BackgroundColor3 = CFG.BgColor
        bgColorBtn.BackgroundColor3 = CFG.BgColor
        notify({ Title="Appearance", Desc="Background color updated.", Type="Info", Duration=2 })
    end)

    -- Section: Watermark
    swLabel("── Watermark ──", AC)
    swLabel("Script Name")
    local tbScriptName = swTextbox("Script name...", CFG.ScriptName, function(v)
        CFG.ScriptName = v; wmLabels.script.Text = v
    end)
    swLabel("Display Name")
    local tbUserName = swTextbox("Your name...", CFG.UserName, function(v)
        CFG.UserName = v; wmLabels.user.Text = "👤 " .. v
    end)
    swLabel("Config Name")
    local tbConfigName = swTextbox("Config name...", CFG.ConfigName, function(v)
        CFG.ConfigName = v; wmLabels.config.Text = "📁 " .. v
    end)
    swLabel("Build Type")
    local tbBuildType = swTextbox("Public / Beta / Dev...", CFG.BuildType, function(v)
        CFG.BuildType = v; wmLabels.build.Text = "[" .. v .. "]"
    end)
    swLabel("Game Name")
    local tbGameName = swTextbox("Game name...", CFG.GameName, function(v)
        CFG.GameName = v; wmLabels.game.Text = v .. " (" .. CFG.GameId .. ")"
    end)

    -- Section: Info & Copies
    swLabel("── Copy Info ──", AC)
    swButton("📋 Copy Username", function()
        setclipboard(LP.Name)
        notify({ Title="Copied", Desc="Username copied to clipboard.", Type="Success", Duration=2 })
    end)
    swButton("📋 Copy User ID", function()
        setclipboard(tostring(LP.UserId))
        notify({ Title="Copied", Desc="User ID copied.", Type="Success", Duration=2 })
    end)
    swButton("📋 Copy Game ID", function()
        setclipboard(tostring(game.GameId))
        notify({ Title="Copied", Desc="Game ID copied.", Type="Success", Duration=2 })
    end)
    swButton("📋 Copy Config Name", function()
        setclipboard(CFG.ConfigName)
        notify({ Title="Copied", Desc="Config name copied.", Type="Success", Duration=2 })
    end)

    -- Section: Danger
    swLabel("── Danger Zone ──", Color3.fromRGB(255,65,65))
    local unloadBtn = new("TextButton", { Text="🗑 Unload Script", Size=UDim2.new(1,0,0,30), BackgroundColor3=Color3.fromRGB(55,20,20), TextColor3=Color3.fromRGB(255,100,100), TextSize=13, Font=Enum.Font.GothamBold, AutoButtonColor=false, ZIndex=102, Parent=swScroll })
    cor(unloadBtn, UDim.new(0,6)); str(unloadBtn, Color3.fromRGB(100,30,30))
    unloadBtn.MouseEnter:Connect(function() tw(unloadBtn,{BackgroundColor3=Color3.fromRGB(80,25,25)},.1) end)
    unloadBtn.MouseLeave:Connect(function() tw(unloadBtn,{BackgroundColor3=Color3.fromRGB(55,20,20)},.1) end)
    unloadBtn.MouseButton1Click:Connect(function()
        notify({ Title="Unloading", Desc="Script is being unloaded...", Type="Warning", Duration=2 })
        task.delay(.5, function() SG:Destroy() end)
    end)

    SETTINGS_BTN.MouseButton1Click:Connect(function()
        SETTINGS_WIN.Visible = not SETTINGS_WIN.Visible
    end)

    -- ═══════════════════════════════════════════════════════════
    -- EASTER EGG SYSTEM
    -- ═══════════════════════════════════════════════════════════
    local _eggActive = false

    -- Keyword scanner (scans workspace descendants for text)
    task.spawn(function()
        while SG and SG.Parent do
            task.wait(5)
            pcall(function()
                local found = false
                -- scan player gui and workspace for text
                local function scanInst(inst, depth)
                    if depth > 6 then return end
                    local ok, txt = pcall(function() return inst.Text end)
                    if ok and txt then
                        txt = txt:lower()
                        for _, kw in ipairs(EASTER_KEYWORDS) do
                            if txt:find(kw, 1, true) then found = true; return end
                        end
                    end
                    for _, child in ipairs(inst:GetChildren()) do
                        scanInst(child, depth + 1)
                    end
                end
                pcall(function() scanInst(LP.PlayerGui, 0) end)
                pcall(function() scanInst(game:GetService("Workspace"), 0) end)

                if found and not EGG_BTN.Visible then
                    EGG_BTN.Visible = true
                    repositionBar()
                    tw(EGG_BTN, { BackgroundColor3 = Color3.fromRGB(80, 60, 20) }, .3)
                    notify({ Title="Easter Egg Found!", Desc="Something was detected... click the Easter Egg button!", Type="Warning", Duration=5 })
                end
            end)
        end
    end)

    -- Easter egg video player overlay
    local function playEasterEgg()
        if _eggActive then return end
        _eggActive = true

        -- pick random video
        local vid = EASTER_VIDEOS[math.random(1, #EASTER_VIDEOS)]

        -- try to download and play
        local overlay2 = new("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 0,
            ZIndex = 500,
            Parent = SG,
        })

        local infoLbl = new("TextLabel", {
            Text = "🎬 EASTER EGG ACTIVATED!\n\nhttps://youtu.be/" .. vid.id .. "\n\n" ..
                   (vid.audioOnly and "[Audio Only]" or "[Video]") ..
                   (vid.loop and " [Looping]" or "") ..
                   "\n\nVideo downloaded to: " .. _FOLDER .. "/videos/\n\nClick anywhere to close",
            Size = UDim2.new(0.6, 0, 0.6, 0),
            Position = UDim2.new(0.2, 0, 0.2, 0),
            BackgroundColor3 = Color3.fromRGB(15, 15, 15),
            TextColor3 = Color3.fromRGB(255, 220, 50),
            TextSize = 16,
            Font = Enum.Font.GothamBold,
            TextWrapped = true,
            ZIndex = 501,
            Parent = overlay2,
        })
        cor(infoLbl, UDim.new(0, 16))
        str(infoLbl, Color3.fromRGB(100, 80, 0), 2)

        -- Download attempt
        task.spawn(function()
            pcall(function()
                local url = "https://www.youtube.com/watch?v=" .. vid.id
                local fname = _FOLDER .. "/videos/" .. vid.id .. ".txt"
                if not isfile(fname) then
                    writefile(fname, url)
                end
            end)
        end)

        -- audio sound attempt via roblox
        local snd = Instance.new("Sound")
        snd.Parent = game:GetService("SoundService")
        snd.Looped = vid.loop
        -- use a placeholder roblox sound for demo (actual YouTube audio requires external tools)
        pcall(function()
            -- try to play a roblox ambient if no audio extraction available
        end)

        local closeBtn = new("TextButton", {
            Text = "✕ Close Easter Egg",
            Size = UDim2.new(0, 180, 0, 36),
            Position = UDim2.new(0.5, -90, 0.82, 0),
            BackgroundColor3 = Color3.fromRGB(60, 20, 20),
            TextColor3 = C.TextOn,
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            AutoButtonColor = false,
            ZIndex = 502,
            Parent = overlay2,
        })
        cor(closeBtn, UDim.new(0, 8))

        closeBtn.MouseButton1Click:Connect(function()
            snd:Destroy()
            tw(overlay2, { BackgroundTransparency = 1 }, .3)
            task.wait(.3)
            overlay2:Destroy()
            _eggActive = false
        end)
    end

    EGG_BTN.MouseButton1Click:Connect(playEasterEgg)

    -- ═══════════════════════════════════════════════════════════
    -- OVERLAY SYSTEM (for dropdowns / color pickers)
    -- ═══════════════════════════════════════════════════════════
    local _ovFrame = new("Frame", {
        Name = "OvRoot",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ZIndex = 200,
        Parent = SG,
    })
    local _ovActive = nil
    local function closeOV()
        if _ovActive then _ovActive:Destroy(); _ovActive = nil end
    end
    local function openOV(fn)
        closeOV()
        local f = new("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ZIndex = 200,
            Parent = _ovFrame,
        })
        local bg = new("TextButton", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
            ZIndex = 200,
            Parent = f,
        })
        local canClose = false
        task.delay(0.15, function() canClose = true end)
        bg.MouseButton1Click:Connect(function() if canClose then closeOV() end end)
        _ovActive = f
        fn(f)
    end

    -- ═══════════════════════════════════════════════════════════
    -- WINDOW OBJECT API
    -- ═══════════════════════════════════════════════════════════
    local WO = {
        _categories = {},
        _activeCategory = nil,
        Notify = notify,
    }

    local _vis = true
    UIS.InputBegan:Connect(function(i, gpe)
        if not gpe and i.KeyCode == KEY then
            _vis = not _vis
            BG.Visible = _vis
            WM.Visible = _vis
            BAR.Visible = _vis
        end
    end)

    -- ── AddCategory ────────────────────────────────────────────
    function WO:AddCategory(name)
        local isFirst = #self._categories == 0

        -- Category tab button (in scrolling bar)
        local catBtn = new("TextButton", {
            Text            = name,
            Size            = UDim2.new(0, 0, 1, -4),
            AutomaticSize   = Enum.AutomaticSize.X,
            BackgroundColor3 = isFirst and AC or C.BtnBg,
            TextColor3      = isFirst and C.TextOn or C.TextSub,
            TextSize        = 13,
            Font            = Enum.Font.GothamSemibold,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            ZIndex          = 12,
            LayoutOrder     = #self._categories + 1,
            Parent          = CAT_SCROLL,
        })
        pad(catBtn, 0, 12, 0, 12)
        cor(catBtn, UDim.new(0, 4))
        local catStroke = str(catBtn, C.BtnStroke, 1.5)
        if isFirst then
            onAC(function(c) if self._activeCategory == CAT then catBtn.BackgroundColor3 = c end end)
        end

        -- Category content panel (on the image)
        local catPanel = new("Frame", {
            Size            = UDim2.new(1, 0, 0, 0),
            AutomaticSize   = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Visible         = isFirst,
            ZIndex          = 5,
            Parent          = CONTENT,
        })
        local panelList = lst(catPanel, Enum.FillDirection.Vertical, 8)

        local CAT = {
            _name   = name,
            _btn    = catBtn,
            _panel  = catPanel,
            _win    = self,
        }
        table.insert(self._categories, CAT)
        if isFirst then self._activeCategory = CAT end

        local function activateCat()
            if self._activeCategory == CAT then return end
            local old = self._activeCategory
            if old then
                old._panel.Visible = false
                tw(old._btn, { BackgroundColor3 = C.BtnBg, TextColor3 = C.TextSub }, .12)
            end
            catPanel.Visible = true
            tw(catBtn, { BackgroundColor3 = AC, TextColor3 = C.TextOn }, .12)
            self._activeCategory = CAT
        end

        catBtn.MouseButton1Click:Connect(activateCat)
        catBtn.MouseEnter:Connect(function()
            if self._activeCategory ~= CAT then
                tw(catBtn, { BackgroundColor3 = Color3.fromRGB(65, 65, 65), TextColor3 = C.TextOn }, .1)
            end
        end)
        catBtn.MouseLeave:Connect(function()
            if self._activeCategory ~= CAT then
                tw(catBtn, { BackgroundColor3 = C.BtnBg, TextColor3 = C.TextSub }, .1)
            end
        end)

        -- ── Element Builders ──────────────────────────────────

        local function mkRow(h)
            return new("Frame", {
                Size = UDim2.new(1, 0, 0, h or 32),
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundTransparency = 0.45,
                ZIndex = 6,
                Parent = catPanel,
            })
        end

        -- ────────────────────────────────────────────────────
        -- AddButton
        -- ────────────────────────────────────────────────────
        function CAT:AddButton(o5)
            o5 = o5 or {}
            local nm = o5.Name or "Button"
            local cb = o5.Callback or function() end

            local row = mkRow(32)
            cor(row, UDim.new(0, 8))

            local btn = new("TextButton", {
                Text            = nm,
                Size            = UDim2.new(1, -8, 0, 26),
                Position        = UDim2.new(0, 4, 0, 3),
                BackgroundColor3 = C.BtnBg,
                TextColor3      = C.TextSub,
                TextSize        = 12,
                Font            = Enum.Font.GothamSemibold,
                AutoButtonColor = false,
                ZIndex          = 7,
                Parent          = row,
            })
            cor(btn, UDim.new(0, 6))
            str(btn, Color3.fromRGB(50, 50, 50))

            btn.MouseEnter:Connect(function() tw(btn, { BackgroundColor3 = C.BtnHover, TextColor3 = C.TextOn }, .1) end)
            btn.MouseLeave:Connect(function() tw(btn, { BackgroundColor3 = C.BtnBg, TextColor3 = C.TextSub }, .1) end)
            btn.MouseButton1Click:Connect(function()
                btn.BackgroundColor3 = AC
                btn.TextColor3 = C.TextOn
                task.delay(.18, function() tw(btn, { BackgroundColor3 = C.BtnHover }, .15) end)
                pcall(cb)
            end)
            onAC(function(c) end) -- accent flash uses current AC at click time

            local r = {}
            function r:SetText(t) btn.Text = t end
            return r
        end

        -- ────────────────────────────────────────────────────
        -- AddLabel
        -- ────────────────────────────────────────────────────
        function CAT:AddLabel(o5)
            o5 = o5 or {}
            local lbl = new("TextLabel", {
                Text            = o5.Text or "",
                Size            = UDim2.new(1, 0, 0, 0),
                AutomaticSize   = Enum.AutomaticSize.Y,
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundTransparency = 0.6,
                TextColor3      = o5.Color or C.TextMuted,
                TextSize        = o5.Size or 11,
                Font            = Enum.Font.Gotham,
                TextXAlignment  = Enum.TextXAlignment.Left,
                TextWrapped     = true,
                ZIndex          = 6,
                Parent          = catPanel,
            })
            cor(lbl, UDim.new(0, 6))
            pad(lbl, 4, 8, 4, 8)

            local r = {}
            function r:Set(t) lbl.Text = t end
            function r:Get() return lbl.Text end
            return r
        end

        -- ────────────────────────────────────────────────────
        -- AddToggle
        -- ────────────────────────────────────────────────────
        function CAT:AddToggle(o5)
            o5 = o5 or {}
            local nm    = o5.Name or "Toggle"
            local val   = o5.Default == true
            local cb    = o5.Callback or function() end
            local flag  = o5.Flag
            local hasKB = o5.Keybind ~= nil

            -- keybind mode: "Toggle" | "Hold" | "Always"
            local kbMode  = "Toggle"
            local kbKey   = o5.Keybind or Enum.KeyCode.Unknown
            local listening = false
            local holding   = false

            local row = mkRow(hasKB and 34 or 32)
            cor(row, UDim.new(0, 8))

            -- name label
            local lbl = new("TextLabel", {
                Text            = nm,
                Size            = UDim2.new(1, -(hasKB and 130 or 54), 1, 0),
                Position        = UDim2.new(0, 8, 0, 0),
                BackgroundTransparency = 1,
                TextColor3      = C.TextSub,
                TextSize        = 12,
                Font            = Enum.Font.Gotham,
                TextXAlignment  = Enum.TextXAlignment.Left,
                ZIndex          = 7,
                Parent          = row,
            })

            -- track
            local track = new("Frame", {
                Size     = UDim2.new(0, 36, 0, 18),
                Position = UDim2.new(1, -44, 0.5, -9),
                BackgroundColor3 = val and AC or C.TrackOff,
                ZIndex   = 7,
                Parent   = row,
            })
            cor(track, UDim.new(0, 9))
            local knob = new("Frame", {
                Size     = UDim2.new(0, 14, 0, 14),
                Position = val and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7),
                BackgroundColor3 = C.TextOn,
                ZIndex   = 8,
                Parent   = track,
            })
            cor(knob, UDim.new(0, 7))
            local trackBtn = new("TextButton", {
                Size = UDim2.new(0, 36, 0, 18),
                Position = UDim2.new(1, -44, 0.5, -9),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
                ZIndex = 9,
                Parent = row,
            })
            onAC(function(c) if val then track.BackgroundColor3 = c end end)

            -- keybind button
            local kbBtn, modeBtn
            if hasKB then
                kbBtn = new("TextButton", {
                    Text = kbKey == Enum.KeyCode.Unknown and "NONE" or kbKey.Name,
                    Size = UDim2.new(0, 56, 0, 18),
                    Position = UDim2.new(1, -126, 0.5, -9),
                    BackgroundColor3 = C.Input,
                    TextColor3 = AC,
                    TextSize = 9,
                    Font = Enum.Font.GothamBold,
                    AutoButtonColor = false,
                    ZIndex = 7,
                    Parent = row,
                })
                cor(kbBtn, UDim.new(0, 5))
                str(kbBtn, Color3.fromRGB(55, 55, 55))
                onAC(function(c) if not listening then kbBtn.TextColor3 = c end end)

                -- mode button (right click → cycle)
                modeBtn = new("TextButton", {
                    Text = "T",
                    Size = UDim2.new(0, 18, 0, 18),
                    Position = UDim2.new(1, -168, 0.5, -9),
                    BackgroundColor3 = C.Input,
                    TextColor3 = C.TextMuted,
                    TextSize = 9,
                    Font = Enum.Font.GothamBold,
                    AutoButtonColor = false,
                    ZIndex = 7,
                    Parent = row,
                })
                cor(modeBtn, UDim.new(0, 5))
                str(modeBtn, Color3.fromRGB(55, 55, 55))

                local modeMap = { Toggle = "T", Hold = "H", Always = "A" }
                local modeOrder = { "Toggle", "Hold", "Always" }
                modeBtn.MouseButton2Click:Connect(function()
                    local ci = 1
                    for i, m in ipairs(modeOrder) do if m == kbMode then ci = i break end end
                    kbMode = modeOrder[(ci % #modeOrder) + 1]
                    modeBtn.Text = modeMap[kbMode]
                    notify({ Title = "Keybind Mode", Desc = nm .. ": " .. kbMode, Type = "Info", Duration = 2 })
                end)
            end

            local function set(v, silent)
                val = v
                track.BackgroundColor3 = v and AC or C.TrackOff
                tw(knob, { Position = v and UDim2.new(1,-16,.5,-7) or UDim2.new(0,2,.5,-7) }, .15, Enum.EasingStyle.Back)
                if not silent then pcall(cb, v) end
                if flag then _G[flag] = v end
            end

            trackBtn.MouseButton1Click:Connect(function() set(not val) end)

            -- keybind input
            if hasKB then
                kbBtn.MouseButton1Click:Connect(function()
                    if listening then return end
                    listening = true
                    kbBtn.Text = "..."
                    kbBtn.TextColor3 = Color3.fromRGB(255, 185, 0)
                    kbBtn.BackgroundColor3 = Color3.fromRGB(34, 30, 16)
                end)

                UIS.InputBegan:Connect(function(i, gpe)
                    if listening and not gpe and i.UserInputType == Enum.UserInputType.Keyboard then
                        kbKey = i.KeyCode
                        kbBtn.Text = kbKey.Name
                        kbBtn.TextColor3 = AC
                        kbBtn.BackgroundColor3 = C.Input
                        listening = false
                    elseif not listening and not gpe and i.KeyCode == kbKey and kbKey ~= Enum.KeyCode.Unknown then
                        if kbMode == "Toggle" then set(not val)
                        elseif kbMode == "Hold" then holding = true; set(true)
                        elseif kbMode == "Always" then set(true) end
                    end
                end)

                UIS.InputEnded:Connect(function(i)
                    if holding and i.KeyCode == kbKey and kbMode == "Hold" then
                        holding = false; set(false)
                    end
                end)
            end

            if flag then _G[flag] = val end

            local r = { Value = val }
            function r:Set(v) set(v, true) end
            function r:Get() return val end
            return r
        end

        -- ────────────────────────────────────────────────────
        -- AddSlider
        -- ────────────────────────────────────────────────────
        function CAT:AddSlider(o5)
            o5 = o5 or {}
            local nm   = o5.Name or "Slider"
            local mn   = o5.Min or 0
            local mx   = o5.Max or 100
            local step = o5.Step or 1
            local suf  = o5.Suffix or ""
            local flag = o5.Flag
            local cb   = o5.Callback or function() end
            local val  = math.clamp(o5.Default or mn, mn, mx)

            local wrap = new("Frame", {
                Size = UDim2.new(1, 0, 0, 48),
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundTransparency = 0.45,
                ZIndex = 6,
                Parent = catPanel,
            })
            cor(wrap, UDim.new(0, 8))

            -- name + value row
            local top = new("Frame", {
                Size = UDim2.new(1, -8, 0, 20),
                Position = UDim2.new(0, 4, 0, 4),
                BackgroundTransparency = 1,
                ZIndex = 7,
                Parent = wrap,
            })
            local nameLbl = new("TextLabel", {
                Text = nm,
                Size = UDim2.new(1, -56, 1, 0),
                BackgroundTransparency = 1,
                TextColor3 = C.TextSub,
                TextSize = 12,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 8,
                Parent = top,
            })
            -- value box
            local vbox = new("Frame", {
                Size = UDim2.new(0, 50, 0, 18),
                Position = UDim2.new(1, -52, 0.5, -9),
                BackgroundColor3 = C.Input,
                ZIndex = 8,
                Parent = top,
            })
            cor(vbox, UDim.new(0, 6))
            local valLbl = new("TextLabel", {
                Text = tostring(val) .. suf,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                TextColor3 = AC,
                TextSize = 11,
                Font = Enum.Font.GothamBold,
                ZIndex = 9,
                Parent = vbox,
            })
            onAC(function(c) valLbl.TextColor3 = c end)

            -- slider track
            local hb = new("TextButton", {
                Size = UDim2.new(1, -8, 0, 20),
                Position = UDim2.new(0, 4, 0, 26),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
                ZIndex = 9,
                Parent = wrap,
            })
            local tr = new("Frame", {
                Size = UDim2.new(1, 0, 0, 5),
                Position = UDim2.new(0, 0, 0.5, -2),
                BackgroundColor3 = C.SliderBg,
                ZIndex = 7,
                Parent = hb,
            })
            cor(tr, UDim.new(0, 3))
            local pct = (val - mn) / (mx - mn)
            local fl = new("Frame", {
                Size = UDim2.new(pct, 0, 1, 0),
                BackgroundColor3 = AC,
                ZIndex = 8,
                Parent = tr,
            })
            cor(fl, UDim.new(0, 3))
            local kn = new("Frame", {
                Size = UDim2.new(0, 14, 0, 14),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(pct, 0, 0.5, 0),
                BackgroundColor3 = C.TextOn,
                ZIndex = 10,
                Parent = tr,
            })
            cor(kn, UDim.new(0, 7))
            str(kn, AC, 2)
            onAC(function(c) fl.BackgroundColor3 = c; str(kn, c, 2) end)

            hb.MouseEnter:Connect(function()
                tw(kn, { Size = UDim2.new(0, 17, 0, 17) }, .15, Enum.EasingStyle.Back)
            end)
            hb.MouseLeave:Connect(function()
                tw(kn, { Size = UDim2.new(0, 14, 0, 14) }, .12)
            end)

            local function sv(v, silent)
                v = math.clamp(math.round(v / step) * step, mn, mx)
                val = v
                local p = (v - mn) / (mx - mn)
                fl.Size = UDim2.new(p, 0, 1, 0)
                kn.Position = UDim2.new(p, 0, 0.5, 0)
                valLbl.Text = tostring(v) .. suf
                if not silent then pcall(cb, v) end
                if flag then _G[flag] = v end
            end

            local dragging = false
            hb.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    sv(mn + (mx - mn) * math.clamp((i.Position.X - tr.AbsolutePosition.X) / tr.AbsoluteSize.X, 0, 1))
                end
            end)
            UIS.InputChanged:Connect(function(i)
                if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                    sv(mn + (mx - mn) * math.clamp((i.Position.X - tr.AbsolutePosition.X) / tr.AbsoluteSize.X, 0, 1))
                end
            end)
            UIS.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
            end)

            if flag then _G[flag] = val end

            local r = { Value = val }
            function r:Set(v) sv(v, true) end
            function r:Get() return val end
            return r
        end

        -- ────────────────────────────────────────────────────
        -- AddDropdown
        -- ────────────────────────────────────────────────────
        function CAT:AddDropdown(o5)
            o5 = o5 or {}
            local nm   = o5.Name or "Dropdown"
            local opts = o5.Options or {}
            local multi = o5.Multi or false
            local flag = o5.Flag
            local cb   = o5.Callback or function() end
            local sel  = o5.Default or (opts[1] or "")
            local msel = {}

            local wrap = new("Frame", {
                Size = UDim2.new(1, 0, 0, 50),
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundTransparency = 0.45,
                ZIndex = 6,
                Parent = catPanel,
            })
            cor(wrap, UDim.new(0, 8))

            local nameLbl = new("TextLabel", {
                Text = nm,
                Size = UDim2.new(1, -8, 0, 16),
                Position = UDim2.new(0, 8, 0, 4),
                BackgroundTransparency = 1,
                TextColor3 = C.TextSub,
                TextSize = 12,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 7,
                Parent = wrap,
            })
            local hd = new("TextButton", {
                Size = UDim2.new(1, -8, 0, 24),
                Position = UDim2.new(0, 4, 0, 22),
                BackgroundColor3 = C.Input,
                Text = "",
                AutoButtonColor = false,
                ZIndex = 7,
                Parent = wrap,
            })
            cor(hd, UDim.new(0, 7))
            local hsk = str(hd, Color3.fromRGB(55, 55, 55))
            local sl = new("TextLabel", {
                Text = multi and "Select..." or tostring(sel),
                Size = UDim2.new(1, -26, 1, 0),
                Position = UDim2.new(0, 8, 0, 0),
                BackgroundTransparency = 1,
                TextColor3 = C.TextOn,
                TextSize = 11,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 8,
                Parent = hd,
            })
            local ar = new("TextLabel", {
                Text = "▼",
                Size = UDim2.new(0, 16, 1, 0),
                Position = UDim2.new(1, -18, 0, 0),
                BackgroundTransparency = 1,
                TextColor3 = C.TextMuted,
                TextSize = 8,
                Font = Enum.Font.Gotham,
                ZIndex = 8,
                Parent = hd,
            })
            hd.MouseEnter:Connect(function() tw(hd,{BackgroundColor3=C.BtnHover},.1); tw(hsk,{Color=AC},.1) end)
            hd.MouseLeave:Connect(function() tw(hd,{BackgroundColor3=C.Input},.1); tw(hsk,{Color=Color3.fromRGB(55,55,55)})  end)

            local isOpen = false
            local function closeDD() isOpen=false; tw(ar,{},.1); closeOV() end
            local function build(ov)
                local ap=hd.AbsolutePosition; local as=hd.AbsoluteSize
                local lh=math.min(#opts*26+8,160)
                local px=math.min(ap.X,SG.AbsoluteSize.X-as.X-8)
                local py=ap.Y+as.Y+4; if py+lh>SG.AbsoluteSize.Y-8 then py=ap.Y-lh-4 end
                local pan=new("Frame",{Size=UDim2.new(0,as.X,0,0),Position=UDim2.new(0,px,0,py),BackgroundColor3=Color3.fromRGB(24,24,24),ZIndex=210,Parent=ov})
                cor(pan,UDim.new(0,10)); str(pan,Color3.fromRGB(55,55,55))
                tw(pan,{Size=UDim2.new(0,as.X,0,lh)},.15,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
                local sc=new("ScrollingFrame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,ScrollBarThickness=2,ScrollBarImageColor3=AC,CanvasSize=UDim2.new(0,0,0,0),ZIndex=211,Parent=pan})
                lst(sc,Enum.FillDirection.Vertical,2); pad(sc,4,4,4,4)
                local ll=sc:FindFirstChildOfClass("UIListLayout")
                ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    task.defer(function() if sc and sc.Parent then sc.CanvasSize=UDim2.new(0,0,0,ll.AbsoluteContentSize.Y+8) end end)
                end)
                ov.ChildRemoved:Connect(function() isOpen=false end)
                for _,op in pairs(opts) do
                    local isSel=multi and table.find(msel,op)~=nil or op==sel
                    local ob=new("TextButton",{Size=UDim2.new(1,0,0,22),BackgroundColor3=isSel and AC or Color3.fromRGB(32,32,32),Text=op,TextColor3=isSel and C.TextOn or C.TextSub,TextSize=11,Font=Enum.Font.Gotham,AutoButtonColor=false,ZIndex=212,Parent=sc})
                    cor(ob,UDim.new(0,6))
                    ob.MouseEnter:Connect(function() if not(multi and table.find(msel,op)) and op~=sel then tw(ob,{BackgroundColor3=Color3.fromRGB(44,44,44),TextColor3=C.TextOn},.08) end end)
                    ob.MouseLeave:Connect(function() local s2=multi and table.find(msel,op)~=nil or op==sel;ob.BackgroundColor3=s2 and AC or Color3.fromRGB(32,32,32);ob.TextColor3=s2 and C.TextOn or C.TextSub end)
                    ob.MouseButton1Click:Connect(function()
                        if multi then
                            local idx=table.find(msel,op);if idx then table.remove(msel,idx) else table.insert(msel,op) end
                            sl.Text=#msel>0 and table.concat(msel,", ") or "Select...";pcall(cb,msel)
                            if flag then _G[flag]=msel end
                        else sel=op;sl.Text=op;pcall(cb,op);if flag then _G[flag]=op end;closeDD() end
                    end)
                end
            end
            hd.MouseButton1Click:Connect(function()
                isOpen=not isOpen
                if isOpen then openOV(build) else closeDD() end
            end)
            if flag then _G[flag]=sel end
            local r={Value=sel}
            function r:Set(v) sel=v;sl.Text=v;if flag then _G[flag]=v end end
            function r:SetOptions(t) opts=t end
            function r:Get() return multi and msel or sel end
            return r
        end

        -- ────────────────────────────────────────────────────
        -- AddTextbox
        -- ────────────────────────────────────────────────────
        function CAT:AddTextbox(o5)
            o5 = o5 or {}
            local nm = o5.Name or "Textbox"
            local cb = o5.Callback or function() end

            local wrap = new("Frame", {
                Size = UDim2.new(1, 0, 0, 50),
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundTransparency = 0.45,
                ZIndex = 6,
                Parent = catPanel,
            })
            cor(wrap, UDim.new(0, 8))

            new("TextLabel", {
                Text = nm,
                Size = UDim2.new(1, -8, 0, 16),
                Position = UDim2.new(0, 8, 0, 4),
                BackgroundTransparency = 1,
                TextColor3 = C.TextSub,
                TextSize = 12,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 7,
                Parent = wrap,
            })

            local ifrm = new("Frame", {
                Size = UDim2.new(1, -8, 0, 24),
                Position = UDim2.new(0, 4, 0, 22),
                BackgroundColor3 = C.Input,
                ZIndex = 7,
                Parent = wrap,
            })
            cor(ifrm, UDim.new(0, 7))
            local sk = str(ifrm, Color3.fromRGB(55, 55, 55))

            local tb = new("TextBox", {
                PlaceholderText = o5.Placeholder or "Type here...",
                Text = o5.Default or "",
                Size = UDim2.new(1, -36, 1, 0),
                Position = UDim2.new(0, 8, 0, 0),
                BackgroundTransparency = 1,
                TextColor3 = C.TextOn,
                PlaceholderColor3 = C.TextMuted,
                TextSize = 11,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false,
                ZIndex = 8,
                Parent = ifrm,
            })

            local cf = new("TextButton", {
                Text = "✓",
                Size = UDim2.new(0, 24, 0, 20),
                Position = UDim2.new(1, -26, 0.5, -10),
                BackgroundColor3 = AC,
                TextColor3 = C.TextOn,
                TextSize = 12,
                Font = Enum.Font.GothamBold,
                AutoButtonColor = false,
                ZIndex = 9,
                Parent = ifrm,
            })
            cor(cf, UDim.new(0, 6))
            onAC(function(c) cf.BackgroundColor3 = c end)

            tb.Focused:Connect(function() tw(sk, { Color = AC }, .12) end)
            tb.FocusLost:Connect(function(en) tw(sk, { Color = Color3.fromRGB(55,55,55) }, .12); if en then pcall(cb, tb.Text) end end)
            cf.MouseButton1Click:Connect(function() pcall(cb, tb.Text); tb:ReleaseFocus() end)

            local r = {}
            function r:Set(v) tb.Text = v end
            function r:Get() return tb.Text end
            return r
        end

        -- ────────────────────────────────────────────────────
        -- AddSeparator
        -- ────────────────────────────────────────────────────
        function CAT:AddSeparator()
            local sep = new("Frame", {
                Size = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = Color3.fromRGB(60, 60, 60),
                BackgroundTransparency = 0.5,
                ZIndex = 6,
                Parent = catPanel,
            })
            new("UIGradient", {
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(0.1, 0),
                    NumberSequenceKeypoint.new(0.9, 0),
                    NumberSequenceKeypoint.new(1, 1),
                }),
                Parent = sep,
            })
        end

        -- ────────────────────────────────────────────────────
        -- AddColorPicker
        -- ────────────────────────────────────────────────────
        function CAT:AddColorPicker(o5)
            o5 = o5 or {}
            local nm   = o5.Name or "Color"
            local col  = o5.Default or Color3.fromRGB(255, 80, 80)
            local flag = o5.Flag
            local cb   = o5.Callback or function() end
            local ch, cs, cv = Color3.toHSV(col)

            local row = mkRow(32)
            cor(row, UDim.new(0, 8))
            new("TextLabel", {
                Text = nm,
                Size = UDim2.new(1,-52,1,0),
                Position = UDim2.new(0,8,0,0),
                BackgroundTransparency=1,
                TextColor3=C.TextSub,TextSize=12,Font=Enum.Font.Gotham,
                TextXAlignment=Enum.TextXAlignment.Left,ZIndex=7,Parent=row,
            })
            local sw = new("TextButton", {
                Size=UDim2.new(0,36,0,22),
                Position=UDim2.new(1,-40,0.5,-11),
                BackgroundColor3=col,Text="",AutoButtonColor=false,ZIndex=7,Parent=row,
            })
            cor(sw,UDim.new(0,7)); str(sw,Color3.fromRGB(60,60,60))

            local function buildCP(ov)
                local ap=sw.AbsolutePosition; local pw,ph=220,148
                local px=math.min(ap.X,SG.AbsoluteSize.X-pw-8)
                local py=ap.Y+26; if py+ph>SG.AbsoluteSize.Y-8 then py=ap.Y-ph-6 end
                local pan=new("TextButton",{AutoButtonColor=false,Text="",Size=UDim2.new(0,pw,0,0),Position=UDim2.new(0,px,0,py),BackgroundColor3=Color3.fromRGB(22,22,22),ZIndex=210,Parent=ov})
                cor(pan,UDim.new(0,12)); str(pan,Color3.fromRGB(55,55,55))
                tw(pan,{Size=UDim2.new(0,pw,0,ph)},.15,Enum.EasingStyle.Back)
                local svbg=new("Frame",{Size=UDim2.new(1,-12,0,88),Position=UDim2.new(0,6,0,6),BackgroundColor3=Color3.fromHSV(ch,1,1),ZIndex=211,Parent=pan})
                cor(svbg,UDim.new(0,6))
                local wl=new("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.fromRGB(255,255,255),ZIndex=212,Parent=svbg}); cor(wl,UDim.new(0,6))
                new("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)}),Parent=wl})
                local bl=new("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.fromRGB(0,0,0),ZIndex=213,Parent=svbg}); cor(bl,UDim.new(0,6))
                new("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)}),Rotation=90,Parent=bl})
                local svc=new("Frame",{Size=UDim2.new(0,12,0,12),AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(cs,0,1-cv,0),BackgroundColor3=C.TextOn,ZIndex=215,Parent=svbg}); cor(svc,UDim.new(0,6)); str(svc,Color3.fromRGB(0,0,0),1.5)
                local hb=new("Frame",{Size=UDim2.new(1,-12,0,12),Position=UDim2.new(0,6,0,100),ZIndex=211,Parent=pan}); cor(hb,UDim.new(0,6))
                new("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,0,0)),ColorSequenceKeypoint.new(.17,Color3.fromRGB(255,255,0)),ColorSequenceKeypoint.new(.33,Color3.fromRGB(0,255,0)),ColorSequenceKeypoint.new(.5,Color3.fromRGB(0,255,255)),ColorSequenceKeypoint.new(.67,Color3.fromRGB(0,0,255)),ColorSequenceKeypoint.new(.83,Color3.fromRGB(255,0,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(255,0,0))}),Parent=hb})
                local hc=new("Frame",{Size=UDim2.new(0,4,1,4),AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(ch,0,.5,0),BackgroundColor3=C.TextOn,ZIndex=213,Parent=hb}); cor(hc,UDim.new(0,3))
                local pv=new("Frame",{Size=UDim2.new(1,-12,0,14),Position=UDim2.new(0,6,0,120),BackgroundColor3=col,ZIndex=211,Parent=pan}); cor(pv,UDim.new(0,6))
                local function upd() col=Color3.fromHSV(ch,cs,cv); sw.BackgroundColor3=col; svbg.BackgroundColor3=Color3.fromHSV(ch,1,1); svc.Position=UDim2.new(cs,0,1-cv,0); hc.Position=UDim2.new(ch,0,.5,0); pv.BackgroundColor3=col; pcall(cb,col); if flag then _G[flag]=col end end
                local svd,hud=false,false
                svbg.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then svd=true;cs=math.clamp((i.Position.X-svbg.AbsolutePosition.X)/svbg.AbsoluteSize.X,0,1);cv=1-math.clamp((i.Position.Y-svbg.AbsolutePosition.Y)/svbg.AbsoluteSize.Y,0,1);upd() end end)
                hb.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then hud=true;ch=math.clamp((i.Position.X-hb.AbsolutePosition.X)/hb.AbsoluteSize.X,0,1);upd() end end)
                UIS.InputChanged:Connect(function(i) if i.UserInputType~=Enum.UserInputType.MouseMovement then return end;if svd then cs=math.clamp((i.Position.X-svbg.AbsolutePosition.X)/svbg.AbsoluteSize.X,0,1);cv=1-math.clamp((i.Position.Y-svbg.AbsolutePosition.Y)/svbg.AbsoluteSize.Y,0,1);upd() end;if hud then ch=math.clamp((i.Position.X-hb.AbsolutePosition.X)/hb.AbsoluteSize.X,0,1);upd() end end)
                UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then svd=false;hud=false end end)
            end
            local open=false
            sw.MouseButton1Click:Connect(function() open=not open; if open then openOV(buildCP) else closeOV() end end)
            if flag then _G[flag]=col end
            local r={Value=col}
            function r:Set(c2) col=c2;ch,cs,cv=Color3.toHSV(c2);sw.BackgroundColor3=c2 end
            function r:Get() return col end
            return r
        end

        -- ────────────────────────────────────────────────────
        -- AddKeybind (standalone)
        -- ────────────────────────────────────────────────────
        function CAT:AddKeybind(o5)
            o5 = o5 or {}
            local nm   = o5.Name or "Keybind"
            local key  = o5.Default or Enum.KeyCode.Unknown
            local flag = o5.Flag
            local cb   = o5.Callback or function() end
            local listening = false

            local row = mkRow(32)
            cor(row, UDim.new(0,8))
            new("TextLabel",{Text=nm,Size=UDim2.new(1,-88,1,0),Position=UDim2.new(0,8,0,0),BackgroundTransparency=1,TextColor3=C.TextSub,TextSize=12,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=7,Parent=row})
            local kb=new("TextButton",{Size=UDim2.new(0,76,0,20),Position=UDim2.new(1,-80,.5,-10),BackgroundColor3=C.Input,Text=key.Name,TextColor3=AC,TextSize=10,Font=Enum.Font.GothamBold,AutoButtonColor=false,ZIndex=7,Parent=row})
            cor(kb,UDim.new(0,6)); str(kb,Color3.fromRGB(55,55,55))
            onAC(function(c) if not listening then kb.TextColor3=c end end)
            kb.MouseButton1Click:Connect(function()
                if listening then return end
                listening=true; kb.Text="..."; kb.TextColor3=Color3.fromRGB(255,185,0); kb.BackgroundColor3=Color3.fromRGB(34,30,16)
            end)
            UIS.InputBegan:Connect(function(i,gpe)
                if listening and not gpe and i.UserInputType==Enum.UserInputType.Keyboard then
                    key=i.KeyCode; kb.Text=key.Name; kb.TextColor3=AC; kb.BackgroundColor3=C.Input; listening=false
                elseif not listening and not gpe and i.KeyCode==key and key~=Enum.KeyCode.Unknown then
                    pcall(cb); if flag then _G[flag]=key end
                end
            end)
            if flag then _G[flag]=key end
            local r={Value=key}
            function r:Set(k) key=k;kb.Text=k.Name end
            function r:Get() return key end
            return r
        end

        -- ────────────────────────────────────────────────────
        -- AddProgressBar
        -- ────────────────────────────────────────────────────
        function CAT:AddProgressBar(o5)
            o5 = o5 or {}
            local nm  = o5.Name or "Progress"
            local mx2 = o5.Max or 100
            local cur = math.clamp(o5.Default or 0, 0, mx2)

            local wrap = new("Frame",{Size=UDim2.new(1,0,0,40),BackgroundColor3=Color3.fromRGB(0,0,0),BackgroundTransparency=0.45,ZIndex=6,Parent=catPanel})
            cor(wrap,UDim.new(0,8))
            local top=new("Frame",{Size=UDim2.new(1,-8,0,18),Position=UDim2.new(0,4,0,4),BackgroundTransparency=1,ZIndex=7,Parent=wrap})
            new("TextLabel",{Text=nm,Size=UDim2.new(1,-50,1,0),BackgroundTransparency=1,TextColor3=C.TextSub,TextSize=12,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=8,Parent=top})
            local pl=new("TextLabel",{Text=math.round(cur/mx2*100).."%",Size=UDim2.new(0,44,1,0),Position=UDim2.new(1,-46,0,0),BackgroundTransparency=1,TextColor3=AC,TextSize=11,Font=Enum.Font.GothamBold,ZIndex=8,Parent=top})
            onAC(function(c) pl.TextColor3=c end)
            local tr2=new("Frame",{Size=UDim2.new(1,-8,0,6),Position=UDim2.new(0,4,0,28),BackgroundColor3=C.SliderBg,ZIndex=7,Parent=wrap}); cor(tr2,UDim.new(0,4))
            local fl2=new("Frame",{Size=UDim2.new(cur/mx2,0,1,0),BackgroundColor3=AC,ZIndex=8,Parent=tr2}); cor(fl2,UDim.new(0,4))
            onAC(function(c) fl2.BackgroundColor3=c end)
            local r={Value=cur}
            function r:Set(v) v=math.clamp(v,0,mx2);cur=v;tw(fl2,{Size=UDim2.new(v/mx2,0,1,0)},.22);pl.Text=math.round(v/mx2*100).."%" end
            function r:Get() return cur end
            return r
        end

        return CAT
    end

    -- ── Window controls ────────────────────────────────────────
    function WO:SetAccent(c)
        AC = c
        for _, fn in pairs(_acCBs) do pcall(fn, c) end
    end

    function WO:Toggle()
        _vis = not _vis
        BG.Visible = _vis
        WM.Visible = _vis
        BAR.Visible = _vis
    end

    function WO:Destroy()
        SG:Destroy()
    end

    function WO:SetBackground(id)
        BG_IMG.Image = id
    end

    return WO
end

return Peleccos
