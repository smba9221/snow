--[[
     ███████╗███╗   ██╗ ██████╗ ██╗    ██╗
     ██╔════╝████╗  ██║██╔═══██╗██║    ██║
     ███████╗██╔██╗ ██║██║   ██║██║ █╗ ██║
     ╚════██║██║╚██╗██║██║   ██║██║███╗██║
     ███████║██║ ╚████║╚██████╔╝╚███╔███╔╝
     ╚══════╝╚═╝  ╚═══╝ ╚═════╝  ╚══╝╚══╝

    Snow UI Library
    A smooth, themeable Roblox UI library with Lucide icon support.
    API-compatible with Obsidian / LinoriaLib style scripts.

    https://github.com/smba9221/snow
]]

local cloneref = (cloneref or clonereference or function(Instance) return Instance end)
local function GetService(Name)
    return cloneref(game:GetService(Name))
end

local Players = GetService("Players")
local UserInputService = GetService("UserInputService")
local TweenService = GetService("TweenService")
local RunService = GetService("RunService")
local HttpService = GetService("HttpService")
local TextService = GetService("TextService")
local CoreGui = GetService("CoreGui")
local Teams = GetService("Teams")
local SoundService = GetService("SoundService")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local LUCIDE_URL = "https://github.com/latte-soft/lucide-roblox/releases/latest/download/lucide-roblox.luau"

local Library = {
    Version = "1.0.0",

    LocalPlayer = LocalPlayer,
    IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled,

    ScreenGui = nil,
    Window = nil,

    Toggles = {},
    Options = {},
    Labels = {},
    Buttons = {},
    Tabs = {},
    Dialogues = {},
    KeyPickers = {},
    DependencyBoxes = {},
    Notifications = {},

    Signals = {},
    UnloadSignals = {},
    Registry = setmetatable({}, { __mode = "k" }),
    Scales = setmetatable({}, { __mode = "k" }),
    OpenPopups = {},

    Toggled = false,
    Unloaded = false,

    ToggleKeybind = Enum.KeyCode.RightControl,
    NotifySide = "Right",
    ShowCustomCursor = false,
    ForceCheckbox = false,
    NotifyOnError = false,
    ShowToggleFrameInKeybinds = true,
    ShowAllKeybinds = false,

    DPIScale = 1,
    CornerRadius = 6,
    MinSize = Vector2.new(560, 380),

    SearchText = "",
    Searching = false,

    ActiveTab = nil,
    ActiveLoading = nil,
    ActiveDialog = nil,

    Animations = {
        ToggleWindow = true,
        TabSwitch = true,
        Groupbox = true,
        Dropdown = true,
        KeyPicker = true,
    },

    TweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    FastTweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    NotifyTweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    WindowAnimationInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    TabTransitionInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    DropdownTransitionInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    TabSwipeOffset = 14,
    TabSwipeFrom = "bottom",

    Scheme = {
        BackgroundColor = Color3.fromRGB(14, 15, 19),
        SidebarColor = Color3.fromRGB(11, 12, 15),
        MainColor = Color3.fromRGB(21, 22, 27),
        ElementColor = Color3.fromRGB(30, 31, 37),
        OutlineColor = Color3.fromRGB(36, 38, 45),
        AccentColor = Color3.fromRGB(58, 155, 240),
        FontColor = Color3.fromRGB(232, 233, 238),
        MutedColor = Color3.fromRGB(122, 125, 136),
        RedColor = Color3.fromRGB(255, 92, 92),
        DarkColor = Color3.fromRGB(8, 9, 11),
        WhiteColor = Color3.fromRGB(255, 255, 255),
        Font = Font.fromEnum(Enum.Font.Gotham),
    },
}

local Toggles = Library.Toggles
local Options = Library.Options

--// Small helpers \\--

local function Round(Number, Decimals)
    local Mult = 10 ^ (Decimals or 0)
    return math.floor(Number * Mult + 0.5) / Mult
end

local function TableSize(Table)
    local Count = 0
    for _ in pairs(Table) do
        Count = Count + 1
    end
    return Count
end

local function Trim(Text)
    return (tostring(Text):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function StripRichText(Text)
    return (tostring(Text or ""):gsub("<[^>]->", ""))
end

local function IsClick(Input)
    return Input.UserInputType == Enum.UserInputType.MouseButton1
        or Input.UserInputType == Enum.UserInputType.Touch
end

local function IsMove(Input)
    return Input.UserInputType == Enum.UserInputType.MouseMovement
        or Input.UserInputType == Enum.UserInputType.Touch
end

local function MousePos()
    return UserInputService:GetMouseLocation()
end

function Library:Validate(Table, Template)
    Table = type(Table) == "table" and Table or {}
    for Key, Value in pairs(Template) do
        if Table[Key] == nil then
            Table[Key] = Value
        elseif type(Value) == "table" and type(Table[Key]) == "table" and not Value[1] then
            Library:Validate(Table[Key], Value)
        end
    end
    return Table
end

function Library:SafeCallback(Func, ...)
    if type(Func) ~= "function" then
        return
    end
    local Result = table.pack(xpcall(Func, function(Error)
        return debug.traceback(tostring(Error), 2)
    end, ...))
    if not Result[1] then
        local Message = tostring(Result[2])
        if Library.NotifyOnError then
            Library:Notify({ Title = "Callback error", Description = Message:split("\n")[1], Icon = "triangle-alert" })
        end
        warn("[Snow] Callback error: " .. Message)
        return
    end
    return table.unpack(Result, 2, Result.n)
end

function Library:GiveSignal(Signal)
    local Connection = Signal
    if typeof(Signal) == "RBXScriptSignal" then
        error("GiveSignal expects a connection, not a signal", 2)
    end
    table.insert(Library.Signals, Connection)
    return Connection
end

function Library:OnUnload(Callback)
    table.insert(Library.UnloadSignals, Callback)
end

function Library:GetBetterColor(Color, Add)
    Add = Add * 255
    return Color3.fromRGB(
        math.clamp(Color.R * 255 + Add, 0, 255),
        math.clamp(Color.G * 255 + Add, 0, 255),
        math.clamp(Color.B * 255 + Add, 0, 255)
    )
end

function Library:GetLighterColor(Color)
    local H, S, V = Color:ToHSV()
    return Color3.fromHSV(H, math.max(0, S - 0.1), math.min(1, V + 0.1))
end

function Library:GetDarkerColor(Color)
    local H, S, V = Color:ToHSV()
    return Color3.fromHSV(H, S, V / 1.5)
end

function Library:GetTextBounds(Text, FontFace, Size, Width)
    local Params = Instance.new("GetTextBoundsParams")
    Params.Text = StripRichText(Text)
    Params.Font = FontFace or Library.Scheme.Font
    Params.Size = Size or 14
    Params.Width = Width or 10000
    local Ok, Bounds = pcall(TextService.GetTextBoundsAsync, TextService, Params)
    if Ok then
        return Bounds.X, Bounds.Y
    end
    return #Params.Text * (Params.Size * 0.55), Params.Size
end

function Library:MouseIsOverFrame(Frame, Position)
    Position = Position or MousePos()
    local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize
    return Position.X >= AbsPos.X and Position.X <= AbsPos.X + AbsSize.X
        and Position.Y >= AbsPos.Y and Position.Y <= AbsPos.Y + AbsSize.Y
end

function Library:IsInsideFrame(ParentFrame, Frame)
    return Frame == ParentFrame or Frame:IsDescendantOf(ParentFrame)
end

local ShortKeyNames = {
    LeftShift = "LShift", RightShift = "RShift",
    LeftControl = "LCtrl", RightControl = "RCtrl",
    LeftAlt = "LAlt", RightAlt = "RAlt",
    LeftSuper = "LSuper", RightSuper = "RSuper",
    Zero = "0", One = "1", Two = "2", Three = "3", Four = "4",
    Five = "5", Six = "6", Seven = "7", Eight = "8", Nine = "9",
    Backquote = "`", Minus = "-", Equals = "=", LeftBracket = "[", RightBracket = "]",
    BackSlash = "\\", Semicolon = ";", Quote = "'", Comma = ",", Period = ".", Slash = "/",
    PageUp = "PgUp", PageDown = "PgDn", Insert = "Ins", Delete = "Del", Return = "Enter",
    CapsLock = "Caps", Backspace = "Back",
    MB1 = "MB1", MB2 = "MB2", MB3 = "MB3",
}

function Library:GetKeyString(Key)
    if typeof(Key) == "EnumItem" then
        Key = Key.Name
    end
    Key = tostring(Key)
    return ShortKeyNames[Key] or Key
end

--// Theme registry \\--

local ThemeProperties = {
    BackgroundColor3 = true, TextColor3 = true, ImageColor3 = true, BorderColor3 = true,
    PlaceholderColor3 = true, ScrollBarImageColor3 = true, Color = true, TextStrokeColor3 = true,
    FontFace = true,
}

local function ResolveThemeValue(Value)
    if type(Value) == "function" then
        return Value()
    elseif type(Value) == "string" then
        local Resolved = Library.Scheme[Value]
        if Resolved == nil then
            warn("[Snow] Unknown scheme key: " .. Value)
        end
        return Resolved
    end
    return Value
end

function Library:AddToRegistry(Instance, Properties)
    local Entry = Library.Registry[Instance] or {}
    for Property, Value in pairs(Properties) do
        Entry[Property] = Value
        pcall(function()
            Instance[Property] = ResolveThemeValue(Value)
        end)
    end
    Library.Registry[Instance] = Entry
end

function Library:RefreshInstance(Instance)
    local Properties = Library.Registry[Instance]
    if not Properties then
        return
    end
    for Property, Value in pairs(Properties) do
        pcall(function()
            Instance[Property] = ResolveThemeValue(Value)
        end)
    end
end

function Library:RemoveFromRegistry(Instance)
    Library.Registry[Instance] = nil
end

function Library:UpdateColorsUsingRegistry()
    for Instance, Properties in pairs(Library.Registry) do
        for Property, Value in pairs(Properties) do
            pcall(function()
                Instance[Property] = ResolveThemeValue(Value)
            end)
        end
    end
end

local function BoldFont()
    return Font.new(Library.Scheme.Font.Family, Enum.FontWeight.Bold)
end

local function MediumFont()
    return Font.new(Library.Scheme.Font.Family, Enum.FontWeight.Medium)
end

local Templates = {
    Frame = { BorderSizePixel = 0, BackgroundColor3 = "MainColor" },
    CanvasGroup = { BorderSizePixel = 0, BackgroundTransparency = 1 },
    TextLabel = {
        BorderSizePixel = 0, BackgroundTransparency = 1, FontFace = "Font", TextColor3 = "FontColor",
        TextSize = 14, RichText = true, Text = "",
    },
    TextButton = {
        BorderSizePixel = 0, BackgroundTransparency = 1, FontFace = "Font", TextColor3 = "FontColor",
        TextSize = 14, RichText = true, Text = "", AutoButtonColor = false,
    },
    TextBox = {
        BorderSizePixel = 0, BackgroundTransparency = 1, FontFace = "Font", TextColor3 = "FontColor",
        PlaceholderColor3 = "MutedColor", TextSize = 13, ClearTextOnFocus = false, Text = "",
    },
    ImageLabel = { BorderSizePixel = 0, BackgroundTransparency = 1 },
    ImageButton = { BorderSizePixel = 0, BackgroundTransparency = 1, AutoButtonColor = false },
    ScrollingFrame = {
        BorderSizePixel = 0, BackgroundTransparency = 1, ScrollBarThickness = 2,
        ScrollBarImageColor3 = "OutlineColor", CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
        TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
        BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
    },
    UIStroke = { Color = "OutlineColor", ApplyStrokeMode = Enum.ApplyStrokeMode.Border },
    UIListLayout = { SortOrder = Enum.SortOrder.LayoutOrder },
    VideoFrame = { BorderSizePixel = 0, BackgroundTransparency = 1 },
    ViewportFrame = { BorderSizePixel = 0, BackgroundTransparency = 1 },
}

local function New(ClassName, Properties)
    local Instance = Instance.new(ClassName)
    local Merged = {}
    if Templates[ClassName] then
        for Key, Value in pairs(Templates[ClassName]) do
            Merged[Key] = Value
        end
    end
    for Key, Value in pairs(Properties or {}) do
        Merged[Key] = Value
    end

    local Themed = nil
    local Parent = Merged.Parent
    Merged.Parent = nil

    for Key, Value in pairs(Merged) do
        if ThemeProperties[Key] and (type(Value) == "string" or type(Value) == "function") then
            Themed = Themed or {}
            Themed[Key] = Value
        else
            Instance[Key] = Value
        end
    end

    if Themed then
        Library:AddToRegistry(Instance, Themed)
    end

    if Parent then
        Instance.Parent = Parent
    end

    return Instance
end
Library.Create = New

local function Corner(Parent, Radius)
    return New("UICorner", { CornerRadius = UDim.new(0, Radius or Library.CornerRadius), Parent = Parent })
end

local function Padding(Parent, Top, Bottom, Left, Right)
    return New("UIPadding", {
        PaddingTop = UDim.new(0, Top or 0),
        PaddingBottom = UDim.new(0, Bottom or Top or 0),
        PaddingLeft = UDim.new(0, Left or Top or 0),
        PaddingRight = UDim.new(0, Right or Left or Top or 0),
        Parent = Parent,
    })
end

local function Stroke(Parent, ColorKey, Transparency, Thickness)
    return New("UIStroke", {
        Color = ColorKey or "OutlineColor",
        Transparency = Transparency or 0,
        Thickness = Thickness or 1,
        Parent = Parent,
    })
end

local function Tween(Instance, Properties, Info, Animate)
    if Animate == false then
        for Property, Value in pairs(Properties) do
            Instance[Property] = Value
        end
        return nil
    end
    local Created = TweenService:Create(Instance, Info or Library.TweenInfo, Properties)
    Created:Play()
    return Created
end
Library.Tween = Tween

--// DPI scaling \\--

local function AddScale(Frame)
    local Scale = New("UIScale", { Scale = Library.DPIScale, Parent = Frame })
    Library.Scales[Scale] = true
    return Scale
end

function Library:SetDPIScale(Scale)
    if type(Scale) == "number" and Scale > 3 then
        Scale = Scale / 100 -- accepts 100 / 75 / 125 style values
    end
    Library.DPIScale = math.clamp(tonumber(Scale) or 1, 0.4, 3)
    for UIScale in pairs(Library.Scales) do
        UIScale.Scale = Library.DPIScale
    end
end

local function Unscale(Value)
    return Value / Library.DPIScale
end

--// Icons (Lucide) \\--

local IconModule = nil
local IconCache = {}

function Library:SetIconModule(Module)
    IconModule = Module
    IconCache = {}
end

do
    local Ok, Module = pcall(function()
        return loadstring(game:HttpGet(LUCIDE_URL))()
    end)
    if Ok and type(Module) == "table" and type(Module.GetAsset) == "function" then
        IconModule = Module
    end
end

function Library:GetIcon(IconName)
    if type(IconName) ~= "string" or not IconModule then
        return nil
    end
    if IconCache[IconName] ~= nil then
        return IconCache[IconName] or nil
    end
    local Ok, Asset = pcall(IconModule.GetAsset, IconName, 48)
    if Ok and type(Asset) == "table" and Asset.Url then
        IconCache[IconName] = Asset
        return Asset
    end
    IconCache[IconName] = false
    return nil
end

function Library:GetCustomIcon(Icon)
    if Icon == nil or Icon == "" then
        return nil
    end
    if type(Icon) == "table" and Icon.Url then
        return Icon
    end
    if type(Icon) == "number" or tonumber(Icon) then
        return { Url = "rbxassetid://" .. tostring(Icon), ImageRectOffset = Vector2.zero, ImageRectSize = Vector2.zero, Custom = true }
    end
    if type(Icon) == "string" then
        if Icon:match("^rbxasset") or Icon:match("^rbxthumb") or Icon:match("^https?://") or Icon:match("^rbxgameasset") then
            return { Url = Icon, ImageRectOffset = Vector2.zero, ImageRectSize = Vector2.zero, Custom = true }
        end
        return Library:GetIcon(Icon)
    end
    return nil
end

function Library:ApplyIcon(ImageObject, Icon)
    local Asset = Library:GetCustomIcon(Icon)
    if not Asset then
        ImageObject.Image = ""
        return false
    end
    ImageObject.Image = Asset.Url
    ImageObject.ImageRectOffset = Asset.ImageRectOffset or Vector2.zero
    ImageObject.ImageRectSize = Asset.ImageRectSize or Vector2.zero
    return true
end

-- Creates an ImageLabel showing a lucide icon / asset. Returns nil when the icon can't be resolved.
function Library:CreateIcon(Icon, Properties, IsButton)
    local Asset = Library:GetCustomIcon(Icon)
    if not Asset then
        return nil
    end
    Properties = Properties or {}
    if Properties.ImageColor3 == nil then
        Properties.ImageColor3 = "FontColor"
    end
    local Image = New(IsButton and "ImageButton" or "ImageLabel", Properties)
    Library:ApplyIcon(Image, Asset)
    return Image
end

--// ScreenGui & layers \\--

local ScreenGui = New("ScreenGui", {
    Name = HttpService:GenerateGUID(false):sub(1, 8),
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 999,
})

do
    pcall(function()
        if protectgui then
            protectgui(ScreenGui)
        elseif syn and syn.protect_gui then
            syn.protect_gui(ScreenGui)
        end
    end)
    local Parented = pcall(function()
        ScreenGui.Parent = (gethui and gethui()) or CoreGui
    end)
    if not Parented or not ScreenGui.Parent then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end
Library.ScreenGui = ScreenGui

local function Layer(Name, ZIndex)
    return New("Frame", {
        Name = Name,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ZIndex = ZIndex,
        Parent = ScreenGui,
    })
end

local WindowLayer = Layer("Windows", 1)
local FloatLayer = Layer("Floats", 5)
local OverlayLayer = Layer("Overlay", 50)
local NotificationLayer = Layer("Notifications", 80)
local TooltipLayer = Layer("Tooltips", 100)
local CursorLayer = Layer("Cursor", 200)

Library.WindowLayer = WindowLayer
Library.Floats = FloatLayer
Library.Overlay = OverlayLayer

--// Dragging & resizing \\--

function Library:MakeDraggable(Frame, Handle, IgnoreToggled)
    Handle = Handle or Frame
    local Dragging, StartMouse, StartPos = false, nil, nil

    Handle.InputBegan:Connect(function(Input)
        if not IsClick(Input) then
            return
        end
        if not IgnoreToggled and not Library.Toggled then
            return
        end
        Dragging = true
        StartMouse = Input.Position
        StartPos = Frame.Position

        local Changed
        Changed = Input.Changed:Connect(function()
            if Input.UserInputState == Enum.UserInputState.End then
                Dragging = false
                Changed:Disconnect()
            end
        end)
    end)

    Library:GiveSignal(UserInputService.InputChanged:Connect(function(Input)
        if not Dragging or not IsMove(Input) then
            return
        end
        local Delta = Input.Position - StartMouse
        local Target = UDim2.new(
            StartPos.X.Scale, StartPos.X.Offset + Delta.X,
            StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y
        )
        Tween(Frame, { Position = Target }, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
    end))
end

function Library:MakeResizable(Frame, Handle, Callback)
    local Resizing, StartMouse, StartSize = false, nil, nil

    Handle.InputBegan:Connect(function(Input)
        if not IsClick(Input) then
            return
        end
        Resizing = true
        StartMouse = Input.Position
        StartSize = Frame.Size

        local Changed
        Changed = Input.Changed:Connect(function()
            if Input.UserInputState == Enum.UserInputState.End then
                Resizing = false
                Changed:Disconnect()
            end
        end)
    end)

    Library:GiveSignal(UserInputService.InputChanged:Connect(function(Input)
        if not Resizing or not IsMove(Input) then
            return
        end
        local Delta = (Input.Position - StartMouse) / Library.DPIScale
        Frame.Size = UDim2.fromOffset(
            math.max(Library.MinSize.X, StartSize.X.Offset + Delta.X),
            math.max(Library.MinSize.Y, StartSize.Y.Offset + Delta.Y)
        )
        if Callback then
            Callback()
        end
    end))
end

--// Popups (dropdown lists, colour pickers, menus, settings panels) \\--
-- A popup is { Frame = GuiObject, Anchor = GuiObject?, Close = function, Follow = function? }

function Library:OpenPopup(Popup)
    for _, Existing in ipairs(Library.OpenPopups) do
        if Existing == Popup then
            return
        end
    end
    table.insert(Library.OpenPopups, Popup)
    -- Newer popups (e.g. a dropdown inside a settings panel) draw above older ones
    Popup.Frame.ZIndex = #Library.OpenPopups + 1
end

function Library:ClosePopup(Popup)
    for Index, Existing in ipairs(Library.OpenPopups) do
        if Existing == Popup then
            table.remove(Library.OpenPopups, Index)
            break
        end
    end
end

function Library:CloseAllPopups()
    for Index = #Library.OpenPopups, 1, -1 do
        local Popup = Library.OpenPopups[Index]
        if Popup then
            Popup.Close()
        end
    end
    Library.OpenPopups = {}
end

Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input)
    if not (IsClick(Input) or Input.UserInputType == Enum.UserInputType.MouseButton2) then
        return
    end
    local Position = MousePos()
    for Index = #Library.OpenPopups, 1, -1 do
        local Popup = Library.OpenPopups[Index]
        if not Popup then
            continue
        end
        local Inside = Popup.Frame.Visible and Library:MouseIsOverFrame(Popup.Frame, Position)
        if not Inside and Popup.Anchor and Library:MouseIsOverFrame(Popup.Anchor, Position) then
            Inside = true
        end
        if Inside then
            break
        end
        Popup.Close()
    end
end))

-- Positions popups next to their anchors every frame (so they follow the window while dragging)
Library:GiveSignal(RunService.RenderStepped:Connect(function()
    for _, Popup in ipairs(Library.OpenPopups) do
        if Popup.Follow then
            Popup.Follow()
        end
    end
end))

