local json = require("dkjson")

local appdata_path = os.getenv("APPDATA")
local config_file = appdata_path .. "\\Blackmagic Design\\DaVinci Resolve\\Support\\Fusion\\Scripts\\Utility\\Martas\\config.json"
print(config_file)

-- Function to save configuration to JSON file
local function save_config(file_path, config)
    local file = io.open(file_path, "w")
    if file then
        local content = json.encode(config, { indent = true })
        file:write(content)
        file:close()
    else
        error("Could not open file for writing: " .. file_path)
    end
end

-- Function to load configuration from JSON file
local function load_config(file_path)
    local file = io.open(file_path, "r")
    if file then
        local content = file:read("*a")
        file:close()
        return json.decode(content)
    else
        return nil
    end
end

-- Load or create the configuration file
local config = load_config(config_file)
if not config then
    config = {
        Paths = {
            recent_preset_path = "",
            unique_ids_path = ""
        }
    }
    save_config(config_file, config)
end

local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)


-- Function to read file content
local function readFile(filePath)
    local file = io.open(filePath, "r")
    if not file then return nil end
    local content = file:read("*a")
    file:close()
    return content
end

local function GetID(item, fxIDs)
    for _, fxID in ipairs(fxIDs) do
        if item.Description == fxID.Description then
            return fxID.ID
        end
    end
end


local function ApplySapphire(tool, p)
    local lowerLabel = string.lower(string.gsub(p.Label, " ", "_"))
    if type(p.Value) == "table" and p.Value.R and p.Value.G and p.Value.B then -- color parameter type
        tool[lowerLabel .. "Red"] = p.Value.R / 255
        tool[lowerLabel .. "Green"] = p.Value.G / 255
        tool[lowerLabel .. "Blue"] = p.Value.B / 255
    elseif type(p.Value) == "table" and p.Value.X and p.Value.Y then -- position parameter type
        tool[lowerLabel] = { p.Value.X, p.Value.Y }
    elseif type(p.Value) == "boolean" then                           -- checkbox parameter type
        tool[lowerLabel] = p.Value and 1 or 0
    elseif type(p.Value) == "table" and p.Value.Index then           -- dropdown parameter type
        tool[lowerLabel] = p.Value.Index
    else                                                             -- other parameter types
        tool[lowerLabel] = p.Value
    end
end

local function ApplySapphireKeyframes(tool, p, keyframe)
    local i = keyframe.Time.FrameCount or 0
    local lowerLabel = string.lower(string.gsub(p.Label, " ", "_"))
    if type(keyframe.Value) == "table" and keyframe.Value.R and keyframe.Value.G and keyframe.Value.B then -- color parameter type
        tool[lowerLabel .. "Red"][i] = keyframe.Value.R / 255
        tool[lowerLabel .. "Green"][i] = keyframe.Value.G / 255
        tool[lowerLabel .. "Blue"][i] = keyframe.Value.B / 255
    elseif type(p.Value) == "table" and keyframe.Value.X and keyframe.Value.Y then -- position parameter type
        tool[lowerLabel] = { keyframe.Value.X, keyframe.Value.Y }
    elseif type(p.Value) == "boolean" then                                         -- checkbox parameter type
        tool[lowerLabel][i] = keyframe.Value and 1 or 0
    elseif type(p.Value) == "table" and keyframe.Value.Index then                  -- dropdown parameter type
        tool[lowerLabel][i] = keyframe.Value.Index
    else                                                                           -- other parameter types
        tool[lowerLabel][i] = keyframe.Value
    end
end

local function SapphireEnableKeyframes(tool, p)
    local lowerLabel = string.lower(string.gsub(p.Label, " ", "_"))
    if type(p.Value) == "table" and p.Value.R and p.Value.G and p.Value.B then -- color parameter type
        tool[lowerLabel .. "Red"] = comp.BezierSpline({})
        tool[lowerLabel .. "Green"] = comp.BezierSpline({})
        tool[lowerLabel .. "Blue"] = comp.BezierSpline({})
    else
        tool[lowerLabel] = comp.BezierSpline({})
    end
