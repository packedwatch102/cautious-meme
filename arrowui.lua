--[[

Credit to original creator
This is a modified version 

CHANGES:
[+] When moving through menu, skips "Categories"
[+] Displays "<...>" when changing keybind
[+] Unwanted movement in UI when toggled (you could use arrow keys to enable/disable & move in ui when closed)
[+] Removed unwanted callback when using keybind
[+] Hideable tabs
[+] Adding new tab returns indexable number _G["Layout"][indexNumber]
[+] Hold key for fast selection
[+] Better handling of variables when creating tabs {name = "name", default = true}

KNOWN ISSUES:
[*] Calling twice gives unknown error
[*] Movement in menu while chatting

]]--
for i,v in pairs(_G) do
    if tostring(i) == "Layout" and #v ~= 0 then
        return
    end
end

-- BASE FUNCTIONS
local v2 = Vector2.new
local u2 = UDim2.new
local drawing = Drawing.new
local RGB = Color3.fromRGB
-- MATH FUNCTIONS
local clamp = math.clamp
local round = math.round
local abs = math.abs
local random = math.random
local floor = math.floor

--START
local function NewSquare(position, color, transparency)
    local b = drawing("Square")
    b.Position = position
    b.Size = v2(0, 0)
    b.Color = color
    b.Visible = true
    b.Filled = true
    b.Thickness = 0
    b.Transparency = transparency
    return b
end

local function NewText(position, color, text, text_size)
    local t = drawing("Text")
    t.Position = position
    t.Size = text_size
    t.Text = text
    t.Font = 3
    t.Color = color
    t.Visible = true
    t.Transparency = 1
    return t
end

local function CreateTextBox(text, back_color, back_transparency, text_color, text_size, pos, info)

    local b = NewSquare(pos, back_color, back_transparency)
    local t = NewText(v2(0, 0), text_color, text, text_size)

    local margin = 2
    b.Size = v2(t.TextBounds.X+margin*4, t.TextBounds.Y+margin*2)
    t.Position = v2(pos.X+margin*2, pos.Y+margin)

    if info.Type == "Toggle" then
        local newpos = v2(b.Position.X + b.Size.X, b.Position.Y)

        local b2 = NewSquare(newpos, back_color, back_transparency)
        local t2 = NewText(v2(0, 0), RGB(255, 255, 255), "<off>", text_size)

        b2.Size = v2(t2.TextBounds.X+margin*4, t2.TextBounds.Y+margin*2)
        t2.Position = v2(newpos.X+margin, newpos.Y+margin)

        return {["Main"] = b, ["Text"] = t, ["Extra"] = {["Main"] = b2, ["Text"] = t2}}
    elseif info.Type == "Slider" then
        local newpos = v2(b.Position.X + b.Size.X, b.Position.Y)

        local b2 = NewSquare(newpos, back_color, back_transparency)
        local t2 = NewText(v2(0, 0), RGB(255, 255, 255), "< 0"..info.Suffix.." >", text_size)
        t2.Center = true

        b2.Size = v2(t2.TextBounds.X+margin*4, t2.TextBounds.Y+margin*2)
        t2.Position = v2(newpos.X+margin+t2.TextBounds.X/2, newpos.Y+margin)

        return {["Main"] = b, ["Text"] = t, ["Extra"] = {["Main"] = b2, ["Text"] = t2}}
    elseif info.Type == "Dropdown" then
        local newpos = v2(b.Position.X + b.Size.X, b.Position.Y)

        local b2 = NewSquare(newpos, back_color, back_transparency)
        local t2 = NewText(v2(0, 0), RGB(255, 255, 255), "testtext", text_size)
        t2.Center = true

        b2.Size = v2(t2.TextBounds.X+margin*4, t2.TextBounds.Y+margin*2)
        t2.Position = v2(newpos.X+margin+t2.TextBounds.X/2, newpos.Y+margin)

        return {["Main"] = b, ["Text"] = t, ["Extra"] = {["Main"] = b2, ["Text"] = t2}}
    elseif info.Type == "Colorpicker" then
        local newpos = v2(b.Position.X + b.Size.X, b.Position.Y)

        local b2 = NewSquare(newpos, back_color, back_transparency)
        local t2 = NewText(v2(0, 0), RGB(255, 255, 255), "<   >", text_size)
        local p2 = NewSquare(newpos, RGB(0,0,0), 1)
        p2.Size = v2(9, 9)
        p2.Color = info.Color

        t2.Center = true

        b2.Size = v2(t2.TextBounds.X+margin*4, t2.TextBounds.Y+margin*2)
        t2.Position = v2(newpos.X+margin+t2.TextBounds.X/2, newpos.Y+margin)

        p2.Position = v2(t2.Position.X-p2.Size.X/2, b2.Position.Y+b2.Size.Y/2-p2.Size.Y/2)

        return {["Main"] = b, ["Text"] = t, ["Extra"] = {["Main"] = b2, ["Text"] = t2, ["Preview"] = p2}}
    elseif info.Type == "Keybind" then
        local newpos = v2(b.Position.X + b.Size.X, b.Position.Y)

        local b2 = NewSquare(newpos, back_color, back_transparency)
        local t2 = NewText(v2(0, 0), RGB(255, 255, 255), "Home", text_size)
        t2.Center = true

        b2.Size = v2(t2.TextBounds.X+margin*4, t2.TextBounds.Y+margin*2)
        t2.Position = v2(newpos.X+margin+t2.TextBounds.X/2, newpos.Y+margin)

        return {["Main"] = b, ["Text"] = t, ["Extra"] = {["Main"] = b2, ["Text"] = t2}}
    end

    return {["Main"] = b, ["Text"] = t}
