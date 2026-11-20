--[[
    Snow ThemeManager
    Built-in themes, live colour editing, custom theme files and a default theme.
]]

local cloneref = (cloneref or clonereference or function(Instance) return Instance end)
local HttpService = cloneref(game:GetService("HttpService"))

local HasFileApi = type(writefile) == "function" and type(readfile) == "function"
    and type(isfile) == "function" and type(isfolder) == "function"
    and type(makefolder) == "function" and type(listfiles) == "function"

local ThemeManager = {
    Folder = "SnowSettings",
    Library = nil,
    DefaultTheme = "Snow",
}

-- The scheme keys a theme controls, in the order they appear in the UI.
ThemeManager.Keys = {
    { "BackgroundColor", "background" },
    { "SidebarColor", "sidebar" },
    { "MainColor", "main" },
    { "ElementColor", "element" },
    { "OutlineColor", "outline" },
    { "AccentColor", "accent" },
    { "FontColor", "font" },
    { "MutedColor", "muted text" },
}

ThemeManager.BuiltInThemes = {
    Snow = { 1, {
        BackgroundColor = "0e0f13", SidebarColor = "0b0c0f", MainColor = "15161b", ElementColor = "1e1f25",
        OutlineColor = "24262d", AccentColor = "3a9bf0", FontColor = "e8e9ee", MutedColor = "7a7d88",
    } },
    Frost = { 2, {
        BackgroundColor = "10141b", SidebarColor = "0c1016", MainColor = "161c25", ElementColor = "1f2631",
        OutlineColor = "28303d", AccentColor = "7cc7ff", FontColor = "eef4fb", MutedColor = "7f8b9c",
    } },
    Rose = { 3, {
        BackgroundColor = "141013", SidebarColor = "100c0f", MainColor = "1b151a", ElementColor = "251d23",
        OutlineColor = "2e242b", AccentColor = "f0588e", FontColor = "f2e8ee", MutedColor = "8a7a84",
    } },
    Mint = { 4, {
        BackgroundColor = "0e1311", SidebarColor = "0b0f0d", MainColor = "141b18", ElementColor = "1c2521",
        OutlineColor = "242e2a", AccentColor = "3ddc97", FontColor = "e6f1ec", MutedColor = "778a82",
    } },
    Amber = { 5, {
        BackgroundColor = "13110e", SidebarColor = "0f0d0b", MainColor = "1b1814", ElementColor = "25211c",
        OutlineColor = "2e2924", AccentColor = "f5a623", FontColor = "f2ede6", MutedColor = "8a8377",
    } },
    Violet = { 6, {
        BackgroundColor = "110f15", SidebarColor = "0d0c11", MainColor = "18151d", ElementColor = "221e28",
        OutlineColor = "2b2632", AccentColor = "9b7bff", FontColor = "eeeaf5", MutedColor = "807a8c",
    } },
    Mono = { 7, {
        BackgroundColor = "0f0f0f", SidebarColor = "0b0b0b", MainColor = "161616", ElementColor = "202020",
        OutlineColor = "2a2a2a", AccentColor = "e6e6e6", FontColor = "f0f0f0", MutedColor = "7d7d7d",
    } },
    Light = { 8, {
        BackgroundColor = "f4f5f7", SidebarColor = "eceef1", MainColor = "ffffff", ElementColor = "e6e8ec",
        OutlineColor = "d7dae0", AccentColor = "2f80ed", FontColor = "1d1f24", MutedColor = "6b707b",
    } },
}

ThemeManager.Fonts = {
    "Gotham", "BuilderSans", "Montserrat", "Ubuntu", "Roboto", "SourceSans",
    "Nunito", "Oswald", "Arial", "Code", "RobotoMono", "Jura",
}

function ThemeManager:SetLibrary(Library)
    self.Library = Library
end

function ThemeManager:GetPaths()
    return { self.Folder, self.Folder .. "/themes" }
end

function ThemeManager:BuildFolderTree()
    if not HasFileApi then
        return
    end
    for _, Path in ipairs(self:GetPaths()) do
        if not isfolder(Path) then
            makefolder(Path)
        end
    end
end
ThemeManager.CheckFolderTree = ThemeManager.BuildFolderTree

function ThemeManager:SetFolder(Folder)
    self.Folder = Folder
    self:BuildFolderTree()
end

local function ToColor(Value)
    if typeof(Value) == "Color3" then
        return Value
    end
    local Ok, Color = pcall(Color3.fromHex, tostring(Value))
    return Ok and Color or nil
