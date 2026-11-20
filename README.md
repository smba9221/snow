# ❄ Snow UI Library

A smooth, themeable Roblox UI library with a clean sidebar layout, sub-tab pills, tabbed groupboxes, built-in [Lucide](https://lucide.dev) icons, and animations throughout.

The API follows the **Obsidian / LinoriaLib** style (`Library.Toggles`, `Library.Options`, `AddLeftGroupbox`, `AddToggle(...)`, `:AddKeyPicker(...)`, `ThemeManager`, `SaveManager`). Most Obsidian scripts port over by changing the loadstring URL.

- Sidebar with **sections** and icon tabs, which can be resized and snap to an icon-only compact mode
- **Sub tabs** (pill bar with an animated accent underline) and **tabboxes** (several tabs in one groupbox)
- Toggles (switch or checkbox), buttons and sub-buttons, inputs, sliders, dropdowns (single, multi, searchable, player/team lists), key pickers, colour pickers, labels, dividers, images, videos, viewports, UI passthrough
- A `...` settings panel you can attach to any toggle, label, button, input or dropdown
- Dependency boxes, including nested ones
- Notifications (with progress steps), dialogs, a loading screen, a watermark, a keybind list, and draggable mobile buttons
- Theming through a live colour registry, 8 built-in themes, and custom themes saved to disk
- Config saving and loading with autoload
- DPI scaling, a custom cursor, search, and groupboxes you can pop out into floating windows

---

## Contents

1. [Installation](#installation)
2. [Quick start](#quick-start)
3. [Window](#window)
4. [Tabs, sections & sub tabs](#tabs-sections--sub-tabs)
5. [Groupboxes & tabboxes](#groupboxes--tabboxes)
6. [Elements](#elements)
   - [Label](#label) · [Button](#button) · [Toggle / Checkbox](#toggle--checkbox) · [Input](#input) · [Slider](#slider) · [Dropdown](#dropdown) · [Divider](#divider) · [Image](#image) · [Video](#video) · [Viewport](#viewport) · [UI passthrough](#ui-passthrough)
7. [Addons: KeyPicker, ColorPicker, Settings](#addons)
8. [Dependency boxes](#dependency-boxes)
9. [Notifications](#notifications)
10. [Dialogs](#dialogs)
11. [Loading screen](#loading-screen)
12. [Watermark, keybind list, draggable buttons](#watermark-keybind-list-draggable-buttons)
13. [Icons (Lucide)](#icons-lucide)
14. [Theming & ThemeManager](#theming--thememanager)
15. [SaveManager](#savemanager)
16. [Library reference](#library-reference)
17. [Differences from Obsidian](#differences-from-obsidian)

---

## Installation

### Executor

```lua
local Repo = "https://raw.githubusercontent.com/smba9221/snow/main/"

local Library      = loadstring(game:HttpGet(Repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(Repo .. "addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet(Repo .. "addons/SaveManager.lua"))()
```

> The repository must be **public** for `game:HttpGet` to read the raw files.

### Using in Roblox Studio

Put `Library.lua` in a `ModuleScript` (for example `ReplicatedStorage.Snow`) and require it from a `LocalScript`. Studio can't `loadstring` the icon pack, so install [lucide-roblox](https://github.com/latte-soft/lucide-roblox) as a ModuleScript and pass it in:

```lua
local Library = require(game.ReplicatedStorage.Snow)
Library:SetIconModule(require(game.ReplicatedStorage.Lucide))
```

Without an icon module everything still works; icons are just hidden. SaveManager and ThemeManager files need executor file functions (`writefile`, `readfile`, …). Without them they run, but nothing is saved.

---

## Quick start

```lua
local Window = Library:CreateWindow({
    Title = "<u><accent>snow</accent></u>.lua",
    Icon = "snowflake",
    Footer = "quality at its finest",
    FooterRight = "lifetime, <accent>snow</accent>",
})

Window:AddSection("game")
local Main = Window:AddTab("main", "crosshair")

local Box = Main:AddLeftGroupbox("features", "rocket")

Box:AddToggle("Enabled", {
    Text = "enabled",
    Default = true,
    Callback = function(Value) print("enabled:", Value) end,
}):AddKeyPicker("EnabledKey", { Default = "Z", Mode = "Toggle", SyncToggleState = true })

Box:AddSlider("Speed", { Text = "speed", Min = 0, Max = 100, Default = 50, Suffix = "%" })

-- read values anywhere
print(Library.Toggles.Enabled.Value, Library.Options.Speed.Value)

-- or listen
Library.Options.Speed:OnChanged(function(Value) print("speed:", Value) end)
```

See [`Example.lua`](Example.lua) for a script that uses every feature.

---

## Window

```lua
local Window = Library:CreateWindow({ ... })
```

| Option | Type | Default | Description |
|---|---|---|---|
| `Title` | string | `"Snow"` | Rich text. `<accent>text</accent>` uses the theme's accent colour |
| `Icon` | string / number | – | Lucide name or asset id, shown after the title |
| `IconSize` | UDim2 | `22×22` | |
| `Footer` | string | `""` | Bottom-left footer text (rich text, `<accent>` supported) |
| `FooterRight` | string | – | Bottom-right footer text |
| `Size` | UDim2 | `720×500` | Scale components are converted to pixels |
| `Position` | UDim2 | centred | Used when `Center = false` |
| `Center` | boolean | `true` | |
| `AutoShow` | boolean | `true` | Waits for `Loading:Continue()` if a loading screen is open |
| `Resizable` | boolean | `true` | Grip in the bottom-right corner |
| `ToggleKeybind` | KeyCode / KeyPicker | `RightControl` | Also settable through `Library.ToggleKeybind` |
| `NotifySide` | `"Left"` / `"Right"` | `"Right"` | |
| `Search` | boolean | `false` | Search box under the title that filters elements by text |
| `SidebarWidth` | number | `190` | |
| `EnableSidebarResize` | boolean | `false` | Drag the sidebar edge |
| `MinSidebarWidth` / `MaxSidebarWidth` | number | `56` / `320` | |
| `SidebarCollapseThreshold` | number | `110` | Below this width the sidebar shows icons only |
| `SidebarCompactWidth` | number | `MinSidebarWidth` | Width used by `SetCompact(true)` |
| `DisableCompactingSnap` | boolean | `false` | Don't snap to compact width after dragging |
| `CornerRadius` | number | `6` | |
| `Font` | Enum.Font / Font | Gotham | |
| `DPIScale` | number | `1` | |
| `ShowCustomCursor` | boolean | `false` | |
| `UnlockMouseWhileOpen` | boolean | `true` | Frees the mouse in first person while the menu is open |
| `ShowMobileButtons` | boolean | `true` | On touch devices, adds a draggable "Toggle" button |
| `Animations` | table | all `true` | `{ ToggleWindow, TabSwitch, Groupbox, Dropdown, KeyPicker }` |
| `TabTransitionTime` | number | `0.25` | |
| `TabSwipeOffset` | number | `14` | Pixels the page slides during a tab switch |
| `TabSwipeFrom` | string | `"bottom"` | `"left"`, `"right"`, `"top"`, `"bottom"` or `"auto"` |
| `AlwaysOnTop` | boolean | `false` | |

**Methods**

| Method | |
|---|---|
| `Window:AddTab(Name, Icon?, Description?, Order?)` / `AddTab({ Name, Icon, Description, Tooltip, Order })` | Adds a sidebar tab |
| `Window:AddSection(Name)` | Muted heading in the sidebar (like "game" / "settings") |
| `Window:AddKeyTab(Name, Icon?)` | Tab with `Tab:AddKeyBox(function(Key) end)` for key systems |
| `Window:AddCustomTab(Name, Icon?)` | Empty tab; parent your own instances to `Tab.Container` |
| `Window:AddDialog(Idx, Info)` | See [Dialogs](#dialogs) |
| `Window:ChangeTitle(Text)` / `SetFooter(Text)` / `SetFooterRight(Text)` | |
| `Window:ShowTabInfo(Title, Description?)` / `HideTabInfo()` | Overrides the header text shown for tabs without sub tabs |
| `Window:SetBackgroundImage(Image)` / `SetBackgroundImageTransparency(n)` | |
| `Window:SetCornerRadius(n)` | |
| `Window:SetSidebarWidth(n)` / `GetSidebarWidth()` / `SetCompact(bool)` / `IsSidebarCompacted()` | |
| `Window:SetAnimations(Animations?, TransitionTime?, SwipeOffset?, SwipeFrom?)` | |
| `Window:SetAlwaysOnTop(bool)` | |
| `Window:Toggle(Visible?)` | Same as `Library:Toggle` |

---

## Tabs, sections & sub tabs

```lua
Window:AddSection("game")
local Main = Window:AddTab("main", "crosshair")
local Visuals = Window:AddTab("visuals", "eye", "description shown in the header")
Window:AddSection("settings")
local Settings = Window:AddTab("settings", "settings")
```

A tab has two columns. Add boxes directly to it:

```lua
Main:AddLeftGroupbox("name", "icon")
Main:AddRightGroupbox("name", "icon")
Main:AddGroupbox({ Side = "Left", Name = "name", IconName = "icon" })
Main:AddLeftTabbox() / Main:AddRightTabbox() / Main:AddTabbox({ Side = "Right" })
Main:AddDependencyGroupbox({ Side = "Left", Name = "..." })
```

**Sub tabs** show as pills along the top of the content area (the `aim / rage / weapons` look). Each sub tab has its own two columns and the same methods as a tab:

```lua
local General = Main:AddSubTab("general")
local Movement = Main:AddSubTab("movement", "footprints") -- optional icon
General:AddLeftGroupbox("box", "rocket")
Movement:Show()
```

Tab methods: `Show()`, `SetVisible(bool)`, `SetOrder(n)`, `SetTooltip(text)`, `SetDescription(text)`, `AddSubTab(name, icon?)`, `Destroy()`.
`Library.Tabs[name]` holds every tab, and `Tab.SubTabs[name]` holds its sub tabs.

---

## Groupboxes & tabboxes

### Groupbox

```lua
local Box = Tab:AddLeftGroupbox("features", "rocket")
-- or
local Box = Tab:AddGroupbox({
    Side = "Right",              -- "Left" | "Right" | 1 | 2
    Name = "jumping",
    IconName = "arrow-big-up",   -- lucide icon, drawn in the accent colour
    Description = "subtitle",    -- optional second line
    Collapsed = false,           -- start collapsed
    DisableCollapsing = false,   -- clicking the header collapses by default
    MaxHeight = 200,             -- scroll inside the box past this height
    PopOut = true,               -- adds a button that pops the box into a floating window
    PopOutWidth = 260,
    MaxPopOutHeight = 400,
    Visible = true,
})
```

The groupbox title gets an accent underline. Methods: `SetVisible`, `Show`, `Hide`, `SetTitle`, `SetDescription`, `SetCollapsed`, `ToggleCollapsed`, `SetMaxHeight`, `SetPoppedOut(bool, Position?)`, `TogglePoppedOut`, `SetMaxPopOutHeight`, `SetPopOutWidth`, `AddTabbox`, `AddDependencyBox`, `Destroy`, and every element method below.

### Tabbox

A groupbox whose header holds several tabs. The active tab gets an animated accent underline (the `ragebot / settings / priority` look).

```lua
local Box = Tab:AddLeftTabbox()           -- or AddRightTabbox / AddTabbox({ Side, IconName })
local Features = Box:AddTab("features", "rocket")    -- the icon shows while this tab is active
local Tuning   = Box:AddTab("tuning", "sliders-horizontal")

Features:AddToggle("A", { Text = "enabled" })
Tuning:Show()
```

Tabbox methods: `AddTab(name, icon?, maxHeight?)`, `SelectTab(tab)`, `SetMaxHeight`, `SetVisible`, `Show`, `Hide`, `Destroy`. Groupboxes can contain tabboxes too: `Groupbox:AddTabbox()`.

---

## Elements

Every element is created on a groupbox, tabbox tab, dependency box, settings panel or dialog. Elements with an `Idx` are stored in:

- `Library.Toggles[Idx]`: toggles and checkboxes
- `Library.Options[Idx]`: inputs, sliders, dropdowns, key pickers, colour pickers, images, videos, viewports, passthroughs
- `Library.Labels[Idx]` and `Library.Buttons[Idx or Text]`

Common to all: `Visible`, `Tooltip`, and `DisabledTooltip` options, plus the `:SetVisible(bool)` and `:Destroy()` methods. Value elements also have `Callback` / `Changed` options and the `:SetValue(v)`, `:OnChanged(fn)`, `:SetDisabled(bool)` and `:SetText(text)` methods.

### Label

```lua
Box:AddLabel("plain text")
Box:AddLabel("a long paragraph that wraps onto several lines", true) -- DoesWrap (muted)
Box:AddLabel("MyLabel", { Text = "with id", DoesWrap = false, Size = 14 })
Box:AddLabel("chams"):AddColorPicker("ChamsColor", { Default = Color3.new(1, 0, 0) })
Box:AddLabel("menu bind"):AddKeyPicker("MenuKey", { Default = "RightShift", NoUI = true })
```

Methods: `SetText`, `SetVisible`, `AddKeyPicker`, `AddColorPicker`, `AddSettings`, `Destroy`.

### Button

```lua
local Button = Box:AddButton("click me", function() end)

local Button = Box:AddButton({
    Text = "save",
    Icon = "save",              -- lucide icon before the text
    Variant = "Primary",        -- "Primary" (accent, default) | "Secondary" (subtle)
    Func = function(FromKeyPicker) end,
    DoubleClick = false,        -- asks "Are you sure?" first
    Risky = false,              -- red button
    Disabled = false,
    Tooltip = "...",
})

-- side-by-side sub buttons (they share the row equally)
Button:AddButton({ Text = "second", Func = function() end })

-- trigger from a key ("Press" mode). Func receives FromKeyPicker = true
Button:AddKeyPicker("SaveKey", { Default = "K" })
```

Methods: `SetText`, `SetIcon`, `SetDisabled`, `SetRisky`, `SetVisible`, `AddButton`, `AddKeyPicker`, `AddSettings`, `Destroy`.

### Toggle / Checkbox

```lua
Box:AddToggle("Fly", {
    Text = "fly",
    Default = false,
    Risky = false,          -- red text
    Disabled = false,
    Tooltip = "...",
    DisabledTooltip = "...",
    Callback = function(Value) end,
})

Box:AddCheckbox("Box", { Text = "checkbox style" })
Library.ForceCheckbox = true -- make every AddToggle a checkbox
```

Toggles render as a pill switch on the right. Addons appear just left of the switch: `:AddKeyPicker`, `:AddColorPicker`, `:AddSettings`. These calls chain (each returns the toggle, except `AddSettings`, which returns the panel).
Methods: `SetValue`, `OnChanged`, `SetText`, `SetDisabled`, `SetRisky`, `SetVisible`, `Destroy`.

### Input

```lua
Box:AddInput("Name", {
    Text = "name",            -- label on the left; omit for a full-width box
    Default = "",
    Placeholder = "type...",
    Finished = false,         -- true: only fires when Enter is pressed
    Numeric = false,
    MaxLength = nil,
    AllowEmpty = true,
    EmptyReset = "---",       -- value used when emptied and AllowEmpty = false
    ClearTextOnFocus = false,
    ClearTextOnBlur = false,
    VerifyValue = function(Text) return true end, -- return false to reject
    Callback = function(Value) end,
})
```

Methods: `SetValue`, `OnChanged`, `SetText`, `SetPlaceholder`, `SetDisabled`, `SetVisible`, `AddSettings`, `Destroy`.

### Slider

The value is drawn inside the bar (`hide: 0.25s`). Right-click the bar to type a value.

```lua
Box:AddSlider("Delay", {
    Text = "delay",
    Min = 0, Max = 1, Default = 0.25,
    Rounding = 2,             -- decimal places
    Prefix = "", Suffix = "s",
    HideMax = true,           -- false shows "0.25s/1s"
    AllowRightClickInput = true,
    FormatDisplayValue = function(Slider, Value) return "custom " .. Value end,
    Callback = function(Value) end,
})
```

Methods: `SetValue`, `SetMin`, `SetMax`, `SetText`, `SetPrefix`, `SetSuffix`, `OnChanged`, `SetDisabled`, `SetVisible`, `Destroy`.

### Dropdown

```lua
Box:AddDropdown("Mode", {
    Text = "mode",                    -- omit for a full-width box
    Values = { "a", "b", Library:DropdownDivider("more"), "c" },
    Default = "a",                    -- a value, or an index (1)
    Multi = false,                    -- Value becomes { [value] = true }
    AllowNull = false,                -- clicking the selected value clears it
    Searchable = false,
    MaxVisibleDropdownItems = 8,
    AutoWidth = false,                -- list grows to fit the longest value
    DisabledValues = { "c" },
    ValueImages = { a = "star" },     -- lucide / asset per value
    FormatValue = function(v) return tostring(v) end,        -- display + list
    FormatDisplayValue = function(v) return v end,           -- the box only
    FormatListValue = function(v) return v end,              -- the list only
    SpecialType = nil,                -- "Player" | "Team" (auto-filled, kept in sync)
    ExcludeLocalPlayer = false,
    EnablePlayerImages = false,       -- avatar headshots for SpecialType = "Player"
    Callback = function(Value) end,
})
```

Multi `Default` / `SetValue` accept `{ "a", "b" }` or `{ a = true, b = true }`.
Methods: `SetValue`, `SetValues`, `AddValues`, `SetDisabledValues`, `AddDisabledValues`, `SetValueImages`, `AddValueImages`, `GetActiveValues(ReturnCount?)`, `Open`, `Close`, `OnChanged`, `SetText`, `SetDisabled`, `SetVisible`, `AddSettings`, `Destroy`.

### Divider

```lua
Box:AddDivider()
Box:AddDivider("with text")
```

### Image

```lua
Box:AddImage("Logo", {
    Image = "snowflake",      -- lucide name, rbxassetid://, or a number
    Color = Color3.new(1, 1, 1),
    Transparency = 0,
    BackgroundTransparency = 1,
    ScaleType = Enum.ScaleType.Fit,
    RectOffset = nil, RectSize = nil,
    Height = 200,
})
```

Methods: `SetImage`, `SetColor`, `SetTransparency`, `SetRectOffset`, `SetRectSize`, `SetScaleType`, `SetHeight`, `SetVisible`, `Destroy`.

### Video

```lua
Box:AddVideo("Clip", { Video = "rbxassetid://...", Looped = true, Playing = true, Volume = 1, Height = 200 })
```

Methods: `Play`, `Pause`, `SetPlaying`, `SetVideo`, `SetLooped`, `SetVolume`, `SetHeight`, `SetVisible`, `Destroy`.

### Viewport

```lua
Box:AddViewport("Avatar", {
    Object = LocalPlayer.Character,   -- BasePart or Model
    Clone = true,                     -- render a clone (default)
    AutoFocus = true,                 -- frame the object
    Interactive = true,               -- drag to rotate, scroll to zoom
    Camera = nil,                     -- custom Camera
    Height = 200,
})
```

Methods: `SetObject(obj, clone?)`, `Focus`, `Rotate(yaw, pitch)`, `Zoom(delta)`, `LookAt(Vector3)`, `SetDistance`, `GetDistance`, `SetFieldOfView`, `SetCamera`, `SetCameraCFrame`, `GetCameraCFrame`, `SetInteractive`, `SetHeight`, `SetVisible`, `Destroy`.

### UI passthrough

Embeds any GuiObject you made yourself:

```lua
Box:AddUIPassthrough("Custom", { Instance = MyFrame, Height = 40 })
```

Methods: `SetInstance`, `SetHeight`, `SetVisible`, `Destroy`.

---

## Addons

### KeyPicker

Attach to a toggle, label or button. Left-click the chip, then press a key or mouse button. **Escape** unbinds it. Right-click the chip to switch modes.

```lua
Toggle:AddKeyPicker("FlyKey", {
    Default = "F",                 -- KeyCode name, "MB1"/"MB2"/"MB3", or "None"
    DefaultModifiers = { "LeftShift" }, -- optional, so the bind is Shift+F
    Mode = "Toggle",               -- "Always" | "Toggle" | "Hold" | "Press"
    Modes = { "Always", "Toggle", "Hold" },
    Text = "fly",                  -- name in the keybind list
    SyncToggleState = false,       -- key state <-> toggle value
    NoUI = false,                  -- hide from the keybind list
    Blacklisted = { "W", "A", "S", "D" },
    Whitelisted = nil,
    Callback = function(State) end,        -- state changed
    ChangedCallback = function(Key) end,   -- the bound key changed
    Clicked = function() end,              -- key pressed
})
```

To bind a modifier with a key, hold the modifier while pressing the key. A modifier pressed and released on its own is bound by itself.
Methods: `GetState()`, `SetValue({ Key, Mode, Modifiers? })`, `OnChanged`, `OnClick`, `DoClick`, `SetText`, `Update`, `SetMenuVisibility`, `Destroy`.

### ColorPicker

Attach to a toggle or label. Click the swatch for the picker (saturation/value square, hue bar, optional alpha bar, hex and RGB boxes). Right-click copies the colour; **Shift + right-click** pastes it.

```lua
Toggle:AddColorPicker("BoxColor", {
    Default = Color3.fromRGB(58, 155, 240),
    Title = "box colour",
    Transparency = 0,          -- set a number to enable the alpha bar
    Callback = function(Color, Transparency) end,
})
```

Methods: `SetValueRGB(Color3, Transparency?)`, `SetValue({ h, s, v }, Transparency?)`, `OnChanged`, `Destroy`. Fields: `Value`, `Transparency`.

### Settings (`...`)

A small floating panel attached to an element. It accepts every element method.

```lua
local Panel = Toggle:AddSettings({ Width = 220 })
Panel:AddSlider("Strength", { Text = "strength", Min = 0, Max = 100, Default = 50 })
Panel:AddDropdown("Preset", { Text = "preset", Values = { "a", "b" }, Default = 1 })
```

Methods: `Open`, `Close`, `Toggle`, `SetWidth`, `Destroy`.

---

## Dependency boxes

Elements inside a dependency box only show while every dependency matches.

```lua
local Advanced = Box:AddDependencyBox()
Advanced:AddSlider("Value", { Text = "value", Min = 0, Max = 10 })

Advanced:SetupDependencies({
    { Library.Toggles.ShowAdvanced, true },       -- toggle must be on
    { Library.Options.Mode, "expert" },           -- dropdown value
    { Library.Options.Amount, function(v) return tonumber(v) and tonumber(v) > 5 end }, -- predicate
})
```

Boxes can nest. A nested box is hidden whenever its parent is hidden. For multi dropdowns, the dependency checks that the value is selected. `Tab:AddDependencyGroupbox(Info)` does the same for an entire groupbox.

---

## Notifications

```lua
Library:Notify("text", 4)                               -- description, time
Library:Notify("text", 4, 4590657391, 2)                -- + sound id, volume

local N = Library:Notify({
    Title = "title",
    Description = "description",
    Icon = "info",                 -- lucide or asset (or BigIcon for a 24px icon)
    IconColor = Color3.new(1, 1, 1),
    TitleColor = nil, DescriptionColor = nil,
    Time = 4,                      -- seconds, or an Instance (closes when it's destroyed)
    Persist = false,               -- stay until :Destroy()
    Steps = nil,                   -- progress bar with N steps
    SoundId = nil, Volume = 3,
    Callback = function(N) end,    -- runs when dismissed
})
N:ChangeTitle("...")
N:ChangeDescription("...")
N:ChangeStep(3)
N:Destroy()
```

`Library:SetNotifySide("Left" | "Right")`

---

## Dialogs

```lua
local Dialog = Window:AddDialog("Confirm", {
    Title = "are you sure?",
    Description = "this can't be undone",
    Icon = "triangle-alert",
    OutsideClickDismiss = true,
    AutoDismiss = true,            -- close after a footer button runs
    FooterButtons = {
        Cancel  = { Title = "cancel",  Variant = "Ghost",   Order = 1 },
        Confirm = { Title = "confirm", Variant = "Primary", Order = 2, WaitTime = 3,
                    Callback = function(Dialog) end },
    },
})
Dialog:AddToggle("DontAsk", { Text = "don't ask again" }) -- dialogs hold elements too
```

Variants: `Primary`, `Secondary`, `Destructive`, `Ghost`. `WaitTime` disables the button with a countdown.
Methods: `SetTitle`, `SetDescription`, `AddFooterButton(idx, info)`, `RemoveFooterButton`, `SetButtonDisabled`, `SetButtonOrder`, `Dismiss`.

---

## Loading screen

```lua
local Loading = Library:CreateLoading({
    Title = "snow",
    Icon = "snowflake",
    LoadingIcon = "loader-circle",
    LoadingIconColor = nil,
    LoadingIconTweenTime = 1,  -- seconds per spin
    TotalSteps = 3,
    WindowWidth = 360,
})
Loading:SetMessage("loading assets")
Loading:SetDescription("this may take a second")
Loading:SetCurrentStep(1)

-- on failure:
Loading:ShowErrorPage("couldn't load", { { Title = "retry", Callback = function() end } })

-- when done (shows the window if it was created with AutoShow):
Loading:Continue()
```

---

## Watermark, keybind list, draggable buttons

```lua
Library:SetWatermark("snow.lua | 60 fps")      -- rich text
Library:SetWatermarkVisibility(true)

Library.KeybindFrame.Visible = true            -- "[Z] feature (Toggle)" list
Library.ShowAllKeybinds = true                 -- also list inactive binds (muted)

local Btn = Library:AddDraggableButton("Toggle", function() Library:Toggle() end)
local Lbl = Library:AddDraggableLabel("status", "activity")
local Img = Library:AddDraggableImageButton("snowflake", 20, function() end)
```

All three panels can be dragged. Clicking an entry in the keybind list flips a `Toggle`-mode bind.

---

## Icons (Lucide)

Anywhere an icon is accepted you can pass a [lucide.dev](https://lucide.dev/icons) icon name (`"snowflake"`, `"crosshair"`, `"eye"`, …), an `rbxassetid://` string, an asset id number, or a URL.

Icons come from [latte-soft/lucide-roblox](https://github.com/latte-soft/lucide-roblox), which is loaded automatically in executors. Some icon names are newer than the bundled Lucide version. Those are hidden, not errors.

```lua
Library:GetIcon("snowflake")              -- { Url, ImageRectOffset, ImageRectSize, ... } or nil
Library:CreateIcon("snowflake", { Size = UDim2.fromOffset(16, 16), Parent = Frame })
Library:ApplyIcon(SomeImageLabel, "eye")
Library:SetIconModule(require(path.to.Lucide))   -- use your own copy
```

---

## Theming & ThemeManager

Colours live in `Library.Scheme`:

| Key | Used for |
|---|---|
| `BackgroundColor` | window background |
| `SidebarColor` | sidebar and footer |
| `MainColor` | groupboxes, popups, notifications |
| `ElementColor` | input boxes, dropdown boxes, slider tracks, active tab |
| `OutlineColor` | strokes and dividers |
| `AccentColor` | switches, slider fills, buttons, underlines, icons |
| `FontColor` | text |
| `MutedColor` | secondary text, inactive tabs |
| `RedColor` | risky elements |
| `DarkColor`, `WhiteColor` | overlays, knobs |
| `Font` | `Font` object |

Change them, then refresh:

```lua
Library.Scheme.AccentColor = Color3.fromRGB(240, 88, 142)
Library:UpdateColorsUsingRegistry()
Library:SetFont(Enum.Font.Montserrat)
```

Your own instances can follow the theme too:

```lua
Library:AddToRegistry(MyFrame, { BackgroundColor3 = "MainColor", BorderColor3 = function() return Library.Scheme.AccentColor end })
```

**ThemeManager** adds a groupbox with a colour picker per key, a font dropdown, 8 built-in themes (Snow, Frost, Rose, Mint, Amber, Violet, Mono, Light) and custom theme files:

```lua
ThemeManager:SetLibrary(Library)
ThemeManager:SetFolder("MyScript")            -- MyScript/themes/*.json
ThemeManager:ApplyToTab(Tabs.Settings)         -- or :ApplyToGroupbox(groupbox)
-- ThemeManager:ApplyTheme("Rose")  ThemeManager:SaveCustomTheme("mine")  ThemeManager:LoadDefault()
```

---

## SaveManager

```lua
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()                 -- don't save theme colour pickers
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
SaveManager:SetFolder("MyScript/some-game")       -- MyScript/some-game/settings/*.json
SaveManager:SetSubFolder("place-123")             -- optional
SaveManager:BuildConfigSection(Tabs.Settings)     -- name box, create/load/overwrite/delete, autoload
SaveManager:LoadAutoloadConfig()
```

API: `Save(name)`, `Load(name)`, `Delete(name)`, `RefreshConfigList()`, `SaveAutoloadConfig(name)`, `GetAutoloadConfig()`, `DeleteAutoLoadConfig()`, `SetLoadingOrder({...})`. Saved types: Toggle, Input, Slider, Dropdown, ColorPicker, KeyPicker. Custom parsers go in `SaveManager.Parser[Type] = { Save = fn, Load = fn }`.

---

## Library reference

**Properties**

| Property | Default | |
|---|---|---|
| `Library.Toggles` / `Library.Options` / `Library.Labels` / `Library.Buttons` | | Element registries |
| `Library.Tabs` | | Tabs by name |
| `Library.Toggled` | | Is the window open |
| `Library.ToggleKeybind` | `RightControl` | KeyCode, KeyCode name, or a KeyPicker (`Options.MenuKeybind`) |
| `Library.ForceCheckbox` | `false` | |
| `Library.ShowCustomCursor` | `false` | |
| `Library.NotifyOnError` | `false` | Show callback errors as notifications |
| `Library.ShowAllKeybinds` | `false` | |
| `Library.Animations` | all `true` | `ToggleWindow`, `TabSwitch`, `Groupbox`, `Dropdown`, `KeyPicker` |
| `Library.TweenInfo` | 0.2s Quint | Default tween |
| `Library.MinSize` | `560×380` | Minimum window size when resizing |
| `Library.KeybindFrame`, `Library.WatermarkFrame`, `Library.ScreenGui` | | Instances |
| `Library.IsMobile` | | |

**Functions**

| Function | |
|---|---|
| `Library:CreateWindow(Info)` | |
| `Library:CreateLoading(Info)` | |
| `Library:Toggle(Visible?)` | |
| `Library:Notify(...)` | |
| `Library:SetWatermark(Text)` / `SetWatermarkVisibility(bool)` | |
| `Library:SetNotifySide(side)` | |
| `Library:SetDPIScale(n)` | `1` = 100% (also accepts `75`, `125`, …) |
| `Library:SetFont(Font)` | |
| `Library:UpdateColorsUsingRegistry()` / `AddToRegistry(inst, props)` / `RemoveFromRegistry(inst)` | |
| `Library:UpdateDependencyBoxes()` | |
| `Library:UpdateSearch(text)` | |
| `Library:GetIcon(name)` / `GetCustomIcon(icon)` / `CreateIcon(icon, props)` / `ApplyIcon(img, icon)` / `SetIconModule(m)` | |
| `Library:AddTooltip(text, disabledText, guiObject)` | |
| `Library:MakeDraggable(frame, handle, ignoreToggled?)` / `MakeResizable(frame, handle)` | |
| `Library:AddDraggableButton` / `AddDraggableLabel` / `AddDraggableImageButton` | |
| `Library:DropdownDivider(title?)` | |
| `Library:GetKeyString(key)` / `GetTextBounds(text, font, size, width?)` | |
| `Library:GetLighterColor(c)` / `GetDarkerColor(c)` / `GetBetterColor(c, n)` | |
| `Library:SafeCallback(fn, ...)` / `GiveSignal(connection)` | |
| `Library:OnUnload(fn)` / `Library:Unload()` | |
| `Library.Cursor:ChangeIcon(icon)` / `ChangeIconColor` / `ChangeIconSize` / `ChangeCrossColor` / `ResetCursor` | |

---

## Differences from Obsidian

Snow follows Obsidian's API but isn't a 1:1 copy:

- **Additions:** sidebar sections (`Window:AddSection`), button `Variant`, `<accent>` rich text tag, `Window:SetFooterRight`, `Library.ShowAllKeybinds`, `Slider` defaults to `HideMax = true` (the value sits inside the bar).
- **Search** is opt-in (`Search = true`) and always searches all tabs.
- **Not implemented** (the options are accepted and ignored): window snapping to screen edges, dropdown `DragSelect`, `GlobalSearch`, loading screen sidebar pages, and tabbox pop-out.
- The keybind list shows active binds and can't be collapsed. Its entries can be clicked.
