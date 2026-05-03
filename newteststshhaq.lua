--[[
    PeleccosSoftwares v14.0  (Ion X Edition)
    ─────────────────────────────────────────────────────────────
    NEW in v14:
    • Right-click context popup on any toggle → Toggle/Hold/Always + Keybind
    • Auto-flag detection — no Flag="" needed, auto-generated from Name
    • Group Boxes (AddGroup) with titled card containers
    • Config system as sub-tab inside Settings
    • Settings: Watermark, Menu Accent Color, Menu Font, Visual Font
    • Slider step is config-saved correctly
    • Keybind properly fires Toggle/Hold/Always per mode
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
pcall(function() if not isfolder(_DIR)             then makefolder(_DIR) end end)
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

local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = r or UDim.new(0, 6)
    c.Parent = p
    return c
end

local function padding(p, t, r, b, l)
    local u = Instance.new("UIPadding")
    u.PaddingTop    = dim(0, t or 0)
    u.PaddingRight  = dim(0, r or 0)
    u.PaddingBottom = dim(0, b or 0)
    u.PaddingLeft   = dim(0, l or 0)
    u.Parent = p
    return u
end

local function layout(p, dir, gap, ha, va)
    local l = Instance.new("UIListLayout")
    l.FillDirection       = dir or Enum.FillDirection.Vertical
    l.Padding             = dim(0, gap or 0)
    l.HorizontalAlignment = ha or Enum.HorizontalAlignment.Left
    l.VerticalAlignment   = va or Enum.VerticalAlignment.Top
    l.SortOrder           = Enum.SortOrder.LayoutOrder
    l.Parent = p
    return l
end

-- auto-fit canvas to list content
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
    BgOuter  = rgb(19,  22,  25),
    BgSide   = rgb(13,  15,  16),
    BgSideBd = rgb(25,  28,  30),
    BgMain   = rgb(13,  15,  16),
    BgMainBd = rgb(25,  28,  30),
    BgGroup  = rgb(13,  15,  16),
    BgGroupH = rgb(35,  39,  42),
    BgRow    = rgb(26,  32,  36),
    BgHover  = rgb(19,  22,  25),
    BgActive = rgb(19,  22,  25),
    Tx0      = rgb(210, 210, 210),
    Tx1      = rgb(128, 128, 128),
    Tx2      = rgb(70,  80,  90),
    TxSub    = rgb(80,  100, 120),
    Toggle   = rgb(49,  61,  72),
    White    = rgb(255, 255, 255),
    nOk      = rgb(50,  200, 100),
    nWarn    = rgb(255, 185, 0),
    nErr     = rgb(255, 60,  60),
    nInfo    = rgb(0,   130, 255),
    Popup    = rgb(22,  26,  30),
    PopupBd  = rgb(40,  46,  52),
}

-- ═══════════════════════════════════════════════════════════════
-- FPS / PING
-- ═══════════════════════════════════════════════════════════════
local _fps, _ping = 60, 0
RunService.Heartbeat:Connect(function(dt) _fps = math.clamp(math.floor(1/dt), 0, 999) end)
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
                _ping = math.clamp(math.floor((tick()-t0)*1000) - 16, 0, 999)
            end)
        end
        task.wait(1)
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- MOUSE BUTTON HELPER
-- ═══════════════════════════════════════════════════════════════
local MOUSE_BUTTONS = {
    Enum.UserInputType.MouseButton1,
    Enum.UserInputType.MouseButton2,
    Enum.UserInputType.MouseButton3,
}
local function isMouseButton(uit)
    for _, mb in ipairs(MOUSE_BUTTONS) do
        if uit == mb then return true end
    end
    return false
end

-- ═══════════════════════════════════════════════════════════════
-- AUTO-FLAG from Name
-- ═══════════════════════════════════════════════════════════════
local _usedFlags = {}
local function autoFlag(name)
    -- convert "Speed Hack" → "speedHack", deduplicate with suffix
    if not name or name == "" then name = "unnamed" end
    local f = name:gsub("^%l", string.upper):gsub("%s+(%a)", string.upper):gsub("%s+","")
    f = f:sub(1,1):lower() .. f:sub(2)
    f = f:gsub("[^%w]", "")
    local base = f
    local i = 0
    while _usedFlags[f] do
        i = i + 1
        f = base .. i
    end
    _usedFlags[f] = true
    return f
end

-- ═══════════════════════════════════════════════════════════════
-- CONFIG SYSTEM
-- ═══════════════════════════════════════════════════════════════
local function makeConfigSystem(scriptName)
    local cfgDir = _DIR.."/configs/"..scriptName.."/"
    pcall(function()
        if not isfolder(_DIR.."/configs") then makefolder(_DIR.."/configs") end
        if not isfolder(cfgDir) then makefolder(cfgDir) end
    end)
    local _flags = {}

    local function reg(flag, getFn, setFn, ftype)
        if flag then _flags[flag] = {get=getFn, set=setFn, ftype=ftype or "any"} end
    end
    local function listCfgs()
        local list = {}
        pcall(function()
            if typeof(listfiles)=="function" then
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
                if     ftype=="bool"   then data[flag]=(v and "true" or "false")
                elseif ftype=="number" then data[flag]=tostring(v)
                elseif ftype=="color"  then data[flag]=math.floor(v.R*255)..","..math.floor(v.G*255)..","..math.floor(v.B*255)
                elseif ftype=="key"    then data[flag]=tostring(v):gsub("Enum%.KeyCode%.",""):gsub("Enum%.UserInputType%.","")
                elseif ftype=="mode"   then data[flag]=tostring(v)
                else                        data[flag]=tostring(v) end
            end)
        end
        local json = ""; local ok = pcall(function() json = HttpService:JSONEncode(data) end)
        if not ok then return false end
        return pcall(function() writefile(cfgDir..name..".json", json) end)
    end
    local function loadCfg(name)
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(cfgDir..name..".json")) end)
        if not ok or type(data)~="table" then return false end
        for flag, val in pairs(data) do
            local info = _flags[flag]
            if info then pcall(function()
                local ftype = info.ftype
                if     ftype=="bool"   then info.set(val=="true")
                elseif ftype=="number" then info.set(tonumber(val) or 0)
                elseif ftype=="color"  then
                    local r,g,b = val:match("(%d+),(%d+),(%d+)")
                    if r then info.set(rgb(tonumber(r),tonumber(g),tonumber(b))) end
                elseif ftype=="key"    then
                    local s = pcall(function() info.set(Enum.KeyCode[val]) end)
                    if not s then pcall(function() info.set(Enum.UserInputType[val]) end) end
                elseif ftype=="mode"   then info.set(val)
                else info.set(val) end
            end) end
        end
        return true
    end
    local function delCfg(name) pcall(function() delfile(cfgDir..name..".json") end) end
    local function openDir()
        pcall(function() if syn and syn.open_file_in_desktop then syn.open_file_in_desktop(cfgDir) end end)
        pcall(function() if KRNL_ENV and KRNL_ENV.open_file_in_desktop then KRNL_ENV.open_file_in_desktop(cfgDir) end end)
    end
    return {register=reg, list=listCfgs, save=saveCfg, load=loadCfg, delete=delCfg, openDir=openDir, dir=cfgDir}
end

-- ═══════════════════════════════════════════════════════════════
-- LIBRARY
-- ═══════════════════════════════════════════════════════════════
local Peleccos = {}; Peleccos.__index = Peleccos

