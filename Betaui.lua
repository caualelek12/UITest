--[[
    PeleccosSoftwares v12.0
    Redesigned from scratch — bar sits above Roblox safe-area inset,
    Milenium-inspired internals, no generic AI aesthetics.

    API:
        local Lib = loadstring(readfile("PeleccosSoftwares_v12.lua"))()
        local Win = Lib:CreateWindow({
            Title       = "MyScript",
            Background  = "rbxassetid://118298630077545",
            AccentColor = Color3.fromRGB(180, 180, 180),
            Key         = Enum.KeyCode.Insert,
            UserName    = "Player",
            ConfigName  = "Default",
            BuildType   = "Public",
        })
        local Cat = Win:AddCategory("Combat")
        Cat:AddToggle({ Name="Aimbot", Default=false, Callback=function(v) end })
        Cat:AddSlider({ Name="FOV", Min=10, Max=360, Step=1, Default=90, Suffix="°", Callback=function(v) end })
        Cat:AddButton({ Name="Teleport", Callback=function() end })
        Cat:AddLabel({ Text="v1.0" })
        Cat:AddDropdown({ Name="Team", Options={"Red","Blue"}, Callback=function(v) end })
        Cat:AddColorPicker({ Name="Color", Default=Color3.fromRGB(255,80,80), Callback=function(c) end })
        Cat:AddKeybind({ Name="Quick Toggle", Default=Enum.KeyCode.F, Callback=function() end })
        Cat:AddTextbox({ Name="Player", Placeholder="name...", Callback=function(v) end })
        Cat:AddProgressBar({ Name="Loading", Max=100, Default=72 })
]]

-- ═══════════════════════════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════════════════════════
local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")
local GuiService   = game:GetService("GuiService")
local LP           = Players.LocalPlayer

-- Safe-area inset (how many pixels Roblox pushes the top bar down)
local GUI_INSET = GuiService:GetGuiInset().Y  -- typically 36px

-- ═══════════════════════════════════════════════════════════════
-- FOLDERS
-- ═══════════════════════════════════════════════════════════════
local _DIR = "PeleccosSoftwares"
pcall(function() if not isfolder(_DIR) then makefolder(_DIR) end end)
pcall(function() if not isfolder(_DIR.."/videos") then makefolder(_DIR.."/videos") end end)
pcall(function() if not isfolder(_DIR.."/configs") then makefolder(_DIR.."/configs") end end)

-- ═══════════════════════════════════════════════════════════════
-- PRIMITIVE HELPERS
-- ═══════════════════════════════════════════════════════════════
local rgb  = Color3.fromRGB
local hsv  = Color3.fromHSV
local dim2 = UDim2.new
local dim  = UDim.new

local function tw(obj, props, style, t, dir)
    TweenService:Create(obj, TweenInfo.new(
        t or 0.22,
        style or Enum.EasingStyle.Quint,
        dir or Enum.EasingDirection.Out
    ), props):Play()
end

local function mk(cls, props)
    local o = Instance.new(cls)
    for k,v in pairs(props or {}) do
        if k ~= "Parent" then o[k] = v end
    end
    if props and props.Parent then o.Parent = props.Parent end
    return o
end

-- corner radius presets
local RC = {
    none  = dim(0,0),
    sharp = dim(0,3),   -- outer shell (blocky feel)
    soft  = dim(0,5),   -- inner elements
    mid   = dim(0,7),   -- section headers, cards
    pill  = dim(0,999), -- toggle tracks, accents
}

local function corner(p, r)  local c=Instance.new("UICorner"); c.CornerRadius=r or RC.soft;   c.Parent=p; return c end
local function stroke(p,col,t) local s=Instance.new("UIStroke"); s.Color=col or rgb(35,35,38); s.Thickness=t or 1; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=p; return s end
local function padding(p,t,r,b,l) local u=Instance.new("UIPadding"); u.PaddingTop=dim(0,t or 0); u.PaddingRight=dim(0,r or 0); u.PaddingBottom=dim(0,b or 0); u.PaddingLeft=dim(0,l or 0); u.Parent=p; return u end
local function layout(p,dir,gap,ha,va) local l=Instance.new("UIListLayout"); l.FillDirection=dir or Enum.FillDirection.Vertical; l.Padding=dim(0,gap or 0); l.HorizontalAlignment=ha or Enum.HorizontalAlignment.Left; l.VerticalAlignment=va or Enum.VerticalAlignment.Top; l.SortOrder=Enum.SortOrder.LayoutOrder; l.Parent=p; return l end
local function autoCanvas(sf)
    local ll = sf:FindFirstChildOfClass("UIListLayout"); if not ll then return end
    local function upd() task.defer(function() if sf and sf.Parent then sf.CanvasSize=dim2(0,0,0,ll.AbsoluteContentSize.Y+14) end end) end
    ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(upd); upd()
end
local function draggify(frame, handle)
    local drag,ds,sp = false,nil,nil
    handle = handle or frame
    handle.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true; ds=i.Position; sp=frame.Position end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=i.Position-ds
            frame.Position=dim2(sp.X.Scale, sp.X.Offset+d.X, sp.Y.Scale, sp.Y.Offset+d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)
end

-- ═══════════════════════════════════════════════════════════════
-- PALETTE  (Milenium-inspired dark grey, minimal)
-- ═══════════════════════════════════════════════════════════════
local C = {
    -- backgrounds
    bg0      = rgb(14, 14, 16),   -- deepest bg (main window)
    bg1      = rgb(19, 19, 21),   -- section shell
    bg2      = rgb(22, 22, 24),   -- section inner
    bg3      = rgb(28, 28, 31),   -- element bg / input
    bg4      = rgb(33, 33, 36),   -- button / slider track
    -- borders
    br0      = rgb(23, 23, 29),   -- outer stroke
    br1      = rgb(36, 36, 38),   -- separator
    br2      = rgb(50, 50, 54),   -- highlight stroke
    -- text
    t0       = rgb(245,245,248),  -- primary text
    t1       = rgb(175,175,182),  -- secondary text
    t2       = rgb(95, 95,100),   -- muted / placeholder
    -- notification types
    nOk      = rgb(50,200,100),
    nWarn    = rgb(255,185,0),
    nErr     = rgb(255,60,60),
    nInfo    = rgb(0,130,255),
}