end

local function GetUniverseParam(tool, p)
    local lastParam = nil
    for i = 0, 1000 do
        local param = tool[tostring(i)]
        local paramR = tool[tostring(i) .. "Red"]
        if paramR and paramR.Name == p.Label .. " Red" then
            return i
        elseif param and param.Name == p.Label then
            lastParam = i
        end
    end
    -- for _, i in ipairs(tool:GetInputList()) do
    --     local param = tool[i]
    --     local paramR = tool[i .. "Red"]
    --     if paramR and paramR.Name == p.Label .. " Red" then
    --         return i
    --     elseif param and param.Name == p.Label then
    --         lastParam = i
    --     end
    -- end
    return lastParam
end

local function ApplyUniverse(tool, p, i)
    local r = tool[tostring(i) .. "Red"]
    local g = tool[tostring(i) .. "Green"]
    local b = tool[tostring(i) .. "Blue"]
    if type(p.Value) == "table" and p.Value.R and p.Value.G and p.Value.B and (r and r.Name == p.Label .. " Red" or g and g.Name == p.Label .. " Green" or b and b.Name == p.Label .. " Blue") then
        -- print(r, g, b)
        if p.Value.R > 1 then
            tool[tostring(i) .. "Red"] = p.Value.R / 255
            tool[tostring(i) .. "Green"] = p.Value.G / 255
            tool[tostring(i) .. "Blue"] = p.Value.B / 255
        else
            tool[tostring(i) .. "Red"] = p.Value.R
            tool[tostring(i) .. "Green"] = p.Value.G
            tool[tostring(i) .. "Blue"] = p.Value.B
        end
    elseif type(p.Value) == "table" and p.Value.X and p.Value.Y then -- position parameter type
        tool[tostring(i)] = { p.Value.X, p.Value.Y }
    elseif type(p.Value) == "boolean" then                           -- checkbox parameter type
        tool[tostring(i)] = p.Value and 1 or 0
    elseif type(p.Value) == "table" and p.Value.Index then           -- dropdown parameter type
        tool[tostring(i)] = p.Value.Index
    elseif tool[tostring(i)].Name == p.Label then
        tool[tostring(i)] = p.Value
    end
end

local function ApplyUniverseKeyframes(tool, p, i, keyframe)
    local t = keyframe.Time.FrameCount or 0
    local r = tool[tostring(i) .. "Red"]
    local g = tool[tostring(i) .. "Green"]
    local b = tool[tostring(i) .. "Blue"]
    if type(keyframe.Value) == "table" and keyframe.Value.R and keyframe.Value.G and keyframe.Value.B and (r and r.Name == p.Label .. " Red" or g and g.Name == p.Label .. " Green" or b and b.Name == p.Label .. " Blue") then
        tool[tostring(i) .. "Red"][t] = keyframe.Value.R / 255
        tool[tostring(i) .. "Green"][t] = keyframe.Value.G / 255
        tool[tostring(i) .. "Blue"][t] = keyframe.Value.B / 255
    elseif type(keyframe.Value) == "table" and keyframe.Value.X and keyframe.Value.Y then -- position parameter type
        tool[tostring(i)][t] = { keyframe.Value.X, keyframe.Value.Y }
    elseif type(keyframe.Value) == "boolean" then                                         -- checkbox parameter type
        tool[tostring(i)][t] = keyframe.Value and 1 or 0
    elseif type(keyframe.Value) == "table" and keyframe.Value.Index then                  -- dropdown parameter type
        tool[tostring(i)][t] = keyframe.Value.Index
    elseif tool[tostring(i)].Name == p.Label then
        tool[tostring(i)][t] = keyframe.Value
    end
end