end

-- Pushes theme data (key -> hex/Color3, optional Font) into the library scheme and any colour pickers.
function ThemeManager:ApplyThemeData(Data)
    local Library = self.Library
    local Options = Library.Options
    for _, Entry in ipairs(self.Keys) do
        local Key = Entry[1]
        local Color = Data[Key] and ToColor(Data[Key])
        if Color then
            Library.Scheme[Key] = Color
            if Options[Key] and Options[Key].Type == "ColorPicker" then
                Options[Key]:SetValueRGB(Color)
            end
        end
    end
    if Data.Font and Enum.Font[Data.Font] then
        Library:SetFont(Enum.Font[Data.Font])
        if Options.ThemeManager_Font then
            Options.ThemeManager_Font:SetValue(Data.Font)
        end
    end
    Library:UpdateColorsUsingRegistry()
end

function ThemeManager:ApplyTheme(Name)
    local Data = self:GetCustomTheme(Name)
    if not Data then
        local BuiltIn = self.BuiltInThemes[Name]
        Data = BuiltIn and BuiltIn[2]
    end
    if not Data then
        return false
    end
    self.CurrentTheme = Name
    self:ApplyThemeData(Data)
    return true
end

-- Reads the colour pickers back into the scheme (called whenever a picker changes).
function ThemeManager:ThemeUpdate()
    local Library = self.Library
    local Options = Library.Options
    for _, Entry in ipairs(self.Keys) do
        local Picker = Options[Entry[1]]
        if Picker and Picker.Type == "ColorPicker" then
            Library.Scheme[Entry[1]] = Picker.Value
        end
    end
    Library:UpdateColorsUsingRegistry()
end

function ThemeManager:GetCustomTheme(Name)
    if not HasFileApi or not Name then
        return nil
    end
    local File = self.Folder .. "/themes/" .. Name .. ".json"
    if not isfile(File) then
        return nil
    end
    local Ok, Decoded = pcall(HttpService.JSONDecode, HttpService, readfile(File))
    return Ok and Decoded or nil
end

function ThemeManager:SaveCustomTheme(Name)
    if not HasFileApi then
        return false, "file functions are not available"
    end
    if not Name or Name:gsub("%s", "") == "" then
        return false, "invalid theme name"
    end
    self:BuildFolderTree()
    local Library = self.Library
    local Data = {}
    for _, Entry in ipairs(self.Keys) do
        Data[Entry[1]] = Library.Scheme[Entry[1]]:ToHex()
    end
    local Font = Library.Options.ThemeManager_Font
    if Font and Font.Value then
        Data.Font = Font.Value
    end
    writefile(self.Folder .. "/themes/" .. Name .. ".json", HttpService:JSONEncode(Data))
    return true
end

function ThemeManager:Delete(Name)
    if not HasFileApi or type(delfile) ~= "function" then
        return false, "file functions are not available"
    end
    local File = self.Folder .. "/themes/" .. tostring(Name) .. ".json"
    if not isfile(File) then
        return false, "invalid file"
    end
    local Ok = pcall(delfile, File)
    return Ok
end

function ThemeManager:ReloadCustomThemes()
    if not HasFileApi then
        return {}
    end
    self:BuildFolderTree()
    local Names = {}
    for _, File in ipairs(listfiles(self.Folder .. "/themes")) do
        local Name = File:match("([^/\\]+)%.json$")
        if Name then
            table.insert(Names, Name)
        end
    end
    table.sort(Names)
    return Names
end

function ThemeManager:GetDefaultTheme()
    if HasFileApi then
        local File = self.Folder .. "/themes/default.txt"
        if isfile(File) then
            return readfile(File)
        end
    end
    return self.DefaultTheme
end

function ThemeManager:SetDefaultTheme(Data)
    -- Accepts a table of scheme colours to use as the fallback default theme.
    self.BuiltInThemes.Default = { 0, Data }
    self.DefaultTheme = "Default"
end

function ThemeManager:SaveDefault(Name)
    if HasFileApi then
        self:BuildFolderTree()
        writefile(self.Folder .. "/themes/default.txt", Name)
    end
end

function ThemeManager:LoadDefault()
    local Name = self:GetDefaultTheme()
    if not self:ApplyTheme(Name) then
        self:ApplyTheme(self.DefaultTheme)
        Name = self.DefaultTheme
    end
    local Options = self.Library.Options
    if Options.ThemeManager_ThemeList and self.BuiltInThemes[Name] then
        Options.ThemeManager_ThemeList:SetValue(Name)
    end