end

local function Count(tbl)
    local c = 0
    for i, v in pairs(tbl) do
        c = c + 1
    end
    return c
end

-- LIBRARY START
local Keys = {Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.Left, Enum.KeyCode.Right}
local ContextActionService = game:GetService("ContextActionService")

ContextActionService:BindActionAtPriority("DisableArrowKeys", function() return Enum.ContextActionResult.Sink end, false, Enum.ContextActionPriority.High.Value, unpack(Keys))

local DESTROY_GUI = false

_G["Layout"] = {}

_G["Theme"] = { 
    ["UI_Position"] = v2(100, 100),
    ["Text_Size"] = 15,

    ["Category_Text"] = RGB(255, 255, 255),
    ["Category_Back"] = RGB(0, 0, 0),
    ["Category_Back_Transparency"] = 0.75,

    ["Option_Text"] = RGB(255, 255, 255),
    ["Option_Back"] = RGB(0, 0, 0),
    ["Option_Back_Transparency"] = 0.75,

    ["Selected_Color"] = RGB(255, 225, 50)
}

local function GetNewYCoord()
    local y = _G["Theme"]["UI_Position"].Y
    for i,v in pairs(_G["Layout"]) do
        if v["Hide"] == false then
            y = y + v["Drawings"]["Main"].Size.Y
        end
    end
    return y
end

local selected = 1
local n = #_G["Layout"]

local Library = {}
function Library:UpdateTheme()
    for i = 1, #_G["Layout"] do
        local v = _G["Layout"][i]
        if i == selected then
            if v["Type"] == "Category" then
                v["Drawings"]["Main"].Color = _G["Theme"]["Category_Back"]
                v["Drawings"]["Main"].Transparency = _G["Theme"]["Category_Back_Transparency"]
                v["Drawings"]["Text"].Color = _G["Theme"]["Selected_Color"]
                v["Drawings"]["Text"].Size = _G["Theme"]["Text_Size"]
            else
                v["Drawings"]["Main"].Color = _G["Theme"]["Option_Back"]
                v["Drawings"]["Main"].Transparency = _G["Theme"]["Option_Back_Transparency"]
                v["Drawings"]["Text"].Color = _G["Theme"]["Selected_Color"]
                v["Drawings"]["Text"].Size = _G["Theme"]["Text_Size"]
                if v["Type"] == "Toggle" or v["Type"] == "Slider" or v["Type"] == "Dropdown" or v["Type"] == "Colorpicker" or v["Type"] == "Keybind" then
                    v["Drawings"]["Extra"]["Main"].Color = _G["Theme"]["Option_Back"]
                    v["Drawings"]["Extra"]["Main"].Transparency = _G["Theme"]["Option_Back_Transparency"]
                    v["Drawings"]["Extra"]["Text"].Color = _G["Theme"]["Selected_Color"]
                    v["Drawings"]["Extra"]["Text"].Size = _G["Theme"]["Text_Size"]
                end
            end
        else
            if v["Type"] == "Category" then
                v["Drawings"]["Main"].Color = _G["Theme"]["Category_Back"]
                v["Drawings"]["Main"].Transparency = _G["Theme"]["Category_Back_Transparency"]
                v["Drawings"]["Text"].Color = _G["Theme"]["Category_Text"]
                v["Drawings"]["Text"].Size = _G["Theme"]["Text_Size"]
            else
                v["Drawings"]["Main"].Color = _G["Theme"]["Option_Back"]
                v["Drawings"]["Main"].Transparency = _G["Theme"]["Option_Back_Transparency"]
                v["Drawings"]["Text"].Color = _G["Theme"]["Option_Text"]
                v["Drawings"]["Text"].Size = _G["Theme"]["Text_Size"]
                if v["Type"] == "Toggle" or v["Type"] == "Slider" or v["Type"] == "Dropdown" or v["Type"] == "Colorpicker" or v["Type"] == "Keybind" then
                    v["Drawings"]["Extra"]["Main"].Color = _G["Theme"]["Option_Back"]
                    v["Drawings"]["Extra"]["Main"].Transparency = _G["Theme"]["Option_Back_Transparency"]
                    v["Drawings"]["Extra"]["Text"].Color = _G["Theme"]["Option_Text"]
                    v["Drawings"]["Extra"]["Text"].Size = _G["Theme"]["Text_Size"]
                end
            end
        end
    end
end

