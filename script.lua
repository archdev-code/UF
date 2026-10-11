local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local Config = {
    BallPull = false,
    Range = 120,
    CFrameSpeed = false,
    SpeedValue = 1,
}

local Capabilities = {
    HookMetamethod = type(hookmetamethod) == "function",
    NewCclosure = type(newcclosure) == "function",
    CheckCaller = type(checkcaller) == "function",
    GetRawMetatable = type(getrawmetatable) == "function",
    SetReadonly = type(setreadonly) == "function",
    ProtectGui = (type(syn) == "table" and type(syn.protect_gui) == "function") or type(protect_gui) == "function",
}

local function SafeWrap(Fn)
    if Capabilities.NewCclosure then
        local Ok, Wrapped = pcall(newcclosure, Fn)
        if Ok then return Wrapped end
    end
    return Fn
end

local function HookMetamethod(Target, Method, Replacement)
    if Capabilities.HookMetamethod then
        local Ok, Hooked = pcall(hookmetamethod, Target, Method, Replacement)
        if Ok and Hooked then return Hooked end
    end
    if Capabilities.GetRawMetatable and Capabilities.SetReadonly then
        local Ok, Meta = pcall(getrawmetatable, Target)
        if not Ok or not Meta then return nil end
        local Original = Meta[Method]
        pcall(setreadonly, Meta, false)
        Meta[Method] = SafeWrap(Replacement)
        pcall(setreadonly, Meta, true)
        return Original
    end
    return nil
end

local function GetRoot()
    local Character = LocalPlayer.Character
    if not Character then return nil end
    return Character:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
    local Character = LocalPlayer.Character
    if not Character then return nil end
    return Character:FindFirstChildOfClass("Humanoid")
end

local function FindFootball()
    for _, Object in ipairs(workspace:GetChildren()) do
        if Object:IsA("BasePart") and Object.Name:lower():find("football") then
            return Object
        end
    end
    return nil
end

local function PingMultiplier()
    local Ping = LocalPlayer:GetNetworkPing() * 1000
    if Ping > 200 then return 2 end
    if Ping > 100 then return 1.4 end
    return 1
end

local PositionCache = {}
local SpoofedCFrame = nil
local OriginalIndex = nil
local HookInstalled = false

local function InstallHook()
    if HookInstalled then return end
    HookInstalled = true
    local Previous = HookMetamethod(game, "__index", function(Self, Key)
        if Key == "CFrame" and SpoofedCFrame and Self == GetRoot() then
            if not Capabilities.CheckCaller or not checkcaller() then
                return SpoofedCFrame
            end
        end
        if OriginalIndex then
            return OriginalIndex(Self, Key)
        end
        return Self[Key]
    end)
    if Previous then
        OriginalIndex = Previous
    end
end

InstallHook()

local PullConnection = RunService.Heartbeat:Connect(function()
    if not Config.BallPull then
        SpoofedCFrame = nil
        return
    end

    local Ball = FindFootball()
    local Root = GetRoot()
    if not Ball or not Root then
        SpoofedCFrame = nil
        return
    end

    local Id = tostring(Ball:GetDebugId())
    local Old = PositionCache[Id]
    local Now = Ball.Position
    PositionCache[Id] = Now
    if not Old then Old = Now end

    if (Root.Position - Now).Magnitude > Config.Range then
        SpoofedCFrame = nil
        return
    end

    local Velocity = Now - Old
    local Target
    local Mult = PingMultiplier()

    if Velocity.Magnitude > 0.1 then
        Target = Now + (Velocity.Unit * 8 * Mult)
    else
        Target = Now + Vector3.new(5, 0, 5) * Mult
    end

    Target = Vector3.new(Target.X, math.max(Target.Y, Now.Y), Target.Z)

    SpoofedCFrame = Root.CFrame
    Root.CFrame = CFrame.new(Target)
end)

