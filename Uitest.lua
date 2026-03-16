--[[
╔══════════════════════════════════════════════════════════════════╗
║               PELECCOS SOFTWARES  v11.0                          ║
╠══════════════════════════════════════════════════════════════════╣
║  LAYOUT:                                                         ║
║    SIDEBAR (left): Categories + Tabs with icon                  ║
║    CONTENT (right): SubTabs on top + Sections below             ║
║                                                                  ║
║  Win:AddCategory("Name")          → text separator              ║
║  Win:AddTab({ Name, Icon })       → sidebar button              ║
║  Tab:AddSubTab({ Name })          → button on top of content    ║
║  SubTab:AddSection({ Name, Side})                               ║
║  Sec:AddToggle / AddSlider / AddButton / AddTextbox /           ║
║      AddDropdown / AddColorPicker / AddKeybind /                ║
║      AddLabel / AddSeparator / AddProgressBar                   ║
╚══════════════════════════════════════════════════════════════════╝
]]

local _FOLDER = "PeleccosSoftwares"
local _ERROR_FILE = _FOLDER .. "/errors.txt"

pcall(function()
    if not isfolder(_FOLDER) then makefolder(_FOLDER) end
end)

local function logError(err)
    pcall(function()
        local existing = ""
        if isfile(_ERROR_FILE) then existing = readfile(_ERROR_FILE) end
        local line = os.date("[%d/%m/%Y %H:%M:%S] ") .. tostring(err) .. "\n"
        writefile(_ERROR_FILE, existing .. line)
    end)
end

local _IMG_FOLDER = _FOLDER .. "/images"
pcall(function()
    if not isfolder(_IMG_FOLDER) then makefolder(_IMG_FOLDER) end
end)

local function loadImage(assetId, imageLabel)
    pcall(function()
        if not imageLabel or not imageLabel.Parent then return end
        local filename = _IMG_FOLDER .. "/" .. tostring(assetId):gsub("[^%w]", "_") .. ".png"
        if typeof(getcustomasset) == "function" then
            if not isfile(filename) then
                local ok, data = pcall(function()
                    return game:HttpGet("https://assetdelivery.roblox.com/v1/asset/?id=" .. tostring(assetId):match("%d+") or tostring(assetId))
                end)
                if ok and data and #data > 0 then
                    pcall(function() writefile(filename, data) end)
                end
            end
            if isfile(filename) then
                local ok, asset = pcall(getcustomasset, filename)
                if ok and asset then
                    imageLabel.Image = asset
                    return
                end
            end
        end
        imageLabel.Image = "rbxassetid://" .. tostring(assetId):match("%d+") or tostring(assetId)
    end)
end

local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")
local CoreGui      = game:GetService("CoreGui")
local LP           = Players.LocalPlayer

local C = {
    Sidebar  = Color3.fromRGB(22, 22, 22),
    Content  = Color3.fromRGB(20, 20, 20),
    SubBar   = Color3.fromRGB(18, 18, 18),
    Gbox     = Color3.fromRGB(26, 26, 26),
    BtnOff   = Color3.fromRGB(20, 20, 20),
    BtnHover = Color3.fromRGB(36, 36, 36),
    TxtOff   = Color3.fromRGB(58, 58, 58),
    TxtOn    = Color3.fromRGB(255, 255, 255),
    TxtSub   = Color3.fromRGB(170, 170, 182),
    TxtMuted = Color3.fromRGB(80, 80, 92),
    Border   = Color3.fromRGB(40, 40, 40),
    Input    = Color3.fromRGB(16, 16, 16),
    TrackOff = Color3.fromRGB(38, 38, 38),
    SliderBg = Color3.fromRGB(32, 32, 32),
    CatText  = Color3.fromRGB(100, 100, 115),
}

local _FONT = Enum.Font.Gotham
local _FONTBOLD = Enum.Font.GothamBold
local _FONTSEMI = Enum.Font.GothamSemibold
local _fontReg = {}
local function regFont(obj, kind) table.insert(_fontReg, {obj=obj, kind=kind or "body"}) end
local function applyFont()
    for _, e in ipairs(_fontReg) do
        if e.obj and e.obj.Parent then
            if e.kind=="bold" then e.obj.Font=_FONTBOLD
            elseif e.kind=="semi" then e.obj.Font=_FONTSEMI
            else e.obj.Font=_FONT end
        end
    end
end
local function setFont(f)
    _FONT=f
    local boldMap = {
        [Enum.Font.Gotham]          = {Enum.Font.GothamBold,       Enum.Font.GothamSemibold},
        [Enum.Font.Arial]           = {Enum.Font.ArialBold,         Enum.Font.Arial},
        [Enum.Font.SourceSans]      = {Enum.Font.SourceSansBold,    Enum.Font.SourceSansSemibold},
        [Enum.Font.Ubuntu]          = {Enum.Font.Ubuntu,            Enum.Font.Ubuntu},
        [Enum.Font.RobotoMono]      = {Enum.Font.RobotoMono,        Enum.Font.RobotoMono},
        [Enum.Font.Nunito]          = {Enum.Font.Nunito,            Enum.Font.Nunito},
        [Enum.Font.Oswald]          = {Enum.Font.Oswald,            Enum.Font.Oswald},
        [Enum.Font.FredokaOne]      = {Enum.Font.FredokaOne,        Enum.Font.FredokaOne},
        [Enum.Font.Creepster]       = {Enum.Font.Creepster,         Enum.Font.Creepster},
        [Enum.Font.PermanentMarker] = {Enum.Font.PermanentMarker,   Enum.Font.PermanentMarker},
        [Enum.Font.Bangers]         = {Enum.Font.Bangers,           Enum.Font.Bangers},
        [Enum.Font.Sarpanch]        = {Enum.Font.Sarpanch,          Enum.Font.Sarpanch},
        [Enum.Font.SpecialElite]    = {Enum.Font.SpecialElite,      Enum.Font.SpecialElite},
        [Enum.Font.SciFi]           = {Enum.Font.SciFi,             Enum.Font.SciFi},
        [Enum.Font.Code]            = {Enum.Font.Code,              Enum.Font.Code},
        [Enum.Font.Highway]         = {Enum.Font.Highway,           Enum.Font.Highway},
        [Enum.Font.Cartoon]         = {Enum.Font.Cartoon,           Enum.Font.Cartoon},
        [Enum.Font.Arcade]          = {Enum.Font.Arcade,            Enum.Font.Arcade},
        [Enum.Font.Fantasy]         = {Enum.Font.Fantasy,           Enum.Font.Fantasy},
        [Enum.Font.Antique]         = {Enum.Font.Antique,           Enum.Font.Antique},
    }
    local v = boldMap[f]
    if v then _FONTBOLD=v[1]; _FONTSEMI=v[2] else _FONTBOLD=f; _FONTSEMI=f end
    applyFont()
end

local _contrastReg = {}
local _contrastOn = false
local function regContrast(obj, role) table.insert(_contrastReg, {obj=obj, role=role or "sub"}) end
local function applyContrast(accent)
    local h,s,v = Color3.toHSV(accent)
    local isLight = (v > 0.65 and s < 0.6) or v > 0.88
    local onColor = isLight and Color3.fromRGB(20,20,20) or Color3.fromRGB(255,255,255)
    for _, e in ipairs(_contrastReg) do
        if e.obj and e.obj.Parent then
            if e.role=="on" then
                e.obj.TextColor3 = onColor
            elseif e.role=="stbtn" then
                if e.getActive and e.getActive() then
                    e.obj.TextColor3 = onColor
                else
                    e.obj.TextColor3 = Color3.fromRGB(170,170,182)
                end
            elseif e.role=="tablbl" then
                if e.getActive and e.getActive() then
                    e.obj.TextColor3 = onColor
                else
                    e.obj.TextColor3 = Color3.fromRGB(58,58,58)
                end
            end
        end
    end
end

local function tw(o,p,t,s,d) TweenService:Create(o,TweenInfo.new(t or .15,s or Enum.EasingStyle.Quart,d or Enum.EasingDirection.Out),p):Play() end
local function twSp(o,p,t) tw(o,p,t or .22,Enum.EasingStyle.Back,Enum.EasingDirection.Out) end

local function new(cls, props)
    local o = Instance.new(cls)
    for k,v in pairs(props or {}) do if k~="Parent" then o[k]=v end end
    if props and props.Parent then o.Parent=props.Parent end
    return o
end
local function newTxt(props, fontKind, contrastRole)
    local o = new("TextLabel", props)
    if fontKind then regFont(o, fontKind) end
    if contrastRole then regContrast(o, contrastRole) end
    return o
end

local function cor(p,r) local c=Instance.new("UICorner");c.CornerRadius=r or UDim.new(0,8);c.Parent=p;return c end
local function str(p,col,t) local s=Instance.new("UIStroke");s.Color=col or C.Border;s.Thickness=t or 1;s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;s.Parent=p;return s end
local function pad(p,t,r,b,l) local u=Instance.new("UIPadding");u.PaddingTop=UDim.new(0,t or 0);u.PaddingRight=UDim.new(0,r or 0);u.PaddingBottom=UDim.new(0,b or 0);u.PaddingLeft=UDim.new(0,l or 0);u.Parent=p;return u end
local function lst(p,dir,gap,ha,va) local l=Instance.new("UIListLayout");l.FillDirection=dir or Enum.FillDirection.Vertical;l.Padding=UDim.new(0,gap or 0);l.HorizontalAlignment=ha or Enum.HorizontalAlignment.Left;l.VerticalAlignment=va or Enum.VerticalAlignment.Top;l.SortOrder=Enum.SortOrder.LayoutOrder;l.Parent=p;return l end
local function autoY(s) local ll=s:FindFirstChildOfClass("UIListLayout");if not ll then return end;local function u() task.defer(function() if s and s.Parent then s.CanvasSize=UDim2.new(0,0,0,ll.AbsoluteContentSize.Y+8) end end) end;ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(u);u() end
local function dk(c,f) local h,s,v=Color3.toHSV(c);return Color3.fromHSV(h,s,math.clamp(v*f,0,1)) end

local function drag(frame,handle)
    local d,ds,sp=false,nil,nil; handle=handle or frame
    handle.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then d=true;ds=i.Position;sp=frame.Position end end)
    UIS.InputChanged:Connect(function(i) if d and i.UserInputType==Enum.UserInputType.MouseMovement then local dv=i.Position-ds;frame.Position=UDim2.new(sp.X.Scale,sp.X.Offset+dv.X,sp.Y.Scale,sp.Y.Offset+dv.Y) end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then d=false end end)
