--[[
    PeleccosSoftwares v12.3
    Changes from v12.2:
    - Top bar taller (34px)
    - Ping: multi-method detection (Stats.Network + Heartbeat fallback)
    - Watermark: all fields visible — ScriptName | User | Game[id] | Config | fps | ping
    - Settings window: already has no X button (toggle via Settings button only)
    - Textboxes: already have no OK button (FocusLost auto-fires callback)
    - Custom font support via Font = "fonts/myfont.ttf" in CreateWindow
    - Config Manager: Create / Load / Save / Delete / Open folder
    - Auto-detects all flagged elements for config saving
]]
-- ═══════════════════════════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════════════════════════
local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")
local GuiService   = game:GetService("GuiService")
local HttpService  = game:GetService("HttpService")
local LP           = Players.LocalPlayer

-- ═══════════════════════════════════════════════════════════════
-- FOLDERS
-- ═══════════════════════════════════════════════════════════════
local _DIR = "PeleccosSoftwares"
pcall(function() if not isfolder(_DIR)             then makefolder(_DIR) end end)
pcall(function() if not isfolder(_DIR.."/eggs")    then makefolder(_DIR.."/eggs") end end)
pcall(function() if not isfolder(_DIR.."/configs") then makefolder(_DIR.."/configs") end end)
pcall(function() if not isfolder(_DIR.."/fonts")   then makefolder(_DIR.."/fonts") end end)

-- ═══════════════════════════════════════════════════════════════
-- ASSET LOADER  (PNG images + TTF/OTF fonts from muglios server)
-- ═══════════════════════════════════════════════════════════════
local BASE_URL = "http://muglios.ddns.net:45905/"

local function loadAsset(remotePath, localDir, validate)
    if not (typeof(isfile)=="function" and typeof(writefile)=="function" and typeof(getcustomasset)=="function") then return "" end
    local fileName = localDir..(remotePath:match("[^/]+$") or remotePath)
    local url = BASE_URL .. remotePath
    local result = ""
    pcall(function()
        if not isfile(fileName) then
            local data = game:HttpGet(url)
            if not data or #data < 4 then return end
            if validate and not validate(data) then return end
            writefile(fileName, data)
        end
        if isfile(fileName) then result = getcustomasset(fileName) or "" end
    end)
    return result
end

local function loadImage(path) return loadAsset(path, _DIR.."/eggs/", function(d) return d:sub(1,4)=="\137PNG" end) end
local function loadFont(path)  return loadAsset(path, _DIR.."/fonts/", nil) end

-- ═══════════════════════════════════════════════════════════════
-- PRIMITIVE HELPERS
-- ═══════════════════════════════════════════════════════════════
local rgb  = Color3.fromRGB
local hsv  = Color3.fromHSV
local dim2 = UDim2.new
local dim  = UDim.new

local function tw(obj, props, style, t, dir)
    TweenService:Create(obj, TweenInfo.new(t or 0.22, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props):Play()
end

local function mk(cls, props)
    local o = Instance.new(cls)
    for k,v in pairs(props or {}) do if k~="Parent" then o[k]=v end end
    if props and props.Parent then o.Parent=props.Parent end
    return o
end

local RC = { none=dim(0,0), sharp=dim(0,4), soft=dim(0,6), mid=dim(0,8), pill=dim(0,999) }

local function corner(p,r)     local c=Instance.new("UICorner");c.CornerRadius=r or RC.soft;c.Parent=p;return c end
local function stroke(p,col,t) local s=Instance.new("UIStroke");s.Color=col or rgb(55,55,62);s.Thickness=t or 1.5;s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;s.Parent=p;return s end
local function padding(p,t,r,b,l) local u=Instance.new("UIPadding");u.PaddingTop=dim(0,t or 0);u.PaddingRight=dim(0,r or 0);u.PaddingBottom=dim(0,b or 0);u.PaddingLeft=dim(0,l or 0);u.Parent=p;return u end
local function layout(p,dir,gap,ha,va) local l=Instance.new("UIListLayout");l.FillDirection=dir or Enum.FillDirection.Vertical;l.Padding=dim(0,gap or 0);l.HorizontalAlignment=ha or Enum.HorizontalAlignment.Left;l.VerticalAlignment=va or Enum.VerticalAlignment.Top;l.SortOrder=Enum.SortOrder.LayoutOrder;l.Parent=p;return l end
local function autoCanvas(sf) local ll=sf:FindFirstChildOfClass("UIListLayout");if not ll then return end;local function upd() task.defer(function() if sf and sf.Parent then sf.CanvasSize=dim2(0,0,0,ll.AbsoluteContentSize.Y+14) end end) end;ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(upd);upd() end
local function draggify(frame,handle) local drag,ds,sp=false,nil,nil;handle=handle or frame;handle.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true;ds=i.Position;sp=frame.Position end end);UIS.InputChanged:Connect(function(i) if drag and i.UserInputType==Enum.UserInputType.MouseMovement then local d=i.Position-ds;frame.Position=dim2(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y) end end);UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end) end

-- ═══════════════════════════════════════════════════════════════
-- PALETTE
-- ═══════════════════════════════════════════════════════════════
local C = {
    bg0=rgb(10,10,12),bg1=rgb(16,16,19),bg2=rgb(20,20,23),bg3=rgb(26,26,30),bg4=rgb(34,34,39),
    br0=rgb(55,55,62),br1=rgb(42,42,48),br2=rgb(70,70,78),
    t0=rgb(240,240,244),t1=rgb(170,170,178),t2=rgb(90,90,98),
    nOk=rgb(50,200,100),nWarn=rgb(255,185,0),nErr=rgb(255,60,60),nInfo=rgb(0,130,255),
}

