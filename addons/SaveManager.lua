--[[
    Snow SaveManager
    Saves / loads every Toggle and Option to JSON config files (executor file functions required).
]]

local cloneref = (cloneref or clonereference or function(Instance) return Instance end)
local HttpService = cloneref(game:GetService("HttpService"))

local HasFileApi = type(writefile) == "function" and type(readfile) == "function"
    and type(isfile) == "function" and type(isfolder) == "function"
    and type(makefolder) == "function" and type(listfiles) == "function"

local SaveManager = {
    Folder = "SnowSettings",
    SubFolder = "",
    Ignore = {},
    Library = nil,
    LoadingOrder = { "Toggle", "Input", "Slider", "Dropdown", "ColorPicker", "KeyPicker" },
}

SaveManager.Parser = {
    Toggle = {
        Save = function(Idx, Object)
            return { type = "Toggle", idx = Idx, value = Object.Value }
        end,
        Load = function(Idx, Data, Library)
            local Object = Library.Toggles[Idx]
            if Object and Object.Value ~= Data.value then
                Object:SetValue(Data.value)
            end
        end,
    },
    Slider = {
        Save = function(Idx, Object)
            return { type = "Slider", idx = Idx, value = tostring(Object.Value) }
        end,
        Load = function(Idx, Data, Library)
            local Object = Library.Options[Idx]
            if Object and Object.Value ~= tonumber(Data.value) then
                Object:SetValue(Data.value)
            end
        end,
    },
    Dropdown = {
        Save = function(Idx, Object)
            local Value = Object.Value
            if Object.Multi then
                Value = Object:GetActiveValues()
            end
            return { type = "Dropdown", idx = Idx, value = Value, multi = Object.Multi }
        end,
        Load = function(Idx, Data, Library)
            local Object = Library.Options[Idx]
            if Object then
                Object:SetValue(Data.value)
            end
        end,
    },
    ColorPicker = {
        Save = function(Idx, Object)
            return { type = "ColorPicker", idx = Idx, value = Object.Value:ToHex(), transparency = Object.Transparency }
        end,
        Load = function(Idx, Data, Library)
            local Object = Library.Options[Idx]
            if Object then
                Object:SetValueRGB(Color3.fromHex(Data.value), Data.transparency)
            end
        end,
    },
    KeyPicker = {
        Save = function(Idx, Object)
            return { type = "KeyPicker", idx = Idx, mode = Object.Mode, key = Object.Value, modifiers = Object.Modifiers }
        end,
        Load = function(Idx, Data, Library)
            local Object = Library.Options[Idx]
            if Object then
                Object:SetValue({ Data.key, Data.mode, Data.modifiers })
            end
        end,
    },
    Input = {
        Save = function(Idx, Object)
            return { type = "Input", idx = Idx, text = Object.Value }
        end,
        Load = function(Idx, Data, Library)
            local Object = Library.Options[Idx]
            if Object and type(Data.text) == "string" then
                Object:SetValue(Data.text)
            end
        end,
    },
}

function SaveManager:SetLibrary(Library)
    self.Library = Library
end

function SaveManager:SetLoadingOrder(Order)
    self.LoadingOrder = Order
end

function SaveManager:SetIgnoreIndexes(List)
    for _, Key in ipairs(List) do
        self.Ignore[Key] = true
    end
end

function SaveManager:IgnoreThemeSettings()
    self:SetIgnoreIndexes({
        "BackgroundColor", "SidebarColor", "MainColor", "ElementColor", "OutlineColor",
        "AccentColor", "FontColor", "MutedColor", "ThemeManager_ThemeList",
        "ThemeManager_CustomThemeList", "ThemeManager_CustomThemeName", "ThemeManager_Font",
    })
end

function SaveManager:SetFolder(Folder)
    self.Folder = Folder
    self:BuildFolderTree()
end

function SaveManager:SetSubFolder(Folder)
    self.SubFolder = Folder or ""
    self:BuildFolderTree()
end

function SaveManager:GetPaths()
    local Settings = self.Folder .. "/settings"
    if self.SubFolder ~= "" then
        Settings = Settings .. "/" .. self.SubFolder
    end
    return { self.Folder, self.Folder .. "/themes", self.Folder .. "/settings", Settings }