local SpeedConnection = RunService.Heartbeat:Connect(function()
    if not Config.CFrameSpeed then return end
    local Root = GetRoot()
    local Humanoid = GetHumanoid()
    if not Root or not Humanoid then return end
    if Humanoid.MoveDirection.Magnitude > 0 then
        Root.CFrame = Root.CFrame + (Humanoid.MoveDirection * Config.SpeedValue)
    end
end)

local function BuildLoadingScreen()
    local LoadingGui = Instance.new("ScreenGui")
    LoadingGui.Name = "DownloadGgLoading"
    LoadingGui.ResetOnSpawn = false
    LoadingGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    LoadingGui.IgnoreGuiInset = true
    LoadingGui.DisplayOrder = 100
    pcall(function() LoadingGui.Parent = game:GetService("CoreGui") end)
    if not LoadingGui.Parent then
        LoadingGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    if Capabilities.ProtectGui then
        if type(syn) == "table" and type(syn.protect_gui) == "function" then
            pcall(syn.protect_gui, LoadingGui)
        elseif type(protect_gui) == "function" then
            pcall(protect_gui, LoadingGui)
        end
    end

    local Backdrop = Instance.new("Frame")
    Backdrop.Size = UDim2.new(1, 0, 1, 0)
    Backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Backdrop.BorderSizePixel = 0
    Backdrop.ZIndex = 1
    Backdrop.Parent = LoadingGui

    local Center = Instance.new("Frame")
    Center.Size = UDim2.new(0, 340, 0, 150)
    Center.Position = UDim2.new(0.5, -170, 0.5, -75)
    Center.BackgroundTransparency = 1
    Center.ZIndex = 2
    Center.Parent = Backdrop

    local Brand = Instance.new("TextLabel")
    Brand.Size = UDim2.new(1, 0, 0, 42)
    Brand.BackgroundTransparency = 1
    Brand.Text = "Welcome to the Hub"
    Brand.TextColor3 = Color3.fromRGB(255, 255, 255)
    Brand.Font = Enum.Font.GothamBold
    Brand.TextSize = 28
    Brand.TextTransparency = 1
    Brand.ZIndex = 3
    Brand.Parent = Center

    local SubBrand = Instance.new("TextLabel")
    SubBrand.Size = UDim2.new(1, 0, 0, 18)
    SubBrand.Position = UDim2.new(0, 0, 0, 46)
    SubBrand.BackgroundTransparency = 1
    SubBrand.Text = "DOWNLOAD.GG"
    SubBrand.TextColor3 = Color3.fromRGB(180, 180, 180)
    SubBrand.Font = Enum.Font.Gotham
    SubBrand.TextSize = 11
    SubBrand.TextTransparency = 1
    SubBrand.ZIndex = 3
    SubBrand.Parent = Center

    local BarTrack = Instance.new("Frame")
    BarTrack.Size = UDim2.new(0, 260, 0, 3)
    BarTrack.Position = UDim2.new(0.5, -130, 0, 94)
    BarTrack.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    BarTrack.BorderSizePixel = 0
    BarTrack.BackgroundTransparency = 1
    BarTrack.ZIndex = 3
    BarTrack.Parent = Center

    local BarTrackCorner = Instance.new("UICorner")
    BarTrackCorner.CornerRadius = UDim.new(1, 0)
    BarTrackCorner.Parent = BarTrack

    local BarFill = Instance.new("Frame")
    BarFill.Size = UDim2.new(0, 0, 1, 0)
    BarFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    BarFill.BorderSizePixel = 0
    BarFill.ZIndex = 4
    BarFill.Parent = BarTrack

    local BarFillCorner = Instance.new("UICorner")
    BarFillCorner.CornerRadius = UDim.new(1, 0)
    BarFillCorner.Parent = BarFill

    local Status = Instance.new("TextLabel")
    Status.Size = UDim2.new(1, 0, 0, 16)
    Status.Position = UDim2.new(0, 0, 0, 106)
    Status.BackgroundTransparency = 1
    Status.Text = "Initializing"
    Status.TextColor3 = Color3.fromRGB(140, 140, 140)
    Status.Font = Enum.Font.Gotham
    Status.TextSize = 11
    Status.TextTransparency = 1
    Status.ZIndex = 3
    Status.Parent = Center

    local ScanLine = Instance.new("Frame")
    ScanLine.Size = UDim2.new(1, 0, 0, 1)
    ScanLine.Position = UDim2.new(0, 0, 0, -2)
    ScanLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ScanLine.BackgroundTransparency = 0.85
    ScanLine.BorderSizePixel = 0
    ScanLine.ZIndex = 5
    ScanLine.Parent = Backdrop

    task.spawn(function()
        while LoadingGui.Parent do
            local Tween = TweenService:Create(ScanLine, TweenInfo.new(2.4, Enum.EasingStyle.Linear), {
                Position = UDim2.new(0, 0, 1, 0)
            })
            Tween:Play()
            Tween.Completed:Wait()
            ScanLine.Position = UDim2.new(0, 0, 0, -2)
        end
    end)

    TweenService:Create(Brand, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextTransparency = 0
    }):Play()
    task.wait(0.15)
    TweenService:Create(SubBrand, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextTransparency = 0
    }):Play()
    task.wait(0.15)
    TweenService:Create(BarTrack, TweenInfo.new(0.6), { BackgroundTransparency = 0 }):Play()
    TweenService:Create(Status, TweenInfo.new(0.6), { TextTransparency = 0 }):Play()

    task.wait(0.4)

    local Steps = {
        { Progress = 0.2, Text = "Hooking Environment" },
        { Progress = 0.45, Text = "Resolving Metatable" },
        { Progress = 0.7, Text = "Caching Football" },
        { Progress = 0.9, Text = "Binding Input" },
        { Progress = 1.0, Text = "Ready" },
    }

    for _, Step in ipairs(Steps) do
        TweenService:Create(BarFill, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(Step.Progress, 0, 1, 0)
        }):Play()
        Status.Text = Step.Text
        task.wait(0.35)
    end

    task.wait(0.35)

    TweenService:Create(Brand, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        TextTransparency = 1
    }):Play()
    TweenService:Create(SubBrand, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        TextTransparency = 1
    }):Play()
    TweenService:Create(BarTrack, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
    TweenService:Create(BarFill, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
    TweenService:Create(Status, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
    TweenService:Create(ScanLine, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()

    task.wait(0.3)

    local Out = TweenService:Create(Backdrop, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        BackgroundTransparency = 1
    })
    Out:Play()
    Out.Completed:Wait()

    LoadingGui:Destroy()
end

local function BuildUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "DownloadGg"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.Enabled = false
    pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
    if not ScreenGui.Parent then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    if Capabilities.ProtectGui then
        if type(syn) == "table" and type(syn.protect_gui) == "function" then
            pcall(syn.protect_gui, ScreenGui)
        elseif type(protect_gui) == "function" then
            pcall(protect_gui, ScreenGui)
        end
    end

    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 400, 0, 300)
    Main.Position = UDim2.new(0, 20, 0.5, -150)
    Main.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Main.Parent = ScreenGui

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 10)
    MainCorner.Parent = Main

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Color3.fromRGB(30, 30, 36)
    MainStroke.Thickness = 1
    MainStroke.Parent = Main

    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0, 56)
    Header.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
    Header.BorderSizePixel = 0
    Header.Parent = Main

    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 10)
    HeaderCorner.Parent = Header

    local HeaderMask = Instance.new("Frame")
    HeaderMask.Size = UDim2.new(1, 0, 0, 12)
    HeaderMask.Position = UDim2.new(0, 0, 1, -12)
    HeaderMask.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
    HeaderMask.BorderSizePixel = 0
    HeaderMask.Parent = Header

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -70, 0, 22)
    Title.Position = UDim2.new(0, 18, 0, 8)
    Title.BackgroundTransparency = 1
    Title.Text = "Download.gg"
    Title.TextColor3 = Color3.fromRGB(240, 240, 245)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 15
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Header

    local SubLabel = Instance.new("TextLabel")
    SubLabel.Size = UDim2.new(1, -70, 0, 16)
    SubLabel.Position = UDim2.new(0, 18, 0, 32)
    SubLabel.BackgroundTransparency = 1
    SubLabel.Text = "Universal Football Script"
    SubLabel.TextColor3 = Color3.fromRGB(110, 140, 200)
    SubLabel.Font = Enum.Font.Gotham
    SubLabel.TextSize = 11
    SubLabel.TextXAlignment = Enum.TextXAlignment.Left
    SubLabel.Parent = Header

    local CloseButton = Instance.new("TextButton")
    CloseButton.Size = UDim2.new(0, 24, 0, 24)
    CloseButton.Position = UDim2.new(1, -34, 0.5, -12)
    CloseButton.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
    CloseButton.Text = "×"
    CloseButton.TextColor3 = Color3.fromRGB(200, 200, 210)
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.TextSize = 15
    CloseButton.BorderSizePixel = 0
    CloseButton.Parent = Header

    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 6)
    CloseCorner.Parent = CloseButton

    CloseButton.MouseButton1Click:Connect(function()
        ScreenGui.Enabled = false
    end)

    local Body = Instance.new("Frame")
    Body.Size = UDim2.new(1, -36, 1, -72)
    Body.Position = UDim2.new(0, 18, 0, 64)
    Body.BackgroundTransparency = 1
    Body.Parent = Main

    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 10)
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.Parent = Body

    local function MakeToggle(Text, Order, Default, Callback)
        local Button = Instance.new("TextButton")
        Button.Size = UDim2.new(1, 0, 0, 48)
        Button.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
        Button.BorderSizePixel = 0
        Button.Text = ""
        Button.LayoutOrder = Order
        Button.Parent = Body

        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(0, 8)
        Corner.Parent = Button

        local Stroke = Instance.new("UIStroke")
        Stroke.Color = Color3.fromRGB(30, 30, 36)
        Stroke.Thickness = 1
        Stroke.Parent = Button

        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, -80, 1, 0)
        Label.Position = UDim2.new(0, 16, 0, 0)
        Label.BackgroundTransparency = 1
        Label.Text = Text
        Label.TextColor3 = Color3.fromRGB(230, 230, 235)
        Label.Font = Enum.Font.Gotham
        Label.TextSize = 13
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = Button

        local Indicator = Instance.new("Frame")
        Indicator.Size = UDim2.new(0, 42, 0, 22)
        Indicator.Position = UDim2.new(1, -58, 0.5, -11)
        Indicator.BackgroundColor3 = Default and Color3.fromRGB(50, 100, 200) or Color3.fromRGB(30, 30, 36)
        Indicator.BorderSizePixel = 0
        Indicator.Parent = Button

        local IndicatorCorner = Instance.new("UICorner")
        IndicatorCorner.CornerRadius = UDim.new(1, 0)
        IndicatorCorner.Parent = Indicator

        local Dot = Instance.new("Frame")
        Dot.Size = UDim2.new(0, 18, 0, 18)
        Dot.Position = Default and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        Dot.BackgroundColor3 = Color3.fromRGB(200, 200, 210)
        Dot.BorderSizePixel = 0
        Dot.Parent = Indicator

        local DotCorner = Instance.new("UICorner")
        DotCorner.CornerRadius = UDim.new(1, 0)
        DotCorner.Parent = Dot

        local State = Default
        Button.MouseButton1Click:Connect(function()
            State = not State
            if State then
                Indicator.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
                Dot.Position = UDim2.new(1, -20, 0.5, -9)
            else
                Indicator.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
                Dot.Position = UDim2.new(0, 2, 0.5, -9)
            end
            Callback(State)
        end)

        return Button
    end

    local function MakeSlider(Text, Order, Min, Max, Default, Callback)
        local Container = Instance.new("Frame")
        Container.Size = UDim2.new(1, 0, 0, 54)
        Container.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
        Container.BorderSizePixel = 0
        Container.LayoutOrder = Order
        Container.Parent = Body

        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(0, 8)
        Corner.Parent = Container

        local Stroke = Instance.new("UIStroke")
        Stroke.Color = Color3.fromRGB(30, 30, 36)
        Stroke.Thickness = 1
        Stroke.Parent = Container

        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, -20, 0, 18)
        Label.Position = UDim2.new(0, 16, 0, 8)
        Label.BackgroundTransparency = 1
        Label.Text = Text .. "  ·  " .. Default
        Label.TextColor3 = Color3.fromRGB(180, 180, 190)
        Label.Font = Enum.Font.Gotham
        Label.TextSize = 12
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = Container

        local Bar = Instance.new("Frame")
        Bar.Size = UDim2.new(1, -32, 0, 5)
        Bar.Position = UDim2.new(0, 16, 0, 38)
        Bar.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
        Bar.BorderSizePixel = 0
        Bar.Parent = Container

        local BarCorner = Instance.new("UICorner")
        BarCorner.CornerRadius = UDim.new(1, 0)
        BarCorner.Parent = Bar

        local Ratio = (Default - Min) / (Max - Min)

        local Fill = Instance.new("Frame")
        Fill.Size = UDim2.new(Ratio, 0, 1, 0)
        Fill.BackgroundColor3 = Color3.fromRGB(60, 120, 220)
        Fill.BorderSizePixel = 0
        Fill.Parent = Bar

        local FillCorner = Instance.new("UICorner")
        FillCorner.CornerRadius = UDim.new(1, 0)
        FillCorner.Parent = Fill

        local Knob = Instance.new("TextButton")
        Knob.Size = UDim2.new(0, 14, 0, 14)
        Knob.Position = UDim2.new(Ratio, -7, 0.5, -7)
        Knob.BackgroundColor3 = Color3.fromRGB(240, 240, 245)
        Knob.Text = ""
        Knob.BorderSizePixel = 0
        Knob.Parent = Bar

        local KnobCorner = Instance.new("UICorner")
        KnobCorner.CornerRadius = UDim.new(1, 0)
        KnobCorner.Parent = Knob

        local Dragging = false

        local function Update(Input)
            local Rel = math.clamp((Input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
            Fill.Size = UDim2.new(Rel, 0, 1, 0)
            Knob.Position = UDim2.new(Rel, -7, 0.5, -7)
            local Value = Min + (Max - Min) * Rel
            if Max - Min >= 10 then
                Value = math.floor(Value + 0.5)
            else
                Value = math.floor(Value * 100 + 0.5) / 100
            end
            Label.Text = Text .. "  ·  " .. tostring(Value)
            Callback(Value)
        end

        Knob.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                Dragging = true
            end
        end)

        UserInputService.InputChanged:Connect(function(Input)
            if Dragging and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
                Update(Input)
            end
        end)

        UserInputService.InputEnded:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                Dragging = false
            end
        end)
    end

    MakeToggle("Ball Pull", 1, false, function(State)
        Config.BallPull = State
    end)

    MakeSlider("Pull Range", 2, 10, 400, 120, function(Value)
        Config.Range = Value
    end)

    MakeToggle("CFrame Speed", 3, false, function(State)
        Config.CFrameSpeed = State
    end)

    MakeSlider("Speed Value", 4, 0.1, 10, 1, function(Value)
        Config.SpeedValue = Value
    end)

    return ScreenGui
end

BuildLoadingScreen()

local UI = BuildUI()
UI.Enabled = true