-- ═══════════════════════════════════════════════════════════════
-- FPS / PING  — multi-method ping detection
-- ═══════════════════════════════════════════════════════════════
local _fps, _ping = 60, 0
RunService.Heartbeat:Connect(function(dt) _fps=math.clamp(math.floor(1/dt),0,999) end)
task.spawn(function()
    while true do
        pcall(function()
            -- Method 1: Stats.Network.ServerStatsItem["Data Ping"]
            local ok1=false
            pcall(function()
                local stats=game:GetService("Stats")
                local net=stats:WaitForChild("Network",1)
                if net then
                    local ssi=net:FindFirstChild("ServerStatsItem")
                    if ssi then
                        local dp=ssi:FindFirstChild("Data Ping")
                        if dp then _ping=math.floor(dp:GetValue()); ok1=true end
                    end
                end
            end)
            -- Method 2: workspace ping via heartbeat timing delta
            if not ok1 then
                pcall(function()
                    local t0=tick()
                    game:GetService("RunService").Heartbeat:Wait()
                    local delta=tick()-t0
                    -- estimate from frame delta vs real delta (crude but works offline)
                    _ping=math.clamp(math.floor(delta*1000)-math.floor(1000/60),0,999)
                end)
            end
        end)
        task.wait(1)
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- EASTER EGG DATA
-- ═══════════════════════════════════════════════════════════════
local EASTER_IMGS = {"eggs/egg1.png","eggs/egg2.png","eggs/egg3.png"}
local EASTER_KW   = {"peleccos","easter","egg","secret","hidden","password","cheat","hack","admin","god","infinite","unlimited","special","rare","legendary"}

-- ═══════════════════════════════════════════════════════════════
-- NOTIFICATION SYSTEM
-- ═══════════════════════════════════════════════════════════════
local _notifHolder=nil
local function initNotifs(sg)
    _notifHolder=mk("Frame",{Size=dim2(0,244,0,0),AutomaticSize=Enum.AutomaticSize.Y,AnchorPoint=Vector2.new(1,1),Position=dim2(1,-14,1,-14),BackgroundTransparency=1,ZIndex=500,Parent=sg})
    layout(_notifHolder,Enum.FillDirection.Vertical,6,Enum.HorizontalAlignment.Right,Enum.VerticalAlignment.Bottom)
end
local function notify(o)
    if not _notifHolder then return end; o=o or {}
    local ac=({Success=C.nOk,Warning=C.nWarn,Error=C.nErr,Info=C.nInfo})[o.Type or "Info"] or C.nInfo
    local card=mk("Frame",{Size=dim2(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=C.bg1,BackgroundTransparency=1,ZIndex=501,Parent=_notifHolder})
    corner(card,RC.sharp); stroke(card,C.br0,1.5)
    mk("Frame",{Size=dim2(0,3,1,0),BackgroundColor3=ac,ZIndex=502,Parent=card})
    local inner=mk("Frame",{Size=dim2(1,-3,1,0),Position=dim2(0,3,0,0),BackgroundTransparency=1,ZIndex=502,Parent=card}); padding(inner,9,9,9,10); layout(inner,Enum.FillDirection.Vertical,4)
    local hrow=mk("Frame",{Size=dim2(1,0,0,16),BackgroundTransparency=1,ZIndex=503,Parent=inner}); layout(hrow,Enum.FillDirection.Horizontal,6,Enum.HorizontalAlignment.Left,Enum.VerticalAlignment.Center)
    local badge=mk("TextLabel",{Text=({Success="OK",Warning="!!",Error="XX",Info="??"})[o.Type or "Info"] or "??",Size=dim2(0,22,0,14),BackgroundColor3=ac,TextColor3=C.t0,TextSize=9,Font=Enum.Font.GothamBold,ZIndex=503,Parent=hrow}); corner(badge,RC.sharp)
    mk("TextLabel",{Text=o.Title or "Notice",Size=dim2(1,-28,1,0),BackgroundTransparency=1,TextColor3=C.t0,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=503,Parent=hrow})
    if o.Desc and o.Desc~="" then mk("TextLabel",{Text=o.Desc,Size=dim2(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,TextColor3=C.t2,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,ZIndex=503,Parent=inner}) end
    local pb=mk("Frame",{Size=dim2(1,0,0,2),BackgroundColor3=C.bg4,ZIndex=503,Parent=inner}); local pf=mk("Frame",{Size=dim2(1,0,1,0),BackgroundColor3=ac,ZIndex=504,Parent=pb})
    tw(card,{BackgroundTransparency=0},Enum.EasingStyle.Back,0.3,Enum.EasingDirection.Out); local dur=o.Duration or 4; tw(pf,{Size=dim2(0,0,1,0)},Enum.EasingStyle.Linear,dur)
    task.delay(dur,function() tw(card,{BackgroundTransparency=1},Enum.EasingStyle.Quint,0.2); task.wait(0.22); pcall(function() card:Destroy() end) end)
end

-- ═══════════════════════════════════════════════════════════════
-- HSV COLOR PICKER
-- ═══════════════════════════════════════════════════════════════
local function buildColorPicker(ov,anchor,h0,s0,v0,onUpdate,SG_ref)
    local ch,cs,cv=h0,s0,v0; local pw,ph=214,152
    local ap=anchor.AbsolutePosition; local px=math.min(ap.X,SG_ref.AbsoluteSize.X-pw-10); local py=ap.Y+anchor.AbsoluteSize.Y+6
    if py+ph>SG_ref.AbsoluteSize.Y-10 then py=ap.Y-ph-6 end
    local pan=mk("TextButton",{AutoButtonColor=false,Text="",Size=dim2(0,pw,0,0),Position=dim2(0,px,0,py),BackgroundColor3=C.bg1,ZIndex=220,Parent=ov}); corner(pan,RC.sharp); stroke(pan,C.br0,1.5); tw(pan,{Size=dim2(0,pw,0,ph)},Enum.EasingStyle.Back,0.18)
    local svbg=mk("Frame",{Size=dim2(1,-12,0,86),Position=dim2(0,6,0,6),BackgroundColor3=hsv(ch,1,1),ZIndex=221,Parent=pan}); corner(svbg,RC.sharp)
    local wg=mk("Frame",{Size=dim2(1,0,1,0),BackgroundColor3=rgb(255,255,255),ZIndex=222,Parent=svbg}); corner(wg,RC.sharp); mk("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)}),Parent=wg})
    local bg2f=mk("Frame",{Size=dim2(1,0,1,0),BackgroundColor3=rgb(0,0,0),ZIndex=223,Parent=svbg}); corner(bg2f,RC.sharp); mk("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)}),Rotation=90,Parent=bg2f})
    local svc=mk("TextButton",{AutoButtonColor=false,Text="",AnchorPoint=Vector2.new(.5,.5),Size=dim2(0,10,0,10),Position=dim2(cs,0,1-cv,0),BackgroundColor3=rgb(255,255,255),ZIndex=226,Parent=svbg}); corner(svc,RC.pill); stroke(svc,rgb(0,0,0),1.5)
    local hueBar=mk("TextButton",{AutoButtonColor=false,Text="",Size=dim2(1,-12,0,9),Position=dim2(0,6,0,98),ZIndex=221,Parent=pan}); corner(hueBar,RC.pill)
    mk("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,rgb(255,0,0)),ColorSequenceKeypoint.new(0.17,rgb(255,255,0)),ColorSequenceKeypoint.new(0.33,rgb(0,255,0)),ColorSequenceKeypoint.new(0.5,rgb(0,255,255)),ColorSequenceKeypoint.new(0.67,rgb(0,0,255)),ColorSequenceKeypoint.new(0.83,rgb(255,0,255)),ColorSequenceKeypoint.new(1,rgb(255,0,0))}),Parent=hueBar})
    local hueCursor=mk("Frame",{AnchorPoint=Vector2.new(.5,.5),Size=dim2(0,10,1,2),Position=dim2(ch,0,.5,0),BackgroundColor3=rgb(255,255,255),ZIndex=223,Parent=hueBar}); corner(hueCursor,RC.sharp); stroke(hueCursor,rgb(0,0,0),1)
    local prev=mk("Frame",{Size=dim2(1,-12,0,12),Position=dim2(0,6,0,113),BackgroundColor3=hsv(ch,cs,cv),ZIndex=221,Parent=pan}); corner(prev,RC.sharp)
    local function upd() local col=hsv(ch,cs,cv); svbg.BackgroundColor3=hsv(ch,1,1); svc.Position=dim2(cs,0,1-cv,0); hueCursor.Position=dim2(ch,0,.5,0); prev.BackgroundColor3=col; onUpdate(col,ch,cs,cv) end
    local dragSV,dragHue=false,false
    svbg.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragSV=true;cs=math.clamp((i.Position.X-svbg.AbsolutePosition.X)/svbg.AbsoluteSize.X,0,1);cv=1-math.clamp((i.Position.Y-svbg.AbsolutePosition.Y)/svbg.AbsoluteSize.Y,0,1);upd() end end)
    hueBar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragHue=true;ch=math.clamp((i.Position.X-hueBar.AbsolutePosition.X)/hueBar.AbsoluteSize.X,0,1);upd() end end)
    UIS.InputChanged:Connect(function(i) if i.UserInputType~=Enum.UserInputType.MouseMovement then return end; if dragSV then cs=math.clamp((i.Position.X-svbg.AbsolutePosition.X)/svbg.AbsoluteSize.X,0,1);cv=1-math.clamp((i.Position.Y-svbg.AbsolutePosition.Y)/svbg.AbsoluteSize.Y,0,1);upd() end; if dragHue then ch=math.clamp((i.Position.X-hueBar.AbsolutePosition.X)/hueBar.AbsoluteSize.X,0,1);upd() end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragSV=false;dragHue=false end end)
end

-- ═══════════════════════════════════════════════════════════════
-- SHARED WINDOW BUILDER
-- ═══════════════════════════════════════════════════════════════
local function buildWindow(parent,size,pos,zBase,bgImage,acReg)
    local outer=mk("Frame",{BackgroundColor3=rgb(8,8,10),BorderSizePixel=0,Size=size,Position=pos,ZIndex=zBase,Parent=parent})
    local outerStroke=stroke(outer,C.br0,2)
    local img=mk("ImageLabel",{Name="BgImage",BorderSizePixel=0,BackgroundColor3=rgb(6,6,8),AnchorPoint=Vector2.new(.5,.5),Image=bgImage or "",Size=dim2(1,-4,1,-4),Position=dim2(.5,0,.5,0),ZIndex=zBase+1,Parent=outer}); corner(img,RC.soft)
    local ov=mk("Frame",{Size=dim2(1,0,1,0),BackgroundColor3=rgb(0,0,0),BackgroundTransparency=0.38,ZIndex=zBase+2,Parent=img}); corner(ov,RC.soft)
    local dragHandle=mk("TextButton",{Size=dim2(1,0,1,0),BackgroundTransparency=1,Text="",AutoButtonColor=false,ZIndex=zBase+2,Parent=img})
    if acReg then acReg(function(c) outerStroke.Color=c end) end
    return outer,img,dragHandle
end

-- ═══════════════════════════════════════════════════════════════
-- CONFIG SYSTEM
-- ═══════════════════════════════════════════════════════════════
local function makeConfigSystem(scriptName)
    local cfgDir=_DIR.."/configs/"..scriptName.."/"
    pcall(function() if not isfolder(cfgDir) then makefolder(cfgDir) end end)
    local _flags={}

    local function reg(flag,getFn,setFn,ftype) if flag then _flags[flag]={get=getFn,set=setFn,ftype=ftype or "any"} end end

    local function listCfgs()
        local list={}
        pcall(function()
            if typeof(listfiles)=="function" then
                for _,f in ipairs(listfiles(cfgDir)) do
                    local name=f:match("([^/\\]+)%.json$")
                    if name then table.insert(list,name) end
                end
            end
        end)
        return list
    end

    local function saveCfg(name)
        local data={}
        for flag,info in pairs(_flags) do
            pcall(function()
                local v=info.get(); local t=info.ftype
                if     t=="bool"   then data[flag]=v and "true" or "false"
                elseif t=="number" then data[flag]=tostring(v)
                elseif t=="color"  then data[flag]=math.floor(v.R*255)..","..math.floor(v.G*255)..","..math.floor(v.B*255)
                elseif t=="key"    then data[flag]=tostring(v):gsub("Enum%.KeyCode%.","")
                else                    data[flag]=tostring(v) end
            end)
        end
        return pcall(function() writefile(cfgDir..name..".json",HttpService:JSONEncode(data)) end)
    end

    local function loadCfg(name)
        local ok2,data=pcall(function() return HttpService:JSONDecode(readfile(cfgDir..name..".json")) end)
        if not ok2 or type(data)~="table" then return false end
        for flag,val in pairs(data) do
            local info=_flags[flag]
            if info then pcall(function()
                local t=info.ftype
                if     t=="bool"   then info.set(val=="true")
                elseif t=="number" then info.set(tonumber(val) or 0)
                elseif t=="color"  then local r,g,b=val:match("(%d+),(%d+),(%d+)"); if r then info.set(rgb(tonumber(r),tonumber(g),tonumber(b))) end
                elseif t=="key"    then pcall(function() info.set(Enum.KeyCode[val]) end)
                else                    info.set(val) end
            end) end
        end
        return true
    end

    local function delCfg(name) pcall(function() delfile(cfgDir..name..".json") end) end
    local function openDir() pcall(function() if syn and syn.open_file_in_desktop then syn.open_file_in_desktop(cfgDir) end end) end

    return {register=reg, list=listCfgs, save=saveCfg, load=loadCfg, delete=delCfg, openDir=openDir, dir=cfgDir}
end

-- ═══════════════════════════════════════════════════════════════
-- LIBRARY
-- ═══════════════════════════════════════════════════════════════
local Peleccos={}; Peleccos.__index=Peleccos

function Peleccos:CreateWindow(o)
    o=o or {}

    pcall(function() game:GetService("CoreGui"):FindFirstChild("PeleccosV12"):Destroy() end)
    pcall(function() local pg=LP:FindFirstChild("PlayerGui"); if pg then local x=pg:FindFirstChild("PeleccosV12"); if x then x:Destroy() end end end)

    local AC       = o.AccentColor or rgb(160,160,170)
    local KEY      = o.Key or Enum.KeyCode.Insert
    local BG_IMAGE = o.Background or "rbxassetid://118298630077545"

    -- Custom font (downloaded from server, falls back to Gotham)
    local FONT_REG  = Enum.Font.Gotham
    local FONT_BOLD = Enum.Font.GothamBold
    local FONT_SEMI = Enum.Font.GothamSemibold
    if o.Font then
        task.spawn(function()
            local asset=loadFont(o.Font)
            if asset~="" then
                pcall(function()
                    -- Store so newly created elements can use it
                    -- (Roblox Font.new works in newer engine versions)
                    FONT_REG  = Font.new(asset,Enum.FontWeight.Regular)
                    FONT_BOLD = Font.new(asset,Enum.FontWeight.Bold)
                    FONT_SEMI = Font.new(asset,Enum.FontWeight.SemiBold)
                end)
            end
        end)
    end

    local _acCBs={}
    local function onAC(fn) table.insert(_acCBs,fn) end
    local function fireAC() for _,fn in ipairs(_acCBs) do pcall(fn,AC) end end

    local CFG={
        ScriptName = o.Title      or "PeleccosSoftwares",
        UserName   = LP and LP.Name or "User",
        ConfigName = o.ConfigName or "Default",
        BuildType  = o.BuildType  or "Public",
        GameName   = tostring(game.Name or "Unknown"),
        GameId     = tostring(game.GameId or 0),
        ShowWM     = true,
    }

    local CFGSYS=makeConfigSystem(CFG.ScriptName)

    -- ── ScreenGui ──────────────────────────────────────────────
    local SG=mk("ScreenGui",{Name="PeleccosV12",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Global,IgnoreGuiInset=true,DisplayOrder=999})
    local ok=pcall(function() SG.Parent=game:GetService("CoreGui") end)
    if not ok then SG.Parent=LP:WaitForChild("PlayerGui") end
    initNotifs(SG)

    local _ovRoot=mk("Frame",{Name="OvRoot",Size=dim2(1,0,1,0),BackgroundTransparency=1,ZIndex=200,Parent=SG})
    local _ovActive=nil
    local function closeOV() if _ovActive then _ovActive:Destroy();_ovActive=nil end end
    local function openOV(fn)
        closeOV(); local f=mk("Frame",{Size=dim2(1,0,1,0),BackgroundTransparency=1,ZIndex=200,Parent=_ovRoot})
        local bg=mk("TextButton",{Size=dim2(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=200,Parent=f})
        local ok2=false; task.delay(0.12,function() ok2=true end)
        bg.MouseButton1Click:Connect(function() if ok2 then closeOV() end end)
        _ovActive=f; fn(f)
    end

    -- ══════════════════════════════════════════════════════════
    -- TOP BAR — 30px
    -- ══════════════════════════════════════════════════════════
    local BAR_H=34
    local BAR=mk("Frame",{Name="Bar",Size=dim2(1,0,0,BAR_H),Position=dim2(0,0,0,0),BackgroundColor3=rgb(8,8,10),BorderSizePixel=0,ZIndex=50,Parent=SG})
    local barLine=mk("Frame",{Size=dim2(1,0,0,1),AnchorPoint=Vector2.new(0,1),Position=dim2(0,0,1,0),BackgroundColor3=AC,ZIndex=51,Parent=BAR}); onAC(function(c) barLine.BackgroundColor3=c end)
    stroke(BAR,C.br1,1)

    -- Easter egg button (left, hidden)
    local EGG_BTN=mk("TextButton",{Text="🥚",TextColor3=C.t0,TextSize=11,Font=Enum.Font.GothamSemibold,BackgroundColor3=C.bg4,AutomaticSize=Enum.AutomaticSize.X,Size=dim2(0,0,0,BAR_H-6),Position=dim2(0,3,0,3),AutoButtonColor=false,BorderSizePixel=0,ZIndex=52,Visible=false,Parent=BAR})
    corner(EGG_BTN,RC.sharp); stroke(EGG_BTN,C.br0,1); padding(EGG_BTN,0,8,0,8)
    EGG_BTN.MouseEnter:Connect(function() tw(EGG_BTN,{BackgroundColor3=C.bg3},Enum.EasingStyle.Quint,0.1) end)
    EGG_BTN.MouseLeave:Connect(function() tw(EGG_BTN,{BackgroundColor3=C.bg4},Enum.EasingStyle.Quint,0.1) end)

    -- Right buttons: Configs + Settings
    local CFGWIN_BTN=mk("TextButton",{Text="Configs",TextColor3=C.t1,TextSize=10,Font=Enum.Font.GothamSemibold,BackgroundColor3=C.bg4,Size=dim2(0,58,0,BAR_H-6),Position=dim2(1,-128,0,3),AutoButtonColor=false,BorderSizePixel=0,ZIndex=52,Parent=BAR})
    corner(CFGWIN_BTN,RC.sharp); stroke(CFGWIN_BTN,C.br0,1)
    CFGWIN_BTN.MouseEnter:Connect(function() tw(CFGWIN_BTN,{BackgroundColor3=C.bg3,TextColor3=C.t0},Enum.EasingStyle.Quint,0.1) end)
    CFGWIN_BTN.MouseLeave:Connect(function() tw(CFGWIN_BTN,{BackgroundColor3=C.bg4,TextColor3=C.t1},Enum.EasingStyle.Quint,0.1) end)

    local SET_BTN=mk("TextButton",{Text="Settings",TextColor3=C.t1,TextSize=10,Font=Enum.Font.GothamSemibold,BackgroundColor3=C.bg4,Size=dim2(0,62,0,BAR_H-6),Position=dim2(1,-65,0,3),AutoButtonColor=false,BorderSizePixel=0,ZIndex=52,Parent=BAR})
    corner(SET_BTN,RC.sharp); stroke(SET_BTN,C.br0,1)
    SET_BTN.MouseEnter:Connect(function() tw(SET_BTN,{BackgroundColor3=C.bg3,TextColor3=C.t0},Enum.EasingStyle.Quint,0.1) end)
    SET_BTN.MouseLeave:Connect(function() tw(SET_BTN,{BackgroundColor3=C.bg4,TextColor3=C.t1},Enum.EasingStyle.Quint,0.1) end)

    -- Category scroll (centre)
    local CAT_SF=mk("ScrollingFrame",{BackgroundTransparency=1,BorderSizePixel=0,ScrollingDirection=Enum.ScrollingDirection.X,CanvasSize=dim2(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.X,ScrollBarThickness=0,ZIndex=52,Parent=BAR})
    layout(CAT_SF,Enum.FillDirection.Horizontal,3,Enum.HorizontalAlignment.Center,Enum.VerticalAlignment.Center)

    local function repositionBar()
        local eW=EGG_BTN.Visible and (EGG_BTN.AbsoluteSize.X+6) or 2
        CAT_SF.Position=dim2(0,eW+2,0,0); CAT_SF.Size=dim2(1,-(eW+134),1,0)
    end
    repositionBar()
    EGG_BTN:GetPropertyChangedSignal("Visible"):Connect(function() task.defer(repositionBar) end)

    -- ══════════════════════════════════════════════════════════
    -- WATERMARK — 20px tall, shows user + game
    -- ══════════════════════════════════════════════════════════
    local WM=mk("Frame",{Name="Watermark",Size=dim2(0,10,0,20),AutomaticSize=Enum.AutomaticSize.X,Position=dim2(0,8,0,BAR_H+5),BackgroundColor3=rgb(8,8,10),BackgroundTransparency=0.10,BorderSizePixel=0,ZIndex=30,Parent=SG})
    stroke(WM,C.br1,1)
    local wmRow=mk("Frame",{Size=dim2(1,0,1,0),AutomaticSize=Enum.AutomaticSize.X,BackgroundTransparency=1,ZIndex=31,Parent=WM}); padding(wmRow,0,7,0,7)
    layout(wmRow,Enum.FillDirection.Horizontal,0,Enum.HorizontalAlignment.Left,Enum.VerticalAlignment.Center)
    local wmLabels={}
    local function wmSep() mk("TextLabel",{Text=" | ",Size=dim2(0,11,1,0),BackgroundTransparency=1,TextColor3=C.br2,TextSize=10,Font=Enum.Font.Gotham,ZIndex=31,Parent=wmRow}) end
    local function wmLbl(key,txt,bold,colored)
        local lbl=mk("TextLabel",{Text=tostring(txt),Size=dim2(0,0,1,0),AutomaticSize=Enum.AutomaticSize.X,BackgroundTransparency=1,TextColor3=colored and AC or C.t1,TextSize=10,Font=(bold or colored) and Enum.Font.GothamBold or Enum.Font.Gotham,ZIndex=31,Parent=wmRow})
        if colored then onAC(function(c) lbl.TextColor3=c end) end; return lbl
    end
    -- ScriptName [accent] | User | Game[id] | Config | fps | ping
    wmLabels.script=wmLbl("script",CFG.ScriptName,true,true); wmSep()
    wmLabels.user  =wmLbl("user",  CFG.UserName,  false,false); wmSep()
    wmLabels.game  =wmLbl("game",  CFG.GameName.." ["..CFG.GameId.."]",false,false); wmSep()
    wmLabels.config=wmLbl("config",CFG.ConfigName,false,false); wmSep()
    wmLabels.fps   =wmLbl("fps",   "--fps",       false,false); wmSep()
    wmLabels.ping  =wmLbl("ping",  "--ms",        false,false)
    draggify(WM,WM)
    RunService.Heartbeat:Connect(function()
        pcall(function()
            wmLabels.fps.Text  = tostring(_fps).."fps"
            wmLabels.ping.Text = tostring(_ping).."ms"
        end)
    end)

    -- ══════════════════════════════════════════════════════════
    -- MAIN WINDOW
    -- ══════════════════════════════════════════════════════════
    local BG,BG_IMG,mainDragHandle=buildWindow(SG,dim2(0,500,0,380),dim2(0,300,0,BAR_H+30),2,BG_IMAGE,onAC)
    BG.Name="MainWindow"
    task.defer(function()
        local sv=SG.AbsoluteSize; local winW=math.max(math.floor(sv.X*0.33),360); local winH=math.max(math.floor((sv.Y-BAR_H)*0.84),280)
        BG.Size=dim2(0,winW,0,winH); BG.Position=dim2(0,math.floor(sv.X*0.35),0,BAR_H+math.floor((sv.Y-BAR_H)*0.09))
    end)
    draggify(BG,mainDragHandle)

    local CONTENT=mk("ScrollingFrame",{Size=dim2(1,-8,1,-8),Position=dim2(0,4,0,4),BackgroundTransparency=1,ScrollBarThickness=2,ScrollBarImageColor3=AC,CanvasSize=dim2(0,0,0,0),ZIndex=6,Parent=BG_IMG})
    onAC(function(c) CONTENT.ScrollBarImageColor3=c end)
    local contentLL=layout(CONTENT,Enum.FillDirection.Vertical,6); padding(CONTENT,6,4,6,4)
    contentLL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() task.defer(function() if CONTENT and CONTENT.Parent then CONTENT.CanvasSize=dim2(0,0,0,contentLL.AbsoluteContentSize.Y+20) end end) end)

    -- ══════════════════════════════════════════════════════════
    -- SETTINGS WINDOW (no X button — toggled by Settings button)
    -- ══════════════════════════════════════════════════════════
    local SW,SW_IMG,swDragHandle=buildWindow(SG,dim2(0,296,0,380),dim2(.5,-148,.5,-190),100,BG_IMAGE,onAC)
    SW.Name="SettingsWin"; SW.Visible=false
    local SW_HDR=mk("Frame",{Size=dim2(1,0,0,26),BackgroundColor3=rgb(0,0,0),BackgroundTransparency=0.40,ZIndex=104,Parent=SW_IMG})
    local swAcc=mk("Frame",{Size=dim2(1,0,0,1),AnchorPoint=Vector2.new(0,1),Position=dim2(0,0,1,0),BackgroundColor3=AC,ZIndex=105,Parent=SW_HDR}); onAC(function(c) swAcc.BackgroundColor3=c end)
    mk("TextLabel",{Text="⚙  Settings",Size=dim2(1,0,1,0),Position=dim2(0,10,0,0),BackgroundTransparency=1,TextColor3=C.t0,TextSize=11,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=105,Parent=SW_HDR})
    draggify(SW,swDragHandle)
    local SW_SF=mk("ScrollingFrame",{Size=dim2(1,-6,1,-28),Position=dim2(0,3,0,27),BackgroundTransparency=1,ScrollBarThickness=2,ScrollBarImageColor3=AC,CanvasSize=dim2(0,0,0,0),ZIndex=104,Parent=SW_IMG})
    onAC(function(c) SW_SF.ScrollBarImageColor3=c end)
    local swLL=layout(SW_SF,Enum.FillDirection.Vertical,5); padding(SW_SF,6,6,6,6)
    swLL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() task.defer(function() if SW_SF and SW_SF.Parent then SW_SF.CanvasSize=dim2(0,0,0,swLL.AbsoluteContentSize.Y+14) end end) end)

    -- Settings helpers
    local function swSection(title)
        local f=mk("Frame",{Size=dim2(1,0,0,15),BackgroundColor3=rgb(0,0,0),BackgroundTransparency=0.52,ZIndex=105,Parent=SW_SF}); padding(f,0,0,0,5)
        local lbl=mk("TextLabel",{Text=title:upper(),Size=dim2(1,-5,1,0),BackgroundTransparency=1,TextColor3=AC,TextSize=9,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=106,Parent=f}); onAC(function(c) lbl.TextColor3=c end)
    end
    local function swRow(h) local r=mk("Frame",{Size=dim2(1,0,0,h or 24),BackgroundColor3=C.bg3,BackgroundTransparency=0.38,ZIndex=105,Parent=SW_SF}); corner(r,RC.soft); return r end
    local function swToggle(lbl_text,default,onChange)
        local r=swRow(24); mk("TextLabel",{Text=lbl_text,Size=dim2(1,-46,1,0),Position=dim2(0,6,0,0),BackgroundTransparency=1,TextColor3=C.t1,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=106,Parent=r})
        local val=default==true; local track=mk("Frame",{Size=dim2(0,30,0,13),Position=dim2(1,-34,.5,-6.5),BackgroundColor3=val and AC or C.bg4,ZIndex=106,Parent=r}); corner(track,RC.pill)
        local knob=mk("Frame",{Size=dim2(0,10,0,10),Position=val and dim2(1,-12,.5,-5) or dim2(0,2,.5,-5),BackgroundColor3=C.t0,ZIndex=107,Parent=track}); corner(knob,RC.pill)
        onAC(function(c) if val then track.BackgroundColor3=c end end)
        local tbtn=mk("TextButton",{Size=dim2(1,0,1,0),BackgroundTransparency=1,Text="",AutoButtonColor=false,ZIndex=108,Parent=r})
        tbtn.MouseButton1Click:Connect(function() val=not val; tw(track,{BackgroundColor3=val and AC or C.bg4},Enum.EasingStyle.Quint,0.18); tw(knob,{Position=val and dim2(1,-12,.5,-5) or dim2(0,2,.5,-5)},Enum.EasingStyle.Back,0.2); if onChange then onChange(val) end end)
        return {Get=function() return val end}
    end
    local function swButton(txt,cb)
        local r=swRow(24); local lbl=mk("TextLabel",{Text=txt,Size=dim2(1,0,1,0),BackgroundTransparency=1,TextColor3=C.t1,TextSize=11,Font=Enum.Font.GothamSemibold,ZIndex=106,Parent=r})
        local hb=mk("TextButton",{Text="",Size=dim2(1,0,1,0),BackgroundTransparency=1,AutoButtonColor=false,ZIndex=107,Parent=r})
        hb.MouseEnter:Connect(function() tw(r,{BackgroundTransparency=0.15},Enum.EasingStyle.Quint,0.1); tw(lbl,{TextColor3=C.t0},Enum.EasingStyle.Quint,0.1) end)
        hb.MouseLeave:Connect(function() tw(r,{BackgroundTransparency=0.38},Enum.EasingStyle.Quint,0.1); tw(lbl,{TextColor3=C.t1},Enum.EasingStyle.Quint,0.1) end)
        hb.MouseButton1Click:Connect(function() tw(lbl,{TextColor3=AC},Enum.EasingStyle.Quint,0.08); task.delay(0.15,function() tw(lbl,{TextColor3=C.t1},Enum.EasingStyle.Quint,0.12) end); if cb then cb() end end); return r
    end
    local function swColorRow(lbl_text,defCol,onChange)
        local r=swRow(24); mk("TextLabel",{Text=lbl_text,Size=dim2(1,-42,1,0),Position=dim2(0,6,0,0),BackgroundTransparency=1,TextColor3=C.t1,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=106,Parent=r})
        local col=defCol; local h,s,v=Color3.toHSV(col); local sw2=mk("TextButton",{Size=dim2(0,30,0,16),Position=dim2(1,-34,.5,-8),BackgroundColor3=col,Text="",AutoButtonColor=false,ZIndex=106,Parent=r}); corner(sw2,RC.soft); stroke(sw2,C.br2,1)
        local openPick=false; sw2.MouseButton1Click:Connect(function() openPick=not openPick; if openPick then openOV(function(ov) buildColorPicker(ov,sw2,h,s,v,function(nc,nh,ns,nv) col=nc;h,s,v=nh,ns,nv;sw2.BackgroundColor3=nc; if onChange then onChange(nc) end end,SG) end) else closeOV() end end)
        return {Get=function() return col end}
    end

    swSection("Appearance")
    swColorRow("Accent Color",AC,function(c) AC=c;fireAC() end)
    swColorRow("Background Tint",C.bg0,function(c) BG.BackgroundColor3=c;SW.BackgroundColor3=c end)
    swSection("Watermark")
    swToggle("Show Watermark",true,function(v) CFG.ShowWM=v;WM.Visible=v end)
    swSection("Copy")
    swButton("Copy Username",    function() pcall(function() setclipboard(LP.Name) end);               notify({Title="Copied",Desc="Username copied.",Type="Success",Duration=2}) end)
    swButton("Copy User ID",     function() pcall(function() setclipboard(tostring(LP.UserId)) end);   notify({Title="Copied",Desc="User ID copied.",Type="Success",Duration=2}) end)
    swButton("Copy Game ID",     function() pcall(function() setclipboard(tostring(game.GameId)) end); notify({Title="Copied",Desc="Game ID copied.",Type="Success",Duration=2}) end)
    swSection("Danger Zone")
    local unloadRow=swRow(26); unloadRow.BackgroundColor3=rgb(36,12,12); unloadRow.BackgroundTransparency=0.28
    mk("TextLabel",{Text="Unload Script",Size=dim2(1,0,1,0),BackgroundTransparency=1,TextColor3=rgb(215,55,55),TextSize=12,Font=Enum.Font.GothamBold,ZIndex=106,Parent=unloadRow})
    local unloadBtn=mk("TextButton",{Size=dim2(1,0,1,0),BackgroundTransparency=1,Text="",AutoButtonColor=false,ZIndex=107,Parent=unloadRow})
    unloadBtn.MouseEnter:Connect(function() tw(unloadRow,{BackgroundTransparency=0.08},Enum.EasingStyle.Quint,0.1) end)
    unloadBtn.MouseLeave:Connect(function() tw(unloadRow,{BackgroundTransparency=0.28},Enum.EasingStyle.Quint,0.1) end)
    unloadBtn.MouseButton1Click:Connect(function() notify({Title="Unloading",Desc="Removing script...",Type="Warning",Duration=2}); task.delay(.5,function() pcall(function() SG:Destroy() end) end) end)

    SET_BTN.MouseButton1Click:Connect(function()
        SW.Visible=not SW.Visible
        if SW.Visible then CFGW.Visible=false end
    end)

    -- ══════════════════════════════════════════════════════════
    -- CONFIG MANAGER WINDOW
    -- ══════════════════════════════════════════════════════════
    local CFGW,CFGW_IMG,cfgwDragHandle=buildWindow(SG,dim2(0,276,0,360),dim2(.5,-290,.5,-180),110,BG_IMAGE,onAC)
    CFGW.Name="ConfigWin"; CFGW.Visible=false

    local CFGW_HDR=mk("Frame",{Size=dim2(1,0,0,26),BackgroundColor3=rgb(0,0,0),BackgroundTransparency=0.40,ZIndex=114,Parent=CFGW_IMG})
    local cfgAcc=mk("Frame",{Size=dim2(1,0,0,1),AnchorPoint=Vector2.new(0,1),Position=dim2(0,0,1,0),BackgroundColor3=AC,ZIndex=115,Parent=CFGW_HDR}); onAC(function(c) cfgAcc.BackgroundColor3=c end)
    mk("TextLabel",{Text="📁  Configs  —  "..CFG.ScriptName,Size=dim2(1,0,1,0),Position=dim2(0,10,0,0),BackgroundTransparency=1,TextColor3=C.t0,TextSize=11,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=115,Parent=CFGW_HDR})
    draggify(CFGW,cfgwDragHandle)

    -- Toolbar row: [text input] [+ Create] [📂]
    local cfgToolRow=mk("Frame",{Size=dim2(1,0,0,28),Position=dim2(0,0,0,26),BackgroundColor3=rgb(0,0,0),BackgroundTransparency=0.60,ZIndex=114,Parent=CFGW_IMG})
    padding(cfgToolRow,4,4,4,4); layout(cfgToolRow,Enum.FillDirection.Horizontal,4,Enum.HorizontalAlignment.Left,Enum.VerticalAlignment.Center)

    -- Name input
    local newCfgFrame=mk("Frame",{Size=dim2(1,-90,0,20),BackgroundColor3=C.bg4,ZIndex=115,Parent=cfgToolRow}); corner(newCfgFrame,RC.sharp); stroke(newCfgFrame,C.br0,1)
    local newCfgTB=mk("TextBox",{PlaceholderText="config name...",Text="",Size=dim2(1,-6,1,0),BackgroundTransparency=1,TextColor3=C.t0,PlaceholderColor3=C.t2,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false,ZIndex=116,Parent=newCfgFrame}); padding(newCfgTB,0,3,0,4)

    local function cfgToolBtn(txt,w,cb)
        local b=mk("TextButton",{Text=txt,Size=dim2(0,w,0,20),BackgroundColor3=C.bg4,TextColor3=C.t1,TextSize=10,Font=Enum.Font.GothamSemibold,AutoButtonColor=false,ZIndex=115,Parent=cfgToolRow}); corner(b,RC.sharp); stroke(b,C.br0,1)
        b.MouseEnter:Connect(function() tw(b,{BackgroundColor3=C.bg3,TextColor3=C.t0},Enum.EasingStyle.Quint,0.1) end)
        b.MouseLeave:Connect(function() tw(b,{BackgroundColor3=C.bg4,TextColor3=C.t1},Enum.EasingStyle.Quint,0.1) end)
        b.MouseButton1Click:Connect(cb); return b
    end

    -- Separator below toolbar
    local cfgSep=mk("Frame",{Size=dim2(1,0,0,1),Position=dim2(0,0,0,54),BackgroundColor3=C.br1,ZIndex=114,Parent=CFGW_IMG})

    -- Config list scroll
    local CFGW_SF=mk("ScrollingFrame",{Size=dim2(1,-6,1,-57),Position=dim2(0,3,0,56),BackgroundTransparency=1,ScrollBarThickness=2,ScrollBarImageColor3=AC,CanvasSize=dim2(0,0,0,0),ZIndex=114,Parent=CFGW_IMG})
    onAC(function(c) CFGW_SF.ScrollBarImageColor3=c end)
    local cfgwLL=layout(CFGW_SF,Enum.FillDirection.Vertical,4); padding(CFGW_SF,4,4,4,4)
    cfgwLL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() task.defer(function() if CFGW_SF and CFGW_SF.Parent then CFGW_SF.CanvasSize=dim2(0,0,0,cfgwLL.AbsoluteContentSize.Y+10) end end) end)

    local function refreshCfgList()
        for _,ch in ipairs(CFGW_SF:GetChildren()) do if not ch:IsA("UIListLayout") and not ch:IsA("UIPadding") then ch:Destroy() end end
        local list=CFGSYS.list()
        if #list==0 then
            mk("TextLabel",{Text="No configs yet.\nType a name above and press + Create.",Size=dim2(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,TextColor3=C.t2,TextSize=10,Font=Enum.Font.Gotham,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=115,Parent=CFGW_SF}); return
        end
        for _,name in ipairs(list) do
            local row=mk("Frame",{Size=dim2(1,0,0,30),BackgroundColor3=C.bg3,BackgroundTransparency=0.38,ZIndex=115,Parent=CFGW_SF}); corner(row,RC.sharp)
            mk("TextLabel",{Text=name,Size=dim2(1,-118,1,0),Position=dim2(0,8,0,0),BackgroundTransparency=1,TextColor3=C.t1,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=116,Parent=row})
            -- Load
            local loadBtn=mk("TextButton",{Text="Load",Size=dim2(0,36,0,20),Position=dim2(1,-112,.5,-10),BackgroundColor3=C.bg4,TextColor3=AC,TextSize=9,Font=Enum.Font.GothamBold,AutoButtonColor=false,ZIndex=116,Parent=row}); corner(loadBtn,RC.sharp); stroke(loadBtn,C.br0,1)
            onAC(function(c) loadBtn.TextColor3=c end)
            loadBtn.MouseEnter:Connect(function() tw(loadBtn,{BackgroundColor3=C.bg3},Enum.EasingStyle.Quint,0.1) end)
            loadBtn.MouseLeave:Connect(function() tw(loadBtn,{BackgroundColor3=C.bg4},Enum.EasingStyle.Quint,0.1) end)
            loadBtn.MouseButton1Click:Connect(function()
                if CFGSYS.load(name) then CFG.ConfigName=name;wmLabels.config.Text=name; notify({Title="Loaded",Desc=name,Type="Success",Duration=2})
                else notify({Title="Load Failed",Desc="Could not read "..name,Type="Error",Duration=3}) end
            end)
            -- Save
            local saveBtn=mk("TextButton",{Text="Save",Size=dim2(0,36,0,20),Position=dim2(1,-72,.5,-10),BackgroundColor3=C.bg4,TextColor3=C.t1,TextSize=9,Font=Enum.Font.GothamBold,AutoButtonColor=false,ZIndex=116,Parent=row}); corner(saveBtn,RC.sharp); stroke(saveBtn,C.br0,1)
            saveBtn.MouseEnter:Connect(function() tw(saveBtn,{BackgroundColor3=C.bg3,TextColor3=C.t0},Enum.EasingStyle.Quint,0.1) end)
            saveBtn.MouseLeave:Connect(function() tw(saveBtn,{BackgroundColor3=C.bg4,TextColor3=C.t1},Enum.EasingStyle.Quint,0.1) end)
            saveBtn.MouseButton1Click:Connect(function()
                if CFGSYS.save(name) then notify({Title="Saved",Desc=name.." updated.",Type="Success",Duration=2})
                else notify({Title="Save Failed",Type="Error",Duration=2}) end
            end)
            -- Delete
            local delBtn=mk("TextButton",{Text="Del",Size=dim2(0,28,0,20),Position=dim2(1,-32,.5,-10),BackgroundColor3=rgb(36,12,12),TextColor3=rgb(200,60,60),TextSize=9,Font=Enum.Font.GothamBold,AutoButtonColor=false,ZIndex=116,Parent=row}); corner(delBtn,RC.sharp); stroke(delBtn,C.br0,1)
            delBtn.MouseEnter:Connect(function() tw(delBtn,{BackgroundColor3=rgb(54,16,16)},Enum.EasingStyle.Quint,0.1) end)
            delBtn.MouseLeave:Connect(function() tw(delBtn,{BackgroundColor3=rgb(36,12,12)},Enum.EasingStyle.Quint,0.1) end)
            delBtn.MouseButton1Click:Connect(function() CFGSYS.delete(name); refreshCfgList(); notify({Title="Deleted",Desc=name.." removed.",Type="Warning",Duration=2}) end)
        end
    end

    cfgToolBtn("+ Create",54,function()
        local name=(newCfgTB.Text~="" and newCfgTB.Text) or ("Config"..tostring(#CFGSYS.list()+1))
        newCfgTB.Text=""
        local ok2=CFGSYS.save(name)
        if ok2 then notify({Title="Created",Desc=name,Type="Success",Duration=2}); refreshCfgList()
        else notify({Title="Create Failed",Desc="Check executor file permissions.",Type="Error",Duration=3}) end
    end)
    cfgToolBtn("📂",26,function()
        CFGSYS.openDir()
        notify({Title="Configs Folder",Desc=CFGSYS.dir,Type="Info",Duration=3})
    end)

    CFGWIN_BTN.MouseButton1Click:Connect(function()
        CFGW.Visible=not CFGW.Visible
        if CFGW.Visible then SW.Visible=false; refreshCfgList() end
    end)

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
                    if ok2 and tx then local lo=tx:lower(); for _,kw in ipairs(EASTER_KW) do if lo:find(kw,1,true) then found=true;return end end end
                    for _,c2 in ipairs(inst:GetChildren()) do scan(c2,d+1) end
                end
                pcall(function() scan(LP.PlayerGui,0) end)
                if found and not EGG_BTN.Visible then EGG_BTN.Visible=true; task.defer(repositionBar); notify({Title="🥚 Easter Egg",Desc="Something secret was found.",Type="Warning",Duration=5}) end
            end)
        end
    end)

    EGG_BTN.MouseButton1Click:Connect(function()
        if _eggActive then return end; _eggActive=true
        local imgPath=EASTER_IMGS[math.random(1,#EASTER_IMGS)]; local loadedAsset=""
        task.spawn(function() loadedAsset=loadImage(imgPath) end)
        local ov3=mk("Frame",{Size=dim2(1,0,1,0),BackgroundColor3=rgb(0,0,0),BackgroundTransparency=0.45,ZIndex=500,Parent=SG})
        local eggOuter=mk("Frame",{Size=dim2(0,300,0,224),Position=dim2(.5,-150,.5,-112),BackgroundColor3=rgb(8,8,10),ZIndex=501,Parent=ov3})
        local eggStroke=stroke(eggOuter,AC,2); onAC(function(c) eggStroke.Color=c end)
        local eggImg=mk("ImageLabel",{BackgroundColor3=rgb(6,6,8),AnchorPoint=Vector2.new(.5,.5),Image=BG_IMAGE,Size=dim2(1,-4,1,-4),Position=dim2(.5,0,.5,0),ZIndex=502,Parent=eggOuter}); corner(eggImg,RC.soft)
        mk("Frame",{Size=dim2(1,0,1,0),BackgroundColor3=rgb(0,0,0),BackgroundTransparency=0.35,ZIndex=503,Parent=eggImg})
        local eHdr=mk("Frame",{Size=dim2(1,0,0,26),BackgroundColor3=rgb(0,0,0),BackgroundTransparency=0.40,ZIndex=504,Parent=eggImg})
        local eAcc=mk("Frame",{Size=dim2(1,0,0,1),AnchorPoint=Vector2.new(0,1),Position=dim2(0,0,1,0),BackgroundColor3=AC,ZIndex=505,Parent=eHdr}); onAC(function(c) eAcc.BackgroundColor3=c end)
        mk("TextLabel",{Text="🥚  EASTER EGG",Size=dim2(1,-30,1,0),Position=dim2(0,10,0,0),BackgroundTransparency=1,TextColor3=AC,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=505,Parent=eHdr})
        local eClose=mk("TextButton",{Text="✕",Size=dim2(0,20,0,18),Position=dim2(1,-23,0,4),BackgroundColor3=rgb(48,16,16),TextColor3=rgb(220,80,80),TextSize=10,Font=Enum.Font.GothamBold,AutoButtonColor=false,ZIndex=506,Parent=eHdr}); corner(eClose,RC.sharp)
        local eImgDisplay=mk("ImageLabel",{Size=dim2(1,-16,0,132),Position=dim2(0,8,0,34),BackgroundColor3=C.bg4,BackgroundTransparency=0.5,Image="",ZIndex=504,Parent=eggImg}); corner(eImgDisplay,RC.soft); stroke(eImgDisplay,C.br1,1)
        local loadLbl=mk("TextLabel",{Text="Loading...",Size=dim2(1,0,1,0),BackgroundTransparency=1,TextColor3=C.t2,TextSize=11,Font=Enum.Font.Gotham,ZIndex=505,Parent=eImgDisplay})
        task.spawn(function() for i=1,20 do task.wait(0.3); if loadedAsset~="" then eImgDisplay.Image=loadedAsset;loadLbl.Visible=false;break end end end)
        mk("TextLabel",{Text="📁  ".._DIR.."/eggs/",Size=dim2(1,-16,0,20),Position=dim2(0,8,0,172),BackgroundTransparency=1,TextColor3=C.t2,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=504,Parent=eggImg})
        local function closeEgg() tw(ov3,{BackgroundTransparency=1},Enum.EasingStyle.Quint,0.2);task.wait(.22);pcall(function() ov3:Destroy() end);_eggActive=false end
        eClose.MouseButton1Click:Connect(closeEgg)
        local bdClose=mk("TextButton",{Size=dim2(1,0,1,0),BackgroundTransparency=1,Text="",AutoButtonColor=false,ZIndex=500,Parent=ov3}); bdClose.MouseButton1Click:Connect(closeEgg)
    end)

    -- ══════════════════════════════════════════════════════════
    -- KEY TOGGLE
    -- ══════════════════════════════════════════════════════════
    local _vis=true
    UIS.InputBegan:Connect(function(i,gpe)
        if not gpe and i.KeyCode==KEY then _vis=not _vis; BG.Visible=_vis; BAR.Visible=_vis; if not _vis then SW.Visible=false;CFGW.Visible=false end end
    end)

    -- ══════════════════════════════════════════════════════════
    -- WINDOW OBJECT
    -- ══════════════════════════════════════════════════════════
    local WO={_categories={},_activeCat=nil,Notify=notify,_cfgsys=CFGSYS}

    function WO:AddCategory(name)
        local isFirst=#self._categories==0
        local catBtn=mk("TextButton",{Text=name,Size=dim2(0,0,0,BAR_H-6),AutomaticSize=Enum.AutomaticSize.X,Position=dim2(0,0,0,3),BackgroundColor3=isFirst and AC or C.bg4,TextColor3=isFirst and C.t0 or C.t2,TextSize=10,Font=Enum.Font.GothamSemibold,AutoButtonColor=false,BorderSizePixel=0,ZIndex=53,LayoutOrder=#self._categories+1,Parent=CAT_SF})
        padding(catBtn,0,10,0,10); corner(catBtn,RC.sharp); stroke(catBtn,C.br0,1)
        onAC(function(c) if self._activeCat==CAT then catBtn.BackgroundColor3=c end end)
        local catPanel=mk("Frame",{Size=dim2(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Visible=isFirst,ZIndex=6,Parent=CONTENT}); layout(catPanel,Enum.FillDirection.Vertical,5)
        local CAT={_name=name,_btn=catBtn,_panel=catPanel,_win=self}; table.insert(self._categories,CAT); if isFirst then self._activeCat=CAT end

        local function activateCat()
            if self._activeCat==CAT then return end; local old=self._activeCat
            if old then old._panel.Visible=false; tw(old._btn,{BackgroundColor3=C.bg4,TextColor3=C.t2},Enum.EasingStyle.Quint,0.15) end
            catPanel.Visible=true; tw(catBtn,{BackgroundColor3=AC,TextColor3=C.t0},Enum.EasingStyle.Quint,0.15); self._activeCat=CAT
        end
        catBtn.MouseButton1Click:Connect(activateCat)
        catBtn.MouseEnter:Connect(function() if self._activeCat~=CAT then tw(catBtn,{BackgroundColor3=C.bg3,TextColor3=C.t1},Enum.EasingStyle.Quint,0.1) end end)
        catBtn.MouseLeave:Connect(function() if self._activeCat~=CAT then tw(catBtn,{BackgroundColor3=C.bg4,TextColor3=C.t2},Enum.EasingStyle.Quint,0.1) end end)

        local function mkRow(h) local r=mk("Frame",{Size=dim2(1,0,0,h or 30),BackgroundColor3=C.bg2,BackgroundTransparency=0.42,ZIndex=6,Parent=catPanel}); corner(r,RC.sharp); stroke(r,C.br0,1); return r end
        local KEYS_SHORT={[Enum.KeyCode.LeftShift]="LSH",[Enum.KeyCode.RightShift]="RSH",[Enum.KeyCode.LeftControl]="LCT",[Enum.KeyCode.RightControl]="RCT",[Enum.KeyCode.Insert]="INS",[Enum.KeyCode.Backspace]="BS",[Enum.KeyCode.Return]="ENT",[Enum.KeyCode.CapsLock]="CAP",[Enum.KeyCode.Escape]="ESC",[Enum.KeyCode.Space]="SPC"}
        local function keyName(k) if not k or k==Enum.KeyCode.Unknown then return "NONE" end; return KEYS_SHORT[k] or tostring(k):gsub("Enum%.KeyCode%.",""):gsub("Enum%.UserInputType%.","") end

        function CAT:AddButton(o5)
            o5=o5 or {}; local nm=o5.Name or "Button"; local cb=o5.Callback or function() end; local row=mkRow(30)
            local face=mk("Frame",{Size=dim2(1,-8,0,22),Position=dim2(0,4,0,4),BackgroundColor3=C.bg4,ZIndex=7,Parent=row}); corner(face,RC.soft); stroke(face,C.br1,1)
            local lbl=mk("TextLabel",{Text=nm,Size=dim2(1,0,1,0),BackgroundTransparency=1,TextColor3=C.t1,TextSize=12,Font=Enum.Font.GothamSemibold,ZIndex=8,Parent=face})
            local pip=mk("Frame",{Size=dim2(0,2,0,14),Position=dim2(0,0,.5,-7),BackgroundColor3=AC,BackgroundTransparency=1,ZIndex=8,Parent=face}); onAC(function(c) pip.BackgroundColor3=c end); corner(pip,RC.pill)
            local hbtn=mk("TextButton",{Size=dim2(1,0,1,0),BackgroundTransparency=1,Text="",AutoButtonColor=false,ZIndex=9,Parent=face})
            hbtn.MouseEnter:Connect(function() tw(face,{BackgroundColor3=C.bg3},Enum.EasingStyle.Quint,0.12);tw(lbl,{TextColor3=C.t0},Enum.EasingStyle.Quint,0.12);tw(pip,{BackgroundTransparency=0},Enum.EasingStyle.Quint,0.12) end)
            hbtn.MouseLeave:Connect(function() tw(face,{BackgroundColor3=C.bg4},Enum.EasingStyle.Quint,0.12);tw(lbl,{TextColor3=C.t1},Enum.EasingStyle.Quint,0.12);tw(pip,{BackgroundTransparency=1},Enum.EasingStyle.Quint,0.12) end)
            hbtn.MouseButton1Click:Connect(function() tw(face,{BackgroundColor3=AC},Enum.EasingStyle.Quint,0.07);tw(lbl,{TextColor3=C.bg0},Enum.EasingStyle.Quint,0.07);task.delay(0.18,function() tw(face,{BackgroundColor3=C.bg4},Enum.EasingStyle.Quint,0.18);tw(lbl,{TextColor3=C.t1},Enum.EasingStyle.Quint,0.18) end);pcall(cb) end)
            local r={}; function r:SetText(t) lbl.Text=t end; return r
        end

        function CAT:AddLabel(o5)
            o5=o5 or {}
            local lbl=mk("TextLabel",{Text=o5.Text or "",Size=dim2(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=C.bg2,BackgroundTransparency=0.42,TextColor3=o5.Color or C.t2,TextSize=o5.Size or 11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,ZIndex=6,Parent=catPanel}); corner(lbl,RC.sharp); stroke(lbl,C.br0,1); padding(lbl,4,8,4,8)
            local r={}; function r:Set(t) lbl.Text=t end; function r:Get() return lbl.Text end; return r
        end

        function CAT:AddToggle(o5)
            o5=o5 or {}; local nm=o5.Name or "Toggle"; local val=o5.Default==true; local cb=o5.Callback or function() end; local flag=o5.Flag
            local hasKB=o5.Keybind~=nil; local kbMode="Toggle"; local kbKey=o5.Keybind or Enum.KeyCode.Unknown; local listening=false; local holding=false
            local row=mkRow(hasKB and 32 or 30)
            mk("TextLabel",{Text=nm,Size=dim2(1,-(hasKB and 150 or 58),1,0),Position=dim2(0,8,0,0),BackgroundTransparency=1,TextColor3=C.t1,TextSize=12,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=7,Parent=row})
            local track=mk("Frame",{Size=dim2(0,34,0,16),Position=dim2(1,-38,.5,-8),BackgroundColor3=val and AC or C.bg4,ZIndex=7,Parent=row}); corner(track,RC.pill); stroke(track,C.br1,1)
            local knob=mk("Frame",{Size=dim2(0,12,0,12),Position=val and dim2(1,-14,.5,-6) or dim2(0,2,.5,-6),BackgroundColor3=C.t0,ZIndex=8,Parent=track}); corner(knob,RC.pill)
            onAC(function(c) if val then track.BackgroundColor3=c end end)
            local trackHit=mk("TextButton",{Size=dim2(0,34,0,16),Position=dim2(1,-38,.5,-8),BackgroundTransparency=1,Text="",AutoButtonColor=false,ZIndex=9,Parent=row})
            local kbBtn,modeBtn
            if hasKB then
                modeBtn=mk("TextButton",{Text="T",Size=dim2(0,16,0,15),Position=dim2(1,-148,.5,-7.5),BackgroundColor3=C.bg4,TextColor3=C.t2,TextSize=8,Font=Enum.Font.GothamBold,AutoButtonColor=false,ZIndex=7,Parent=row}); corner(modeBtn,RC.sharp); stroke(modeBtn,C.br0,1)
                local modeOrder={"Toggle","Hold","Always"}; local modeAbbr={Toggle="T",Hold="H",Always="A"}
                modeBtn.MouseButton2Click:Connect(function() local ci=1; for i,m in ipairs(modeOrder) do if m==kbMode then ci=i break end end; kbMode=modeOrder[(ci%#modeOrder)+1]; modeBtn.Text=modeAbbr[kbMode]; notify({Title="Mode",Desc=nm..": "..kbMode,Type="Info",Duration=2}) end)
                kbBtn=mk("TextButton",{Text=keyName(kbKey),Size=dim2(0,58,0,15),Position=dim2(1,-124,.5,-7.5),BackgroundColor3=C.bg4,TextColor3=AC,TextSize=9,Font=Enum.Font.GothamBold,AutoButtonColor=false,ZIndex=7,Parent=row}); corner(kbBtn,RC.sharp); stroke(kbBtn,C.br0,1)
                onAC(function(c) if not listening then kbBtn.TextColor3=c end end)
                kbBtn.MouseButton1Click:Connect(function() if listening then return end; listening=true;kbBtn.Text="...";kbBtn.TextColor3=rgb(255,185,0);kbBtn.BackgroundColor3=rgb(28,24,10) end)
            end
            local function set(v,silent)
                val=v; tw(track,{BackgroundColor3=v and AC or C.bg4},Enum.EasingStyle.Quint,0.18); tw(knob,{Position=v and dim2(1,-14,.5,-6) or dim2(0,2,.5,-6)},Enum.EasingStyle.Back,0.22)
                if not silent then pcall(cb,v) end; if flag then _G[flag]=v end
            end
            trackHit.MouseButton1Click:Connect(function() set(not val) end)
            if hasKB then
                UIS.InputBegan:Connect(function(i,gpe)
                    if listening and not gpe and i.UserInputType==Enum.UserInputType.Keyboard then kbKey=i.KeyCode;kbBtn.Text=keyName(kbKey);kbBtn.TextColor3=AC;kbBtn.BackgroundColor3=C.bg4;listening=false
                    elseif not listening and not gpe and i.KeyCode==kbKey and kbKey~=Enum.KeyCode.Unknown then
                        if kbMode=="Toggle" then set(not val) elseif kbMode=="Hold" then holding=true;set(true) elseif kbMode=="Always" then set(true) end
                    end
                end)
                UIS.InputEnded:Connect(function(i) if holding and i.KeyCode==kbKey and kbMode=="Hold" then holding=false;set(false) end end)
            end
            if flag then _G[flag]=val; CFGSYS.register(flag,function() return val end,function(v) set(v,true) end,"bool") end
            local r={Value=val}; function r:Set(v) set(v,true) end; function r:Get() return val end; return r
        end

        function CAT:AddSlider(o5)
            o5=o5 or {}; local nm=o5.Name or "Slider"; local mn=o5.Min or 0; local mx=o5.Max or 100; local step=o5.Step or 1; local suf=o5.Suffix or ""; local flag=o5.Flag; local cb=o5.Callback or function() end; local val=math.clamp(o5.Default or mn,mn,mx)
            local wrap=mk("Frame",{Size=dim2(1,0,0,48),BackgroundColor3=C.bg2,BackgroundTransparency=0.42,ZIndex=6,Parent=catPanel}); corner(wrap,RC.sharp); stroke(wrap,C.br0,1)
            local top=mk("Frame",{Size=dim2(1,-8,0,20),Position=dim2(0,4,0,4),BackgroundTransparency=1,ZIndex=7,Parent=wrap})
            mk("TextLabel",{Text=nm,Size=dim2(1,-60,1,0),BackgroundTransparency=1,TextColor3=C.t1,TextSize=12,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=8,Parent=top})
            local vbg=mk("Frame",{Size=dim2(0,52,0,17),Position=dim2(1,-54,.5,-8.5),BackgroundColor3=C.bg4,ZIndex=8,Parent=top}); corner(vbg,RC.soft); stroke(vbg,C.br1,1)
            local vLbl=mk("TextLabel",{Text=tostring(val)..suf,Size=dim2(1,0,1,0),BackgroundTransparency=1,TextColor3=C.t2,TextSize=11,Font=Enum.Font.GothamSemibold,ZIndex=9,Parent=vbg})
            local trackArea=mk("TextButton",{Size=dim2(1,-8,0,18),Position=dim2(0,4,0,26),BackgroundTransparency=1,Text="",AutoButtonColor=false,ZIndex=9,Parent=wrap})
            local trackBg=mk("Frame",{Size=dim2(1,0,0,4),Position=dim2(0,0,.5,-2),BackgroundColor3=C.bg4,ZIndex=7,Parent=trackArea}); corner(trackBg,RC.pill)
            local pct=(val-mn)/(mx-mn); local fill=mk("Frame",{Size=dim2(pct,0,1,0),BackgroundColor3=AC,ZIndex=8,Parent=trackBg}); corner(fill,RC.pill); onAC(function(c) fill.BackgroundColor3=c end)
            local kn=mk("Frame",{AnchorPoint=Vector2.new(.5,.5),Size=dim2(0,13,0,13),Position=dim2(pct,0,.5,0),BackgroundColor3=C.t0,ZIndex=10,Parent=trackBg}); corner(kn,RC.pill); stroke(kn,C.br2,1)
            trackArea.MouseEnter:Connect(function() tw(kn,{Size=dim2(0,15,0,15)},Enum.EasingStyle.Back,0.15) end); trackArea.MouseLeave:Connect(function() tw(kn,{Size=dim2(0,13,0,13)},Enum.EasingStyle.Quint,0.12) end)
            local function sv(v,silent) v=math.clamp(math.round(v/step)*step,mn,mx);val=v;local p=(v-mn)/(mx-mn); tw(fill,{Size=dim2(p,0,1,0)},Enum.EasingStyle.Linear,0.04);tw(kn,{Position=dim2(p,0,.5,0)},Enum.EasingStyle.Linear,0.04); vLbl.Text=tostring(v)..suf;tw(vLbl,{TextColor3=C.t0},Enum.EasingStyle.Quint,0.08); if not silent then pcall(cb,v) end; if flag then _G[flag]=v end end
            local dragging=false
            trackArea.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true;sv(mn+(mx-mn)*math.clamp((i.Position.X-trackBg.AbsolutePosition.X)/trackBg.AbsoluteSize.X,0,1)) end end)
            UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then sv(mn+(mx-mn)*math.clamp((i.Position.X-trackBg.AbsolutePosition.X)/trackBg.AbsoluteSize.X,0,1)) end end)
            UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false;tw(vLbl,{TextColor3=C.t2},Enum.EasingStyle.Quint,0.25) end end)
            if flag then _G[flag]=val; CFGSYS.register(flag,function() return val end,function(v) sv(v,true) end,"number") end
            local r={Value=val}; function r:Set(v) sv(v,true) end; function r:Get() return val end; return r
        end

        -- No OK button — FocusLost fires callback automatically
        function CAT:AddTextbox(o5)
            o5=o5 or {}; local nm=o5.Name or "Input"; local cb=o5.Callback or function() end; local flag=o5.Flag
            local wrap=mk("Frame",{Size=dim2(1,0,0,48),BackgroundColor3=C.bg2,BackgroundTransparency=0.42,ZIndex=6,Parent=catPanel}); corner(wrap,RC.sharp); stroke(wrap,C.br0,1)
            mk("TextLabel",{Text=nm,Size=dim2(1,-8,0,14),Position=dim2(0,6,0,4),BackgroundTransparency=1,TextColor3=C.t2,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=7,Parent=wrap})
            local ifrm=mk("Frame",{Size=dim2(1,-8,0,24),Position=dim2(0,4,0,20),BackgroundColor3=C.bg4,ZIndex=7,Parent=wrap}); corner(ifrm,RC.soft); local sk=stroke(ifrm,C.br1,1)
            local tb=mk("TextBox",{PlaceholderText=o5.Placeholder or "type here...",Text=o5.Default or "",Size=dim2(1,-8,1,0),Position=dim2(0,5,0,0),BackgroundTransparency=1,TextColor3=C.t0,PlaceholderColor3=C.t2,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false,ZIndex=8,Parent=ifrm})
            tb.Focused:Connect(function() tw(sk,{Color=AC},Enum.EasingStyle.Quint,0.12) end)
            tb.FocusLost:Connect(function() tw(sk,{Color=C.br1},Enum.EasingStyle.Quint,0.12); pcall(cb,tb.Text); if flag then _G[flag]=tb.Text end end)
            if flag then _G[flag]=o5.Default or ""; CFGSYS.register(flag,function() return tb.Text end,function(v) tb.Text=tostring(v) end,"string") end
            local r={}; function r:Set(v) tb.Text=v end; function r:Get() return tb.Text end; return r
        end

        function CAT:AddDropdown(o5)
            o5=o5 or {}; local nm=o5.Name or "Dropdown"; local opts=o5.Options or {}; local multi=o5.Multi or false; local flag=o5.Flag; local cb=o5.Callback or function() end; local sel=o5.Default or (opts[1] or ""); local msel={}
            local wrap=mk("Frame",{Size=dim2(1,0,0,48),BackgroundColor3=C.bg2,BackgroundTransparency=0.42,ZIndex=6,Parent=catPanel}); corner(wrap,RC.sharp); stroke(wrap,C.br0,1)
            mk("TextLabel",{Text=nm,Size=dim2(1,-8,0,14),Position=dim2(0,6,0,4),BackgroundTransparency=1,TextColor3=C.t2,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=7,Parent=wrap})
            local hd=mk("TextButton",{Size=dim2(1,-8,0,23),Position=dim2(0,4,0,21),BackgroundColor3=C.bg4,Text="",AutoButtonColor=false,ZIndex=7,Parent=wrap}); corner(hd,RC.soft); local hsk=stroke(hd,C.br1,1)
            local sl=mk("TextLabel",{Text=multi and "Select..." or tostring(sel),Size=dim2(1,-22,1,0),Position=dim2(0,6,0,0),BackgroundTransparency=1,TextColor3=C.t1,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=8,Parent=hd})
            local arr=mk("TextLabel",{Text="▾",Size=dim2(0,14,1,0),Position=dim2(1,-15,0,0),BackgroundTransparency=1,TextColor3=C.t2,TextSize=9,Font=Enum.Font.Gotham,ZIndex=8,Parent=hd})
            hd.MouseEnter:Connect(function() tw(hd,{BackgroundColor3=C.bg3},Enum.EasingStyle.Quint,0.1);tw(hsk,{Color=AC},Enum.EasingStyle.Quint,0.1) end); hd.MouseLeave:Connect(function() tw(hd,{BackgroundColor3=C.bg4},Enum.EasingStyle.Quint,0.1);tw(hsk,{Color=C.br1},Enum.EasingStyle.Quint,0.1) end)
            local isOpen=false; local function closeDD() isOpen=false;tw(arr,{Rotation=0},Enum.EasingStyle.Quint,0.12);closeOV() end
            local function buildDD(ov)
                local ap=hd.AbsolutePosition;local as=hd.AbsoluteSize;local lh=math.min(#opts*24+10,160); local px=math.min(ap.X,SG.AbsoluteSize.X-as.X-10); local py=ap.Y+as.Y+4; if py+lh>SG.AbsoluteSize.Y-10 then py=ap.Y-lh-4 end
                local pan=mk("Frame",{Size=dim2(0,as.X,0,0),Position=dim2(0,px,0,py),BackgroundColor3=C.bg1,ZIndex=220,Parent=ov}); corner(pan,RC.sharp); stroke(pan,C.br0,1.5); tw(pan,{Size=dim2(0,as.X,0,lh)},Enum.EasingStyle.Back,0.16)
                local sc=mk("ScrollingFrame",{Size=dim2(1,0,1,0),BackgroundTransparency=1,ScrollBarThickness=2,ScrollBarImageColor3=AC,CanvasSize=dim2(0,0,0,0),ZIndex=221,Parent=pan}); onAC(function(c) sc.ScrollBarImageColor3=c end); layout(sc,Enum.FillDirection.Vertical,3); padding(sc,4,4,4,4); autoCanvas(sc)
                for _,op in ipairs(opts) do
                    local isSel=multi and table.find(msel,op)~=nil or op==sel
                    local ob=mk("TextButton",{Size=dim2(1,0,0,22),Text=op,BackgroundColor3=isSel and AC or C.bg4,TextColor3=isSel and C.t0 or C.t2,TextSize=11,Font=Enum.Font.Gotham,AutoButtonColor=false,ZIndex=222,Parent=sc}); corner(ob,RC.soft)
                    ob.MouseEnter:Connect(function() if not(multi and table.find(msel,op)) and op~=sel then tw(ob,{BackgroundColor3=C.bg3,TextColor3=C.t1},Enum.EasingStyle.Quint,0.08) end end)
                    ob.MouseLeave:Connect(function() local s2=multi and table.find(msel,op)~=nil or op==sel; ob.BackgroundColor3=s2 and AC or C.bg4; ob.TextColor3=s2 and C.t0 or C.t2 end)
                    ob.MouseButton1Click:Connect(function() if multi then local idx=table.find(msel,op);if idx then table.remove(msel,idx) else table.insert(msel,op) end;sl.Text=#msel>0 and table.concat(msel,", ") or "Select...";pcall(cb,msel);if flag then _G[flag]=msel end else sel=op;sl.Text=op;pcall(cb,op);if flag then _G[flag]=op end;closeDD() end end)
                end
            end
            hd.MouseButton1Click:Connect(function() isOpen=not isOpen;tw(arr,{Rotation=isOpen and 180 or 0},Enum.EasingStyle.Quint,0.15); if isOpen then openOV(buildDD) else closeDD() end end)
            if flag then _G[flag]=sel; CFGSYS.register(flag,function() return sel end,function(v) sel=v;sl.Text=v;if flag then _G[flag]=v end end,"string") end
            local r={Value=sel}; function r:Set(v) sel=v;sl.Text=v end; function r:SetOptions(t) opts=t end; function r:Get() return multi and msel or sel end; return r
        end

        function CAT:AddColorPicker(o5)
            o5=o5 or {}; local nm=o5.Name or "Color"; local col=o5.Default or rgb(255,80,80); local flag=o5.Flag; local cb=o5.Callback or function() end; local h,s,v=Color3.toHSV(col); local row=mkRow(30)
            mk("TextLabel",{Text=nm,Size=dim2(1,-52,1,0),Position=dim2(0,8,0,0),BackgroundTransparency=1,TextColor3=C.t1,TextSize=12,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=7,Parent=row})
            local sw=mk("TextButton",{Size=dim2(0,34,0,19),Position=dim2(1,-38,.5,-9.5),BackgroundColor3=col,Text="",AutoButtonColor=false,ZIndex=7,Parent=row}); corner(sw,RC.soft); stroke(sw,C.br2,1)
            local open=false; sw.MouseButton1Click:Connect(function() open=not open; if open then openOV(function(ov) buildColorPicker(ov,sw,h,s,v,function(nc,nh,ns,nv) col=nc;h,s,v=nh,ns,nv;sw.BackgroundColor3=nc;pcall(cb,nc);if flag then _G[flag]=nc end end,SG) end) else closeOV() end end)
            if flag then _G[flag]=col; CFGSYS.register(flag,function() return col end,function(c2) col=c2;h,s,v=Color3.toHSV(c2);sw.BackgroundColor3=c2;pcall(cb,c2) end,"color") end
            local r={Value=col}; function r:Set(c2) col=c2;h,s,v=Color3.toHSV(c2);sw.BackgroundColor3=c2 end; function r:Get() return col end; return r
        end

        function CAT:AddKeybind(o5)
            o5=o5 or {}; local nm=o5.Name or "Keybind"; local key=o5.Default or Enum.KeyCode.Unknown; local flag=o5.Flag; local cb=o5.Callback or function() end; local listening=false
            local row=mkRow(30); mk("TextLabel",{Text=nm,Size=dim2(1,-94,1,0),Position=dim2(0,8,0,0),BackgroundTransparency=1,TextColor3=C.t1,TextSize=12,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=7,Parent=row})
            local kb=mk("TextButton",{Text=keyName(key),Size=dim2(0,78,0,17),Position=dim2(1,-82,.5,-8.5),BackgroundColor3=C.bg4,TextColor3=AC,TextSize=9,Font=Enum.Font.GothamBold,AutoButtonColor=false,ZIndex=7,Parent=row}); corner(kb,RC.soft); stroke(kb,C.br0,1); onAC(function(c) if not listening then kb.TextColor3=c end end)
            kb.MouseButton1Click:Connect(function() if listening then return end; listening=true;kb.Text="...";kb.TextColor3=rgb(255,185,0);kb.BackgroundColor3=rgb(28,24,10) end)
            UIS.InputBegan:Connect(function(i,gpe) if listening and not gpe and i.UserInputType==Enum.UserInputType.Keyboard then key=i.KeyCode;kb.Text=keyName(key);kb.TextColor3=AC;kb.BackgroundColor3=C.bg4;listening=false elseif not listening and not gpe and i.KeyCode==key and key~=Enum.KeyCode.Unknown then pcall(cb);if flag then _G[flag]=key end end end)
            if flag then _G[flag]=key; CFGSYS.register(flag,function() return key end,function(k) key=k;kb.Text=keyName(k) end,"key") end
            local r={Value=key}; function r:Set(k) key=k;kb.Text=keyName(k) end; function r:Get() return key end; return r
        end

        function CAT:AddSeparator()
            local sep=mk("Frame",{Size=dim2(1,0,0,1),BackgroundColor3=C.br1,BackgroundTransparency=0.35,ZIndex=6,Parent=catPanel})
            mk("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.06,0),NumberSequenceKeypoint.new(.94,0),NumberSequenceKeypoint.new(1,1)}),Parent=sep})
        end

        function CAT:AddProgressBar(o5)
            o5=o5 or {}; local nm=o5.Name or "Progress"; local maxV=o5.Max or 100; local cur=math.clamp(o5.Default or 0,0,maxV)
            local wrap=mk("Frame",{Size=dim2(1,0,0,40),BackgroundColor3=C.bg2,BackgroundTransparency=0.42,ZIndex=6,Parent=catPanel}); corner(wrap,RC.sharp); stroke(wrap,C.br0,1)
            local top=mk("Frame",{Size=dim2(1,-8,0,18),Position=dim2(0,4,0,4),BackgroundTransparency=1,ZIndex=7,Parent=wrap})
            mk("TextLabel",{Text=nm,Size=dim2(1,-52,1,0),BackgroundTransparency=1,TextColor3=C.t1,TextSize=12,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=8,Parent=top})
            local pct=mk("TextLabel",{Text=math.round(cur/maxV*100).."%",Size=dim2(0,46,1,0),Position=dim2(1,-48,0,0),BackgroundTransparency=1,TextColor3=AC,TextSize=11,Font=Enum.Font.GothamSemibold,ZIndex=8,Parent=top}); onAC(function(c) pct.TextColor3=c end)
            local trk=mk("Frame",{Size=dim2(1,-8,0,4),Position=dim2(0,4,0,28),BackgroundColor3=C.bg4,ZIndex=7,Parent=wrap}); corner(trk,RC.pill)
            local fill2=mk("Frame",{Size=dim2(cur/maxV,0,1,0),BackgroundColor3=AC,ZIndex=8,Parent=trk}); corner(fill2,RC.pill); onAC(function(c) fill2.BackgroundColor3=c end)
            local r={Value=cur}; function r:Set(v) v=math.clamp(v,0,maxV);cur=v;tw(fill2,{Size=dim2(v/maxV,0,1,0)},Enum.EasingStyle.Quint,0.22);pct.Text=math.round(v/maxV*100).."%" end; function r:Get() return cur end; return r
        end

        return CAT
    end

    function WO:SetAccent(c) AC=c;fireAC() end
    function WO:Toggle() _vis=not _vis;BG.Visible=_vis;BAR.Visible=_vis; if not _vis then SW.Visible=false;CFGW.Visible=false end end
    function WO:Destroy() SG:Destroy() end
    function WO:SetBackground(id) BG_IMG.Image=id;SW_IMG.Image=id;CFGW_IMG.Image=id end
    function WO:SetConfigName(name) CFG.ConfigName=name;wmLabels.config.Text=name end
    function WO:SaveConfig(name) return CFGSYS.save(name or CFG.ConfigName) end
    function WO:LoadConfig(name) return CFGSYS.load(name or CFG.ConfigName) end

    return WO
end

return Peleccos