-- Places Frame below (or above, if there's no room) Anchor, in absolute screen coordinates.
local function PlaceBelow(Frame, Anchor, Gap, AlignRight, TargetHeight)
    local AbsPos, AbsSize = Anchor.AbsolutePosition, Anchor.AbsoluteSize
    local FrameSize = Frame.AbsoluteSize
    if TargetHeight then
        FrameSize = Vector2.new(FrameSize.X, TargetHeight * Library.DPIScale)
    end
    local Viewport = ScreenGui.AbsoluteSize
    local X = AlignRight and (AbsPos.X + AbsSize.X - FrameSize.X) or AbsPos.X
    local Y = AbsPos.Y + AbsSize.Y + (Gap or 4)
    if Y + FrameSize.Y > Viewport.Y - 4 and AbsPos.Y - FrameSize.Y - (Gap or 4) > 0 then
        Y = AbsPos.Y - FrameSize.Y - (Gap or 4)
    end
    X = math.clamp(X, 4, math.max(4, Viewport.X - FrameSize.X - 4))
    Frame.Position = UDim2.fromOffset(X, Y)
end

--// Tooltips \\--

local TooltipLabel = New("TextLabel", {
    BackgroundColor3 = "MainColor",
    BackgroundTransparency = 0,
    TextColor3 = "FontColor",
    TextSize = 13,
    AutomaticSize = Enum.AutomaticSize.XY,
    Visible = false,
    ZIndex = 10,
    Parent = TooltipLayer,
})
Corner(TooltipLabel, 4)
Stroke(TooltipLabel)
Padding(TooltipLabel, 4, 4, 7, 7)
AddScale(TooltipLabel)

local CurrentTooltip = nil

function Library:AddTooltip(InfoText, DisabledInfoText, HoverInstance)
    local Tooltip = {
        Info = InfoText,
        DisabledInfo = DisabledInfoText,
        Disabled = false,
        Hovering = false,
        Signals = {},
    }

    local function Show()
        local Text = Tooltip.Disabled and Tooltip.DisabledInfo or Tooltip.Info
        if not Text or Text == "" or not Library.Toggled then
            return
        end
        CurrentTooltip = Tooltip
        TooltipLabel.Text = Text
        TooltipLabel.Visible = true
    end

    table.insert(Tooltip.Signals, HoverInstance.MouseEnter:Connect(function()
        Tooltip.Hovering = true
        Show()
    end))
    table.insert(Tooltip.Signals, HoverInstance.MouseLeave:Connect(function()
        Tooltip.Hovering = false
        if CurrentTooltip == Tooltip then
            TooltipLabel.Visible = false
            CurrentTooltip = nil
        end
    end))

    function Tooltip:Refresh()
        if Tooltip.Hovering then
            Show()
        end
    end

    function Tooltip:Destroy()
        for _, Signal in ipairs(Tooltip.Signals) do
            Signal:Disconnect()
        end
        if CurrentTooltip == Tooltip then
            TooltipLabel.Visible = false
        end
    end

    return Tooltip
end

Library:GiveSignal(RunService.RenderStepped:Connect(function()
    if TooltipLabel.Visible then
        local Position = MousePos()
        TooltipLabel.Position = UDim2.fromOffset(Position.X + 14, Position.Y + 12)
    end
end))

--// Custom cursor \\--

local CursorImage = New("ImageLabel", {
    Size = UDim2.fromOffset(18, 18),
    ImageColor3 = "WhiteColor",
    Visible = false,
    ZIndex = 10,
    Parent = CursorLayer,
})
local CursorCross = New("Frame", {
    BackgroundTransparency = 1,
    Size = UDim2.fromOffset(17, 17),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Visible = false,
    Parent = CursorLayer,
})
do
    local Horizontal = New("Frame", { BackgroundColor3 = "WhiteColor", Size = UDim2.new(1, 0, 0, 1), Position = UDim2.fromScale(0, 0.5), AnchorPoint = Vector2.new(0, 0.5), Parent = CursorCross })
    local Vertical = New("Frame", { BackgroundColor3 = "WhiteColor", Size = UDim2.new(0, 1, 1, 0), Position = UDim2.fromScale(0.5, 0), AnchorPoint = Vector2.new(0.5, 0), Parent = CursorCross })
    Stroke(Horizontal, "DarkColor")
    Stroke(Vertical, "DarkColor")
end

Library.Cursor = { Icon = nil }

function Library.Cursor:ChangeIcon(Icon)
    Library.Cursor.Icon = Icon
    if not Icon or Icon == "" then
        CursorImage.Image = ""
        return
    end
    Library:ApplyIcon(CursorImage, Icon)
end
function Library.Cursor:ResetIcon()
    Library.Cursor:ChangeIcon(nil)
    CursorImage.Size = UDim2.fromOffset(18, 18)
    Library:AddToRegistry(CursorImage, { ImageColor3 = "WhiteColor" })
end
function Library.Cursor:ChangeIconColor(Color)
    Library:AddToRegistry(CursorImage, { ImageColor3 = function() return Color end })
end
function Library.Cursor:ChangeIconSize(Size)
    CursorImage.Size = Size
end
function Library.Cursor:ChangeCrossColor(Color)
    for _, Line in ipairs(CursorCross:GetChildren()) do
        if Line:IsA("Frame") then
            Library:AddToRegistry(Line, { BackgroundColor3 = function() return Color end })
        end
    end
end
function Library.Cursor:ResetCross()
    for _, Line in ipairs(CursorCross:GetChildren()) do
        if Line:IsA("Frame") then
            Library:AddToRegistry(Line, { BackgroundColor3 = "WhiteColor" })
        end
    end
end
function Library.Cursor:ResetCursor()
    Library.Cursor:ResetIcon()
    Library.Cursor:ResetCross()
end

local OriginalMouseIcon = UserInputService.MouseIconEnabled
Library:GiveSignal(RunService.RenderStepped:Connect(function()
    local Show = Library.ShowCustomCursor and Library.Toggled and not Library.Unloaded
    if Show then
        local Position = MousePos()
        UserInputService.MouseIconEnabled = false
        local UseImage = CursorImage.Image ~= ""
        CursorImage.Visible = UseImage
        CursorCross.Visible = not UseImage
        CursorImage.Position = UDim2.fromOffset(Position.X, Position.Y)
        CursorCross.Position = UDim2.fromOffset(Position.X, Position.Y)
    elseif CursorImage.Visible or CursorCross.Visible then
        CursorImage.Visible = false
        CursorCross.Visible = false
        UserInputService.MouseIconEnabled = OriginalMouseIcon
    end
end))

--// Notifications \\--

local NotificationHolder = New("Frame", {
    Name = "NotificationHolder",
    BackgroundTransparency = 1,
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -12, 0, 12),
    Size = UDim2.new(0, 300, 1, -24),
    Parent = NotificationLayer,
})
local NotificationList = New("UIListLayout", {
    Padding = UDim.new(0, 6),
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    Parent = NotificationHolder,
})
AddScale(NotificationHolder)

function Library:SetNotifySide(Side)
    Library.NotifySide = (tostring(Side):lower() == "left") and "Left" or "Right"
    if Library.NotifySide == "Left" then
        NotificationHolder.AnchorPoint = Vector2.new(0, 0)
        NotificationHolder.Position = UDim2.new(0, 12, 0, 12)
        NotificationList.HorizontalAlignment = Enum.HorizontalAlignment.Left
    else
        NotificationHolder.AnchorPoint = Vector2.new(1, 0)
        NotificationHolder.Position = UDim2.new(1, -12, 0, 12)
        NotificationList.HorizontalAlignment = Enum.HorizontalAlignment.Right
    end
end

local NotificationOrder = 0

function Library:Notify(Info, Time, SoundId, Volume)
    if type(Info) ~= "table" then
        Info = { Description = tostring(Info), Time = Time, SoundId = SoundId, Volume = Volume }
    end

    local Notification = {
        Title = Info.Title,
        Description = tostring(Info.Description or ""),
        Time = Info.Time or 4,
        Steps = Info.Steps,
        CurrentStep = 0,
        Persist = Info.Persist == true,
        Destroyed = false,
    }

    NotificationOrder = NotificationOrder + 1
    local FromLeft = Library.NotifySide == "Left"
    local Hidden = UDim2.new(FromLeft and 0 or 1, FromLeft and -320 or 320, 0, 0)
    local Shown = UDim2.new(FromLeft and 0 or 1, 0, 0, 0)

    local Wrapper = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        LayoutOrder = -NotificationOrder,
        Parent = NotificationHolder,
    })

    local Card = New("Frame", {
        BackgroundColor3 = "MainColor",
        AnchorPoint = Vector2.new(FromLeft and 0 or 1, 0),
        Position = Hidden,
        Size = UDim2.fromOffset(280, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = Wrapper,
    })
    Corner(Card, 6)
    Stroke(Card)
    New("UIListLayout", { Parent = Card })

    local Content = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = Card,
    })
    Padding(Content, 10, 10, 12, 12)

    local TextOffset = 0
    local IconImage = nil
    if Info.Icon or Info.BigIcon then
        local Big = Info.BigIcon ~= nil
        IconImage = Library:CreateIcon(Info.BigIcon or Info.Icon, {
            Size = UDim2.fromOffset(Big and 24 or 16, Big and 24 or 16),
            ImageColor3 = Info.IconColor and function()
                return typeof(Info.IconColor) == "Color3" and Info.IconColor or Library.Scheme[Info.IconColor] or Library.Scheme.AccentColor
            end or "AccentColor",
            Parent = Content,
        })
        if IconImage then
            TextOffset = Big and 34 or 26
        end
    end

    local TextHolder = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(TextOffset, 0),
        Size = UDim2.new(1, -TextOffset, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = Content,
    })
    New("UIListLayout", { Padding = UDim.new(0, 3), Parent = TextHolder })

    local function ColorOf(Value, Fallback)
        if typeof(Value) == "Color3" then
            return function() return Value end
        elseif type(Value) == "string" then
            return Value
        end
        return Fallback
    end

    local TitleLabel = New("TextLabel", {
        FontFace = BoldFont,
        TextColor3 = ColorOf(Info.TitleColor, "FontColor"),
        Text = Notification.Title or "",
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = Notification.Title ~= nil and Notification.Title ~= "",
        LayoutOrder = 1,
        Parent = TextHolder,
    })

    local DescriptionLabel = New("TextLabel", {
        TextColor3 = ColorOf(Info.DescriptionColor, "MutedColor"),
        Text = Notification.Description,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = Notification.Description ~= "",
        LayoutOrder = 2,
        Parent = TextHolder,
    })

    local BarHolder = New("Frame", {
        BackgroundColor3 = "ElementColor",
        Size = UDim2.new(1, 0, 0, 2),
        LayoutOrder = 2,
        Parent = Card,
    })
    local Bar = New("Frame", {
        BackgroundColor3 = "AccentColor",
        Size = UDim2.fromScale(1, 1),
        Parent = BarHolder,
    })
    if Notification.Steps then
        Bar.Size = UDim2.fromScale(0, 1)
    end

    local function SyncHeight()
        Wrapper.Size = UDim2.new(1, 0, 0, Unscale(Card.AbsoluteSize.Y))
    end
    Card:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        if not Notification.Destroyed then
            SyncHeight()
        end
    end)
    task.defer(SyncHeight)

    function Notification:Resize()
        SyncHeight()
    end

    function Notification:ChangeTitle(Text)
        Notification.Title = Text
        TitleLabel.Text = Text or ""
        TitleLabel.Visible = Text ~= nil and Text ~= ""
    end

    function Notification:ChangeDescription(Text)
        Notification.Description = tostring(Text or "")
        DescriptionLabel.Text = Notification.Description
        DescriptionLabel.Visible = Notification.Description ~= ""
    end

    function Notification:ChangeStep(Step)
        if not Notification.Steps then
            return
        end
        Notification.CurrentStep = math.clamp(Step, 0, Notification.Steps)
        Tween(Bar, { Size = UDim2.fromScale(Notification.CurrentStep / Notification.Steps, 1) })
    end

    function Notification:Destroy()
        if Notification.Destroyed then
            return
        end
        Notification.Destroyed = true
        Library.Notifications[Wrapper] = nil
        Tween(Card, { Position = Hidden }, Library.NotifyTweenInfo)
        task.delay(0.25, function()
            Tween(Wrapper, { Size = UDim2.new(1, 0, 0, 0) }, Library.FastTweenInfo)
            task.wait(0.12)
            Wrapper:Destroy()
        end)
        if Info.Callback then
            Library:SafeCallback(Info.Callback, Notification)
        end
    end

    Library.Notifications[Wrapper] = Notification
    Tween(Card, { Position = Shown }, Library.NotifyTweenInfo)

    if Info.SoundId then
        local SoundId = tostring(Info.SoundId):gsub("%D", "")
        local Sound = New("Sound", {
            SoundId = "rbxassetid://" .. SoundId,
            Volume = Info.Volume or 3,
            Parent = SoundService,
        })
        Sound.Ended:Connect(function()
            Sound:Destroy()
        end)
        Sound:Play()
    end

    if typeof(Notification.Time) == "Instance" then
        local Watched = Notification.Time
        Bar.Size = UDim2.fromScale(1, 1)
        local Connection
        Connection = Watched.AncestryChanged:Connect(function(_, Parent)
            if not Parent then
                Connection:Disconnect()
                Notification:Destroy()
            end
        end)
    elseif not Notification.Persist then
        if not Notification.Steps then
            Tween(Bar, { Size = UDim2.fromScale(0, 1) }, TweenInfo.new(Notification.Time, Enum.EasingStyle.Linear))
        end
        task.delay(Notification.Time, function()
            Notification:Destroy()
        end)
    end

    return Notification
end

--// Floating info panels (watermark / keybinds) \\--

local function FloatingPanel(Name, Position)
    local Frame = New("Frame", {
        Name = Name,
        BackgroundColor3 = "MainColor",
        Position = Position,
        Size = UDim2.fromOffset(0, 0),
        AutomaticSize = Enum.AutomaticSize.XY,
        Visible = false,
        Parent = FloatLayer,
    })
    Corner(Frame, 4)
    Stroke(Frame)
    AddScale(Frame)
    local Accent = New("Frame", {
        BackgroundColor3 = "AccentColor",
        Size = UDim2.new(1, 0, 0, 2),
        ZIndex = 2,
        Parent = Frame,
    })
    Corner(Accent, 2)
    Library:MakeDraggable(Frame, Frame, true)
    return Frame
end

local WatermarkFrame = FloatingPanel("Watermark", UDim2.fromOffset(12, 12))
local WatermarkLabel = New("TextLabel", {
    Text = "",
    TextSize = 13,
    AutomaticSize = Enum.AutomaticSize.XY,
    Size = UDim2.fromOffset(0, 0),
    Parent = WatermarkFrame,
})
Padding(WatermarkLabel, 7, 5, 10, 10)
Library.WatermarkFrame = WatermarkFrame

function Library:SetWatermark(Text)
    WatermarkLabel.Text = tostring(Text)
end

function Library:SetWatermarkVisibility(Visible)
    WatermarkFrame.Visible = Visible == true
end

local KeybindFrame = FloatingPanel("Keybinds", UDim2.new(0, 12, 0.5, -60))
KeybindFrame.AutomaticSize = Enum.AutomaticSize.Y
KeybindFrame.Size = UDim2.fromOffset(220, 0)
New("UIListLayout", { Parent = KeybindFrame })
New("TextLabel", {
    FontFace = MediumFont,
    Text = "keybinds",
    TextSize = 13,
    Size = UDim2.new(1, 0, 0, 24),
    LayoutOrder = 1,
    Parent = KeybindFrame,
})
local KeybindContainer = New("Frame", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    LayoutOrder = 2,
    Parent = KeybindFrame,
})
New("UIListLayout", { Padding = UDim.new(0, 1), Parent = KeybindContainer })
Padding(KeybindContainer, 0, 7, 8, 8)

Library.KeybindFrame = KeybindFrame
Library.KeybindContainer = KeybindContainer

--// Draggable labels / buttons (useful on mobile) \\--

local function DraggableBase()
    local Frame = New("TextButton", {
        BackgroundColor3 = "MainColor",
        BackgroundTransparency = 0,
        Position = UDim2.fromOffset(12, 60),
        Size = UDim2.fromOffset(0, 30),
        AutomaticSize = Enum.AutomaticSize.X,
        TextSize = 13,
        Parent = FloatLayer,
    })
    Corner(Frame, 6)
    Stroke(Frame)
    Padding(Frame, 0, 0, 12, 12)
    return Frame
end

function Library:AddDraggableLabel(Text, Icon)
    if type(Text) == "table" then
        Icon = Text.Icon
        Text = Text.Text
    end
    local Label = { Connections = {}, Destroyed = false }
    local Frame = DraggableBase()
    Frame.Text = tostring(Text or "")
    Label.Label = Frame
    Label.Scale = AddScale(Frame)
    Library:MakeDraggable(Frame, Frame, true)

    local IconImage = nil
    function Label:SetIcon(NewIcon)
        if IconImage then
            IconImage:Destroy()
            IconImage = nil
        end
        if NewIcon then
            IconImage = Library:CreateIcon(NewIcon, {
                Size = UDim2.fromOffset(14, 14),
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(0, -6, 0.5, 0),
                ImageColor3 = "AccentColor",
                Parent = Frame,
            })
            Frame:FindFirstChildOfClass("UIPadding").PaddingLeft = UDim.new(0, IconImage and 32 or 12)
            if IconImage then
                IconImage.Position = UDim2.new(0, -6, 0.5, 0)
            end
        end
    end
    function Label:SetText(NewText)
        Frame.Text = tostring(NewText)
    end
    function Label:SetVisible(Visible)
        Frame.Visible = Visible
    end
    function Label:SetIconPosition() end
    function Label:Destroy()
        Label.Destroyed = true
        Frame:Destroy()
    end
    Label:SetIcon(Icon)
    return Label
end

function Library:AddDraggableButton(Text, Func, ExcludeScaling, ExcludeDragging)
    if type(Text) == "table" then
        Func = Text.Func or Text.Callback
        ExcludeScaling = Text.ExcludeScaling
        ExcludeDragging = Text.ExcludeDragging
        Text = Text.Text
    end
    local Button = { Connections = {}, Destroyed = false }
    local Frame = DraggableBase()
    Frame.Text = tostring(Text or "")
    Button.Button = Frame
    if not ExcludeScaling then
        AddScale(Frame)
    end
    if not ExcludeDragging then
        Library:MakeDraggable(Frame, Frame, true)
    end
    local DownAt = nil
    Frame.MouseButton1Down:Connect(function()
        DownAt = MousePos()
    end)
    Frame.MouseButton1Up:Connect(function()
        -- Only treat as a click if the button wasn't dragged
        if DownAt and (MousePos() - DownAt).Magnitude < 6 then
            Library:SafeCallback(Func, Button)
        end
        DownAt = nil
    end)
    function Button:SetText(NewText)
        Frame.Text = tostring(NewText)
    end
    function Button:Destroy()
        Button.Destroyed = true
        Frame:Destroy()
    end
    return Button
end

function Library:AddDraggableImageButton(Icon, IconSize, Func, ExcludeScaling, ExcludeDragging)
    if type(Icon) == "table" and not Icon.Url then
        IconSize = Icon.IconSize
        Func = Icon.Func or Icon.Callback
        ExcludeScaling = Icon.ExcludeScaling
        ExcludeDragging = Icon.ExcludeDragging
        Icon = Icon.Icon
    end
    local Button = Library:AddDraggableButton("", Func, ExcludeScaling, ExcludeDragging)
    local Frame = Button.Button
    Frame.AutomaticSize = Enum.AutomaticSize.None
    Frame:FindFirstChildOfClass("UIPadding"):Destroy()
    local Image = New("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        ImageColor3 = "FontColor",
        Parent = Frame,
    })
    Button.IconImage = Image
    function Button:SetIcon(NewIcon)
        Library:ApplyIcon(Image, NewIcon)
    end
    function Button:SetIconSize(Size)
        Size = Size or 18
        Image.Size = UDim2.fromOffset(Size, Size)
        Frame.Size = UDim2.fromOffset(Size + 16, Size + 16)
    end
    Button:SetIcon(Icon)
    Button:SetIconSize(IconSize)
    return Button
end

--// Loading screen \\--

function Library:CreateLoading(Info)
    Info = Library:Validate(Info, {
        Title = "Loading",
        LoadingIcon = "loader-circle",
        LoadingIconTweenTime = 1,
        CurrentStep = 0,
        TotalSteps = 1,
        WindowWidth = 360,
    })

    local Loading = {
        CurrentStep = Info.CurrentStep,
        TotalSteps = Info.TotalSteps,
        TweenTime = Info.LoadingIconTweenTime,
        Destroyed = false,
    }

    local Frame = New("CanvasGroup", {
        BackgroundColor3 = "BackgroundColor",
        BackgroundTransparency = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(Info.WindowWidth, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        GroupTransparency = 1,
        Parent = WindowLayer,
    })
    Corner(Frame, Library.CornerRadius)
    AddScale(Frame)
    local Outline = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(1, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = 10,
        Parent = Frame,
    })
    Corner(Outline, Library.CornerRadius)
    Stroke(Outline)

    local Body = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = Frame,
    })
    Padding(Body, 20, 20, 22, 22)
    New("UIListLayout", { Padding = UDim.new(0, 12), HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = Body })

    local Header = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 26),
        LayoutOrder = 1,
        Parent = Body,
    })
    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 6),
        Parent = Header,
    })
    New("TextLabel", {
        FontFace = BoldFont,
        Text = Info.Title,
        TextSize = 20,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromScale(0, 1),
        Parent = Header,
    })
    if Info.Icon then
        Library:CreateIcon(Info.Icon, {
            Size = Info.IconSize or UDim2.fromOffset(20, 20),
            ImageColor3 = "AccentColor",
            LayoutOrder = 2,
            Parent = Header,
        })
    end

    local Spinner = New("ImageLabel", {
        Size = UDim2.fromOffset(30, 30),
        ImageColor3 = Info.LoadingIconColor and function() return Info.LoadingIconColor end or "AccentColor",
        LayoutOrder = 2,
        Parent = Body,
    })
    Library:ApplyIcon(Spinner, Info.LoadingIcon)

    local MessageLabel = New("TextLabel", {
        FontFace = MediumFont,
        Text = "Loading...",
        TextSize = 14,
        TextWrapped = true,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 3,
        Parent = Body,
    })
    local DescriptionLabel = New("TextLabel", {
        TextColor3 = "MutedColor",
        Text = "",
        TextSize = 13,
        TextWrapped = true,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = false,
        LayoutOrder = 4,
        Parent = Body,
    })
    local ProgressBack = New("Frame", {
        BackgroundColor3 = "ElementColor",
        Size = UDim2.new(1, 0, 0, 6),
        LayoutOrder = 5,
        Parent = Body,
    })
    Corner(ProgressBack, 3)
    local ProgressFill = New("Frame", {
        BackgroundColor3 = "AccentColor",
        Size = UDim2.fromScale(0, 1),
        Parent = ProgressBack,
    })
    Corner(ProgressFill, 3)

    local ErrorButtons = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 28),
        Visible = false,
        LayoutOrder = 6,
        Parent = Body,
    })
    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Padding = UDim.new(0, 8),
        Parent = ErrorButtons,
    })

    local SpinConnection = RunService.RenderStepped:Connect(function(Delta)
        Spinner.Rotation = (Spinner.Rotation + Delta * 360 / math.max(Loading.TweenTime, 0.05)) % 360
    end)

    local function UpdateProgress()
        local Alpha = Loading.TotalSteps > 0 and math.clamp(Loading.CurrentStep / Loading.TotalSteps, 0, 1) or 0
        Tween(ProgressFill, { Size = UDim2.fromScale(Alpha, 1) })
    end

    function Loading:SetMessage(Text)
        MessageLabel.Text = tostring(Text)
    end
    function Loading:SetDescription(Text)
        DescriptionLabel.Text = tostring(Text or "")
        DescriptionLabel.Visible = DescriptionLabel.Text ~= ""
    end
    function Loading:SetLoadingIcon(Icon)
        Library:ApplyIcon(Spinner, Icon)
    end
    function Loading:SetLoadingIconColor(Color)
        Library:AddToRegistry(Spinner, { ImageColor3 = function() return Color end })
    end
    function Loading:SetLoadingIconTweenTime(Time)
        Loading.TweenTime = Time
    end
    function Loading:SetCurrentStep(Step)
        Loading.CurrentStep = Step
        UpdateProgress()
    end
    function Loading:SetTotalSteps(Steps)
        Loading.TotalSteps = Steps
        UpdateProgress()
    end
    function Loading:SetWindowWidth(Width)
        Frame.Size = UDim2.fromOffset(Width, 0)
    end
    function Loading:SetWindowHeight() end
    function Loading:SetContentWidth() end
    function Loading:SetSidebarWidth() end
    function Loading:ShowSidebarPage() end

    function Loading:SetErrorButtons(Buttons)
        for _, Child in ipairs(ErrorButtons:GetChildren()) do
            if Child:IsA("GuiButton") then
                Child:Destroy()
            end
        end
        for Index, ButtonInfo in ipairs(Buttons or {}) do
            local Primary = ButtonInfo.Variant ~= "Secondary"
            local Button = New("TextButton", {
                BackgroundColor3 = Primary and "AccentColor" or "ElementColor",
                BackgroundTransparency = 0,
                TextColor3 = Primary and "WhiteColor" or "FontColor",
                Text = ButtonInfo.Title or ButtonInfo.Text or "OK",
                TextSize = 13,
                AutomaticSize = Enum.AutomaticSize.X,
                Size = UDim2.fromOffset(0, 28),
                LayoutOrder = Index,
                Parent = ErrorButtons,
            })
            Corner(Button, 4)
            Padding(Button, 0, 0, 14, 14)
            Button.Activated:Connect(function()
                Library:SafeCallback(ButtonInfo.Callback or ButtonInfo.Func, Loading)
            end)
        end
    end

    function Loading:SetErrorMessage(Text)
        MessageLabel.Text = tostring(Text)
    end

    function Loading:ShowErrorPage(Message, Buttons)
        Spinner.Visible = false
        ProgressBack.Visible = false
        Library:AddToRegistry(MessageLabel, { TextColor3 = "RedColor" })
        MessageLabel.Text = tostring(Message or "Something went wrong")
        if Buttons then
            Loading:SetErrorButtons(Buttons)
        end
        ErrorButtons.Visible = #ErrorButtons:GetChildren() > 1
    end

    function Loading:Destroy()
        if Loading.Destroyed then
            return
        end
        Loading.Destroyed = true
        SpinConnection:Disconnect()
        Frame:Destroy()
        if Library.ActiveLoading == Loading then
            Library.ActiveLoading = nil
        end
    end

    function Loading:Continue()
        if Loading.Destroyed then
            return
        end
        Tween(Frame, { GroupTransparency = 1 }, Library.WindowAnimationInfo)
        task.wait(0.25)
        Loading:Destroy()
        if Library.Window and Library.Window.PendingShow then
            Library.Window.PendingShow = false
            Library:Toggle(true)
        end
    end

    Library.ActiveLoading = Loading
    UpdateProgress()
    Tween(Frame, { GroupTransparency = 0 }, Library.WindowAnimationInfo)
    return Loading
end

--// Elements \\--

local BaseGroupbox = {}
BaseGroupbox.__index = BaseGroupbox
Library.BaseGroupbox = BaseGroupbox

local ElementOrder = 0
local function NextOrder()
    ElementOrder = ElementOrder + 1
    return ElementOrder
end

local ROW_HEIGHT = 22