end

function SaveManager:GetSettingsFolder()
    local Paths = self:GetPaths()
    return Paths[#Paths]
end

function SaveManager:BuildFolderTree()
    if not HasFileApi then
        return
    end
    for _, Path in ipairs(self:GetPaths()) do
        if not isfolder(Path) then
            makefolder(Path)
        end
    end
end
SaveManager.CheckFolderTree = SaveManager.BuildFolderTree
SaveManager.CheckSubFolder = SaveManager.BuildFolderTree

function SaveManager:SaveJSON(Name)
    local Data = { objects = {} }
    local Library = self.Library
    for Idx, Toggle in pairs(Library.Toggles) do
        if not self.Ignore[Idx] and Toggle.Type == "Toggle" then
            table.insert(Data.objects, self.Parser.Toggle.Save(Idx, Toggle))
        end
    end
    for Idx, Option in pairs(Library.Options) do
        local Parser = self.Parser[Option.Type]
        if Parser and not self.Ignore[Idx] then
            table.insert(Data.objects, Parser.Save(Idx, Option))
        end
    end
    return HttpService:JSONEncode(Data)
end

function SaveManager:Save(Name)
    if not HasFileApi then
        return false, "file functions are not available"
    end
    if not Name or Name:gsub("%s", "") == "" then
        return false, "no config file is selected"
    end
    self:BuildFolderTree()
    local Ok, Encoded = pcall(self.SaveJSON, self, Name)
    if not Ok then
        return false, "failed to encode data"
    end
    writefile(self:GetSettingsFolder() .. "/" .. Name .. ".json", Encoded)
    return true
end

function SaveManager:LoadJSON(Json)
    local Ok, Decoded = pcall(HttpService.JSONDecode, HttpService, Json)
    if not Ok or type(Decoded) ~= "table" then
        return false, "decode error"
    end
    local Buckets = {}
    for _, Object in ipairs(Decoded.objects or {}) do
        Buckets[Object.type] = Buckets[Object.type] or {}
        table.insert(Buckets[Object.type], Object)
    end
    for _, Type in ipairs(self.LoadingOrder) do
        for _, Object in ipairs(Buckets[Type] or {}) do
            local Parser = self.Parser[Type]
            if Parser and not self.Ignore[Object.idx] then
                task.spawn(Parser.Load, Object.idx, Object, self.Library)
            end
        end
    end
    return true
end

function SaveManager:Load(Name)
    if not HasFileApi then
        return false, "file functions are not available"
    end
    if not Name then
        return false, "no config file is selected"
    end
    local File = self:GetSettingsFolder() .. "/" .. Name .. ".json"
    if not isfile(File) then
        return false, "invalid file"
    end
    return self:LoadJSON(readfile(File))
end

function SaveManager:Delete(Name)
    if not HasFileApi or type(delfile) ~= "function" then
        return false, "file functions are not available"
    end
    local File = self:GetSettingsFolder() .. "/" .. tostring(Name) .. ".json"
    if not isfile(File) then
        return false, "invalid file"
    end
    local Ok = pcall(delfile, File)
    return Ok, Ok and nil or "delete error"
end

function SaveManager:RefreshConfigList()
    if not HasFileApi then
        return {}
    end
    self:BuildFolderTree()
    local Names = {}
    for _, File in ipairs(listfiles(self:GetSettingsFolder())) do
        local Name = File:match("([^/\\]+)%.json$")
        if Name then
            table.insert(Names, Name)
        end
    end
    table.sort(Names)
    return Names
end

function SaveManager:GetAutoloadConfig()
    if not HasFileApi then
        return "none"
    end
    local File = self:GetSettingsFolder() .. "/autoload.txt"
    if isfile(File) then
        return readfile(File)
    end
    return "none"
end

function SaveManager:SaveAutoloadConfig(Name)
    if not HasFileApi then
        return false, "file functions are not available"
    end
    self:BuildFolderTree()
    writefile(self:GetSettingsFolder() .. "/autoload.txt", Name)
    return true
end

function SaveManager:DeleteAutoLoadConfig()
    if not HasFileApi or type(delfile) ~= "function" then
        return false, "file functions are not available"
    end
    local File = self:GetSettingsFolder() .. "/autoload.txt"
    if isfile(File) then
        pcall(delfile, File)
    end
    return true
end

function SaveManager:LoadAutoloadConfig()
    local Name = self:GetAutoloadConfig()
    if Name == "none" then
        return
    end
    local Ok, Error = self:Load(Name)
    if Ok then
        self.Library:Notify({ Title = "Config", Description = "Auto loaded config " .. Name, Icon = "folder-check" })
    else
        self.Library:Notify({ Title = "Config", Description = "Failed to auto load " .. Name .. ": " .. tostring(Error), Icon = "folder-x" })
    end
end

function SaveManager:BuildConfigSection(Tab)
    assert(self.Library, "SaveManager:SetLibrary(Library) must be called first")
    local Library = self.Library
    local Options = Library.Options

    local Box = Tab:AddRightGroupbox("configuration", "folder-cog")

    Box:AddInput("SaveManager_ConfigName", { Text = "name", Placeholder = "config name" })
    Box:AddButton({
        Text = "create config",
        Icon = "file-plus",
        Func = function()
            local Name = Options.SaveManager_ConfigName.Value
            local Ok, Error = self:Save(Name)
            if not Ok then
                return Library:Notify({ Title = "Config", Description = "Failed to create: " .. tostring(Error), Icon = "circle-x" })
            end
            Library:Notify({ Title = "Config", Description = "Created config " .. Name, Icon = "circle-check" })
            Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
            Options.SaveManager_ConfigList:SetValue(Name)
        end,
    })

    Box:AddDivider()
    Box:AddDropdown("SaveManager_ConfigList", { Text = "config", Values = self:RefreshConfigList(), AllowNull = true })

    Box:AddButton({
        Text = "load",
        Func = function()
            local Name = Options.SaveManager_ConfigList.Value
            local Ok, Error = self:Load(Name)
            if not Ok then
                return Library:Notify({ Title = "Config", Description = "Failed to load: " .. tostring(Error), Icon = "circle-x" })
            end
            Library:Notify({ Title = "Config", Description = "Loaded config " .. tostring(Name), Icon = "circle-check" })
        end,
    }):AddButton({
        Text = "overwrite",
        Func = function()
            local Name = Options.SaveManager_ConfigList.Value
            local Ok, Error = self:Save(Name)
            if not Ok then
                return Library:Notify({ Title = "Config", Description = "Failed to overwrite: " .. tostring(Error), Icon = "circle-x" })
            end
            Library:Notify({ Title = "Config", Description = "Overwrote config " .. tostring(Name), Icon = "circle-check" })
        end,
    })

    Box:AddButton({
        Text = "delete",
        Risky = true,
        DoubleClick = true,
        Func = function()
            local Name = Options.SaveManager_ConfigList.Value
            local Ok, Error = self:Delete(Name)
            if not Ok then
                return Library:Notify({ Title = "Config", Description = "Failed to delete: " .. tostring(Error), Icon = "circle-x" })
            end
            Library:Notify({ Title = "Config", Description = "Deleted config " .. tostring(Name), Icon = "trash-2" })
            Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
            Options.SaveManager_ConfigList:SetValue(nil)
        end,
    }):AddButton({
        Text = "refresh",
        Variant = "Secondary",
        Func = function()
            Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
        end,
    })

    local AutoloadLabel = Box:AddLabel("autoload: " .. self:GetAutoloadConfig(), true)

    Box:AddButton({
        Text = "set as autoload",
        Variant = "Secondary",
        Func = function()
            local Name = Options.SaveManager_ConfigList.Value
            if not Name then
                return
            end
            self:SaveAutoloadConfig(Name)
            AutoloadLabel:SetText("autoload: " .. Name)
            Library:Notify({ Title = "Config", Description = "Set " .. Name .. " to auto load", Icon = "circle-check" })
        end,
    }):AddButton({
        Text = "reset autoload",
        Variant = "Secondary",
        Func = function()
            self:DeleteAutoLoadConfig()
            AutoloadLabel:SetText("autoload: none")
        end,
    })

    self:SetIgnoreIndexes({ "SaveManager_ConfigList", "SaveManager_ConfigName" })
    return Box
end

SaveManager:BuildFolderTree()

return SaveManager