local active = true
function Library:Toggle()
    active = not active
    for i = 1, #_G["Layout"] do
        local v = _G["Layout"][i]
        if v["Hide"] == false then
            if v["Type"] == "Category" then
                v["Drawings"]["Main"].Visible = active
                v["Drawings"]["Text"].Visible = active
            else
                v["Drawings"]["Main"].Visible = active
                v["Drawings"]["Text"].Visible = active
                if v["Type"] == "Toggle" or v["Type"] == "Slider" or v["Type"] == "Dropdown" or v["Type"] == "Keybind" then
                    v["Drawings"]["Extra"]["Main"].Visible = active
                    v["Drawings"]["Extra"]["Text"].Visible = active
                elseif v["Type"] == "Colorpicker" then
                    v["Drawings"]["Extra"]["Main"].Visible = active
                    v["Drawings"]["Extra"]["Text"].Visible = active
                    v["Drawings"]["Extra"]["Preview"].Visible = active
                end
            end
        end
    end
end

function Library:PlaceUI()
    local current_y = _G["Theme"]["UI_Position"].Y
    for i = 1, #_G["Layout"] do
        local v = _G["Layout"][i]
        if active then
                if v["Type"] == "Category" then
                v["Drawings"]["Main"].Visible = not v["Hide"]
                v["Drawings"]["Text"].Visible = not v["Hide"]
            else
                v["Drawings"]["Main"].Visible = not v["Hide"]
                v["Drawings"]["Text"].Visible = not v["Hide"]
                if v["Type"] == "Toggle" or v["Type"] == "Slider" or v["Type"] == "Dropdown" or v["Type"] == "Keybind" then
                    v["Drawings"]["Extra"]["Main"].Visible = not v["Hide"]
                    v["Drawings"]["Extra"]["Text"].Visible = not v["Hide"]
                elseif v["Type"] == "Colorpicker" then
                    v["Drawings"]["Extra"]["Main"].Visible = not v["Hide"]
                    v["Drawings"]["Extra"]["Text"].Visible = not v["Hide"]
                    v["Drawings"]["Extra"]["Preview"].Visible = not v["Hide"]
                end
            end
        end
        if v["Type"] == "Toggle" or v["Type"] == "Slider" or v["Type"] == "Dropdown" or v["Type"] == "Keybind" then
            local pos = v2(_G["Theme"]["UI_Position"].X+10, current_y)

            local b = v["Drawings"]["Main"]
            local t = v["Drawings"]["Text"]

            local margin = 2

            b.Position = pos
            b.Size = v2(t.TextBounds.X+margin*4, t.TextBounds.Y+margin*2)
            t.Position = v2(pos.X+margin*2, pos.Y+margin)

            local newpos = v2(b.Position.X + b.Size.X, b.Position.Y)

            local b2 = v["Drawings"]["Extra"]["Main"]
            local t2 = v["Drawings"]["Extra"]["Text"]

            if v["Type"] == "Toggle" then
                t2.Text = "<off>"
            elseif v["Type"] == "Dropdown" then
                t2.Text = "testtext"
            elseif v["Type"] == "Slider" then
                local suff = v["Suffix"]
                t2.Text = "< 0"..v["Suffix"].." >"
            elseif v["Type"] == "Keybind" then
                t2.Text = "Home"
            end

            b2.Position = newpos
            t2.Center = true

            b2.Size = v2(t2.TextBounds.X+margin*4, t2.TextBounds.Y+margin*2)
            t2.Position = v2(newpos.X+margin+t2.TextBounds.X/2, newpos.Y+margin)
        elseif v["Type"] == "Category" then
            local pos = v2(_G["Theme"]["UI_Position"].X, current_y)

            local b = v["Drawings"]["Main"]
            local t = v["Drawings"]["Text"]

            local margin = 2

            b.Position = pos
            b.Size = v2(t.TextBounds.X+margin*4, t.TextBounds.Y+margin*2)
            t.Position = v2(pos.X+margin*2, pos.Y+margin)
        elseif v["Type"] == "Label" or v["Type"] == "Button" then
            local pos = v2(_G["Theme"]["UI_Position"].X+10, current_y)

            local b = v["Drawings"]["Main"]
            local t = v["Drawings"]["Text"]

            local margin = 2

            b.Position = pos
            b.Size = v2(t.TextBounds.X+margin*4, t.TextBounds.Y+margin*2)
            t.Position = v2(pos.X+margin*2, pos.Y+margin)
        elseif v["Type"] == "Colorpicker" then
            local pos = v2(_G["Theme"]["UI_Position"].X+10, current_y)

            local b = v["Drawings"]["Main"]
            local t = v["Drawings"]["Text"]

            local margin = 2
            b.Position = pos
            b.Size = v2(t.TextBounds.X+margin*4, t.TextBounds.Y+margin*2)
            t.Position = v2(pos.X+margin*2, pos.Y+margin)

            local newpos = v2(b.Position.X + b.Size.X, b.Position.Y)

            local b2 = v["Drawings"]["Extra"]["Main"]
            local t2 = v["Drawings"]["Extra"]["Text"]
            local p2 = v["Drawings"]["Extra"]["Preview"]

            t2.Text = "<   >"
            t2.Center = true

            b2.Position = newpos
            b2.Size = v2(t2.TextBounds.X+margin*4, t2.TextBounds.Y+margin*2)
            t2.Position = v2(newpos.X+margin+t2.TextBounds.X/2, newpos.Y+margin)

            p2.Position = v2(t2.Position.X-p2.Size.X/2, b2.Position.Y+b2.Size.Y/2-p2.Size.Y/2)
        end
        if v["Hide"] == false then
            current_y = current_y + v["Drawings"]["Main"].Size.Y
        else
            current_y = current_y
        end
    end