local function UniverseEnableKeyframes(tool, p, i)
    local r = tool[tostring(i) .. "Red"]
    local g = tool[tostring(i) .. "Green"]
    local b = tool[tostring(i) .. "Blue"]
    if type(p.Value) == "table" and p.Value.R and p.Value.G and p.Value.B and (r and r.Name == p.Label .. " Red" or g and g.Name == p.Label .. " Green" or b and b.Name == p.Label .. " Blue") then
        tool[tostring(i) .. "Red"] = comp.BezierSpline({})
        tool[tostring(i) .. "Green"] = comp.BezierSpline({})
        tool[tostring(i) .. "Blue"] = comp.BezierSpline({})
    else
        tool[tostring(i)] = comp.BezierSpline({})
    end
end

local function ApplyTwixtor(tool, p)
    local cleanedLabel = string.gsub(p.Label, "%%", "")    -- Remove % from p.Label
    cleanedLabel = string.gsub(cleanedLabel, " ", "")      -- Replace spaces with nothing

    if type(p.Value) == "boolean" then                     -- checkbox parameter type
        tool[cleanedLabel] = p.Value and 1 or 0
    elseif type(p.Value) == "table" and p.Value.Index then -- dropdown parameter type
        tool[cleanedLabel] = p.Value.Index
    else                                                   -- other parameter types
        tool[cleanedLabel] = p.Value
    end
end

local function ApplyTwixtorKeyframes(tool, p, keyframe)
    local t = keyframe.Time.FrameCount or 0
    local cleanedLabel = string.gsub(p.Label, "%%", "")                  -- Remove % from p.Label
    cleanedLabel = string.gsub(cleanedLabel, " ", "")                    -- Replace spaces with nothing

    if type(keyframe.Value) == "boolean" then                            -- checkbox parameter type
        tool[cleanedLabel][t] = keyframe.Value and 1 or 0
    elseif type(keyframe.Value) == "table" and keyframe.Value.Index then -- dropdown parameter type
        tool[cleanedLabel][t] = keyframe.Value.Index
    else                                                                 -- other parameter types
        tool[cleanedLabel][t] = keyframe.Value
    end
end

local function TwixtorEnableKeyframes(tool, p)
    local cleanedLabel = string.gsub(p.Label, "%%", "") -- Remove % from p.Label
    cleanedLabel = string.gsub(cleanedLabel, " ", "")   -- Replace spaces with nothing

    tool[cleanedLabel] = comp.BezierSpline({})
end

local function rgbToHex(r, g, b)
    return string.format("%02X%02X%02X", r, g, b)
end

local function CreateNote(item, _)
    local xf = comp:AddTool("Transform", _, 0)
    comp:SetActiveTool(xf)
    xf:SetAttrs({ TOOLB_NameSet = true, TOOLS_Name = item.Description .. _ }) -- rename tool

    local note = comp:AddTool("Note", _, 1)
    local comments = {}
    local p = item.Parameters
    print(item.Description)
    if p then
        for _, param in ipairs(item.Parameters) do
            if param.Keyframes then
                for i, keyframe in ipairs(param.Keyframes) do
                    table.insert(comments,
                        param.Label ..
                        ": " .. tostring(keyframe.Value) .. ";" .. "Frame: " .. tostring(keyframe.Time.FrameCount))
                    if type(param.Value) == "table" then
                        if keyframe.Value.R or keyframe.Value.G or keyframe.Value.B then -- try to conver color to hex
                            local hexColor = rgbToHex(keyframe.Value.R, keyframe.Value.G, keyframe.Value.B)
                            table.insert(comments,
                                param.Label .. ": " .. hexColor .. ";" .. "Frame: " .. tostring(keyframe.Time.FrameCount))
                        elseif keyframe.Value.X or keyframe.Value.Y then
                            table.insert(comments,
                                param.Label ..
                                ": X: " ..
                                tostring(keyframe.Value.X) ..
                                ", Y: " ..
                                tostring(keyframe.Value.Y) .. ";" .. "Frame: " .. tostring(keyframe.Time.FrameCount))
                        end
                    else
                        table.insert(comments,
                            param.Label ..
                            ": " .. tostring(keyframe.Value) .. ";" .. "Frame: " .. tostring(keyframe.Time.FrameCount))
                    end
                end
            else
                if type(param.Value) == "table" then
                    if param.Value.R or param.Value.G or param.Value.B then -- try to conver color to hex
                        local hexColor = rgbToHex(param.Value.R, param.Value.G, param.Value.B)
                        table.insert(comments, param.Label .. ": " .. hexColor)
                    elseif param.Value.X or param.Value.Y then
                        table.insert(comments,
                            param.Label .. ": X: " .. tostring(param.Value.X) .. ", Y: " .. tostring(param.Value.Y))
                    else
                        table.insert(comments, param.Label .. ": " .. tostring(param.Value))
                    end
                else
                    table.insert(comments, param.Label .. ": " .. tostring(param.Value))
                end
            end
        end
    else
        table.insert(comments, "No parameters found")
    end
    note["Comments"][0] = table.concat(comments, "\n")
    note:SetAttrs({ TOOLB_NameSet = true, TOOLS_Name = "OFX ID not found" })