local function ApplyVisibility(Element)
    if Element.Holder then
        Element.Holder.Visible = Element.Visible ~= false and Element.SearchVisible ~= false
    end
    local Box = Element.Parent
    if Box and Box.Resize then
        Box:Resize()
    end
end

-- Shared bookkeeping for every element type.
local function Finalize(Box, Element, Info, Idx, Registry)
    Element.Parent = Box
    Element.Visible = Info.Visible ~= false
    Element.Connections = Element.Connections or {}
    Element.Destroyed = false
    table.insert(Box.Elements, Element)

    if Info.Tooltip or Info.DisabledTooltip then
        Element.TooltipTable = Library:AddTooltip(Info.Tooltip, Info.DisabledTooltip, Element.Holder)
        Element.TooltipTable.Disabled = Element.Disabled == true
    end

    if not Element.SetVisible then
        function Element:SetVisible(Visible)
            Element.Visible = Visible ~= false
            ApplyVisibility(Element)
        end
    end

    if not Element.Destroy then
        function Element:Destroy()
            if Element.Destroyed then
                return
            end
            Element.Destroyed = true
            for _, Connection in ipairs(Element.Connections) do
                Connection:Disconnect()
            end
            if Element.TooltipTable then
                Element.TooltipTable:Destroy()
            end
            for _, Addon in ipairs(Element.Addons or {}) do
                if Addon.Destroy then
                    Addon:Destroy()
                end
            end
            local Index = table.find(Box.Elements, Element)
            if Index then
                table.remove(Box.Elements, Index)
            end
            if Idx ~= nil and Registry and Registry[Idx] == Element then
                Registry[Idx] = nil
            end
            Element.Holder:Destroy()
            if Box.Resize then
                Box:Resize()
            end
        end
    end

    if Idx ~= nil and Registry then
        Registry[Idx] = Element
    end

    ApplyVisibility(Element)
    return Element
end

local function SetTooltipDisabled(Element)
    if Element.TooltipTable then
        Element.TooltipTable.Disabled = Element.Disabled == true
        Element.TooltipTable:Refresh()
    end
end

-- The area to the right of a row that hosts keypickers, colour pickers and settings chips.
local function GetAddonArea(Element, RightOffset)
    if Element.AddonArea then
        return Element.AddonArea
    end
    local Area = New("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = Element.AddonPosition or UDim2.new(1, -(RightOffset or 0), 0.5, 0),
        Size = UDim2.fromScale(0, 1),
        AutomaticSize = Enum.AutomaticSize.X,
        ZIndex = 3,
        Parent = Element.AddonParent or Element.Holder,
    })
    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 4),
        Parent = Area,
    })
    Element.AddonArea = Area

    -- Keep the row label from running under the addons
    if Element.TextLabel and not Element.KeepLabelWidth then
        local BaseOffset = Element.LabelRightInset or 0
        local function Fit()
            local Width = Unscale(Area.AbsoluteSize.X)
            Element.TextLabel.Size = UDim2.new(1, -(BaseOffset + Width + (Width > 0 and 6 or 0)) - (Element.LabelLeftInset or 0), 1, 0)
        end
        Area:GetPropertyChangedSignal("AbsoluteSize"):Connect(Fit)
        task.defer(Fit)
    end
    return Area
end

local function Chip(Parent, Text, Order)
    local Button = New("TextButton", {
        BackgroundColor3 = "ElementColor",
        BackgroundTransparency = 0,
        TextColor3 = "MutedColor",
        Text = Text,
        TextSize = 12,
        Size = UDim2.fromOffset(0, 16),
        AutomaticSize = Enum.AutomaticSize.X,
        LayoutOrder = Order or 0,
        Parent = Parent,
    })
    Corner(Button, 4)
    Padding(Button, 0, 0, 5, 5)
    New("UISizeConstraint", { MinSize = Vector2.new(18, 16), Parent = Button })
    local ChipStroke = Stroke(Button, "AccentColor", 1)
    return Button, ChipStroke
end

local function HoverOverlay(Button, Radius)
    local Overlay = New("Frame", {
        BackgroundColor3 = "WhiteColor",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 2,
        Parent = Button,
    })
    Corner(Overlay, Radius or 4)
    Button.MouseEnter:Connect(function()
        Tween(Overlay, { BackgroundTransparency = 0.93 }, Library.FastTweenInfo)
    end)
    Button.MouseLeave:Connect(function()
        Tween(Overlay, { BackgroundTransparency = 1 }, Library.FastTweenInfo)
    end)
    return Overlay
end

local function MakeRow(Box, Height)
    return New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, Height or ROW_HEIGHT),
        LayoutOrder = NextOrder(),
        Parent = Box.Container,
    })
end

local function RowLabel(Parent, Text, Props)
    local Properties = {
        Text = Text or "",
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Size = UDim2.fromScale(1, 1),
        Parent = Parent,
    }
    for Key, Value in pairs(Props or {}) do
        Properties[Key] = Value
    end
    return New("TextLabel", Properties)
end

local function ParseArgs(A, B)
    -- Supports (Idx, Info) and (Info) where Info.Idx is optional
    if type(A) == "table" then
        return A.Idx, A
    end
    return A, B or {}
end

--// Addons: KeyPicker \\--

local ModifierKeys = {
    LeftShift = true, RightShift = true, LeftControl = true, RightControl = true,
    LeftAlt = true, RightAlt = true, LeftSuper = true, RightSuper = true,
}

local MouseButtonNames = {
    [Enum.UserInputType.MouseButton1] = "MB1",
    [Enum.UserInputType.MouseButton2] = "MB2",
    [Enum.UserInputType.MouseButton3] = "MB3",
}

local function NormalizeKey(Key)
    if Key == nil or Key == "" then
        return "None"
    end
    if typeof(Key) == "EnumItem" then
        if Key.EnumType == Enum.UserInputType then
            return MouseButtonNames[Key] or Key.Name
        end
        return Key.Name
    end
    return tostring(Key)
end

local function KeyToEnum(Value)
    if Value == "MB1" then
        return Enum.UserInputType.MouseButton1
    elseif Value == "MB2" then
        return Enum.UserInputType.MouseButton2
    elseif Value == "MB3" then
        return Enum.UserInputType.MouseButton3
    end
    local Ok, KeyCode = pcall(function()
        return Enum.KeyCode[Value]
    end)
    return Ok and KeyCode or nil
end

local function IsKeyHeld(Value)
    local Key = KeyToEnum(Value)
    if not Key then
        return false
    end
    if Key.EnumType == Enum.UserInputType then
        return UserInputService:IsMouseButtonPressed(Key)
    end
    return UserInputService:IsKeyDown(Key)
end

local function InputKeyName(Input)
    if Input.UserInputType == Enum.UserInputType.Keyboard then
        return Input.KeyCode.Name
    end
    return MouseButtonNames[Input.UserInputType]
end

local function AddKeyPickerTo(Parent, Idx, Info)
    Idx, Info = ParseArgs(Idx, Info)
    Info = Info or {}

    local KeyPicker = {
        Idx = Idx,
        Type = "KeyPicker",
        Text = Info.Text or Parent.Text or tostring(Idx),
        Value = NormalizeKey(Info.Default),
        Modifiers = Info.DefaultModifiers or {},
        Mode = Info.Mode or "Toggle",
        Modes = Info.Modes or { "Always", "Toggle", "Hold" },
        Blacklisted = Info.Blacklisted or {},
        BlacklistedModifiers = Info.BlacklistedModifiers or {},
        Whitelisted = Info.Whitelisted,
        WhitelistedModifiers = Info.WhitelistedModifiers,
        SyncToggleState = Info.SyncToggleState == true,
        NoUI = Info.NoUI == true,
        Toggled = false,
        Picking = false,
        Callback = Info.Callback,
        Changed = Info.Changed or Info.ChangedCallback,
        Clicked = Info.Clicked,
        Parent = Parent,
        Connections = {},
        Destroyed = false,
    }

    if Parent.Type == "Button" or Parent.Type == "SubButton" then
        KeyPicker.Mode = "Press"
        KeyPicker.Modes = { "Press" }
    end
    if not table.find(KeyPicker.Modes, KeyPicker.Mode) then
        table.insert(KeyPicker.Modes, KeyPicker.Mode)
    end
    if KeyPicker.SyncToggleState and Parent.Type == "Toggle" then
        KeyPicker.Toggled = Parent.Value
    end

    local Area = GetAddonArea(Parent)
    local Picker, PickerStroke = Chip(Area, "-", 1)
    KeyPicker.Holder = Picker

    -- Entry in the keybind list
    local Entry = New("TextButton", {
        Text = "",
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = "MutedColor",
        Size = UDim2.new(1, 0, 0, 18),
        Visible = false,
        Parent = KeybindContainer,
    })
    Entry.Activated:Connect(function()
        if KeyPicker.Mode == "Toggle" then
            KeyPicker:DoClick()
        end
    end)

    -- Mode menu (right click)
    local ModeMenu = New("Frame", {
        BackgroundColor3 = "MainColor",
        Size = UDim2.fromOffset(80, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = false,
        Parent = OverlayLayer,
    })
    Corner(ModeMenu, 4)
    Stroke(ModeMenu)
    Padding(ModeMenu, 3, 3, 3, 3)
    AddScale(ModeMenu)
    New("UIListLayout", { Parent = ModeMenu })

    local ModeButtons = {}
    local ModePopup
    ModePopup = {
        Frame = ModeMenu,
        Anchor = Picker,
        Close = function()
            ModeMenu.Visible = false
            Library:ClosePopup(ModePopup)
        end,
        Follow = function()
            PlaceBelow(ModeMenu, Picker, 4, true)
        end,
    }

    local function RefreshModeButtons()
        for Mode, Button in pairs(ModeButtons) do
            Library:AddToRegistry(Button, { TextColor3 = KeyPicker.Mode == Mode and "AccentColor" or "MutedColor" })
        end
    end

    for Index, Mode in ipairs(KeyPicker.Modes) do
        local Button = New("TextButton", {
            Text = Mode,
            TextSize = 13,
            Size = UDim2.new(1, 0, 0, 20),
            LayoutOrder = Index,
            Parent = ModeMenu,
        })
        Corner(Button, 3)
        HoverOverlay(Button, 3)
        Button.Activated:Connect(function()
            KeyPicker.Mode = Mode
            KeyPicker.Toggled = (Mode == "Always") or (Mode == "Toggle" and KeyPicker.Toggled) or false
            RefreshModeButtons()
            KeyPicker:Update()
            ModePopup.Close()
        end)
        ModeButtons[Mode] = Button
    end
    RefreshModeButtons()

    function KeyPicker:GetDisplay()
        if KeyPicker.Value == "None" then
            return "-"
        end
        local Parts = {}
        for _, Modifier in ipairs(KeyPicker.Modifiers) do
            table.insert(Parts, Library:GetKeyString(Modifier))
        end
        table.insert(Parts, Library:GetKeyString(KeyPicker.Value))
        return table.concat(Parts, "+")
    end

    function KeyPicker:Display(PickerText)
        Picker.Text = PickerText or (KeyPicker.Picking and "..." or KeyPicker:GetDisplay())
        Tween(PickerStroke, { Transparency = KeyPicker.Picking and 0 or 1 }, Library.FastTweenInfo)
        Library:AddToRegistry(Picker, { TextColor3 = KeyPicker.Picking and "AccentColor" or "MutedColor" })
    end

    function KeyPicker:GetState()
        if KeyPicker.Mode == "Always" then
            return true
        elseif KeyPicker.Mode == "Press" then
            return false
        end
        return KeyPicker.Toggled
    end

    function KeyPicker:Update()
        KeyPicker:Display()
        local State = KeyPicker:GetState()
        local HasKey = KeyPicker.Value ~= "None"
        Entry.Text = string.format("[%s] %s (%s)", KeyPicker:GetDisplay(), StripRichText(KeyPicker.Text), KeyPicker.Mode)
        Entry.Visible = not KeyPicker.NoUI and HasKey and (State or Library.ShowAllKeybinds) and KeyPicker.Mode ~= "Always"
        Library:AddToRegistry(Entry, { TextColor3 = State and "AccentColor" or "MutedColor" })
    end

    function KeyPicker:SetText(Text)
        KeyPicker.Text = Text
        KeyPicker:Update()
    end

    function KeyPicker:OnChanged(Func)
        KeyPicker.Changed = Func
    end

    function KeyPicker:OnClick(Func)
        KeyPicker.Clicked = Func
    end

    function KeyPicker:RunChanged()
        Library:SafeCallback(KeyPicker.Changed, KeyToEnum(KeyPicker.Value) or KeyPicker.Value, KeyPicker.Modifiers)
        Library:SafeCallback(KeyPicker.ChangedCallback, KeyToEnum(KeyPicker.Value) or KeyPicker.Value, KeyPicker.Modifiers)
    end

    function KeyPicker:SetState(State)
        local Old = KeyPicker:GetState()
        KeyPicker.Toggled = State
        if KeyPicker.SyncToggleState and Parent.Type == "Toggle" and Parent.Value ~= State then
            Parent:SetValue(State)
        end
        KeyPicker:Update()
        if Old ~= KeyPicker:GetState() then
            Library:SafeCallback(KeyPicker.Callback, KeyPicker:GetState())
        end
    end

    function KeyPicker:DoClick()
        if KeyPicker.Mode == "Toggle" then
            KeyPicker:SetState(not KeyPicker.Toggled)
        elseif KeyPicker.Mode == "Press" then
            Library:SafeCallback(KeyPicker.Callback, true)
            if Parent.Type == "Button" or Parent.Type == "SubButton" then
                Parent:Fire(true)
            end
        end
        Library:SafeCallback(KeyPicker.Clicked)
    end

    function KeyPicker:SetValue(Data)
        if type(Data) ~= "table" then
            Data = { Data }
        end
        KeyPicker.Value = NormalizeKey(Data[1])
        if Data[2] and table.find(KeyPicker.Modes, Data[2]) then
            KeyPicker.Mode = Data[2]
            RefreshModeButtons()
        end
        KeyPicker.Modifiers = type(Data[3]) == "table" and Data[3] or KeyPicker.Modifiers
        if KeyPicker.Mode == "Always" then
            KeyPicker.Toggled = true
        end
        KeyPicker:Update()
        KeyPicker:RunChanged()
    end

    function KeyPicker:IsAllowed(KeyName, Modifiers)
        if table.find(KeyPicker.Blacklisted, KeyName) then
            return false
        end
        if KeyPicker.Whitelisted and not table.find(KeyPicker.Whitelisted, KeyName) then
            return false
        end
        for _, Modifier in ipairs(Modifiers) do
            if table.find(KeyPicker.BlacklistedModifiers, Modifier) then
                return false
            end
            if KeyPicker.WhitelistedModifiers and not table.find(KeyPicker.WhitelistedModifiers, Modifier) then
                return false
            end
        end
        return true
    end

    function KeyPicker:Matches(Input)
        if KeyPicker.Value == "None" or KeyPicker.Picking then
            return false
        end
        if InputKeyName(Input) ~= KeyPicker.Value then
            return false
        end
        for _, Modifier in ipairs(KeyPicker.Modifiers) do
            if not IsKeyHeld(Modifier) then
                return false
            end
        end
        return true
    end

    function KeyPicker:SetMenuVisibility(Visible)
        if Visible then
            ModeMenu.Visible = true
            ModePopup.Follow()
            Library:OpenPopup(ModePopup)
        else
            ModePopup.Close()
        end
    end

    local function StopPicking(KeyName, Modifiers)
        KeyPicker.Picking = false
        Library.IsPicking = false
        if KeyName and KeyPicker:IsAllowed(KeyName, Modifiers or {}) then
            KeyPicker.Value = KeyName
            KeyPicker.Modifiers = Modifiers or {}
            KeyPicker:Update()
            KeyPicker:RunChanged()
        else
            KeyPicker:Update()
        end
    end

    local function StartPicking()
        if KeyPicker.Picking then
            return
        end
        KeyPicker.Picking = true
        Library.IsPicking = true
        KeyPicker:Display()

        local PendingModifier = nil
        local Began, Ended
        local function Finish(KeyName, Modifiers)
            Began:Disconnect()
            Ended:Disconnect()
            -- Defer so the same key press doesn't immediately trigger the new bind
            task.defer(StopPicking, KeyName, Modifiers)
        end

        Began = UserInputService.InputBegan:Connect(function(Input)
            local KeyName = InputKeyName(Input)
            if not KeyName then
                return
            end
            if Input.KeyCode == Enum.KeyCode.Escape then
                Finish("None", {})
                return
            end
            if ModifierKeys[KeyName] then
                PendingModifier = KeyName
                return
            end
            local Held = {}
            for Modifier in pairs(ModifierKeys) do
                if UserInputService:IsKeyDown(Enum.KeyCode[Modifier]) then
                    table.insert(Held, Modifier)
                end
            end
            Finish(KeyName, Held)
        end)
        Ended = UserInputService.InputEnded:Connect(function(Input)
            local KeyName = InputKeyName(Input)
            if KeyName and KeyName == PendingModifier then
                Finish(KeyName, {})
            end
        end)
    end

    Picker.Activated:Connect(StartPicking)
    Picker.MouseButton2Click:Connect(function()
        if #KeyPicker.Modes > 1 then
            KeyPicker:SetMenuVisibility(not ModeMenu.Visible)
        end
    end)

    function KeyPicker:Destroy()
        KeyPicker.Destroyed = true
        Picker:Destroy()
        Entry:Destroy()
        ModeMenu:Destroy()
        local Index = table.find(Library.KeyPickers, KeyPicker)
        if Index then
            table.remove(Library.KeyPickers, Index)
        end
        if Idx ~= nil and Options[Idx] == KeyPicker then
            Options[Idx] = nil
        end
    end

    if KeyPicker.Mode == "Always" then
        KeyPicker.Toggled = true
    end

    Parent.Addons = Parent.Addons or {}
    table.insert(Parent.Addons, KeyPicker)
    table.insert(Library.KeyPickers, KeyPicker)
    if Idx ~= nil then
        Options[Idx] = KeyPicker
    end
    KeyPicker:Update()
    return KeyPicker
end

--// Addons: ColorPicker \\--

local HueSequence = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
    ColorSequenceKeypoint.new(1 / 6, Color3.fromHSV(1 / 6, 1, 1)),
    ColorSequenceKeypoint.new(2 / 6, Color3.fromHSV(2 / 6, 1, 1)),
    ColorSequenceKeypoint.new(3 / 6, Color3.fromHSV(3 / 6, 1, 1)),
    ColorSequenceKeypoint.new(4 / 6, Color3.fromHSV(4 / 6, 1, 1)),
    ColorSequenceKeypoint.new(5 / 6, Color3.fromHSV(5 / 6, 1, 1)),
    ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
})

local function AddColorPickerTo(Parent, Idx, Info)
    Idx, Info = ParseArgs(Idx, Info)
    Info = Info or {}

    local ColorPicker = {
        Idx = Idx,
        Type = "ColorPicker",
        Title = Info.Title,
        Value = Info.Default or Color3.new(1, 1, 1),
        Transparency = Info.Transparency or 0,
        HasTransparency = Info.Transparency ~= nil,
        Callback = Info.Callback,
        Changed = Info.Changed,
        Parent = Parent,
        Connections = {},
        Destroyed = false,
    }

    local Area = GetAddonArea(Parent)
    local Swatch = New("TextButton", {
        BackgroundTransparency = 0,
        Size = UDim2.fromOffset(22, 14),
        LayoutOrder = 2,
        Parent = Area,
    })
    Corner(Swatch, 3)
    Stroke(Swatch)
    ColorPicker.Holder = Swatch

    local Width = 196
    local Menu = New("Frame", {
        BackgroundColor3 = "MainColor",
        Size = UDim2.fromOffset(Width + 16, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = false,
        Parent = OverlayLayer,
    })
    Corner(Menu, 6)
    Stroke(Menu)
    Padding(Menu, 8, 8, 8, 8)
    AddScale(Menu)
    New("UIListLayout", { Padding = UDim.new(0, 8), Parent = Menu })

    if ColorPicker.Title then
        New("TextLabel", {
            FontFace = MediumFont,
            Text = ColorPicker.Title,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, 0, 0, 14),
            LayoutOrder = 0,
            Parent = Menu,
        })
    end

    local Top = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 150),
        LayoutOrder = 1,
        Parent = Menu,
    })

    local SatVib = New("TextButton", {
        BackgroundTransparency = 0,
        Size = UDim2.new(1, -22, 1, 0),
        Parent = Top,
    })
    Corner(SatVib, 4)
    local White = New("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), Size = UDim2.fromScale(1, 1), Parent = SatVib })
    Corner(White, 4)
    New("UIGradient", { Transparency = NumberSequence.new(0, 1), Parent = White })
    local Black = New("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), Size = UDim2.fromScale(1, 1), Parent = SatVib })
    Corner(Black, 4)
    New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0), Parent = Black })
    local SatVibCursor = New("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(8, 8),
        ZIndex = 3,
        Parent = SatVib,
    })
    Corner(SatVibCursor, 4)
    New("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 1.5, Parent = SatVibCursor })

    local Hue = New("TextButton", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.fromScale(1, 0),
        Size = UDim2.new(0, 14, 1, 0),
        Parent = Top,
    })
    Corner(Hue, 4)
    New("UIGradient", { Rotation = 90, Color = HueSequence, Parent = Hue })
    local HueCursor = New("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0),
        Size = UDim2.new(1, 4, 0, 3),
        ZIndex = 3,
        Parent = Hue,
    })
    Corner(HueCursor, 2)
    Stroke(HueCursor, "DarkColor")

    local Alpha, AlphaGradient, AlphaCursor = nil, nil, nil
    if ColorPicker.HasTransparency then
        Alpha = New("TextButton", {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 0,
            Size = UDim2.new(1, 0, 0, 12),
            LayoutOrder = 2,
            Parent = Menu,
        })
        Corner(Alpha, 4)
        AlphaGradient = New("UIGradient", { Transparency = NumberSequence.new(0, 1), Parent = Alpha })
        AlphaCursor = New("Frame", {
            BackgroundColor3 = Color3.new(1, 1, 1),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0, 0.5),
            Size = UDim2.new(0, 3, 1, 4),
            ZIndex = 3,
            Parent = Alpha,
        })
        Corner(AlphaCursor, 2)
        Stroke(AlphaCursor, "DarkColor")
    end

    local Inputs = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 22),
        LayoutOrder = 3,
        Parent = Menu,
    })
    New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), Parent = Inputs })

    local function SmallBox(Order, Placeholder)
        local Frame = New("Frame", {
            BackgroundColor3 = "ElementColor",
            Size = UDim2.new(0.5, -3, 1, 0),
            LayoutOrder = Order,
            Parent = Inputs,
        })
        Corner(Frame, 4)
        local Box = New("TextBox", {
            PlaceholderText = Placeholder,
            TextSize = 12,
            Size = UDim2.fromScale(1, 1),
            Parent = Frame,
        })
        return Box
    end
    local HexBox = SmallBox(1, "#ffffff")
    local RgbBox = SmallBox(2, "255, 255, 255")

    function ColorPicker:SetHSVFromRGB(Color)
        local H, S, V = Color:ToHSV()
        ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = H, S, V
    end
    ColorPicker:SetHSVFromRGB(ColorPicker.Value)

    function ColorPicker:Display()
        ColorPicker.Value = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib)
        Swatch.BackgroundColor3 = ColorPicker.Value
        Swatch.BackgroundTransparency = ColorPicker.HasTransparency and ColorPicker.Transparency or 0
        SatVib.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1)
        SatVibCursor.Position = UDim2.fromScale(ColorPicker.Sat, 1 - ColorPicker.Vib)
        HueCursor.Position = UDim2.fromScale(0.5, ColorPicker.Hue)
        if Alpha then
            Alpha.BackgroundColor3 = ColorPicker.Value
            AlphaCursor.Position = UDim2.fromScale(ColorPicker.Transparency, 0.5)
        end
        if not HexBox:IsFocused() then
            HexBox.Text = "#" .. ColorPicker.Value:ToHex()
        end
        if not RgbBox:IsFocused() then
            RgbBox.Text = string.format("%d, %d, %d",
                math.floor(ColorPicker.Value.R * 255 + 0.5),
                math.floor(ColorPicker.Value.G * 255 + 0.5),
                math.floor(ColorPicker.Value.B * 255 + 0.5))
        end
    end

    function ColorPicker:RunChanged()
        Library:SafeCallback(ColorPicker.Callback, ColorPicker.Value, ColorPicker.Transparency)
        Library:SafeCallback(ColorPicker.Changed, ColorPicker.Value, ColorPicker.Transparency)
    end

    function ColorPicker:Update()
        ColorPicker:Display()
        ColorPicker:RunChanged()
    end

    function ColorPicker:OnChanged(Func)
        ColorPicker.Changed = Func
    end

    function ColorPicker:SetValue(HSV, Transparency)
        if typeof(HSV) == "Color3" then
            return ColorPicker:SetValueRGB(HSV, Transparency)
        end
        ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = HSV[1], HSV[2], HSV[3]
        if Transparency ~= nil then
            ColorPicker.Transparency = Transparency
        end
        ColorPicker:Update()
    end

    function ColorPicker:SetValueRGB(Color, Transparency)
        ColorPicker:SetHSVFromRGB(Color)
        if Transparency ~= nil then
            ColorPicker.Transparency = Transparency
        end
        ColorPicker:Update()
    end

    HexBox.FocusLost:Connect(function()
        local Ok, Color = pcall(Color3.fromHex, HexBox.Text)
        if Ok and Color then
            ColorPicker:SetValueRGB(Color)
        else
            ColorPicker:Display()
        end
    end)
    RgbBox.FocusLost:Connect(function()
        local R, G, B = RgbBox.Text:match("(%d+)%D+(%d+)%D+(%d+)")
        if R then
            ColorPicker:SetValueRGB(Color3.fromRGB(math.clamp(tonumber(R), 0, 255), math.clamp(tonumber(G), 0, 255), math.clamp(tonumber(B), 0, 255)))
        else
            ColorPicker:Display()
        end
    end)

    local Dragging = nil
    local function UpdateDrag(Position)
        if Dragging == "SatVib" then
            local Rel = (Position - SatVib.AbsolutePosition) / SatVib.AbsoluteSize
            ColorPicker.Sat = math.clamp(Rel.X, 0, 1)
            ColorPicker.Vib = 1 - math.clamp(Rel.Y, 0, 1)
        elseif Dragging == "Hue" then
            ColorPicker.Hue = math.clamp((Position.Y - Hue.AbsolutePosition.Y) / Hue.AbsoluteSize.Y, 0, 1)
        elseif Dragging == "Alpha" then
            ColorPicker.Transparency = math.clamp((Position.X - Alpha.AbsolutePosition.X) / Alpha.AbsoluteSize.X, 0, 1)
        end
        ColorPicker:Update()
    end

    local function BindDrag(Target, Name)
        Target.InputBegan:Connect(function(Input)
            if IsClick(Input) then
                Dragging = Name
                UpdateDrag(Vector2.new(Input.Position.X, MousePos().Y))
                local Changed
                Changed = Input.Changed:Connect(function()
                    if Input.UserInputState == Enum.UserInputState.End then
                        Dragging = nil
                        Changed:Disconnect()
                    end
                end)
            end
        end)
    end
    BindDrag(SatVib, "SatVib")
    BindDrag(Hue, "Hue")
    if Alpha then
        BindDrag(Alpha, "Alpha")
    end
    table.insert(ColorPicker.Connections, UserInputService.InputChanged:Connect(function(Input)
        if Dragging and IsMove(Input) then
            UpdateDrag(MousePos())
        end
    end))

    local MenuPopup
    MenuPopup = {
        Frame = Menu,
        Anchor = Swatch,
        Close = function()
            Menu.Visible = false
            Dragging = nil
            Library:ClosePopup(MenuPopup)
        end,
        Follow = function()
            PlaceBelow(Menu, Swatch, 4, true)
        end,
    }
    ColorPicker.ColorMenu = MenuPopup

    Swatch.Activated:Connect(function()
        if Menu.Visible then
            MenuPopup.Close()
        else
            Menu.Visible = true
            MenuPopup.Follow()
            Library:OpenPopup(MenuPopup)
        end
    end)

    -- Right click to copy, shift + right click to paste
    Swatch.MouseButton2Click:Connect(function()
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            if Library.CopiedColor then
                ColorPicker:SetValueRGB(Library.CopiedColor[1], Library.CopiedColor[2])
            end
        else
            Library.CopiedColor = { ColorPicker.Value, ColorPicker.Transparency }
            Library:Notify({ Description = "Copied colour #" .. ColorPicker.Value:ToHex(), Time = 1.5, Icon = "clipboard-check" })
        end
    end)

    function ColorPicker:Destroy()
        ColorPicker.Destroyed = true
        for _, Connection in ipairs(ColorPicker.Connections) do
            Connection:Disconnect()
        end
        Swatch:Destroy()
        Menu:Destroy()
        if Idx ~= nil and Options[Idx] == ColorPicker then
            Options[Idx] = nil
        end
    end

    ColorPicker:Display()
    Parent.Addons = Parent.Addons or {}
    table.insert(Parent.Addons, ColorPicker)
    if Idx ~= nil then
        Options[Idx] = ColorPicker
    end
    return ColorPicker
