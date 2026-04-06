--[[
╔══════════════════════════════════════════════════════════════════╗
║           PELECCOS SOFTWARES  v12.0                             ║
╠══════════════════════════════════════════════════════════════════╣
║  LAYOUT:                                                         ║
║    TOP BAR : Easter Egg btn | scrollable categories | Settings  ║
║    MAIN WIN: image bg, draggable by clicking anywhere on it     ║
║    SETTINGS: same visual style as main window, separate frame   ║
║    WATERMARK: always visible (even when UI hidden), draggable   ║
║               toggle in Settings to show/hide it                ║
║                                                                  ║
║  API:                                                            ║
║    local Win = Lib:CreateWindow({ ... })                        ║
║    local Cat = Win:AddCategory("Name")                          ║
║    Cat:AddButton / AddToggle / AddSlider / AddLabel             ║
║    Cat:AddDropdown / AddTextbox / AddColorPicker                ║
║    Cat:AddKeybind / AddSeparator / AddProgressBar               ║
╚══════════════════════════════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════════════════════════
local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")
local LP           = Players.LocalPlayer

-- ═══════════════════════════════════════════════════════════════
-- FOLDERS
-- ═══════════════════════════════════════════════════════════════
local _FOLDER = "PeleccosSoftwares"
pcall(function() if not isfolder(_FOLDER) then makefolder(_FOLDER) end end)
pcall(function() if not isfolder(_FOLDER.."/videos") then makefolder(_FOLDER.."/videos") end end)

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

-- Border radius constants:
-- R_OUTER = outer shells / rows  (3px = almost square, blocky)
-- R_INNER = inner btn faces / inputs (4px = just a touch of rounding)
-- R_PILL  = toggle track only
local R_OUTER = UDim.new(0, 3)
local R_INNER = UDim.new(0, 4)
local R_PILL  = UDim.new(0, 9)

local function cor(p, r)
    local c = Instance.new("UICorner"); c.CornerRadius = r or R_INNER; c.Parent = p; return c
end
local function str(p, col, t)
    local s = Instance.new("UIStroke"); s.Color = col or Color3.fromRGB(55,55,55)
    s.Thickness = t or 1; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = p; return s
end
local function pad(p, t, r, b, l)
    local u = Instance.new("UIPadding")
    u.PaddingTop=UDim.new(0,t or 0); u.PaddingRight=UDim.new(0,r or 0)
    u.PaddingBottom=UDim.new(0,b or 0); u.PaddingLeft=UDim.new(0,l or 0)
    u.Parent=p; return u
end
local function lst(p, dir, gap, ha, va)
    local l = Instance.new("UIListLayout")
    l.FillDirection=dir or Enum.FillDirection.Vertical
    l.Padding=UDim.new(0,gap or 0)
    l.HorizontalAlignment=ha or Enum.HorizontalAlignment.Left
    l.VerticalAlignment=va or Enum.VerticalAlignment.Top
    l.SortOrder=Enum.SortOrder.LayoutOrder
    l.Parent=p; return l
end
local function autoY(sc)
    local ll=sc:FindFirstChildOfClass("UIListLayout"); if not ll then return end
    local function u() task.defer(function() if sc and sc.Parent then sc.CanvasSize=UDim2.new(0,0,0,ll.AbsoluteContentSize.Y+12) end end) end
    ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(u); u()
end
local function makeDraggable(frame, handle)
    local dragging,ds,sp=false,nil,nil; handle=handle or frame
    handle.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true;ds=i.Position;sp=frame.Position end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=i.Position-ds; frame.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
end

-- ═══════════════════════════════════════════════════════════════
-- PALETTE
-- ═══════════════════════════════════════════════════════════════
local C = {
    BtnBg    = Color3.fromRGB(52, 52, 52),
    BtnHover = Color3.fromRGB(70, 70, 70),
    BtnStroke= Color3.fromRGB(28, 28, 28),
    TextOn   = Color3.fromRGB(255, 255, 255),
    TextSub  = Color3.fromRGB(175, 175, 175),
    TextMuted= Color3.fromRGB(95,  95,  95),
    TrackOff = Color3.fromRGB(42,  42,  42),
    Input    = Color3.fromRGB(28,  28,  28),
    SliderBg = Color3.fromRGB(38,  38,  38),
    RowBg    = Color3.fromRGB(0,   0,   0),
    Sep      = Color3.fromRGB(58,  58,  58),
    Notif    = Color3.fromRGB(22,  22,  22),
    WinBg    = Color3.fromRGB(18,  18,  18),
    WmBg     = Color3.fromRGB(16,  16,  16),
}

-- ═══════════════════════════════════════════════════════════════
-- NOTIFICATION SYSTEM
-- ═══════════════════════════════════════════════════════════════
local _NH
local NC = {
    Success=Color3.fromRGB(50,200,100), Warning=Color3.fromRGB(255,185,0),
    Error=Color3.fromRGB(255,60,60),    Info=Color3.fromRGB(0,130,255),
}
local function initNotifs(sg)
    _NH=new("Frame",{Size=UDim2.new(0,290,1,0),Position=UDim2.new(1,-298,0,0),BackgroundTransparency=1,ZIndex=400,Parent=sg})
    lst(_NH,Enum.FillDirection.Vertical,8); pad(_NH,12,0,12,0)
end
local function notify(o)
    if not _NH then return end; o=o or {}
    local ac=NC[o.Type or "Info"] or NC.Info
    local card=new("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=C.Notif,BackgroundTransparency=1,Position=UDim2.new(1.2,0,0,0),ZIndex=401,Parent=_NH})
    cor(card,R_OUTER); str(card,Color3.fromRGB(45,45,45),1)
    local bar=new("Frame",{Size=UDim2.new(0,3,1,0),BackgroundColor3=ac,ZIndex=402,Parent=card})
    local inn=new("Frame",{Size=UDim2.new(1,-3,1,0),Position=UDim2.new(0,3,0,0),BackgroundTransparency=1,ZIndex=402,Parent=card})
    pad(inn,8,8,8,8); lst(inn,Enum.FillDirection.Vertical,4)
    local hrow=new("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,ZIndex=403,Parent=inn})
    lst(hrow,Enum.FillDirection.Horizontal,6,Enum.HorizontalAlignment.Left,Enum.VerticalAlignment.Center)
    local typeLabels={Success="OK",Warning="!!",Error="XX",Info="??"}
    local ico=new("TextLabel",{Text=typeLabels[o.Type or "Info"] or "??",Size=UDim2.new(0,20,0,16),BackgroundColor3=ac,TextColor3=C.TextOn,TextSize=9,Font=Enum.Font.GothamBold,ZIndex=403,Parent=hrow})
    cor(ico,R_OUTER)
    new("TextLabel",{Text=o.Title or "Notice",Size=UDim2.new(1,-26,0,16),BackgroundTransparency=1,TextColor3=C.TextOn,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=403,Parent=hrow})
    if o.Desc and o.Desc~="" then new("TextLabel",{Text=o.Desc,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,TextColor3=Color3.fromRGB(140,140,150),TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,ZIndex=403,Parent=inn}) end
    tw(card,{BackgroundTransparency=0,Position=UDim2.new(0,0,0,0)},.28,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
    local dur=o.Duration or 4
    task.delay(dur,function() tw(card,{BackgroundTransparency=1,Position=UDim2.new(1.2,0,0,0)},.2); task.wait(.22); pcall(function() card:Destroy() end) end)
end

-- ═══════════════════════════════════════════════════════════════
-- FPS / PING
-- ═══════════════════════════════════════════════════════════════
local _fps,_ping=60,0
RunService.Heartbeat:Connect(function(dt) _fps=math.floor(1/dt) end)
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
local EASTER_VIDEOS={
    {id="MUwoJJNAwhI",loop=false,audioOnly=false},{id="pKBTU3jTUQU",loop=false,audioOnly=false},
    {id="KcrtcnvkcWQ",loop=true, audioOnly=false},{id="HnH1MgwJFvY",loop=false,audioOnly=false},
    {id="igmpRziaOqc",loop=false,audioOnly=false},{id="I0lA3rHbFuE",loop=false,audioOnly=true },
    {id="u-fOF9Wlpd8",loop=false,audioOnly=false},{id="PHvhOPM_5ak",loop=true, audioOnly=false},
    {id="Fy69pNzf9iE",loop=false,audioOnly=false},{id="7xO4u-lzsYU",loop=false,audioOnly=false},
    {id="WnOWVSYNMFw",loop=false,audioOnly=false},{id="1L1WkeRR-EQ",loop=true, audioOnly=false},
    {id="NoR9zrJiSLc",loop=false,audioOnly=false},{id="JabG22Zl02I",loop=false,audioOnly=false},
    {id="YmHZI03a_Yo",loop=false,audioOnly=false},{id="mHJ3l18YqNM",loop=false,audioOnly=false},
}
local EASTER_KEYWORDS={"peleccos","easter","egg","secret","hidden","password","cheat","hack","admin","god","infinite","unlimited","special","rare","legendary"}

-- ═══════════════════════════════════════════════════════════════
-- REUSABLE COLOR PICKER BUILDER
-- ═══════════════════════════════════════════════════════════════
local function makeColorPickerBuilder(SG_ref)
    return function(ov, swBtn, initH, initS, initV, onUpdate)
        local ch,cs,cv=initH,initS,initV
        local ap=swBtn.AbsolutePosition; local pw,ph=220,150
        local px=math.min(ap.X,SG_ref.AbsoluteSize.X-pw-8)
        local py=ap.Y+26; if py+ph>SG_ref.AbsoluteSize.Y-8 then py=ap.Y-ph-6 end
        local pan=new("TextButton",{AutoButtonColor=false,Text="",Size=UDim2.new(0,pw,0,0),Position=UDim2.new(0,px,0,py),BackgroundColor3=C.WinBg,ZIndex=210,Parent=ov})
        cor(pan,R_OUTER); str(pan,Color3.fromRGB(50,50,50),1)
        tw(pan,{Size=UDim2.new(0,pw,0,ph)},.15,Enum.EasingStyle.Back)
        local svbg=new("Frame",{Size=UDim2.new(1,-12,0,86),Position=UDim2.new(0,6,0,6),BackgroundColor3=Color3.fromHSV(ch,1,1),ZIndex=211,Parent=pan})
        cor(svbg,R_OUTER)
        local wl=new("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.fromRGB(255,255,255),ZIndex=212,Parent=svbg}); cor(wl,R_OUTER)
        new("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)}),Parent=wl})
        local bl=new("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.fromRGB(0,0,0),ZIndex=213,Parent=svbg}); cor(bl,R_OUTER)
        new("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)}),Rotation=90,Parent=bl})
        local svc=new("Frame",{Size=UDim2.new(0,10,0,10),AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(cs,0,1-cv,0),BackgroundColor3=C.TextOn,ZIndex=215,Parent=svbg}); cor(svc,UDim.new(0,5)); str(svc,Color3.fromRGB(0,0,0),1.5)
        local hb=new("Frame",{Size=UDim2.new(1,-12,0,10),Position=UDim2.new(0,6,0,98),ZIndex=211,Parent=pan}); cor(hb,R_OUTER)
        new("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,0,0)),ColorSequenceKeypoint.new(.17,Color3.fromRGB(255,255,0)),ColorSequenceKeypoint.new(.33,Color3.fromRGB(0,255,0)),ColorSequenceKeypoint.new(.5,Color3.fromRGB(0,255,255)),ColorSequenceKeypoint.new(.67,Color3.fromRGB(0,0,255)),ColorSequenceKeypoint.new(.83,Color3.fromRGB(255,0,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(255,0,0))}),Parent=hb})
        local hc=new("Frame",{Size=UDim2.new(0,3,1,4),AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(ch,0,.5,0),BackgroundColor3=C.TextOn,ZIndex=213,Parent=hb}); cor(hc,UDim.new(0,2))
        local pv=new("Frame",{Size=UDim2.new(1,-12,0,12),Position=UDim2.new(0,6,0,116),BackgroundColor3=Color3.fromHSV(ch,cs,cv),ZIndex=211,Parent=pan}); cor(pv,R_OUTER)
        local function upd()
            local col=Color3.fromHSV(ch,cs,cv)
            svbg.BackgroundColor3=Color3.fromHSV(ch,1,1); svc.Position=UDim2.new(cs,0,1-cv,0)
            hc.Position=UDim2.new(ch,0,.5,0); pv.BackgroundColor3=col; onUpdate(col,ch,cs,cv)
        end
        local svd,hud=false,false
        svbg.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then svd=true;cs=math.clamp((i.Position.X-svbg.AbsolutePosition.X)/svbg.AbsoluteSize.X,0,1);cv=1-math.clamp((i.Position.Y-svbg.AbsolutePosition.Y)/svbg.AbsoluteSize.Y,0,1);upd() end end)
        hb.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then hud=true;ch=math.clamp((i.Position.X-hb.AbsolutePosition.X)/hb.AbsoluteSize.X,0,1);upd() end end)
        UIS.InputChanged:Connect(function(i) if i.UserInputType~=Enum.UserInputType.MouseMovement then return end; if svd then cs=math.clamp((i.Position.X-svbg.AbsolutePosition.X)/svbg.AbsoluteSize.X,0,1);cv=1-math.clamp((i.Position.Y-svbg.AbsolutePosition.Y)/svbg.AbsoluteSize.Y,0,1);upd() end; if hud then ch=math.clamp((i.Position.X-hb.AbsolutePosition.X)/hb.AbsoluteSize.X,0,1);upd() end end)
        UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then svd=false;hud=false end end)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- LIBRARY
-- ═══════════════════════════════════════════════════════════════
local Peleccos={}; Peleccos.__index=Peleccos

function Peleccos:CreateWindow(o)
    o=o or {}
    pcall(function() local x=game:GetService("CoreGui"):FindFirstChild("PeleccosV12"); if x then x:Destroy() end end)
    pcall(function() local pg=LP:FindFirstChild("PlayerGui"); local x=pg and pg:FindFirstChild("PeleccosV12"); if x then x:Destroy() end end)

    local AC=o.AccentColor or Color3.fromRGB(80,80,92)
    local _acCBs={}
    local function onAC(fn) table.insert(_acCBs,fn) end
    local function fireAC() for _,fn in pairs(_acCBs) do pcall(fn,AC) end end

    local KEY      = o.Key or Enum.KeyCode.Insert
    local BG_IMAGE = o.Background or "rbxassetid://118298630077545"
    local CFG={
        ScriptName = o.Title      or "PeleccosSoftwares",
        UserName   = o.UserName   or (LP and LP.Name or "User"),
        ConfigName = o.ConfigName or "Default",
        BuildType  = o.BuildType  or "Public",
        GameName   = o.GameName   or tostring(game.Name or "Unknown"),
        GameId     = o.GameId     or tostring(game.GameId or 0),
        BgColor    = o.BgColor    or Color3.fromRGB(35,35,35),
        ShowWM     = true,
    }

    -- ── ScreenGui ──────────────────────────────────────────────
    local SG=new("ScreenGui",{Name="PeleccosV12",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
    local ok=pcall(function() SG.Parent=game:GetService("CoreGui") end)
    if not ok then SG.Parent=LP:WaitForChild("PlayerGui") end
    initNotifs(SG)
    local buildCP=makeColorPickerBuilder(SG)

    -- overlay root for dropdowns / color pickers
    local _ovFrame=new("Frame",{Name="OvRoot",Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,ZIndex=200,Parent=SG})
    local _ovActive=nil
    local function closeOV() if _ovActive then _ovActive:Destroy();_ovActive=nil end end
    local function openOV(fn)
        closeOV()
        local f=new("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,ZIndex=200,Parent=_ovFrame})
        local bg=new("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=200,Parent=f})
        local canClose=false; task.delay(0.15,function() canClose=true end)
        bg.MouseButton1Click:Connect(function() if canClose then closeOV() end end)
        _ovActive=f; fn(f)
    end

    -- ── MAIN BACKGROUND WINDOW ─────────────────────────────────
    local BG=new("Frame",{Name="Background",ZIndex=2,BorderSizePixel=0,BackgroundColor3=CFG.BgColor,Size=UDim2.new(0.32558,0,0.85044,0),Position=UDim2.new(0.35349,0,0.1076,0),Parent=SG})
    -- No UICorner on BG = fully square/blocky outer border
    str(BG,Color3.fromRGB(38,38,38),1)

    local BG_IMG=new("ImageLabel",{Name="Image",BorderSizePixel=0,BackgroundColor3=Color3.fromRGB(10,10,10),AnchorPoint=Vector2.new(0.5,0.5),Image=BG_IMAGE,Size=UDim2.new(0.98058,0,0.97555,0),Position=UDim2.new(0.5,0,0.5,0),ZIndex=2,Parent=BG})
    cor(BG_IMG,R_OUTER)
    local overlay=new("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.fromRGB(0,0,0),BackgroundTransparency=0.42,ZIndex=3,Parent=BG_IMG}); cor(overlay,R_OUTER)

    -- transparent drag handle stretched over full image (ZIndex 3, below content at 5)
    local BG_DRAG=new("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",AutoButtonColor=false,ZIndex=3,Parent=BG_IMG})
    makeDraggable(BG,BG_DRAG)

    -- content scroll (ZIndex 5, above drag handle)
    local CONTENT=new("ScrollingFrame",{Size=UDim2.new(0.96,0,0.93,0),Position=UDim2.new(0.02,0,0.04,0),BackgroundTransparency=1,ScrollBarThickness=3,ScrollBarImageColor3=AC,CanvasSize=UDim2.new(0,0,0,0),ZIndex=5,Parent=BG_IMG})
    onAC(function(c) CONTENT.ScrollBarImageColor3=c end)
    local contentList=lst(CONTENT,Enum.FillDirection.Vertical,6); pad(CONTENT,8,4,8,4)
    contentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        task.defer(function() if CONTENT and CONTENT.Parent then CONTENT.CanvasSize=UDim2.new(0,0,0,contentList.AbsoluteContentSize.Y+20) end end)
    end)

    -- ── TOP BAR ────────────────────────────────────────────────
    local BAR=new("Frame",{Name="Bar",BorderSizePixel=0,BackgroundColor3=Color3.fromRGB(0,0,0),BackgroundTransparency=0.3,Size=UDim2.new(1,0,0.038,0),ZIndex=10,Parent=SG})

    local EGG_BTN=new("TextButton",{Name="EasterEGG",Text="Easter Egg",TextColor3=C.TextOn,TextSize=12,Font=Enum.Font.GothamBold,BorderSizePixel=0,BackgroundColor3=C.BtnBg,Size=UDim2.new(0,98,0.94,0),Position=UDim2.new(0,2,0.03,0),AutoButtonColor=false,ZIndex=11,Visible=false,Parent=BAR})
    cor(EGG_BTN,R_OUTER); str(EGG_BTN,C.BtnStroke,2)
    EGG_BTN.MouseEnter:Connect(function() tw(EGG_BTN,{BackgroundColor3=C.BtnHover},.1) end)
    EGG_BTN.MouseLeave:Connect(function() tw(EGG_BTN,{BackgroundColor3=C.BtnBg},.1) end)

    local CAT_SCROLL=new("ScrollingFrame",{Name="categorias",Active=true,ScrollingDirection=Enum.ScrollingDirection.X,BorderSizePixel=0,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.X,BackgroundTransparency=1,ScrollBarThickness=0,ZIndex=11,Parent=BAR})
    lst(CAT_SCROLL,Enum.FillDirection.Horizontal,3,Enum.HorizontalAlignment.Center,Enum.VerticalAlignment.Center)

    local SETTINGS_BTN=new("TextButton",{Name="Settings",Text="Settings",TextColor3=C.TextOn,TextSize=12,Font=Enum.Font.GothamBold,BorderSizePixel=0,BackgroundColor3=C.BtnBg,Size=UDim2.new(0,68,0.94,0),Position=UDim2.new(1,-70,0.03,0),AutoButtonColor=false,ZIndex=11,Parent=BAR})
    cor(SETTINGS_BTN,R_OUTER); str(SETTINGS_BTN,C.BtnStroke,2)
    SETTINGS_BTN.MouseEnter:Connect(function() tw(SETTINGS_BTN,{BackgroundColor3=C.BtnHover},.1) end)
    SETTINGS_BTN.MouseLeave:Connect(function() tw(SETTINGS_BTN,{BackgroundColor3=C.BtnBg},.1) end)

    local function repositionBar()
        local eggW=EGG_BTN.Visible and 104 or 2
        CAT_SCROLL.Position=UDim2.new(0,eggW+2,0,0); CAT_SCROLL.Size=UDim2.new(1,-(eggW+74),1,0)
    end
    repositionBar(); EGG_BTN:GetPropertyChangedSignal("Visible"):Connect(repositionBar)

    -- ── WATERMARK ──────────────────────────────────────────────
    -- Parented directly to SG — completely independent of UI visibility toggle
    local WM=new("Frame",{Name="Watermark",BorderSizePixel=0,BackgroundColor3=C.WmBg,BackgroundTransparency=0.08,Size=UDim2.new(0,580,0,22),Position=UDim2.new(0.006,0,0.053,0),ZIndex=20,Parent=SG})
    str(WM,Color3.fromRGB(45,45,45),1) -- no UICorner = square/blocky
    local wmInner=new("Frame",{Size=UDim2.new(1,-8,1,0),Position=UDim2.new(0,4,0,0),BackgroundTransparency=1,ZIndex=21,Parent=WM})
    lst(wmInner,Enum.FillDirection.Horizontal,0,Enum.HorizontalAlignment.Left,Enum.VerticalAlignment.Center)
    local wmLabels={}
    local function mkWmSep()
        new("TextLabel",{Text=" | ",Size=UDim2.new(0,14,1,0),BackgroundTransparency=1,TextColor3=C.Sep,TextSize=10,Font=Enum.Font.Gotham,ZIndex=21,Parent=wmInner})
    end
    local function mkWmLbl(key,txt,bold)
        local lbl=new("TextLabel",{Text=tostring(txt),Size=UDim2.new(0,0,1,0),AutomaticSize=Enum.AutomaticSize.X,BackgroundTransparency=1,TextColor3=key=="script" and AC or C.TextSub,TextSize=10,Font=(bold or key=="script") and Enum.Font.GothamBold or Enum.Font.Gotham,ZIndex=21,Parent=wmInner})
        if key=="script" then onAC(function(c) lbl.TextColor3=c end) end
        return lbl
    end
    wmLabels.script=mkWmLbl("script",CFG.ScriptName,true); mkWmSep()
    wmLabels.user  =mkWmLbl("user",  CFG.UserName);         mkWmSep()
    wmLabels.config=mkWmLbl("config",CFG.ConfigName);        mkWmSep()
    wmLabels.fps   =mkWmLbl("fps",   "FPS: --");             mkWmSep()
    wmLabels.ping  =mkWmLbl("ping",  "Ping: --ms");          mkWmSep()
    wmLabels.build =mkWmLbl("build", "["..CFG.BuildType.."]"); mkWmSep()
    wmLabels.game  =mkWmLbl("game",  CFG.GameName.." ("..CFG.GameId..")")
    makeDraggable(WM,WM)
    RunService.Heartbeat:Connect(function()
        pcall(function() wmLabels.fps.Text="FPS: "..tostring(_fps); wmLabels.ping.Text="Ping: "..tostring(_ping).."ms" end)
    end)

    -- Live watermark setter — called from settings textboxes
    local function wmSet(key,value)
        CFG[key]=value
        if key=="ScriptName" then wmLabels.script.Text=value
        elseif key=="UserName"   then wmLabels.user.Text=value
        elseif key=="ConfigName" then wmLabels.config.Text=value
        elseif key=="BuildType"  then wmLabels.build.Text="["..value.."]"
        elseif key=="GameName"   then wmLabels.game.Text=value.." ("..CFG.GameId..")"
        elseif key=="GameId"     then wmLabels.game.Text=CFG.GameName.." ("..value..")" end
    end

    -- ── SETTINGS WINDOW ────────────────────────────────────────
    -- Same exact visual recipe as main window: square outer, image bg, dark overlay
    local SW=new("Frame",{Name="SettingsWin",BackgroundColor3=CFG.BgColor,BorderSizePixel=0,ZIndex=100,Visible=false,Size=UDim2.new(0,330,0,490),Position=UDim2.new(0.5,-165,0.5,-245),Parent=SG})
    str(SW,Color3.fromRGB(38,38,38),1) -- square outer, same as BG
    local SW_IMG=new("ImageLabel",{BorderSizePixel=0,BackgroundColor3=Color3.fromRGB(10,10,10),AnchorPoint=Vector2.new(0.5,0.5),Image=BG_IMAGE,Size=UDim2.new(0.993,0,0.993,0),Position=UDim2.new(0.5,0,0.5,0),ZIndex=101,Parent=SW})
    cor(SW_IMG,R_OUTER)
    local sw_ov=new("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.fromRGB(0,0,0),BackgroundTransparency=0.42,ZIndex=102,Parent=SW_IMG}); cor(sw_ov,R_OUTER)

    -- Title bar (draggable handle for SW)
    local SW_HDR=new("Frame",{Size=UDim2.new(1,0,0,28),BackgroundColor3=Color3.fromRGB(0,0,0),BackgroundTransparency=0.5,ZIndex=103,Parent=SW_IMG})
    new("TextLabel",{Text="Settings",Size=UDim2.new(1,-36,1,0),Position=UDim2.new(0,8,0,0),BackgroundTransparency=1,TextColor3=C.TextOn,TextSize=13,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=104,Parent=SW_HDR})
    local SW_CLOSE=new("TextButton",{Text="X",Size=UDim2.new(0,24,0,20),Position=UDim2.new(1,-26,0,4),BackgroundColor3=Color3.fromRGB(50,18,18),TextColor3=C.TextOn,TextSize=10,Font=Enum.Font.GothamBold,AutoButtonColor=false,ZIndex=105,Parent=SW_HDR})
    cor(SW_CLOSE,R_OUTER); str(SW_CLOSE,Color3.fromRGB(80,28,28),1)
    SW_CLOSE.MouseButton1Click:Connect(function() SW.Visible=false end)
    makeDraggable(SW,SW_HDR)

    -- Content scroll inside settings
    local SW_SCROLL=new("ScrollingFrame",{Size=UDim2.new(1,-6,1,-32),Position=UDim2.new(0,3,0,30),BackgroundTransparency=1,ScrollBarThickness=3,ScrollBarImageColor3=AC,CanvasSize=UDim2.new(0,0,0,0),ZIndex=103,Parent=SW_IMG})
    onAC(function(c) SW_SCROLL.ScrollBarImageColor3=c end)
    local swList=lst(SW_SCROLL,Enum.FillDirection.Vertical,6); pad(SW_SCROLL,8,8,8,8)
    swList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        task.defer(function() if SW_SCROLL and SW_SCROLL.Parent then SW_SCROLL.CanvasSize=UDim2.new(0,0,0,swList.AbsoluteContentSize.Y+16) end end)
    end)

    -- Settings sub-helpers
    local function swSection(title)
        local lbl=new("TextLabel",{Text=title:upper(),Size=UDim2.new(1,0,0,14),BackgroundColor3=Color3.fromRGB(0,0,0),BackgroundTransparency=0.55,TextColor3=AC,TextSize=9,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=104,Parent=SW_SCROLL})
        pad(lbl,0,0,0,4); onAC(function(c) lbl.TextColor3=c end)
    end
    local function swTextbox(label, defaultVal, onChanged)
        local wrap=new("Frame",{Size=UDim2.new(1,0,0,40),BackgroundTransparency=1,ZIndex=104,Parent=SW_SCROLL})
        new("TextLabel",{Text=label,Size=UDim2.new(1,0,0,13),BackgroundTransparency=1,TextColor3=C.TextSub,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=105,Parent=wrap})
        local ifrm=new("Frame",{Size=UDim2.new(1,0,0,22),Position=UDim2.new(0,0,0,16),BackgroundColor3=C.Input,ZIndex=105,Parent=wrap})
        cor(ifrm,R_OUTER); str(ifrm,Color3.fromRGB(50,50,50),1)
        local tb=new("TextBox",{PlaceholderText="...",Text=tostring(defaultVal),Size=UDim2.new(1,-8,1,0),Position=UDim2.new(0,6,0,0),BackgroundTransparency=1,TextColor3=C.TextOn,PlaceholderColor3=C.TextMuted,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false,ZIndex=106,Parent=ifrm})
        tb.FocusLost:Connect(function() if onChanged then onChanged(tb.Text) end end)
        return tb
    end
    local function swButton(txt, cb)
        local btn=new("TextButton",{Text=txt,Size=UDim2.new(1,0,0,24),BackgroundColor3=C.BtnBg,TextColor3=C.TextSub,TextSize=11,Font=Enum.Font.GothamSemibold,AutoButtonColor=false,ZIndex=104,Parent=SW_SCROLL})
        cor(btn,R_OUTER); str(btn,C.BtnStroke,1)
        btn.MouseEnter:Connect(function() tw(btn,{BackgroundColor3=C.BtnHover,TextColor3=C.TextOn},.1) end)
        btn.MouseLeave:Connect(function() tw(btn,{BackgroundColor3=C.BtnBg,TextColor3=C.TextSub},.1) end)
        btn.MouseButton1Click:Connect(function() if cb then cb() end end)
        return btn
    end
    local function swToggle(label, default, cb)
        local row=new("Frame",{Size=UDim2.new(1,0,0,24),BackgroundColor3=Color3.fromRGB(0,0,0),BackgroundTransparency=0.5,ZIndex=104,Parent=SW_SCROLL})
        cor(row,R_OUTER)
        new("TextLabel",{Text=label,Size=UDim2.new(1,-48,1,0),Position=UDim2.new(0,6,0,0),BackgroundTransparency=1,TextColor3=C.TextSub,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=105,Parent=row})
        local val=default==true
        local track=new("Frame",{Size=UDim2.new(0,32,0,15),Position=UDim2.new(1,-36,.5,-7.5),BackgroundColor3=val and AC or C.TrackOff,ZIndex=105,Parent=row}); cor(track,R_PILL)
        local knob=new("Frame",{Size=UDim2.new(0,11,0,11),Position=val and UDim2.new(1,-13,.5,-5.5) or UDim2.new(0,2,.5,-5.5),BackgroundColor3=C.TextOn,ZIndex=106,Parent=track}); cor(knob,UDim.new(0,5.5))
        onAC(function(c) if val then track.BackgroundColor3=c end end)
        local tbtn=new("TextButton",{Size=UDim2.new(0,32,0,15),Position=UDim2.new(1,-36,.5,-7.5),BackgroundTransparency=1,Text="",AutoButtonColor=false,ZIndex=107,Parent=row})
        tbtn.MouseButton1Click:Connect(function()
            val=not val; track.BackgroundColor3=val and AC or C.TrackOff
            tw(knob,{Position=val and UDim2.new(1,-13,.5,-5.5) or UDim2.new(0,2,.5,-5.5)},.14,Enum.EasingStyle.Back)
            if cb then cb(val) end
        end)
        return {Get=function() return val end}
    end
    local function swColorRow(label, defaultCol, onChanged)
        local row=new("Frame",{Size=UDim2.new(1,0,0,24),BackgroundColor3=Color3.fromRGB(0,0,0),BackgroundTransparency=0.5,ZIndex=104,Parent=SW_SCROLL})
        cor(row,R_OUTER)
        new("TextLabel",{Text=label,Size=UDim2.new(1,-44,1,0),Position=UDim2.new(0,6,0,0),BackgroundTransparency=1,TextColor3=C.TextSub,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=105,Parent=row})
        local col=defaultCol; local h,s,v=Color3.toHSV(col)
        local sw=new("TextButton",{Size=UDim2.new(0,32,0,17),Position=UDim2.new(1,-36,.5,-8.5),BackgroundColor3=col,Text="",AutoButtonColor=false,ZIndex=105,Parent=row})
        cor(sw,R_OUTER); str(sw,Color3.fromRGB(58,58,58),1)
        local open=false
        sw.MouseButton1Click:Connect(function()
            open=not open
            if open then openOV(function(ov)
                buildCP(ov,sw,h,s,v,function(newCol,nh,ns,nv) col=newCol;h,s,v=nh,ns,nv; sw.BackgroundColor3=newCol; if onChanged then onChanged(newCol) end end)
            end) else closeOV() end
        end)
        return {Get=function() return col end}
    end

    -- Populate Settings
    swSection("Appearance")
    swColorRow("Accent Color", AC, function(c) AC=c; fireAC() end)
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

    swSection("Copy Info")
    swButton("Copy Username",    function() pcall(function() setclipboard(LP.Name) end); notify({Title="Copied",Desc="Username copied.",Type="Success",Duration=2}) end)
    swButton("Copy User ID",     function() pcall(function() setclipboard(tostring(LP.UserId)) end); notify({Title="Copied",Desc="User ID copied.",Type="Success",Duration=2}) end)
    swButton("Copy Game ID",     function() pcall(function() setclipboard(tostring(game.GameId)) end); notify({Title="Copied",Desc="Game ID copied.",Type="Success",Duration=2}) end)
    swButton("Copy Config Name", function() pcall(function() setclipboard(CFG.ConfigName) end); notify({Title="Copied",Desc="Config name copied.",Type="Success",Duration=2}) end)

    swSection("Danger Zone")
    local unloadBtn=new("TextButton",{Text="Unload Script",Size=UDim2.new(1,0,0,26),BackgroundColor3=Color3.fromRGB(48,17,17),TextColor3=Color3.fromRGB(255,85,85),TextSize=12,Font=Enum.Font.GothamBold,AutoButtonColor=false,ZIndex=104,Parent=SW_SCROLL})
    cor(unloadBtn,R_OUTER); str(unloadBtn,Color3.fromRGB(85,24,24),1)
    unloadBtn.MouseEnter:Connect(function() tw(unloadBtn,{BackgroundColor3=Color3.fromRGB(70,22,22)},.1) end)
    unloadBtn.MouseLeave:Connect(function() tw(unloadBtn,{BackgroundColor3=Color3.fromRGB(48,17,17)},.1) end)
    unloadBtn.MouseButton1Click:Connect(function()
        notify({Title="Unloading",Desc="Removing script...",Type="Warning",Duration=2})
        task.delay(.5,function() pcall(function() SG:Destroy() end) end)
    end)

    SETTINGS_BTN.MouseButton1Click:Connect(function() SW.Visible=not SW.Visible end)

    -- ── EASTER EGG ─────────────────────────────────────────────
    local _eggActive=false
    task.spawn(function()
        while SG and SG.Parent do
            task.wait(5)
            pcall(function()
                local found=false
                local function scan(inst,depth)
                    if depth>5 or found then return end
                    local ok2,txt=pcall(function() return inst.Text end)
                    if ok2 and txt then local low=txt:lower(); for _,kw in ipairs(EASTER_KEYWORDS) do if low:find(kw,1,true) then found=true; return end end end
                    for _,ch2 in ipairs(inst:GetChildren()) do scan(ch2,depth+1) end
                end
                pcall(function() scan(LP.PlayerGui,0) end); pcall(function() scan(workspace,0) end)
                if found and not EGG_BTN.Visible then
                    EGG_BTN.Visible=true; repositionBar()
                    notify({Title="Easter Egg",Desc="Something was found. Check the bar.",Type="Warning",Duration=5})
                end
            end)
        end
    end)
    EGG_BTN.MouseButton1Click:Connect(function()
        if _eggActive then return end; _eggActive=true
        local vid=EASTER_VIDEOS[math.random(1,#EASTER_VIDEOS)]
        local ov2=new("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.fromRGB(0,0,0),BackgroundTransparency=0,ZIndex=500,Parent=SG})
        local panel=new("Frame",{Size=UDim2.new(0,340,0,170),Position=UDim2.new(0.5,-170,0.5,-85),BackgroundColor3=Color3.fromRGB(14,14,14),ZIndex=501,Parent=ov2})
        cor(panel,R_OUTER); str(panel,Color3.fromRGB(52,52,52),1)
        new("TextLabel",{Text="EASTER EGG",Size=UDim2.new(1,0,0,26),BackgroundColor3=Color3.fromRGB(0,0,0),BackgroundTransparency=0.4,TextColor3=AC,TextSize=13,Font=Enum.Font.GothamBold,ZIndex=502,Parent=panel})
        onAC(function(c) panel:FindFirstChild("TextLabel") and (panel:FindFirstChild("TextLabel").TextColor3=c) end)
        new("TextLabel",{Text="youtu.be/"..vid.id.."\n\n"..(vid.audioOnly and "[Audio Only]" or "[Video]")..(vid.loop and "  [Looping]" or "").."\n\nSaved to: ".._FOLDER.."/videos/",Size=UDim2.new(1,-20,0,95),Position=UDim2.new(0,10,0,32),BackgroundTransparency=1,TextColor3=Color3.fromRGB(195,195,205),TextSize=11,Font=Enum.Font.Gotham,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=502,Parent=panel})
        pcall(function() local fname=_FOLDER.."/videos/"..vid.id..".txt"; if not isfile(fname) then writefile(fname,"https://www.youtube.com/watch?v="..vid.id) end end)
        local closeBtn=new("TextButton",{Text="Close",Size=UDim2.new(0,80,0,24),Position=UDim2.new(0.5,-40,1,-32),BackgroundColor3=Color3.fromRGB(48,17,17),TextColor3=C.TextOn,TextSize=11,Font=Enum.Font.GothamBold,AutoButtonColor=false,ZIndex=503,Parent=panel})
        cor(closeBtn,R_OUTER)
        closeBtn.MouseButton1Click:Connect(function() tw(ov2,{BackgroundTransparency=1},.25); task.wait(.26); pcall(function() ov2:Destroy() end); _eggActive=false end)
    end)

    -- ── VISIBILITY TOGGLE (key) ─────────────────────────────────
    local _vis=true
    UIS.InputBegan:Connect(function(i,gpe)
        if not gpe and i.KeyCode==KEY then
            _vis=not _vis; BG.Visible=_vis; BAR.Visible=_vis
            if not _vis then SW.Visible=false end
            -- WM.Visible is controlled ONLY by the "Show Watermark" toggle in settings
        end
    end)

    -- ═════════════════════════════════════════════════════════════
    -- WINDOW OBJECT
    -- ═════════════════════════════════════════════════════════════
    local WO={_categories={},_activeCategory=nil,Notify=notify}

    function WO:AddCategory(name)
        local isFirst=#self._categories==0
        local catBtn=new("TextButton",{Text=name,Size=UDim2.new(0,0,0.92,0),AutomaticSize=Enum.AutomaticSize.X,BackgroundColor3=isFirst and AC or C.BtnBg,TextColor3=isFirst and C.TextOn or C.TextSub,TextSize=12,Font=Enum.Font.GothamSemibold,BorderSizePixel=0,AutoButtonColor=false,ZIndex=12,LayoutOrder=#self._categories+1,Parent=CAT_SCROLL})
        pad(catBtn,0,10,0,10); cor(catBtn,R_OUTER); str(catBtn,C.BtnStroke,1.5)
        onAC(function(c) if self._activeCategory==CAT then catBtn.BackgroundColor3=c end end)

        local catPanel=new("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Visible=isFirst,ZIndex=5,Parent=CONTENT})
        lst(catPanel,Enum.FillDirection.Vertical,5)

        local CAT={_name=name,_btn=catBtn,_panel=catPanel,_win=self}
        table.insert(self._categories,CAT)
        if isFirst then self._activeCategory=CAT end

        local function activateCat()
            if self._activeCategory==CAT then return end
            local old=self._activeCategory
            if old then old._panel.Visible=false; tw(old._btn,{BackgroundColor3=C.BtnBg,TextColor3=C.TextSub},.12) end
            catPanel.Visible=true; tw(catBtn,{BackgroundColor3=AC,TextColor3=C.TextOn},.12); self._activeCategory=CAT
        end
        catBtn.MouseButton1Click:Connect(activateCat)
        catBtn.MouseEnter:Connect(function() if self._activeCategory~=CAT then tw(catBtn,{BackgroundColor3=Color3.fromRGB(60,60,60),TextColor3=C.TextOn},.1) end end)
        catBtn.MouseLeave:Connect(function() if self._activeCategory~=CAT then tw(catBtn,{BackgroundColor3=C.BtnBg,TextColor3=C.TextSub},.1) end end)

        -- Row builder: blocky outer shell (R_OUTER), semi-transparent dark bg
        local function mkRow(h)
            local r=new("Frame",{Size=UDim2.new(1,0,0,h or 30),BackgroundColor3=C.RowBg,BackgroundTransparency=0.48,ZIndex=6,Parent=catPanel})
            cor(r,R_OUTER); return r
        end

        -- ── AddButton ─────────────────────────────────────────
        function CAT:AddButton(o5)
            o5=o5 or {}; local nm=o5.Name or "Button"; local cb=o5.Callback or function() end
            local row=mkRow(30)
            local btn=new("TextButton",{Text=nm,Size=UDim2.new(1,-6,0,24),Position=UDim2.new(0,3,0,3),BackgroundColor3=C.BtnBg,TextColor3=C.TextSub,TextSize=12,Font=Enum.Font.GothamSemibold,AutoButtonColor=false,ZIndex=7,Parent=row})
            cor(btn,R_INNER); str(btn,C.BtnStroke,1)  -- inner face: 4px radius
            btn.MouseEnter:Connect(function() tw(btn,{BackgroundColor3=C.BtnHover,TextColor3=C.TextOn},.1) end)
            btn.MouseLeave:Connect(function() tw(btn,{BackgroundColor3=C.BtnBg,TextColor3=C.TextSub},.1) end)
            btn.MouseButton1Click:Connect(function() btn.BackgroundColor3=AC;btn.TextColor3=C.TextOn; task.delay(.18,function() tw(btn,{BackgroundColor3=C.BtnHover},.15) end); pcall(cb) end)
            local r={}; function r:SetText(t) btn.Text=t end; return r
        end

        -- ── AddLabel ──────────────────────────────────────────
        function CAT:AddLabel(o5)
            o5=o5 or {}
            local lbl=new("TextLabel",{Text=o5.Text or "",Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=C.RowBg,BackgroundTransparency=0.5,TextColor3=o5.Color or C.TextMuted,TextSize=o5.Size or 11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,ZIndex=6,Parent=catPanel})
            cor(lbl,R_OUTER); pad(lbl,4,8,4,8)
            local r={}; function r:Set(t) lbl.Text=t end; function r:Get() return lbl.Text end; return r
        end

        -- ── AddToggle ─────────────────────────────────────────
        function CAT:AddToggle(o5)
            o5=o5 or {}; local nm=o5.Name or "Toggle"; local val=o5.Default==true
            local cb=o5.Callback or function() end; local flag=o5.Flag
            local hasKB=o5.Keybind~=nil; local kbMode="Toggle"
            local kbKey=o5.Keybind or Enum.KeyCode.Unknown; local listening=false; local holding=false
            local row=mkRow(hasKB and 32 or 30)
            new("TextLabel",{Text=nm,Size=UDim2.new(1,-(hasKB and 140 or 50),1,0),Position=UDim2.new(0,8,0,0),BackgroundTransparency=1,TextColor3=C.TextSub,TextSize=12,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=7,Parent=row})
            local track=new("Frame",{Size=UDim2.new(0,34,0,16),Position=UDim2.new(1,-38,.5,-8),BackgroundColor3=val and AC or C.TrackOff,ZIndex=7,Parent=row}); cor(track,R_PILL)
            local knob=new("Frame",{Size=UDim2.new(0,12,0,12),Position=val and UDim2.new(1,-14,.5,-6) or UDim2.new(0,2,.5,-6),BackgroundColor3=C.TextOn,ZIndex=8,Parent=track}); cor(knob,UDim.new(0,6))
            local trackBtn=new("TextButton",{Size=UDim2.new(0,34,0,16),Position=UDim2.new(1,-38,.5,-8),BackgroundTransparency=1,Text="",AutoButtonColor=false,ZIndex=9,Parent=row})
            onAC(function(c) if val then track.BackgroundColor3=c end end)
            local kbBtn,modeBtn
            if hasKB then
                modeBtn=new("TextButton",{Text="T",Size=UDim2.new(0,15,0,15),Position=UDim2.new(1,-138,.5,-7.5),BackgroundColor3=C.Input,TextColor3=C.TextMuted,TextSize=8,Font=Enum.Font.GothamBold,AutoButtonColor=false,ZIndex=7,Parent=row})
                cor(modeBtn,R_OUTER); str(modeBtn,Color3.fromRGB(48,48,48),1)
                local modeOrder={"Toggle","Hold","Always"}; local modeAbbr={Toggle="T",Hold="H",Always="A"}
                modeBtn.MouseButton2Click:Connect(function()
                    local ci=1; for i,m in ipairs(modeOrder) do if m==kbMode then ci=i break end end
                    kbMode=modeOrder[(ci%#modeOrder)+1]; modeBtn.Text=modeAbbr[kbMode]
                    notify({Title="Keybind Mode",Desc=nm..": "..kbMode,Type="Info",Duration=2})
                end)
                kbBtn=new("TextButton",{Text=kbKey==Enum.KeyCode.Unknown and "NONE" or kbKey.Name,Size=UDim2.new(0,56,0,15),Position=UDim2.new(1,-118,.5,-7.5),BackgroundColor3=C.Input,TextColor3=AC,TextSize=9,Font=Enum.Font.GothamBold,AutoButtonColor=false,ZIndex=7,Parent=row})
                cor(kbBtn,R_OUTER); str(kbBtn,Color3.fromRGB(48,48,48),1)
                onAC(function(c) if not listening then kbBtn.TextColor3=c end end)
                kbBtn.MouseButton1Click:Connect(function()
                    if listening then return end
                    listening=true; kbBtn.Text="..."; kbBtn.TextColor3=Color3.fromRGB(255,185,0); kbBtn.BackgroundColor3=Color3.fromRGB(30,26,12)
                end)
            end
            local function set(v,silent)
                val=v; track.BackgroundColor3=v and AC or C.TrackOff
                tw(knob,{Position=v and UDim2.new(1,-14,.5,-6) or UDim2.new(0,2,.5,-6)},.14,Enum.EasingStyle.Back)
                if not silent then pcall(cb,v) end; if flag then _G[flag]=v end
            end
            trackBtn.MouseButton1Click:Connect(function() set(not val) end)
            if hasKB then
                UIS.InputBegan:Connect(function(i,gpe)
                    if listening and not gpe and i.UserInputType==Enum.UserInputType.Keyboard then
                        kbKey=i.KeyCode; kbBtn.Text=kbKey.Name; kbBtn.TextColor3=AC; kbBtn.BackgroundColor3=C.Input; listening=false
                    elseif not listening and not gpe and i.KeyCode==kbKey and kbKey~=Enum.KeyCode.Unknown then
                        if kbMode=="Toggle" then set(not val) elseif kbMode=="Hold" then holding=true;set(true) elseif kbMode=="Always" then set(true) end
                    end
                end)
                UIS.InputEnded:Connect(function(i) if holding and i.KeyCode==kbKey and kbMode=="Hold" then holding=false;set(false) end end)
            end
            if flag then _G[flag]=val end
            local r={Value=val}; function r:Set(v) set(v,true) end; function r:Get() return val end; return r
        end

        -- ── AddSlider ─────────────────────────────────────────
        function CAT:AddSlider(o5)
            o5=o5 or {}; local nm=o5.Name or "Slider"; local mn=o5.Min or 0; local mx=o5.Max or 100
            local step=o5.Step or 1; local suf=o5.Suffix or ""; local flag=o5.Flag; local cb=o5.Callback or function() end
            local val=math.clamp(o5.Default or mn,mn,mx)
            local wrap=new("Frame",{Size=UDim2.new(1,0,0,44),BackgroundColor3=C.RowBg,BackgroundTransparency=0.48,ZIndex=6,Parent=catPanel}); cor(wrap,R_OUTER)
            local top=new("Frame",{Size=UDim2.new(1,-8,0,19),Position=UDim2.new(0,4,0,4),BackgroundTransparency=1,ZIndex=7,Parent=wrap})
            new("TextLabel",{Text=nm,Size=UDim2.new(1,-56,1,0),BackgroundTransparency=1,TextColor3=C.TextSub,TextSize=12,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=8,Parent=top})
            local vbox=new("Frame",{Size=UDim2.new(0,48,0,16),Position=UDim2.new(1,-50,.5,-8),BackgroundColor3=C.Input,ZIndex=8,Parent=top}); cor(vbox,R_OUTER)
            local valLbl=new("TextLabel",{Text=tostring(val)..suf,Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,TextColor3=AC,TextSize=11,Font=Enum.Font.GothamBold,ZIndex=9,Parent=vbox})
            onAC(function(c) valLbl.TextColor3=c end)
            local hb=new("TextButton",{Size=UDim2.new(1,-8,0,18),Position=UDim2.new(0,4,0,24),BackgroundTransparency=1,Text="",AutoButtonColor=false,ZIndex=9,Parent=wrap})
            local tr=new("Frame",{Size=UDim2.new(1,0,0,4),Position=UDim2.new(0,0,.5,-2),BackgroundColor3=C.SliderBg,ZIndex=7,Parent=hb})
            -- track is flat (no corner) to stay blocky
            local pct=(val-mn)/(mx-mn)
            local fl=new("Frame",{Size=UDim2.new(pct,0,1,0),BackgroundColor3=AC,ZIndex=8,Parent=tr})
            onAC(function(c) fl.BackgroundColor3=c end)
            local kn=new("Frame",{Size=UDim2.new(0,13,0,13),AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(pct,0,.5,0),BackgroundColor3=C.TextOn,ZIndex=10,Parent=tr})
            cor(kn,R_INNER); str(kn,AC,2); onAC(function(c) str(kn,c,2) end)
            hb.MouseEnter:Connect(function() tw(kn,{Size=UDim2.new(0,16,0,16)},.14,Enum.EasingStyle.Back) end)
            hb.MouseLeave:Connect(function() tw(kn,{Size=UDim2.new(0,13,0,13)},.12) end)
            local function sv(v,silent)
                v=math.clamp(math.round(v/step)*step,mn,mx); val=v; local p=(v-mn)/(mx-mn)
                fl.Size=UDim2.new(p,0,1,0); kn.Position=UDim2.new(p,0,.5,0); valLbl.Text=tostring(v)..suf
                if not silent then pcall(cb,v) end; if flag then _G[flag]=v end
            end
            local dragging=false
            hb.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true;sv(mn+(mx-mn)*math.clamp((i.Position.X-tr.AbsolutePosition.X)/tr.AbsoluteSize.X,0,1)) end end)
            UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then sv(mn+(mx-mn)*math.clamp((i.Position.X-tr.AbsolutePosition.X)/tr.AbsoluteSize.X,0,1)) end end)
            UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
            if flag then _G[flag]=val end
            local r={Value=val}; function r:Set(v) sv(v,true) end; function r:Get() return val end; return r
        end

        -- ── AddTextbox ────────────────────────────────────────
        function CAT:AddTextbox(o5)
            o5=o5 or {}; local nm=o5.Name or "Textbox"; local cb=o5.Callback or function() end
            local wrap=new("Frame",{Size=UDim2.new(1,0,0,46),BackgroundColor3=C.RowBg,BackgroundTransparency=0.48,ZIndex=6,Parent=catPanel}); cor(wrap,R_OUTER)
            new("TextLabel",{Text=nm,Size=UDim2.new(1,-8,0,13),Position=UDim2.new(0,6,0,4),BackgroundTransparency=1,TextColor3=C.TextSub,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=7,Parent=wrap})
            local ifrm=new("Frame",{Size=UDim2.new(1,-8,0,21),Position=UDim2.new(0,4,0,20),BackgroundColor3=C.Input,ZIndex=7,Parent=wrap}); cor(ifrm,R_OUTER); local sk=str(ifrm,Color3.fromRGB(48,48,48),1)
            local tb=new("TextBox",{PlaceholderText=o5.Placeholder or "Type here...",Text=o5.Default or "",Size=UDim2.new(1,-34,1,0),Position=UDim2.new(0,6,0,0),BackgroundTransparency=1,TextColor3=C.TextOn,PlaceholderColor3=C.TextMuted,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false,ZIndex=8,Parent=ifrm})
            local cf=new("TextButton",{Text="OK",Size=UDim2.new(0,24,0,17),Position=UDim2.new(1,-26,.5,-8.5),BackgroundColor3=AC,TextColor3=C.TextOn,TextSize=9,Font=Enum.Font.GothamBold,AutoButtonColor=false,ZIndex=9,Parent=ifrm}); cor(cf,R_OUTER)
            onAC(function(c) cf.BackgroundColor3=c end)
            tb.Focused:Connect(function() tw(sk,{Color=AC},.12) end); tb.FocusLost:Connect(function(en) tw(sk,{Color=Color3.fromRGB(48,48,48)},.12); if en then pcall(cb,tb.Text) end end)
            cf.MouseButton1Click:Connect(function() pcall(cb,tb.Text); tb:ReleaseFocus() end)
            local r={}; function r:Set(v) tb.Text=v end; function r:Get() return tb.Text end; return r
        end

        -- ── AddDropdown ───────────────────────────────────────
        function CAT:AddDropdown(o5)
            o5=o5 or {}; local nm=o5.Name or "Dropdown"; local opts=o5.Options or {}; local multi=o5.Multi or false
            local flag=o5.Flag; local cb=o5.Callback or function() end; local sel=o5.Default or (opts[1] or ""); local msel={}
            local wrap=new("Frame",{Size=UDim2.new(1,0,0,46),BackgroundColor3=C.RowBg,BackgroundTransparency=0.48,ZIndex=6,Parent=catPanel}); cor(wrap,R_OUTER)
            new("TextLabel",{Text=nm,Size=UDim2.new(1,-8,0,13),Position=UDim2.new(0,6,0,4),BackgroundTransparency=1,TextColor3=C.TextSub,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=7,Parent=wrap})
            local hd=new("TextButton",{Size=UDim2.new(1,-8,0,21),Position=UDim2.new(0,4,0,20),BackgroundColor3=C.Input,Text="",AutoButtonColor=false,ZIndex=7,Parent=wrap}); cor(hd,R_OUTER); local hsk=str(hd,Color3.fromRGB(48,48,48),1)
            local sl=new("TextLabel",{Text=multi and "Select..." or tostring(sel),Size=UDim2.new(1,-22,1,0),Position=UDim2.new(0,6,0,0),BackgroundTransparency=1,TextColor3=C.TextOn,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=8,Parent=hd})
            new("TextLabel",{Text="v",Size=UDim2.new(0,13,1,0),Position=UDim2.new(1,-14,0,0),BackgroundTransparency=1,TextColor3=C.TextMuted,TextSize=8,Font=Enum.Font.Gotham,ZIndex=8,Parent=hd})
            hd.MouseEnter:Connect(function() tw(hd,{BackgroundColor3=C.BtnHover},.1);tw(hsk,{Color=AC},.1) end)
            hd.MouseLeave:Connect(function() tw(hd,{BackgroundColor3=C.Input},.1);tw(hsk,{Color=Color3.fromRGB(48,48,48)},.1) end)
            local isOpen=false
            local function closeDD() isOpen=false; closeOV() end
            local function buildDD(ov)
                local ap=hd.AbsolutePosition; local as=hd.AbsoluteSize; local lh=math.min(#opts*22+8,150)
                local px=math.min(ap.X,SG.AbsoluteSize.X-as.X-8); local py=ap.Y+as.Y+3; if py+lh>SG.AbsoluteSize.Y-8 then py=ap.Y-lh-3 end
                local pan=new("Frame",{Size=UDim2.new(0,as.X,0,0),Position=UDim2.new(0,px,0,py),BackgroundColor3=Color3.fromRGB(20,20,20),ZIndex=210,Parent=ov}); cor(pan,R_OUTER); str(pan,Color3.fromRGB(48,48,48),1)
                tw(pan,{Size=UDim2.new(0,as.X,0,lh)},.14,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
                local sc=new("ScrollingFrame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,ScrollBarThickness=2,ScrollBarImageColor3=AC,CanvasSize=UDim2.new(0,0,0,0),ZIndex=211,Parent=pan}); autoY(sc); lst(sc,Enum.FillDirection.Vertical,2); pad(sc,4,4,4,4)
                onAC(function(c) sc.ScrollBarImageColor3=c end)
                ov.ChildRemoved:Connect(function() isOpen=false end)
                for _,op in pairs(opts) do
                    local isSel=multi and table.find(msel,op)~=nil or op==sel
                    local ob=new("TextButton",{Size=UDim2.new(1,0,0,20),BackgroundColor3=isSel and AC or Color3.fromRGB(26,26,26),Text=op,TextColor3=isSel and C.TextOn or C.TextSub,TextSize=11,Font=Enum.Font.Gotham,AutoButtonColor=false,ZIndex=212,Parent=sc}); cor(ob,R_OUTER)
                    ob.MouseEnter:Connect(function() if not(multi and table.find(msel,op)) and op~=sel then tw(ob,{BackgroundColor3=Color3.fromRGB(40,40,40),TextColor3=C.TextOn},.08) end end)
                    ob.MouseLeave:Connect(function() local s2=multi and table.find(msel,op)~=nil or op==sel; ob.BackgroundColor3=s2 and AC or Color3.fromRGB(26,26,26); ob.TextColor3=s2 and C.TextOn or C.TextSub end)
                    ob.MouseButton1Click:Connect(function()
                        if multi then local idx=table.find(msel,op);if idx then table.remove(msel,idx) else table.insert(msel,op) end; sl.Text=#msel>0 and table.concat(msel,", ") or "Select..."; pcall(cb,msel); if flag then _G[flag]=msel end
                        else sel=op;sl.Text=op;pcall(cb,op);if flag then _G[flag]=op end;closeDD() end
                    end)
                end
            end
            hd.MouseButton1Click:Connect(function() isOpen=not isOpen; if isOpen then openOV(buildDD) else closeDD() end end)
            if flag then _G[flag]=sel end
            local r={Value=sel}; function r:Set(v) sel=v;sl.Text=v;if flag then _G[flag]=v end end; function r:SetOptions(t) opts=t end; function r:Get() return multi and msel or sel end; return r
        end

        -- ── AddColorPicker ────────────────────────────────────
        function CAT:AddColorPicker(o5)
            o5=o5 or {}; local nm=o5.Name or "Color"; local col=o5.Default or Color3.fromRGB(255,80,80)
            local flag=o5.Flag; local cb=o5.Callback or function() end; local h,s,v=Color3.toHSV(col)
            local row=mkRow(30)
            new("TextLabel",{Text=nm,Size=UDim2.new(1,-48,1,0),Position=UDim2.new(0,8,0,0),BackgroundTransparency=1,TextColor3=C.TextSub,TextSize=12,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=7,Parent=row})
            local sw=new("TextButton",{Size=UDim2.new(0,34,0,20),Position=UDim2.new(1,-38,.5,-10),BackgroundColor3=col,Text="",AutoButtonColor=false,ZIndex=7,Parent=row}); cor(sw,R_OUTER); str(sw,Color3.fromRGB(55,55,55),1)
            local open=false
            sw.MouseButton1Click:Connect(function()
                open=not open
                if open then openOV(function(ov) buildCP(ov,sw,h,s,v,function(newCol,nh,ns,nv) col=newCol;h,s,v=nh,ns,nv; sw.BackgroundColor3=newCol; pcall(cb,newCol); if flag then _G[flag]=newCol end end) end)
                else closeOV() end
            end)
            if flag then _G[flag]=col end
            local r={Value=col}; function r:Set(c2) col=c2;h,s,v=Color3.toHSV(c2);sw.BackgroundColor3=c2 end; function r:Get() return col end; return r
        end

        -- ── AddKeybind ────────────────────────────────────────
        function CAT:AddKeybind(o5)
            o5=o5 or {}; local nm=o5.Name or "Keybind"; local key=o5.Default or Enum.KeyCode.Unknown
            local flag=o5.Flag; local cb=o5.Callback or function() end; local listening=false
            local row=mkRow(30)
            new("TextLabel",{Text=nm,Size=UDim2.new(1,-88,1,0),Position=UDim2.new(0,8,0,0),BackgroundTransparency=1,TextColor3=C.TextSub,TextSize=12,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=7,Parent=row})
            local kb=new("TextButton",{Size=UDim2.new(0,74,0,17),Position=UDim2.new(1,-78,.5,-8.5),BackgroundColor3=C.Input,Text=key.Name,TextColor3=AC,TextSize=9,Font=Enum.Font.GothamBold,AutoButtonColor=false,ZIndex=7,Parent=row}); cor(kb,R_OUTER); str(kb,Color3.fromRGB(48,48,48),1)
            onAC(function(c) if not listening then kb.TextColor3=c end end)
            kb.MouseButton1Click:Connect(function() if listening then return end; listening=true;kb.Text="...";kb.TextColor3=Color3.fromRGB(255,185,0);kb.BackgroundColor3=Color3.fromRGB(30,26,12) end)
            UIS.InputBegan:Connect(function(i,gpe)
                if listening and not gpe and i.UserInputType==Enum.UserInputType.Keyboard then
                    key=i.KeyCode;kb.Text=key.Name;kb.TextColor3=AC;kb.BackgroundColor3=C.Input;listening=false
                elseif not listening and not gpe and i.KeyCode==key and key~=Enum.KeyCode.Unknown then
                    pcall(cb); if flag then _G[flag]=key end
                end
            end)
            if flag then _G[flag]=key end
            local r={Value=key}; function r:Set(k) key=k;kb.Text=k.Name end; function r:Get() return key end; return r
        end

        -- ── AddSeparator ──────────────────────────────────────
        function CAT:AddSeparator()
            local sep=new("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=C.Sep,BackgroundTransparency=0.5,ZIndex=6,Parent=catPanel})
            new("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.08,0),NumberSequenceKeypoint.new(.92,0),NumberSequenceKeypoint.new(1,1)}),Parent=sep})
        end

        -- ── AddProgressBar ────────────────────────────────────
        function CAT:AddProgressBar(o5)
            o5=o5 or {}; local nm=o5.Name or "Progress"; local mx2=o5.Max or 100; local cur=math.clamp(o5.Default or 0,0,mx2)
            local wrap=new("Frame",{Size=UDim2.new(1,0,0,38),BackgroundColor3=C.RowBg,BackgroundTransparency=0.48,ZIndex=6,Parent=catPanel}); cor(wrap,R_OUTER)
            local top=new("Frame",{Size=UDim2.new(1,-8,0,17),Position=UDim2.new(0,4,0,4),BackgroundTransparency=1,ZIndex=7,Parent=wrap})
            new("TextLabel",{Text=nm,Size=UDim2.new(1,-48,1,0),BackgroundTransparency=1,TextColor3=C.TextSub,TextSize=12,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=8,Parent=top})
            local pl=new("TextLabel",{Text=math.round(cur/mx2*100).."%",Size=UDim2.new(0,42,1,0),Position=UDim2.new(1,-44,0,0),BackgroundTransparency=1,TextColor3=AC,TextSize=11,Font=Enum.Font.GothamBold,ZIndex=8,Parent=top})
            onAC(function(c) pl.TextColor3=c end)
            local tr2=new("Frame",{Size=UDim2.new(1,-8,0,4),Position=UDim2.new(0,4,0,26),BackgroundColor3=C.SliderBg,ZIndex=7,Parent=wrap})
            -- flat track, no corner = blocky
            local fl2=new("Frame",{Size=UDim2.new(cur/mx2,0,1,0),BackgroundColor3=AC,ZIndex=8,Parent=tr2}); onAC(function(c) fl2.BackgroundColor3=c end)
            local r={Value=cur}
            function r:Set(v) v=math.clamp(v,0,mx2);cur=v;tw(fl2,{Size=UDim2.new(v/mx2,0,1,0)},.22);pl.Text=math.round(v/mx2*100).."%" end
            function r:Get() return cur end; return r
        end

        return CAT
    end

    -- Window-level API
    function WO:SetAccent(c) AC=c; fireAC() end
    function WO:Toggle() _vis=not _vis; BG.Visible=_vis; BAR.Visible=_vis; if not _vis then SW.Visible=false end end
    function WO:Destroy() SG:Destroy() end
    function WO:SetBackground(id) BG_IMG.Image=id; SW_IMG.Image=id end

    return WO
end

return Peleccos
