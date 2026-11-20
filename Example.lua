--[[
    Snow UI Library - Example
    Shows every element and feature. Run it in an executor (or a LocalScript in Studio,
    see README "Using in Roblox Studio").
]]

local Repo = "https://raw.githubusercontent.com/smba9221/snow/main/"

local Library = loadstring(game:HttpGet(Repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(Repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(Repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

Library.NotifyOnError = true -- show callback errors as notifications
Library.ShowAllKeybinds = false -- only list active keybinds in the keybind panel

--// Loading screen (optional) \\--

local Loading = Library:CreateLoading({
    Title = "snow",
    Icon = "snowflake",
    TotalSteps = 3,
})
Loading:SetMessage("fetching assets")
task.wait(0.4)
Loading:SetCurrentStep(1)
Loading:SetMessage("building interface")

--// Window \\--

local Window = Library:CreateWindow({
    Title = "<u><accent>snow</accent></u>.lua",   -- <accent> follows the theme's accent colour
    Icon = "snowflake",                            -- any lucide.dev icon name, or an rbxassetid
    Footer = "quality at its finest",
    FooterRight = "lifetime, <accent>snow</accent>",
    Size = UDim2.fromOffset(780, 560),
    NotifySide = "Right",
    Search = true,                                 -- search bar under the title
    EnableSidebarResize = true,                    -- drag the sidebar edge (snaps to icon-only)
    ToggleKeybind = Enum.KeyCode.RightControl,
})

Window:AddSection("game")
local Tabs = {
    Main = Window:AddTab("main", "crosshair"),
    Visuals = Window:AddTab("visuals", "eye", "colours, images and viewports"),
    World = Window:AddTab("world", "globe", "dependency boxes and inputs"),
    Misc = Window:AddTab("misc", "pickaxe", "notifications, dialogs and more"),
}
Window:AddSection("settings")
Tabs.Settings = Window:AddTab("settings", "settings", "menu, themes and configs")

--// Main tab: sub tabs (pills along the top) \\--

local General = Tabs.Main:AddSubTab("general")
local Movement = Tabs.Main:AddSubTab("movement")
local Extras = Tabs.Main:AddSubTab("extras")

-- Left: a tabbox (several tabs in one box, accent underline under the active one)
local FeatureBox = General:AddLeftTabbox()
local Features = FeatureBox:AddTab("features", "rocket")
local Tuning = FeatureBox:AddTab("tuning", "sliders-horizontal")
local Priority = FeatureBox:AddTab("priority", "list-ordered")

Features:AddToggle("FeatureEnabled", {
    Text = "enabled",
    Default = true,
    Tooltip = "Master switch for this feature",
    Callback = function(Value)
        print("[snow] enabled ->", Value)
    end,
}):AddKeyPicker("FeatureKey", {
    Default = "Z",
    Mode = "Toggle",        -- Always / Toggle / Hold (right click the chip to change)
    Text = "feature",
    SyncToggleState = true, -- pressing Z flips the toggle
})

Features:AddToggle("AutoMode", { Text = "auto mode", Default = true })
Features:AddDropdown("AutoModeStyle", {
    Text = "auto mode style",
    Values = { "Aggressive", "Balanced", "Passive" },
    Default = "Aggressive",
})
Features:AddSlider("Delay", { Text = "delay", Min = 0, Max = 1, Default = 0.25, Rounding = 2, Suffix = "s" })
Features:AddSlider("Attempts", { Text = "attempts", Min = 1, Max = 5, Default = 2, Rounding = 0, Suffix = "x" })
Features:AddSlider("Cooldown", { Text = "cooldown", Min = 0, Max = 10, Default = 0, Suffix = "s" })
Features:AddDropdown("Conditions", {
    Text = "conditions",
    Values = { "hide when idle", "only in combat", "on screen" },
    Multi = true,
    Default = { "hide when idle" },
})
Features:AddDivider()
Features:AddDropdown("Method", { Text = "method", Values = { "Remote", "Direct", "Hybrid" }, Default = 1 })
Features:AddDropdown("Mode", { Text = "mode", Values = { "tool", "ability" }, Default = "tool" })
Features:AddDropdown("Preferred", { Text = "preferred slot", Values = { "primary", "secondary", "melee" }, Default = "primary" })
Features:AddDropdown("Target", {
    Text = "target",
    SpecialType = "Player",      -- auto-filled & kept in sync with the server's players
    ExcludeLocalPlayer = true,
    EnablePlayerImages = true,
    Searchable = true,
    AllowNull = true,
})

Tuning:AddSlider("Smoothness", { Text = "smoothness", Min = 0, Max = 100, Default = 35, Suffix = "%" })
Tuning:AddSlider("Range", {
    Text = "range",
    Min = 0,
    Max = 500,
    Default = 150,
    HideMax = false,                 -- show "150/500"
    Suffix = " studs",
})
Tuning:AddSlider("Custom", {
    Min = 0,
    Max = 3,
    Default = 1,
    FormatDisplayValue = function(_, Value)
        return ({ "off", "low", "medium", "high" })[Value + 1]
    end,
})

Priority:AddDropdown("PriorityOrder", {
    Text = "priority",
    Values = {
        "closest",
        "lowest health",
        Library:DropdownDivider("advanced"),
        "highest threat",
        "random",
    },
    Default = "closest",
    DisabledValues = { "random" },
})
Priority:AddLabel("random is disabled in this build", true)

-- Right: another tabbox
local ExtraBox = General:AddRightTabbox()
local Client = ExtraBox:AddTab("client", "orbit")
local Fake = ExtraBox:AddTab("fake pos", "ghost")

Client:AddLabel("client won't see changes")
local ClientEnabled = Client:AddToggle("ClientEnabled", { Text = "enabled", Default = true })

-- The "..." chip opens a small settings panel attached to the toggle
local ClientSettings = ClientEnabled:AddSettings({ Width = 210 })
ClientSettings:AddSlider("ClientStrength", { Text = "strength", Min = 0, Max = 100, Default = 50, Suffix = "%" })
ClientSettings:AddToggle("ClientSilent", { Text = "silent", Default = false })
ClientSettings:AddDropdown("ClientPreset", { Text = "preset", Values = { "Default", "Subtle", "Max" }, Default = 1 })

Client:AddToggle("HideHead", { Text = "hide head", Default = true })
Client:AddToggle("RapidBody", { Text = "rapid body" })
Client:AddDropdown("Pitch", { Text = "pitch", Values = { "None", "Up", "Down", "Jitter" }, Default = "None" })
Client:AddDropdown("Preset", { Text = "preset", Values = { "None", "Legit", "Rage" }, Default = "None" })
Client:AddDropdown("Yaw", { Text = "yaw", Values = { "Backwards", "Spin", "Jitter" }, Default = "Backwards" })
Client:AddSlider("YawSpeed", { Text = "yaw speed", Min = 0, Max = 100, Default = 100, Suffix = "%" })
Client:AddButton({
    Text = "custom yaw...",
    Func = function()
        Library:Notify("custom yaw clicked")
    end,
}):AddButton({
    Text = "custom pitch...",
    Func = function()
        Library:Notify("custom pitch clicked")
    end,
})
Client:AddToggle("Spinbot", { Text = "spinbot", Risky = true, Tooltip = "Risky toggles are shown in red" })

Fake:AddCheckbox("FakeEnabled", { Text = "enabled (checkbox)", Default = false })
Fake:AddInput("FakeOffset", { Text = "offset", Default = "0, 5, 0", Placeholder = "x, y, z" })

-- Movement sub tab: plain groupboxes
local Walk = Movement:AddLeftGroupbox("walking", "footprints")
Walk:AddToggle("WalkSpeedOn", { Text = "walk speed" }):AddKeyPicker("WalkSpeedKey", {
    Default = "LeftAlt",
    Mode = "Hold",
    Text = "walk speed",
    SyncToggleState = true,
})
Walk:AddSlider("WalkSpeed", { Text = "speed", Min = 16, Max = 200, Default = 16 })

local Jump = Movement:AddRightGroupbox({
    Name = "jumping",
    IconName = "arrow-big-up",
    Description = "groupboxes can have a description",
    PopOut = true, -- the arrow icon pops this box out into a floating window
})
Jump:AddToggle("InfiniteJump", { Text = "infinite jump" })
Jump:AddSlider("JumpPower", { Text = "power", Min = 50, Max = 300, Default = 50 })

local ExtrasBox = Extras:AddLeftGroupbox("collapsible", "chevrons-down-up")
ExtrasBox:AddLabel("click a groupbox header to collapse it", true)
ExtrasBox:AddToggle("ExtraA", { Text = "option a" })
ExtrasBox:AddToggle("ExtraB", { Text = "option b", Disabled = true, DisabledTooltip = "This one is locked" })

local Scroller = Extras:AddRightGroupbox({ Name = "max height", IconName = "scroll", MaxHeight = 140 })
for Index = 1, 10 do
    Scroller:AddToggle("ScrollToggle" .. Index, { Text = "scrolling toggle " .. Index })
end

--// Visuals tab \\--

local Esp = Tabs.Visuals:AddLeftGroupbox("esp", "scan-eye")
Esp:AddToggle("EspBoxes", { Text = "boxes", Default = true })
    :AddColorPicker("EspBoxColor", { Default = Color3.fromRGB(58, 155, 240), Title = "box colour" })
Esp:AddToggle("EspNames", { Text = "names" })
    :AddColorPicker("EspNameColor", { Default = Color3.new(1, 1, 1), Title = "name colour", Transparency = 0 })
Esp:AddCheckbox("EspHealth", { Text = "health bar" })
Esp:AddLabel("chams colour"):AddColorPicker("ChamsColor", { Default = Color3.fromRGB(240, 88, 142) })
Esp:AddDivider("tip")
Esp:AddLabel("right click a colour swatch to copy it, shift + right click to paste", true)

local Media = Tabs.Visuals:AddRightGroupbox("media", "image")
Media:AddImage("SnowImage", { Image = "snowflake", Color = Color3.fromRGB(58, 155, 240), Height = 70 })
Media:AddViewport("Avatar", {
    Object = game:GetService("Players").LocalPlayer.Character,
    Interactive = true, -- drag to rotate, scroll to zoom
    Height = 180,
})

--// World tab: dependency boxes, inputs \\--

local Deps = Tabs.World:AddLeftGroupbox("dependency boxes", "git-branch")
Deps:AddToggle("ShowAdvanced", { Text = "show advanced" })
local Advanced = Deps:AddDependencyBox()
Advanced:AddSlider("AdvancedValue", { Text = "advanced value", Min = 0, Max = 10, Default = 5 })
Advanced:AddDropdown("AdvancedMode", { Text = "mode", Values = { "simple", "expert" }, Default = "simple" })
local Expert = Advanced:AddDependencyBox()
Expert:AddLabel("only visible in expert mode")
Expert:SetupDependencies({ { Options.AdvancedMode, "expert" } })
Advanced:SetupDependencies({ { Toggles.ShowAdvanced, true } })

local Inputs = Tabs.World:AddRightGroupbox("inputs", "text-cursor-input")
Inputs:AddInput("Username", {
    Text = "username",
    Placeholder = "type here...",
    Finished = true, -- only fires on Enter
    Callback = function(Value)
        Library:Notify({ Title = "input", Description = "you typed " .. Value, Icon = "keyboard" })
    end,
})
Inputs:AddInput("Amount", { Text = "amount", Numeric = true, Default = "10", MaxLength = 5 })
Inputs:AddInput("FullWidth", { Placeholder = "an input without a label is full width" })

--// Misc tab: notifications, dialogs, buttons \\--

local Notifs = Tabs.Misc:AddLeftGroupbox("notifications", "bell")
Notifs:AddButton({
    Text = "simple",
    Icon = "bell",
    Func = function()
        Library:Notify("This is a simple notification", 3)
    end,
})
Notifs:AddButton({
    Text = "with title & icon",
    Variant = "Secondary",
    Func = function()
        Library:Notify({ Title = "snow", Description = "Notifications slide in from the side.", Icon = "info", Time = 4 })
    end,
})
Notifs:AddButton({
    Text = "progress",
    Variant = "Secondary",
    Func = function()
        local Notification = Library:Notify({
            Title = "downloading",
            Description = "step 0 / 5",
            Icon = "download",
            Steps = 5,
            Persist = true,
        })
        for Step = 1, 5 do
            task.wait(0.5)
            Notification:ChangeStep(Step)
            Notification:ChangeDescription(("step %d / 5"):format(Step))
        end
        Notification:ChangeTitle("done")
        task.wait(1)
        Notification:Destroy()
    end,
})

local Dialogs = Tabs.Misc:AddRightGroupbox("dialogs & buttons", "message-square")
Dialogs:AddButton({
    Text = "open dialog",
    Icon = "message-square",
    Func = function()
        local Dialog = Window:AddDialog("ConfirmDialog", {
            Title = "are you sure?",
            Description = "Dialogs can hold elements and footer buttons.",
            Icon = "triangle-alert",
            OutsideClickDismiss = true,
            FooterButtons = {
                Cancel = { Title = "cancel", Variant = "Ghost", Order = 1 },
                Confirm = {
                    Title = "confirm",
                    Variant = "Primary",
                    Order = 2,
                    WaitTime = 2,
                    Callback = function()
                        Library:Notify({ Description = "confirmed!", Icon = "check" })
                    end,
                },
            },
        })
        Dialog:AddToggle("DialogDontAsk", { Text = "don't ask again" })
    end,
})
Dialogs:AddButton({
    Text = "double click me",
    DoubleClick = true,
    Risky = true,
    Func = function()
        Library:Notify("double clicked")
    end,
})
Dialogs:AddButton({ Text = "bound to a key", Func = function(FromKey)
    Library:Notify(FromKey and "pressed via keybind" or "clicked")
end }):AddKeyPicker("ButtonKey", { Default = "B", Text = "button" })

--// Settings tab \\--

local Menu = Tabs.Settings:AddLeftGroupbox("menu", "wrench")
Menu:AddToggle("KeybindMenuOpen", {
    Text = "keybind list",
    Default = true,
    Callback = function(Value)
        Library.KeybindFrame.Visible = Value
    end,
})
Menu:AddToggle("ShowWatermark", {
    Text = "watermark",
    Default = true,
    Callback = function(Value)
        Library:SetWatermarkVisibility(Value)
    end,
})
Menu:AddToggle("CustomCursor", {
    Text = "custom cursor",
    Default = false,
    Callback = function(Value)
        Library.ShowCustomCursor = Value
    end,
})
Menu:AddDropdown("NotificationSide", {
    Text = "notify side",
    Values = { "Left", "Right" },
    Default = "Right",
    Callback = function(Value)
        Library:SetNotifySide(Value)
    end,
})
Menu:AddDropdown("DPIDropdown", {
    Text = "ui scale",
    Values = { "75%", "90%", "100%", "110%", "125%" },
    Default = "100%",
    Callback = function(Value)
        Library:SetDPIScale(tonumber((Value:gsub("%%", ""))) / 100)
    end,
})
Menu:AddLabel("menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightControl", NoUI = true, Text = "menu" })
Menu:AddButton({
    Text = "unload",
    Risky = true,
    DoubleClick = true,
    Func = function()
        Library:Unload()
    end,
})

Library.ToggleKeybind = Options.MenuKeybind -- rebindable menu key
Library.KeybindFrame.Visible = true

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("snow")
SaveManager:SetFolder("snow/example")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

--// Watermark with live FPS \\--

Library:SetWatermarkVisibility(true)
local RunService = game:GetService("RunService")
local Frames, Last = 0, os.clock()
local WatermarkConnection = RunService.RenderStepped:Connect(function()
    Frames += 1
    local Now = os.clock()
    if Now - Last >= 1 then
        Library:SetWatermark(("<accent>snow</accent>.lua | %d fps | %s"):format(Frames, os.date("%H:%M:%S")):gsub(
            "<accent>(.-)</accent>",
            '<font color="#' .. Library.Scheme.AccentColor:ToHex() .. '">%1</font>'
        ))
        Frames, Last = 0, Now
    end
end)

Library:OnUnload(function()
    WatermarkConnection:Disconnect()
    print("[snow] unloaded")
end)

--// Finish loading \\--

Loading:SetCurrentStep(3)
Loading:SetMessage("ready")
task.wait(0.3)
Loading:Continue() -- fades the loader out and shows the window