end

_G.Picker_Colors = {
    [1] = RGB(255, 0, 0),
    [2] = RGB(255, 136, 0),
    [3] = RGB(255, 255, 0),
    [4] = RGB(160, 255, 0),
    [5] = RGB(0, 255, 0),
    [6] = RGB(0, 255, 195),
    [7] = RGB(0, 213, 255),
    [8] = RGB(0, 145, 255),
    [9] = RGB(0, 60, 255),
    [10] = RGB(102, 0, 255),
    [11] = RGB(162, 0, 255),
    [12] = RGB(221, 0, 255),
    [13] = RGB(255, 0, 128),
    [14] = RGB(255, 255, 255),
    [15] = RGB(165, 165, 165),
    [16] = RGB(107, 107, 107),
    [17] = RGB(61, 61, 61),
    [18] = RGB(0, 0, 0)
}

function Library:Reset()
    Library:UpdateTheme()
    Library:PlaceUI()
    n = #_G["Layout"]
    for i = 1, n do
        local v = _G["Layout"][i]
        if i == selected then
            if v["Type"] == "Toggle" then
                if v["ENABLED"] == true then
                    v["Drawings"]["Extra"]["Text"].Text = "<on>"
                else 
                    v["Drawings"]["Extra"]["Text"].Text = "<off>"
                end
            elseif v["Type"] == "Slider" then
                v["Drawings"]["Extra"]["Text"].Text = "<"..v["VALUE"]..v["Suffix"]..">"

                local newpos = v["Drawings"]["Extra"]["Main"].Position
                local margin = 2
                local b2 = v["Drawings"]["Extra"]["Main"]
                local t2 = v["Drawings"]["Extra"]["Text"]
                b2.Size = v2(t2.TextBounds.X+margin*4, t2.TextBounds.Y+margin*2)
                t2.Position = v2(newpos.X+margin+t2.TextBounds.X/2, newpos.Y+margin)
            elseif v["Type"] == "Dropdown" then
                local current = v["Selected"]
                v["Drawings"]["Extra"]["Text"].Text = "<"..v["OPTIONS"][current]..">"

                local newpos = v["Drawings"]["Extra"]["Main"].Position
                local margin = 2
                local b2 = v["Drawings"]["Extra"]["Main"]
                local t2 = v["Drawings"]["Extra"]["Text"]
                b2.Size = v2(t2.TextBounds.X+margin*4, t2.TextBounds.Y+margin*2)
                t2.Position = v2(newpos.X+margin+t2.TextBounds.X/2, newpos.Y+margin)
            elseif v["Type"] == "Keybind" then
                local current = string.sub(tostring(v["Keybind"]), 14, #tostring(v["Keybind"]))
                v["Drawings"]["Extra"]["Text"].Text = "<"..current..">"

                local newpos = v["Drawings"]["Extra"]["Main"].Position
                local margin = 2
                local b2 = v["Drawings"]["Extra"]["Main"]
                local t2 = v["Drawings"]["Extra"]["Text"]
                b2.Size = v2(t2.TextBounds.X+margin*4, t2.TextBounds.Y+margin*2)
                t2.Position = v2(newpos.X+margin+t2.TextBounds.X/2, newpos.Y+margin)
            end
        else 
            if v["Type"] == "Toggle" then
                if v["ENABLED"] == true then
                    v["Drawings"]["Extra"]["Text"].Text = "<on>"
                else 
                    v["Drawings"]["Extra"]["Text"].Text = "<off>"
                end
            elseif v["Type"] == "Slider" then
                v["Drawings"]["Extra"]["Text"].Text = "<"..v["VALUE"]..v["Suffix"]..">"

                local newpos = v["Drawings"]["Extra"]["Main"].Position
                local margin = 2
                local b2 = v["Drawings"]["Extra"]["Main"]
                local t2 = v["Drawings"]["Extra"]["Text"]
                b2.Size = v2(t2.TextBounds.X+margin*4, t2.TextBounds.Y+margin*2)
                t2.Position = v2(newpos.X+margin+t2.TextBounds.X/2, newpos.Y+margin)
            elseif v["Type"] == "Dropdown" then
                local current = v["Selected"]
                v["Drawings"]["Extra"]["Text"].Text = "<"..v["OPTIONS"][current]..">"

                local newpos = v["Drawings"]["Extra"]["Main"].Position
                local margin = 2
                local b2 = v["Drawings"]["Extra"]["Main"]
                local t2 = v["Drawings"]["Extra"]["Text"]
                b2.Size = v2(t2.TextBounds.X+margin*4, t2.TextBounds.Y+margin*2)
                t2.Position = v2(newpos.X+margin+t2.TextBounds.X/2, newpos.Y+margin)
            elseif v["Type"] == "Keybind" then
                local current = string.sub(tostring(v["Keybind"]), 14, #tostring(v["Keybind"]))
                v["Drawings"]["Extra"]["Text"].Text = "<"..current..">"

                local newpos = v["Drawings"]["Extra"]["Main"].Position
                local margin = 2
                local b2 = v["Drawings"]["Extra"]["Main"]
                local t2 = v["Drawings"]["Extra"]["Text"]
                b2.Size = v2(t2.TextBounds.X+margin*4, t2.TextBounds.Y+margin*2)
                t2.Position = v2(newpos.X+margin+t2.TextBounds.X/2, newpos.Y+margin)
            end
        end
    end
end

Library:Reset()
local UIS = game:GetService("UserInputService")
local holdingButtons = {}
local c
local b
c = UIS.InputBegan:Connect(function(input, gameProcessedEvent)
    if active and (not gameProcessedEvent or (input.KeyCode == Enum.KeyCode.Up or input.KeyCode == Enum.KeyCode.Down or input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.Right)) then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode == Enum.KeyCode.Up then
                local currentTime = os.clock()
                holdingButtons[input.KeyCode] = {true, currentTime}
                local goingup = false
                while holdingButtons[input.KeyCode][1] and holdingButtons[input.KeyCode][2] == currentTime do
                    selected = clamp(selected - 1, 1, n-1)
                    if selected == 1 or _G["Layout"][selected].Hide then
                        local found = false
                        for indexnum = #_G["Layout"], 1, -1 do
                            if _G["Layout"][indexnum].Type ~= "Category" and _G["Layout"][indexnum].Hide == false then
                                selected = indexnum
                                found = true
                                break
                            end
                        end
                        if not found then
                            selected = 1
                        end
                    else
                        if _G["Layout"][selected].Type == "Category" or _G["Layout"][selected].Hide == true then
                            for indexnum = selected, 1, -1 do
                                if _G["Layout"][indexnum].Type ~= "Category" and _G["Layout"][indexnum].Hide == false then
                                    selected = indexnum
                                    break
                                end
                            end
                        end
                    end
                    Library:Reset()
                    if not goingup then
                        if holdingButtons[input.KeyCode][1] then
                            repeat task.wait() until not holdingButtons[input.KeyCode][1] or (os.clock() - holdingButtons[input.KeyCode][2]) > 0.3
                            goingup = true
                            task.wait(0.1)
                        end
                    elseif goingup then
                        task.wait(0.1)
                    end
                    task.wait()
                end
            end
            if input.KeyCode == Enum.KeyCode.Left then
                local currentTime = os.clock()
                holdingButtons[input.KeyCode] = {true, currentTime}
                local goingup = false
                n = #_G["Layout"]
                for i = 1, n do
                    local v = _G["Layout"][i]
                    if i == selected then
                        if v["Type"] == "Toggle" then
                            v["ENABLED"] = not v["ENABLED"]
                            v["CallBack"](v["ENABLED"])
                            Library:Reset()
                        elseif v["Type"] == "Slider" then
                            while holdingButtons[input.KeyCode][1] and holdingButtons[input.KeyCode][2] == currentTime and i == selected do
                                local str = "1"
                                for i = 1, v["Decimals"] do 
                                    str = str.."0"
                                end
                                local newval = clamp(round((v["VALUE"] - v["Increment"])* tonumber(str))/tonumber(str), v["Min"], v["Max"])
                                v["VALUE"] = newval
                                v["CallBack"](newval)
                                Library:Reset()
                                if not goingup then
                                    if holdingButtons[input.KeyCode][1] then
                                        repeat task.wait() until not holdingButtons[input.KeyCode][1] or (os.clock() - holdingButtons[input.KeyCode][2]) > 0.3
                                        goingup = true
                                        task.wait(0.03)
                                    end
                                elseif goingup then
                                    task.wait(0.03)
                                end
                                task.wait()
                            end
                        elseif v["Type"] == "Dropdown" then
                            while holdingButtons[input.KeyCode][1] and holdingButtons[input.KeyCode][2] == currentTime and i == selected do
                                local n = #v["OPTIONS"]
                                local current = v["Selected"]

                                current = current - 1
                                if current == 0 then
                                    current = n
                                end
                                v["Selected"] = current
                                v["CallBack"](v["OPTIONS"][current])
                                Library:Reset()
                                if not goingup then
                                    if holdingButtons[input.KeyCode][1] then
                                        repeat task.wait() until not holdingButtons[input.KeyCode][1] or (os.clock() - holdingButtons[input.KeyCode][2]) > 0.3
                                        goingup = true
                                        task.wait(0.1)
                                    end
                                elseif goingup then
                                    task.wait(0.1)
                                end
                                task.wait()
                            end
                        elseif v["Type"] == "Colorpicker" then
                            local n = #v["Colors"]
                            local current = v["Selected"]

                            current = current - 1
                            if current == 0 then
                                current = n
                            end
                            v["Selected"] = current
                            local col = v["Colors"][current]
                            v["Drawings"]["Extra"]["Preview"].Color = col
                            v["CallBack"](col)
                            Library:Reset()
                        end
                    end
                end
            end
            if input.KeyCode == Enum.KeyCode.Down then
                local currentTime = os.clock()
                holdingButtons[input.KeyCode] = {true, currentTime}
                local goingup = false
                while holdingButtons[input.KeyCode][1] and holdingButtons[input.KeyCode][2] == currentTime do
                    selected = clamp(selected + 1, 1, n+1)
                    if selected == n+1 then
                        local found = false
                        for indexnum = 1, #_G["Layout"] do
                            if _G["Layout"][indexnum].Type ~= "Category" and _G["Layout"][indexnum].Hide == false then
                                selected = indexnum
                                found = true
                                break
                            end
                        end
                        if not found then
                            selected = 1
                        end
                    else
                        if _G["Layout"][selected].Type == "Category" or _G["Layout"][selected].Hide == true then
                            for indexnum = selected, #_G["Layout"] do
                                if _G["Layout"][indexnum].Type ~= "Category" and _G["Layout"][indexnum].Hide == false then
                                    selected = indexnum
                                    break
                                end
                            end
                        end
                    end
                    Library:Reset()
                    if not goingup then
                        if holdingButtons[input.KeyCode][1] then
                            repeat task.wait() until not holdingButtons[input.KeyCode][1] or (os.clock() - holdingButtons[input.KeyCode][2]) > 0.3
                            goingup = true
                            task.wait(0.1)
                        end
                    elseif goingup then
                        task.wait(0.1)
                    end
                    task.wait()
                end
            end
            if input.KeyCode == Enum.KeyCode.Right then
                local currentTime = os.clock()
                holdingButtons[input.KeyCode] = {true, currentTime}
                local goingup = false
                n = #_G["Layout"]
                for i = 1, n do
                    local v = _G["Layout"][i]
                    if i == selected then
                            if v["Type"] == "Button" then
                                v["CallBack"]()
                                Library:Reset()
                            elseif v["Type"] == "Slider" then
                                while holdingButtons[input.KeyCode][1] and holdingButtons[input.KeyCode][2] == currentTime and i == selected do
                                    local str = "1"
                                    for i = 1, v["Decimals"] do 
                                        str = str.."0"
                                    end
                                    local newval = clamp(round((v["VALUE"] + v["Increment"])* tonumber(str))/tonumber(str), v["Min"], v["Max"])
                                    v["VALUE"] = newval
                                    v["CallBack"](newval)
                                    Library:Reset()
                                    if not goingup then
                                        if holdingButtons[input.KeyCode][1] then
                                            repeat task.wait() until not holdingButtons[input.KeyCode][1] or (os.clock() - holdingButtons[input.KeyCode][2]) > 0.3
                                            goingup = true
                                            task.wait(0.03)
                                        end
                                    elseif goingup then
                                        task.wait(0.03)
                                    end
                                    task.wait()
                                end
                            elseif v["Type"] == "Toggle" then
                                v["ENABLED"] = not v["ENABLED"]
                                v["CallBack"](v["ENABLED"])
                                Library:Reset()
                            elseif v["Type"] == "Dropdown" then
                                while holdingButtons[input.KeyCode][1] and holdingButtons[input.KeyCode][2] == currentTime and i == selected do
                                    local n = #v["OPTIONS"]
                                    local current = v["Selected"]

                                    current = current + 1
                                    if current == n+1 then
                                        current = 1
                                    end
                                    v["Selected"] = current
                                    v["CallBack"](v["OPTIONS"][current])
                                    Library:Reset()
                                    if not goingup then
                                        if holdingButtons[input.KeyCode][1] then
                                            repeat task.wait() until not holdingButtons[input.KeyCode][1] or (os.clock() - holdingButtons[input.KeyCode][2]) > 0.3
                                            goingup = true
                                            task.wait(0.1)
                                        end
                                    elseif goingup then
                                        task.wait(0.1)
                                    end
                                    task.wait()
                                end
                            elseif v["Type"] == "Colorpicker" then
                                local n = #v["Colors"]
                                local current = v["Selected"]

                                current = current + 1
                                if current == n+1 then
                                    current = 1
                                end
                                v["Selected"] = current
                                local col = v["Colors"][current]
                                v["Drawings"]["Extra"]["Preview"].Color = col
                                v["CallBack"](col)
                                Library:Reset()
                            elseif v["Type"] == "Keybind" then
                                local replace = ""
                                for k = 1, #(v["Drawings"]["Extra"]["Text"].Text) do
                                    replace = replace .. "_"
                                end
                                v["Drawings"]["Extra"]["Text"].Text = replace
                                local oldbind = v["Keybind"]
                                v["Keybind"] = "             ..."
                                Library:Reset()
                                local c
                                c = UIS.InputBegan:Connect(function(input2, gameProcessedEvent)
                                    if DESTROY_GUI then
                                        c:Disconnect()
                                    elseif input2.UserInputType == Enum.UserInputType.Keyboard then
                                        if not gameProcessedEvent or (input2.KeyCode ~= Enum.KeyCode.Up and input2.KeyCode ~= Enum.KeyCode.Down and input2.KeyCode ~= Enum.KeyCode.Left and input2.KeyCode ~= Enum.KeyCode.Right) then
                                            v["Keybind"] = input2.KeyCode
                                            v["CallBack"](input2.KeyCode)
                                            v["ChangeTime"] = tick()
                                            Library:Reset()
                                            c:Disconnect()
                                        else
                                            v["Keybind"] = oldbind
                                            --v["CallBack"](oldbind)
                                            Library:Reset()
                                            c:Disconnect()
                                        end
                                    end
                                end)
                            end
                    end
                end
            end
            -- if input.KeyCode == Enum.KeyCode.End then
            --     Library:Toggle()
            -- end
        end
    end
end)

b = UIS.InputEnded:Connect(function(input, gameProcessedEvent)
    if active and (not gameProcessedEvent or (input.KeyCode == Enum.KeyCode.Up or input.KeyCode == Enum.KeyCode.Down or input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.Right)) then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            if holdingButtons[input.KeyCode] then
                holdingButtons[input.KeyCode] = {false}
            end
        end
    end
end)




spawn(function()
    while wait() do
        if DESTROY_GUI then
            c:Disconnect()
        end
    end
end)



function Library:NewCategory(info)
    local val = #_G["Layout"]+1
    local new_y = GetNewYCoord()
    local catname = typeof(info.name) == "string" and info.name or ""
    _G["Layout"][val] = {
        ["Type"] = "Category",
        ["Drawings"] = CreateTextBox(catname, RGB(10, 10, 10), 0.75, RGB(255, 255, 255), _G["Theme"]["Text_Size"], v2(_G["Theme"]["UI_Position"].X, new_y), {Type = "Category"}),
        ["Hide"] = typeof(info.hiding) == "boolean" and info.hiding or false
    }
    Library:Reset()

    local cat_funcs = {}

    function cat_funcs:NewButton(info)
        local val = #_G["Layout"]+1
        local new_y = GetNewYCoord()
        local buttonname = typeof(info.name) == "string" and info.name or ""
        _G["Layout"][val] = {
            ["Type"] = "Button",
            ["Drawings"] = CreateTextBox(buttonname, RGB(10, 10, 10), 0.75, RGB(255, 255, 255), _G["Theme"]["Text_Size"], v2(_G["Theme"]["UI_Position"].X+10, new_y), {Type = "Button"}),
            ["CallBack"] = typeof(info.callback) == "function" and info.callback or function() end,
            ["Hide"] = typeof(info.hiding) == "boolean" and info.hiding or false
        }
        Library:Reset()
        return val
    end

    function cat_funcs:NewToggle(info)
        local val = #_G["Layout"]+1
        local new_y = GetNewYCoord()
        local buttonname = typeof(info.name) == "string" and info.name or ""
        _G["Layout"][val] = {
            ["ENABLED"] = typeof(info.default) == "boolean" and info.default or false,
            ["Type"] = "Toggle",
            ["Drawings"] = CreateTextBox(buttonname, RGB(10, 10, 10), 0.75, RGB(255, 255, 255), _G["Theme"]["Text_Size"], v2(_G["Theme"]["UI_Position"].X+10, new_y), {Type = "Toggle"}),
            ["CallBack"] = typeof(info.callback) == "function" and info.callback or function() end,
            ["Hide"] = typeof(info.hiding) == "boolean" and info.hiding or false
        }
        Library:Reset()
        local toggle_funcs = {}
        function toggle_funcs:Toggle()
            n = #_G["Layout"]
            for i = 1, n do
                local v = _G["Layout"][i]
                if v["Type"] == "Toggle" and i == val then
                    v["ENABLED"] = not v["ENABLED"]
                    v["CallBack"](v["ENABLED"])
                    Library:Reset()
                end
            end
        end
        return val, toggle_funcs
    end

    function cat_funcs:NewSlider(info)
        local suff = typeof(info.suffix) == "string" and info.suffix or ""
        local val = #_G["Layout"]+1
        local new_y = GetNewYCoord()
        local buttonname = typeof(info.name) == "string" and info.name or ""
        _G["Layout"][val] = {
            ["VALUE"] = typeof(info.default) == "number" and info.default or 1,
            ["Type"] = "Slider",
            ["Increment"] = typeof(info.increment) == "number" and info.increment or 0.1,
            ["Min"] = typeof(info.min) == "number" and info.min or 0,
            ["Max"] = typeof(info.max) == "number" and info.max or 1,
            ["Decimals"] = typeof(info.decimal) == "number" and info.decimal or 1,
            ["Suffix"] = suff,
            ["Drawings"] = CreateTextBox(buttonname, RGB(10, 10, 10), 0.75, RGB(255, 255, 255), _G["Theme"]["Text_Size"], v2(_G["Theme"]["UI_Position"].X+10, new_y), {Type = "Slider", Suffix = suff}),
            ["CallBack"] = typeof(info.callback) == "function" and info.callback or function() end,
            ["Hide"] = typeof(info.hiding) == "boolean" and info.hiding or false
        }
        Library:Reset()
        return val
    end

    function cat_funcs:NewDropdown(info)
        local val = #_G["Layout"]+1
        local new_y = GetNewYCoord()
        local buttonname = typeof(info.name) == "string" and info.name or ""
        _G["Layout"][val] = {
            ["OPTIONS"] = typeof(info.options) == "table" and info.options or {"No", "Table", "Found"},
            ["Type"] = "Dropdown",
            ["Drawings"] = CreateTextBox(buttonname, RGB(10, 10, 10), 0.75, RGB(255, 255, 255), _G["Theme"]["Text_Size"], v2(_G["Theme"]["UI_Position"].X+10, new_y), {Type = "Dropdown"}),
            ["Selected"] = typeof(info.selected) == "number" and info.selected or 1,
            ["CallBack"] = typeof(info.callback) == "function" and info.callback or function() end,
            ["Hide"] = typeof(info.hiding) == "boolean" and info.hiding or false
        }
        Library:Reset()
        return val
    end

    function cat_funcs:NewColorpicker(info)
        local val = #_G["Layout"]+1
        local new_y = GetNewYCoord()
        local buttonname = typeof(info.name) == "string" and info.name or ""
        local default = typeof(info.default) == "Color3" and info.default or Color3.fromRGB(0,0,0)
        _G["Layout"][val] = {
            ["Colors"] = _G.Picker_Colors,
            ["Type"] = "Colorpicker",
            ["Drawings"] = CreateTextBox(buttonname, RGB(10, 10, 10), 0.75, RGB(255, 255, 255), _G["Theme"]["Text_Size"], v2(_G["Theme"]["UI_Position"].X+10, new_y), {Type = "Colorpicker", Color = default}),
            ["Selected"] = 1,
            ["CallBack"] = typeof(info.callback) == "function" and info.callback or function() end,
            ["Hide"] = typeof(info.hiding) == "boolean" and info.hiding or false
        }
        Library:Reset()
        return val
    end

    function cat_funcs:NewLabel(info)
        local val = #_G["Layout"]+1
        local new_y = GetNewYCoord()
        local buttonname = typeof(info.name) == "string" and info.name or ""
        _G["Layout"][val] = {
            ["Type"] = "Label",
            ["Drawings"] = CreateTextBox(buttonname, RGB(10, 10, 10), 0.75, RGB(255, 255, 255), _G["Theme"]["Text_Size"], v2(_G["Theme"]["UI_Position"].X+10, new_y), {Type = "Label"}),
            ["Hide"] = typeof(info.hiding) == "boolean" and info.hiding or false
        }
        Library:Reset()
        return val
    end

    function cat_funcs:NewKeybind(info)
        local default = typeof(info.keybind) == "EnumItem" and info.keybind or nil
        local val = #_G["Layout"]+1
        local new_y = GetNewYCoord()
        local buttonname = typeof(info.name) == "string" and info.name or ""
        _G["Layout"][val] = {
            ["Type"] = "Keybind",
            ["Drawings"] = CreateTextBox(buttonname, RGB(10, 10, 10), 0.75, RGB(255, 255, 255), _G["Theme"]["Text_Size"], v2(_G["Theme"]["UI_Position"].X+10, new_y), {Type = "Keybind", Keybind = default}),
            ["Keybind"] = default,
            ["CallBack"] = typeof(info.callback) == "function" and info.callback or function() end,
            ["ChangeTime"] = 0,
            ["Hide"] = typeof(info.hiding) == "boolean" and info.hiding or false
        }
        local c
        c = UIS.InputBegan:Connect(function(input, gameProcessedEvent)
            if DESTROY_GUI then
                c:Disconnect()
            elseif not gameProcessedEvent or (input.KeyCode == Enum.KeyCode.Up or input.KeyCode == Enum.KeyCode.Down or input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.Right) then
                if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == _G["Layout"][val]["Keybind"] and (tick() - _G["Layout"][val]["ChangeTime"]) > 0.01 then
                    local cb = typeof(info.callback) == "function" and info.callback or function() end
                    cb()
                end
            end
        end)
        Library:Reset()
        return val
    end
    return cat_funcs, val
end

function Library:Kill()
    for i, v in pairs(_G["Layout"]) do
        v["Drawings"]["Main"]:Remove()
        v["Drawings"]["Text"]:Remove()
        if v["Type"] == "Toggle" or v["Type"] == "Slider" or v["Type"] == "Dropdown" or v["Type"] == "Keybind" then
            v["Drawings"]["Extra"]["Main"]:Remove()
            v["Drawings"]["Extra"]["Text"]:Remove()
        elseif v["Type"] == "Colorpicker" then
            v["Drawings"]["Extra"]["Main"]:Remove()
            v["Drawings"]["Extra"]["Text"]:Remove()
            v["Drawings"]["Extra"]["Preview"]:Remove()
        end
    end
    DESTROY_GUI = true
    _G["Layout"] = {}
end
return Library