end


function Main(data, fxIDs)
    local sapphire = "S_"
    local bcc = "BCC"
    local uni = "uni."
    local twx = "Twixtor"
    local nb = "NewBlue"
    for _, item in ipairs(data) do
        -- print(_)
        local ofx = GetID(item, fxIDs)
        if ofx == nil or string.find(ofx, nb) then
            CreateNote(item, _)
        else
            local tool = comp:AddTool(ofx, _, 0)
            tool:SetAttrs({ TOOLB_NameSet = true, TOOLS_Name = item.Description .. _ }) -- rename tool
            comp:SetActiveTool(tool)

            local parameters = item.Parameters
            if parameters then
                for _, p in ipairs(item.Parameters) do
                    if string.find(item.Description, sapphire, 1, true) == 1 or string.find(item.Description, bcc, 1, true) == 1 then
                        if p.Keyframes then
                            SapphireEnableKeyframes(tool, p)
                            for i, keyframe in ipairs(p.Keyframes) do
                                ApplySapphireKeyframes(tool, p, keyframe)
                            end
                        else
                            ApplySapphire(tool, p)
                        end
                        -- elseif string.find(item.Description, bcc, 1, true) == 1 then
                    elseif string.find(item.Description, uni, 1, true) == 1 then
                        local param = GetUniverseParam(tool, p)
                        if p.Keyframes then
                            UniverseEnableKeyframes(tool, p, param)
                            for i, keyframe in ipairs(p.Keyframes) do
                                ApplyUniverseKeyframes(tool, p, param, keyframe)
                            end
                        else
                            ApplyUniverse(tool, p, param)
                        end
                    elseif string.find(item.Description, twx, 1, true) == 1 then
                        if p.Keyframes then
                            TwixtorEnableKeyframes(tool, p)
                            for i, keyframe in ipairs(p.Keyframes) do
                                ApplyTwixtorKeyframes(tool, p, keyframe)
                            end
                        else
                            ApplyTwixtor(tool, p)
                        end
                    else
                        -- NewBlue is unsupported in fusion
                        CreateNote(item, _)
                    end
                end
            end
        end
        if _ == 1 then
        else
            local cT = string.gsub(item.Description .. _, "[ %-./()]", "")
            local pT = string.gsub(data[_ - 1].Description .. (_ - 1), "[ %-./()]", "")
            print("Connecting " .. cT .. " to " .. pT)
            if cT and pT then
                comp:FindTool(cT):ConnectInput("Source", comp:FindTool(pT))
                comp:FindTool(cT):ConnectInput("From", comp:FindTool(pT))
                comp:FindTool(cT):ConnectInput("Background", comp:FindTool(pT))
                comp:FindTool(cT):ConnectInput("Input", comp:FindTool(pT))
            end
        end
    end
end

-- comp:Lock()
-- Main()
-- comp:Unlock()