end

--// Addons: Settings panel ("..." chip) \\--

local function AddSettingsTo(Parent, Info)
    Info = Info or {}
    local Area = GetAddonArea(Parent)
    local Gear = Chip(Area, "...", 3)

    local Panel = New("Frame", {
        BackgroundColor3 = "MainColor",
        Size = UDim2.fromOffset(Info.Width or 220, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = false,
        Parent = OverlayLayer,
    })
    Corner(Panel, 6)
    Stroke(Panel)
    AddScale(Panel)
    Padding(Panel, 8, 8, 10, 10)
    New("UIListLayout", { Padding = UDim.new(0, 6), Parent = Panel })

    local Settings = setmetatable({
        Type = "Settings",
        Container = Panel,
        Holder = Panel,
        Gear = Gear,
        Elements = {},
        Parent = Parent,
        Connections = {},
        Destroyed = false,
    }, BaseGroupbox)

    local PanelPopup
    PanelPopup = {
        Frame = Panel,
        Anchor = Gear,
        Close = function()
            Panel.Visible = false
            Library:ClosePopup(PanelPopup)
        end,
        Follow = function()
            PlaceBelow(Panel, Gear, 4, true)
        end,
    }
    Settings.Menu = PanelPopup

    function Settings:Resize() end
    function Settings:Open()
        Panel.Visible = true
        PanelPopup.Follow()
        Library:OpenPopup(PanelPopup)
    end
    function Settings:Close()
        PanelPopup.Close()
    end
    function Settings:Toggle()
        if Panel.Visible then
            Settings:Close()
        else
            Settings:Open()
        end
    end
    function Settings:SetWidth(Width)
        Panel.Size = UDim2.fromOffset(Width or 220, 0)
    end
    function Settings:Update() end
    function Settings:Destroy()
        Settings.Destroyed = true
        Gear:Destroy()
        Panel:Destroy()
    end

    Gear.Activated:Connect(function()
        Settings:Toggle()
    end)

    Parent.Addons = Parent.Addons or {}
    table.insert(Parent.Addons, Settings)
    Parent.Settings = Settings
    return Settings
end

local function AttachAddonMethods(Element, Allowed)
    if Allowed.KeyPicker then
        function Element:AddKeyPicker(Idx, Info)
            AddKeyPickerTo(Element, Idx, Info)
            return Element
        end
    end
    if Allowed.ColorPicker then
        function Element:AddColorPicker(Idx, Info)
            AddColorPickerTo(Element, Idx, Info)
            return Element
        end
    end
    function Element:AddSettings(Info)
        return AddSettingsTo(Element, Info)
    end
end

--// Label \\--

function BaseGroupbox:AddLabel(A, B, C)
    local Idx, Info
    if type(A) == "table" then
        Info = A
        Idx = A.Idx
    elseif type(B) == "table" then
        Idx, Info = A, B
    else
        Info = { Text = A, DoesWrap = B }
        Idx = C
    end
    Info.Text = Info.Text or ""

    local Label = {
        Type = "Label",
        Text = Info.Text,
        DoesWrap = Info.DoesWrap == true,
        Addons = {},
    }

    local Holder = MakeRow(self)
    Label.Holder = Holder
    Label.Container = Holder
    local TextLabel = RowLabel(Holder, Info.Text, { TextSize = Info.Size or 14 })
    Label.TextLabel = TextLabel

    if Label.DoesWrap then
        Holder.Size = UDim2.new(1, 0, 0, 0)
        Holder.AutomaticSize = Enum.AutomaticSize.Y
        TextLabel.TextWrapped = true
        TextLabel.TextTruncate = Enum.TextTruncate.None
        TextLabel.Size = UDim2.new(1, 0, 0, 0)
        TextLabel.AutomaticSize = Enum.AutomaticSize.Y
        TextLabel.TextColor3 = Library.Scheme.MutedColor
        Library:AddToRegistry(TextLabel, { TextColor3 = "MutedColor" })
        Label.KeepLabelWidth = true
    end

    function Label:SetText(Text)
        Label.Text = Text
        TextLabel.Text = Text
    end
    Label.Display = function() end

    AttachAddonMethods(Label, { KeyPicker = true, ColorPicker = true })
    return Finalize(self, Label, Info, Idx or (#Library.Labels + 1), Library.Labels)
end

--// Button \\--

local function CreateButtonBase(Owner, Info, Parent)
    local Button = {
        Type = Owner and "SubButton" or "Button",
        Text = Info.Text or "Button",
        Func = Info.Func or Info.Callback,
        DoubleClick = Info.DoubleClick == true,
        Icon = Info.Icon or Info.IconName,
        Risky = Info.Risky == true,
        Disabled = Info.Disabled == true,
        Variant = Info.Variant or "Primary",
        Addons = {},
        Connections = {},
    }

    local Base = New("TextButton", {
        BackgroundColor3 = function()
            if Button.Risky then
                return Library.Scheme.RedColor
            end
            return Button.Variant == "Secondary" and Library.Scheme.ElementColor or Library.Scheme.AccentColor
        end,
        BackgroundTransparency = 0,
        Size = UDim2.fromScale(1, 1),
        ClipsDescendants = true,
        Parent = Parent,
    })
    Corner(Base, 4)
    local Overlay = HoverOverlay(Base, 4)
    Button.Base = Base

    local Inner = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 3,
        Parent = Base,
    })
    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 5),
        Parent = Inner,
    })
    local TextColor = function()
        return Button.Variant == "Secondary" and not Button.Risky and Library.Scheme.FontColor or Library.Scheme.WhiteColor
    end
    local Label = New("TextLabel", {
        Text = Button.Text,
        TextSize = 13,
        TextColor3 = TextColor,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromScale(0, 1),
        TextTruncate = Enum.TextTruncate.AtEnd,
        LayoutOrder = 2,
        Parent = Inner,
    })
    New("UISizeConstraint", { MaxSize = Vector2.new(400, 100), Parent = Label })
    Button.Label = Label

    local IconImage = nil
    function Button:SetIcon(Icon)
        Button.Icon = Icon
        if IconImage then
            IconImage:Destroy()
            IconImage = nil
        end
        if Icon then
            IconImage = Library:CreateIcon(Icon, {
                Size = UDim2.fromOffset(14, 14),
                ImageColor3 = TextColor,
                LayoutOrder = 1,
                Parent = Inner,
            })
        end
        Button.IconImage = IconImage
    end
    Button:SetIcon(Button.Icon)

    local function UpdateColors()
        Base.BackgroundTransparency = Button.Disabled and 0.6 or 0
        Label.TextTransparency = Button.Disabled and 0.4 or 0
        Library:RefreshInstance(Base)
        Library:RefreshInstance(Label)
        if IconImage then
            Library:RefreshInstance(IconImage)
        end
    end
    Button.UpdateColors = UpdateColors

    local Confirming = false
    function Button:Fire(FromKeyPicker)
        if Button.Disabled then
            return
        end
        if Button.DoubleClick and not FromKeyPicker then
            if not Confirming then
                Confirming = true
                Label.Text = "Are you sure?"
                task.delay(1.5, function()
                    if Confirming then
                        Confirming = false
                        Label.Text = Button.Text
                    end
                end)
                return
            end
            Confirming = false
            Label.Text = Button.Text
        end
        Overlay.BackgroundTransparency = 0.8
        Tween(Overlay, { BackgroundTransparency = 0.93 }, Library.TweenInfo)
        Library:SafeCallback(Button.Func, FromKeyPicker == true)
    end

    Base.Activated:Connect(function()
        Button:Fire(false)
    end)

    function Button:SetText(Text)
        Button.Text = Text
        Label.Text = Text
    end
    function Button:SetDisabled(Disabled)
        Button.Disabled = Disabled == true
        UpdateColors()
        SetTooltipDisabled(Button)
    end
    function Button:SetRisky(Risky)
        Button.Risky = Risky == true
        UpdateColors()
    end

    Button.AddonParent = Base
    Button.AddonPosition = UDim2.new(1, -4, 0.5, 0)
    AttachAddonMethods(Button, { KeyPicker = true })
    UpdateColors()
    return Button
end

function BaseGroupbox:AddButton(A, B)
    local Info = type(A) == "table" and A or { Text = A, Func = B }
    local Holder = MakeRow(self)
    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 6),
        Parent = Holder,
    })

    local Button = CreateButtonBase(nil, Info, Holder)
    Button.Holder = Holder
    local SubButtons = { Button }

    local function Layout()
        local Count = #SubButtons
        for _, Item in ipairs(SubButtons) do
            Item.Base.Size = UDim2.new(1 / Count, -(6 * (Count - 1)) / Count, 1, 0)
        end
    end

    function Button:AddButton(SubA, SubB)
        local SubInfo = type(SubA) == "table" and SubA or { Text = SubA, Func = SubB }
        local Sub = CreateButtonBase(Button, SubInfo, Holder)
        Sub.Base.LayoutOrder = #SubButtons + 1
        table.insert(SubButtons, Sub)
        Layout()
        function Sub:SetVisible(Visible)
            Sub.Base.Visible = Visible ~= false
        end
        function Sub:Destroy()
            Sub.Base:Destroy()
            table.remove(SubButtons, table.find(SubButtons, Sub))
            Layout()
        end
        if SubInfo.Tooltip or SubInfo.DisabledTooltip then
            Sub.TooltipTable = Library:AddTooltip(SubInfo.Tooltip, SubInfo.DisabledTooltip, Sub.Base)
        end
        Library.Buttons[SubInfo.Idx or SubInfo.Text] = Sub
        return Sub
    end

    return Finalize(self, Button, Info, Info.Idx or Button.Text, Library.Buttons)
end

--// Toggle & Checkbox \\--

local function CreateToggle(Box, Idx, Info, IsCheckbox)
    Idx, Info = ParseArgs(Idx, Info)
    local Toggle = {
        Type = "Toggle",
        Text = Info.Text or tostring(Idx),
        Value = Info.Default == true,
        Risky = Info.Risky == true,
        Disabled = Info.Disabled == true,
        Callback = Info.Callback,
        Changed = Info.Changed,
        IsCheckbox = IsCheckbox,
        Addons = {},
    }

    local Holder = New("TextButton", {
        Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
        LayoutOrder = NextOrder(),
        Parent = Box.Container,
    })
    Toggle.Holder = Holder

    local Label = RowLabel(Holder, Toggle.Text, {
        TextColor3 = function()
            return Toggle.Risky and Library.Scheme.RedColor or Library.Scheme.FontColor
        end,
    })
    Toggle.TextLabel = Label

    local Switch, Knob, Check
    if IsCheckbox then
        Switch = New("Frame", {
            BackgroundColor3 = function()
                return Toggle.Value and Library.Scheme.AccentColor or Library.Scheme.ElementColor
            end,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.fromScale(0, 0.5),
            Size = UDim2.fromOffset(16, 16),
            Parent = Holder,
        })
        Corner(Switch, 4)
        Stroke(Switch)
        Check = Library:CreateIcon("check", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(12, 12),
            ImageColor3 = "WhiteColor",
            ImageTransparency = 1,
            Parent = Switch,
        })
        if not Check then
            Check = New("Frame", {
                BackgroundColor3 = "WhiteColor",
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(6, 6),
                Parent = Switch,
            })
            Corner(Check, 2)
        end
        Label.Position = UDim2.fromOffset(24, 0)
        Toggle.LabelLeftInset = 24
        Label.Size = UDim2.new(1, -24, 1, 0)
    else
        Switch = New("Frame", {
            BackgroundColor3 = function()
                return Toggle.Value and Library.Scheme.AccentColor or Library.Scheme.ElementColor
            end,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.fromScale(1, 0.5),
            Size = UDim2.fromOffset(30, 16),
            Parent = Holder,
        })
        Corner(Switch, 8)
        Knob = New("Frame", {
            BackgroundColor3 = "WhiteColor",
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 2, 0.5, 0),
            Size = UDim2.fromOffset(12, 12),
            Parent = Switch,
        })
        Corner(Knob, 6)
        Label.Size = UDim2.new(1, -36, 1, 0)
        Toggle.LabelRightInset = 36
    end
    Toggle.Switch = Switch
    Toggle.AddonPosition = UDim2.new(1, IsCheckbox and 0 or -36, 0.5, 0)

    function Toggle:Display(Animate)
        local Info2 = Animate == false and TweenInfo.new(0) or Library.TweenInfo
        local Fill = Toggle.Value and Library.Scheme.AccentColor or Library.Scheme.ElementColor
        Tween(Switch, { BackgroundColor3 = Fill, BackgroundTransparency = Toggle.Disabled and 0.5 or 0 }, Info2)
        if Knob then
            Tween(Knob, {
                Position = UDim2.new(0, Toggle.Value and 16 or 2, 0.5, 0),
                BackgroundTransparency = Toggle.Disabled and 0.5 or 0,
            }, Info2)
        elseif Check then
            if Check:IsA("ImageLabel") then
                Tween(Check, { ImageTransparency = Toggle.Value and 0 or 1 }, Info2)
            else
                Tween(Check, { BackgroundTransparency = Toggle.Value and 0 or 1 }, Info2)
            end
        end
        Label.TextTransparency = Toggle.Disabled and 0.5 or 0
    end

    function Toggle:OnChanged(Func)
        Toggle.Changed = Func
    end

    function Toggle:RunChanged()
        Library:SafeCallback(Toggle.Callback, Toggle.Value)
        Library:SafeCallback(Toggle.Changed, Toggle.Value)
    end

    function Toggle:SetValue(Value)
        Toggle.Value = Value == true
        Toggle:Display()
        for _, Addon in ipairs(Toggle.Addons) do
            if Addon.Type == "KeyPicker" and Addon.SyncToggleState and Addon.Toggled ~= Toggle.Value then
                Addon.Toggled = Toggle.Value
                Addon:Update()
                Library:SafeCallback(Addon.Callback, Addon:GetState())
            end
        end
        Toggle:RunChanged()
        Library:UpdateDependencyBoxes()
    end

    function Toggle:SetText(Text)
        Toggle.Text = Text
        Label.Text = Text
    end

    function Toggle:SetDisabled(Disabled)
        Toggle.Disabled = Disabled == true
        Toggle:Display()
        SetTooltipDisabled(Toggle)
    end

    function Toggle:SetRisky(Risky)
        Toggle.Risky = Risky == true
        Library:RefreshInstance(Label)
    end

    Holder.Activated:Connect(function()
        if Toggle.Disabled or Library.IsPicking then
            return
        end
        Toggle:SetValue(not Toggle.Value)
    end)

    AttachAddonMethods(Toggle, { KeyPicker = true, ColorPicker = true })
    Toggle:Display(false)
    return Finalize(Box, Toggle, Info, Idx, Toggles)
end

function BaseGroupbox:AddToggle(Idx, Info)
    return CreateToggle(self, Idx, Info, Library.ForceCheckbox)
end

function BaseGroupbox:AddCheckbox(Idx, Info)
    return CreateToggle(self, Idx, Info, true)
end

--// Input \\--

function BaseGroupbox:AddInput(Idx, Info)
    Idx, Info = ParseArgs(Idx, Info)
    local Input = {
        Type = "Input",
        Text = Info.Text or "",
        Value = tostring(Info.Default or ""),
        Numeric = Info.Numeric == true,
        Finished = Info.Finished == true,
        AllowEmpty = Info.AllowEmpty ~= false,
        EmptyReset = Info.EmptyReset or "---",
        MaxLength = Info.MaxLength,
        Disabled = Info.Disabled == true,
        Callback = Info.Callback,
        Changed = Info.Changed,
        Addons = {},
    }

    local Holder = MakeRow(self)
    Input.Holder = Holder
    local HasLabel = Input.Text ~= ""
    local BoxScale = HasLabel and 0.55 or 1

    local Label = RowLabel(Holder, Input.Text, { Size = UDim2.new(1 - BoxScale, -6, 1, 0), Visible = HasLabel })
    Input.TextLabel = Label
    Input.KeepLabelWidth = true
    Input.AddonPosition = UDim2.new(1 - BoxScale, -6, 0.5, 0)

    local Frame = New("Frame", {
        BackgroundColor3 = "ElementColor",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.fromScale(1, 0.5),
        Size = UDim2.new(BoxScale, 0, 0, 20),
        Parent = Holder,
    })
    Corner(Frame, 4)
    local FocusStroke = Stroke(Frame, "AccentColor", 1)

    local Box = New("TextBox", {
        Text = Input.Value,
        PlaceholderText = Info.Placeholder or "",
        ClearTextOnFocus = Info.ClearTextOnFocus == true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextSize = 13,
        ClipsDescendants = true,
        Size = UDim2.new(1, -12, 1, 0),
        Position = UDim2.fromOffset(6, 0),
        Parent = Frame,
    })
    Input.Box = Box

    function Input:OnChanged(Func)
        Input.Changed = Func
    end

    function Input:RunChanged()
        Library:SafeCallback(Input.Callback, Input.Value)
        Library:SafeCallback(Input.Changed, Input.Value)
    end

    function Input:SetValue(Text)
        Text = tostring(Text or "")
        if Input.MaxLength and #Text > Input.MaxLength then
            Text = Text:sub(1, Input.MaxLength)
        end
        if Input.Numeric and Text ~= "" and not tonumber(Text) and Text ~= "-" and Text ~= "." then
            Box.Text = Input.Value
            return
        end
        if Text == "" and not Input.AllowEmpty then
            Text = Input.EmptyReset
        end
        if Info.VerifyValue and not Library:SafeCallback(Info.VerifyValue, Text) then
            Box.Text = Input.Value
            return
        end
        Input.Value = Text
        if Box.Text ~= Text then
            Box.Text = Text
        end
        Input:RunChanged()
        Library:UpdateDependencyBoxes()
    end

    function Input:SetText(Text)
        Input.Text = Text
        Label.Text = Text
    end

    function Input:SetDisabled(Disabled)
        Input.Disabled = Disabled == true
        Box.TextEditable = not Input.Disabled
        Box.TextTransparency = Input.Disabled and 0.5 or 0
        SetTooltipDisabled(Input)
    end

    function Input:SetPlaceholder(Text)
        Box.PlaceholderText = Text
    end

    Box.Focused:Connect(function()
        Tween(FocusStroke, { Transparency = 0 }, Library.FastTweenInfo)
    end)

    Box.FocusLost:Connect(function(EnterPressed)
        Tween(FocusStroke, { Transparency = 1 }, Library.FastTweenInfo)
        if Input.Finished then
            if EnterPressed then
                Input:SetValue(Box.Text)
            else
                Box.Text = Input.Value
            end
        end
        if Info.ClearTextOnBlur then
            Box.Text = ""
        end
    end)

    Box:GetPropertyChangedSignal("Text"):Connect(function()
        if Input.MaxLength and #Box.Text > Input.MaxLength then
            Box.Text = Box.Text:sub(1, Input.MaxLength)
            return
        end
        if Input.Numeric then
            local Filtered = Box.Text:gsub("[^%d%.%-]", "")
            if Filtered ~= Box.Text then
                Box.Text = Filtered
                return
            end
        end
        if not Input.Finished and Box.Text ~= Input.Value and Box:IsFocused() then
            Input:SetValue(Box.Text)
        end
    end)

    AttachAddonMethods(Input, {})
    Input:SetDisabled(Input.Disabled)
    return Finalize(self, Input, Info, Idx, Options)
end

--// Slider \\--

