--!strict

----------------------------------------------------------------------------------------------------------------

local util = require(script.Parent.Parent.Parent:WaitForChild("util"))
local types = require(script.Parent.Parent.Parent:WaitForChild("types"))

local input_option = require(script.Parent.Parent:WaitForChild("input_option"))

----------------------------------------------------------------------------------------------------------------

export type string_input_option = types.string_input_option
export type string_data = types.string_data
export type input_frame = types.input_frame

----------------------------------------------------------------------------------------------------------------

local truncate = util.truncate
local props = util.props

----------------------------------------------------------------------------------------------------------------

local function new(data : string_data) : (boolean, string_input_option?)
    local success, option_new = input_option(data)

    if not (option_new and success) then
        return false
    end

    --[[----------------------------------------------------------------------]]--

    local option = option_new :: string_input_option

    --[[----------------------------------------------------------------------]]--

    local function focus_lost(enter_pressed : boolean)
        if not enter_pressed and option.enter_required.get() then
            option.frame.get().input.Text = option.get()
            return
        end

        local input_text = option.frame.get().input.Text

        option.set(input_text)
        option.frame.get().input.Text = option.get()
	end
	
	local function focused()
		option.focused:Fire()
	end

    --[[----------------------------------------------------------------------]]--

    local function value_changed(new_value : string)
        option.frame.get().input.Text = truncate(option.get(), option.max_length.get())
    end

    local function enabled_changed(new_value : boolean)
        local frame = option.frame.get()

        frame.input.TextEditable = new_value
        frame.input.Text = truncate(option.get(), option.max_length.get())
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