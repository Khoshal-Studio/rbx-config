--!strict

----------------------------------------------------------------------------------------------------------------

local util = require(script.Parent.Parent.Parent:WaitForChild("util"))
local types = require(script.Parent.Parent.Parent:WaitForChild("types"))

local input_option = require(script.Parent.Parent:WaitForChild("input_option"))

----------------------------------------------------------------------------------------------------------------

export type number_input_option = types.number_input_option
export type number_data = types.number_data
export type input_frame = types.input_frame

----------------------------------------------------------------------------------------------------------------

local props = util.props

----------------------------------------------------------------------------------------------------------------

local function new(data : number_data) : (boolean, number_input_option?)
    local success, option_new = input_option(data)
    
    if not (option_new and success) then
        return false
    end

    --[[----------------------------------------------------------------------]]--

    local option = option_new :: number_input_option

    --[[----------------------------------------------------------------------]]--

    local function focus_lost(enter_pressed : boolean)
        local frame = option.frame.get()
        local input = frame.input

        if not enter_pressed and option.enter_required.get() then
            input.Text = tostring(option.get())
            return
        end

        if input.Text == "" then
            option.set(0)
            return
        end

        local new_value = tonumber(input.Text)
        
        if not new_value then
            input.Text = tostring(option.get())
            return
        end
        
        option.set(new_value)
	end
	
	local function focused()
		option.focused:Fire()
	end

    --[[----------------------------------------------------------------------]]--
    
	local function value_changed(new_value : number)
        option.frame.get().input.Text = tostring(new_value)
    end

    local function enabled_changed(new_value : boolean)
        local frame = option.frame.get()

        frame.input.TextEditable = new_value
        frame.input.Text = tostring(option.get())
	end
    
    --[[----------------------------------------------------------------------]]--

    local function frame_init(frame : input_frame)
		frame.input.FocusLost:Connect(focus_lost)
		frame.input.Focused:Connect(focused)

        option.changed:Fire(option.get())
    end

    --[[----------------------------------------------------------------------]]--

    option.enter_required = props(if data.enter_required == nil then false else data.enter_required)

    --[[----------------------------------------------------------------------]]--

    option.changed:Connect(value_changed)
    option.enabled.changed:Connect(enabled_changed)

    --[[----------------------------------------------------------------------]]--
    
    frame_init(option.frame.get())

    --[[----------------------------------------------------------------------]]--
    
    return true, option
end

----------------------------------------------------------------------------------------------------------------

return new

----------------------------------------------------------------------------------------------------------------