MainWindow = disp:AddWindow({
    ID = "MainWindow",
    TargetID = "MainWindow",
    WindowTitle = "[Martas] Import Vegas Pro Preset",
    Geometry = { 950, 400, 350, 130 },
    Spacing = 10,
    ui:VGroup {
        ID = "root",
        ui:HGroup {
            ui:LineEdit {
                ID = "filePath1",
                PlaceholderText = "Preset file path",
                -- Alignment = {AlignHCenter = true},
                -- Events = {ReturnPressed = true}
                Weight = 0.75,
                Text = config.Paths.recent_preset_path or ""
            },

            ui:Button {
                ID = "BrowseP",
                Text = "Browse",
                Weight = 0.25,
                -- Events = {Action = true}
            }
        },
        ui:HGroup {
            ui:LineEdit {
                ID = "filePath2",
                PlaceholderText = "OFX IDs file path",
                -- Alignment = {AlignHCenter = true},
                -- Events = {ReturnPressed = true}
                Weight = 0.75,
                Text = config.Paths.unique_ids_path or ""
            },

            ui:Button {
                ID = "BrowseId",
                Text = "Browse",
                Weight = 0.25,
                -- Events = {Action = true}
            }
        },
        ui:CheckBox {
            ID = "exit",
            Text = "Exit on completion",
            Checked = true
        },
        ui:Button {
            ID = "Import",
            Text = "Import",
            Weight = 1
        }
    }
})

local itm = MainWindow:GetItems()

--[[
    GUI Interactions
]] --

function MainWindow.On.BrowseP.Clicked(ev)
    local folderPath = tostring(fu:RequestFile(
        "",
        {
            FReqS_Title = "Select a preset",
            FReqS_Filter = "JSON files (*.json)|*.json|All files (*.*)|*.*",
        }
    ))
    if folderPath then
        itm.filePath1.Text = folderPath
        -- Update the configuration with the new path
        config.Paths.recent_preset_path = folderPath
        save_config(config_file, config)
    end
end

function MainWindow.On.BrowseId.Clicked(ev)
    local folderPath = tostring(fu:RequestFile(
        "",
        {
            FReqS_Title = "Select a preset",
            FReqS_Filter = "*.json",
        }
    ))
    if folderPath then
        itm.filePath2.Text = folderPath
        -- Update the configuration with the new path
        config.Paths.unique_ids_path = folderPath
        save_config(config_file, config)
    end
end

function MainWindow.On.Import.Clicked()
    -- Load JSON data from file
    -- local filePath = "C:/Users/martinko/OneDrive - MSFT/Documents/VFX/Vegas Pro/Exported Presets/!!!!!LACEX PURPLE BUILDUP.json"
    -- "C:/Users/martinko/OneDrive - MSFT/Documents/VFX/Vegas Pro/Exported Presets/!!!!!LACEX IMPACT BEFORE REVERSE.json"
    -- local fxIDsjson = readFile("C:\\Users\\martinko\\OneDrive - MSFT\\Documents\\VFX\\Vegas Pro\\Exported Presets\\!!!! UniqueIDs.json")
    local jsonData = readFile(itm.filePath1.Text)
    local fxIDsjson = readFile(itm.filePath2.Text)

    -- Parse JSON data
    local data, pos, err = json.decode(jsonData, 1, nil)
    if err then
        print("Error:", err)
    else
        print("Data loaded successfully")
        -- You can now use the 'data' table
    end
    local fxIDs, pos1, err1 = json.decode(fxIDsjson, 1, nil)
    if err1 then
        print("Error:", err1)
    else
        print("Data loaded successfully")
        -- You can now use the 'data' table
    end

    comp:Lock()
    Main(data, fxIDs)
    comp:Unlock()

    if itm.exit.Checked then
        disp:ExitLoop()
    end
end

function MainWindow.On.MainWindow.Close(ev)
    disp:ExitLoop()
end

MainWindow:Show()
disp:RunLoop()
MainWindow:Hide()

print("Script executed successfully")

-- get ofx id from selected tools
-- for i, tool in ipairs(comp:GetToolList(true)) do
--     print(tool.ID)
-- end
