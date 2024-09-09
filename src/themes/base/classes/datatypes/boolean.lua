--!strict

----------------------------------------------------------------------------------------------------------------

local types = require(script.Parent.Parent.Parent:WaitForChild("types"))

local input_option = require(script.Parent.Parent.input_option)

----------------------------------------------------------------------------------------------------------------

export type boolean_input_option = types.boolean_input_option
export type boolean_data = types.boolean_data
export type boolean_frame = types.boolean_frame

----------------------------------------------------------------------------------------------------------------

local function new(data : boolean_data) : (boolean, boolean_input_option?)
    local success, option_new = input_option(data)

    if not (option_new and success) then
        return false
    end

    --[[----------------------------------------------------------------------]]--

    local option = option_new :: boolean_input_option

    --[[----------------------------------------------------------------------]]--

    local function value_changed(new_value : boolean)
        local frame = option.frame.get()
        local checkbox = frame.button_frame.checkbox

        if new_value then
            checkbox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        else
            checkbox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        end
    end

    --[[----------------------------------------------------------------------]]--

    local function frame_init(frame : boolean_frame)
        frame.button_frame.checkbox.MouseButton1Click:Connect(function()
            option.set(not option.get())
        end)

        option.changed:Fire(option.get())
    end

    --[[----------------------------------------------------------------------]]--

    option.changed:Connect(value_changed)

    --[[----------------------------------------------------------------------]]--
    
    frame_init(option.frame.get())

    --[[----------------------------------------------------------------------]]--
    
    return true, option
end

----------------------------------------------------------------------------------------------------------------

return new

----------------------------------------------------------------------------------------------------------------