function BaseGroupbox:AddSlider(Idx, Info)
    Idx, Info = ParseArgs(Idx, Info)
    local Slider = {
        Type = "Slider",
        Text = Info.Text,
        Min = Info.Min or 0,
        Max = Info.Max or 100,
        Rounding = Info.Rounding or 0,
        Prefix = Info.Prefix or "",
        Suffix = Info.Suffix or "",
        HideMax = Info.HideMax ~= false,
        Disabled = Info.Disabled == true,
        Callback = Info.Callback,
        Changed = Info.Changed,
        Addons = {},
    }
    Slider.Value = math.clamp(Info.Default or Slider.Min, Slider.Min, Slider.Max)

    local Holder = MakeRow(self, 20)
    Slider.Holder = Holder

    local Bar = New("TextButton", {
        BackgroundColor3 = "ElementColor",
        BackgroundTransparency = 0,
        Size = UDim2.fromScale(1, 1),
        Parent = Holder,
    })
    Corner(Bar, 4)
    HoverOverlay(Bar, 4)
    local Fill = New("Frame", {
        BackgroundColor3 = "AccentColor",
        Size = UDim2.fromScale(0, 1),
        Parent = Bar,
    })
    Corner(Fill, 4)
    local ValueLabel = New("TextLabel", {
        TextSize = 13,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 3,
        Parent = Bar,
    })
    local ManualBox = New("TextBox", {
        BackgroundColor3 = "ElementColor",
        BackgroundTransparency = 0,
        TextSize = 13,
        Size = UDim2.fromScale(1, 1),
        Visible = false,
        ZIndex = 4,
        Parent = Bar,
    })
    Corner(ManualBox, 4)
    Stroke(ManualBox, "AccentColor")

    local function FormatNumber(Value)
        return tostring(Round(Value, Slider.Rounding))
    end

    function Slider:Display(Animate)
        local Alpha = (Slider.Max - Slider.Min) ~= 0 and (Slider.Value - Slider.Min) / (Slider.Max - Slider.Min) or 0
        Tween(Fill, { Size = UDim2.fromScale(math.clamp(Alpha, 0, 1), 1) }, Library.FastTweenInfo, Animate)
        Fill.Visible = Alpha > 0.001
        if Info.FormatDisplayValue then
            ValueLabel.Text = tostring(Library:SafeCallback(Info.FormatDisplayValue, Slider, Slider.Value) or "")
        else
            local Text = (Slider.Text and Slider.Text ~= "") and (Slider.Text .. ": ") or ""
            Text = Text .. Slider.Prefix .. FormatNumber(Slider.Value) .. Slider.Suffix
            if not Slider.HideMax then
                Text = Text .. "/" .. Slider.Prefix .. FormatNumber(Slider.Max) .. Slider.Suffix
            end
            ValueLabel.Text = Text
        end
        ValueLabel.TextTransparency = Slider.Disabled and 0.5 or 0
        Bar.BackgroundTransparency = Slider.Disabled and 0.5 or 0
    end

    function Slider:OnChanged(Func)
        Slider.Changed = Func
    end

    function Slider:RunChanged()
        Library:SafeCallback(Slider.Callback, Slider.Value)
        Library:SafeCallback(Slider.Changed, Slider.Value)
    end

    function Slider:SetValue(Value, Animate)
        local Number = tonumber(Value)
        if not Number then
            return
        end
        Number = math.clamp(Round(Number, Slider.Rounding), Slider.Min, Slider.Max)
        local Changed = Number ~= Slider.Value
        Slider.Value = Number
        Slider:Display(Animate)
        if Changed or Animate == nil then
            Slider:RunChanged()
            Library:UpdateDependencyBoxes()
        end
    end

    function Slider:SetMin(Value)
        Slider.Min = Value
        Slider:SetValue(math.max(Slider.Value, Value))
    end
    function Slider:SetMax(Value)
        Slider.Max = Value
        Slider:SetValue(math.min(Slider.Value, Value))
    end
    function Slider:SetText(Text)
        Slider.Text = Text
        Slider:Display()
    end
    function Slider:SetPrefix(Prefix)
        Slider.Prefix = Prefix or ""
        Slider:Display()
    end
    function Slider:SetSuffix(Suffix)
        Slider.Suffix = Suffix or ""
        Slider:Display()
    end
    function Slider:SetDisabled(Disabled)
        Slider.Disabled = Disabled == true
        Slider:Display()
        SetTooltipDisabled(Slider)
    end

    local Sliding = false
    local function SetFromX(X)
        local Alpha = math.clamp((X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
        Slider:SetValue(Slider.Min + (Slider.Max - Slider.Min) * Alpha, true)
    end

    Bar.InputBegan:Connect(function(Input)
        if not IsClick(Input) or Slider.Disabled or ManualBox.Visible then
            return
        end
        Sliding = true
        SetFromX(Input.Position.X)
        local Changed
        Changed = Input.Changed:Connect(function()
            if Input.UserInputState == Enum.UserInputState.End then
                Sliding = false
                Changed:Disconnect()
            end
        end)
    end)
    Slider.Connections = {
        UserInputService.InputChanged:Connect(function(Input)
            if Sliding and IsMove(Input) then
                SetFromX(Input.Position.X)
            end
        end),
    }

    Bar.MouseButton2Click:Connect(function()
        if Info.AllowRightClickInput == false or Slider.Disabled then
            return
        end
        ManualBox.Text = FormatNumber(Slider.Value)
        ManualBox.Visible = true
        ManualBox:CaptureFocus()
    end)
    ManualBox.FocusLost:Connect(function()
        ManualBox.Visible = false
        Slider:SetValue(ManualBox.Text)
    end)

    Slider:Display(false)
    return Finalize(self, Slider, Info, Idx, Options)
end

--// Dropdown \\--

function Library:DropdownDivider(Title)
    return { DropdownDivider = true, Title = Title }
end

local function IsDivider(Value)
    return type(Value) == "table" and Value.DropdownDivider == true
end

local function GetPlayerNames(ExcludeLocal)
    local Names = {}
    for _, Player in ipairs(Players:GetPlayers()) do
        if not (ExcludeLocal and Player == LocalPlayer) then
            table.insert(Names, Player.Name)
        end
    end
    table.sort(Names, function(A, B)
        return A:lower() < B:lower()
    end)
    return Names
end

local function GetTeamNames()
    local Names = {}
    for _, Team in ipairs(Teams:GetTeams()) do
        table.insert(Names, Team.Name)
    end
    table.sort(Names)
    return Names
end

function BaseGroupbox:AddDropdown(Idx, Info)
    Idx, Info = ParseArgs(Idx, Info)
    local Dropdown = {
        Type = "Dropdown",
        Text = Info.Text,
        Values = Info.Values or {},
        Multi = Info.Multi == true,
        SpecialType = Info.SpecialType,
        AllowNull = Info.AllowNull == true,
        Searchable = Info.Searchable == true,
        DisabledValues = Info.DisabledValues or {},
        ValueImages = Info.ValueImages or {},
        MaxVisibleItems = Info.MaxVisibleDropdownItems or 8,
        Disabled = Info.Disabled == true,
        DragSelect = Info.DragSelect == true,
        Callback = Info.Callback,
        Changed = Info.Changed,
        Addons = {},
        Connections = {},
    }
    Dropdown.Value = Dropdown.Multi and {} or nil

    if Dropdown.SpecialType == "Player" then
        Dropdown.Values = GetPlayerNames(Info.ExcludeLocalPlayer)
    elseif Dropdown.SpecialType == "Team" then
        Dropdown.Values = GetTeamNames()
    end

    local Holder = MakeRow(self)
    Dropdown.Holder = Holder
    local HasLabel = Dropdown.Text ~= nil and Dropdown.Text ~= ""
    local BoxScale = HasLabel and 0.5 or 1

    local Label = RowLabel(Holder, Dropdown.Text or "", { Size = UDim2.new(1 - BoxScale, -6, 1, 0), Visible = HasLabel })
    Dropdown.TextLabel = Label
    Dropdown.KeepLabelWidth = true
    Dropdown.AddonPosition = UDim2.new(1 - BoxScale, -6, 0.5, 0)

    local Box = New("TextButton", {
        BackgroundColor3 = "ElementColor",
        BackgroundTransparency = 0,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.fromScale(1, 0.5),
        Size = UDim2.new(BoxScale, 0, 0, 20),
        Parent = Holder,
    })
    Corner(Box, 4)
    HoverOverlay(Box, 4)
    Dropdown.Box = Box

    local Display = New("TextLabel", {
        TextColor3 = "MutedColor",
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Position = UDim2.fromOffset(7, 0),
        Size = UDim2.new(1, -26, 1, 0),
        ZIndex = 3,
        Parent = Box,
    })

    local Chevron = Library:CreateIcon("chevron-down", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -5, 0.5, 0),
        Size = UDim2.fromOffset(12, 12),
        ImageColor3 = "MutedColor",
        ZIndex = 3,
        Parent = Box,
    }) or New("TextLabel", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -5, 0.5, 0),
        Size = UDim2.fromOffset(12, 12),
        Text = "▾",
        TextColor3 = "MutedColor",
        TextSize = 12,
        ZIndex = 3,
        Parent = Box,
    })

    -- The floating list
    local List = New("Frame", {
        BackgroundColor3 = "MainColor",
        Size = UDim2.fromOffset(100, 0),
        ClipsDescendants = true,
        Visible = false,
        Parent = OverlayLayer,
    })
    Corner(List, 4)
    Stroke(List)
    AddScale(List)

    local SearchBox = nil
    local SearchHeight = 0
    if Dropdown.Searchable then
        SearchHeight = 26
        local SearchFrame = New("Frame", {
            BackgroundColor3 = "ElementColor",
            Position = UDim2.fromOffset(4, 4),
            Size = UDim2.new(1, -8, 0, 20),
            Parent = List,
        })
        Corner(SearchFrame, 4)
        SearchBox = New("TextBox", {
            PlaceholderText = "Search...",
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Position = UDim2.fromOffset(6, 0),
            Size = UDim2.new(1, -12, 1, 0),
            Parent = SearchFrame,
        })
    end

    local Items = New("ScrollingFrame", {
        Position = UDim2.fromOffset(0, SearchHeight),
        Size = UDim2.new(1, 0, 1, -SearchHeight),
        Parent = List,
    })
    Padding(Items, 2, 2, 2, 2)
    New("UIListLayout", { Parent = Items })

    local ItemButtons = {}
    local ITEM_HEIGHT = 22

    local function FormatList(Value)
        if Info.FormatListValue then
            return tostring(Library:SafeCallback(Info.FormatListValue, Value))
        elseif Info.FormatValue then
            return tostring(Library:SafeCallback(Info.FormatValue, Value))
        end
        return tostring(Value)
    end

    local function FormatDisplay(Value)
        if Info.FormatDisplayValue then
            return tostring(Library:SafeCallback(Info.FormatDisplayValue, Value))
        elseif Info.FormatValue then
            return tostring(Library:SafeCallback(Info.FormatValue, Value))
        end
        return tostring(Value)
    end

    local function IsSelected(Value)
        if Dropdown.Multi then
            return Dropdown.Value[Value] == true
        end
        return Dropdown.Value == Value
    end

    function Dropdown:Display()
        local Text
        if Dropdown.Multi then
            local Parts = {}
            for _, Value in ipairs(Dropdown.Values) do
                if not IsDivider(Value) and Dropdown.Value[Value] then
                    table.insert(Parts, FormatDisplay(Value))
                end
            end
            Text = table.concat(Parts, ", ")
        elseif Dropdown.Value ~= nil then
            Text = FormatDisplay(Dropdown.Value)
        end
        Display.Text = (Text and Text ~= "") and Text or "--"
        Display.TextTransparency = Dropdown.Disabled and 0.5 or 0
    end

    local function RefreshItemColors()
        for Value, Item in pairs(ItemButtons) do
            local Selected = IsSelected(Value)
            local Disabled = table.find(Dropdown.DisabledValues, Value) ~= nil
            Library:AddToRegistry(Item.Label, {
                TextColor3 = Disabled and "MutedColor" or (Selected and "AccentColor" or "FontColor"),
            })
            Item.Label.TextTransparency = Disabled and 0.5 or 0
            if Item.Check then
                Tween(Item.Check, { ImageTransparency = Selected and 0 or 1 }, Library.FastTweenInfo)
            end
        end
    end
    Dropdown.UpdateColors = RefreshItemColors

    local function VisibleItemCount()
        local Count = 0
        for _, Child in ipairs(Items:GetChildren()) do
            if Child:IsA("GuiObject") and Child.Visible then
                Count = Count + 1
            end
        end
        return Count
    end

    function Dropdown:RecalculateListSize()
        local Count = math.min(VisibleItemCount(), Dropdown.MaxVisibleItems)
        local Height = SearchHeight + math.max(Count, 1) * ITEM_HEIGHT + 4
        local Width = Unscale(Box.AbsoluteSize.X)
        if Info.AutoWidth then
            for _, Value in ipairs(Dropdown.Values) do
                if not IsDivider(Value) then
                    Width = math.max(Width, Library:GetTextBounds(FormatList(Value), Library.Scheme.Font, 13) + 44)
                end
            end
        end
        Dropdown.ListHeight = Height
        Dropdown.ListWidth = Width
        return Width, Height
    end

    local function ApplySearch()
        local Query = SearchBox and SearchBox.Text:lower() or ""
        for _, Child in ipairs(Items:GetChildren()) do
            if Child:IsA("GuiObject") then
                local Key = Child:GetAttribute("SearchKey")
                if Key then
                    Child.Visible = Query == "" or Key:find(Query, 1, true) ~= nil
                else
                    Child.Visible = Query == ""
                end
            end
        end
        if List.Visible then
            local Width, Height = Dropdown:RecalculateListSize()
            Tween(List, { Size = UDim2.fromOffset(Width, Height) }, Library.DropdownTransitionInfo)
        end
    end

    function Dropdown:BuildDropdownList()
        for _, Child in ipairs(Items:GetChildren()) do
            if Child:IsA("GuiObject") then
                Child:Destroy()
            end
        end
        ItemButtons = {}

        for Index, Value in ipairs(Dropdown.Values) do
            if IsDivider(Value) then
                local Divider = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, Value.Title and ITEM_HEIGHT or 7),
                    LayoutOrder = Index,
                    Parent = Items,
                })
                New("Frame", {
                    BackgroundColor3 = "OutlineColor",
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.fromScale(0, Value.Title and 1 or 0.5),
                    Size = UDim2.new(1, 0, 0, 1),
                    Parent = Divider,
                })
                if Value.Title then
                    RowLabel(Divider, Value.Title, { TextColor3 = "MutedColor", TextSize = 12, Position = UDim2.fromOffset(6, 0), Size = UDim2.new(1, -6, 1, 0) })
                end
                continue
            end

            local Item = New("TextButton", {
                Size = UDim2.new(1, 0, 0, ITEM_HEIGHT),
                LayoutOrder = Index,
                Parent = Items,
            })
            Item:SetAttribute("SearchKey", FormatList(Value):lower())
            Corner(Item, 3)
            HoverOverlay(Item, 3)

            local TextX = 7
            local Image = Dropdown.ValueImages[Value]
            if Image then
                local IconImage = Library:CreateIcon(Image, {
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, 6, 0.5, 0),
                    Size = UDim2.fromOffset(16, 16),
                    ZIndex = 3,
                    Parent = Item,
                })
                if IconImage then
                    TextX = 28
                end
            end

            local ItemLabel = RowLabel(Item, FormatList(Value), {
                TextSize = 13,
                Position = UDim2.fromOffset(TextX, 0),
                Size = UDim2.new(1, -(TextX + 24), 1, 0),
                ZIndex = 3,
            })

            local Check = nil
            if Dropdown.Multi then
                Check = Library:CreateIcon("check", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -6, 0.5, 0),
                    Size = UDim2.fromOffset(12, 12),
                    ImageColor3 = "AccentColor",
                    ImageTransparency = 1,
                    ZIndex = 3,
                    Parent = Item,
                })
            end

            ItemButtons[Value] = { Button = Item, Label = ItemLabel, Check = Check }

            Item.Activated:Connect(function()
                if table.find(Dropdown.DisabledValues, Value) then
                    return
                end
                if Dropdown.Multi then
                    local NewValue = table.clone(Dropdown.Value)
                    NewValue[Value] = not NewValue[Value] or nil
                    Dropdown:SetValue(NewValue)
                else
                    if Dropdown.Value == Value then
                        if Dropdown.AllowNull then
                            Dropdown:SetValue(nil)
                        end
                    else
                        Dropdown:SetValue(Value)
                    end
                    Dropdown:Close()
                end
            end)
        end

        RefreshItemColors()
        ApplySearch()
    end
    Dropdown.RefreshPool = Dropdown.BuildDropdownList

    local ListPopup
    ListPopup = {
        Frame = List,
        Anchor = Box,
        Close = function()
            Dropdown:Close()
        end,
        Follow = function()
            PlaceBelow(List, Box, 3, false, Dropdown.ListHeight)
        end,
    }
    Dropdown.Menu = ListPopup

    function Dropdown:Open()
        if Dropdown.Disabled or List.Visible then
            return
        end
        if SearchBox then
            SearchBox.Text = ""
        end
        ApplySearch()
        local Width, Height = Dropdown:RecalculateListSize()
        List.Size = UDim2.fromOffset(Width, 0)
        List.Visible = true
        ListPopup.Follow()
        Library:OpenPopup(ListPopup)
        Tween(List, { Size = UDim2.fromOffset(Width, Height) }, Library.DropdownTransitionInfo, Library.Animations.Dropdown)
        Tween(Chevron, { Rotation = 180 }, Library.DropdownTransitionInfo)
    end

    local CloseToken = 0
    function Dropdown:Close()
        if not List.Visible then
            return
        end
        Library:ClosePopup(ListPopup)
        Tween(Chevron, { Rotation = 0 }, Library.DropdownTransitionInfo)
        CloseToken = CloseToken + 1
        local Token = CloseToken
        if Library.Animations.Dropdown then
            Tween(List, { Size = UDim2.fromOffset(List.Size.X.Offset, 0) }, Library.DropdownTransitionInfo)
            task.delay(Library.DropdownTransitionInfo.Time, function()
                if Token == CloseToken then
                    List.Visible = false
                end
            end)
        else
            List.Visible = false
        end
    end

    function Dropdown:OnChanged(Func)
        Dropdown.Changed = Func
    end

    function Dropdown:RunChanged()
        Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
        Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
    end

    function Dropdown:GetActiveValues(ReturnCount)
        local Active = {}
        if Dropdown.Multi then
            for _, Value in ipairs(Dropdown.Values) do
                if not IsDivider(Value) and Dropdown.Value[Value] then
                    table.insert(Active, Value)
                end
            end
        elseif Dropdown.Value ~= nil then
            table.insert(Active, Dropdown.Value)
        end
        return ReturnCount == true and #Active or Active
    end

    local function NormalizeValue(Value)
        if Dropdown.Multi then
            local Result = {}
            if type(Value) == "table" then
                for Key, Enabled in pairs(Value) do
                    -- Accept both { "a", "b" } and { a = true, b = true }
                    local Item = (type(Key) == "number" and Enabled ~= true) and Enabled or Key
                    if (Enabled == true or type(Key) == "number") and table.find(Dropdown.Values, Item) then
                        Result[Item] = true
                    end
                end
            end
            return Result
        end
        if Value ~= nil and table.find(Dropdown.Values, Value) then
            return Value
        end
        return nil
    end

    function Dropdown:SetValue(Value)
        Dropdown.Value = NormalizeValue(Value)
        Dropdown:Display()
        RefreshItemColors()
        Dropdown:RunChanged()
        Library:UpdateDependencyBoxes()
    end

    function Dropdown:SetValues(Values)
        Dropdown.Values = Values or {}
        local Kept = NormalizeValue(Dropdown.Value)
        local Changed = false
        if Dropdown.Multi then
            Changed = TableSize(Kept) ~= TableSize(Dropdown.Value)
        else
            Changed = Kept ~= Dropdown.Value
        end
        Dropdown.Value = Kept
        Dropdown:BuildDropdownList()
        Dropdown:Display()
        if Changed then
            Dropdown:RunChanged()
        end
    end

    function Dropdown:AddValues(Values)
        local NewValues = table.clone(Dropdown.Values)
        for _, Value in ipairs(type(Values) == "table" and Values or { Values }) do
            table.insert(NewValues, Value)
        end
        Dropdown:SetValues(NewValues)
    end

    function Dropdown:SetDisabledValues(Values)
        Dropdown.DisabledValues = Values or {}
        RefreshItemColors()
    end

    function Dropdown:AddDisabledValues(Values)
        for _, Value in ipairs(type(Values) == "table" and Values or { Values }) do
            table.insert(Dropdown.DisabledValues, Value)
        end
        RefreshItemColors()
    end

    function Dropdown:SetValueImages(Images)
        Dropdown.ValueImages = Images or {}
        Dropdown:BuildDropdownList()
    end

    function Dropdown:AddValueImages(Images)
        for Value, Image in pairs(Images or {}) do
            Dropdown.ValueImages[Value] = Image
        end
        Dropdown:BuildDropdownList()
    end

    function Dropdown:SetText(Text)
        Dropdown.Text = Text
        Label.Text = Text or ""
    end

    function Dropdown:SetDisabled(Disabled)
        Dropdown.Disabled = Disabled == true
        if Dropdown.Disabled then
            Dropdown:Close()
        end
        Box.BackgroundTransparency = Dropdown.Disabled and 0.5 or 0
        Dropdown:Display()
        SetTooltipDisabled(Dropdown)
    end

    function Dropdown:SetDragSelect(Enabled)
        Dropdown.DragSelect = Enabled == true
    end

    Box.Activated:Connect(function()
        if List.Visible then
            Dropdown:Close()
        else
            Dropdown:Open()
        end
    end)

    if SearchBox then
        SearchBox:GetPropertyChangedSignal("Text"):Connect(ApplySearch)
    end

    if Dropdown.SpecialType == "Player" then
        if Info.EnablePlayerImages then
            local function RefreshImages()
                for _, Player in ipairs(Players:GetPlayers()) do
                    Dropdown.ValueImages[Player.Name] = "rbxthumb://type=AvatarHeadShot&id=" .. Player.UserId .. "&w=48&h=48"
                end
            end
            RefreshImages()
            table.insert(Dropdown.Connections, Players.PlayerAdded:Connect(RefreshImages))
        end
        local function Refresh()
            task.defer(function()
                Dropdown:SetValues(GetPlayerNames(Info.ExcludeLocalPlayer))
            end)
        end
        table.insert(Dropdown.Connections, Players.PlayerAdded:Connect(Refresh))
        table.insert(Dropdown.Connections, Players.PlayerRemoving:Connect(Refresh))
    elseif Dropdown.SpecialType == "Team" then
        local function Refresh()
            task.defer(function()
                Dropdown:SetValues(GetTeamNames())
            end)
        end
        table.insert(Dropdown.Connections, Teams.ChildAdded:Connect(Refresh))
        table.insert(Dropdown.Connections, Teams.ChildRemoved:Connect(Refresh))
    end

    -- Default value (by value or by index)
    local Default = Info.Default
    if Dropdown.Multi then
        local Initial = {}
        if type(Default) == "table" then
            for Key, Value in pairs(Default) do
                if type(Key) == "number" then
                    local Resolved = (type(Value) == "number" and Dropdown.Values[Value]) or Value
                    Initial[Resolved] = true
                elseif Value == true then
                    Initial[Key] = true
                end
            end
        elseif Default ~= nil then
            Initial[(type(Default) == "number" and Dropdown.Values[Default]) or Default] = true
        end
        Dropdown.Value = NormalizeValue(Initial)
    elseif Default ~= nil then
        if type(Default) == "number" and Dropdown.Values[Default] ~= nil and not table.find(Dropdown.Values, Default) then
            Default = Dropdown.Values[Default]
        end
        Dropdown.Value = NormalizeValue(Default)
    end

    Dropdown:BuildDropdownList()
    Dropdown:Display()
    AttachAddonMethods(Dropdown, {})
    if Dropdown.Disabled then
        Dropdown:SetDisabled(true)
    end

    local Element = Finalize(self, Dropdown, Info, Idx, Options)
    local BaseDestroy = Element.Destroy
    function Dropdown:Destroy()
        List:Destroy()
        BaseDestroy(Dropdown)
    end
    return Element
end

--// Divider \\--

function BaseGroupbox:AddDivider(Info)
    if type(Info) ~= "table" then
        Info = { Text = Info }
    end
    local HasText = Info.Text ~= nil and Info.Text ~= ""
    local Divider = { Type = "Divider", Text = Info.Text }
    local Holder = MakeRow(self, HasText and 18 or 9)
    Divider.Holder = Holder

    local Line = New("Frame", {
        BackgroundColor3 = "OutlineColor",
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.new(1, 0, 0, 1),
        Parent = Holder,
    })

    if HasText then
        local Label = New("TextLabel", {
            BackgroundColor3 = "MainColor",
            BackgroundTransparency = 0,
            TextColor3 = "MutedColor",
            Text = Info.Text,
            TextSize = 12,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.fromScale(0, 1),
            ZIndex = 2,
            Parent = Holder,
        })
        Padding(Label, 0, 0, 6, 6)
        Divider.TextLabel = Label
        Divider.KeepLabelWidth = true
    end
    Divider.Line = Line
    return Finalize(self, Divider, Info, nil, nil)
end

--// Image \\--