end

local EvBus={_cbs={}}
function EvBus:Fire(d) for _,f in pairs(self._cbs) do pcall(f,d) end end
function EvBus:Connect(f) table.insert(self._cbs,f);return{Disconnect=function() for i,v in pairs(self._cbs) do if v==f then table.remove(self._cbs,i);break end end end} end

local _OVR,_OVA=nil,nil
local function closeOV() if _OVA then _OVA:Destroy();_OVA=nil end end
local function openOV(fn)
    closeOV()
    local f=new("Frame",{Name="OvF",Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,ZIndex=200,Parent=_OVR})
    local bg=new("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=200,Parent=f})
    local canClose = false
    task.delay(0.2, function() canClose = true end)
    bg.MouseButton1Click:Connect(function() if canClose then closeOV() end end)
    _OVA=f; fn(f)
end

local _NH
local NC={Success=Color3.fromRGB(50,200,100),Warning=Color3.fromRGB(255,185,0),Error=Color3.fromRGB(255,65,65),Info=Color3.fromRGB(0,135,255)}
local function initN(sg)
    _NH=new("Frame",{Name="Notifs",Size=UDim2.new(0,300,1,0),Position=UDim2.new(1,-310,0,0),BackgroundTransparency=1,ZIndex=300,Parent=sg})
    lst(_NH,Enum.FillDirection.Vertical,10); pad(_NH,16,0,16,0)
end
local function notify(o)
    if not _NH then return end; o=o or {}
    local ac=NC[o.Type or "Info"] or NC.Info; local desc=o.Desc or o.Description or ""
    local card=new("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=Color3.fromRGB(24,24,24),BackgroundTransparency=1,Position=UDim2.new(1.3,0,0,0),ZIndex=301,Parent=_NH})
    cor(card,UDim.new(0,12)); str(card,Color3.fromRGB(48,48,48))
    local bar=new("Frame",{Size=UDim2.new(0,4,1,0),BackgroundColor3=ac,BorderSizePixel=0,ZIndex=302,Parent=card}); cor(bar,UDim.new(0,4))
    local inn=new("Frame",{Size=UDim2.new(1,-4,1,0),Position=UDim2.new(0,4,0,0),BackgroundTransparency=1,ZIndex=302,Parent=card}); pad(inn,10,10,10,10); lst(inn,Enum.FillDirection.Vertical,5)
    local row=new("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,ZIndex=303,Parent=inn}); lst(row,Enum.FillDirection.Horizontal,6,Enum.HorizontalAlignment.Left,Enum.VerticalAlignment.Center)
    local icons={Success="✓",Warning="⚠",Error="✕",Info="i"}
    local ico=new("TextLabel",{Text=icons[o.Type or "Info"] or "i",Size=UDim2.new(0,18,0,18),BackgroundColor3=ac,TextColor3=Color3.fromRGB(255,255,255),TextSize=11,Font=_FONTBOLD,ZIndex=303,Parent=row}); cor(ico,UDim.new(0,9))
    new("TextLabel",{Text=o.Title or "Notification",Size=UDim2.new(1,-24,0,18),BackgroundTransparency=1,TextColor3=C.TxtOn,TextSize=13,Font=_FONTBOLD,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=303,Parent=row})
    if desc~="" then new("TextLabel",{Text=desc,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,TextColor3=Color3.fromRGB(145,145,158),TextSize=11,Font=_FONT,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,ZIndex=303,Parent=inn}) end
    local pt=new("Frame",{Size=UDim2.new(1,0,0,2),BackgroundColor3=Color3.fromRGB(38,38,38),ZIndex=303,Parent=inn}); cor(pt,UDim.new(0,2))
    local pf=new("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=ac,ZIndex=304,Parent=pt}); cor(pf,UDim.new(0,2))
    tw(card,{BackgroundTransparency=0,Position=UDim2.new(0,0,0,0)},.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
    local dur=o.Duration or 4; tw(pf,{Size=UDim2.new(0,0,1,0)},dur,Enum.EasingStyle.Linear)
    task.delay(dur,function() tw(card,{BackgroundTransparency=1,Position=UDim2.new(1.3,0,0,0)},.22); task.wait(.25); card:Destroy() end)
end

local Peleccos={}; Peleccos.__index=Peleccos
Peleccos.Events=EvBus

-- Track LayoutOrder for sidebar items so Config always gets 9999
local _sideLayoutOrder = 0

function Peleccos:CreateWindow(o)
    o=o or {}
    pcall(function() local x=game:GetService("CoreGui"):FindFirstChild("PeleccosUI"); if x then x:Destroy() end end)
    pcall(function() local pg=LP:FindFirstChild("PlayerGui"); if pg then local x=pg:FindFirstChild("PeleccosUI"); if x then x:Destroy() end end end)
    pcall(function() if typeof(gethui)=="function" then local x=gethui():FindFirstChild("PeleccosUI"); if x then x:Destroy() end end end)
    logError("PeleccosSoftwares UI loaded - " .. os.date())

    local AC  = o.AccentColor or Color3.fromRGB(80,80,92)
    local ACD = dk(AC,.72)
    local _acCBs={}
    local function onAC(fn) table.insert(_acCBs,fn) end
    local function applyAC() ACD=dk(AC,.72); for _,fn in pairs(_acCBs) do pcall(fn,AC) end; if _contrastOn then applyContrast(AC) end end

    local W,H  = o.Width or 780, o.Height or 500
    local SW   = 200
    local TH   = 44
    local STH  = 36
    local UCH  = 58
    local KEY  = o.Key or Enum.KeyCode.Insert

    if o.Font then setFont(o.Font) end

    local SG=new("ScreenGui",{Name="PeleccosUI",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
    local _parentGui = (typeof(gethui)=="function" and gethui()) or (pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui")) or LP:WaitForChild("PlayerGui")
    SG.Parent = _parentGui
    _OVR=new("Frame",{Name="OvRoot",Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,ZIndex=200,Parent=SG})
    initN(SG)

    local WIN=new("Frame",{Name="Win",Size=UDim2.new(0,W,0,H),Position=UDim2.new(.5,-W/2,.5,-H/2),BackgroundColor3=C.Content,BorderSizePixel=0,ClipsDescendants=true,ZIndex=1,Parent=SG})
    cor(WIN,UDim.new(0,10)); str(WIN,C.Border)
    new("ImageLabel",{Size=UDim2.new(1,90,1,90),Position=UDim2.new(0,-45,0,-45),BackgroundTransparency=1,Image="rbxassetid://6014261993",ImageColor3=Color3.fromRGB(0,0,0),ImageTransparency=.55,ScaleType=Enum.ScaleType.Slice,SliceCenter=Rect.new(49,49,450,450),ZIndex=0,Parent=WIN})

    local TOPBAR=new("Frame",{Name="TopBar",Size=UDim2.new(1,0,0,TH),BackgroundColor3=C.Sidebar,BorderSizePixel=0,ZIndex=10,Parent=WIN})
    cor(TOPBAR,UDim.new(0,10))
    new("Frame",{Size=UDim2.new(1,0,.5,0),Position=UDim2.new(0,0,.5,0),BackgroundColor3=C.Sidebar,BorderSizePixel=0,ZIndex=9,Parent=TOPBAR})
    new("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BackgroundColor3=C.Border,BorderSizePixel=0,ZIndex=11,Parent=TOPBAR})

    local LB=new("Frame",{Size=UDim2.new(0,SW,1,0),BackgroundTransparency=1,ZIndex=12,Parent=TOPBAR})
    local LI=new("ImageLabel",{Size=UDim2.new(0,28,0,28),Position=UDim2.new(0,10,.5,-14),BackgroundColor3=C.BtnHover,Image=o.Logo or "rbxassetid://0",ZIndex=13,Parent=LB}); cor(LI,UDim.new(0,7))
    new("TextLabel",{Text=o.Title or "Peleccos",Size=UDim2.new(1,-46,1,0),Position=UDim2.new(0,44,0,0),BackgroundTransparency=1,TextColor3=C.TxtOn,TextSize=15,Font=_FONTBOLD,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=13,Parent=LB})

    local SF=new("Frame",{Size=UDim2.new(0,120,0,28),Position=UDim2.new(1,-126,.5,-14),BackgroundColor3=C.BtnOff,ZIndex=12,Parent=TOPBAR}); cor(SF,UDim.new(0,8)); str(SF,C.Border)
    new("TextLabel",{Text="",Size=UDim2.new(0,18,1,0),Position=UDim2.new(0,6,0,0),BackgroundTransparency=1,TextColor3=C.TxtOff,TextSize=11,Font=_FONT,ZIndex=13,Parent=SF})
    local SBX=new("TextBox",{Text="",PlaceholderText="Search",Size=UDim2.new(1,-26,1,0),Position=UDim2.new(0,22,0,0),BackgroundTransparency=1,TextColor3=C.TxtOn,PlaceholderColor3=C.TxtOff,TextSize=11,Font=_FONT,TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false,ZIndex=13,Parent=SF})
    SBX.Focused:Connect(function() tw(SF,{BackgroundColor3=C.BtnHover},.12) end)
    SBX.FocusLost:Connect(function() tw(SF,{BackgroundColor3=C.BtnOff},.12) end)

    local SIDE=new("Frame",{
        Name="Sidebar",
        Size=UDim2.new(0,SW,1,-(TH+1)),
        Position=UDim2.new(0,0,0,TH+1),
        BackgroundColor3=C.Sidebar,
        BorderSizePixel=0,
        ClipsDescendants=true,
        ZIndex=8,
        Parent=WIN,
    })
    lst(SIDE,Enum.FillDirection.Vertical,0)
    pad(SIDE,6,0,UCH+8,0)

    if o.User then
        local U=o.User
        local UC=new("Frame",{Name="UserCard",Size=UDim2.new(0,SW,0,UCH),Position=UDim2.new(0,0,1,-UCH),BackgroundColor3=Color3.fromRGB(18,18,18),ZIndex=12,Parent=WIN})
        new("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=C.Border,BorderSizePixel=0,ZIndex=13,Parent=UC})
        local av=new("ImageLabel",{Size=UDim2.new(0,36,0,36),Position=UDim2.new(0,10,.5,-18),BackgroundColor3=C.BtnHover,Image=U.Avatar or "rbxassetid://0",ZIndex=13,Parent=UC}); cor(av,UDim.new(0,8))
        new("TextLabel",{Text=U.Name or "User",Size=UDim2.new(1,-58,0,18),Position=UDim2.new(0,54,0,9),BackgroundTransparency=1,TextColor3=C.TxtOn,TextSize=13,Font=_FONTBOLD,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=13,Parent=UC})
        local expLbl=new("TextLabel",{Text="Expires: "..(U.Expiry or "Never"),Size=UDim2.new(1,-58,0,14),Position=UDim2.new(0,54,0,29),BackgroundTransparency=1,TextColor3=AC,TextSize=10,Font=_FONT,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=13,Parent=UC})
        onAC(function(c) expLbl.TextColor3=c end)
    end

    new("Frame",{Size=UDim2.new(0,1,1,-(TH+1)),Position=UDim2.new(0,SW,0,TH+1),BackgroundColor3=C.Border,BorderSizePixel=0,ZIndex=10,Parent=WIN})

    local CONT=new("Frame",{
        Name="Content",
        Size=UDim2.new(1,-(SW+1),1,-(TH+1)),
        Position=UDim2.new(0,SW+1,0,TH+1),
        BackgroundColor3=C.Content,
        ClipsDescendants=true,
        ZIndex=5,
        Parent=WIN,
    })

    drag(WIN,TOPBAR)

    local _els={}
    SBX:GetPropertyChangedSignal("Text"):Connect(function()
        local q=SBX.Text:lower()
        for _,e in pairs(_els) do e.frame.Visible=q=="" or e.label:lower():find(q,1,true)~=nil end
    end)

    local WO={_tabs={},_activeTab=nil,Notify=notify,Events=Peleccos.Events}
    local _toggleRegistry={}
    -- Track current LayoutOrder for sidebar so Config always gets pushed to 9999
    local _sideOrder = 0

    local _vis=true
    local _keyIgnoreOnce=false
    UIS.InputBegan:Connect(function(i,gpe)
        if not gpe and i.KeyCode==KEY then
            if _keyIgnoreOnce then _keyIgnoreOnce=false; return end
            _vis=not _vis; WIN.Visible=_vis
        end
    end)

    function WO:AddCategory(name)
        _sideOrder = _sideOrder + 1
        local cf=new("Frame",{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,LayoutOrder=_sideOrder,ZIndex=9,Parent=SIDE})
        local line=new("Frame",{Size=UDim2.new(0,2,1,-10),Position=UDim2.new(0,10,.5,-( (28-10)/2 )),BackgroundColor3=AC,ZIndex=10,Parent=cf})
        cor(line,UDim.new(0,2))
        onAC(function(c) line.BackgroundColor3=c end)
        local catLbl=new("TextLabel",{
            Text=(name or ""):upper(),
            Size=UDim2.new(1,-20,1,0),Position=UDim2.new(0,18,0,0),
            BackgroundTransparency=1,TextColor3=C.CatText,
            TextSize=9,Font=_FONTBOLD,
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=10,Parent=cf,
        })
        regFont(catLbl,"bold")
    end

    function WO:AddTab(o2)
        o2=o2 or {}
        local tname=o2.Name or "Tab"
        local first=#self._tabs==0

        _sideOrder = _sideOrder + 1
        local sbtn=new("TextButton",{
            Size=UDim2.new(1,-8,0,34),
            BackgroundColor3=first and AC or C.BtnOff,
            BackgroundTransparency=first and 0 or 1,
            Text="",AutoButtonColor=false,
            LayoutOrder=_sideOrder,
            ZIndex=9,Parent=SIDE,
        })
        cor(sbtn,UDim.new(0,7))
        local abar=new("Frame",{
            Size=UDim2.new(0,3,.55,0),
            Position=UDim2.new(0,0,.225,0),
            BackgroundColor3=AC,
            Visible=first,
            ZIndex=11,Parent=sbtn,
        }); cor(abar,UDim.new(0,2))
        onAC(function(c) abar.BackgroundColor3=c end)

        local _hasIcon = o2.Icon and o2.Icon ~= "" and o2.Icon ~= "rbxassetid://0"
        local ibox=new("Frame",{
            Size=UDim2.new(0,22,0,22),
            Position=UDim2.new(0,10,.5,-11),
            BackgroundColor3=first and AC or Color3.fromRGB(34,34,34),
            BackgroundTransparency=_hasIcon and 0 or 1,
            ZIndex=10,Parent=sbtn,
        }); cor(ibox,UDim.new(0,6))
        local iimg=new("ImageLabel",{
            Size=UDim2.new(0,13,0,13),
            Position=UDim2.new(.5,-6.5,.5,-6.5),
            BackgroundTransparency=1,
            Image=o2.Icon or "",
            ImageColor3=C.TxtOn,
            Visible=_hasIcon,
            ZIndex=11,Parent=ibox,
        })
        local _lblX = _hasIcon and 36 or 14
        local slbl=new("TextLabel",{
            Text=tname,
            Size=UDim2.new(1,-40,1,0),
            Position=UDim2.new(0,_lblX,0,0),
            BackgroundTransparency=1,
            TextColor3=first and C.TxtOn or C.TxtOff,
            TextSize=12,Font=_FONT,
            TextXAlignment=Enum.TextXAlignment.Left,
            ZIndex=10,Parent=sbtn,
        })
        regFont(slbl,"body")
        table.insert(_contrastReg, {obj=slbl, role="tablbl", getActive=function() return self._activeTab==TAB end})

        local tabPage=new("Frame",{
            Size=UDim2.new(1,0,1,0),
            BackgroundTransparency=1,
            Visible=first,
            ZIndex=5,Parent=CONT,
        })

        local STBAR=new("Frame",{
            Name="SubTabBar",
            Size=UDim2.new(1,0,0,STH),
            Position=UDim2.new(0,0,0,0),
            BackgroundColor3=Color3.fromRGB(24,24,26),
            BorderSizePixel=0,
            ZIndex=20,
            ClipsDescendants=true,
            Parent=tabPage,
        })
        local stbarLine=new("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BackgroundColor3=AC,BorderSizePixel=0,ZIndex=21,Parent=STBAR})
        onAC(function(c) stbarLine.BackgroundColor3=c end)
        local STINNER=new("Frame",{
            Size=UDim2.new(1,-16,0,26),
            Position=UDim2.new(0,8,0.5,-13),
            BackgroundTransparency=1,
            ZIndex=20,
            ClipsDescendants=false,
            Parent=STBAR,
        })
        local stbarList=lst(STINNER,Enum.FillDirection.Horizontal,4)

        local STPAGES=new("Frame",{
            Name="SubPages",
            Size=UDim2.new(1,0,1,-STH),
            Position=UDim2.new(0,0,0,STH),
            BackgroundTransparency=1,
            ClipsDescendants=true,
            ZIndex=5,Parent=tabPage,
        })

        local TAB={
            _name=tname,_sbtn=sbtn,_slbl=slbl,_abar=abar,_ibox=ibox,_hasIcon=_hasIcon,
            _page=tabPage,_stbar=STINNER,_stpages=STPAGES,
            _subtabs={},_activeSub=nil,_win=self,
        }
        table.insert(self._tabs,TAB)
        if first then self._activeTab=TAB end

        onAC(function(c) if self._activeTab==TAB then sbtn.BackgroundColor3=c end end)
        onAC(function(c) if self._activeTab==TAB then ibox.BackgroundColor3=c end end)

        local function activateTab()
            if self._activeTab==TAB then return end
            local old=self._activeTab
            if old then
                old._page.Visible=false
                old._sbtn.BackgroundTransparency=1
                old._slbl.TextColor3=C.TxtOff
                old._abar.Visible=false
                old._ibox.BackgroundColor3=Color3.fromRGB(34,34,34)
                if not old._hasIcon then old._ibox.BackgroundTransparency=1 end
            end
            tabPage.Visible=true
            sbtn.BackgroundColor3=AC; sbtn.BackgroundTransparency=0
            slbl.TextColor3=C.TxtOn; abar.Visible=true
            if _hasIcon then ibox.BackgroundColor3=AC; ibox.BackgroundTransparency=0 end
            self._activeTab=TAB
            if _contrastOn then applyContrast(AC) end
        end

        sbtn.MouseButton1Click:Connect(activateTab)
        sbtn.MouseEnter:Connect(function()
            if self._activeTab~=TAB then
                sbtn.BackgroundTransparency=0
                tw(sbtn,{BackgroundColor3=Color3.fromRGB(32,32,32)},.1)
                tw(slbl,{TextColor3=C.TxtSub},.1)
            end
        end)
        sbtn.MouseLeave:Connect(function()
            if self._activeTab~=TAB then
                tw(sbtn,{BackgroundColor3=C.BtnOff},.1)
                sbtn.BackgroundTransparency=1
                tw(slbl,{TextColor3=C.TxtOff},.1)
            end
        end)

        function TAB:AddSubTab(o3)
            o3=o3 or {}
            local stname=o3.Name or "SubTab"
            local sfirst=#self._subtabs==0

            local stbtn=new("TextButton",{
                Size=UDim2.new(0,0,0,26),
                AutomaticSize=Enum.AutomaticSize.X,
                BackgroundColor3=sfirst and AC or Color3.fromRGB(38,38,42),
                BackgroundTransparency=sfirst and 0 or 0,
                Text=stname,
                TextColor3=sfirst and C.TxtOn or C.TxtSub,
                TextSize=11,Font=_FONTSEMI,
                AutoButtonColor=false,ZIndex=21,Parent=self._stbar,
            })
            cor(stbtn,UDim.new(0,6)); pad(stbtn,0,14,0,14)
            regFont(stbtn,"semi")
            table.insert(_contrastReg, {obj=stbtn, role="stbtn", getActive=function() return self._activeSub==STAB end})

            local stPage=new("Frame",{
                Size=UDim2.new(1,0,1,0),
                BackgroundTransparency=1,
                Visible=sfirst,
                ZIndex=5,Parent=self._stpages,
            })

            local function mkCol(xs,xo)
                local sc=new("ScrollingFrame",{
                    Size=UDim2.new(.5,-8,1,-6),
                    Position=UDim2.new(xs,xo,0,3),
                    BackgroundTransparency=1,
                    ScrollBarThickness=2,
                    ScrollBarImageColor3=AC,
                    CanvasSize=UDim2.new(0,0,0,0),
                    ZIndex=5,Parent=stPage,
                })
                lst(sc,Enum.FillDirection.Vertical,8); pad(sc,4,4,4,4); autoY(sc)
                onAC(function(c2) sc.ScrollBarImageColor3=c2 end)
                return sc
            end
            local LC=mkCol(0,4); local RC=mkCol(.5,4)

            local STAB={
                _name=stname,_btn=stbtn,_page=stPage,
                _lc=LC,_rc=RC,_tab=self,_cf=true,
            }
            table.insert(self._subtabs,STAB)
            if sfirst then self._activeSub=STAB end

            onAC(function(c) if self._activeSub==STAB then stbtn.BackgroundColor3=c end end)

            local function activateSub()
                if self._activeSub==STAB then return end
                local old=self._activeSub
                if old then
                    old._page.Visible=false
                    old._btn.BackgroundColor3=Color3.fromRGB(38,38,42)
                    old._btn.BackgroundTransparency=0
                    old._btn.TextColor3=C.TxtSub
                end
                stPage.Visible=true
                stbtn.BackgroundColor3=AC; stbtn.BackgroundTransparency=0; stbtn.TextColor3=C.TxtOn
                self._activeSub=STAB
                if _contrastOn then applyContrast(AC) end
            end
            stbtn.MouseButton1Click:Connect(activateSub)
            stbtn.MouseEnter:Connect(function()
                if self._activeSub~=STAB then
                    tw(stbtn,{BackgroundColor3=Color3.fromRGB(50,50,56),TextColor3=C.TxtOn},.08)
                end
            end)
            stbtn.MouseLeave:Connect(function()
                if self._activeSub~=STAB then
                    tw(stbtn,{BackgroundColor3=Color3.fromRGB(38,38,42),TextColor3=C.TxtSub},.08)
                end
            end)

            function STAB:AddSection(o4)
                o4=o4 or {}
                local gname=o4.Name or "Section"
                local side=o4.Side or "auto"
                local col=side=="left" and self._lc or side=="right" and self._rc or (self._cf and self._lc or self._rc)
                if side=="auto" then self._cf=not self._cf end

                local gbox=new("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=C.Gbox,ZIndex=5,Parent=col})
                cor(gbox,UDim.new(0,10)); str(gbox,C.Border)

                local ghdr=new("Frame",{Size=UDim2.new(1,0,0,30),BackgroundColor3=AC,ZIndex=6,Parent=gbox}); cor(ghdr,UDim.new(0,10))
                new("Frame",{Size=UDim2.new(1,0,.5,0),Position=UDim2.new(0,0,.5,0),BackgroundColor3=AC,BorderSizePixel=0,ZIndex=5,Parent=ghdr})
                local secHdrLbl=new("TextLabel",{Text=gname,Size=UDim2.new(1,-12,1,0),Position=UDim2.new(0,12,0,0),BackgroundTransparency=1,TextColor3=C.TxtOn,TextSize=12,Font=_FONTBOLD,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=7,Parent=ghdr})
                regFont(secHdrLbl,"bold"); regContrast(secHdrLbl,"on")
                onAC(function(c) ghdr.BackgroundColor3=c; local p=ghdr:FindFirstChildOfClass("Frame"); if p then p.BackgroundColor3=c end end)

                local items=new("Frame",{Size=UDim2.new(1,0,0,0),Position=UDim2.new(0,0,0,30),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,ZIndex=5,Parent=gbox})
                lst(items,Enum.FillDirection.Vertical,4); pad(items,8,10,10,10)

                local S={_i=items,_allEls=_els,_tn=tname,_stn=stname,_gn=gname}
                local function fire(tp,nm,vl) Peleccos.Events:Fire({Type=tp,Name=nm,Value=vl,Tab=tname,SubTab=stname,Section=gname}) end
                local function toast(op) if op.Toast then notify({Title=op.ToastTitle or op.Name or "Action",Desc=op.ToastDesc or op.ToastDescription or "",Type=op.ToastType or "Info",Duration=op.ToastDuration or 3}) end end

                function S:AddLabel(o5)
                    o5=o5 or {}
                    local l=new("TextLabel",{Text=o5.Text or "",Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,TextColor3=o5.Color or C.TxtMuted,TextSize=o5.Size or 12,Font=_FONT,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,ZIndex=6,Parent=self._i})
                    regFont(l,"body")
                    local r={} function r:Set(t) l.Text=t end function r:Get() return l.Text end return r
                end

                function S:AddButton(o5)
                    o5=o5 or {}; local nm=o5.Name or "Button"; local cb=o5.Callback or function() end
                    local btn=new("TextButton",{Size=UDim2.new(1,0,0,30),BackgroundColor3=C.BtnOff,Text=nm,TextColor3=C.TxtOff,TextSize=12,Font=_FONTSEMI,AutoButtonColor=false,ZIndex=6,Parent=self._i}); cor(btn,UDim.new(0,8)); str(btn,C.Border)
                    regFont(btn,"semi")
                    btn.MouseEnter:Connect(function() tw(btn,{BackgroundColor3=C.BtnHover,TextColor3=C.TxtOn},.1) end)
                    btn.MouseLeave:Connect(function() tw(btn,{BackgroundColor3=C.BtnOff,TextColor3=C.TxtOff},.1) end)
                    btn.MouseButton1Click:Connect(function() btn.BackgroundColor3=AC;btn.TextColor3=C.TxtOn;task.delay(.18,function() tw(btn,{BackgroundColor3=C.BtnHover},.15) end); fire("Button",nm,true);toast(o5);cb() end)
                    table.insert(self._allEls,{label=nm,frame=btn})
                    local r={} function r:SetText(t) btn.Text=t end return r
                end

                function S:AddToggle(o5)
                    o5=o5 or {}
                    local nm=o5.Name or "Toggle"
                    local val=o5.Default or false
                    local cb=o5.Callback or function() end
                    local flag=o5.Flag
                    local hasKB=o5.Keybind~=nil
                    local hasCP=o5.Color~=nil
                    local reservedW = 40 + (hasKB and 56 or 0) + (hasCP and 32 or 0) + 8

                    local row=new("Frame",{Size=UDim2.new(1,0,0,28),BackgroundColor3=C.BtnOff,BackgroundTransparency=1,ZIndex=6,Parent=self._i}); cor(row,UDim.new(0,6))
                    row.MouseEnter:Connect(function() tw(row,{BackgroundColor3=C.BtnHover,BackgroundTransparency=0},.1) end)
                    row.MouseLeave:Connect(function() tw(row,{BackgroundTransparency=1},.1) end)
                    local lbl=new("TextLabel",{Text=nm,Size=UDim2.new(1,-(reservedW+4),1,0),Position=UDim2.new(0,4,0,0),BackgroundTransparency=1,TextColor3=C.TxtSub,TextSize=12,Font=_FONT,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=7,Parent=row})
                    regFont(lbl,"body"); regContrast(lbl,"sub")

                    local track=new("Frame",{Size=UDim2.new(0,36,0,18),Position=UDim2.new(1,-40,.5,-9),BackgroundColor3=val and AC or C.TrackOff,ZIndex=7,Parent=row}); cor(track,UDim.new(0,9))
                    local knob=new("Frame",{Size=UDim2.new(0,14,0,14),Position=val and UDim2.new(1,-16,.5,-7) or UDim2.new(0,2,.5,-7),BackgroundColor3=C.TxtOn,ZIndex=8,Parent=track}); cor(knob,UDim.new(0,7))
                    local trackBtn=new("TextButton",{Size=UDim2.new(0,36,0,18),Position=UDim2.new(1,-40,.5,-9),BackgroundTransparency=1,Text="",AutoButtonColor=false,ZIndex=9,Parent=row})
                    onAC(function(c)
                        if val then
                            track.BackgroundColor3=c
                            local _,_,v2=Color3.toHSV(c)
                            knob.BackgroundColor3 = v2>0.7 and Color3.fromRGB(30,30,30) or Color3.fromRGB(255,255,255)
                        end
                    end)

                    local function set(v,silent)
                        val=v; track.BackgroundColor3=v and AC or C.TrackOff
                        tw(knob,{Position=v and UDim2.new(1,-16,.5,-7) or UDim2.new(0,2,.5,-7)},.15,Enum.EasingStyle.Back)
                        if v then local _,_,bv=Color3.toHSV(AC); knob.BackgroundColor3=bv>0.7 and Color3.fromRGB(30,30,30) or Color3.fromRGB(255,255,255)
                        else knob.BackgroundColor3=Color3.fromRGB(255,255,255) end
                        if not silent then fire("Toggle",nm,v);toast(o5);cb(v) end
                        if flag then _G[flag]=v end
                    end
                    trackBtn.MouseButton1Click:Connect(function() set(not val) end)
                    if flag then _G[flag]=val end
                    if flag then _toggleRegistry[flag]={get=function() return val end, set=function(v) set(v,false) end} end

                    if hasCP then
                        local cpCol=o5.Color or Color3.fromRGB(255,80,80); local cpCb=o5.ColorCallback or function() end
                        local cpX = hasKB and UDim2.new(1,-132,.5,-10) or UDim2.new(1,-76,.5,-10)
                        local sw=new("TextButton",{Size=UDim2.new(0,22,0,18),Position=cpX,BackgroundColor3=cpCol,Text="",AutoButtonColor=false,ZIndex=7,Parent=row}); cor(sw,UDim.new(0,5)); str(sw,C.Border)
                        local open=false; local ch,cs,cv=Color3.toHSV(cpCol)
                        local function buildCP(ov)
                            local ap=sw.AbsolutePosition; local pw,ph=200,130
                            local px=math.min(ap.X,SG.AbsoluteSize.X-pw-8); local py=ap.Y+22; if py+ph>SG.AbsoluteSize.Y-8 then py=ap.Y-ph-4 end
                            local pan=new("TextButton",{AutoButtonColor=false,Text="",Size=UDim2.new(0,pw,0,0),Position=UDim2.new(0,px,0,py),BackgroundColor3=Color3.fromRGB(22,22,22),ZIndex=210,Parent=ov}); cor(pan,UDim.new(0,10)); str(pan,C.Border)
                            tw(pan,{Size=UDim2.new(0,pw,0,ph)},.15,Enum.EasingStyle.Back)
                            local svbg=new("Frame",{Size=UDim2.new(1,-12,0,76),Position=UDim2.new(0,6,0,6),BackgroundColor3=Color3.fromHSV(ch,1,1),ZIndex=211,Parent=pan}); cor(svbg,UDim.new(0,6))
                            local wl=new("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.fromRGB(255,255,255),ZIndex=212,Parent=svbg}); cor(wl,UDim.new(0,6)); new("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)}),Parent=wl})
                            local bl=new("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.fromRGB(0,0,0),ZIndex=213,Parent=svbg}); cor(bl,UDim.new(0,6)); new("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)}),Rotation=90,Parent=bl})
                            local svc=new("Frame",{Size=UDim2.new(0,10,0,10),AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(cs,0,1-cv,0),BackgroundColor3=C.TxtOn,ZIndex=215,Parent=svbg}); cor(svc,UDim.new(0,5)); str(svc,Color3.fromRGB(0,0,0),1.5)
                            local hb=new("Frame",{Size=UDim2.new(1,-12,0,10),Position=UDim2.new(0,6,0,88),ZIndex=211,Parent=pan}); cor(hb,UDim.new(0,5))
                            new("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,0,0)),ColorSequenceKeypoint.new(.17,Color3.fromRGB(255,255,0)),ColorSequenceKeypoint.new(.33,Color3.fromRGB(0,255,0)),ColorSequenceKeypoint.new(.5,Color3.fromRGB(0,255,255)),ColorSequenceKeypoint.new(.67,Color3.fromRGB(0,0,255)),ColorSequenceKeypoint.new(.83,Color3.fromRGB(255,0,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(255,0,0))}),Parent=hb})
                            local hc=new("Frame",{Size=UDim2.new(0,3,1,4),AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(ch,0,.5,0),BackgroundColor3=C.TxtOn,ZIndex=213,Parent=hb}); cor(hc,UDim.new(0,2))
                            local pv=new("Frame",{Size=UDim2.new(1,-12,0,12),Position=UDim2.new(0,6,0,104),BackgroundColor3=cpCol,ZIndex=211,Parent=pan}); cor(pv,UDim.new(0,5))
                            local function upd() cpCol=Color3.fromHSV(ch,cs,cv); sw.BackgroundColor3=cpCol; svbg.BackgroundColor3=Color3.fromHSV(ch,1,1); svc.Position=UDim2.new(cs,0,1-cv,0); hc.Position=UDim2.new(ch,0,.5,0); pv.BackgroundColor3=cpCol; cpCb(cpCol) end
                            local svd,hud=false,false
                            svbg.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then svd=true;cs=math.clamp((i.Position.X-svbg.AbsolutePosition.X)/svbg.AbsoluteSize.X,0,1);cv=1-math.clamp((i.Position.Y-svbg.AbsolutePosition.Y)/svbg.AbsoluteSize.Y,0,1);upd() end end)
                            hb.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then hud=true;ch=math.clamp((i.Position.X-hb.AbsolutePosition.X)/hb.AbsoluteSize.X,0,1);upd() end end)
                            UIS.InputChanged:Connect(function(i) if i.UserInputType~=Enum.UserInputType.MouseMovement then return end; if svd then cs=math.clamp((i.Position.X-svbg.AbsolutePosition.X)/svbg.AbsoluteSize.X,0,1);cv=1-math.clamp((i.Position.Y-svbg.AbsolutePosition.Y)/svbg.AbsoluteSize.Y,0,1);upd() end; if hud then ch=math.clamp((i.Position.X-hb.AbsolutePosition.X)/hb.AbsoluteSize.X,0,1);upd() end end)
                            UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then svd=false;hud=false end end)
                        end
                        sw.MouseButton1Click:Connect(function() open=not open; if open then openOV(buildCP) else closeOV() end end)
                    end

                    if hasKB then
                        local key=o5.Keybind or Enum.KeyCode.Unknown; local listening=false
                        local kb=new("TextButton",{Size=UDim2.new(0,48,0,18),Position=UDim2.new(1,-92,.5,-9),BackgroundColor3=C.Input,Text=key.Name,TextColor3=AC,TextSize=9,Font=_FONTBOLD,AutoButtonColor=false,ZIndex=7,Parent=row}); cor(kb,UDim.new(0,5)); str(kb,C.Border)
                        regFont(kb,"bold")
                        onAC(function(c) if not listening then kb.TextColor3=c end end)
                        kb.MouseButton1Click:Connect(function()
                            if listening then return end
                            listening=true; kb.Text="..."; kb.TextColor3=Color3.fromRGB(255,185,0); kb.BackgroundColor3=Color3.fromRGB(34,30,16)
                        end)
                        UIS.InputBegan:Connect(function(i,gpe)
                            if listening and not gpe and i.UserInputType==Enum.UserInputType.Keyboard then
                                key=i.KeyCode; kb.Text=key.Name; kb.TextColor3=AC; kb.BackgroundColor3=C.Input; listening=false
                            elseif not listening and not gpe and i.KeyCode==key and key~=Enum.KeyCode.Unknown then
                                set(not val)
                            end
                        end)
                    end

                    table.insert(self._allEls,{label=nm,frame=row})
                    local r={Value=val} function r:Set(v) set(v,true) end function r:Get() return val end return r
                end

                function S:AddSlider(o5)
                    o5=o5 or {}; local nm=o5.Name or "Slider"; local mn,mx=o5.Min or 0,o5.Max or 100; local step=o5.Step or 1; local suf=o5.Suffix or ""; local flag=o5.Flag; local cb=o5.Callback or function() end
                    local val=math.clamp(o5.Default or mn,mn,mx)
                    local wrap=new("Frame",{Size=UDim2.new(1,0,0,44),BackgroundTransparency=1,ZIndex=6,Parent=self._i})
                    local top=new("Frame",{Size=UDim2.new(1,0,0,20),BackgroundTransparency=1,ZIndex=6,Parent=wrap})
                    local sliderLbl=new("TextLabel",{Text=nm,Size=UDim2.new(1,-54,1,0),BackgroundTransparency=1,TextColor3=C.TxtSub,TextSize=12,Font=_FONT,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=7,Parent=top})
                    regFont(sliderLbl,"body")
                    local vb=new("Frame",{Size=UDim2.new(0,46,0,18),Position=UDim2.new(1,-48,.5,-9),BackgroundColor3=C.Input,ZIndex=7,Parent=top}); cor(vb,UDim.new(0,6))
                    local vl=new("TextLabel",{Text=tostring(val)..suf,Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,TextColor3=AC,TextSize=11,Font=_FONTBOLD,ZIndex=8,Parent=vb})
                    regFont(vl,"bold")
                    onAC(function(c) vl.TextColor3=c end)
                    local hb=new("TextButton",{Size=UDim2.new(1,0,0,22),Position=UDim2.new(0,0,0,22),BackgroundTransparency=1,Text="",AutoButtonColor=false,ZIndex=9,Parent=wrap})
                    local tr=new("Frame",{Size=UDim2.new(1,0,0,5),Position=UDim2.new(0,0,.5,-2),BackgroundColor3=C.SliderBg,ZIndex=6,Parent=hb}); cor(tr,UDim.new(0,3))
                    local pct=(val-mn)/(mx-mn)
                    local fl=new("Frame",{Size=UDim2.new(pct,0,1,0),BackgroundColor3=AC,ZIndex=7,Parent=tr}); cor(fl,UDim.new(0,3))
                    local kn=new("Frame",{Size=UDim2.new(0,14,0,14),AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(pct,0,.5,0),BackgroundColor3=C.TxtOn,ZIndex=9,Parent=tr}); cor(kn,UDim.new(0,7)); str(kn,AC,2)
                    onAC(function(c) fl.BackgroundColor3=c; str(kn,c,2) end)
                    hb.MouseEnter:Connect(function() twSp(kn,{Size=UDim2.new(0,17,0,17)},.15) end)
                    hb.MouseLeave:Connect(function() tw(kn,{Size=UDim2.new(0,14,0,14)},.12) end)
                    local function sv(v,silent)
                        v=math.clamp(math.round(v/step)*step,mn,mx); val=v; local p=(v-mn)/(mx-mn)
                        fl.Size=UDim2.new(p,0,1,0); kn.Position=UDim2.new(p,0,.5,0); vl.Text=tostring(v)..suf
                        if not silent then fire("Slider",nm,v);cb(v) end; if flag then _G[flag]=v end
                    end
                    local dr=false
                    hb.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dr=true;sv(mn+(mx-mn)*math.clamp((i.Position.X-tr.AbsolutePosition.X)/tr.AbsoluteSize.X,0,1)) end end)
                    UIS.InputChanged:Connect(function(i) if dr and i.UserInputType==Enum.UserInputType.MouseMovement then sv(mn+(mx-mn)*math.clamp((i.Position.X-tr.AbsolutePosition.X)/tr.AbsoluteSize.X,0,1)) end end)
                    UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dr=false end end)
                    if flag then _G[flag]=val end
                    table.insert(self._allEls,{label=nm,frame=wrap})
                    local r={Value=val} function r:Set(v) sv(v,true) end function r:Get() return val end return r
                end

                function S:AddTextbox(o5)
                    o5=o5 or {}; local nm=o5.Name or "Textbox"; local cb=o5.Callback or function() end
                    local wrap=new("Frame",{Size=UDim2.new(1,0,0,46),BackgroundTransparency=1,ZIndex=6,Parent=self._i})
                    local tbLbl=new("TextLabel",{Text=nm,Size=UDim2.new(1,0,0,16),BackgroundTransparency=1,TextColor3=C.TxtSub,TextSize=12,Font=_FONT,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=7,Parent=wrap})
                    regFont(tbLbl,"body")
                    local ifrm=new("Frame",{Size=UDim2.new(1,0,0,26),Position=UDim2.new(0,0,0,18),BackgroundColor3=C.Input,ZIndex=7,Parent=wrap}); cor(ifrm,UDim.new(0,8)); local sk=str(ifrm,C.Border)
                    local tb=new("TextBox",{Text=o5.Default or "",PlaceholderText=o5.Placeholder or "Type here",Size=UDim2.new(1,-32,1,0),Position=UDim2.new(0,8,0,0),BackgroundTransparency=1,TextColor3=C.TxtOn,PlaceholderColor3=C.TxtOff,TextSize=11,Font=_FONT,TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false,ZIndex=8,Parent=ifrm})
                    regFont(tb,"body")
                    local cf=new("TextButton",{Size=UDim2.new(0,22,0,20),Position=UDim2.new(1,-24,.5,-10),BackgroundColor3=AC,Text="✓",TextColor3=C.TxtOn,TextSize=12,Font=_FONTBOLD,AutoButtonColor=false,ZIndex=9,Parent=ifrm}); cor(cf,UDim.new(0,6))
                    regFont(cf,"bold")
                    onAC(function(c) cf.BackgroundColor3=c end)
                    cf.MouseEnter:Connect(function() tw(cf,{BackgroundColor3=dk(AC,.85)},.1);twSp(cf,{Size=UDim2.new(0,24,0,22)},.15) end)
                    cf.MouseLeave:Connect(function() tw(cf,{BackgroundColor3=AC},.1);tw(cf,{Size=UDim2.new(0,22,0,20)},.12) end)
                    tb.Focused:Connect(function() tw(sk,{Color=AC},.12) end)
                    tb.FocusLost:Connect(function(en) tw(sk,{Color=C.Border},.12); if en then fire("Textbox",nm,tb.Text);toast(o5);cb(tb.Text) end end)
                    cf.MouseButton1Click:Connect(function() fire("Textbox",nm,tb.Text);toast(o5);cb(tb.Text);tb:ReleaseFocus() end)
                    if o5.OnChange then tb:GetPropertyChangedSignal("Text"):Connect(function() cb(tb.Text) end) end
                    table.insert(self._allEls,{label=nm,frame=wrap})
                    local r={} function r:Set(v) tb.Text=v end function r:Get() return tb.Text end return r
                end

                function S:AddDropdown(o5)
                    o5=o5 or {}; local nm=o5.Name or "Dropdown"; local opts=o5.Options or {}; local multi=o5.Multi or false; local flag=o5.Flag; local cb=o5.Callback or function() end
                    local sel=o5.Default or (opts[1] or ""); local msel={}; local open=false
                    local wrap=new("Frame",{Size=UDim2.new(1,0,0,46),BackgroundTransparency=1,ZIndex=6,Parent=self._i})
                    local ddLbl=new("TextLabel",{Text=nm,Size=UDim2.new(1,0,0,16),BackgroundTransparency=1,TextColor3=C.TxtSub,TextSize=12,Font=_FONT,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=7,Parent=wrap})
                    regFont(ddLbl,"body")
                    local hd=new("TextButton",{Size=UDim2.new(1,0,0,26),Position=UDim2.new(0,0,0,18),BackgroundColor3=C.Input,Text="",AutoButtonColor=false,ZIndex=7,Parent=wrap}); cor(hd,UDim.new(0,8)); local hsk=str(hd,C.Border)
                    hd.MouseEnter:Connect(function() tw(hd,{BackgroundColor3=C.BtnHover},.1);tw(hsk,{Color=AC},.1) end)
                    hd.MouseLeave:Connect(function() tw(hd,{BackgroundColor3=C.Input},.1);tw(hsk,{Color=C.Border},.1) end)
                    local sl=new("TextLabel",{Text=multi and "Select..." or tostring(sel),Size=UDim2.new(1,-26,1,0),Position=UDim2.new(0,8,0,0),BackgroundTransparency=1,TextColor3=C.TxtOn,TextSize=11,Font=_FONT,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=8,Parent=hd})
                    regFont(sl,"body")
                    local ar=new("ImageLabel",{Image="rbxassetid://6034818375",Size=UDim2.new(0,12,0,12),Position=UDim2.new(1,-18,.5,-6),BackgroundTransparency=1,ImageColor3=C.TxtOff,ZIndex=8,Parent=hd})
                    local function closeDropdown() open=false; tw(ar,{Rotation=0},.15); closeOV() end
                    local function build(ov)
                        local ap=hd.AbsolutePosition;local as=hd.AbsoluteSize;local lh=math.min(#opts*26+10,160)
                        local px=math.min(ap.X,SG.AbsoluteSize.X-as.X-8);local py=ap.Y+as.Y+4;if py+lh>SG.AbsoluteSize.Y-8 then py=ap.Y-lh-4 end
                        local pan=new("Frame",{Size=UDim2.new(0,as.X,0,0),Position=UDim2.new(0,px,0,py),BackgroundColor3=Color3.fromRGB(24,24,24),ZIndex=210,Parent=ov}); cor(pan,UDim.new(0,10)); str(pan,C.Border)
                        tw(pan,{Size=UDim2.new(0,as.X,0,lh)},.15,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
                        local sc=new("ScrollingFrame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,ScrollBarThickness=2,ScrollBarImageColor3=AC,CanvasSize=UDim2.new(0,0,0,0),ZIndex=211,Parent=pan}); lst(sc,Enum.FillDirection.Vertical,2); pad(sc,4,4,4,4); autoY(sc)
                        ov.ChildRemoved:Connect(function() tw(ar,{Rotation=0},.15); open=false end)
                        for _,op in pairs(opts) do
                            local isSel=multi and table.find(msel,op)~=nil or op==sel
                            local ob=new("TextButton",{Size=UDim2.new(1,0,0,24),BackgroundColor3=isSel and AC or Color3.fromRGB(30,30,30),Text=op,TextColor3=isSel and C.TxtOn or C.TxtSub,TextSize=11,Font=_FONT,AutoButtonColor=false,ZIndex=212,Parent=sc}); cor(ob,UDim.new(0,6))
                            regFont(ob,"body")
                            ob.MouseEnter:Connect(function() if not(multi and table.find(msel,op)) and op~=sel then tw(ob,{BackgroundColor3=Color3.fromRGB(42,42,42),TextColor3=C.TxtOn},.08) end end)
                            ob.MouseLeave:Connect(function() local s2=multi and table.find(msel,op)~=nil or op==sel;ob.BackgroundColor3=s2 and AC or Color3.fromRGB(30,30,30);ob.TextColor3=s2 and C.TxtOn or C.TxtSub end)
                            ob.MouseButton1Click:Connect(function()
                                if multi then local idx=table.find(msel,op);if idx then table.remove(msel,idx) else table.insert(msel,op) end;sl.Text=#msel>0 and table.concat(msel,", ") or "Select...";cb(msel);fire("Dropdown",nm,msel);toast(o5);if flag then _G[flag]=msel end
                                else sel=op;sl.Text=op;cb(op);fire("Dropdown",nm,op);toast(o5);if flag then _G[flag]=op end;closeDropdown() end
                            end)
                        end
                    end
                    hd.MouseButton1Click:Connect(function() open=not open; if open then tw(ar,{Rotation=180},.15);openOV(build) else closeDropdown() end end)
                    if flag then _G[flag]=sel end
                    table.insert(self._allEls,{label=nm,frame=wrap})
                    local r={Value=sel} function r:Set(v) sel=v;sl.Text=v;if flag then _G[flag]=v end end function r:SetOptions(t) opts=t end function r:Get() return multi and msel or sel end return r
                end

                function S:AddColorPicker(o5)
                    o5=o5 or {}; local nm=o5.Name or "Color"; local col=o5.Default or Color3.fromRGB(255,80,80); local flag=o5.Flag; local cb=o5.Callback or function() end; local open=false; local ch,cs,cv=Color3.toHSV(col)
                    local row=new("Frame",{Size=UDim2.new(1,0,0,28),BackgroundColor3=C.BtnOff,BackgroundTransparency=1,ZIndex=6,Parent=self._i}); cor(row,UDim.new(0,6))
                    row.MouseEnter:Connect(function() tw(row,{BackgroundColor3=C.BtnHover,BackgroundTransparency=0},.1) end)
                    row.MouseLeave:Connect(function() tw(row,{BackgroundTransparency=1},.1) end)
                    local cpLbl=new("TextLabel",{Text=nm,Size=UDim2.new(1,-50,1,0),Position=UDim2.new(0,4,0,0),BackgroundTransparency=1,TextColor3=C.TxtSub,TextSize=12,Font=_FONT,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=7,Parent=row})
                    regFont(cpLbl,"body")
                    local sw=new("TextButton",{Size=UDim2.new(0,32,0,20),Position=UDim2.new(1,-36,.5,-10),BackgroundColor3=col,Text="",AutoButtonColor=false,ZIndex=7,Parent=row}); cor(sw,UDim.new(0,6)); str(sw,C.Border)
                    sw.MouseEnter:Connect(function() twSp(sw,{Size=UDim2.new(0,34,0,22)},.15) end)
                    sw.MouseLeave:Connect(function() tw(sw,{Size=UDim2.new(0,32,0,20)},.12) end)
                    local function buildCP(ov)
                        local ap=sw.AbsolutePosition; local pw,ph=220,140
                        local px=math.min(ap.X,SG.AbsoluteSize.X-pw-8); local py=ap.Y+24; if py+ph>SG.AbsoluteSize.Y-8 then py=ap.Y-ph-6 end
                        local pan=new("TextButton",{AutoButtonColor=false,Text="",Size=UDim2.new(0,pw,0,0),Position=UDim2.new(0,px,0,py),BackgroundColor3=Color3.fromRGB(22,22,22),ZIndex=210,Parent=ov}); cor(pan,UDim.new(0,12)); str(pan,C.Border)
                        tw(pan,{Size=UDim2.new(0,pw,0,ph)},.15,Enum.EasingStyle.Back)
                        local svbg=new("Frame",{Size=UDim2.new(1,-12,0,84),Position=UDim2.new(0,6,0,6),BackgroundColor3=Color3.fromHSV(ch,1,1),ZIndex=211,Parent=pan}); cor(svbg,UDim.new(0,6))
                        local wl=new("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.fromRGB(255,255,255),ZIndex=212,Parent=svbg}); cor(wl,UDim.new(0,6)); new("UIGradient",{Color=ColorSequence.new(Color3.fromRGB(255,255,255),Color3.fromRGB(255,255,255)),Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)}),Parent=wl})
                        local bl=new("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.fromRGB(0,0,0),ZIndex=213,Parent=svbg}); cor(bl,UDim.new(0,6)); new("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)}),Rotation=90,Parent=bl})
                        local svc=new("Frame",{Size=UDim2.new(0,12,0,12),AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(cs,0,1-cv,0),BackgroundColor3=C.TxtOn,ZIndex=215,Parent=svbg}); cor(svc,UDim.new(0,6)); str(svc,Color3.fromRGB(0,0,0),1.5)
                        local hb=new("Frame",{Size=UDim2.new(1,-12,0,12),Position=UDim2.new(0,6,0,96),ZIndex=211,Parent=pan}); cor(hb,UDim.new(0,6))
                        new("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,0,0)),ColorSequenceKeypoint.new(.17,Color3.fromRGB(255,255,0)),ColorSequenceKeypoint.new(.33,Color3.fromRGB(0,255,0)),ColorSequenceKeypoint.new(.5,Color3.fromRGB(0,255,255)),ColorSequenceKeypoint.new(.67,Color3.fromRGB(0,0,255)),ColorSequenceKeypoint.new(.83,Color3.fromRGB(255,0,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(255,0,0))}),Parent=hb})
                        local hc=new("Frame",{Size=UDim2.new(0,4,1,4),AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(ch,0,.5,0),BackgroundColor3=C.TxtOn,ZIndex=213,Parent=hb}); cor(hc,UDim.new(0,3))
                        local pv=new("Frame",{Size=UDim2.new(1,-12,0,14),Position=UDim2.new(0,6,0,115),BackgroundColor3=col,ZIndex=211,Parent=pan}); cor(pv,UDim.new(0,6))
                        local function upd() col=Color3.fromHSV(ch,cs,cv); sw.BackgroundColor3=col; svbg.BackgroundColor3=Color3.fromHSV(ch,1,1); svc.Position=UDim2.new(cs,0,1-cv,0); hc.Position=UDim2.new(ch,0,.5,0); pv.BackgroundColor3=col; fire("ColorPicker",nm,col); cb(col); if flag then _G[flag]=col end end
                        local svd,hud=false,false
                        svbg.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then svd=true;cs=math.clamp((i.Position.X-svbg.AbsolutePosition.X)/svbg.AbsoluteSize.X,0,1);cv=1-math.clamp((i.Position.Y-svbg.AbsolutePosition.Y)/svbg.AbsoluteSize.Y,0,1);upd() end end)
                        hb.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then hud=true;ch=math.clamp((i.Position.X-hb.AbsolutePosition.X)/hb.AbsoluteSize.X,0,1);upd() end end)
                        UIS.InputChanged:Connect(function(i) if i.UserInputType~=Enum.UserInputType.MouseMovement then return end;if svd then cs=math.clamp((i.Position.X-svbg.AbsolutePosition.X)/svbg.AbsoluteSize.X,0,1);cv=1-math.clamp((i.Position.Y-svbg.AbsolutePosition.Y)/svbg.AbsoluteSize.Y,0,1);upd() end;if hud then ch=math.clamp((i.Position.X-hb.AbsolutePosition.X)/hb.AbsoluteSize.X,0,1);upd() end end)
                        UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then svd=false;hud=false end end)
                    end
                    sw.MouseButton1Click:Connect(function() open=not open;if open then openOV(buildCP) else closeOV() end end)
                    if flag then _G[flag]=col end
                    table.insert(self._allEls,{label=nm,frame=row})
                    local r={Value=col} function r:Set(c2) col=c2;ch,cs,cv=Color3.toHSV(c2);sw.BackgroundColor3=c2 end function r:Get() return col end return r
                end

                function S:AddKeybind(o5)
                    o5=o5 or {}; local nm=o5.Name or "Keybind"; local key=o5.Default or Enum.KeyCode.Unknown; local flag=o5.Flag; local cb=o5.Callback or function() end; local listening=false
                    local row=new("Frame",{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,ZIndex=6,Parent=self._i})
                    local kbLbl=new("TextLabel",{Text=nm,Size=UDim2.new(1,-84,1,0),Position=UDim2.new(0,4,0,0),BackgroundTransparency=1,TextColor3=C.TxtSub,TextSize=12,Font=_FONT,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=7,Parent=row})
                    regFont(kbLbl,"body")
                    local kb=new("TextButton",{Size=UDim2.new(0,76,0,20),Position=UDim2.new(1,-80,.5,-10),BackgroundColor3=C.Input,Text=key.Name,TextColor3=AC,TextSize=10,Font=_FONTBOLD,AutoButtonColor=false,ZIndex=7,Parent=row}); cor(kb,UDim.new(0,6)); str(kb,C.Border)
                    regFont(kb,"bold")
                    onAC(function(c) if not listening then kb.TextColor3=c end end)
                    kb.MouseEnter:Connect(function() tw(kb,{BackgroundColor3=C.BtnHover},.1) end)
                    kb.MouseLeave:Connect(function() if not listening then tw(kb,{BackgroundColor3=C.Input},.1) end end)
                    kb.MouseButton1Click:Connect(function()
                        if listening then return end
                        listening=true; kb.Text="..."; kb.TextColor3=Color3.fromRGB(255,185,0); kb.BackgroundColor3=Color3.fromRGB(34,30,16); twSp(kb,{Size=UDim2.new(0,80,0,22)},.2)
                    end)
                    UIS.InputBegan:Connect(function(i,gpe)
                        if listening and not gpe then
                            if i.UserInputType==Enum.UserInputType.Keyboard then
                                key=i.KeyCode; kb.Text=key.Name; kb.TextColor3=AC; kb.BackgroundColor3=C.Input; tw(kb,{Size=UDim2.new(0,76,0,20)},.12); listening=false
                                fire("Keybind",nm,key); if flag then _G[flag]=key end
                            elseif i.UserInputType==Enum.UserInputType.MouseButton2 then
                                kb.Text=key.Name; kb.TextColor3=AC; kb.BackgroundColor3=C.Input; tw(kb,{Size=UDim2.new(0,76,0,20)},.12); listening=false
                            end
                        elseif not listening and not gpe and i.KeyCode==key then
                            if key==KEY then _keyIgnoreOnce=true end
                            local lf=o5.LinkedFlag
                            if lf and _toggleRegistry[lf] then
                                local tr=_toggleRegistry[lf]
                                tr.set(not tr.get())
                            end
                            fire("Keybind",nm,key); toast(o5); cb()
                        end
                    end)
                    if flag then _G[flag]=key end
                    table.insert(self._allEls,{label=nm,frame=row})
                    local r={Value=key} function r:Set(k) key=k;kb.Text=k.Name end function r:Get() return key end return r
                end

                function S:AddSeparator()
                    local sep=new("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=C.Border,BorderSizePixel=0,ZIndex=6,Parent=self._i})
                    new("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.08,0),NumberSequenceKeypoint.new(.92,0),NumberSequenceKeypoint.new(1,1)}),Parent=sep})
                end

                function S:AddProgressBar(o5)
                    o5=o5 or {}; local nm=o5.Name or "Progress"; local mx=o5.Max or 100; local cur=math.clamp(o5.Default or 0,0,mx); local pbc=o5.Color or AC
                    local wrap=new("Frame",{Size=UDim2.new(1,0,0,36),BackgroundTransparency=1,ZIndex=6,Parent=self._i})
                    local pbLbl=new("TextLabel",{Text=nm,Size=UDim2.new(1,-44,0,16),BackgroundTransparency=1,TextColor3=C.TxtSub,TextSize=12,Font=_FONT,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=7,Parent=wrap})
                    regFont(pbLbl,"body")
                    local pl=new("TextLabel",{Text=math.round(cur/mx*100).."%",Size=UDim2.new(0,40,0,16),Position=UDim2.new(1,-42,0,0),BackgroundTransparency=1,TextColor3=AC,TextSize=11,Font=_FONTBOLD,ZIndex=7,Parent=wrap})
                    regFont(pl,"bold")
                    onAC(function(c) pl.TextColor3=c end)
                    local tr=new("Frame",{Size=UDim2.new(1,0,0,6),Position=UDim2.new(0,0,0,22),BackgroundColor3=C.SliderBg,ZIndex=7,Parent=wrap}); cor(tr,UDim.new(0,4))
                    local fl=new("Frame",{Size=UDim2.new(cur/mx,0,1,0),BackgroundColor3=pbc,ZIndex=8,Parent=tr}); cor(fl,UDim.new(0,4))
                    onAC(function(c) if pbc==AC then fl.BackgroundColor3=c end end)
                    local r={Value=cur}
                    function r:Set(v) v=math.clamp(v,0,mx);cur=v;tw(fl,{Size=UDim2.new(v/mx,0,1,0)},.22);pl.Text=math.round(v/mx*100).."%" end
                    function r:Get() return cur end
                    return r
                end

                return S
            end
            return STAB
        end
        return TAB
    end

    function WO:Destroy() SG:Destroy() end
    function WO:Toggle() _vis=not _vis; WIN.Visible=_vis end
    function WO:SetAccent(c) AC=c; applyAC() end

    -- Config tab is added via task.defer so it runs AFTER the calling script
    -- has added all its own tabs. We also set LayoutOrder=9999 on both the
    -- category frame and the tab button so UIListLayout always sorts them last.
    local _finalized = false
    local function _finalizeConfig()
        if _finalized then return end
        _finalized = true
        _sideOrder = 9998
        WO:AddCategory("System")
        local TabCfg = WO:AddTab({ Name = o.ConfigName or "Config", Icon = o.ConfigIcon or "rbxassetid://0" })

        local SubUI = TabCfg:AddSubTab({ Name = "Interface" })
        local SecAccent = SubUI:AddSection({ Name = "Appearance", Side = "left" })
        SecAccent:AddColorPicker({
            Name = "Accent Color",
            Default = AC,
            Callback = function(c) WO:SetAccent(c) end,
        })
        SecAccent:AddDropdown({
            Name = "Font",
            Options = {"Gotham","Arial","SourceSans","Ubuntu","RobotoMono","Nunito","Oswald","FredokaOne","Creepster","PermanentMarker","Bangers","Sarpanch","SpecialElite","SciFi","Code","Highway","Cartoon","Arcade","Fantasy","Antique"},
            Default = "Gotham",
            Callback = function(v)
                local map={
                    Gotham=Enum.Font.Gotham, Arial=Enum.Font.Arial,
                    SourceSans=Enum.Font.SourceSans, Ubuntu=Enum.Font.Ubuntu,
                    RobotoMono=Enum.Font.RobotoMono, Nunito=Enum.Font.Nunito,
                    Oswald=Enum.Font.Oswald, FredokaOne=Enum.Font.FredokaOne,
                    Creepster=Enum.Font.Creepster, PermanentMarker=Enum.Font.PermanentMarker,
                    Bangers=Enum.Font.Bangers, Sarpanch=Enum.Font.Sarpanch,
                    SpecialElite=Enum.Font.SpecialElite, SciFi=Enum.Font.SciFi,
                    Code=Enum.Font.Code, Highway=Enum.Font.Highway,
                    Cartoon=Enum.Font.Cartoon, Arcade=Enum.Font.Arcade,
                    Fantasy=Enum.Font.Fantasy, Antique=Enum.Font.Antique,
                }
                if map[v] then setFont(map[v]) end
            end,
        })
        SecAccent:AddToggle({
            Name = "Auto Contrast",
            Default = false,
            Callback = function(v)
                _contrastOn = v
                if v then applyContrast(AC) else
                    for _, e in ipairs(_contrastReg) do
                        if e.obj and e.obj.Parent then
                            if e.role=="on" then e.obj.TextColor3=Color3.fromRGB(255,255,255)
                            elseif e.role=="sub" then e.obj.TextColor3=Color3.fromRGB(170,170,182)
                            elseif e.role=="muted" then e.obj.TextColor3=Color3.fromRGB(80,80,92) end
                        end
                    end
                end
            end,
        })

        local SecKeybinds = SubUI:AddSection({ Name = "Keybinds", Side = "right" })
        SecKeybinds:AddKeybind({
            Name = "Open/Close Menu",
            Default = KEY,
            Callback = function() WO:Toggle() end,
        })

        local SubSec = TabCfg:AddSubTab({ Name = "Security" })
        local SecProt = SubSec:AddSection({ Name = "Protections", Side = "left" })
        SecProt:AddToggle({ Name = "Anti-AFK", Default = true,
            Callback = function(v)
                if v then pcall(function() game:GetService("VirtualUser"):Button2Down(Vector2.new(0,0),CFrame.new()) end) end
            end })
        local SecInfo = SubSec:AddSection({ Name = "Info", Side = "right" })
        SecInfo:AddLabel({ Text = "Peleccos Softwares v11.0", Color = Color3.fromRGB(130,130,145), Size = 13 })
        SecInfo:AddSeparator()
        SecInfo:AddLabel({ Text = "Automatic configuration tab.", Color = Color3.fromRGB(70,70,80), Size = 11 })

        -- ── Built-in Config Save/Load ─────────────────────────────────────
        -- Works with any script that uses this lib without any extra code.
        -- Saves/loads all Toggle and Slider values by their Name+Section key.
        local CFG_FOLDER = "PeleccosSoftwares"
        local CFG_FILE   = CFG_FOLDER .. "/ui_config.json"
        local _cfgData   = {}  -- name → value

        local function cfgSave()
            pcall(function()
                if not isfolder(CFG_FOLDER) then makefolder(CFG_FOLDER) end
                writefile(CFG_FILE, game:GetService("HttpService"):JSONEncode(_cfgData))
            end)
        end

        local function cfgLoad()
            pcall(function()
                if not isfile(CFG_FILE) then return end
                local raw = readfile(CFG_FILE)
                if raw and #raw > 1 then
                    _cfgData = game:GetService("HttpService"):JSONDecode(raw) or {}
                end
            end)
        end

        -- Wrap the event bus so every Toggle/Slider change is intercepted
        -- and saved without modifying the calling script at all
        local _origFire = Peleccos.Events.Fire
        Peleccos.Events.Fire = function(self, d)
            if d and (d.Type == "Toggle" or d.Type == "Slider") then
                local key = (d.Tab or "") .. "|" .. (d.SubTab or "") .. "|" .. (d.Section or "") .. "|" .. (d.Name or "")
                _cfgData[key] = d.Value
            end
            return _origFire(self, d)
        end

        -- Restore saved values on next frame (after GUI is fully built)
        task.defer(function()
            cfgLoad()
            for key, val in pairs(_cfgData) do
                -- Fire a fake event so listeners update their internal state
                local parts = key:split("|")
                if #parts == 4 then
                    Peleccos.Events:Fire({
                        Type    = type(val) == "boolean" and "Toggle" or "Slider",
                        Name    = parts[4],
                        Value   = val,
                        Tab     = parts[1],
                        SubTab  = parts[2],
                        Section = parts[3],
                        _fromLoad = true,
                    })
                end
            end
        end)

        -- Config SubTab: Configs (named profiles)
        local PROFILES_FOLDER = CFG_FOLDER .. "/configs"
        pcall(function() if not isfolder(PROFILES_FOLDER) then makefolder(PROFILES_FOLDER) end end)

        local _currentProfile = "default"
        local _autoSave = true

        local function profilePath(name)
            return PROFILES_FOLDER .. "/" .. (name or "default"):gsub("[^%w_%-]","_") .. ".json"
        end

        local function saveProfile(name)
            pcall(function()
                if not isfolder(PROFILES_FOLDER) then makefolder(PROFILES_FOLDER) end
                writefile(profilePath(name), game:GetService("HttpService"):JSONEncode(_cfgData))
            end)
        end

        local function loadProfile(name)
            local count = 0
            pcall(function()
                local path = profilePath(name)
                if not isfile(path) then return end
                local raw = readfile(path)
                if not raw or #raw < 2 then return end
                _cfgData = game:GetService("HttpService"):JSONDecode(raw) or {}
                for key, val in pairs(_cfgData) do
                    local parts = key:split("|")
                    if #parts == 4 then
                        Peleccos.Events:Fire({
                            Type      = type(val) == "boolean" and "Toggle" or "Slider",
                            Name      = parts[4], Value   = val,
                            Tab       = parts[1], SubTab  = parts[2],
                            Section   = parts[3], _fromLoad = true,
                        })
                        count = count + 1
                    end
                end
            end)
            return count
        end

        local function listProfiles()
            local list = {}
            pcall(function()
                if not isfolder(PROFILES_FOLDER) then return end
                for _, f in ipairs(listfiles(PROFILES_FOLDER)) do
                    local name = f:match("([^/\]+)%.json$")
                    if name then table.insert(list, name) end
                end
            end)
            if #list == 0 then table.insert(list, "default") end
            return list
        end

        local function deleteProfile(name)
            pcall(function()
                local path = profilePath(name)
                if isfile(path) then delfile(path) end
            end)
        end

        -- Auto-patch Fire to save on every change
        local _origFireCfg = Peleccos.Events.Fire
        Peleccos.Events.Fire = function(self2, d)
            local r = _origFireCfg(self2, d)
            if d and (d.Type=="Toggle" or d.Type=="Slider") and not d._fromLoad then
                local key = (d.Tab or "").."|"..(d.SubTab or "").."|"..(d.Section or "").."|"..(d.Name or "")
                _cfgData[key] = d.Value
                if _autoSave then saveProfile(_currentProfile) end
            end
            return r
        end

        -- Load default profile on startup
        task.defer(function() loadProfile("default"); _currentProfile = "default" end)

        local SubCfg = TabCfg:AddSubTab({ Name = "Configs" })

        -- LEFT: profile list + actions
        local SecProfiles = SubCfg:AddSection({ Name = "Profiles", Side = "left" })

        local _profileList = listProfiles()
        local _selectedProfile = _profileList[1] or "default"

        local profileDropRef = SecProfiles:AddDropdown({
            Name = "Active Profile",
            Options = _profileList,
            Default = _selectedProfile,
            Callback = function(v) _selectedProfile = v end,
        })

        SecProfiles:AddButton({
            Name = "Load Selected",
            Callback = function()
                _currentProfile = _selectedProfile
                local n = loadProfile(_currentProfile)
                notify({ Title="Config", Desc='Loaded "'..(_currentProfile)..'" ('..n..' settings)', Type="Success", Duration=3 })
            end,
        })

        SecProfiles:AddButton({
            Name = "Save to Selected",
            Callback = function()
                _currentProfile = _selectedProfile
                saveProfile(_currentProfile)
                notify({ Title="Config", Desc='Saved to "'.._currentProfile..'"', Type="Success", Duration=3 })
            end,
        })

        SecProfiles:AddButton({
            Name = "Delete Selected",
            Callback = function()
                if _selectedProfile == "default" then
                    notify({ Title="Config", Desc="Cannot delete default profile.", Type="Warning", Duration=3 })
                    return
                end
                deleteProfile(_selectedProfile)
                notify({ Title="Config", Desc='Deleted "'.._selectedProfile..'"', Type="Success", Duration=3 })
                -- Refresh dropdown
                local newList = listProfiles()
                profileDropRef:SetOptions(newList)
                _selectedProfile = newList[1] or "default"
                profileDropRef:Set(_selectedProfile)
            end,
        })

        -- RIGHT: create new profile + auto-save
        local SecNewProfile = SubCfg:AddSection({ Name = "New Profile", Side = "right" })

        local _newProfileName = ""
        SecNewProfile:AddTextbox({
            Name = "Profile Name",
            Placeholder = "my_config",
            Callback = function(v) _newProfileName = v:gsub("[^%w_%-]","_") end,
        })

        SecNewProfile:AddButton({
            Name = "Create & Save",
            Callback = function()
                local name = _newProfileName ~= "" and _newProfileName or "profile_"..os.time()
                saveProfile(name)
                local newList = listProfiles()
                profileDropRef:SetOptions(newList)
                profileDropRef:Set(name)
                _selectedProfile = name
                _currentProfile  = name
                notify({ Title="Config", Desc='Created "'..name..'"', Type="Success", Duration=3 })
                _newProfileName = ""
            end,
        })

        SecNewProfile:AddSeparator()

        SecNewProfile:AddToggle({
            Name = "Auto-Save on Change",
            Default = true,
            Callback = function(v) _autoSave = v end,
        })
        SecNewProfile:AddLabel({ Text = "Saves to active profile on every toggle/slider change.", Color = Color3.fromRGB(90,90,100) })
    end

    -- Auto-finalize after 0.5s if script never calls Finalize()
    task.delay(0.5, function() _finalizeConfig() end)

    -- Expose so script can call Win:Finalize() explicitly after adding all tabs
    function WO:Finalize() _finalizeConfig() end

    return WO
end

logError("PeleccosSoftwares module initialized")
return Peleccos