function Peleccos:CreateWindow(o)
    o = o or {}

    -- Cleanup old instance
    pcall(function() game:GetService("CoreGui"):FindFirstChild("PeleccosV14"):Destroy() end)
    pcall(function()
        local pg = LP:FindFirstChild("PlayerGui")
        if pg then local x = pg:FindFirstChild("PeleccosV14"); if x then x:Destroy() end end
    end)

    local AC  = o.AccentColor or rgb(81, 14, 119)
    local KEY = o.Key or Enum.KeyCode.Insert

    -- Global font settings
    local MenuFont   = Enum.Font.GothamBold
    local VisFont    = Enum.Font.Code
    local ShowWatermark = true

    -- Accent callbacks
    local _acCBs = {}
    local function onAC(fn) table.insert(_acCBs, fn) end
    local function fireAC(c) for _, fn in ipairs(_acCBs) do pcall(fn, c) end end
    local function setAC(c) AC = c; fireAC(c) end

    -- Font refresh callbacks
    local _fontCBs = {}
    local function onFont(fn) table.insert(_fontCBs, fn) end
    local function fireFont(mf, vf)
        for _, fn in ipairs(_fontCBs) do pcall(fn, mf, vf) end
    end

    local CFG_META = {
        ScriptName = o.Title      or "PeleccosSoftwares",
        UserName   = LP and LP.Name or "User",
        ConfigName = o.ConfigName or "Default",
        BuildType  = o.BuildType  or "Public",
    }

    local CFGSYS = makeConfigSystem(CFG_META.ScriptName)

    -- ── ScreenGui
    local SG = mk("ScreenGui", {
        Name="PeleccosV14", ResetOnSpawn=false,
        ZIndexBehavior=Enum.ZIndexBehavior.Global,
        IgnoreGuiInset=true, DisplayOrder=999,
    })
    local ok = pcall(function() SG.Parent = game:GetService("CoreGui") end)
    if not ok then SG.Parent = LP:WaitForChild("PlayerGui") end

    -- ── Notification holder
    local NotifHolder = mk("Frame", {
        Size=dim2(0,260,1,-20), Position=dim2(1,-272,0,10),
        BackgroundTransparency=1, ClipsDescendants=false, Parent=SG,
    })
    layout(NotifHolder, Enum.FillDirection.Vertical, 4,
        Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Bottom)

    local function notify(opts)
        opts = opts or {}
        local typeKey = opts.Type or "Info"
        local ac2 = ({Success=C.nOk, Warning=C.nWarn, Error=C.nErr, Info=C.nInfo})[typeKey] or C.nInfo
        local typeTxt = ({Success="✓", Warning="!", Error="✗", Info="i"})[typeKey] or "i"

        local Card = mk("Frame", {
            Size=dim2(0,260,0,46), BackgroundColor3=C.BgSideBd,
            BorderSizePixel=0, ClipsDescendants=false, Parent=NotifHolder,
        })
        corner(Card, UDim.new(0,5))
        mk("Frame", {Size=dim2(0,3,1,0), BackgroundColor3=ac2, BorderSizePixel=0, Parent=Card})
        local BadgeFr = mk("Frame", {
            Size=dim2(0,18,0,18), Position=dim2(0,10,0,14),
            BackgroundColor3=ac2, BorderSizePixel=0, Parent=Card,
        })
        corner(BadgeFr, UDim.new(1,0))
        mk("TextLabel", {
            Size=dim2(1,0,1,0), BackgroundTransparency=1,
            Text=typeTxt, TextColor3=C.White, TextSize=10,
            Font=Enum.Font.GothamBold, Parent=BadgeFr,
        })
        mk("TextLabel", {
            Size=dim2(1,-42,0,15), Position=dim2(0,36,0,7),
            BackgroundTransparency=1, Text=opts.Title or "Notice",
            TextColor3=C.Tx0, TextSize=12, Font=Enum.Font.GothamBold,
            TextXAlignment=Enum.TextXAlignment.Left, Parent=Card,
        })
        if opts.Desc and opts.Desc ~= "" then
            mk("TextLabel", {
                Size=dim2(1,-42,0,13), Position=dim2(0,36,0,24),
                BackgroundTransparency=1, Text=opts.Desc,
                TextColor3=C.Tx1, TextSize=10, Font=Enum.Font.Gotham,
                TextXAlignment=Enum.TextXAlignment.Left,
                TextTruncate=Enum.TextTruncate.AtEnd, Parent=Card,
            })
        end
        Card.BackgroundTransparency = 1
        tw(Card, {BackgroundTransparency=0}, 0.18)
        local dur = opts.Duration or 4
        task.delay(dur, function()
            tw(Card, {BackgroundTransparency=1, Size=dim2(0,260,0,0)}, 0.2)
            task.wait(0.22); pcall(function() Card:Destroy() end)
        end)
    end

    -- ── Watermark
    local WatermarkFrame = mk("Frame", {
        Size=dim2(0,220,0,28), Position=dim2(0,8,0,8),
        BackgroundColor3=C.BgSideBd, BorderSizePixel=0,
        Visible=ShowWatermark, Parent=SG,
    })
    corner(WatermarkFrame, UDim.new(0,5))
    mk("Frame", {Size=dim2(0,2,1,0), BackgroundColor3=AC, BorderSizePixel=0, Parent=WatermarkFrame})
    onAC(function(c)
        local bar = WatermarkFrame:FindFirstChild("AccentBar")
        if bar then bar.BackgroundColor3 = c end
    end)
    local WatermarkBar = WatermarkFrame:GetChildren()[1] -- the bar
    WatermarkFrame:FindFirstChildOfClass("Frame").Name = "AccentBar"
    local WmText = mk("TextLabel", {
        Size=dim2(1,-10,1,0), Position=dim2(0,8,0,0),
        BackgroundTransparency=1, Text=CFG_META.ScriptName.." | -- fps | -- ms",
        TextColor3=C.Tx1, TextSize=10, Font=Enum.Font.Code,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=WatermarkFrame,
    })
    RunService.Heartbeat:Connect(function()
        if ShowWatermark then
            pcall(function()
                WmText.Text = CFG_META.ScriptName.." | ".._fps.."fps | ".._ping.."ms"
            end)
        end
    end)

    -- ── Main window
    local WIN_W, WIN_H = 840, 560
    local SIDE_W = 190

    local Main = mk("Frame", {
        Name="Main", Size=dim2(0,WIN_W,0,WIN_H),
        Position=dim2(0.5,-WIN_W/2,0.5,-WIN_H/2),
        BackgroundColor3=C.BgOuter, BorderSizePixel=0,
        Visible=false, Parent=SG,
    })
    corner(Main, UDim.new(0,8))

    -- Draggable (header area only)
    local _drag, _ds, _sp = false, nil, nil
    local DragZone = mk("TextButton", {
        Size=dim2(0,SIDE_W+16,0,55), BackgroundTransparency=1,
        Text="", BorderSizePixel=0, ZIndex=10, Parent=Main,
    })
    DragZone.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            _drag=true; _ds=i.Position; _sp=Main.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if _drag and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d = i.Position - _ds
            Main.Position = dim2(_sp.X.Scale,_sp.X.Offset+d.X,_sp.Y.Scale,_sp.Y.Offset+d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then _drag=false end
    end)

    -- ── Sidebar
    local SideBd = mk("Frame", {
        Size=dim2(0,SIDE_W,1,-16), Position=dim2(0,8,0,8),
        BackgroundColor3=C.BgSideBd, BorderSizePixel=0, Parent=Main,
    })
    corner(SideBd, UDim.new(0,6))
    local Sidebar = mk("Frame", {
        Size=dim2(1,-2,1,-2), Position=dim2(0,1,0,1),
        BackgroundColor3=C.BgSide, BorderSizePixel=0, Parent=SideBd,
    })
    corner(Sidebar, UDim.new(0,5))

    -- Sidebar header
    local LogoBox = mk("Frame", {
        Size=dim2(0,32,0,32), Position=dim2(0,9,0,10),
        BackgroundColor3=rgb(21,21,21), BorderSizePixel=0, Parent=Sidebar,
    })
    corner(LogoBox, UDim.new(0,6))
    local LogoLbl = mk("TextLabel", {
        Size=dim2(1,0,1,0), BackgroundTransparency=1,
        Text="X", TextColor3=AC, TextSize=16, Font=Enum.Font.GothamBold, Parent=LogoBox,
    })
    onAC(function(c) LogoLbl.TextColor3 = c end)
    mk("TextLabel", {
        Size=dim2(0,120,0,16), Position=dim2(0,48,0,12),
        BackgroundTransparency=1, Text=CFG_META.ScriptName,
        TextColor3=C.Tx0, TextSize=13, Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=Sidebar,
    })
    local BuildTypeLbl = mk("TextLabel", {
        Size=dim2(0,120,0,13), Position=dim2(0,48,0,30),
        BackgroundTransparency=1, Text=CFG_META.BuildType,
        TextColor3=AC, TextSize=10, Font=Enum.Font.Code,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=Sidebar,
    })
    onAC(function(c) BuildTypeLbl.TextColor3 = c end)

    mk("Frame", {
        Size=dim2(1,-18,0,1), Position=dim2(0,9,0,55),
        BackgroundColor3=C.BgGroupH, BorderSizePixel=0, Parent=Sidebar,
    })

    -- Sidebar tab scroll
    local TabScroll = mk("ScrollingFrame", {
        Size=dim2(1,0,1,-148), Position=dim2(0,0,0,62),
        BackgroundTransparency=1, ScrollBarThickness=0,
        BorderSizePixel=0, CanvasSize=dim2(0,0,0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y, Parent=Sidebar,
    })
    layout(TabScroll, Enum.FillDirection.Vertical, 0)

    -- Player card at bottom
    mk("Frame", {
        Size=dim2(1,-18,0,1), Position=dim2(0,9,1,-88),
        BackgroundColor3=C.BgGroupH, BorderSizePixel=0, Parent=Sidebar,
    })
    local PCard = mk("Frame", {
        Size=dim2(1,0,0,88), Position=dim2(0,0,1,-88),
        BackgroundTransparency=1, Parent=Sidebar,
    })
    local PAvaWrap = mk("Frame", {
        Size=dim2(0,32,0,32), Position=dim2(0,9,0,10),
        BackgroundColor3=C.BgRow, BorderSizePixel=0, Parent=PCard,
    })
    corner(PAvaWrap, UDim.new(0,4))
    mk("ImageLabel", {
        Size=dim2(1,0,1,0), BackgroundTransparency=1, BorderSizePixel=0,
        Image="https://www.roblox.com/headshot-thumbnail/image?userId="..LP.UserId.."&width=48&height=48&format=png",
        Parent=PAvaWrap,
    })
    mk("TextLabel", {
        Size=dim2(0,110,0,15), Position=dim2(0,48,0,10),
        BackgroundTransparency=1, Text=LP.DisplayName,
        TextColor3=C.Tx0, TextSize=12, Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd, Parent=PCard,
    })
    mk("TextLabel", {
        Size=dim2(0,110,0,13), Position=dim2(0,48,0,27),
        BackgroundTransparency=1, Text="@"..LP.Name,
        TextColor3=C.TxSub, TextSize=10, Font=Enum.Font.Code,
        TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd, Parent=PCard,
    })
    local wFps = mk("TextLabel", {
        Size=dim2(0.5,0,0,13), Position=dim2(0,9,0,55),
        BackgroundTransparency=1, Text="-- fps",
        TextColor3=C.TxSub, TextSize=10, Font=Enum.Font.Code,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=PCard,
    })
    local wPing = mk("TextLabel", {
        Size=dim2(0.5,0,0,13), Position=dim2(0.5,0,0,55),
        BackgroundTransparency=1, Text="-- ms",
        TextColor3=C.TxSub, TextSize=10, Font=Enum.Font.Code,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=PCard,
    })
    RunService.Heartbeat:Connect(function()
        pcall(function() wFps.Text=_fps.."fps"; wPing.Text=_ping.."ms" end)
    end)

    -- ── Content area
    local ContentBd = mk("Frame", {
        Size=dim2(1,-(SIDE_W+24),1,-16), Position=dim2(0,SIDE_W+16,0,8),
        BackgroundColor3=C.BgMainBd, BorderSizePixel=0, Parent=Main,
    })
    corner(ContentBd, UDim.new(0,6))
    local ContentArea = mk("Frame", {
        Size=dim2(1,-2,1,-2), Position=dim2(0,1,0,1),
        BackgroundColor3=C.BgMain, BorderSizePixel=0, Parent=ContentBd,
    })
    corner(ContentArea, UDim.new(0,5))

    -- Sub-tab bar
    local SubTabBar = mk("Frame", {
        Size=dim2(1,0,0,44), BackgroundColor3=C.BgMain,
        BorderSizePixel=0, ClipsDescendants=true, Parent=ContentArea,
    })
    mk("Frame", {
        Size=dim2(1,0,0,1), Position=dim2(0,0,1,-1),
        BackgroundColor3=C.BgGroupH, BorderSizePixel=0, Parent=SubTabBar,
    })

    -- Panel scroll area
    local PanelArea = mk("Frame", {
        Size=dim2(1,0,1,-45), Position=dim2(0,0,0,45),
        BackgroundTransparency=1, ClipsDescendants=true, Parent=ContentArea,
    })
    local PanelScroll = mk("ScrollingFrame", {
        Size=dim2(1,0,1,0), BackgroundTransparency=1,
        ScrollBarThickness=2, ScrollBarImageColor3=C.Toggle,
        BorderSizePixel=0, CanvasSize=dim2(0,0,0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y, Parent=PanelArea,
    })
    onAC(function(c) PanelScroll.ScrollBarImageColor3 = c end)

    -- ── Overlay root (for dropdowns, color pickers, context menus)
    local _ovRoot = mk("Frame", {
        Name="OvRoot", Size=dim2(1,0,1,0),
        BackgroundTransparency=1, ZIndex=200, Parent=SG,
    })
    local _ovActive = nil
    local function closeOV()
        if _ovActive then _ovActive:Destroy(); _ovActive = nil end
    end
    local function openOV(fn)
        closeOV()
        local f = mk("Frame", {Size=dim2(1,0,1,0),BackgroundTransparency=1,ZIndex=200,Parent=_ovRoot})
        local bg = mk("TextButton", {Size=dim2(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=200,Parent=f})
        local ok2 = false; task.delay(0.1, function() ok2=true end)
        bg.MouseButton1Click:Connect(function() if ok2 then closeOV() end end)
        _ovActive = f; fn(f)
    end

    -- ── Tab/subtab state
    local Tabs           = {}
    local SubTabScrolls  = {}
    local TabFrames      = {}
    local SubTabsMap     = {}
    local ActiveTab      = nil
    local ActiveSubs     = {}

    -- Dynamic accent registry
    local DynFills = {}; local DynTexts = {}
    local function regFill(f) table.insert(DynFills, f) end
    local function regText(t) table.insert(DynTexts, t) end

    local function applyAccent(c)
        for _, f in ipairs(DynFills) do pcall(function() f.BackgroundColor3 = c end) end
        for _, t in ipairs(DynTexts) do pcall(function() t.TextColor3       = c end) end
        for k, btn in pairs(Tabs) do
            if k == ActiveTab then
                local ind = btn:FindFirstChild("Ind")
                if ind then ind.BackgroundColor3 = c end
                local ico = btn:FindFirstChild("Ico")
                if ico then ico.TextColor3 = c end
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
        for _, tf in pairs(TabFrames) do tf.Visible = false end
        for k, b in pairs(Tabs) do
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

    -- Key toggle
    local _vis = true
    UIS.InputBegan:Connect(function(i, gpe)
        if not gpe and i.KeyCode==KEY then
            _vis = not _vis; Main.Visible = _vis
        end
    end)

    -- ── KEY NAME HELPER
    local KEYS_SHORT = {
        [Enum.KeyCode.LeftShift]="LSH",[Enum.KeyCode.RightShift]="RSH",
        [Enum.KeyCode.LeftControl]="LCT",[Enum.KeyCode.RightControl]="RCT",
        [Enum.KeyCode.Insert]="INS",[Enum.KeyCode.Backspace]="BS",
        [Enum.KeyCode.Return]="ENT",[Enum.KeyCode.CapsLock]="CAP",
        [Enum.KeyCode.Escape]="ESC",[Enum.KeyCode.Space]="SPC",
        [Enum.UserInputType.MouseButton1]="MB1",
        [Enum.UserInputType.MouseButton2]="MB2",
        [Enum.UserInputType.MouseButton3]="MB3",
    }
    local function keyName(k)
        if not k or k==Enum.KeyCode.Unknown then return "NONE" end
        return KEYS_SHORT[k] or tostring(k):gsub("Enum%.KeyCode%.",""):gsub("Enum%.UserInputType%.","")
    end

    -- ── CONTEXT POPUP builder (right-click on toggle)
    -- Shows Toggle/Hold/Always mode bar + keybind button at mouse position
    local function openContextPopup(opts)
        -- opts = { getMode, setMode, getKey, setKey, name, onPress, onRelease }
        openOV(function(ov)
            local mp = UIS:GetMouseLocation()
            local pw, ph = 180, 72
            local px = math.min(mp.X, SG.AbsoluteSize.X - pw - 4)
            local py = math.min(mp.Y, SG.AbsoluteSize.Y - ph - 4)

            local Pop = mk("Frame", {
                Size=dim2(0,pw,0,ph), Position=dim2(0,px,0,py),
                BackgroundColor3=C.Popup, BorderSizePixel=0, ZIndex=250, Parent=ov,
            })
            corner(Pop, UDim.new(0,7))
            mk("Frame", {
                Size=dim2(1,0,0,1), BackgroundColor3=C.PopupBd,
                BorderSizePixel=0, ZIndex=251, Parent=Pop,
            })

            -- Mode bar row
            local ModeRow = mk("Frame", {
                Size=dim2(1,-12,0,26), Position=dim2(0,6,0,8),
                BackgroundColor3=C.BgRow, BorderSizePixel=0, ZIndex=251, Parent=Pop,
            })
            corner(ModeRow, UDim.new(0,5))
            local modeLL = layout(ModeRow, Enum.FillDirection.Horizontal, 0)
            local MODES = {"Toggle","Hold","Always"}
            local modeBtns = {}

            local function refreshModeBtns()
                for _, info in ipairs(modeBtns) do
                    local active = info.mode == opts.getMode()
                    info.btn.BackgroundColor3 = active and AC or C.BgRow
                    info.btn.TextColor3       = active and C.White or C.Tx2
                end
            end

            for mi, mOpt in ipairs(MODES) do
                local MB = mk("TextButton", {
                    Size=dim2(1/3,0,1,0), BackgroundColor3=C.BgRow,
                    Text=mOpt, TextColor3=C.Tx2, TextSize=10,
                    Font=Enum.Font.GothamBold, AutoButtonColor=false,
                    BorderSizePixel=0, ZIndex=252, LayoutOrder=mi, Parent=ModeRow,
                })
                corner(MB, UDim.new(0,4))
                table.insert(modeBtns, {btn=MB, mode=mOpt})
                MB.MouseButton1Click:Connect(function()
                    opts.setMode(mOpt)
                    refreshModeBtns()
                end)
            end
            refreshModeBtns()

            -- Keybind row
            local KbRow = mk("Frame", {
                Size=dim2(1,-12,0,24), Position=dim2(0,6,0,40),
                BackgroundTransparency=1, ZIndex=251, Parent=Pop,
            })
            mk("TextLabel", {
                Size=dim2(0,56,1,0), BackgroundTransparency=1,
                Text="Keybind:", TextColor3=C.Tx2, TextSize=10,
                Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left,
                ZIndex=252, Parent=KbRow,
            })
            local kbBtn = mk("TextButton", {
                Size=dim2(1,-62,1,0), Position=dim2(0,60,0,0),
                BackgroundColor3=C.BgRow, Text=keyName(opts.getKey()),
                TextColor3=AC, TextSize=10, Font=Enum.Font.GothamBold,
                AutoButtonColor=false, BorderSizePixel=0, ZIndex=252, Parent=KbRow,
            })
            corner(kbBtn, UDim.new(0,4))
            onAC(function(c) kbBtn.TextColor3 = c end)

            local listening = false
            kbBtn.MouseButton1Click:Connect(function()
                if listening then return end
                listening = true; kbBtn.Text = "..."; kbBtn.TextColor3 = rgb(255,185,0)
            end)
            UIS.InputBegan:Connect(function(i, gpe)
                if not listening then return end
                if gpe then return end
                local k
                if isMouseButton(i.UserInputType) then k = i.UserInputType
                elseif i.UserInputType == Enum.UserInputType.Keyboard then k = i.KeyCode end
                if not k then return end
                opts.setKey(k)
                kbBtn.Text = keyName(k); kbBtn.TextColor3 = AC
                listening = false
            end)
        end)
    end

    -- ── WINDOW OBJECT
    local WO = {_categories={}, _cfgsys=CFGSYS}

    function WO:Notify(opts) notify(opts) end
    function WO:SetAccent(c) setAC(c) end
    function WO:Toggle() _vis=not _vis; Main.Visible=_vis end
    function WO:Destroy() SG:Destroy() end
    function WO:SaveConfig(n) return CFGSYS.save(n or CFG_META.ConfigName) end
    function WO:LoadConfig(n) return CFGSYS.load(n or CFG_META.ConfigName) end

    -- ── AddCategory
    function WO:AddCategory(name)
        local isFirst = #self._categories == 0
        local catKey  = name:lower():gsub("%s","_").."_"..tostring(#self._categories)

        -- Sidebar button
        local Btn = mk("TextButton", {
            Name=catKey, Size=dim2(1,0,0,34),
            BackgroundColor3=C.BgHover, BackgroundTransparency=1,
            Text="", BorderSizePixel=0, Parent=TabScroll,
        })
        local Ind = mk("Frame", {
            Name="Ind", Size=dim2(0,2,0,18), Position=dim2(0,8,0.5,-9),
            BackgroundColor3=AC, BorderSizePixel=0, Visible=false, Parent=Btn,
        })
        corner(Ind, UDim.new(0,1))
        local Lbl = mk("TextLabel", {
            Name="Lbl", Size=dim2(1,-28,1,0), Position=dim2(0,24,0,0),
            BackgroundTransparency=1, Text=name, TextColor3=C.Tx2,
            TextSize=13, Font=MenuFont,
            TextXAlignment=Enum.TextXAlignment.Left, Parent=Btn,
        })
        onFont(function(mf,_) Lbl.Font = mf end)
        Btn.MouseEnter:Connect(function()
            if catKey ~= ActiveTab then
                tw(Btn,{BackgroundColor3=C.BgHover,BackgroundTransparency=0},0.1)
                Lbl.TextColor3 = C.Tx1
            end
        end)
        Btn.MouseLeave:Connect(function()
            if catKey ~= ActiveTab then
                tw(Btn,{BackgroundTransparency=1},0.1)
                Lbl.TextColor3 = C.Tx2
            end
        end)
        Btn.MouseButton1Click:Connect(function() SetActiveTab(catKey) end)
        Tabs[catKey] = Btn

        -- Subtab scroll in subtab bar
        local StScroll = mk("ScrollingFrame", {
            Size=dim2(1,0,1,-1), BackgroundTransparency=1,
            ScrollBarThickness=0, BorderSizePixel=0,
            CanvasSize=dim2(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.X,
            Visible=false, Parent=SubTabBar,
        })
        layout(StScroll, Enum.FillDirection.Horizontal, 0,
            Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
        padding(StScroll, 0, 0, 0, 10)
        SubTabScrolls[catKey] = StScroll
        SubTabsMap[catKey]    = {}
        ActiveSubs[catKey]    = nil

        local CAT = {_name=name, _key=catKey, _win=self, _subOrder=0}
        table.insert(self._categories, CAT)
        if isFirst then self._activeCat = CAT end

        -- ── addSubTab (internal)
        local _defaultPanel = nil
        local function addSubTab(label)
            CAT._subOrder = CAT._subOrder + 1
            local subKey  = catKey.."_sub"..CAT._subOrder

            local StBtn = mk("TextButton", {
                Name=subKey, Size=dim2(0,0,1,-1),
                AutomaticSize=Enum.AutomaticSize.X,
                BackgroundTransparency=1, Text="", BorderSizePixel=0,
                LayoutOrder=CAT._subOrder, Parent=StScroll,
            })
            padding(StBtn, 0, 14, 0, 14)
            local StLbl = mk("TextLabel", {
                Name="Lbl", Size=dim2(1,0,1,0), BackgroundTransparency=1,
                Text=label, TextColor3=C.Tx2,
                TextSize=12, Font=MenuFont, Parent=StBtn,
            })
            onFont(function(mf,_) StLbl.Font = mf end)
            local StUnder = mk("Frame", {
                Name="Under", Size=dim2(1,0,0,2), Position=dim2(0,0,1,-2),
                BackgroundColor3=AC, BorderSizePixel=0, Visible=false, Parent=StBtn,
            })

            local TF = mk("Frame", {
                Name=subKey, Size=dim2(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
                BackgroundTransparency=1, Visible=false, Parent=PanelScroll,
            })
            layout(TF, Enum.FillDirection.Vertical, 10)
            padding(TF, 10, 10, 10, 10)

            TabFrames[subKey]              = TF
            SubTabsMap[catKey][subKey]     = {btn=StBtn, frame=TF, lbl=StLbl, under=StUnder}
            if ActiveSubs[catKey] == nil then ActiveSubs[catKey] = subKey end

            StBtn.MouseButton1Click:Connect(function()
                for sk2, st2 in pairs(SubTabsMap[catKey]) do
                    st2.frame.Visible=false; st2.lbl.TextColor3=C.Tx2
                    st2.under.Visible=false
                end
                TF.Visible=true; StLbl.TextColor3=AC
                StUnder.Visible=true; StUnder.BackgroundColor3=AC
                ActiveSubs[catKey]=subKey
                PanelScroll.CanvasPosition=Vector2.new(0,0)
            end)
            return TF
        end

        local function getDefaultPanel()
            if not _defaultPanel then _defaultPanel = addSubTab(name) end
            return _defaultPanel
        end

        -- ── GROUP BOX (titled card container)
        -- Returns a body frame to add widgets into
        local function mkGroup(parent, title, order)
            local Card = mk("Frame", {
                Size=dim2(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
                BackgroundColor3=C.BgGroupH, BorderSizePixel=0,
                LayoutOrder=order or 0, Parent=parent,
            })
            corner(Card, UDim.new(0,7))
            local Inner = mk("Frame", {
                Size=dim2(1,-2,1,-2), Position=dim2(0,1,0,1),
                BackgroundColor3=C.BgGroup, BorderSizePixel=0,
                AutomaticSize=Enum.AutomaticSize.Y, Parent=Card,
            })
            corner(Inner, UDim.new(0,6))
            -- Header
            local Hdr = mk("Frame", {Size=dim2(1,0,0,28), BackgroundTransparency=1, Parent=Inner})
            local HdrLbl = mk("TextLabel", {
                Size=dim2(1,-16,1,0), Position=dim2(0,8,0,0),
                BackgroundTransparency=1, Text=title, TextColor3=C.Tx0,
                TextSize=12, Font=MenuFont,
                TextXAlignment=Enum.TextXAlignment.Left, Parent=Hdr,
            })
            onFont(function(mf,_) HdrLbl.Font = mf end)
            mk("Frame", {
                Size=dim2(1,0,0,1), Position=dim2(0,0,0,28),
                BackgroundColor3=C.BgGroupH, BorderSizePixel=0, Parent=Inner,
            })
            local Body = mk("Frame", {
                Size=dim2(1,0,0,0), Position=dim2(0,0,0,30),
                BackgroundTransparency=1, AutomaticSize=Enum.AutomaticSize.Y, Parent=Inner,
            })
            layout(Body, Enum.FillDirection.Vertical, 0)
            padding(Body, 4, 8, 8, 8)
            return Card, Body
        end

        -- ── ROW helper
        local function mkRow(parent, h)
            return mk("Frame", {Size=dim2(1,0,0,h or 28), BackgroundTransparency=1, Parent=parent})
        end

        -- ────────────────────────────────────────────────
        -- PUBLIC WIDGET API
        -- ────────────────────────────────────────────────

        -- ── AddGroup: returns a group-box container CAT-like object
        function CAT:AddGroup(title)
            local panel = getDefaultPanel()
            local _, Body = mkGroup(panel, title, 0)
            -- proxy object with same widget methods but targeting Body
            local GRP = {}
            -- We'll forward all Add* calls with Body as parent override
            local function mkRowG(h)  return mkRow(Body, h) end

            -- Inline widget builders targeting Body
            function GRP:AddToggle(o5)   return CAT:_AddToggle(o5, Body) end
            function GRP:AddSlider(o5)   return CAT:_AddSlider(o5, Body) end
            function GRP:AddDropdown(o5) return CAT:_AddDropdown(o5, Body) end
            function GRP:AddColorPicker(o5) return CAT:_AddColorPicker(o5, Body) end
            function GRP:AddKeybind(o5)  return CAT:_AddKeybind(o5, Body) end
            function GRP:AddButton(o5)   return CAT:_AddButton(o5, Body) end
            function GRP:AddLabel(o5)    return CAT:_AddLabel(o5, Body) end
            function GRP:AddSeparator()  return CAT:_AddSeparator(Body) end
            return GRP
        end

        -- AddSubTab: returns panel frame for custom layout
        function CAT:AddSubTab(label) return addSubTab(label) end

        -- ──────────────────────────────────────────────────────
        -- Internal widget builders (accept explicit parent)
        -- ──────────────────────────────────────────────────────

        function CAT:_AddToggle(o5, parentOverride)
            o5 = o5 or {}
            local parent  = parentOverride or getDefaultPanel()
            local nm      = o5.Name or "Toggle"
            local flag    = o5.Flag or autoFlag(nm)
            local val     = o5.Default == true
            local cb      = o5.Callback or function() end

            -- Keybind/mode state
            local kbKey   = o5.Keybind or Enum.KeyCode.Unknown
            local kbMode  = "Toggle"  -- Toggle | Hold | Always

            local row = mkRow(parent, 28)

            local Lbl = mk("TextLabel", {
                Size=dim2(1,-36,1,0), BackgroundTransparency=1, Text=nm,
                TextColor3=val and C.Tx0 or C.Tx1,
                TextSize=13, Font=MenuFont,
                TextXAlignment=Enum.TextXAlignment.Left, Parent=row,
            })
            onFont(function(mf,_) Lbl.Font = mf end)

            local Track = mk("Frame", {
                Size=dim2(0,26,0,14), Position=dim2(1,-28,0.5,-7),
                BackgroundColor3=val and AC or C.Toggle,
                BorderSizePixel=0, Parent=row,
            })
            corner(Track, UDim.new(1,0))
            onAC(function(c) if val then Track.BackgroundColor3 = c end end)

            local Ball = mk("Frame", {
                Size=dim2(0,10,0,10),
                Position=val and dim2(1,-12,0.5,-5) or dim2(0,2,0.5,-5),
                BackgroundColor3=C.White, BorderSizePixel=0, Parent=Track,
            })
            corner(Ball, UDim.new(1,0))

            local function set(v, silent)
                val = v
                tw(Track, {BackgroundColor3=v and AC or C.Toggle}, 0.14)
                tw(Ball,  {Position=v and dim2(1,-12,0.5,-5) or dim2(0,2,0.5,-5)}, 0.16)
                Lbl.TextColor3 = v and C.Tx0 or C.Tx1
                if not silent then pcall(cb, v) end
            end

            -- Always mode: activate immediately if set
            local function applyMode(m)
                kbMode = m
                if m == "Always" and not val then set(true) end
            end

            -- Context popup (right-click)
            local Hit = mk("TextButton", {
                Size=dim2(1,0,1,0), BackgroundTransparency=1,
                Text="", AutoButtonColor=false, Parent=row,
            })
            Hit.MouseButton1Click:Connect(function()
                if kbMode ~= "Always" then set(not val) end
            end)
            Hit.MouseButton2Click:Connect(function()
                openContextPopup({
                    getMode = function() return kbMode end,
                    setMode = function(m) applyMode(m) end,
                    getKey  = function() return kbKey  end,
                    setKey  = function(k) kbKey = k    end,
                    name    = nm,
                })
            end)

            -- Keybind input
            local _holding = false
            UIS.InputBegan:Connect(function(i, gpe)
                if gpe then return end
                if kbKey == Enum.KeyCode.Unknown then return end
                if i.KeyCode == kbKey or i.UserInputType == kbKey then
                    if kbMode == "Toggle" then set(not val)
                    elseif kbMode == "Hold" then _holding=true; set(true)
                    elseif kbMode == "Always" then set(true) end
                end
            end)
            UIS.InputEnded:Connect(function(i)
                if kbMode == "Hold" and _holding then
                    if i.KeyCode == kbKey or i.UserInputType == kbKey then
                        _holding = false; set(false)
                    end
                end
            end)

            -- Config
            CFGSYS.register(flag,
                function() return val end,
                function(v) set(v, false) end,
                "bool")
            CFGSYS.register(flag.."__mode",
                function() return kbMode end,
                function(v) applyMode(v) end,
                "mode")

            local r = {Value=val}
            function r:Set(v) set(v, true) end
            function r:Get() return val end
            return r
        end

        function CAT:_AddSlider(o5, parentOverride)
            o5 = o5 or {}
            local parent = parentOverride or getDefaultPanel()
            local nm     = o5.Name or "Slider"
            local flag   = o5.Flag or autoFlag(nm)
            local mn     = o5.Min or 0
            local mx     = o5.Max or 100
            local step   = o5.Step or 1
            local suf    = o5.Suffix or ""
            local cb     = o5.Callback or function() end
            local val    = math.clamp(o5.Default or mn, mn, mx)

            local wrap = mk("Frame", {
                Size=dim2(1,0,0,44), BackgroundTransparency=1, Parent=parent,
            })
            local topRow = mk("Frame", {
                Size=dim2(1,0,0,18), BackgroundTransparency=1, Parent=wrap,
            })
            local NmLbl = mk("TextLabel", {
                Size=dim2(0.6,0,1,0), BackgroundTransparency=1, Text=nm,
                TextColor3=C.Tx1, TextSize=13, Font=MenuFont,
                TextXAlignment=Enum.TextXAlignment.Left, Parent=topRow,
            })
            onFont(function(mf,_) NmLbl.Font = mf end)
            local ValBox = mk("Frame", {
                Size=dim2(0,40,0,14), Position=dim2(1,-42,0.5,-7),
                BackgroundColor3=C.BgRow, BorderSizePixel=0, Parent=topRow,
            })
            corner(ValBox, UDim.new(0,3))
            local function fmtV(v)
                if step < 1 then
                    local dec = math.max(0, math.ceil(-math.log10(step)))
                    return string.format("%."..dec.."f", v)..suf
                end
                return tostring(v)..suf
            end
            local vLbl = mk("TextLabel", {
                Size=dim2(1,0,1,0), BackgroundTransparency=1, Text=fmtV(val),
                TextColor3=AC, TextSize=10, Font=Enum.Font.Code, Parent=ValBox,
            })
            regText(vLbl)

            local trackRow = mk("Frame", {
                Size=dim2(1,0,0,20), Position=dim2(0,0,0,22),
                BackgroundTransparency=1, Parent=wrap,
            })
            local Track = mk("Frame", {
                Size=dim2(1,-48,0,5), Position=dim2(0,0,0.5,-2.5),
                BackgroundColor3=C.BgRow, BorderSizePixel=0, Parent=trackRow,
            })
            corner(Track, UDim.new(1,0))
            local pct = (mn==mx) and 0 or (val-mn)/(mx-mn)
            local Fill = mk("Frame", {
                Size=dim2(pct,0,1,0), BackgroundColor3=AC,
                BorderSizePixel=0, Parent=Track,
            })
            corner(Fill, UDim.new(1,0))
            regFill(Fill)
            local Knob = mk("Frame", {
                Size=dim2(0,10,0,10), Position=dim2(pct,-10*pct,0.5,-5),
                BackgroundColor3=C.White, BorderSizePixel=0, Parent=Track,
            })
            corner(Knob, UDim.new(1,0))

            local minusBtn = mk("TextButton", {
                Size=dim2(0,18,0,18), Position=dim2(1,-44,0.5,-9),
                BackgroundColor3=C.BgRow, Text="-", TextColor3=C.Tx1,
                TextSize=14, Font=Enum.Font.GothamBold,
                AutoButtonColor=false, BorderSizePixel=0, Parent=trackRow,
            })
            corner(minusBtn, UDim.new(0,3))
            local plusBtn = mk("TextButton", {
                Size=dim2(0,18,0,18), Position=dim2(1,-22,0.5,-9),
                BackgroundColor3=C.BgRow, Text="+", TextColor3=C.Tx1,
                TextSize=14, Font=Enum.Font.GothamBold,
                AutoButtonColor=false, BorderSizePixel=0, Parent=trackRow,
            })
            corner(plusBtn, UDim.new(0,3))

            local function sv(v, silent)
                v = math.clamp(math.round(v/step)*step, mn, mx)
                val = tonumber(string.format("%.10g", v))
                local p = (mn==mx) and 0 or (val-mn)/(mx-mn)
                tw(Fill,{Size=dim2(p,0,1,0)},0.04,Enum.EasingStyle.Linear)
                Knob.Position = dim2(p,-10*p,0.5,-5)
                vLbl.Text = fmtV(val)
                if not silent then pcall(cb, val) end
            end

            local dragging = false
            local Hit = mk("TextButton", {
                Size=dim2(1,0,3,0), Position=dim2(0,0,-0.5,0),
                BackgroundTransparency=1, Text="", AutoButtonColor=false, Parent=Track,
            })
            local function posToVal(absX)
                return mn+(mx-mn)*math.clamp((absX-Track.AbsolutePosition.X)/Track.AbsoluteSize.X,0,1)
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
                local m = UIS:IsKeyDown(Enum.KeyCode.LeftShift) and 10 or 1; sv(val-step*m)
            end)
            plusBtn.MouseButton1Click:Connect(function()
                local m = UIS:IsKeyDown(Enum.KeyCode.LeftShift) and 10 or 1; sv(val+step*m)
            end)

            CFGSYS.register(flag,
                function() return val end,
                function(v) sv(v, true) end,
                "number")

            local r = {Value=val}
            function r:Set(v) sv(v, true) end
            function r:Get() return val end
            return r
        end

        function CAT:_AddDropdown(o5, parentOverride)
            o5 = o5 or {}
            local parent = parentOverride or getDefaultPanel()
            local nm     = o5.Name or "Dropdown"
            local flag   = o5.Flag or autoFlag(nm)
            local opts2  = o5.Options or {}
            local multi  = o5.Multi or false
            local cb     = o5.Callback or function() end
            local sel    = o5.Default or (opts2[1] or "")
            local msel   = {}

            local wrap = mk("Frame", {Size=dim2(1,0,0,46), BackgroundTransparency=1, Parent=parent})
            local NmLbl = mk("TextLabel", {
                Size=dim2(1,0,0,14), BackgroundTransparency=1, Text=nm,
                TextColor3=C.Tx2, TextSize=10, Font=MenuFont,
                TextXAlignment=Enum.TextXAlignment.Left, Parent=wrap,
            })
            onFont(function(mf,_) NmLbl.Font = mf end)
            local Hd = mk("TextButton", {
                Size=dim2(1,0,0,26), Position=dim2(0,0,0,18),
                BackgroundColor3=C.BgRow, Text="", AutoButtonColor=false,
                BorderSizePixel=0, Parent=wrap,
            })
            corner(Hd, UDim.new(0,5))
            local SelLbl = mk("TextLabel", {
                Size=dim2(1,-22,1,0), Position=dim2(0,8,0,0),
                BackgroundTransparency=1, Text=multi and "Select..." or tostring(sel),
                TextColor3=C.Tx1, TextSize=12, Font=Enum.Font.Gotham,
                TextXAlignment=Enum.TextXAlignment.Left, Parent=Hd,
            })
            mk("TextLabel", {
                Size=dim2(0,14,1,0), Position=dim2(1,-16,0,0),
                BackgroundTransparency=1, Text="▾", TextColor3=C.Tx2,
                TextSize=10, Font=Enum.Font.Gotham, Parent=Hd,
            })

            local isOpen = false
            local function closeDD() isOpen=false; closeOV() end
            local function buildDD(ov)
                local ap  = Hd.AbsolutePosition; local as = Hd.AbsoluteSize
                local lh  = math.min(#opts2*26+8, 160)
                local px  = math.min(ap.X, SG.AbsoluteSize.X-as.X-10)
                local py  = ap.Y+as.Y+4
                if py+lh > SG.AbsoluteSize.Y-10 then py = ap.Y-lh-4 end
                local pan = mk("Frame",{Size=dim2(0,as.X,0,0),Position=dim2(0,px,0,py),
                    BackgroundColor3=C.BgSideBd,ZIndex=220,Parent=ov})
                corner(pan,UDim.new(0,5))
                tw(pan,{Size=dim2(0,as.X,0,lh)},0.14,Enum.EasingStyle.Back)
                local sc = mk("ScrollingFrame",{Size=dim2(1,0,1,0),BackgroundTransparency=1,
                    ScrollBarThickness=2,ScrollBarImageColor3=C.Toggle,
                    CanvasSize=dim2(0,0,0,0),ZIndex=221,Parent=pan})
                local scLL = layout(sc,Enum.FillDirection.Vertical,2); padding(sc,4,4,4,4)
                autoCanvas(sc, scLL)
                for _, op in ipairs(opts2) do
                    local isSel = multi and table.find(msel,op)~=nil or op==sel
                    local ob = mk("TextButton",{Size=dim2(1,0,0,24),Text=op,
                        BackgroundColor3=isSel and AC or C.BgRow,
                        TextColor3=isSel and C.White or C.Tx1,
                        TextSize=12,Font=Enum.Font.Gotham,
                        AutoButtonColor=false,ZIndex=222,Parent=sc})
                    corner(ob,UDim.new(0,4))
                    ob.MouseButton1Click:Connect(function()
                        if multi then
                            local idx=table.find(msel,op)
                            if idx then table.remove(msel,idx) else table.insert(msel,op) end
                            SelLbl.Text=#msel>0 and table.concat(msel,", ") or "Select..."
                            pcall(cb,msel)
                        else
                            sel=op; SelLbl.Text=op; pcall(cb,op); closeDD()
                        end
                    end)
                end
            end
            Hd.MouseButton1Click:Connect(function()
                isOpen=not isOpen
                if isOpen then openOV(buildDD) else closeDD() end
            end)

            CFGSYS.register(flag,
                function() return sel end,
                function(v) sel=v; SelLbl.Text=v end,
                "string")

            local r={Value=sel}
            function r:Set(v) sel=v; SelLbl.Text=v end
            function r:SetOptions(t) opts2=t end
            function r:Get() return multi and msel or sel end
            return r
        end

        function CAT:_AddColorPicker(o5, parentOverride)
            o5 = o5 or {}
            local parent = parentOverride or getDefaultPanel()
            local nm     = o5.Name or "Color"
            local flag   = o5.Flag or autoFlag(nm)
            local col    = o5.Default or rgb(255,80,80)
            local cb     = o5.Callback or function() end
            local h,s,v  = Color3.toHSV(col)

            local row = mk("Frame", {Size=dim2(1,0,0,28), BackgroundTransparency=1, Parent=parent})
            local NmLbl = mk("TextLabel", {
                Size=dim2(1,-46,1,0), BackgroundTransparency=1, Text=nm,
                TextColor3=C.Tx1, TextSize=13, Font=MenuFont,
                TextXAlignment=Enum.TextXAlignment.Left, Parent=row,
            })
            onFont(function(mf,_) NmLbl.Font = mf end)
            local Sw = mk("TextButton", {
                Size=dim2(0,36,0,20), Position=dim2(1,-38,0.5,-10),
                BackgroundColor3=col, Text="", AutoButtonColor=false,
                BorderSizePixel=0, Parent=row,
            })
            corner(Sw, UDim.new(0,5))

            local open2 = false
            Sw.MouseButton1Click:Connect(function()
                open2 = not open2
                if open2 then
                    openOV(function(ov)
                        local ch2,cs2,cv2 = h,s,v
                        local pw,ph = 210,150
                        local ap = Sw.AbsolutePosition
                        local px = math.min(ap.X, SG.AbsoluteSize.X-pw-10)
                        local py = ap.Y+Sw.AbsoluteSize.Y+6
                        if py+ph > SG.AbsoluteSize.Y-10 then py=ap.Y-ph-6 end
                        local pan=mk("Frame",{Size=dim2(0,pw,0,ph),Position=dim2(0,px,0,py),
                            BackgroundColor3=C.BgSideBd,ZIndex=220,Parent=ov})
                        corner(pan,UDim.new(0,6))

                        local svbg=mk("Frame",{Size=dim2(1,-12,0,90),Position=dim2(0,6,0,6),
                            BackgroundColor3=Color3.fromHSV(ch2,1,1),ZIndex=221,Parent=pan})
                        corner(svbg,UDim.new(0,4))
                        local wg=mk("Frame",{Size=dim2(1,0,1,0),BackgroundColor3=rgb(255,255,255),ZIndex=222,Parent=svbg})
                        corner(wg,UDim.new(0,4))
                        mk("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)}),Parent=wg})
                        local bgf=mk("Frame",{Size=dim2(1,0,1,0),BackgroundColor3=rgb(0,0,0),ZIndex=223,Parent=svbg})
                        corner(bgf,UDim.new(0,4))
                        mk("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)}),Rotation=90,Parent=bgf})
                        local svc=mk("TextButton",{AutoButtonColor=false,Text="",AnchorPoint=Vector2.new(.5,.5),
                            Size=dim2(0,9,0,9),Position=dim2(cs2,0,1-cv2,0),
                            BackgroundColor3=rgb(255,255,255),ZIndex=226,Parent=svbg})
                        corner(svc,UDim.new(1,0))

                        local hueBar=mk("TextButton",{AutoButtonColor=false,Text="",
                            Size=dim2(1,-12,0,10),Position=dim2(0,6,0,102),ZIndex=221,Parent=pan})
                        corner(hueBar,UDim.new(1,0))
                        mk("UIGradient",{Color=ColorSequence.new({
                            ColorSequenceKeypoint.new(0,rgb(255,0,0)),
                            ColorSequenceKeypoint.new(0.17,rgb(255,255,0)),
                            ColorSequenceKeypoint.new(0.33,rgb(0,255,0)),
                            ColorSequenceKeypoint.new(0.5,rgb(0,255,255)),
                            ColorSequenceKeypoint.new(0.67,rgb(0,0,255)),
                            ColorSequenceKeypoint.new(0.83,rgb(255,0,255)),
                            ColorSequenceKeypoint.new(1,rgb(255,0,0))}),Parent=hueBar})
                        local hueCur=mk("Frame",{AnchorPoint=Vector2.new(.5,.5),Size=dim2(0,8,1,2),
                            Position=dim2(ch2,0,.5,0),BackgroundColor3=rgb(255,255,255),ZIndex=223,Parent=hueBar})
                        corner(hueCur,UDim.new(0,2))

                        local prev=mk("Frame",{Size=dim2(1,-12,0,14),Position=dim2(0,6,0,118),
                            BackgroundColor3=Color3.fromHSV(ch2,cs2,cv2),ZIndex=221,Parent=pan})
                        corner(prev,UDim.new(0,4))

                        local function updPicker()
                            local nc=Color3.fromHSV(ch2,cs2,cv2)
                            svbg.BackgroundColor3=Color3.fromHSV(ch2,1,1)
                            svc.Position=dim2(cs2,0,1-cv2,0)
                            hueCur.Position=dim2(ch2,0,.5,0)
                            prev.BackgroundColor3=nc
                            col=nc; h,s,v=ch2,cs2,cv2; Sw.BackgroundColor3=nc
                            pcall(cb,nc)
                        end
                        local dSV,dHue=false,false
                        svbg.InputBegan:Connect(function(i)
                            if i.UserInputType==Enum.UserInputType.MouseButton1 then
                                dSV=true
                                cs2=math.clamp((i.Position.X-svbg.AbsolutePosition.X)/svbg.AbsoluteSize.X,0,1)
                                cv2=1-math.clamp((i.Position.Y-svbg.AbsolutePosition.Y)/svbg.AbsoluteSize.Y,0,1)
                                updPicker()
                            end
                        end)
                        hueBar.InputBegan:Connect(function(i)
                            if i.UserInputType==Enum.UserInputType.MouseButton1 then
                                dHue=true
                                ch2=math.clamp((i.Position.X-hueBar.AbsolutePosition.X)/hueBar.AbsoluteSize.X,0,1)
                                updPicker()
                            end
                        end)
                        UIS.InputChanged:Connect(function(i)
                            if i.UserInputType~=Enum.UserInputType.MouseMovement then return end
                            if dSV then
                                cs2=math.clamp((i.Position.X-svbg.AbsolutePosition.X)/svbg.AbsoluteSize.X,0,1)
                                cv2=1-math.clamp((i.Position.Y-svbg.AbsolutePosition.Y)/svbg.AbsoluteSize.Y,0,1)
                                updPicker()
                            end
                            if dHue then
                                ch2=math.clamp((i.Position.X-hueBar.AbsolutePosition.X)/hueBar.AbsoluteSize.X,0,1)
                                updPicker()
                            end
                        end)
                        UIS.InputEnded:Connect(function(i)
                            if i.UserInputType==Enum.UserInputType.MouseButton1 then dSV=false;dHue=false end
                        end)
                    end)
                else closeOV() end
            end)

            CFGSYS.register(flag,
                function() return col end,
                function(c2) col=c2; h,s,v=Color3.toHSV(c2); Sw.BackgroundColor3=c2; pcall(cb,c2) end,
                "color")

            local r={Value=col}
            function r:Set(c2) col=c2; h,s,v=Color3.toHSV(c2); Sw.BackgroundColor3=c2 end
            function r:Get() return col end
            return r
        end

        function CAT:_AddKeybind(o5, parentOverride)
            o5 = o5 or {}
            local parent = parentOverride or getDefaultPanel()
            local nm     = o5.Name or "Keybind"
            local flag   = o5.Flag or autoFlag(nm)
            local key    = o5.Default or Enum.KeyCode.Unknown
            local cb     = o5.Callback or function() end
            local listen = false

            local row = mk("Frame", {Size=dim2(1,0,0,28), BackgroundTransparency=1, Parent=parent})
            local NmLbl = mk("TextLabel", {
                Size=dim2(1,-92,1,0), BackgroundTransparency=1, Text=nm,
                TextColor3=C.Tx1, TextSize=13, Font=MenuFont,
                TextXAlignment=Enum.TextXAlignment.Left, Parent=row,
            })
            onFont(function(mf,_) NmLbl.Font = mf end)
            local Kb = mk("TextButton", {
                Size=dim2(0,84,0,18), Position=dim2(1,-86,0.5,-9),
                BackgroundColor3=C.BgRow, TextColor3=AC,
                Text=keyName(key), TextSize=10, Font=Enum.Font.GothamBold,
                AutoButtonColor=false, BorderSizePixel=0, Parent=row,
            })
            corner(Kb, UDim.new(0,4))
            onAC(function(c) if not listen then Kb.TextColor3=c end end)
            Kb.MouseButton1Click:Connect(function()
                if listen then return end
                listen=true; Kb.Text="..."; Kb.TextColor3=rgb(255,185,0); Kb.BackgroundColor3=rgb(28,24,10)
            end)
            UIS.InputBegan:Connect(function(i, gpe)
                if listen and not gpe and (i.UserInputType==Enum.UserInputType.Keyboard or isMouseButton(i.UserInputType)) then
                    key = isMouseButton(i.UserInputType) and i.UserInputType or i.KeyCode
                    Kb.Text=keyName(key); Kb.TextColor3=AC; Kb.BackgroundColor3=C.BgRow; listen=false
                elseif not listen and not gpe and (i.KeyCode==key or i.UserInputType==key) and key~=Enum.KeyCode.Unknown then
                    pcall(cb); 
                end
            end)

            CFGSYS.register(flag,
                function() return key end,
                function(k) key=k; Kb.Text=keyName(k) end,
                "key")

            local r={Value=key}
            function r:Set(k) key=k; Kb.Text=keyName(k) end
            function r:Get() return key end
            return r
        end

        function CAT:_AddButton(o5, parentOverride)
            o5 = o5 or {}
            local parent = parentOverride or getDefaultPanel()
            local nm     = o5.Name or "Button"
            local cb     = o5.Callback or function() end
            local Btn = mk("TextButton", {
                Size=dim2(1,0,0,28), BackgroundColor3=C.BgGroupH,
                Text=nm, TextColor3=C.Tx1, TextSize=13, Font=MenuFont,
                AutoButtonColor=false, BorderSizePixel=0, Parent=parent,
            })
            corner(Btn, UDim.new(0,5))
            onFont(function(mf,_) Btn.Font = mf end)
            Btn.MouseEnter:Connect(function() tw(Btn,{BackgroundColor3=C.BgRow,TextColor3=C.Tx0},0.1) end)
            Btn.MouseLeave:Connect(function() tw(Btn,{BackgroundColor3=C.BgGroupH,TextColor3=C.Tx1},0.1) end)
            Btn.MouseButton1Down:Connect(function() tw(Btn,{BackgroundColor3=AC,TextColor3=C.White},0.07) end)
            Btn.MouseButton1Up:Connect(function() tw(Btn,{BackgroundColor3=C.BgRow,TextColor3=C.Tx0},0.14) end)
            Btn.MouseButton1Click:Connect(function()
                task.delay(0.18, function() tw(Btn,{BackgroundColor3=C.BgGroupH,TextColor3=C.Tx1},0.14) end)
                pcall(cb)
            end)
            local r={}; function r:SetText(t) Btn.Text=t end; return r
        end

        function CAT:_AddLabel(o5, parentOverride)
            o5 = o5 or {}
            local parent = parentOverride or getDefaultPanel()
            local Lbl = mk("TextLabel", {
                Size=dim2(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
                BackgroundTransparency=1, Text=o5.Text or "",
                TextColor3=o5.Color or C.Tx2, TextSize=o5.Size or 11,
                Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left,
                TextWrapped=true, Parent=parent,
            })
            local r={}; function r:Set(t) Lbl.Text=t end; function r:Get() return Lbl.Text end; return r
        end

        function CAT:_AddSeparator(parentOverride)
            local parent = parentOverride or getDefaultPanel()
            local sep = mk("Frame", {
                Size=dim2(1,0,0,1), BackgroundColor3=C.BgGroupH,
                BackgroundTransparency=0.4, Parent=parent,
            })
            mk("UIGradient", {
                Transparency=NumberSequence.new({
                    NumberSequenceKeypoint.new(0,1),
                    NumberSequenceKeypoint.new(0.05,0),
                    NumberSequenceKeypoint.new(0.95,0),
                    NumberSequenceKeypoint.new(1,1),
                }), Parent=sep,
            })
        end

        function CAT:_AddTextbox(o5, parentOverride)
            o5 = o5 or {}
            local parent = parentOverride or getDefaultPanel()
            local nm     = o5.Name or "Input"
            local flag   = o5.Flag or autoFlag(nm)
            local cb     = o5.Callback or function() end
            local wrap = mk("Frame", {Size=dim2(1,0,0,46), BackgroundTransparency=1, Parent=parent})
            local NmLbl = mk("TextLabel", {
                Size=dim2(1,0,0,14), BackgroundTransparency=1, Text=nm,
                TextColor3=C.Tx2, TextSize=10, Font=MenuFont,
                TextXAlignment=Enum.TextXAlignment.Left, Parent=wrap,
            })
            onFont(function(mf,_) NmLbl.Font = mf end)
            local ifrm = mk("Frame", {
                Size=dim2(1,0,0,26), Position=dim2(0,0,0,18),
                BackgroundColor3=C.BgRow, BorderSizePixel=0, Parent=wrap,
            })
            corner(ifrm, UDim.new(0,5))
            local tb = mk("TextBox", {
                Size=dim2(1,-10,1,0), Position=dim2(0,6,0,0),
                BackgroundTransparency=1, PlaceholderText=o5.Placeholder or "type here...",
                Text=o5.Default or "", TextColor3=C.Tx0, PlaceholderColor3=C.Tx2,
                TextSize=12, Font=Enum.Font.Gotham,
                TextXAlignment=Enum.TextXAlignment.Left, ClearTextOnFocus=false, Parent=ifrm,
            })
            tb.Focused:Connect(function() tw(ifrm,{BackgroundColor3=C.BgGroupH},0.1) end)
            tb.FocusLost:Connect(function() tw(ifrm,{BackgroundColor3=C.BgRow},0.1); pcall(cb,tb.Text) end)
            CFGSYS.register(flag,
                function() return tb.Text end,
                function(v) tb.Text=tostring(v) end,
                "string")
            local r={}; function r:Set(v) tb.Text=v end; function r:Get() return tb.Text end; return r
        end

        -- ── Public shortcuts (forward to internal builders)
        function CAT:AddToggle(o5)      return self:_AddToggle(o5) end
        function CAT:AddSlider(o5)      return self:_AddSlider(o5) end
        function CAT:AddDropdown(o5)    return self:_AddDropdown(o5) end
        function CAT:AddColorPicker(o5) return self:_AddColorPicker(o5) end
        function CAT:AddKeybind(o5)     return self:_AddKeybind(o5) end
        function CAT:AddButton(o5)      return self:_AddButton(o5) end
        function CAT:AddLabel(o5)       return self:_AddLabel(o5) end
        function CAT:AddSeparator()     return self:_AddSeparator() end
        function CAT:AddTextbox(o5)     return self:_AddTextbox(o5) end

        -- Initial activation
        if isFirst then task.defer(function() SetActiveTab(catKey) end) end

        return CAT
    end

    -- ══════════════════════════════════════════════════
    -- AUTO SETTINGS CATEGORY (always last)
    -- ══════════════════════════════════════════════════
    local function buildSettingsCategory()
        local SetCat = WO:AddCategory("Settings")

        -- ── Sub-tab: General
        local GenPanel = SetCat:AddSubTab("General")
        layout(GenPanel, Enum.FillDirection.Vertical, 10)
        padding(GenPanel, 10, 10, 10, 10)

        -- Watermark toggle
        local wmRow = mk("Frame", {Size=dim2(1,0,0,28), BackgroundTransparency=1, Parent=GenPanel})
        mk("TextLabel", {
            Size=dim2(1,-36,1,0), BackgroundTransparency=1, Text="Show Watermark",
            TextColor3=C.Tx0, TextSize=13, Font=MenuFont,
            TextXAlignment=Enum.TextXAlignment.Left, Parent=wmRow,
        })
        local wmTrack = mk("Frame", {
            Size=dim2(0,26,0,14), Position=dim2(1,-28,0.5,-7),
            BackgroundColor3=ShowWatermark and AC or C.Toggle, BorderSizePixel=0, Parent=wmRow,
        })
        corner(wmTrack, UDim.new(1,0))
        local wmBall = mk("Frame", {
            Size=dim2(0,10,0,10),
            Position=ShowWatermark and dim2(1,-12,0.5,-5) or dim2(0,2,0.5,-5),
            BackgroundColor3=C.White, BorderSizePixel=0, Parent=wmTrack,
        })
        corner(wmBall, UDim.new(1,0))
        local wmHit = mk("TextButton", {
            Size=dim2(1,0,1,0), BackgroundTransparency=1, Text="", AutoButtonColor=false, Parent=wmRow,
        })
        wmHit.MouseButton1Click:Connect(function()
            ShowWatermark = not ShowWatermark
            WatermarkFrame.Visible = ShowWatermark
            tw(wmTrack, {BackgroundColor3=ShowWatermark and AC or C.Toggle}, 0.14)
            tw(wmBall,  {Position=ShowWatermark and dim2(1,-12,0.5,-5) or dim2(0,2,0.5,-5)}, 0.16)
        end)

        -- Menu Accent Color
        local acRow = mk("Frame", {Size=dim2(1,0,0,28), BackgroundTransparency=1, Parent=GenPanel})
        mk("TextLabel", {
            Size=dim2(1,-46,1,0), BackgroundTransparency=1, Text="Menu Accent Color",
            TextColor3=C.Tx1, TextSize=13, Font=MenuFont,
            TextXAlignment=Enum.TextXAlignment.Left, Parent=acRow,
        })
        local AcSw = mk("TextButton", {
            Size=dim2(0,36,0,20), Position=dim2(1,-38,0.5,-10),
            BackgroundColor3=AC, Text="", AutoButtonColor=false,
            BorderSizePixel=0, Parent=acRow,
        })
        corner(AcSw, UDim.new(0,5))
        onAC(function(c) AcSw.BackgroundColor3 = c end)
        AcSw.MouseButton1Click:Connect(function()
            openOV(function(ov)
                local ch2,cs2,cv2 = Color3.toHSV(AC)
                local pw,ph = 210,150
                local ap = AcSw.AbsolutePosition
                local px = math.min(ap.X, SG.AbsoluteSize.X-pw-10)
                local py = ap.Y+AcSw.AbsoluteSize.Y+6
                if py+ph > SG.AbsoluteSize.Y-10 then py=ap.Y-ph-6 end
                local pan=mk("Frame",{Size=dim2(0,pw,0,ph),Position=dim2(0,px,0,py),
                    BackgroundColor3=C.BgSideBd,ZIndex=220,Parent=ov})
                corner(pan,UDim.new(0,6))
                local svbg=mk("Frame",{Size=dim2(1,-12,0,90),Position=dim2(0,6,0,6),
                    BackgroundColor3=Color3.fromHSV(ch2,1,1),ZIndex=221,Parent=pan})
                corner(svbg,UDim.new(0,4))
                local wg=mk("Frame",{Size=dim2(1,0,1,0),BackgroundColor3=rgb(255,255,255),ZIndex=222,Parent=svbg})
                corner(wg,UDim.new(0,4))
                mk("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)}),Parent=wg})
                local bgf=mk("Frame",{Size=dim2(1,0,1,0),BackgroundColor3=rgb(0,0,0),ZIndex=223,Parent=svbg})
                corner(bgf,UDim.new(0,4))
                mk("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)}),Rotation=90,Parent=bgf})
                local svc=mk("TextButton",{AutoButtonColor=false,Text="",AnchorPoint=Vector2.new(.5,.5),
                    Size=dim2(0,9,0,9),Position=dim2(cs2,0,1-cv2,0),
                    BackgroundColor3=rgb(255,255,255),ZIndex=226,Parent=svbg})
                corner(svc,UDim.new(1,0))
                local hueBar=mk("TextButton",{AutoButtonColor=false,Text="",
                    Size=dim2(1,-12,0,10),Position=dim2(0,6,0,102),ZIndex=221,Parent=pan})
                corner(hueBar,UDim.new(1,0))
                mk("UIGradient",{Color=ColorSequence.new({
                    ColorSequenceKeypoint.new(0,rgb(255,0,0)),ColorSequenceKeypoint.new(0.17,rgb(255,255,0)),
                    ColorSequenceKeypoint.new(0.33,rgb(0,255,0)),ColorSequenceKeypoint.new(0.5,rgb(0,255,255)),
                    ColorSequenceKeypoint.new(0.67,rgb(0,0,255)),ColorSequenceKeypoint.new(0.83,rgb(255,0,255)),
                    ColorSequenceKeypoint.new(1,rgb(255,0,0))}),Parent=hueBar})
                local hueCur=mk("Frame",{AnchorPoint=Vector2.new(.5,.5),Size=dim2(0,8,1,2),
                    Position=dim2(ch2,0,.5,0),BackgroundColor3=rgb(255,255,255),ZIndex=223,Parent=hueBar})
                corner(hueCur,UDim.new(0,2))
                local prev=mk("Frame",{Size=dim2(1,-12,0,14),Position=dim2(0,6,0,118),
                    BackgroundColor3=Color3.fromHSV(ch2,cs2,cv2),ZIndex=221,Parent=pan})
                corner(prev,UDim.new(0,4))
                local function updAC()
                    local nc=Color3.fromHSV(ch2,cs2,cv2)
                    svbg.BackgroundColor3=Color3.fromHSV(ch2,1,1)
                    svc.Position=dim2(cs2,0,1-cv2,0)
                    hueCur.Position=dim2(ch2,0,.5,0)
                    prev.BackgroundColor3=nc
                    setAC(nc)
                end
                local dSV,dHue=false,false
                svbg.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dSV=true; cs2=math.clamp((i.Position.X-svbg.AbsolutePosition.X)/svbg.AbsoluteSize.X,0,1); cv2=1-math.clamp((i.Position.Y-svbg.AbsolutePosition.Y)/svbg.AbsoluteSize.Y,0,1); updAC() end end)
                hueBar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dHue=true; ch2=math.clamp((i.Position.X-hueBar.AbsolutePosition.X)/hueBar.AbsoluteSize.X,0,1); updAC() end end)
                UIS.InputChanged:Connect(function(i) if i.UserInputType~=Enum.UserInputType.MouseMovement then return end; if dSV then cs2=math.clamp((i.Position.X-svbg.AbsolutePosition.X)/svbg.AbsoluteSize.X,0,1); cv2=1-math.clamp((i.Position.Y-svbg.AbsolutePosition.Y)/svbg.AbsoluteSize.Y,0,1); updAC() end; if dHue then ch2=math.clamp((i.Position.X-hueBar.AbsolutePosition.X)/hueBar.AbsoluteSize.X,0,1); updAC() end end)
                UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dSV=false;dHue=false end end)
            end)
        end)

        -- Menu Font picker
        local FONTS = {"GothamBold","Gotham","Code","Arial","ArialBold","Roboto","Ubuntu","Inconsolata"}
        local fontWrap = mk("Frame", {Size=dim2(1,0,0,46), BackgroundTransparency=1, Parent=GenPanel})
        mk("TextLabel", {
            Size=dim2(1,0,0,14), BackgroundTransparency=1, Text="Menu Font",
            TextColor3=C.Tx2, TextSize=10, Font=Enum.Font.Gotham,
            TextXAlignment=Enum.TextXAlignment.Left, Parent=fontWrap,
        })
        local fontHd = mk("TextButton", {
            Size=dim2(1,0,0,26), Position=dim2(0,0,0,18),
            BackgroundColor3=C.BgRow, Text="", AutoButtonColor=false,
            BorderSizePixel=0, Parent=fontWrap,
        })
        corner(fontHd, UDim.new(0,5))
        local fontSelLbl = mk("TextLabel", {
            Size=dim2(1,-22,1,0), Position=dim2(0,8,0,0),
            BackgroundTransparency=1, Text="GothamBold",
            TextColor3=C.Tx1, TextSize=12, Font=Enum.Font.Gotham,
            TextXAlignment=Enum.TextXAlignment.Left, Parent=fontHd,
        })
        mk("TextLabel", {Size=dim2(0,14,1,0),Position=dim2(1,-16,0,0),BackgroundTransparency=1,Text="▾",TextColor3=C.Tx2,TextSize=10,Font=Enum.Font.Gotham,Parent=fontHd})
        local fontOpen = false
        fontHd.MouseButton1Click:Connect(function()
            fontOpen = not fontOpen
            if fontOpen then
                openOV(function(ov)
                    local ap=fontHd.AbsolutePosition; local as=fontHd.AbsoluteSize
                    local lh=math.min(#FONTS*26+8,160)
                    local px=math.min(ap.X,SG.AbsoluteSize.X-as.X-10)
                    local py=ap.Y+as.Y+4
                    if py+lh>SG.AbsoluteSize.Y-10 then py=ap.Y-lh-4 end
                    local pan=mk("Frame",{Size=dim2(0,as.X,0,lh),Position=dim2(0,px,0,py),
                        BackgroundColor3=C.BgSideBd,ZIndex=220,Parent=ov})
                    corner(pan,UDim.new(0,5))
                    local sc=mk("ScrollingFrame",{Size=dim2(1,0,1,0),BackgroundTransparency=1,
                        ScrollBarThickness=2,CanvasSize=dim2(0,0,0,0),ZIndex=221,Parent=pan})
                    local scLL=layout(sc,Enum.FillDirection.Vertical,2); padding(sc,4,4,4,4)
                    autoCanvas(sc,scLL)
                    for _, fn2 in ipairs(FONTS) do
                        local ob=mk("TextButton",{Size=dim2(1,0,0,24),Text=fn2,
                            BackgroundColor3=C.BgRow,TextColor3=C.Tx1,
                            TextSize=12,Font=Enum.Font[fn2] or Enum.Font.GothamBold,
                            AutoButtonColor=false,ZIndex=222,Parent=sc})
                        corner(ob,UDim.new(0,4))
                        ob.MouseButton1Click:Connect(function()
                            MenuFont = Enum.Font[fn2] or Enum.Font.GothamBold
                            fontSelLbl.Text = fn2
                            fireFont(MenuFont, VisFont)
                            fontOpen=false; closeOV()
                        end)
                    end
                end)
            else closeOV() end
        end)

        -- Visual (ESP) Font picker
        local visFontWrap = mk("Frame", {Size=dim2(1,0,0,46), BackgroundTransparency=1, Parent=GenPanel})
        mk("TextLabel", {
            Size=dim2(1,0,0,14), BackgroundTransparency=1, Text="Visual (ESP) Font",
            TextColor3=C.Tx2, TextSize=10, Font=Enum.Font.Gotham,
            TextXAlignment=Enum.TextXAlignment.Left, Parent=visFontWrap,
        })
        local visFontHd = mk("TextButton", {
            Size=dim2(1,0,0,26), Position=dim2(0,0,0,18),
            BackgroundColor3=C.BgRow, Text="", AutoButtonColor=false,
            BorderSizePixel=0, Parent=visFontWrap,
        })
        corner(visFontHd, UDim.new(0,5))
        local visFontSelLbl = mk("TextLabel", {
            Size=dim2(1,-22,1,0), Position=dim2(0,8,0,0),
            BackgroundTransparency=1, Text="Monospace",
            TextColor3=C.Tx1, TextSize=12, Font=Enum.Font.Gotham,
            TextXAlignment=Enum.TextXAlignment.Left, Parent=visFontHd,
        })
        mk("TextLabel", {Size=dim2(0,14,1,0),Position=dim2(1,-16,0,0),BackgroundTransparency=1,Text="▾",TextColor3=C.Tx2,TextSize=10,Font=Enum.Font.Gotham,Parent=visFontHd})
        local visFontOpen = false
        visFontHd.MouseButton1Click:Connect(function()
            visFontOpen = not visFontOpen
            if visFontOpen then
                openOV(function(ov)
                    local ap=visFontHd.AbsolutePosition; local as=visFontHd.AbsoluteSize
                    local lh=math.min(#FONTS*26+8,160)
                    local px=math.min(ap.X,SG.AbsoluteSize.X-as.X-10)
                    local py=ap.Y+as.Y+4
                    if py+lh>SG.AbsoluteSize.Y-10 then py=ap.Y-lh-4 end
                    local pan=mk("Frame",{Size=dim2(0,as.X,0,lh),Position=dim2(0,px,0,py),
                        BackgroundColor3=C.BgSideBd,ZIndex=220,Parent=ov})
                    corner(pan,UDim.new(0,5))
                    local sc=mk("ScrollingFrame",{Size=dim2(1,0,1,0),BackgroundTransparency=1,
                        ScrollBarThickness=2,CanvasSize=dim2(0,0,0,0),ZIndex=221,Parent=pan})
                    local scLL=layout(sc,Enum.FillDirection.Vertical,2); padding(sc,4,4,4,4)
                    autoCanvas(sc,scLL)
                    for _, fn2 in ipairs(FONTS) do
                        local ob=mk("TextButton",{Size=dim2(1,0,0,24),Text=fn2,
                            BackgroundColor3=C.BgRow,TextColor3=C.Tx1,
                            TextSize=12,Font=Enum.Font[fn2] or Enum.Font.Code,
                            AutoButtonColor=false,ZIndex=222,Parent=sc})
                        corner(ob,UDim.new(0,4))
                        ob.MouseButton1Click:Connect(function()
                            VisFont = Enum.Font[fn2] or Enum.Font.Code
                            visFontSelLbl.Text = fn2
                            fireFont(MenuFont, VisFont)
                            visFontOpen=false; closeOV()
                        end)
                    end
                end)
            else closeOV() end
        end)

        -- ── Sub-tab: Configs
        local CfgPanel = SetCat:AddSubTab("Configs")
        layout(CfgPanel, Enum.FillDirection.Vertical, 6)
        padding(CfgPanel, 10, 10, 10, 10)

        -- Input + Create button
        local cfgInputRow = mk("Frame", {Size=dim2(1,0,0,28), BackgroundTransparency=1, Parent=CfgPanel})
        local cfgInputFr = mk("Frame", {
            Size=dim2(1,-72,1,0), BackgroundColor3=C.BgRow,
            BorderSizePixel=0, Parent=cfgInputRow,
        })
        corner(cfgInputFr, UDim.new(0,5))
        local cfgInput = mk("TextBox", {
            Size=dim2(1,-8,1,0), Position=dim2(0,4,0,0),
            BackgroundTransparency=1, PlaceholderText="config name...",
            Text="", TextColor3=C.Tx0, PlaceholderColor3=C.Tx2,
            TextSize=11, Font=Enum.Font.Gotham, ClearTextOnFocus=false, Parent=cfgInputFr,
        })
        local cfgCreateBtn = mk("TextButton", {
            Size=dim2(0,64,1,0), Position=dim2(1,-66,0,0),
            BackgroundColor3=AC, Text="+ Create",
            TextColor3=C.White, TextSize=10, Font=Enum.Font.GothamBold,
            AutoButtonColor=false, BorderSizePixel=0, Parent=cfgInputRow,
        })
        corner(cfgCreateBtn, UDim.new(0,5))
        onAC(function(c) cfgCreateBtn.BackgroundColor3 = c end)

        -- Config list
        local cfgListSF = mk("ScrollingFrame", {
            Size=dim2(1,0,1,-40), Position=dim2(0,0,0,34),
            BackgroundTransparency=1, ScrollBarThickness=2,
            ScrollBarImageColor3=C.Toggle, BorderSizePixel=0,
            CanvasSize=dim2(0,0,0,0), Parent=CfgPanel,
        })
        local cfgLL = layout(cfgListSF, Enum.FillDirection.Vertical, 4)
        autoCanvas(cfgListSF, cfgLL)

        local function refreshCfgList()
            for _, ch in ipairs(cfgListSF:GetChildren()) do
                if not ch:IsA("UIListLayout") then ch:Destroy() end
            end
            local list = CFGSYS.list()
            if #list == 0 then
                mk("TextLabel", {
                    Size=dim2(1,0,0,30), BackgroundTransparency=1,
                    Text="No configs yet. Type a name and click + Create.",
                    TextColor3=C.Tx2, TextSize=10, Font=Enum.Font.Gotham,
                    TextWrapped=true, Parent=cfgListSF,
                })
                return
            end
            for _, cname in ipairs(list) do
                local row2 = mk("Frame", {
                    Size=dim2(1,0,0,32), BackgroundColor3=C.BgRow,
                    BorderSizePixel=0, Parent=cfgListSF,
                })
                corner(row2, UDim.new(0,5))
                mk("TextLabel", {
                    Size=dim2(1,-94,1,0), Position=dim2(0,8,0,0),
                    BackgroundTransparency=1, Text=cname, TextColor3=C.Tx1,
                    TextSize=11, Font=Enum.Font.Gotham,
                    TextXAlignment=Enum.TextXAlignment.Left,
                    TextTruncate=Enum.TextTruncate.AtEnd, Parent=row2,
                })
                local function smBtn(txt, xOff, col2, cb2)
                    local b = mk("TextButton", {
                        Size=dim2(0,26,0,20), Position=dim2(1,xOff,0.5,-10),
                        BackgroundColor3=col2, Text=txt, TextColor3=C.Tx0,
                        TextSize=9, Font=Enum.Font.GothamBold,
                        AutoButtonColor=false, BorderSizePixel=0, Parent=row2,
                    })
                    corner(b, UDim.new(0,4))
                    b.MouseButton1Click:Connect(cb2)
                end
                smBtn("L", -88, rgb(28,70,45), function()
                    if CFGSYS.load(cname) then
                        notify({Title="Loaded",Desc=cname,Type="Success",Duration=2})
                    else
                        notify({Title="Load Failed",Desc=cname,Type="Error",Duration=2})
                    end
                end)
                smBtn("S", -58, rgb(28,45,70), function()
                    if CFGSYS.save(cname) then notify({Title="Saved",Desc=cname,Type="Success",Duration=2})
                    else notify({Title="Save Failed",Type="Error",Duration=2}) end
                end)
                smBtn("X", -28, rgb(70,28,28), function()
                    CFGSYS.delete(cname); refreshCfgList()
                    notify({Title="Deleted",Desc=cname,Type="Warning",Duration=2})
                end)
            end
        end

        cfgCreateBtn.MouseButton1Click:Connect(function()
            local cname = cfgInput.Text ~= "" and cfgInput.Text or ("Config"..tostring(#CFGSYS.list()+1))
            cname = cname:gsub("[^%w%-%_]","_"); cfgInput.Text=""
            if CFGSYS.save(cname) then
                notify({Title="Created",Desc=cname,Type="Success",Duration=2}); refreshCfgList()
            else
                notify({Title="Create Failed",Type="Error",Duration=3})
            end
        end)

        task.defer(refreshCfgList)
    end

    -- ── Build settings on next frame so user categories go first
    task.defer(buildSettingsCategory)

    -- ── Animate in
    task.defer(function()
        Main.Visible=true
        Main.Size=dim2(0,WIN_W*0.88,0,WIN_H*0.88)
        tw(Main,{Size=dim2(0,WIN_W,0,WIN_H)},0.24,Enum.EasingStyle.Quint,Enum.EasingDirection.Out)
    end)

    -- ── Expose VisFont getter for ESP drawing code
    function WO:GetVisFont() return VisFont end
    function WO:OnVisFont(fn) onFont(function(_, vf) fn(vf) end) end

    return WO
end

return Peleccos