function BaseGroupbox:AddImage(Idx, Info)
    Idx, Info = ParseArgs(Idx, Info)
    local ImageElement = { Type = "Image", Height = Info.Height or 200 }
    local Holder = MakeRow(self, ImageElement.Height)
    ImageElement.Holder = Holder

    local Image = New("ImageLabel", {
        BackgroundColor3 = "ElementColor",
        BackgroundTransparency = Info.BackgroundTransparency or 1,
        ImageTransparency = Info.Transparency or 0,
        ScaleType = Info.ScaleType or Enum.ScaleType.Fit,
        Size = UDim2.fromScale(1, 1),
        Parent = Holder,
    })
    Corner(Image, 4)
    ImageElement.Image = Image

    function ImageElement:SetImage(NewImage)
        ImageElement.Value = NewImage
        Library:ApplyIcon(Image, NewImage)
        if Info.RectOffset then
            Image.ImageRectOffset = Info.RectOffset
        end
        if Info.RectSize then
            Image.ImageRectSize = Info.RectSize
        end
    end
    function ImageElement:SetHeight(Height)
        ImageElement.Height = Height
        Holder.Size = UDim2.new(1, 0, 0, Height)
        ApplyVisibility(ImageElement)
    end
    function ImageElement:SetColor(Color)
        Image.ImageColor3 = Color
    end
    function ImageElement:SetTransparency(Transparency)
        Image.ImageTransparency = Transparency
    end
    function ImageElement:SetRectOffset(Offset)
        Image.ImageRectOffset = Offset
    end
    function ImageElement:SetRectSize(Size)
        Image.ImageRectSize = Size
    end
    function ImageElement:SetScaleType(ScaleType)
        Image.ScaleType = ScaleType
    end

    ImageElement:SetImage(Info.Image)
    if Info.Color then
        Image.ImageColor3 = Info.Color
    end
    return Finalize(self, ImageElement, Info, Idx, Options)
end

--// Video \\--

function BaseGroupbox:AddVideo(Idx, Info)
    Idx, Info = ParseArgs(Idx, Info)
    local Video = { Type = "Video", Height = Info.Height or 200 }
    local Holder = MakeRow(self, Video.Height)
    Video.Holder = Holder

    local Frame = New("VideoFrame", {
        Video = Info.Video or "",
        Looped = Info.Looped == true,
        Volume = Info.Volume or 1,
        Size = UDim2.fromScale(1, 1),
        Parent = Holder,
    })
    Corner(Frame, 4)
    Video.VideoFrame = Frame

    function Video:SetVideo(Id)
        Frame.Video = Id
    end
    function Video:SetLooped(Looped)
        Frame.Looped = Looped == true
    end
    function Video:SetVolume(Volume)
        Frame.Volume = Volume
    end
    function Video:SetPlaying(Playing)
        Frame.Playing = Playing == true
    end
    function Video:Play()
        Frame:Play()
    end
    function Video:Pause()
        Frame:Pause()
    end
    function Video:SetHeight(Height)
        Video.Height = Height
        Holder.Size = UDim2.new(1, 0, 0, Height)
        ApplyVisibility(Video)
    end

    if Info.Playing then
        task.defer(function()
            Frame:Play()
        end)
    end
    return Finalize(self, Video, Info, Idx, Options)
end

--// Viewport \\--

function BaseGroupbox:AddViewport(Idx, Info)
    Idx, Info = ParseArgs(Idx, Info)
    local Viewport = {
        Type = "Viewport",
        Height = Info.Height or 200,
        Interactive = Info.Interactive == true,
        Yaw = 0,
        Pitch = -15,
        Distance = 10,
        FocusPoint = Vector3.zero,
    }
    local Holder = MakeRow(self, Viewport.Height)
    Viewport.Holder = Holder

    local Frame = New("ViewportFrame", {
        BackgroundColor3 = "ElementColor",
        BackgroundTransparency = 0,
        Ambient = Color3.fromRGB(160, 160, 160),
        LightColor = Color3.fromRGB(255, 255, 255),
        Size = UDim2.fromScale(1, 1),
        Parent = Holder,
    })
    Corner(Frame, 4)
    Viewport.ViewportFrame = Frame

    local Camera = Info.Camera or Instance.new("Camera")
    Camera.FieldOfView = 50
    Camera.Parent = Frame
    Frame.CurrentCamera = Camera
    Viewport.Camera = Camera

    local function ApplyCamera()
        local Rotation = CFrame.Angles(0, math.rad(Viewport.Yaw), 0) * CFrame.Angles(math.rad(Viewport.Pitch), 0, 0)
        Camera.CFrame = CFrame.new(Viewport.FocusPoint) * Rotation * CFrame.new(0, 0, Viewport.Distance)
    end

    function Viewport:SetObject(Object, Clone)
        for _, Child in ipairs(Frame:GetChildren()) do
            if not Child:IsA("UICorner") and Child ~= Camera then
                Child:Destroy()
            end
        end
        if not Object then
            Viewport.Object = nil
            return
        end
        if Clone ~= false and Info.Clone ~= false then
            local Archivable = Object.Archivable
            Object.Archivable = true
            Object = Object:Clone()
            Object.Archivable = Archivable
            -- Don't let cloned scripts (e.g. a character's Animate script) run inside the viewport
            for _, Descendant in ipairs(Object:GetDescendants()) do
                if Descendant:IsA("BaseScript") then
                    Descendant:Destroy()
                end
            end
        end
        Object.Parent = Frame
        Viewport.Object = Object
        if Info.AutoFocus ~= false then
            Viewport:Focus()
        end
    end

    function Viewport:Focus()
        local Object = Viewport.Object
        if not Object then
            return
        end
        local Center, Size
        if Object:IsA("Model") then
            local BoxCFrame, BoxSize = Object:GetBoundingBox()
            Center, Size = BoxCFrame.Position, BoxSize
        else
            Center, Size = Object.Position, Object.Size
        end
        Viewport.FocusPoint = Center
        local Radius = Size.Magnitude / 2
        Viewport.Distance = Radius / math.tan(math.rad(Camera.FieldOfView / 2)) + Radius * 0.25
        ApplyCamera()
    end

    function Viewport:SetCamera(NewCamera)
        Camera = NewCamera
        Camera.Parent = Frame
        Frame.CurrentCamera = Camera
        Viewport.Camera = Camera
    end
    function Viewport:SetCameraCFrame(NewCFrame)
        Camera.CFrame = NewCFrame
    end
    function Viewport:GetCameraCFrame()
        return Camera.CFrame
    end
    function Viewport:Rotate(DeltaYaw, DeltaPitch)
        Viewport.Yaw = Viewport.Yaw + (DeltaYaw or 0)
        Viewport.Pitch = math.clamp(Viewport.Pitch + (DeltaPitch or 0), -85, 85)
        ApplyCamera()
    end
    function Viewport:Zoom(Delta)
        Viewport.Distance = math.max(0.5, Viewport.Distance + Delta)
        ApplyCamera()
    end
    function Viewport:LookAt(Position)
        Viewport.FocusPoint = Position
        ApplyCamera()
    end
    function Viewport:SetDistance(Distance)
        Viewport.Distance = math.max(0.5, Distance)
        ApplyCamera()
    end
    function Viewport:GetDistance()
        return Viewport.Distance
    end
    function Viewport:SetFieldOfView(FieldOfView)
        Camera.FieldOfView = FieldOfView
        ApplyCamera()
    end
    function Viewport:SetInteractive(Interactive)
        Viewport.Interactive = Interactive == true
    end
    function Viewport:SetHeight(Height)
        Viewport.Height = Height
        Holder.Size = UDim2.new(1, 0, 0, Height)
        ApplyVisibility(Viewport)
    end

    local Rotating, LastPosition = false, nil
    Frame.InputBegan:Connect(function(Input)
        if Viewport.Interactive and IsClick(Input) then
            Rotating, LastPosition = true, Input.Position
            local Changed
            Changed = Input.Changed:Connect(function()
                if Input.UserInputState == Enum.UserInputState.End then
                    Rotating = false
                    Changed:Disconnect()
                end
            end)
        end
    end)
    Frame.InputChanged:Connect(function(Input)
        if Viewport.Interactive and Input.UserInputType == Enum.UserInputType.MouseWheel then
            Viewport:Zoom(-Input.Position.Z * Viewport.Distance * 0.1)
        end
    end)
    Viewport.Connections = {
        UserInputService.InputChanged:Connect(function(Input)
            if Rotating and IsMove(Input) then
                local Delta = Input.Position - LastPosition
                LastPosition = Input.Position
                Viewport:Rotate(-Delta.X * 0.5, -Delta.Y * 0.5)
            end
        end),
    }

    ApplyCamera()
    if Info.Object then
        Viewport:SetObject(Info.Object, Info.Clone)
    end
    return Finalize(self, Viewport, Info, Idx, Options)
end

--// UI passthrough \\--

function BaseGroupbox:AddUIPassthrough(Idx, Info)
    Idx, Info = ParseArgs(Idx, Info)
    local Passthrough = { Type = "UIPassthrough", Height = Info.Height or 24 }
    local Holder = MakeRow(self, Passthrough.Height)
    Passthrough.Holder = Holder

    function Passthrough:SetInstance(Instance)
        if Passthrough.Instance and Passthrough.Instance.Parent == Holder then
            Passthrough.Instance.Parent = nil
        end
        Passthrough.Instance = Instance
        if Instance then
            Instance.Parent = Holder
        end
    end
    function Passthrough:SetHeight(Height)
        Passthrough.Height = Height
        Holder.Size = UDim2.new(1, 0, 0, Height)
        ApplyVisibility(Passthrough)
    end

    Passthrough:SetInstance(Info.Instance)
    return Finalize(self, Passthrough, Info, Idx, Options)
end

--// Dependency boxes \\--

local function CheckDependencies(Dependencies)
    for _, Dependency in ipairs(Dependencies) do
        local Element, Expected = Dependency[1], Dependency[2]
        if type(Element) ~= "table" then
            return false
        end
        local Value = Element.Value
        if Element.Type == "Dropdown" and Element.Multi then
            if type(Expected) == "table" then
                for Key in pairs(Expected) do
                    if not Value[Key] then
                        return false
                    end
                end
            elseif not Value[Expected] then
                return false
            end
        elseif Element.Type == "KeyPicker" then
            if Element:GetState() ~= Expected then
                return false
            end
        elseif type(Expected) == "function" then
            if not Expected(Value) then
                return false
            end
        elseif Value ~= Expected then
            return false
        end
        -- Nested: the element's own dependency box must also be visible
        if Element.Parent and Element.Parent.Type == "DependencyBox" and not Element.Parent.Visible then
            return false
        end
    end
    return true
end

function Library:UpdateDependencyBoxes()
    for _, Box in ipairs(Library.DependencyBoxes) do
        Box:Update()
    end
end

function BaseGroupbox:AddDependencyBox()
    local Holder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = NextOrder(),
        Parent = self.Container,
    })
    New("UIListLayout", { Padding = UDim.new(0, 6), Parent = Holder })

    local Owner = self
    local Box = setmetatable({
        Type = "DependencyBox",
        Container = Holder,
        Holder = Holder,
        Elements = {},
        Dependencies = {},
        Visible = true,
        Parent = Owner,
    }, BaseGroupbox)

    function Box:Resize()
        if Owner.Resize then
            Owner:Resize()
        end
    end

    function Box:Update()
        local Visible = CheckDependencies(Box.Dependencies)
        if Visible ~= Box.Visible or Holder.Visible ~= Visible then
            Box.Visible = Visible
            Holder.Visible = Visible
            Box:Resize()
        end
    end

    function Box:SetupDependencies(Dependencies)
        Box.Dependencies = Dependencies or {}
        Box:Update()
    end

    function Box:Destroy()
        local Index = table.find(Library.DependencyBoxes, Box)
        if Index then
            table.remove(Library.DependencyBoxes, Index)
        end
        Holder:Destroy()
        Box:Resize()
    end

    table.insert(Library.DependencyBoxes, Box)
    table.insert(Owner.Elements, Box)
    return Box
end

--// Groupboxes & tabboxes \\--

local Groupbox = setmetatable({}, { __index = BaseGroupbox })
Groupbox.__index = Groupbox

local Tabbox = {}
Tabbox.__index = Tabbox

local TabboxTab = setmetatable({}, { __index = BaseGroupbox })
TabboxTab.__index = TabboxTab

Library.PopOuts = {}

local function ResolveSide(Side)
    if Side == 2 or (type(Side) == "string" and Side:lower() == "right") then
        return "Right"
    end
    return "Left"
end

local function BoxFrame(Parent)
    local Frame = New("Frame", {
        BackgroundColor3 = "MainColor",
        Size = UDim2.new(1, 0, 0, 34),
        ClipsDescendants = true,
        LayoutOrder = NextOrder(),
        Parent = Parent,
    })
    Corner(Frame, Library.CornerRadius)
    Stroke(Frame, "OutlineColor", 0.35)
    return Frame
end

local function BoxContainer(Frame, Top)
    local Container = New("ScrollingFrame", {
        Position = UDim2.fromOffset(0, Top),
        Size = UDim2.new(1, 0, 0, 0),
        ScrollBarThickness = 2,
        Parent = Frame,
    })
    Padding(Container, 2, 10, 10, 10)
    local Layout = New("UIListLayout", { Padding = UDim.new(0, 6), Parent = Container })
    return Container, Layout
end

-- Accent underline that sits under a text label (the "ragebot" look)
local function Underline(Parent, Label)
    local Line = New("Frame", {
        BackgroundColor3 = "AccentColor",
        Size = UDim2.fromOffset(0, 2),
        ZIndex = 3,
        Parent = Parent,
    })
    Corner(Line, 1)
    local function Sync(Animate)
        local X = Unscale(Label.AbsolutePosition.X - Parent.AbsolutePosition.X)
        local Width = Unscale(Label.TextBounds.X)
        local Y = Unscale(Label.AbsolutePosition.Y - Parent.AbsolutePosition.Y) + Unscale(Label.AbsoluteSize.Y) / 2 + Unscale(Label.TextBounds.Y) / 2 + 2
        Tween(Line, { Position = UDim2.fromOffset(X, Y), Size = UDim2.fromOffset(Width, 2) }, Library.TweenInfo, Animate == true)
    end
    return Line, Sync
end

local function CreateGroupbox(Page, Info, Column)
    Info = Info or {}
    local Name = Info.Name or Info.Title or "Groupbox"
    local HasDescription = Info.Description ~= nil and Info.Description ~= ""
    local HeaderHeight = HasDescription and 46 or 34

    local Frame = BoxFrame(Column)
    local Box = setmetatable({
        Type = "Groupbox",
        Name = Name,
        Frame = Frame,
        Holder = Frame,
        Elements = {},
        Collapsed = Info.Collapsed == true,
        Collapsible = not Info.DisableCollapsing,
        MaxHeight = Info.MaxHeight,
        MaxPopOutHeight = Info.MaxPopOutHeight,
        PopOutWidth = Info.PopOutWidth,
        PoppedOut = false,
        Visible = Info.Visible ~= false,
        Page = Page,
        Column = Column,
    }, Groupbox)

    local Header = New("TextButton", {
        Size = UDim2.new(1, 0, 0, HeaderHeight),
        Parent = Frame,
    })
    Box.Header = Header

    local TextX = 12
    local IconImage = nil
    if Info.IconName or Info.Icon then
        IconImage = Library:CreateIcon(Info.IconName or Info.Icon, {
            Position = UDim2.fromOffset(11, 8),
            Size = UDim2.fromOffset(18, 18),
            ImageColor3 = "AccentColor",
            Parent = Header,
        })
        if IconImage then
            TextX = 36
        end
    end

    local Title = New("TextLabel", {
        FontFace = MediumFont,
        Text = Name,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(TextX, 0),
        Size = UDim2.new(1, -(TextX + 40), 0, 34),
        Parent = Header,
    })
    Box.TitleLabel = Title
    local Line, SyncLine = Underline(Header, Title)
    Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
        SyncLine(false)
    end)
    Title:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
        SyncLine(false)
    end)
    task.defer(SyncLine, false)

    local Description = New("TextLabel", {
        TextColor3 = "MutedColor",
        Text = Info.Description or "",
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Position = UDim2.fromOffset(TextX, 28),
        Size = UDim2.new(1, -(TextX + 12), 0, 14),
        Visible = HasDescription,
        Parent = Header,
    })

    local Buttons = New("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -8, 0, 0),
        Size = UDim2.fromOffset(0, 34),
        AutomaticSize = Enum.AutomaticSize.X,
        Parent = Header,
    })
    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 4),
        Parent = Buttons,
    })

    local Chevron = nil
    if Box.Collapsible then
        Chevron = Library:CreateIcon("chevron-down", {
            Size = UDim2.fromOffset(14, 14),
            ImageColor3 = "MutedColor",
            ImageTransparency = 0.4,
            Rotation = Box.Collapsed and 90 or 0,
            LayoutOrder = 2,
            Parent = Buttons,
        })
    end

    local PopOutButton = nil
    if Info.PopOut then
        PopOutButton = Library:CreateIcon("square-arrow-out-up-right", {
            Size = UDim2.fromOffset(14, 14),
            ImageColor3 = "MutedColor",
            ImageTransparency = 0.4,
            LayoutOrder = 1,
            Parent = Buttons,
        }, true)
        if not PopOutButton then
            PopOutButton = New("TextButton", {
                Text = "↗",
                TextColor3 = "MutedColor",
                TextSize = 13,
                Size = UDim2.fromOffset(14, 14),
                LayoutOrder = 1,
                Parent = Buttons,
            })
        end
    end

    local Container, Layout = BoxContainer(Frame, HeaderHeight)
    Box.Container = Container
    Box.Layout = Layout

    local Ready = false
    function Box:Resize(Animate)
        local ContentHeight = Unscale(Layout.AbsoluteContentSize.Y) + 12
        local Limit = Box.PoppedOut and Box.MaxPopOutHeight or Box.MaxHeight
        local Visible = Limit and math.min(ContentHeight, Limit) or ContentHeight
        Container.Size = UDim2.new(1, 0, 0, Visible)
        local Total = Box.Collapsed and HeaderHeight or (HeaderHeight + Visible)
        Tween(Frame, { Size = UDim2.new(1, 0, 0, Total) }, Library.TweenInfo, Animate == true and Ready and Library.Animations.Groupbox)
    end
    Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Box:Resize(false)
    end)
    task.defer(function()
        Box:Resize(false)
        Ready = true
    end)

    function Box:SetCollapsed(Collapsed)
        Box.Collapsed = Collapsed == true
        if Chevron then
            Tween(Chevron, { Rotation = Box.Collapsed and 90 or 0 })
        end
        Box:Resize(true)
    end
    function Box:ToggleCollapsed()
        Box:SetCollapsed(not Box.Collapsed)
    end

    Header.Activated:Connect(function()
        if Box.Collapsible and not Box.PoppedOut then
            Box:ToggleCollapsed()
        end
    end)

    function Box:SetVisible(Visible)
        Box.Visible = Visible ~= false
        Frame.Visible = Box.Visible
    end
    function Box:Show()
        Box:SetVisible(true)
    end
    function Box:Hide()
        Box:SetVisible(false)
    end
    function Box:SetDescription(Text)
        Description.Text = Text or ""
    end
    function Box:SetTitle(Text)
        Box.Name = Text
        Title.Text = Text
    end
    function Box:SetMaxHeight(Height)
        Box.MaxHeight = Height
        Box:Resize(true)
    end
    function Box:SetMaxPopOutHeight(Height)
        Box.MaxPopOutHeight = Height
        Box:Resize(true)
    end

    -- Pop-out: move the groupbox into a floating, draggable window
    local Float, Placeholder = nil, nil
    function Box:SetPopOutWidth(Width)
        Box.PopOutWidth = Width
        if Float then
            Float.Size = UDim2.fromOffset(Width or 260, 0)
        end
    end

    function Box:SetPoppedOut(PoppedOut, Position)
        PoppedOut = PoppedOut == true
        if PoppedOut == Box.PoppedOut then
            return
        end
        Box.PoppedOut = PoppedOut
        if PoppedOut then
            local Width = Box.PopOutWidth or Unscale(Frame.AbsoluteSize.X)
            local Abs = Frame.AbsolutePosition
            Float = New("Frame", {
                BackgroundTransparency = 1,
                Position = Position or UDim2.fromOffset(Abs.X + 24, Abs.Y + 24),
                Size = UDim2.fromOffset(Width, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Visible = Library.Toggled,
                Parent = FloatLayer,
            })
            AddScale(Float)
            Placeholder = New("TextButton", {
                BackgroundColor3 = "MainColor",
                BackgroundTransparency = 0.5,
                TextColor3 = "MutedColor",
                Text = Name .. " (popped out)",
                TextSize = 13,
                Size = UDim2.new(1, 0, 0, 30),
                LayoutOrder = Frame.LayoutOrder,
                Parent = Column,
            })
            Corner(Placeholder, Library.CornerRadius)
            Placeholder.Activated:Connect(function()
                Box:SetPoppedOut(false)
            end)
            Frame.Parent = Float
            Library:MakeDraggable(Float, Header)
            Library.PopOuts[Box] = Float
            Box.Collapsed = false
        else
            Frame.Parent = Column
            Library.PopOuts[Box] = nil
            if Float then
                Float:Destroy()
            end
            if Placeholder then
                Placeholder:Destroy()
            end
            Float, Placeholder = nil, nil
        end
        Box:Resize(false)
    end
    function Box:TogglePoppedOut()
        Box:SetPoppedOut(not Box.PoppedOut)
    end
    function Box:RefreshPopOutPlaceholder() end

    if PopOutButton then
        PopOutButton.Activated:Connect(function()
            Box:TogglePoppedOut()
        end)
    end

    function Box:Destroy()
        Box:SetPoppedOut(false)
        Frame:Destroy()
        if Page then
            local Index = table.find(Page.Boxes, Box)
            if Index then
                table.remove(Page.Boxes, Index)
            end
        end
    end

    Box:SetVisible(Box.Visible)
    if Page then
        table.insert(Page.Boxes, Box)
    end
    return Box
end

function TabboxTab:Resize()
    self.Tabbox:Resize()
end

function TabboxTab:Show()
    self.Tabbox:SelectTab(self)
end

local function CreateTabbox(Page, Info, Column)
    Info = Info or {}
    local Frame = BoxFrame(Column)
    local Box = setmetatable({
        Type = "Tabbox",
        Name = Info.Name or "",
        Frame = Frame,
        Holder = Frame,
        Tabs = {},
        ActiveTab = nil,
        MaxHeight = Info.MaxHeight,
        Visible = Info.Visible ~= false,
        Page = Page,
        Column = Column,
        Elements = {},
    }, Tabbox)

    local HeaderHeight = 34
    local Header = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, HeaderHeight),
        Parent = Frame,
    })

    local HeaderIcon = New("ImageLabel", {
        Position = UDim2.fromOffset(11, 8),
        Size = UDim2.fromOffset(18, 18),
        ImageColor3 = "AccentColor",
        Visible = false,
        Parent = Header,
    })

    local TabButtons = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -24, 1, 0),
        Parent = Header,
    })
    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 14),
        Parent = TabButtons,
    })

    local Line = New("Frame", {
        BackgroundColor3 = "AccentColor",
        Size = UDim2.fromOffset(0, 2),
        ZIndex = 3,
        Parent = Header,
    })
    Corner(Line, 1)

    local function RefreshIcon()
        local Icon = (Box.ActiveTab and Box.ActiveTab.Icon) or Info.IconName or Info.Icon
        local Shown = Icon ~= nil and Library:ApplyIcon(HeaderIcon, Icon)
        HeaderIcon.Visible = Shown == true
        TabButtons.Position = UDim2.fromOffset(Shown and 36 or 12, 0)
    end

    local function SyncLine(Animate)
        local Tab = Box.ActiveTab
        if not Tab then
            return
        end
        local Button = Tab.Button
        local X = Unscale(Button.AbsolutePosition.X - Header.AbsolutePosition.X)
        local Width = Unscale(Button.TextBounds.X)
        local Y = Unscale(Button.AbsoluteSize.Y) / 2 + Unscale(Button.TextBounds.Y) / 2 + 2 + Unscale(Button.AbsolutePosition.Y - Header.AbsolutePosition.Y)
        Tween(Line, { Position = UDim2.fromOffset(X, Y), Size = UDim2.fromOffset(Width, 2) }, Library.TweenInfo, Animate == true)
    end

    function Box:Resize()
        local Tab = Box.ActiveTab
        local ContentHeight = Tab and (Unscale(Tab.Layout.AbsoluteContentSize.Y) + 12) or 0
        local Visible = Box.MaxHeight and math.min(ContentHeight, Box.MaxHeight) or ContentHeight
        if Tab then
            Tab.Container.Size = UDim2.new(1, 0, 0, Visible)
        end
        Frame.Size = UDim2.new(1, 0, 0, HeaderHeight + Visible)
    end

    function Box:SelectTab(Tab)
        local Previous = Box.ActiveTab
        Box.ActiveTab = Tab
        for _, Other in ipairs(Box.Tabs) do
            local Active = Other == Tab
            Other.Container.Visible = Active
            Library:AddToRegistry(Other.Button, { TextColor3 = Active and "FontColor" or "MutedColor" })
        end
        if Previous and Previous ~= Tab and Library.Animations.TabSwitch then
            Tab.Container.Position = UDim2.fromOffset(10, HeaderHeight)
            Tween(Tab.Container, { Position = UDim2.fromOffset(0, HeaderHeight) })
        end
        RefreshIcon()
        SyncLine(Previous ~= nil and Previous ~= Tab)
        Box:Resize()
    end

    function Box:AddTab(Name, IconName, MaxHeight)
        local Button = New("TextButton", {
            FontFace = MediumFont,
            Text = Name,
            TextColor3 = "MutedColor",
            TextSize = 15,
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.fromScale(0, 1),
            LayoutOrder = #Box.Tabs + 1,
            Parent = TabButtons,
        })
        local Container, Layout = BoxContainer(Frame, HeaderHeight)
        Container.Visible = false

        local Tab = setmetatable({
            Type = "TabboxTab",
            Name = Name,
            Icon = IconName,
            Button = Button,
            Container = Container,
            Layout = Layout,
            Elements = {},
            Tabbox = Box,
        }, TabboxTab)

        function Tab:SetMaxHeight(Height)
            Box:SetMaxHeight(Height)
        end
        function Tab:Hide() end
        function Tab:Destroy()
            Button:Destroy()
            Container:Destroy()
            local Index = table.find(Box.Tabs, Tab)
            if Index then
                table.remove(Box.Tabs, Index)
            end
            if Box.ActiveTab == Tab and Box.Tabs[1] then
                Box:SelectTab(Box.Tabs[1])
            end
        end

        Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            if Box.ActiveTab == Tab then
                Box:Resize()
            end
        end)
        Button:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
            if Box.ActiveTab == Tab then
                SyncLine(false)
            end
        end)
        Button:GetPropertyChangedSignal("TextBounds"):Connect(function()
            if Box.ActiveTab == Tab then
                SyncLine(false)
            end
        end)
        Button.Activated:Connect(function()
            Box:SelectTab(Tab)
        end)

        table.insert(Box.Tabs, Tab)
        Box.Tabs[Name] = Tab
        if not Box.ActiveTab then
            Box:SelectTab(Tab)
        end
        if MaxHeight then
            Box.MaxHeight = MaxHeight
        end
        return Tab, #Box.Tabs
    end

    function Box:SetMaxHeight(Height)
        Box.MaxHeight = Height
        Box:Resize()
    end
    function Box:SetVisible(Visible)
        Box.Visible = Visible ~= false
        Frame.Visible = Box.Visible
    end
    function Box:Show()
        Box:SetVisible(true)
    end
    function Box:Hide()
        Box:SetVisible(false)
    end
    function Box:Destroy()
        Frame:Destroy()
        if Page then
            local Index = table.find(Page.Boxes, Box)
            if Index then
                table.remove(Page.Boxes, Index)
            end
        end
    end
    -- Pop-out isn't supported for tabboxes; kept for API compatibility
    function Box:SetPoppedOut() end
    function Box:TogglePoppedOut() end
    function Box:SetMaxPopOutHeight() end
    function Box:SetPopOutWidth() end
    function Box:RefreshPopOutPlaceholder() end
    function Box:UpdateCorners() end

    Box:SetVisible(Box.Visible)
    RefreshIcon()
    if Page then
        table.insert(Page.Boxes, Box)
    end
    return Box