end

function ThemeManager:DeleteDefaultTheme()
    if HasFileApi and type(delfile) == "function" then
        local File = self.Folder .. "/themes/default.txt"
        if isfile(File) then
            pcall(delfile, File)
        end
    end
end

function ThemeManager:CreateThemeManager(Groupbox)
    assert(self.Library, "ThemeManager:SetLibrary(Library) must be called first")
    local Library = self.Library
    local Options = Library.Options

    for _, Entry in ipairs(self.Keys) do
        Groupbox:AddLabel(Entry[2]):AddColorPicker(Entry[1], {
            Default = Library.Scheme[Entry[1]],
            Title = Entry[2],
            Callback = function()
                self:ThemeUpdate()
            end,
        })
    end

    Groupbox:AddDropdown("ThemeManager_Font", {
        Text = "font",
        Values = self.Fonts,
        Default = "Gotham",
        Callback = function(Value)
            if Value and Enum.Font[Value] then
                Library:SetFont(Enum.Font[Value])
            end
        end,
    })

    Groupbox:AddDivider()

    local ThemeNames = {}
    for Name in pairs(self.BuiltInThemes) do
        table.insert(ThemeNames, Name)
    end
    table.sort(ThemeNames, function(A, B)
        return self.BuiltInThemes[A][1] < self.BuiltInThemes[B][1]
    end)

    Groupbox:AddDropdown("ThemeManager_ThemeList", {
        Text = "theme",
        Values = ThemeNames,
        Default = 1,
        Callback = function(Value)
            if Value then
                self:ApplyTheme(Value)
            end
        end,
    })
    Groupbox:AddButton({
        Text = "set as default",
        Variant = "Secondary",
        Func = function()
            local Name = Options.ThemeManager_ThemeList.Value
            self:SaveDefault(Name)
            Library:Notify({ Title = "Theme", Description = "Default theme set to " .. tostring(Name), Icon = "palette" })
        end,
    })

    Groupbox:AddDivider()
    Groupbox:AddInput("ThemeManager_CustomThemeName", { Text = "name", Placeholder = "custom theme" })
    Groupbox:AddButton({
        Text = "save theme",
        Func = function()
            local Name = Options.ThemeManager_CustomThemeName.Value
            local Ok, Error = self:SaveCustomTheme(Name)
            if not Ok then
                return Library:Notify({ Title = "Theme", Description = "Failed to save: " .. tostring(Error), Icon = "circle-x" })
            end
            Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
            Library:Notify({ Title = "Theme", Description = "Saved theme " .. Name, Icon = "circle-check" })
        end,
    })
    Groupbox:AddDropdown("ThemeManager_CustomThemeList", {
        Text = "custom",
        Values = self:ReloadCustomThemes(),
        AllowNull = true,
    })
    Groupbox:AddButton({
        Text = "load",
        Func = function()
            local Name = Options.ThemeManager_CustomThemeList.Value
            if not self:ApplyTheme(Name) then
                return Library:Notify({ Title = "Theme", Description = "Failed to load theme", Icon = "circle-x" })
            end
            Library:Notify({ Title = "Theme", Description = "Loaded theme " .. tostring(Name), Icon = "circle-check" })
        end,
    }):AddButton({
        Text = "delete",
        Risky = true,
        DoubleClick = true,
        Func = function()
            local Name = Options.ThemeManager_CustomThemeList.Value
            self:Delete(Name)
            Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
        end,
    })
    Groupbox:AddButton({
        Text = "set custom as default",
        Variant = "Secondary",
        Func = function()
            local Name = Options.ThemeManager_CustomThemeList.Value
            if Name then
                self:SaveDefault(Name)
                Library:Notify({ Title = "Theme", Description = "Default theme set to " .. Name, Icon = "palette" })
            end
        end,
    })

    self:LoadDefault()
end

function ThemeManager:CreateGroupBox(Tab)
    assert(self.Library, "ThemeManager:SetLibrary(Library) must be called first")
    return Tab:AddLeftGroupbox("themes", "palette")
end

function ThemeManager:ApplyToTab(Tab)
    local Groupbox = self:CreateGroupBox(Tab)
    self:CreateThemeManager(Groupbox)
    return Groupbox
end

function ThemeManager:ApplyToGroupbox(Groupbox)
    self:CreateThemeManager(Groupbox)
    return Groupbox
end

ThemeManager:BuildFolderTree()

return ThemeManager