-- ═══════════════════════════════════════════════════════════════
-- FPS / PING  (live)
-- ═══════════════════════════════════════════════════════════════
local _fps, _ping = 60, 0
RunService.Heartbeat:Connect(function(dt) _fps = math.clamp(math.floor(1/dt),0,999) end)
task.spawn(function()
    while true do
        local s=tick()
        pcall(function() game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() end)
        _ping=math.floor((tick()-s)*1000); task.wait(2)
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- EASTER EGG DATA
-- ═══════════════════════════════════════════════════════════════
local EASTER_VIDS = {
    {id="MUwoJJNAwhI",loop=false},{id="pKBTU3jTUQU",loop=false},
    {id="KcrtcnvkcWQ",loop=true },{id="HnH1MgwJFvY",loop=false},
    {id="igmpRziaOqc",loop=false},{id="I0lA3rHbFuE",loop=false},
    {id="u-fOF9Wlpd8",loop=false},{id="PHvhOPM_5ak",loop=true },
    {id="Fy69pNzf9iE",loop=false},{id="7xO4u-lzsYU",loop=false},
    {id="WnOWVSYNMFw",loop=false},{id="1L1WkeRR-EQ",loop=true },
    {id="NoR9zrJiSLc",loop=false},{id="JabG22Zl02I",loop=false},
    {id="YmHZI03a_Yo",loop=false},{id="mHJ3l18YqNM",loop=false},
}
local EASTER_KW = {"peleccos","easter","egg","secret","hidden","password","cheat","hack","admin","god","infinite","unlimited","special","rare","legendary"}

-- ═══════════════════════════════════════════════════════════════
-- NOTIFICATION SYSTEM  (Milenium-style, bottom-left stacking)
-- ═══════════════════════════════════════════════════════════════
local _notifHolder, _notifList = nil, {}

local function initNotifs(sg)
    -- bottom-right corner, above safe area
    _notifHolder = mk("Frame",{
        Size=dim2(0,240,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        AnchorPoint=Vector2.new(1,1),
        Position=dim2(1,-12,1,-12),
        BackgroundTransparency=1, ZIndex=500, Parent=sg,
    })
    layout(_notifHolder, Enum.FillDirection.Vertical, 6, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Bottom)
end

local function notify(o)
    if not _notifHolder then return end
    o = o or {}
    local ac = ({Success=C.nOk,Warning=C.nWarn,Error=C.nErr,Info=C.nInfo})[o.Type or "Info"] or C.nInfo

    local card = mk("Frame",{
        Size=dim2(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundColor3=C.bg1, BackgroundTransparency=1,
        ZIndex=501, Parent=_notifHolder,
    })
    corner(card, RC.sharp)
    stroke(card, C.br0, 1)

    -- left accent bar
    local bar = mk("Frame",{Size=dim2(0,3,1,0), BackgroundColor3=ac, ZIndex=502, Parent=card})

    local inner = mk("Frame",{
        Size=dim2(1,-3,1,0), Position=dim2(0,3,0,0),
        BackgroundTransparency=1, ZIndex=502, Parent=card,
    })
    padding(inner, 9,9,9,10)
    layout(inner, Enum.FillDirection.Vertical, 4)

    -- type badge + title row
    local hrow = mk("Frame",{
        Size=dim2(1,0,0,16), BackgroundTransparency=1, ZIndex=503, Parent=inner,
    })
    layout(hrow, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

    local typeTxt = ({Success="OK",Warning="!!",Error="XX",Info="??"})[o.Type or "Info"] or "??"
    local badge = mk("TextLabel",{
        Text=typeTxt, Size=dim2(0,22,0,14),
        BackgroundColor3=ac, TextColor3=C.t0,
        TextSize=9, Font=Enum.Font.GothamBold,
        ZIndex=503, Parent=hrow,
    })
    corner(badge, RC.sharp)

    mk("TextLabel",{
        Text=o.Title or "Notice",
        Size=dim2(1,-28,1,0),
        BackgroundTransparency=1, TextColor3=C.t0,
        TextSize=12, Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Left,
        ZIndex=503, Parent=hrow,
    })

    if o.Desc and o.Desc ~= "" then
        mk("TextLabel",{
            Text=o.Desc,
            Size=dim2(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
            BackgroundTransparency=1, TextColor3=C.t2,
            TextSize=10, Font=Enum.Font.Gotham,
            TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true,
            ZIndex=503, Parent=inner,
        })
    end

    -- progress bar at bottom of card
    local progBg = mk("Frame",{
        Size=dim2(1,0,0,2), BackgroundColor3=C.bg4, ZIndex=503, Parent=inner,
    })
    local progFill = mk("Frame",{
        Size=dim2(1,0,1,0), BackgroundColor3=ac, ZIndex=504, Parent=progBg,
    })

    -- animate in
    tw(card, {BackgroundTransparency=0, Position=dim2(0,0,0,0)}, Enum.EasingStyle.Back, 0.3, Enum.EasingDirection.Out)
    local dur = o.Duration or 4
    tw(progFill, {Size=dim2(0,0,1,0)}, Enum.EasingStyle.Linear, dur)
    task.delay(dur, function()
        tw(card, {BackgroundTransparency=1}, Enum.EasingStyle.Quint, 0.2)
        task.wait(0.22); pcall(function() card:Destroy() end)
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- HSV COLOR PICKER  (shared builder)
-- ═══════════════════════════════════════════════════════════════
local function buildColorPicker(ov, anchor, h0, s0, v0, onUpdate, SG_ref)
    local ch,cs,cv = h0,s0,v0
    local pw,ph = 210,148
    local ap = anchor.AbsolutePosition
    local px = math.min(ap.X, SG_ref.AbsoluteSize.X-pw-10)
    local py = ap.Y + anchor.AbsoluteSize.Y + 6
    if py+ph > SG_ref.AbsoluteSize.Y-10 then py = ap.Y - ph - 6 end

    local pan = mk("TextButton",{
        AutoButtonColor=false, Text="",
        Size=dim2(0,pw,0,0),
        Position=dim2(0,px,0,py),
        BackgroundColor3=C.bg1, ZIndex=220, Parent=ov,
    })
    corner(pan, RC.sharp); stroke(pan, C.br0, 1)
    tw(pan, {Size=dim2(0,pw,0,ph)}, Enum.EasingStyle.Back, 0.18)

    -- SV field
    local svbg = mk("Frame",{
        Size=dim2(1,-12,0,84), Position=dim2(0,6,0,6),
        BackgroundColor3=hsv(ch,1,1), ZIndex=221, Parent=pan,
    })
    corner(svbg, RC.sharp)

    -- white gradient (sat)
    local wg = mk("Frame",{Size=dim2(1,0,1,0), BackgroundColor3=rgb(255,255,255), ZIndex=222, Parent=svbg})
    corner(wg, RC.sharp)
    mk("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)}), Parent=wg})
    -- black gradient (val)
    local bg2 = mk("Frame",{Size=dim2(1,0,1,0), BackgroundColor3=rgb(0,0,0), ZIndex=223, Parent=svbg})
    corner(bg2, RC.sharp)
    mk("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)}), Rotation=90, Parent=bg2})

    -- SV cursor
    local svc = mk("TextButton",{
        AutoButtonColor=false, Text="",
        AnchorPoint=Vector2.new(.5,.5),
        Size=dim2(0,9,0,9),
        Position=dim2(cs,0,1-cv,0),
        BackgroundColor3=rgb(255,255,255), ZIndex=226, Parent=svbg,
    })
    corner(svc, RC.pill)
    stroke(svc, rgb(0,0,0), 1.5)

    -- hue bar
    local hueBar = mk("TextButton",{
        AutoButtonColor=false, Text="",
        Size=dim2(1,-12,0,9),
        Position=dim2(0,6,0,96),
        ZIndex=221, Parent=pan,
    })
    corner(hueBar, RC.pill)
    mk("UIGradient",{Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,   rgb(255,0,0)),
        ColorSequenceKeypoint.new(0.17,rgb(255,255,0)),
        ColorSequenceKeypoint.new(0.33,rgb(0,255,0)),
        ColorSequenceKeypoint.new(0.5, rgb(0,255,255)),
        ColorSequenceKeypoint.new(0.67,rgb(0,0,255)),
        ColorSequenceKeypoint.new(0.83,rgb(255,0,255)),
        ColorSequenceKeypoint.new(1,   rgb(255,0,0)),
    }), Parent=hueBar})
    local hueCursor = mk("Frame",{
        AnchorPoint=Vector2.new(.5,.5),
        Size=dim2(0,9,1,2),
        Position=dim2(ch,0,.5,0),
        BackgroundColor3=rgb(255,255,255), ZIndex=223, Parent=hueBar,
    })
    corner(hueCursor, RC.sharp)
    stroke(hueCursor, rgb(0,0,0), 1)

    -- preview
    local prev = mk("Frame",{
        Size=dim2(1,-12,0,11),
        Position=dim2(0,6,0,113),
        BackgroundColor3=hsv(ch,cs,cv),
        ZIndex=221, Parent=pan,
    })
    corner(prev, RC.sharp)

    local function upd()
        local col = hsv(ch,cs,cv)
        svbg.BackgroundColor3 = hsv(ch,1,1)
        svc.Position = dim2(cs,0,1-cv,0)
        hueCursor.Position = dim2(ch,0,.5,0)
        prev.BackgroundColor3 = col
        onUpdate(col, ch, cs, cv)
    end

    local dragSV, dragHue = false, false
    svbg.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            dragSV=true
            cs=math.clamp((i.Position.X-svbg.AbsolutePosition.X)/svbg.AbsoluteSize.X,0,1)
            cv=1-math.clamp((i.Position.Y-svbg.AbsolutePosition.Y)/svbg.AbsoluteSize.Y,0,1)
            upd()
        end
    end)
    hueBar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            dragHue=true
            ch=math.clamp((i.Position.X-hueBar.AbsolutePosition.X)/hueBar.AbsoluteSize.X,0,1)
            upd()
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if i.UserInputType~=Enum.UserInputType.MouseMovement then return end
        if dragSV then
            cs=math.clamp((i.Position.X-svbg.AbsolutePosition.X)/svbg.AbsoluteSize.X,0,1)
            cv=1-math.clamp((i.Position.Y-svbg.AbsolutePosition.Y)/svbg.AbsoluteSize.Y,0,1)
            upd()
        end
        if dragHue then
            ch=math.clamp((i.Position.X-hueBar.AbsolutePosition.X)/hueBar.AbsoluteSize.X,0,1)
            upd()
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dragSV=false; dragHue=false end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- LIBRARY
-- ═══════════════════════════════════════════════════════════════
local Peleccos = {}; Peleccos.__index = Peleccos

function Peleccos:CreateWindow(o)
    o = o or {}

    -- destroy previous instance
    for _, name in ipairs({"PeleccosV12"}) do
        pcall(function() game:GetService("CoreGui"):FindFirstChild(name):Destroy() end)
        pcall(function() local pg=LP:FindFirstChild("PlayerGui"); if pg then local x=pg:FindFirstChild(name); if x then x:Destroy() end end end)
    end

    local AC  = o.AccentColor or rgb(180,180,180)
    local KEY = o.Key or Enum.KeyCode.Insert
    local BG_IMAGE = o.Background or "rbxassetid://118298630077545"

    -- accent callbacks
    local _acCBs = {}
    local function onAC(fn) table.insert(_acCBs,fn) end
    local function fireAC() for _,fn in ipairs(_acCBs) do pcall(fn,AC) end end

    -- live config / watermark state
    local CFG = {
        ScriptName = o.Title      or "PeleccosSoftwares",
        UserName   = o.UserName   or (LP and LP.Name or "User"),
        ConfigName = o.ConfigName or "Default",
        BuildType  = o.BuildType  or "Public",
        GameName   = o.GameName   or tostring(game.Name or "Unknown"),
        GameId     = o.GameId     or tostring(game.GameId or 0),
        BgColor    = o.BgColor    or rgb(14,14,16),
        ShowWM     = true,
    }

    -- ── ScreenGui with IgnoreGuiInset so we can go above the top bar ──
    local SG = mk("ScreenGui",{
        Name="PeleccosV12",
        ResetOnSpawn=false,
        ZIndexBehavior=Enum.ZIndexBehavior.Global,
        IgnoreGuiInset=true,   -- key: renders from pixel (0,0), above safe area
    })
    local ok = pcall(function() SG.Parent = game:GetService("CoreGui") end)
    if not ok then SG.Parent = LP:WaitForChild("PlayerGui") end

    initNotifs(SG)

    -- overlay root for dropdowns / pickers
    local _ovRoot = mk("Frame",{Name="OvRoot",Size=dim2(1,0,1,0),BackgroundTransparency=1,ZIndex=200,Parent=SG})
    local _ovActive = nil
    local function closeOV() if _ovActive then _ovActive:Destroy(); _ovActive=nil end end
    local function openOV(fn)
        closeOV()
        local f = mk("Frame",{Size=dim2(1,0,1,0),BackgroundTransparency=1,ZIndex=200,Parent=_ovRoot})
        local bg = mk("TextButton",{Size=dim2(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=200,Parent=f})
        local ok2=false; task.delay(0.12,function() ok2=true end)
        bg.MouseButton1Click:Connect(function() if ok2 then closeOV() end end)
        _ovActive=f; fn(f)
    end

    -- ══════════════════════════════════════════════════════════
    -- TOP BAR  — IgnoreGuiInset lets us sit at Y=0, above Roblox chrome
    -- Height is fixed at GUI_INSET pixels so it fills exactly the top strip
    -- ══════════════════════════════════════════════════════════
    local BAR_H = math.max(GUI_INSET, 28)  -- at least 28px tall

    local BAR = mk("Frame",{
        Name="Bar",
        Size=dim2(1,0,0,BAR_H),
        Position=dim2(0,0,0,0),   -- literal screen top
        BackgroundColor3=rgb(10,10,12),
        BorderSizePixel=0,
        ZIndex=50,
        Parent=SG,
    })
    -- thin accent bottom-line
    local barLine = mk("Frame",{
        Size=dim2(1,0,0,1), AnchorPoint=Vector2.new(0,1),
        Position=dim2(0,0,1,0),
        BackgroundColor3=AC, ZIndex=51, Parent=BAR,
    })
    onAC(function(c) barLine.BackgroundColor3=c end)

    -- Easter Egg button (left, hidden)
    local EGG_BTN = mk("TextButton",{
        Text="Easter Egg",
        TextColor3=C.t0, TextSize=11, Font=Enum.Font.GothamSemibold,
        BackgroundColor3=C.bg4,
        Size=dim2(0,90,0,BAR_H-6),
        Position=dim2(0,3,0,3),
        AutoButtonColor=false, BorderSizePixel=0,
        ZIndex=52, Visible=false, Parent=BAR,
    })
    corner(EGG_BTN, RC.sharp)
    stroke(EGG_BTN, C.br0, 1)
    EGG_BTN.MouseEnter:Connect(function() tw(EGG_BTN,{BackgroundColor3=C.bg3},Enum.EasingStyle.Quint,0.1) end)
    EGG_BTN.MouseLeave:Connect(function() tw(EGG_BTN,{BackgroundColor3=C.bg4},Enum.EasingStyle.Quint,0.1) end)

    -- Settings button (right)
    local SET_BTN = mk("TextButton",{
        Text="Settings",
        TextColor3=C.t1, TextSize=11, Font=Enum.Font.GothamSemibold,
        BackgroundColor3=C.bg4,
        Size=dim2(0,68,0,BAR_H-6),
        Position=dim2(1,-71,0,3),
        AutoButtonColor=false, BorderSizePixel=0,
        ZIndex=52, Parent=BAR,
    })
    corner(SET_BTN, RC.sharp)
    stroke(SET_BTN, C.br0, 1)
    SET_BTN.MouseEnter:Connect(function() tw(SET_BTN,{BackgroundColor3=C.bg3,TextColor3=C.t0},Enum.EasingStyle.Quint,0.1) end)
    SET_BTN.MouseLeave:Connect(function() tw(SET_BTN,{BackgroundColor3=C.bg4,TextColor3=C.t1},Enum.EasingStyle.Quint,0.1) end)

    -- Category scroll (centre)
    local CAT_SF = mk("ScrollingFrame",{
        BackgroundTransparency=1, BorderSizePixel=0,
        ScrollingDirection=Enum.ScrollingDirection.X,
        CanvasSize=dim2(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.X,
        ScrollBarThickness=0,
        ZIndex=52, Parent=BAR,
    })
    layout(CAT_SF, Enum.FillDirection.Horizontal, 2, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)

    local function repositionBar()
        local eW = EGG_BTN.Visible and 96 or 2
        CAT_SF.Position = dim2(0,eW+2,0,0)
        CAT_SF.Size     = dim2(1,-(eW+74),1,0)
    end
    repositionBar()
    EGG_BTN:GetPropertyChangedSignal("Visible"):Connect(repositionBar)

    -- ══════════════════════════════════════════════════════════
    -- WATERMARK — anchored below top bar, always on SG
    -- ══════════════════════════════════════════════════════════
    local WM = mk("Frame",{
        Name="Watermark",
        Size=dim2(0,600,0,18),
        Position=dim2(0,8,0,BAR_H+4),
        BackgroundColor3=rgb(10,10,12),
        BackgroundTransparency=0.08,
        BorderSizePixel=0,
        ZIndex=30, Parent=SG,
    })
    stroke(WM, C.br0, 1)  -- no corner = flat/square

    local wmRow = mk("Frame",{
        Size=dim2(1,-10,1,0), Position=dim2(0,5,0,0),
        BackgroundTransparency=1, ZIndex=31, Parent=WM,
    })
    layout(wmRow, Enum.FillDirection.Horizontal, 0, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

    local wmLabels = {}
    local function wmSep()
        mk("TextLabel",{Text=" | ",Size=dim2(0,14,1,0),BackgroundTransparency=1,TextColor3=C.br1,TextSize=10,Font=Enum.Font.Gotham,ZIndex=31,Parent=wmRow})
    end
    local function wmLbl(key, txt, bold)
        local lbl = mk("TextLabel",{
            Text=tostring(txt), Size=dim2(0,0,1,0), AutomaticSize=Enum.AutomaticSize.X,
            BackgroundTransparency=1,
            TextColor3 = (key=="script") and AC or C.t1,
            TextSize=10,
            Font=(bold or key=="script") and Enum.Font.GothamBold or Enum.Font.Gotham,
            ZIndex=31, Parent=wmRow,
        })
        if key=="script" then onAC(function(c) lbl.TextColor3=c end) end
        return lbl
    end
    wmLabels.script = wmLbl("script", CFG.ScriptName, true); wmSep()
    wmLabels.user   = wmLbl("user",   CFG.UserName);         wmSep()
    wmLabels.config = wmLbl("config", CFG.ConfigName);       wmSep()
    wmLabels.fps    = wmLbl("fps",    "FPS: --");             wmSep()
    wmLabels.ping   = wmLbl("ping",   "Ping: --ms");          wmSep()
    wmLabels.build  = wmLbl("build",  "["..CFG.BuildType.."]"); wmSep()
    wmLabels.game   = wmLbl("game",   CFG.GameName.." ("..CFG.GameId..")")
    draggify(WM, WM)

    RunService.Heartbeat:Connect(function()
        pcall(function()
            wmLabels.fps.Text  = "FPS: "..tostring(_fps)
            wmLabels.ping.Text = "Ping: "..tostring(_ping).."ms"
        end)
    end)

    local function wmSet(key, val)
        CFG[key]=val
        if key=="ScriptName" then wmLabels.script.Text=val
        elseif key=="UserName"   then wmLabels.user.Text=val
        elseif key=="ConfigName" then wmLabels.config.Text=val
        elseif key=="BuildType"  then wmLabels.build.Text="["..val.."]"
        elseif key=="GameName"   then wmLabels.game.Text=val.." ("..CFG.GameId..")"
        elseif key=="GameId"     then wmLabels.game.Text=CFG.GameName.." ("..val..")"
        end
    end

    -- ══════════════════════════════════════════════════════════
    -- MAIN BACKGROUND WINDOW
    -- Positioned below BAR (offset by BAR_H) using absolute coords
    -- ══════════════════════════════════════════════════════════
    local BG = mk("Frame",{
        Name="Background",
        BackgroundColor3=CFG.BgColor,
        BorderSizePixel=0,
        Size=dim2(0.32558,0,0,0),   -- width = 32% of screen
        -- height computed below after we know screen size
        ZIndex=2, Parent=SG,
    })
    -- We set height and position after SG has a size
    task.defer(function()
        local sv = SG.AbsoluteSize
        local winH = math.floor(sv.Y * 0.85) - BAR_H
        local winW = math.floor(sv.X * 0.32558)
        BG.Size     = dim2(0,winW,0,winH)
        BG.Position = dim2(0, math.floor(sv.X*0.35349), 0, BAR_H + math.floor((sv.Y-BAR_H)*0.10))
    end)
    stroke(BG, C.br0, 1)  -- no UICorner = fully square outer border

    -- Image inside BG
    local BG_IMG = mk("ImageLabel",{
        Name="Image", BorderSizePixel=0,
        BackgroundColor3=rgb(8,8,10),
        AnchorPoint=Vector2.new(.5,.5),
        Image=BG_IMAGE,
        Size=dim2(1,-2,1,-2),
        Position=dim2(.5,0,.5,0),
        ZIndex=2, Parent=BG,
    })
    corner(BG_IMG, RC.sharp)

    -- dark overlay (readability)
    local overlay = mk("Frame",{
        Size=dim2(1,0,1,0), BackgroundColor3=rgb(0,0,0),
        BackgroundTransparency=0.40, ZIndex=3, Parent=BG_IMG,
    })
    corner(overlay, RC.sharp)

    -- drag handle (full image area, below content)
    local dragHandle = mk("TextButton",{
        Size=dim2(1,0,1,0), BackgroundTransparency=1,
        Text="", AutoButtonColor=false, ZIndex=3, Parent=BG_IMG,
    })
    draggify(BG, dragHandle)

    -- content scroll
    local CONTENT = mk("ScrollingFrame",{
        Size=dim2(1,-8,1,-8), Position=dim2(0,4,0,4),
        BackgroundTransparency=1,
        ScrollBarThickness=2, ScrollBarImageColor3=AC,
        CanvasSize=dim2(0,0,0,0),
        ZIndex=5, Parent=BG_IMG,
    })
    onAC(function(c) CONTENT.ScrollBarImageColor3=c end)
    local contentLL = layout(CONTENT, Enum.FillDirection.Vertical, 7)
    padding(CONTENT, 6,4,6,4)
    contentLL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        task.defer(function()
            if CONTENT and CONTENT.Parent then
                CONTENT.CanvasSize = dim2(0,0,0, contentLL.AbsoluteContentSize.Y+18)
            end
        end)
    end)

    -- ══════════════════════════════════════════════════════════
    -- SETTINGS WINDOW  — same visual DNA as main window
    -- ══════════════════════════════════════════════════════════
    local SW = mk("Frame",{
        Name="SettingsWin",
        BackgroundColor3=CFG.BgColor,
        BorderSizePixel=0,
        Size=dim2(0,310,0,480),
        Position=dim2(.5,-155,.5,-240),
        ZIndex=100, Visible=false, Parent=SG,
    })
    stroke(SW, C.br0, 1)  -- square, matching BG

    local SW_IMG = mk("ImageLabel",{
        BorderSizePixel=0,
        BackgroundColor3=rgb(8,8,10),
        AnchorPoint=Vector2.new(.5,.5),
        Image=BG_IMAGE,
        Size=dim2(1,-2,1,-2),
        Position=dim2(.5,0,.5,0),
        ZIndex=101, Parent=SW,
    })
    corner(SW_IMG, RC.sharp)
    local sw_ov2 = mk("Frame",{
        Size=dim2(1,0,1,0), BackgroundColor3=rgb(0,0,0),
        BackgroundTransparency=0.40, ZIndex=102, Parent=SW_IMG,
    })
    corner(sw_ov2, RC.sharp)

    -- Settings title bar (drag handle)
    local SW_HDR = mk("Frame",{
        Size=dim2(1,0,0,28),
        BackgroundColor3=rgb(0,0,0), BackgroundTransparency=0.45,
        ZIndex=103, Parent=SW_IMG,
    })
    local sw_accent = mk("Frame",{
        Size=dim2(1,0,0,1), AnchorPoint=Vector2.new(0,1),
        Position=dim2(0,0,1,0),
        BackgroundColor3=AC, ZIndex=104, Parent=SW_HDR,
    })
    onAC(function(c) sw_accent.BackgroundColor3=c end)
    mk("TextLabel",{
        Text="Settings",
        Size=dim2(1,-36,1,0), Position=dim2(0,10,0,0),
        BackgroundTransparency=1, TextColor3=C.t0,
        TextSize=12, Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Left,
        ZIndex=104, Parent=SW_HDR,
    })
    local SW_X = mk("TextButton",{
        Text="X",
        Size=dim2(0,22,0,20), Position=dim2(1,-24,0,4),
        BackgroundColor3=rgb(48,18,18), TextColor3=C.t0,
        TextSize=10, Font=Enum.Font.GothamBold,
        AutoButtonColor=false, ZIndex=105, Parent=SW_HDR,
    })
    corner(SW_X, RC.sharp)
    SW_X.MouseButton1Click:Connect(function() SW.Visible=false end)
    draggify(SW, SW_HDR)

    -- Settings scroll
    local SW_SF = mk("ScrollingFrame",{
        Size=dim2(1,-6,1,-30), Position=dim2(0,3,0,28),
        BackgroundTransparency=1,
        ScrollBarThickness=2, ScrollBarImageColor3=AC,
        CanvasSize=dim2(0,0,0,0),
        ZIndex=103, Parent=SW_IMG,
    })
    onAC(function(c) SW_SF.ScrollBarImageColor3=c end)
    local swLL = layout(SW_SF, Enum.FillDirection.Vertical, 5)
    padding(SW_SF, 6,6,6,6)
    swLL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        task.defer(function()
            if SW_SF and SW_SF.Parent then SW_SF.CanvasSize=dim2(0,0,0,swLL.AbsoluteContentSize.Y+14) end
        end)
    end)

    -- ── Settings widget builders ──────────────────────────────
    local function swSection(title)
        local f = mk("Frame",{
            Size=dim2(1,0,0,16), BackgroundColor3=rgb(0,0,0),
            BackgroundTransparency=0.55, ZIndex=104, Parent=SW_SF,
        })
        padding(f,0,0,0,4)
        local lbl = mk("TextLabel",{
            Text=title:upper(),
            Size=dim2(1,-4,1,0),
            BackgroundTransparency=1, TextColor3=AC,
            TextSize=9, Font=Enum.Font.GothamBold,
            TextXAlignment=Enum.TextXAlignment.Left,
            ZIndex=105, Parent=f,
        })
        onAC(function(c) lbl.TextColor3=c end)
    end

    local function swRow(h)
        local r=mk("Frame",{
            Size=dim2(1,0,0,h or 24),
            BackgroundColor3=C.bg3, BackgroundTransparency=0.45,
            ZIndex=104, Parent=SW_SF,
        })
        corner(r, RC.sharp)
        return r
    end

    local function swTextbox(lbl_text, defVal, onChange)
        local wrap=mk("Frame",{Size=dim2(1,0,0,38),BackgroundTransparency=1,ZIndex=104,Parent=SW_SF})
        mk("TextLabel",{Text=lbl_text,Size=dim2(1,0,0,13),BackgroundTransparency=1,TextColor3=C.t2,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=105,Parent=wrap})
        local ifrm=mk("Frame",{Size=dim2(1,0,0,22),Position=dim2(0,0,0,15),BackgroundColor3=C.bg3,ZIndex=105,Parent=wrap})
        corner(ifrm,RC.sharp); stroke(ifrm,C.br0,1)
        local tb=mk("TextBox",{
            PlaceholderText="...", Text=tostring(defVal),
            Size=dim2(1,-8,1,0), Position=dim2(0,5,0,0),
            BackgroundTransparency=1, TextColor3=C.t0,
            PlaceholderColor3=C.t2, TextSize=11,
            Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left,
            ClearTextOnFocus=false, ZIndex=106, Parent=ifrm,
        })
        tb.FocusLost:Connect(function() if onChange then onChange(tb.Text) end end)
        return tb
    end

    local function swButton(txt, cb)
        local r = swRow(24)
        local lbl = mk("TextLabel",{
            Text=txt, Size=dim2(1,0,1,0),
            BackgroundTransparency=1, TextColor3=C.t1,
            TextSize=11, Font=Enum.Font.GothamSemibold,
            ZIndex=105, Parent=r,
        })
        local hb = mk("TextButton",{
            Text="", Size=dim2(1,0,1,0),
            BackgroundTransparency=1, AutoButtonColor=false,
            ZIndex=106, Parent=r,
        })
        hb.MouseEnter:Connect(function() tw(r,{BackgroundTransparency=0.2},Enum.EasingStyle.Quint,0.1); tw(lbl,{TextColor3=C.t0},Enum.EasingStyle.Quint,0.1) end)
        hb.MouseLeave:Connect(function() tw(r,{BackgroundTransparency=0.45},Enum.EasingStyle.Quint,0.1); tw(lbl,{TextColor3=C.t1},Enum.EasingStyle.Quint,0.1) end)
        hb.MouseButton1Click:Connect(function()
            tw(lbl,{TextColor3=AC},Enum.EasingStyle.Quint,0.08)
            task.delay(0.15,function() tw(lbl,{TextColor3=C.t1},Enum.EasingStyle.Quint,0.12) end)
            if cb then cb() end
        end)
        onAC(function(c)
            -- flash color on click already uses AC, no persistent bind needed
        end)
        return r
    end

    local function swToggle(lbl_text, default, onChange)
        local r = swRow(24)
        mk("TextLabel",{Text=lbl_text,Size=dim2(1,-46,1,0),Position=dim2(0,6,0,0),BackgroundTransparency=1,TextColor3=C.t1,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=105,Parent=r})
        local val=default==true
        local track=mk("Frame",{Size=dim2(0,30,0,13),Position=dim2(1,-34,.5,-6.5),BackgroundColor3=val and AC or C.bg4,ZIndex=105,Parent=r})
        corner(track,RC.pill)
        local knob=mk("Frame",{Size=dim2(0,10,0,10),Position=val and dim2(1,-12,.5,-5) or dim2(0,2,.5,-5),BackgroundColor3=C.t0,ZIndex=106,Parent=track})
        corner(knob,RC.pill)
        onAC(function(c) if val then track.BackgroundColor3=c end end)
        local tbtn=mk("TextButton",{Size=dim2(1,0,1,0),BackgroundTransparency=1,Text="",AutoButtonColor=false,ZIndex=107,Parent=r})
        tbtn.MouseButton1Click:Connect(function()
            val=not val
            tw(track,{BackgroundColor3=val and AC or C.bg4},Enum.EasingStyle.Quint,0.18)
            tw(knob,{Position=val and dim2(1,-12,.5,-5) or dim2(0,2,.5,-5)},Enum.EasingStyle.Back,0.2)
            if onChange then onChange(val) end
        end)
        return {Get=function() return val end}
    end

    local function swColorRow(lbl_text, defCol, onChange)
        local r = swRow(24)
        mk("TextLabel",{Text=lbl_text,Size=dim2(1,-42,1,0),Position=dim2(0,6,0,0),BackgroundTransparency=1,TextColor3=C.t1,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=105,Parent=r})
        local col=defCol; local h,s,v=Color3.toHSV(col)
        local sw2=mk("TextButton",{Size=dim2(0,30,0,16),Position=dim2(1,-34,.5,-8),BackgroundColor3=col,Text="",AutoButtonColor=false,ZIndex=105,Parent=r})
        corner(sw2,RC.sharp); stroke(sw2,C.br2,1)
        local openPick=false
        sw2.MouseButton1Click:Connect(function()
            openPick=not openPick
            if openPick then
                openOV(function(ov)
                    buildColorPicker(ov,sw2,h,s,v,function(nc,nh,ns,nv)
                        col=nc; h,s,v=nh,ns,nv; sw2.BackgroundColor3=nc
                        if onChange then onChange(nc) end
                    end, SG)
                end)
            else closeOV() end
        end)
        return {Get=function() return col end}
    end

    -- ── Populate Settings ────────────────────────────────────
    swSection("Appearance")
    swColorRow("Accent Color", AC, function(c)
        AC=c; fireAC()
    end)
    swColorRow("Background Color", CFG.BgColor, function(c)
        CFG.BgColor=c; BG.BackgroundColor3=c; SW.BackgroundColor3=c
    end)
    swSection("Watermark")
    swToggle("Show Watermark", true, function(v) CFG.ShowWM=v; WM.Visible=v end)
    swTextbox("Script Name",  CFG.ScriptName, function(v) wmSet("ScriptName",v) end)
    swTextbox("Display Name", CFG.UserName,   function(v) wmSet("UserName",v) end)
    swTextbox("Config Name",  CFG.ConfigName, function(v) wmSet("ConfigName",v) end)
    swTextbox("Build Type",   CFG.BuildType,  function(v) wmSet("BuildType",v) end)
    swTextbox("Game Name",    CFG.GameName,   function(v) wmSet("GameName",v) end)
    swSection("Copy")
    swButton("Copy Username",    function() pcall(function() setclipboard(LP.Name) end);            notify({Title="Copied",Desc="Username copied.",Type="Success",Duration=2}) end)
    swButton("Copy User ID",     function() pcall(function() setclipboard(tostring(LP.UserId)) end); notify({Title="Copied",Desc="User ID copied.",Type="Success",Duration=2}) end)
    swButton("Copy Game ID",     function() pcall(function() setclipboard(tostring(game.GameId)) end); notify({Title="Copied",Desc="Game ID copied.",Type="Success",Duration=2}) end)
    swButton("Copy Config Name", function() pcall(function() setclipboard(CFG.ConfigName) end);      notify({Title="Copied",Desc="Config name copied.",Type="Success",Duration=2}) end)
    swSection("Danger Zone")
    local unloadRow = swRow(26)
    local unloadLbl = mk("TextLabel",{Text="Unload Script",Size=dim2(1,0,1,0),BackgroundTransparency=1,TextColor3=rgb(220,60,60),TextSize=12,Font=Enum.Font.GothamBold,ZIndex=105,Parent=unloadRow})
    unloadRow.BackgroundColor3=rgb(40,14,14); unloadRow.BackgroundTransparency=0.3
    local unloadBtn=mk("TextButton",{Size=dim2(1,0,1,0),BackgroundTransparency=1,Text="",AutoButtonColor=false,ZIndex=106,Parent=unloadRow})
    unloadBtn.MouseEnter:Connect(function() tw(unloadRow,{BackgroundTransparency=0.1},Enum.EasingStyle.Quint,0.1) end)
    unloadBtn.MouseLeave:Connect(function() tw(unloadRow,{BackgroundTransparency=0.3},Enum.EasingStyle.Quint,0.1) end)
    unloadBtn.MouseButton1Click:Connect(function()
        notify({Title="Unloading",Desc="Removing script...",Type="Warning",Duration=2})
        task.delay(.5,function() pcall(function() SG:Destroy() end) end)
    end)

    SET_BTN.MouseButton1Click:Connect(function() SW.Visible=not SW.Visible end)

    -- ══════════════════════════════════════════════════════════
    -- EASTER EGG
    -- ══════════════════════════════════════════════════════════
    local _eggActive=false
    task.spawn(function()
        while SG and SG.Parent do
            task.wait(5)
            pcall(function()
                local found=false
                local function scan(inst,d)
                    if d>5 or found then return end
                    local ok2,tx=pcall(function() return inst.Text end)
                    if ok2 and tx then
                        local lo=tx:lower()
                        for _,kw in ipairs(EASTER_KW) do if lo:find(kw,1,true) then found=true; return end end
                    end
                    for _,c2 in ipairs(inst:GetChildren()) do scan(c2,d+1) end
                end
                pcall(function() scan(LP.PlayerGui,0) end)
                pcall(function() scan(workspace,0) end)
                if found and not EGG_BTN.Visible then
                    EGG_BTN.Visible=true; repositionBar()
                    notify({Title="Easter Egg",Desc="Something was found.",Type="Warning",Duration=5})
                end
            end)
        end
    end)

    EGG_BTN.MouseButton1Click:Connect(function()
        if _eggActive then return end; _eggActive=true
        local vid=EASTER_VIDS[math.random(1,#EASTER_VIDS)]
        local ov3=mk("Frame",{Size=dim2(1,0,1,0),BackgroundColor3=rgb(0,0,0),BackgroundTransparency=0,ZIndex=500,Parent=SG})
        local panel=mk("Frame",{
            Size=dim2(0,320,0,160),
            Position=dim2(.5,-160,.5,-80),
            BackgroundColor3=C.bg1, ZIndex=501, Parent=ov3,
        })
        corner(panel,RC.sharp); stroke(panel,C.br0,1)
        local pHdr=mk("Frame",{Size=dim2(1,0,0,24),BackgroundColor3=rgb(0,0,0),BackgroundTransparency=0.5,ZIndex=502,Parent=panel})
        mk("TextLabel",{Text="EASTER EGG",Size=dim2(1,0,1,0),BackgroundTransparency=1,TextColor3=AC,TextSize=12,Font=Enum.Font.GothamBold,ZIndex=503,Parent=pHdr})
        onAC(function(c) pHdr:FindFirstChildWhichIsA("TextLabel") and (pHdr:FindFirstChildWhichIsA("TextLabel").TextColor3=c) end)
        mk("TextLabel",{
            Text="youtu.be/"..vid.id.."\n\n"..(vid.loop and "[Looping]" or "").."\n\nSaved to: ".._DIR.."/videos/",
            Size=dim2(1,-20,0,88), Position=dim2(0,10,0,30),
            BackgroundTransparency=1, TextColor3=C.t1,
            TextSize=11, Font=Enum.Font.Gotham,
            TextWrapped=true, TextXAlignment=Enum.TextXAlignment.Left,
            ZIndex=502, Parent=panel,
        })
        pcall(function()
            local fn=_DIR.."/videos/"..vid.id..".txt"
            if not isfile(fn) then writefile(fn,"https://www.youtube.com/watch?v="..vid.id) end
        end)
        local closeE=mk("TextButton",{
            Text="Close",
            Size=dim2(0,70,0,22), Position=dim2(.5,-35,1,-28),
            BackgroundColor3=C.bg4, TextColor3=C.t0,
            TextSize=11, Font=Enum.Font.GothamSemibold,
            AutoButtonColor=false, ZIndex=503, Parent=panel,
        })
        corner(closeE,RC.sharp)
        closeE.MouseButton1Click:Connect(function()
            tw(ov3,{BackgroundTransparency=1},Enum.EasingStyle.Quint,0.2)
            task.wait(.22); pcall(function() ov3:Destroy() end); _eggActive=false
        end)
    end)

    -- ══════════════════════════════════════════════════════════
    -- KEY TOGGLE  (Insert hides BG + BAR, NOT watermark)
    -- ══════════════════════════════════════════════════════════
    local _vis=true
    UIS.InputBegan:Connect(function(i,gpe)
        if not gpe and i.KeyCode==KEY then
            _vis=not _vis
            BG.Visible=_vis
            BAR.Visible=_vis
            if not _vis then SW.Visible=false end
            -- WM is controlled only by Settings toggle
        end
    end)

    -- ══════════════════════════════════════════════════════════
    -- WINDOW OBJECT
    -- ══════════════════════════════════════════════════════════
    local WO = {_categories={}, _activeCat=nil, Notify=notify}

    function WO:AddCategory(name)
        local isFirst = #self._categories==0

        -- bar tab button
        local catBtn = mk("TextButton",{
            Text=name,
            Size=dim2(0,0,0,BAR_H-6), AutomaticSize=Enum.AutomaticSize.X,
            Position=dim2(0,0,0,3),
            BackgroundColor3 = isFirst and AC or C.bg4,
            TextColor3       = isFirst and C.t0 or C.t2,
            TextSize=11, Font=Enum.Font.GothamSemibold,
            AutoButtonColor=false, BorderSizePixel=0,
            ZIndex=53, LayoutOrder=#self._categories+1,
            Parent=CAT_SF,
        })
        padding(catBtn,0,8,0,8)
        corner(catBtn, RC.sharp)
        stroke(catBtn, C.br0, 1)
        onAC(function(c) if self._activeCat==CAT then catBtn.BackgroundColor3=c end end)

        -- content panel
        local catPanel = mk("Frame",{
            Size=dim2(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
            BackgroundTransparency=1,
            Visible=isFirst, ZIndex=5, Parent=CONTENT,
        })
        layout(catPanel, Enum.FillDirection.Vertical, 5)

        local CAT = {_name=name, _btn=catBtn, _panel=catPanel, _win=self}
        table.insert(self._categories, CAT)
        if isFirst then self._activeCat=CAT end

        local function activateCat()
            if self._activeCat==CAT then return end
            local old=self._activeCat
            if old then
                old._panel.Visible=false
                tw(old._btn,{BackgroundColor3=C.bg4, TextColor3=C.t2},Enum.EasingStyle.Quint,0.15)
            end
            catPanel.Visible=true
            tw(catBtn,{BackgroundColor3=AC, TextColor3=C.t0},Enum.EasingStyle.Quint,0.15)
            self._activeCat=CAT
        end
        catBtn.MouseButton1Click:Connect(activateCat)
        catBtn.MouseEnter:Connect(function()
            if self._activeCat~=CAT then tw(catBtn,{BackgroundColor3=C.bg3,TextColor3=C.t1},Enum.EasingStyle.Quint,0.1) end
        end)
        catBtn.MouseLeave:Connect(function()
            if self._activeCat~=CAT then tw(catBtn,{BackgroundColor3=C.bg4,TextColor3=C.t2},Enum.EasingStyle.Quint,0.1) end
        end)

        -- ── Element row builder ──────────────────────────────
        -- Outer shell: RC.sharp (3px) so it's blocky
        -- Inner label/btn face: RC.soft (5px) slightly rounder
        local function mkRow(h)
            local r=mk("Frame",{
                Size=dim2(1,0,0,h or 30),
                BackgroundColor3=C.bg3,
                BackgroundTransparency=0.50,
                ZIndex=6, Parent=catPanel,
            })
            corner(r, RC.sharp)
            return r
        end

        -- shared right-click mode info for keybind pills
        local KEYS_SHORT = {
            [Enum.KeyCode.LeftShift]="LS",[Enum.KeyCode.RightShift]="RS",
            [Enum.KeyCode.LeftControl]="LC",[Enum.KeyCode.RightControl]="RC",
            [Enum.KeyCode.Insert]="INS",[Enum.KeyCode.Backspace]="BS",
            [Enum.KeyCode.Return]="Ent",[Enum.KeyCode.CapsLock]="CAPS",
            [Enum.KeyCode.Escape]="ESC",[Enum.KeyCode.Space]="SPC",
        }
        local function keyName(k)
            if not k or k==Enum.KeyCode.Unknown then return "NONE" end
            return KEYS_SHORT[k] or tostring(k):gsub("Enum%.KeyCode%.",""):gsub("Enum%.UserInputType%.","")
        end

        -- ────────────────────────────────────────────────────
        -- AddButton
        -- ────────────────────────────────────────────────────
        function CAT:AddButton(o5)
            o5=o5 or {}; local nm=o5.Name or "Button"; local cb=o5.Callback or function() end
            local row=mkRow(30)

            -- inner button face has RC.soft = slightly rounded inside blocky shell
            local face=mk("Frame",{
                Size=dim2(1,-6,0,24), Position=dim2(0,3,0,3),
                BackgroundColor3=C.bg4,
                ZIndex=7, Parent=row,
            })
            corner(face, RC.soft)
            stroke(face, C.br0, 1)

            local lbl=mk("TextLabel",{
                Text=nm, Size=dim2(1,0,1,0),
                BackgroundTransparency=1, TextColor3=C.t1,
                TextSize=12, Font=Enum.Font.GothamSemibold,
                ZIndex=8, Parent=face,
            })

            -- left accent pip (hidden by default, shows on hover)
            local pip=mk("Frame",{
                Size=dim2(0,2,0,14), Position=dim2(0,0,.5,-7),
                BackgroundColor3=AC, BackgroundTransparency=1,
                ZIndex=8, Parent=face,
            })
            onAC(function(c) pip.BackgroundColor3=c end)

            local hbtn=mk("TextButton",{
                Size=dim2(1,0,1,0), BackgroundTransparency=1,
                Text="", AutoButtonColor=false, ZIndex=9, Parent=face,
            })
            hbtn.MouseEnter:Connect(function()
                tw(face,{BackgroundColor3=C.bg3},Enum.EasingStyle.Quint,0.12)
                tw(lbl,{TextColor3=C.t0},Enum.EasingStyle.Quint,0.12)
                tw(pip,{BackgroundTransparency=0},Enum.EasingStyle.Quint,0.12)
            end)
            hbtn.MouseLeave:Connect(function()
                tw(face,{BackgroundColor3=C.bg4},Enum.EasingStyle.Quint,0.12)
                tw(lbl,{TextColor3=C.t1},Enum.EasingStyle.Quint,0.12)
                tw(pip,{BackgroundTransparency=1},Enum.EasingStyle.Quint,0.12)
            end)
            hbtn.MouseButton1Click:Connect(function()
                tw(face,{BackgroundColor3=AC},Enum.EasingStyle.Quint,0.08)
                tw(lbl,{TextColor3=C.t0},Enum.EasingStyle.Quint,0.08)
                task.delay(0.2,function()
                    tw(face,{BackgroundColor3=C.bg4},Enum.EasingStyle.Quint,0.18)
                    tw(lbl,{TextColor3=C.t1},Enum.EasingStyle.Quint,0.18)
                end)
                pcall(cb)
            end)
            local r={}; function r:SetText(t) lbl.Text=t end; return r
        end

        -- ────────────────────────────────────────────────────
        -- AddLabel
        -- ────────────────────────────────────────────────────
        function CAT:AddLabel(o5)
            o5=o5 or {}
            local lbl=mk("TextLabel",{
                Text=o5.Text or "",
                Size=dim2(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
                BackgroundColor3=C.bg3, BackgroundTransparency=0.55,
                TextColor3=o5.Color or C.t2,
                TextSize=o5.Size or 11, Font=Enum.Font.Gotham,
                TextXAlignment=Enum.TextXAlignment.Left,
                TextWrapped=true, ZIndex=6, Parent=catPanel,
            })
            corner(lbl, RC.sharp); padding(lbl,4,8,4,8)
            local r={}; function r:Set(t) lbl.Text=t end; function r:Get() return lbl.Text end; return r
        end

        -- ────────────────────────────────────────────────────
        -- AddToggle  (Milenium-style: checkbox or pill)
        -- ────────────────────────────────────────────────────
        function CAT:AddToggle(o5)
            o5=o5 or {}
            local nm=o5.Name or "Toggle"; local val=o5.Default==true
            local cb=o5.Callback or function() end; local flag=o5.Flag
            local hasKB=o5.Keybind~=nil
            local kbMode="Toggle"; local kbKey=o5.Keybind or Enum.KeyCode.Unknown
            local listening=false; local holding=false

            local row=mkRow(hasKB and 32 or 30)

            -- name
            local nameLbl=mk("TextLabel",{
                Text=nm,
                Size=dim2(1,-(hasKB and 148 or 56),1,0),
                Position=dim2(0,8,0,0),
                BackgroundTransparency=1, TextColor3=C.t1,
                TextSize=12, Font=Enum.Font.Gotham,
                TextXAlignment=Enum.TextXAlignment.Left,
                ZIndex=7, Parent=row,
            })

            -- toggle pill
            local track=mk("Frame",{
                Size=dim2(0,32,0,15),
                Position=dim2(1,-36,.5,-7.5),
                BackgroundColor3=val and AC or C.bg4,
                ZIndex=7, Parent=row,
            })
            corner(track, RC.pill)
            stroke(track, C.br0, 1)
            local knob=mk("Frame",{
                Size=dim2(0,11,0,11),
                Position=val and dim2(1,-13,.5,-5.5) or dim2(0,2,.5,-5.5),
                BackgroundColor3=C.t0,
                ZIndex=8, Parent=track,
            })
            corner(knob, RC.pill)
            onAC(function(c) if val then track.BackgroundColor3=c end end)

            local trackHit=mk("TextButton",{
                Size=dim2(0,32,0,15), Position=dim2(1,-36,.5,-7.5),
                BackgroundTransparency=1, Text="", AutoButtonColor=false,
                ZIndex=9, Parent=row,
            })

            -- keybind widgets
            local kbBtn, modeBtn
            if hasKB then
                modeBtn=mk("TextButton",{
                    Text="T", Size=dim2(0,14,0,14),
                    Position=dim2(1,-142,.5,-7),
                    BackgroundColor3=C.bg4, TextColor3=C.t2,
                    TextSize=8, Font=Enum.Font.GothamBold,
                    AutoButtonColor=false, ZIndex=7, Parent=row,
                })
                corner(modeBtn,RC.sharp); stroke(modeBtn,C.br0,1)
                local modeOrder={"Toggle","Hold","Always"}
                local modeAbbr={Toggle="T",Hold="H",Always="A"}
                modeBtn.MouseButton2Click:Connect(function()
                    local ci=1
                    for i,m in ipairs(modeOrder) do if m==kbMode then ci=i break end end
                    kbMode=modeOrder[(ci%#modeOrder)+1]
                    modeBtn.Text=modeAbbr[kbMode]
                    notify({Title="Mode",Desc=nm..": "..kbMode,Type="Info",Duration=2})
                end)

                kbBtn=mk("TextButton",{
                    Text=keyName(kbKey),
                    Size=dim2(0,54,0,14),
                    Position=dim2(1,-120,.5,-7),
                    BackgroundColor3=C.bg4, TextColor3=AC,
                    TextSize=9, Font=Enum.Font.GothamBold,
                    AutoButtonColor=false, ZIndex=7, Parent=row,
                })
                corner(kbBtn,RC.sharp); stroke(kbBtn,C.br0,1)
                onAC(function(c) if not listening then kbBtn.TextColor3=c end end)
                kbBtn.MouseButton1Click:Connect(function()
                    if listening then return end
                    listening=true
                    kbBtn.Text="..."; kbBtn.TextColor3=rgb(255,185,0); kbBtn.BackgroundColor3=rgb(28,24,10)
                end)
            end

            local function set(v, silent)
                val=v
                tw(track,{BackgroundColor3=v and AC or C.bg4},Enum.EasingStyle.Quint,0.18)
                tw(knob,{Position=v and dim2(1,-13,.5,-5.5) or dim2(0,2,.5,-5.5)},Enum.EasingStyle.Back,0.22)
                if not silent then pcall(cb,v) end
                if flag then _G[flag]=v end
            end
            trackHit.MouseButton1Click:Connect(function() set(not val) end)
            if hasKB then
                UIS.InputBegan:Connect(function(i,gpe)
                    if listening and not gpe and i.UserInputType==Enum.UserInputType.Keyboard then
                        kbKey=i.KeyCode; kbBtn.Text=keyName(kbKey)
                        kbBtn.TextColor3=AC; kbBtn.BackgroundColor3=C.bg4; listening=false
                    elseif not listening and not gpe and i.KeyCode==kbKey and kbKey~=Enum.KeyCode.Unknown then
                        if kbMode=="Toggle" then set(not val)
                        elseif kbMode=="Hold" then holding=true; set(true)
                        elseif kbMode=="Always" then set(true) end
                    end
                end)
                UIS.InputEnded:Connect(function(i)
                    if holding and i.KeyCode==kbKey and kbMode=="Hold" then holding=false; set(false) end
                end)
            end
            if flag then _G[flag]=val end
            local r={Value=val}
            function r:Set(v) set(v,true) end; function r:Get() return val end; return r
        end

        -- ────────────────────────────────────────────────────
        -- AddSlider  (Milenium-style: pill track, circle knob)
        -- ────────────────────────────────────────────────────
        function CAT:AddSlider(o5)
            o5=o5 or {}
            local nm=o5.Name or "Slider"; local mn=o5.Min or 0; local mx=o5.Max or 100
            local step=o5.Step or 1; local suf=o5.Suffix or ""; local flag=o5.Flag
            local cb=o5.Callback or function() end
            local val=math.clamp(o5.Default or mn,mn,mx)

            local wrap=mk("Frame",{
                Size=dim2(1,0,0,46),
                BackgroundColor3=C.bg3, BackgroundTransparency=0.50,
                ZIndex=6, Parent=catPanel,
            })
            corner(wrap, RC.sharp)

            -- top row
            local top=mk("Frame",{
                Size=dim2(1,-8,0,18), Position=dim2(0,4,0,4),
                BackgroundTransparency=1, ZIndex=7, Parent=wrap,
            })
            mk("TextLabel",{
                Text=nm, Size=dim2(1,-56,1,0),
                BackgroundTransparency=1, TextColor3=C.t1,
                TextSize=12, Font=Enum.Font.Gotham,
                TextXAlignment=Enum.TextXAlignment.Left,
                ZIndex=8, Parent=top,
            })
            -- value badge (Milenium style: grey box right side)
            local vbg=mk("Frame",{
                Size=dim2(0,48,0,16), Position=dim2(1,-50,.5,-8),
                BackgroundColor3=C.bg4, ZIndex=8, Parent=top,
            })
            corner(vbg,RC.sharp)
            local vLbl=mk("TextLabel",{
                Text=tostring(val)..suf, Size=dim2(1,0,1,0),
                BackgroundTransparency=1, TextColor3=C.t2,
                TextSize=11, Font=Enum.Font.GothamSemibold,
                ZIndex=9, Parent=vbg,
            })

            -- track area
            local trackArea=mk("TextButton",{
                Size=dim2(1,-8,0,18), Position=dim2(0,4,0,24),
                BackgroundTransparency=1, Text="", AutoButtonColor=false,
                ZIndex=9, Parent=wrap,
            })
            local trackBg=mk("Frame",{
                Size=dim2(1,0,0,4), Position=dim2(0,0,.5,-2),
                BackgroundColor3=C.bg4, ZIndex=7, Parent=trackArea,
            })
            corner(trackBg,RC.pill)
            local pct=(val-mn)/(mx-mn)
            local fill=mk("Frame",{
                Size=dim2(pct,-4,1,0), Position=dim2(0,0,0,0),  -- -4 so knob doesn't bleed
                BackgroundColor3=AC, ZIndex=8, Parent=trackBg,
            })
            corner(fill,RC.pill)
            onAC(function(c) fill.BackgroundColor3=c end)

            -- circle knob
            local kn=mk("Frame",{
                AnchorPoint=Vector2.new(.5,.5),
                Size=dim2(0,12,0,12), Position=dim2(pct,0,.5,0),
                BackgroundColor3=rgb(244,244,244), ZIndex=10, Parent=trackBg,
            })
            corner(kn,RC.pill)
            stroke(kn,C.br2,1)

            trackArea.MouseEnter:Connect(function() tw(kn,{Size=dim2(0,14,0,14)},Enum.EasingStyle.Back,0.15) end)
            trackArea.MouseLeave:Connect(function() tw(kn,{Size=dim2(0,12,0,12)},Enum.EasingStyle.Quint,0.12) end)

            local function sv(v, silent)
                v=math.clamp(math.round(v/step)*step,mn,mx); val=v
                local p=(v-mn)/(mx-mn)
                tw(fill,{Size=dim2(p,-4,1,0)},Enum.EasingStyle.Linear,0.05)
                tw(kn,{Position=dim2(p,0,.5,0)},Enum.EasingStyle.Linear,0.05)
                vLbl.Text=tostring(v)..suf
                tw(vLbl,{TextColor3=C.t0},Enum.EasingStyle.Quint,0.1)
                if not silent then pcall(cb,v) end
                if flag then _G[flag]=v end
            end
            -- value dims back after stop dragging
            local fadeTask
            local dragging=false
            trackArea.InputBegan:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 then
                    dragging=true
                    sv(mn+(mx-mn)*math.clamp((i.Position.X-trackBg.AbsolutePosition.X)/trackBg.AbsoluteSize.X,0,1))
                end
            end)
            UIS.InputChanged:Connect(function(i)
                if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
                    sv(mn+(mx-mn)*math.clamp((i.Position.X-trackBg.AbsolutePosition.X)/trackBg.AbsoluteSize.X,0,1))
                end
            end)
            UIS.InputEnded:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 then
                    dragging=false
                    tw(vLbl,{TextColor3=C.t2},Enum.EasingStyle.Quint,0.25)
                end
            end)
            if flag then _G[flag]=val end
            local r={Value=val}
            function r:Set(v) sv(v,true) end; function r:Get() return val end; return r
        end

        -- ────────────────────────────────────────────────────
        -- AddTextbox
        -- ────────────────────────────────────────────────────
        function CAT:AddTextbox(o5)
            o5=o5 or {}; local nm=o5.Name or "Input"; local cb=o5.Callback or function() end
            local wrap=mk("Frame",{
                Size=dim2(1,0,0,46),
                BackgroundColor3=C.bg3, BackgroundTransparency=0.50,
                ZIndex=6, Parent=catPanel,
            })
            corner(wrap,RC.sharp)
            mk("TextLabel",{Text=nm,Size=dim2(1,-8,0,13),Position=dim2(0,6,0,4),BackgroundTransparency=1,TextColor3=C.t2,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=7,Parent=wrap})
            local ifrm=mk("Frame",{Size=dim2(1,-8,0,22),Position=dim2(0,4,0,20),BackgroundColor3=C.bg4,ZIndex=7,Parent=wrap})
            corner(ifrm,RC.sharp); local sk=stroke(ifrm,C.br0,1)
            local tb=mk("TextBox",{
                PlaceholderText=o5.Placeholder or "type here...", Text=o5.Default or "",
                Size=dim2(1,-36,1,0), Position=dim2(0,6,0,0),
                BackgroundTransparency=1, TextColor3=C.t0,
                PlaceholderColor3=C.t2, TextSize=11,
                Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left,
                ClearTextOnFocus=false, ZIndex=8, Parent=ifrm,
            })
            local cfBtn=mk("TextButton",{
                Text="OK", Size=dim2(0,26,0,18),
                Position=dim2(1,-28,.5,-9),
                BackgroundColor3=AC, TextColor3=C.t0,
                TextSize=9, Font=Enum.Font.GothamBold,
                AutoButtonColor=false, ZIndex=9, Parent=ifrm,
            })
            corner(cfBtn,RC.sharp)
            onAC(function(c) cfBtn.BackgroundColor3=c end)
            tb.Focused:Connect(function() tw(sk,{Color=AC},Enum.EasingStyle.Quint,0.12) end)
            tb.FocusLost:Connect(function(en) tw(sk,{Color=C.br0},Enum.EasingStyle.Quint,0.12); if en then pcall(cb,tb.Text) end end)
            cfBtn.MouseButton1Click:Connect(function() pcall(cb,tb.Text); tb:ReleaseFocus() end)
            local r={}; function r:Set(v) tb.Text=v end; function r:Get() return tb.Text end; return r
        end

        -- ────────────────────────────────────────────────────
        -- AddDropdown  (Milenium-style: inline popup)
        -- ────────────────────────────────────────────────────
        function CAT:AddDropdown(o5)
            o5=o5 or {}; local nm=o5.Name or "Dropdown"
            local opts=o5.Options or {}; local multi=o5.Multi or false
            local flag=o5.Flag; local cb=o5.Callback or function() end
            local sel=o5.Default or (opts[1] or ""); local msel={}

            local wrap=mk("Frame",{
                Size=dim2(1,0,0,46),
                BackgroundColor3=C.bg3, BackgroundTransparency=0.50,
                ZIndex=6, Parent=catPanel,
            })
            corner(wrap,RC.sharp)
            mk("TextLabel",{Text=nm,Size=dim2(1,-8,0,13),Position=dim2(0,6,0,4),BackgroundTransparency=1,TextColor3=C.t2,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=7,Parent=wrap})

            local hd=mk("TextButton",{
                Size=dim2(1,-8,0,22), Position=dim2(0,4,0,20),
                BackgroundColor3=C.bg4, Text="", AutoButtonColor=false,
                ZIndex=7, Parent=wrap,
            })
            corner(hd,RC.sharp); local hsk=stroke(hd,C.br0,1)
            local sl=mk("TextLabel",{
                Text=multi and "Select..." or tostring(sel),
                Size=dim2(1,-22,1,0), Position=dim2(0,6,0,0),
                BackgroundTransparency=1, TextColor3=C.t1,
                TextSize=11, Font=Enum.Font.Gotham,
                TextXAlignment=Enum.TextXAlignment.Left,
                ZIndex=8, Parent=hd,
            })
            -- arrow indicator
            local arr=mk("TextLabel",{
                Text="v", Size=dim2(0,14,1,0), Position=dim2(1,-15,0,0),
                BackgroundTransparency=1, TextColor3=C.t2,
                TextSize=8, Font=Enum.Font.Gotham, ZIndex=8, Parent=hd,
            })
            hd.MouseEnter:Connect(function() tw(hd,{BackgroundColor3=C.bg3},Enum.EasingStyle.Quint,0.1); tw(hsk,{Color=AC},Enum.EasingStyle.Quint,0.1) end)
            hd.MouseLeave:Connect(function() tw(hd,{BackgroundColor3=C.bg4},Enum.EasingStyle.Quint,0.1); tw(hsk,{Color=C.br0},Enum.EasingStyle.Quint,0.1) end)

            local isOpen=false
            local function closeDD() isOpen=false; tw(arr,{Rotation=0},Enum.EasingStyle.Quint,0.12); closeOV() end
            local function buildDD(ov)
                local ap=hd.AbsolutePosition; local as=hd.AbsoluteSize
                local lh=math.min(#opts*22+10,150)
                local px=math.min(ap.X, SG.AbsoluteSize.X-as.X-10)
                local py=ap.Y+as.Y+4
                if py+lh>SG.AbsoluteSize.Y-10 then py=ap.Y-lh-4 end
                local pan=mk("Frame",{
                    Size=dim2(0,as.X,0,0), Position=dim2(0,px,0,py),
                    BackgroundColor3=C.bg1, ZIndex=220, Parent=ov,
                })
                corner(pan,RC.sharp); stroke(pan,C.br0,1)
                tw(pan,{Size=dim2(0,as.X,0,lh)},Enum.EasingStyle.Back,0.16)
                local sc=mk("ScrollingFrame",{
                    Size=dim2(1,0,1,0), BackgroundTransparency=1,
                    ScrollBarThickness=2, ScrollBarImageColor3=AC,
                    CanvasSize=dim2(0,0,0,0), ZIndex=221, Parent=pan,
                })
                onAC(function(c) sc.ScrollBarImageColor3=c end)
                layout(sc,Enum.FillDirection.Vertical,3); padding(sc,4,4,4,4); autoCanvas(sc)
                ov.ChildRemoved:Connect(function() isOpen=false end)
                for _,op in ipairs(opts) do
                    local isSel=multi and table.find(msel,op)~=nil or op==sel
                    local ob=mk("TextButton",{
                        Size=dim2(1,0,0,20), Text=op,
                        BackgroundColor3=isSel and AC or C.bg4,
                        TextColor3=isSel and C.t0 or C.t2,
                        TextSize=11, Font=Enum.Font.Gotham,
                        AutoButtonColor=false, ZIndex=222, Parent=sc,
                    })
                    corner(ob,RC.sharp)
                    ob.MouseEnter:Connect(function()
                        if not(multi and table.find(msel,op)) and op~=sel then
                            tw(ob,{BackgroundColor3=C.bg3,TextColor3=C.t1},Enum.EasingStyle.Quint,0.08)
                        end
                    end)
                    ob.MouseLeave:Connect(function()
                        local s2=multi and table.find(msel,op)~=nil or op==sel
                        ob.BackgroundColor3=s2 and AC or C.bg4
                        ob.TextColor3=s2 and C.t0 or C.t2
                    end)
                    ob.MouseButton1Click:Connect(function()
                        if multi then
                            local idx=table.find(msel,op)
                            if idx then table.remove(msel,idx) else table.insert(msel,op) end
                            sl.Text=#msel>0 and table.concat(msel,", ") or "Select..."
                            pcall(cb,msel); if flag then _G[flag]=msel end
                        else
                            sel=op; sl.Text=op; pcall(cb,op)
                            if flag then _G[flag]=op end; closeDD()
                        end
                    end)
                end
            end
            hd.MouseButton1Click:Connect(function()
                isOpen=not isOpen
                tw(arr,{Rotation=isOpen and 180 or 0},Enum.EasingStyle.Quint,0.15)
                if isOpen then openOV(buildDD) else closeDD() end
            end)
            if flag then _G[flag]=sel end
            local r={Value=sel}
            function r:Set(v) sel=v;sl.Text=v;if flag then _G[flag]=v end end
            function r:SetOptions(t) opts=t end
            function r:Get() return multi and msel or sel end
            return r
        end

        -- ────────────────────────────────────────────────────
        -- AddColorPicker
        -- ────────────────────────────────────────────────────
        function CAT:AddColorPicker(o5)
            o5=o5 or {}; local nm=o5.Name or "Color"
            local col=o5.Default or rgb(255,80,80); local flag=o5.Flag
            local cb=o5.Callback or function() end
            local h,s,v=Color3.toHSV(col)
            local row=mkRow(30)
            mk("TextLabel",{Text=nm,Size=dim2(1,-50,1,0),Position=dim2(0,8,0,0),BackgroundTransparency=1,TextColor3=C.t1,TextSize=12,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=7,Parent=row})
            local sw=mk("TextButton",{
                Size=dim2(0,32,0,18), Position=dim2(1,-36,.5,-9),
                BackgroundColor3=col, Text="", AutoButtonColor=false,
                ZIndex=7, Parent=row,
            })
            corner(sw,RC.sharp); stroke(sw,C.br2,1)
            local open=false
            sw.MouseButton1Click:Connect(function()
                open=not open
                if open then
                    openOV(function(ov)
                        buildColorPicker(ov,sw,h,s,v,function(nc,nh,ns,nv)
                            col=nc; h,s,v=nh,ns,nv; sw.BackgroundColor3=nc
                            pcall(cb,nc); if flag then _G[flag]=nc end
                        end, SG)
                    end)
                else closeOV() end
            end)
            if flag then _G[flag]=col end
            local r={Value=col}
            function r:Set(c2) col=c2;h,s,v=Color3.toHSV(c2);sw.BackgroundColor3=c2 end
            function r:Get() return col end; return r
        end

        -- ────────────────────────────────────────────────────
        -- AddKeybind  (standalone)
        -- ────────────────────────────────────────────────────
        function CAT:AddKeybind(o5)
            o5=o5 or {}; local nm=o5.Name or "Keybind"
            local key=o5.Default or Enum.KeyCode.Unknown; local flag=o5.Flag
            local cb=o5.Callback or function() end; local listening=false
            local row=mkRow(30)
            mk("TextLabel",{Text=nm,Size=dim2(1,-90,1,0),Position=dim2(0,8,0,0),BackgroundTransparency=1,TextColor3=C.t1,TextSize=12,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=7,Parent=row})
            local kb=mk("TextButton",{
                Text=keyName(key), Size=dim2(0,74,0,16),
                Position=dim2(1,-78,.5,-8),
                BackgroundColor3=C.bg4, TextColor3=AC,
                TextSize=9, Font=Enum.Font.GothamBold,
                AutoButtonColor=false, ZIndex=7, Parent=row,
            })
            corner(kb,RC.sharp); stroke(kb,C.br0,1)
            onAC(function(c) if not listening then kb.TextColor3=c end end)
            kb.MouseButton1Click:Connect(function()
                if listening then return end
                listening=true; kb.Text="..."; kb.TextColor3=rgb(255,185,0); kb.BackgroundColor3=rgb(28,24,10)
            end)
            UIS.InputBegan:Connect(function(i,gpe)
                if listening and not gpe and i.UserInputType==Enum.UserInputType.Keyboard then
                    key=i.KeyCode; kb.Text=keyName(key); kb.TextColor3=AC; kb.BackgroundColor3=C.bg4; listening=false
                elseif not listening and not gpe and i.KeyCode==key and key~=Enum.KeyCode.Unknown then
                    pcall(cb); if flag then _G[flag]=key end
                end
            end)
            if flag then _G[flag]=key end
            local r={Value=key}; function r:Set(k) key=k;kb.Text=keyName(k) end; function r:Get() return key end; return r
        end

        -- ────────────────────────────────────────────────────
        -- AddSeparator  (Milenium-style thin line)
        -- ────────────────────────────────────────────────────
        function CAT:AddSeparator()
            local sep=mk("Frame",{Size=dim2(1,0,0,1),BackgroundColor3=C.br1,BackgroundTransparency=0.4,ZIndex=6,Parent=catPanel})
            mk("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.06,0),NumberSequenceKeypoint.new(.94,0),NumberSequenceKeypoint.new(1,1)}),Parent=sep})
        end

        -- ────────────────────────────────────────────────────
        -- AddProgressBar  (Milenium-style: thin bar + %)
        -- ────────────────────────────────────────────────────
        function CAT:AddProgressBar(o5)
            o5=o5 or {}; local nm=o5.Name or "Progress"
            local maxV=o5.Max or 100; local cur=math.clamp(o5.Default or 0,0,maxV)
            local wrap=mk("Frame",{
                Size=dim2(1,0,0,38),
                BackgroundColor3=C.bg3, BackgroundTransparency=0.50,
                ZIndex=6, Parent=catPanel,
            })
            corner(wrap,RC.sharp)
            local top=mk("Frame",{Size=dim2(1,-8,0,17),Position=dim2(0,4,0,4),BackgroundTransparency=1,ZIndex=7,Parent=wrap})
            mk("TextLabel",{Text=nm,Size=dim2(1,-50,1,0),BackgroundTransparency=1,TextColor3=C.t1,TextSize=12,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=8,Parent=top})
            local pct=mk("TextLabel",{
                Text=math.round(cur/maxV*100).."%",
                Size=dim2(0,44,1,0), Position=dim2(1,-46,0,0),
                BackgroundTransparency=1, TextColor3=C.t2,
                TextSize=11, Font=Enum.Font.GothamSemibold,
                ZIndex=8, Parent=top,
            })
            onAC(function(c) pct.TextColor3=c end)
            local trk=mk("Frame",{Size=dim2(1,-8,0,4),Position=dim2(0,4,0,28),BackgroundColor3=C.bg4,ZIndex=7,Parent=wrap})
            corner(trk,RC.pill)
            local fill=mk("Frame",{Size=dim2(cur/maxV,0,1,0),BackgroundColor3=AC,ZIndex=8,Parent=trk})
            corner(fill,RC.pill)
            onAC(function(c) fill.BackgroundColor3=c end)
            local r={Value=cur}
            function r:Set(v)
                v=math.clamp(v,0,maxV); cur=v
                tw(fill,{Size=dim2(v/maxV,0,1,0)},Enum.EasingStyle.Quint,0.22)
                pct.Text=math.round(v/maxV*100).."%"
            end
            function r:Get() return cur end; return r
        end

        return CAT
    end

    -- ── Window API ──────────────────────────────────────────────
    function WO:SetAccent(c) AC=c; fireAC() end
    function WO:Toggle() _vis=not _vis; BG.Visible=_vis; BAR.Visible=_vis; if not _vis then SW.Visible=false end end
    function WO:Destroy() SG:Destroy() end
    function WO:SetBackground(id) BG_IMG.Image=id; SW_IMG.Image=id end

    return WO
end

return Peleccos