end

function BaseGroupbox:AddTabbox(Info)
    if type(Info) ~= "table" then
        Info = { Name = Info }
    end
    return CreateTabbox(nil, Info, self.Container)
end

--// Pages (the two-column content of a tab or sub tab) \\--

local PageMethods = {}
PageMethods.__index = PageMethods
Library.Pages = {}

local function CreatePage(Parent)
    local Frame = New("CanvasGroup", {
        Size = UDim2.fromScale(1, 1),
        Visible = false,
        Parent = Parent,
    })

    local function Column(Position, Order)
        local Scroll = New("ScrollingFrame", {
            Position = Position,
            Size = UDim2.new(0.5, -15, 1, 0),
            ScrollBarThickness = 0,
            LayoutOrder = Order,
            Parent = Frame,
        })
        New("UIListLayout", { Padding = UDim.new(0, 10), Parent = Scroll })
        Padding(Scroll, 1, 12, 1, 1)
        return Scroll
    end

    local Page = setmetatable({
        Frame = Frame,
        Left = Column(UDim2.fromOffset(10, 0), 1),
        Right = Column(UDim2.new(0.5, 5, 0, 0), 2),
        Boxes = {},
    }, PageMethods)
    table.insert(Library.Pages, Page)
    return Page
end

function PageMethods:AddGroupbox(Info)
    Info = Info or {}
    local Column = ResolveSide(Info.Side) == "Right" and self.Right or self.Left
    return CreateGroupbox(self, Info, Column)
end

function PageMethods:AddLeftGroupbox(Name, IconName, Extra)
    local Info = type(Name) == "table" and Name or { Name = Name, IconName = IconName }
    if type(Extra) == "table" then
        for Key, Value in pairs(Extra) do
            Info[Key] = Value
        end
    end
    Info.Side = "Left"
    return self:AddGroupbox(Info)
end

function PageMethods:AddRightGroupbox(Name, IconName, Extra)
    local Info = type(Name) == "table" and Name or { Name = Name, IconName = IconName }
    if type(Extra) == "table" then
        for Key, Value in pairs(Extra) do
            Info[Key] = Value
        end
    end
    Info.Side = "Right"
    return self:AddGroupbox(Info)
end

function PageMethods:AddTabbox(Info)
    Info = Info or {}
    local Column = ResolveSide(Info.Side) == "Right" and self.Right or self.Left
    return CreateTabbox(self, Info, Column)
end

function PageMethods:AddLeftTabbox(Name, IconName)
    local Info = type(Name) == "table" and Name or { Name = Name, IconName = IconName }
    Info.Side = "Left"
    return self:AddTabbox(Info)
end

function PageMethods:AddRightTabbox(Name, IconName)
    local Info = type(Name) == "table" and Name or { Name = Name, IconName = IconName }
    Info.Side = "Right"
    return self:AddTabbox(Info)
end

function PageMethods:AddDependencyGroupbox(Info)
    local Box = self:AddGroupbox(Info)
    Box.Type = "DependencyGroupbox"
    Box.Dependencies = {}
    function Box:Update()
        local Visible = CheckDependencies(Box.Dependencies)
        Box.Visible = Visible
        Box.Frame.Visible = Visible
    end
    function Box:SetupDependencies(Dependencies)
        Box.Dependencies = Dependencies or {}
        Box:Update()
    end
    table.insert(Library.DependencyBoxes, Box)
    return Box
end

--// Search \\--

local function ElementMatches(Element, Query)
    local Text = Element.Text
    if type(Text) ~= "string" then
        return false
    end
    return StripRichText(Text):lower():find(Query, 1, true) ~= nil
end

function Library:UpdateSearch(Text)
    local Query = Trim(tostring(Text or "")):lower()
    Library.SearchText = Query
    Library.Searching = Query ~= ""

    for _, Page in ipairs(Library.Pages) do
        for _, Box in ipairs(Page.Boxes) do
            local NameMatch = Query ~= "" and Box.Name and Box.Name:lower():find(Query, 1, true) ~= nil
            local AnyMatch = false
            local Subs = Box.Type == "Tabbox" and Box.Tabs or { Box }
            for _, Sub in ipairs(Subs) do
                local SubMatch = false
                for _, Element in ipairs(Sub.Elements) do
                    if Element.Type ~= "DependencyBox" then
                        local Match = Query == "" or NameMatch or ElementMatches(Element, Query)
                        Element.SearchVisible = Match
                        ApplyVisibility(Element)
                        if Match then
                            SubMatch = true
                        end
                    end
                end
                if SubMatch then
                    AnyMatch = true
                    if Box.Type == "Tabbox" and Query ~= "" and Box.ActiveTab ~= Sub then
                        local ActiveHasMatch = false
                        for _, Element in ipairs(Box.ActiveTab.Elements) do
                            if Element.SearchVisible ~= false and Element.Type ~= "DependencyBox" then
                                ActiveHasMatch = true
                                break
                            end
                        end
                        if not ActiveHasMatch then
                            Box:SelectTab(Sub)
                        end
                    end
                end
            end
            Box.Frame.Visible = Box.Visible ~= false and (Query == "" or AnyMatch or NameMatch)
        end
    end
end

--// Window \\--

local PageForwarders = {
    "AddGroupbox", "AddLeftGroupbox", "AddRightGroupbox",
    "AddTabbox", "AddLeftTabbox", "AddRightTabbox", "AddDependencyGroupbox",
}

local function ForwardPageMethods(Object)
    for _, Name in ipairs(PageForwarders) do
        Object[Name] = function(self, ...)
            return self.Page[Name](self.Page, ...)
        end
    end
end

-- Replaces <accent>text</accent> with the current accent colour, so titles follow the theme.
local function FormatRichText(Text)
    Text = tostring(Text or "")
    local Hex = "#" .. Library.Scheme.AccentColor:ToHex()
    Text = Text:gsub("<accent>(.-)</accent>", '<font color="' .. Hex .. '">%1</font>')
    return Text
end
Library.FormatRichText = FormatRichText

Library.ThemeCallbacks = {}
do
    local BaseUpdate = Library.UpdateColorsUsingRegistry
    function Library:UpdateColorsUsingRegistry()
        BaseUpdate(self)
        for _, Callback in ipairs(Library.ThemeCallbacks) do
            Library:SafeCallback(Callback)
        end
    end
end

function Library:SetFont(FontFace)
    if typeof(FontFace) == "EnumItem" then
        FontFace = Font.fromEnum(FontFace)
    end
    if typeof(FontFace) ~= "Font" then
        return
    end
    Library.Scheme.Font = FontFace
    Library:UpdateColorsUsingRegistry()
end

local SWIPE_DIRECTIONS = {
    bottom = Vector2.new(0, 1),
    top = Vector2.new(0, -1),
    left = Vector2.new(-1, 0),
    right = Vector2.new(1, 0),
}

function Library:CreateWindow(Info)
    Info = Library:Validate(Info, {
        Title = "Snow",
        Footer = "",
        Center = true,
        AutoShow = true,
        Resizable = true,
        SidebarWidth = 190,
        MinSidebarWidth = 56,
        MaxSidebarWidth = 320,
        SidebarCollapseThreshold = 110,
        UnlockMouseWhileOpen = true,
        CornerRadius = 6,
        FooterHeight = 28,
    })

    if Library.Window then
        warn("[Snow] A window already exists; creating a second one is not supported.")
    end

    if Info.Font then
        Library:SetFont(Info.Font)
    end
    if Info.NotifySide then
        Library:SetNotifySide(Info.NotifySide)
    end
    if Info.ShowCustomCursor ~= nil then
        Library.ShowCustomCursor = Info.ShowCustomCursor
    end
    if Info.ToggleKeybind then
        Library.ToggleKeybind = Info.ToggleKeybind
    end
    if type(Info.Animations) == "table" then
        for Key, Value in pairs(Info.Animations) do
            Library.Animations[Key] = Value
        end
    end
    if Info.TabTransitionTime then
        Library.TabTransitionInfo = TweenInfo.new(Info.TabTransitionTime, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    end
    Library.TabSwipeOffset = Info.TabSwipeOffset or Library.TabSwipeOffset
    Library.TabSwipeFrom = Info.TabSwipeFrom or Library.TabSwipeFrom
    Library.CornerRadius = Info.CornerRadius
    if Info.DPIScale then
        Library:SetDPIScale(Info.DPIScale)
    end

    local ShowSearch = Info.Search == true and Info.DisableSearch ~= true

    local Window = {
        Title = Info.Title,
        Tabs = {},
        TabCount = 0,
        SidebarWidth = Info.SidebarWidth,
        LastExpandedWidth = Info.SidebarWidth,
        Compacted = false,
        AlwaysOnTop = Info.AlwaysOnTop == true,
        UnlockMouse = Info.UnlockMouseWhileOpen,
        PendingShow = false,
        ToggleToken = 0,
    }

    -- Resolve size into pixels
    local Size = Info.Size or UDim2.fromOffset(720, 500)
    local Viewport = ScreenGui.AbsoluteSize
    local Width = Size.X.Offset + Size.X.Scale * Viewport.X
    local Height = Size.Y.Offset + Size.Y.Scale * Viewport.Y
    Width = math.max(Width, Library.MinSize.X)
    Height = math.max(Height, Library.MinSize.Y)

    local Main = New("CanvasGroup", {
        Name = "Main",
        BackgroundColor3 = "BackgroundColor",
        BackgroundTransparency = 0,
        Position = (Info.Center or not Info.Position) and UDim2.new(0.5, -Width / 2, 0.5, -Height / 2) or Info.Position,
        Size = UDim2.fromOffset(Width, Height),
        Visible = false,
        GroupTransparency = 1,
        Parent = WindowLayer,
    })
    local MainCorner = Corner(Main, Library.CornerRadius)
    Window.Scale = AddScale(Main)
    Window.MainFrame = Main
    Library.WindowContainer = Main

    local BackgroundImage = New("ImageLabel", {
        ScaleType = Enum.ScaleType.Crop,
        Size = UDim2.fromScale(1, 1),
        Visible = false,
        ZIndex = 0,
        Parent = Main,
    })

    local Outline = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(1, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = 30,
        Parent = Main,
    })
    local OutlineCorner = Corner(Outline, math.max(Library.CornerRadius - 1, 0))
    Stroke(Outline)

    local ModalButton = New("TextButton", {
        Size = UDim2.fromOffset(0, 0),
        Modal = true,
        Visible = false,
        Parent = Main,
    })

    local FooterHeight = Info.FooterHeight

    -- Sidebar
    local Sidebar = New("Frame", {
        BackgroundColor3 = "SidebarColor",
        Size = UDim2.new(0, Window.SidebarWidth, 1, -FooterHeight),
        Parent = Main,
    })
    local SidebarLine = New("Frame", {
        BackgroundColor3 = "OutlineColor",
        Position = UDim2.fromOffset(Window.SidebarWidth, 0),
        Size = UDim2.new(0, 1, 1, -FooterHeight),
        Parent = Main,
    })

    local TitleArea = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 64),
        Parent = Sidebar,
    })
    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 7),
        Parent = TitleArea,
    })
    local TitlePadding = Padding(TitleArea, 0, 0, 18, 10)

    local TitleLabel = New("TextLabel", {
        FontFace = BoldFont,
        TextSize = 22,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromScale(0, 1),
        LayoutOrder = 1,
        Parent = TitleArea,
    })
    local TitleIcon = nil
    if Info.Icon then
        TitleIcon = Library:CreateIcon(Info.Icon, {
            Size = Info.IconSize or UDim2.fromOffset(22, 22),
            ImageColor3 = "AccentColor",
            LayoutOrder = 2,
            Parent = TitleArea,
        })
    end

    local SidebarTop = 64
    local SearchBox = nil
    if ShowSearch then
        local SearchFrame = New("Frame", {
            BackgroundColor3 = "ElementColor",
            Position = UDim2.fromOffset(10, SidebarTop),
            Size = UDim2.new(1, -20, 0, 26),
            Parent = Sidebar,
        })
        Corner(SearchFrame, 4)
        Library:CreateIcon("search", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 8, 0.5, 0),
            Size = UDim2.fromOffset(13, 13),
            ImageColor3 = "MutedColor",
            Parent = SearchFrame,
        })
        SearchBox = New("TextBox", {
            PlaceholderText = "search",
            TextXAlignment = Enum.TextXAlignment.Left,
            Position = UDim2.fromOffset(28, 0),
            Size = UDim2.new(1, -34, 1, 0),
            Parent = SearchFrame,
        })
        SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
            Library:UpdateSearch(SearchBox.Text)
        end)
        SidebarTop = SidebarTop + 36
        Window.SearchFrame = SearchFrame
    end

    local TabList = New("ScrollingFrame", {
        Position = UDim2.fromOffset(0, SidebarTop),
        Size = UDim2.new(1, 0, 1, -SidebarTop),
        ScrollBarThickness = 0,
        Parent = Sidebar,
    })
    New("UIListLayout", { Padding = UDim.new(0, 2), Parent = TabList })
    Padding(TabList, 0, 10, 8, 8)

    -- Content
    local Content = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(Window.SidebarWidth + 1, 0),
        Size = UDim2.new(1, -(Window.SidebarWidth + 1), 1, -FooterHeight),
        Parent = Main,
    })
    local TopBar = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 56),
        Parent = Content,
    })
    local TabInfo = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(18, 0),
        Size = UDim2.new(1, -36, 1, 0),
        Parent = TopBar,
    })
    New("UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 1), Parent = TabInfo })
    local TabInfoTitle = New("TextLabel", {
        FontFace = BoldFont,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 18),
        LayoutOrder = 1,
        Parent = TabInfo,
    })
    local TabInfoDescription = New("TextLabel", {
        TextColor3 = "MutedColor",
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Size = UDim2.new(1, 0, 0, 14),
        LayoutOrder = 2,
        Parent = TabInfo,
    })

    local PagesHolder = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 56),
        Size = UDim2.new(1, 0, 1, -56),
        ClipsDescendants = true,
        Parent = Content,
    })

    -- Footer
    local Footer = New("Frame", {
        BackgroundColor3 = "SidebarColor",
        Position = UDim2.new(0, 0, 1, -FooterHeight),
        Size = UDim2.new(1, 0, 0, FooterHeight),
        Parent = Main,
    })
    New("Frame", {
        BackgroundColor3 = "OutlineColor",
        Size = UDim2.new(1, 0, 0, 1),
        Parent = Footer,
    })
    local FooterLeft = New("TextLabel", {
        TextColor3 = "MutedColor",
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(0.5, -12, 1, 0),
        Parent = Footer,
    })
    local FooterRight = New("TextLabel", {
        TextColor3 = "MutedColor",
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -12, 0, 0),
        Size = UDim2.new(0.5, -12, 1, 0),
        Parent = Footer,
    })

    local function RefreshTexts()
        TitleLabel.Text = FormatRichText(Window.Title)
        FooterLeft.Text = FormatRichText(Window.Footer or "")
        FooterRight.Text = FormatRichText(Window.FooterRight or "")
    end
    Window.Footer = Info.Footer
    Window.FooterRight = Info.FooterRight
    RefreshTexts()
    table.insert(Library.ThemeCallbacks, RefreshTexts)

    -- Dragging (title area, top bar, footer)
    Library:MakeDraggable(Main, TitleArea)
    Library:MakeDraggable(Main, TopBar)
    Library:MakeDraggable(Main, Footer)

    if Info.Resizable then
        local Grip = New("TextButton", {
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.fromScale(1, 1),
            Size = UDim2.fromOffset(18, 18),
            ZIndex = 31,
            Parent = Main,
        })
        Library:CreateIcon("move-diagonal-2", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(10, 10),
            ImageColor3 = "MutedColor",
            ImageTransparency = 0.6,
            Rotation = 90,
            Parent = Grip,
        })
        Library:MakeResizable(Main, Grip)
    end

    -- Sidebar sizing / compact mode
    local CompactTargets = {}
    local function ApplySidebarWidth(WidthValue)
        Window.SidebarWidth = WidthValue
        Sidebar.Size = UDim2.new(0, WidthValue, 1, -FooterHeight)
        SidebarLine.Position = UDim2.fromOffset(WidthValue, 0)
        Content.Position = UDim2.fromOffset(WidthValue + 1, 0)
        Content.Size = UDim2.new(1, -(WidthValue + 1), 1, -FooterHeight)
        local Compact = WidthValue < Info.SidebarCollapseThreshold
        Window.Compacted = Compact
        TitleLabel.Visible = not Compact or not TitleIcon
        TitlePadding.PaddingLeft = UDim.new(0, Compact and math.max((WidthValue - 22) / 2, 4) or 18)
        if Window.SearchFrame then
            Window.SearchFrame.Visible = not Compact
        end
        for Target, Kind in pairs(CompactTargets) do
            if Kind == "Label" then
                Target.Visible = not Compact
            elseif Kind == "Icon" then
                Target.Position = Compact and UDim2.new(0.5, 0, 0.5, 0) or UDim2.new(0, 19, 0.5, 0)
            end
        end
    end

    function Window:GetSidebarWidth()
        return Window.SidebarWidth
    end
    function Window:IsSidebarCompacted()
        return Window.Compacted
    end
    function Window:SetSidebarWidth(WidthValue)
        WidthValue = math.clamp(WidthValue, Info.MinSidebarWidth, Info.MaxSidebarWidth)
        if WidthValue >= Info.SidebarCollapseThreshold then
            Window.LastExpandedWidth = WidthValue
        end
        ApplySidebarWidth(WidthValue)
    end
    function Window:SetCompact(State)
        if State then
            Window:SetSidebarWidth(Info.SidebarCompactWidth or Info.MinSidebarWidth)
        else
            Window:SetSidebarWidth(Window.LastExpandedWidth)
        end
    end

    if Info.EnableSidebarResize then
        local Handle = New("TextButton", {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.fromScale(0.5, 0),
            Size = UDim2.new(0, 7, 1, 0),
            ZIndex = 5,
            Parent = SidebarLine,
        })
        local Resizing, StartX, StartWidth = false, 0, 0
        Handle.InputBegan:Connect(function(Input)
            if IsClick(Input) then
                Resizing, StartX, StartWidth = true, Input.Position.X, Window.SidebarWidth
                local Changed
                Changed = Input.Changed:Connect(function()
                    if Input.UserInputState == Enum.UserInputState.End then
                        Resizing = false
                        Changed:Disconnect()
                        if Info.DisableCompactingSnap ~= true and Window.SidebarWidth < Info.SidebarCollapseThreshold then
                            Window:SetCompact(true)
                        end
                    end
                end)
            end
        end)
        Library:GiveSignal(UserInputService.InputChanged:Connect(function(Input)
            if Resizing and IsMove(Input) then
                Window:SetSidebarWidth(StartWidth + Unscale(Input.Position.X - StartX))
            end
        end))
    end

    -- Pages / tab switching
    local CurrentPage = nil
    local function ShowPage(Page, Direction)
        if CurrentPage == Page then
            return
        end
        Library:CloseAllPopups()
        if CurrentPage then
            CurrentPage.Frame.Visible = false
        end
        CurrentPage = Page
        Library.CurrentPage = Page
        if not Page then
            return
        end
        Page.Frame.Visible = true
        if Library.Animations.TabSwitch then
            local Swipe = SWIPE_DIRECTIONS[tostring(Library.TabSwipeFrom):lower()] or Direction or SWIPE_DIRECTIONS.bottom
            local Offset = Library.TabSwipeOffset
            Page.Frame.Position = UDim2.fromOffset(Swipe.X * Offset, Swipe.Y * Offset)
            Page.Frame.GroupTransparency = 1
            Tween(Page.Frame, { Position = UDim2.fromOffset(0, 0), GroupTransparency = 0 }, Library.TabTransitionInfo)
        else
            Page.Frame.Position = UDim2.fromOffset(0, 0)
            Page.Frame.GroupTransparency = 0
        end
    end

    local TabMethods = {}
    TabMethods.__index = TabMethods

    function TabMethods:GetActivePage()
        if #self.SubTabs > 0 then
            return (self.ActiveSubTab or self.SubTabs[1]).Page
        end
        return self.Page
    end

    function TabMethods:Show()
        local Previous = Library.ActiveTab
        if Previous == self then
            return
        end
        Library.PreviousTab = Previous
        Library.ActiveTab = self
        for _, Other in ipairs(Window.Tabs) do
            Other:Hover(false)
        end
        self:UpdateTopBar()
        local Direction = nil
        if Previous and tostring(Library.TabSwipeFrom):lower() == "auto" then
            Direction = (self.Order or 0) >= (Previous.Order or 0) and SWIPE_DIRECTIONS.bottom or SWIPE_DIRECTIONS.top
        end
        ShowPage(self:GetActivePage(), Direction)
    end

    function TabMethods:Hover(Hovering)
        local Active = Library.ActiveTab == self
        Tween(self.Button, { BackgroundTransparency = Active and 0 or (Hovering and 0.6 or 1) }, Library.FastTweenInfo)
        Library:AddToRegistry(self.Label, { TextColor3 = (Active or Hovering) and "FontColor" or "MutedColor" })
        if self.IconImage then
            Library:AddToRegistry(self.IconImage, { ImageColor3 = Active and "AccentColor" or "MutedColor" })
        end
    end

    function TabMethods:SetVisible(Visible)
        self.Button.Visible = Visible ~= false
    end
    function TabMethods:SetOrder(Order)
        self.Order = Order
        self.Button.LayoutOrder = Order
    end
    function TabMethods:SetTooltip(Text)
        if self.TooltipTable then
            self.TooltipTable:Destroy()
        end
        self.TooltipTable = Text and Library:AddTooltip(Text, nil, self.Button) or nil
    end
    function TabMethods:SetDescription(Text)
        self.Description = Text
        if Library.ActiveTab == self then
            self:UpdateTopBar()
        end
    end
    TabMethods.UpdateTabInfo = function(self)
        if Library.ActiveTab == self then
            self:UpdateTopBar()
        end
    end
    function TabMethods:Destroy()
        self.Button:Destroy()
        self.Page.Frame:Destroy()
        self.SubTabBar:Destroy()
        for _, SubTab in ipairs(self.SubTabs) do
            SubTab.Page.Frame:Destroy()
        end
        local Index = table.find(Window.Tabs, self)
        if Index then
            table.remove(Window.Tabs, Index)
        end
        Library.Tabs[self.Name] = nil
        if Library.ActiveTab == self then
            Library.ActiveTab = nil
            if Window.Tabs[1] then
                Window.Tabs[1]:Show()
            else
                ShowPage(nil)
            end
        end
    end

    function TabMethods:AddSubTab(Name, IconName)
        if type(Name) == "table" then
            IconName = Name.Icon or Name.IconName
            Name = Name.Name
        end
        local Tab = self
        local Pill = New("TextButton", {
            BackgroundColor3 = "ElementColor",
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(0, 34),
            AutomaticSize = Enum.AutomaticSize.X,
            LayoutOrder = #Tab.SubTabs + 1,
            Parent = Tab.SubTabBar,
        })
        Corner(Pill, 6)
        Padding(Pill, 0, 0, 14, 14)
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 6),
            Parent = Pill,
        })
        local PillIcon = nil
        if IconName then
            PillIcon = Library:CreateIcon(IconName, {
                Size = UDim2.fromOffset(15, 15),
                ImageColor3 = "MutedColor",
                LayoutOrder = 1,
                Parent = Pill,
            })
        end
        local PillLabel = New("TextLabel", {
            FontFace = MediumFont,
            Text = Name,
            TextColor3 = "MutedColor",
            TextSize = 15,
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.fromScale(0, 1),
            LayoutOrder = 2,
            Parent = Pill,
        })
        -- The underline lives on a separate layer so the pill's list layout doesn't move it
        local PillLine = New("Frame", {
            BackgroundColor3 = "AccentColor",
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0.5, 1),
            Size = UDim2.fromOffset(0, 2),
        })
        Corner(PillLine, 1)

        local SubTab = {
            Type = "SubTab",
            Name = Name,
            Icon = IconName,
            Button = Pill,
            Tab = Tab,
            Page = CreatePage(PagesHolder),
        }
        ForwardPageMethods(SubTab)

        PillLine.Parent = Tab.SubTabLineLayer
        local function SyncPillLine()
            local X = Unscale(Pill.AbsolutePosition.X - Tab.SubTabLineLayer.AbsolutePosition.X) + Unscale(Pill.AbsoluteSize.X) / 2
            local Y = Unscale(Pill.AbsolutePosition.Y - Tab.SubTabLineLayer.AbsolutePosition.Y) + Unscale(Pill.AbsoluteSize.Y) - 4
            PillLine.Position = UDim2.fromOffset(X, Y)
        end
        Pill:GetPropertyChangedSignal("AbsolutePosition"):Connect(SyncPillLine)
        Pill:GetPropertyChangedSignal("AbsoluteSize"):Connect(SyncPillLine)
        task.defer(SyncPillLine)

        local function Refresh()
            local Active = Tab.ActiveSubTab == SubTab
            Tween(Pill, { BackgroundTransparency = Active and 0 or 1 }, Library.FastTweenInfo)
            Tween(PillLine, {
                BackgroundTransparency = Active and 0 or 1,
                Size = UDim2.fromOffset(Active and 14 or 0, 2),
            }, Library.TweenInfo)
            Library:AddToRegistry(PillLabel, { TextColor3 = Active and "FontColor" or "MutedColor" })
            if PillIcon then
                Library:AddToRegistry(PillIcon, { ImageColor3 = Active and "AccentColor" or "MutedColor" })
            end
        end
        SubTab.Refresh = Refresh

        function SubTab:Show()
            Tab.ActiveSubTab = SubTab
            for _, Other in ipairs(Tab.SubTabs) do
                Other.Refresh()
            end
            if Library.ActiveTab == Tab then
                ShowPage(SubTab.Page)
            end
        end
        function SubTab:SetVisible(Visible)
            Pill.Visible = Visible ~= false
        end
        function SubTab:Destroy()
            Pill:Destroy()
            PillLine:Destroy()
            SubTab.Page.Frame:Destroy()
            local Index = table.find(Tab.SubTabs, SubTab)
            if Index then
                table.remove(Tab.SubTabs, Index)
            end
        end

        Pill.MouseEnter:Connect(function()
            if Tab.ActiveSubTab ~= SubTab then
                Library:AddToRegistry(PillLabel, { TextColor3 = "FontColor" })
            end
        end)
        Pill.MouseLeave:Connect(function()
            Refresh()
        end)
        Pill.Activated:Connect(function()
            SubTab:Show()
        end)

        table.insert(Tab.SubTabs, SubTab)
        Tab.SubTabs[Name] = SubTab
        if not Tab.ActiveSubTab then
            Tab.ActiveSubTab = SubTab
        end
        Refresh()
        if Library.ActiveTab == Tab then
            Tab:UpdateTopBar()
            ShowPage(Tab:GetActivePage())
        end
        return SubTab
    end

    local function CreateTab(TabInfoArg, Icon, Description, Order)
        local Name = TabInfoArg
        local Tooltip = nil
        if type(TabInfoArg) == "table" then
            Name = TabInfoArg.Name
            Icon = TabInfoArg.Icon or TabInfoArg.IconName
            Description = TabInfoArg.Description
            Order = TabInfoArg.Order
            Tooltip = TabInfoArg.Tooltip
        end
        Window.TabCount = Window.TabCount + 1

        local Button = New("TextButton", {
            BackgroundColor3 = "ElementColor",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 34),
            LayoutOrder = Order or NextOrder(),
            Parent = TabList,
        })
        Corner(Button, 6)

        local IconImage = nil
        if Icon then
            IconImage = Library:CreateIcon(Icon, {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0, 19, 0.5, 0),
                Size = UDim2.fromOffset(18, 18),
                ImageColor3 = "MutedColor",
                Parent = Button,
            })
            if IconImage then
                CompactTargets[IconImage] = "Icon"
            end
        end
        local Label = New("TextLabel", {
            FontFace = MediumFont,
            Text = Name,
            TextColor3 = "MutedColor",
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Position = UDim2.fromOffset(IconImage and 38 or 12, 0),
            Size = UDim2.new(1, -(IconImage and 44 or 18), 1, 0),
            Parent = Button,
        })
        CompactTargets[Label] = "Label"

        local SubTabBar = New("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(10, 0),
            Size = UDim2.new(1, -20, 1, 0),
            Visible = false,
            Parent = TopBar,
        })
        local PillHolder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Parent = SubTabBar,
        })
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 4),
            Parent = PillHolder,
        })
        local LineLayer = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            ZIndex = 2,
            Parent = SubTabBar,
        })

        local Tab = setmetatable({
            Type = "Tab",
            Name = Name,
            Icon = Icon,
            Description = Description,
            Order = Order or Window.TabCount,
            Button = Button,
            Label = Label,
            IconImage = IconImage,
            Page = CreatePage(PagesHolder),
            SubTabs = {},
            ActiveSubTab = nil,
            SubTabBar = PillHolder,
            SubTabLineLayer = LineLayer,
            SubTabBarFrame = SubTabBar,
        }, TabMethods)
        ForwardPageMethods(Tab)

        Button.MouseEnter:Connect(function()
            Tab:Hover(true)
        end)
        Button.MouseLeave:Connect(function()
            Tab:Hover(false)
        end)
        Button.Activated:Connect(function()
            Tab:Show()
        end)

        if Tooltip then
            Tab:SetTooltip(Tooltip)
        end

        table.insert(Window.Tabs, Tab)
        Library.Tabs[Name] = Tab
        if not Library.ActiveTab then
            Tab:Show()
        end
        Tab:Hover(false)
        return Tab
    end

    function TabMethods:UpdateTopBar()
        local HasSubTabs = #self.SubTabs > 0
        for _, Other in ipairs(Window.Tabs) do
            Other.SubTabBarFrame.Visible = Other == self and HasSubTabs
        end
        TabInfo.Visible = not HasSubTabs
        if Window.TabInfoOverride then
            TabInfoTitle.Text = Window.TabInfoOverride[1]
            TabInfoDescription.Text = Window.TabInfoOverride[2] or ""
            TabInfoDescription.Visible = (Window.TabInfoOverride[2] or "") ~= ""
        else
            TabInfoTitle.Text = self.Name
            TabInfoDescription.Text = self.Description or ""
            TabInfoDescription.Visible = (self.Description or "") ~= ""
        end
    end

    function Window:AddTab(...)
        return CreateTab(...)
    end

    function Window:AddSection(Name, Order)
        local Label = New("TextLabel", {
            FontFace = MediumFont,
            Text = Name,
            TextColor3 = "MutedColor",
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, 0, 0, 26),
            LayoutOrder = Order or NextOrder(),
            Parent = TabList,
        })
        Padding(Label, 6, 0, 6, 0)
        CompactTargets[Label] = "Label"
        local Section = { Label = Label }
        function Section:SetText(Text)
            Label.Text = Text
        end
        function Section:SetVisible(Visible)
            Label.Visible = Visible ~= false
        end
        function Section:Destroy()
            CompactTargets[Label] = nil
            Label:Destroy()
        end
        return Section
    end

    function Window:AddKeyTab(...)
        local Tab = CreateTab(...)
        Tab.Type = "KeyTab"
        Tab.Page.Left.Visible = false
        Tab.Page.Right.Visible = false

        function Tab:AddKeyBox(A, B)
            local Callback = type(A) == "function" and A or B
            local Holder = New("Frame", {
                BackgroundColor3 = "MainColor",
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.45),
                Size = UDim2.fromOffset(300, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = Tab.Page.Frame,
            })
            Corner(Holder, Library.CornerRadius)
            Stroke(Holder, "OutlineColor", 0.35)
            Padding(Holder, 14, 14, 14, 14)
            New("UIListLayout", { Padding = UDim.new(0, 8), Parent = Holder })
            New("TextLabel", {
                FontFace = MediumFont,
                Text = "enter your key",
                TextSize = 15,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, 0, 0, 18),
                LayoutOrder = 1,
                Parent = Holder,
            })
            local BoxFrame = New("Frame", {
                BackgroundColor3 = "ElementColor",
                Size = UDim2.new(1, 0, 0, 26),
                LayoutOrder = 2,
                Parent = Holder,
            })
            Corner(BoxFrame, 4)
            local Box = New("TextBox", {
                PlaceholderText = "key",
                TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2.fromOffset(8, 0),
                Size = UDim2.new(1, -16, 1, 0),
                Parent = BoxFrame,
            })
            local Submit = New("TextButton", {
                BackgroundColor3 = "AccentColor",
                BackgroundTransparency = 0,
                TextColor3 = "WhiteColor",
                Text = "submit",
                TextSize = 13,
                Size = UDim2.new(1, 0, 0, 24),
                LayoutOrder = 3,
                Parent = Holder,
            })
            Corner(Submit, 4)
            HoverOverlay(Submit, 4)
            Submit.Activated:Connect(function()
                Library:SafeCallback(Callback, Box.Text)
            end)
            return Box
        end
        return Tab
    end

    function Window:AddCustomTab(...)
        local Tab = CreateTab(...)
        Tab.Type = "CustomTab"
        Tab.Page.Left.Visible = false
        Tab.Page.Right.Visible = false
        Tab.Container = Tab.Page.Frame
        return Tab
    end

    function Window:ShowTabInfo(Name, Description)
        Window.TabInfoOverride = { Name, Description }
        if Library.ActiveTab then
            Library.ActiveTab:UpdateTopBar()
        end
    end
    function Window:HideTabInfo()
        Window.TabInfoOverride = nil
        if Library.ActiveTab then
            Library.ActiveTab:UpdateTopBar()
        end
    end

    function Window:ChangeTitle(Title)
        Window.Title = Title
        RefreshTexts()
    end
    function Window:RefreshTitleSize() end
    function Window:SetFooter(Text)
        Window.Footer = Text
        RefreshTexts()
    end
    function Window:SetFooterRight(Text)
        Window.FooterRight = Text
        RefreshTexts()
    end
    function Window:SetBackgroundImage(Image)
        BackgroundImage.Visible = Library:ApplyIcon(BackgroundImage, Image)
    end
    function Window:SetBackgroundImageTransparency(Transparency)
        BackgroundImage.ImageTransparency = Transparency
    end
    function Window:SetCornerRadius(Radius)
        Library.CornerRadius = Radius
        MainCorner.CornerRadius = UDim.new(0, Radius)
        OutlineCorner.CornerRadius = UDim.new(0, math.max(Radius - 1, 0))
    end
    function Window:SetAlwaysOnTop(Enabled)
        Window.AlwaysOnTop = Enabled == true
        ScreenGui.DisplayOrder = Window.AlwaysOnTop and 2147483647 or 999
    end
    function Window:SetSnapping(Enabled)
        Window.Snapping = Enabled == true
    end
    function Window:SetAnimations(Animations, TransitionTime, SwipeOffset, SwipeFrom)
        if type(Animations) == "table" then
            for Key, Value in pairs(Animations) do
                Library.Animations[Key] = Value
            end
        end
        if TransitionTime then
            Library.TabTransitionInfo = TweenInfo.new(TransitionTime, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        end
        Library.TabSwipeOffset = SwipeOffset or Library.TabSwipeOffset
        Library.TabSwipeFrom = SwipeFrom or Library.TabSwipeFrom
    end
    function Window:Toggle(Value)
        Library:Toggle(Value)
    end

    --// Dialogs \\--

    local DialogVariants = {
        Primary = { "AccentColor", "WhiteColor", 0 },
        Secondary = { "ElementColor", "FontColor", 0 },
        Destructive = { "RedColor", "WhiteColor", 0 },
        Ghost = { "ElementColor", "MutedColor", 1 },
    }

    function Window:AddDialog(Idx, DialogInfo)
        if type(Idx) == "table" then
            DialogInfo, Idx = Idx, Idx.Idx or HttpService:GenerateGUID(false)
        end
        DialogInfo = DialogInfo or {}
        if Library.Dialogues[Idx] then
            Library.Dialogues[Idx]:Dismiss()
        end

        local Cover = New("TextButton", {
            BackgroundColor3 = "DarkColor",
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            ZIndex = 40,
            Parent = Main,
        })
        local Card = New("Frame", {
            BackgroundColor3 = "MainColor",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(DialogInfo.Width or 360, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            ZIndex = 41,
            Parent = Cover,
        })
        Corner(Card, 8)
        Stroke(Card)
        Padding(Card, 16, 14, 16, 16)
        New("UIListLayout", { Padding = UDim.new(0, 10), Parent = Card })
        local CardScale = New("UIScale", { Scale = 0.94, Parent = Card })

        local Header = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 20),
            LayoutOrder = 1,
            Parent = Card,
        })
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 8),
            Parent = Header,
        })
        if DialogInfo.Icon then
            Library:CreateIcon(DialogInfo.Icon, {
                Size = UDim2.fromOffset(18, 18),
                ImageColor3 = "AccentColor",
                LayoutOrder = 1,
                Parent = Header,
            })
        end
        local DialogTitle = New("TextLabel", {
            FontFace = BoldFont,
            Text = DialogInfo.Title or "",
            TextColor3 = DialogInfo.TitleColor and function() return DialogInfo.TitleColor end or "FontColor",
            TextSize = 16,
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.fromScale(0, 1),
            LayoutOrder = 2,
            Parent = Header,
        })
        local DialogDescription = New("TextLabel", {
            Text = DialogInfo.Description or "",
            TextColor3 = DialogInfo.DescriptionColor and function() return DialogInfo.DescriptionColor end or "MutedColor",
            TextSize = 13,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Visible = (DialogInfo.Description or "") ~= "",
            LayoutOrder = 2,
            Parent = Card,
        })
        local Body = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 3,
            Parent = Card,
        })
        New("UIListLayout", { Padding = UDim.new(0, 6), Parent = Body })
        local FooterRow = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 28),
            LayoutOrder = 4,
            Parent = Card,
        })
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 8),
            Parent = FooterRow,
        })

        local Dialog = setmetatable({
            Type = "Dialog",
            Idx = Idx,
            Container = Body,
            Elements = {},
            Buttons = {},
            Destroyed = false,
            OutsideClickDismiss = DialogInfo.OutsideClickDismiss == true,
            AutoDismiss = DialogInfo.AutoDismiss ~= false,
        }, BaseGroupbox)

        function Dialog:Resize() end
        function Dialog:SetTitle(Text)
            DialogTitle.Text = Text
        end
        function Dialog:SetDescription(Text)
            DialogDescription.Text = Text or ""
            DialogDescription.Visible = DialogDescription.Text ~= ""
        end

        function Dialog:Dismiss()
            if Dialog.Destroyed then
                return
            end
            Dialog.Destroyed = true
            Library.Dialogues[Idx] = nil
            if Library.ActiveDialog == Dialog then
                Library.ActiveDialog = nil
            end
            Tween(Cover, { BackgroundTransparency = 1 })
            Tween(CardScale, { Scale = 0.94 })
            Card.Visible = false
            task.delay(0.2, function()
                Cover:Destroy()
            end)
        end
        Dialog.Destroy = Dialog.Dismiss

        function Dialog:AddFooterButton(ButtonIdx, ButtonInfo)
            ButtonInfo = ButtonInfo or {}
            local Variant = DialogVariants[ButtonInfo.Variant or "Secondary"] or DialogVariants.Secondary
            local Title = ButtonInfo.Title or ButtonInfo.Text or tostring(ButtonIdx)
            local Button = New("TextButton", {
                BackgroundColor3 = Variant[1],
                BackgroundTransparency = Variant[3],
                TextColor3 = Variant[2],
                Text = Title,
                TextSize = 13,
                AutomaticSize = Enum.AutomaticSize.X,
                Size = UDim2.fromOffset(0, 28),
                LayoutOrder = ButtonInfo.Order or (#FooterRow:GetChildren()),
                Parent = FooterRow,
            })
            Corner(Button, 4)
            Padding(Button, 0, 0, 14, 14)
            HoverOverlay(Button, 4)
            local Entry = { Button = Button, Disabled = false }
            Dialog.Buttons[ButtonIdx] = Entry

            if ButtonInfo.WaitTime and ButtonInfo.WaitTime > 0 then
                Entry.Disabled = true
                Button.TextTransparency = 0.5
                task.spawn(function()
                    for Remaining = math.ceil(ButtonInfo.WaitTime), 1, -1 do
                        if Dialog.Destroyed then
                            return
                        end
                        Button.Text = string.format("%s (%d)", Title, Remaining)
                        task.wait(1)
                    end
                    Button.Text = Title
                    Entry.Disabled = false
                    Button.TextTransparency = 0
                end)
            end

            Button.Activated:Connect(function()
                if Entry.Disabled or Dialog.Destroyed then
                    return
                end
                Library:SafeCallback(ButtonInfo.Callback, Dialog)
                if Dialog.AutoDismiss then
                    Dialog:Dismiss()
                end
            end)
            return Entry
        end
        function Dialog:RemoveFooterButton(ButtonIdx)
            local Entry = Dialog.Buttons[ButtonIdx]
            if Entry then
                Entry.Button:Destroy()
                Dialog.Buttons[ButtonIdx] = nil
            end
        end
        function Dialog:SetButtonDisabled(ButtonIdx, Disabled)
            local Entry = Dialog.Buttons[ButtonIdx]
            if Entry then
                Entry.Disabled = Disabled == true
                Entry.Button.TextTransparency = Entry.Disabled and 0.5 or 0
            end
        end
        function Dialog:SetButtonOrder(ButtonIdx, Order)
            local Entry = Dialog.Buttons[ButtonIdx]
            if Entry then
                Entry.Button.LayoutOrder = Order
            end
        end

        for ButtonIdx, ButtonInfo in pairs(DialogInfo.FooterButtons or {}) do
            Dialog:AddFooterButton(ButtonIdx, ButtonInfo)
        end

        Cover.Activated:Connect(function()
            if Dialog.OutsideClickDismiss and not Library:MouseIsOverFrame(Card) then
                Dialog:Dismiss()
            end
        end)

        Library.Dialogues[Idx] = Dialog
        Library.ActiveDialog = Dialog
        Tween(Cover, { BackgroundTransparency = 0.45 })
        Tween(CardScale, { Scale = 1 })
        return Dialog
    end

    --// Showing / hiding \\--

    Window.Main = Main
    Window.ModalButton = ModalButton
    Library.Window = Window

    if Info.ShowMobileButtons ~= false and Library.IsMobile then
        Window.MobileToggle = Library:AddDraggableButton("Toggle", function()
            Library:Toggle()
        end)
    end

    if Info.AutoShow then
        if Library.ActiveLoading then
            Window.PendingShow = true
        else
            task.defer(Library.Toggle, Library, true)
        end
    end

    return Window
end

--// Toggle / input / unload \\--

function Library:Toggle(Value)
    if Library.Unloaded then
        return
    end
    if Value == nil then
        Value = not Library.Toggled
    end
    Library.Toggled = Value == true

    local Window = Library.Window
    if not Window then
        return
    end
    local Main = Window.Main

    if not Library.Toggled then
        Library:CloseAllPopups()
        TooltipLabel.Visible = false
    end
    Window.ModalButton.Visible = Library.Toggled and Window.UnlockMouse == true
    for _, Float in pairs(Library.PopOuts) do
        Float.Visible = Library.Toggled
    end

    Window.ToggleToken = Window.ToggleToken + 1
    local Token = Window.ToggleToken

    if Library.Animations.ToggleWindow then
        if Library.Toggled then
            Main.Visible = true
            Window.Scale.Scale = Library.DPIScale * 0.96
            Tween(Main, { GroupTransparency = 0 }, Library.WindowAnimationInfo)
            Tween(Window.Scale, { Scale = Library.DPIScale }, Library.WindowAnimationInfo)
        else
            Tween(Main, { GroupTransparency = 1 }, Library.WindowAnimationInfo)
            Tween(Window.Scale, { Scale = Library.DPIScale * 0.96 }, Library.WindowAnimationInfo)
            task.delay(Library.WindowAnimationInfo.Time, function()
                if Token == Window.ToggleToken and not Library.Toggled then
                    Main.Visible = false
                end
            end)
        end
    else
        Main.GroupTransparency = Library.Toggled and 0 or 1
        Window.Scale.Scale = Library.DPIScale
        Main.Visible = Library.Toggled
    end
end

local function IsToggleKey(Input)
    local Key = Library.ToggleKeybind
    if type(Key) == "table" and Key.Type == "KeyPicker" then
        return Key:Matches(Input)
    elseif typeof(Key) == "EnumItem" then
        if Key.EnumType == Enum.UserInputType then
            return Input.UserInputType == Key
        end
        return Input.KeyCode == Key
    elseif type(Key) == "string" then
        return InputKeyName(Input) == Key
    end
    return false
end

Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input)
    if Library.Unloaded or Library.IsPicking then
        return
    end
    if UserInputService:GetFocusedTextBox() then
        return
    end

    if IsToggleKey(Input) then
        Library:Toggle()
    end

    for _, KeyPicker in ipairs(Library.KeyPickers) do
        if KeyPicker ~= Library.ToggleKeybind and KeyPicker:Matches(Input) then
            if KeyPicker.Mode == "Hold" then
                KeyPicker:SetState(true)
                Library:SafeCallback(KeyPicker.Clicked)
            elseif KeyPicker.Mode == "Always" then
                Library:SafeCallback(KeyPicker.Clicked)
            else
                KeyPicker:DoClick()
            end
        end
    end
    Library:UpdateDependencyBoxes()
end))

Library:GiveSignal(UserInputService.InputEnded:Connect(function(Input)
    if Library.Unloaded then
        return
    end
    local KeyName = InputKeyName(Input)
    if not KeyName then
        return
    end
    for _, KeyPicker in ipairs(Library.KeyPickers) do
        if KeyPicker.Mode == "Hold" and KeyPicker.Toggled and KeyPicker.Value == KeyName then
            KeyPicker:SetState(false)
        end
    end
end))

function Library:Unload()
    if Library.Unloaded then
        return
    end
    Library.Unloaded = true

    for _, Callback in ipairs(Library.UnloadSignals) do
        Library:SafeCallback(Callback)
    end

    for _, Signal in ipairs(Library.Signals) do
        pcall(function()
            Signal:Disconnect()
        end)
    end

    local function DisconnectAll(Registry)
        for _, Element in pairs(Registry) do
            if type(Element) == "table" and type(Element.Connections) == "table" then
                for _, Connection in ipairs(Element.Connections) do
                    pcall(function()
                        Connection:Disconnect()
                    end)
                end
            end
        end
    end
    DisconnectAll(Library.Toggles)
    DisconnectAll(Library.Options)

    UserInputService.MouseIconEnabled = OriginalMouseIcon
    Library.Toggled = false
    ScreenGui:Destroy()
end

return Library
