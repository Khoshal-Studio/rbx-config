--!strict

----------------------------------------------------------------------------------------------------------------

local util = require(script.Parent.Parent.Parent:WaitForChild("util"))
local types = require(script.Parent.Parent.Parent:WaitForChild("types"))

local input_option = require(script.Parent.Parent:WaitForChild("input_option"))

----------------------------------------------------------------------------------------------------------------

local theme_presets = util.presets
local choice_template = theme_presets:WaitForChild("choice_template")

----------------------------------------------------------------------------------------------------------------

export type dropdown_input_option = types.dropdown_input_option
export type dropdown_data = types.dropdown_data
export type dropdown_frame = types.dropdown_frame
export type choice_template = types.choice_template

----------------------------------------------------------------------------------------------------------------

local find = table.find

local map_children_of_class = util.map_children_of_class
local clear_children_of_class = util.clear_children_of_class
local foreach = util.foreach
local package = util.package
local get_cancel_fn = util.get_cancel_fn

local props = util.props

local default_nil_placeholder = "Select an option."

----------------------------------------------------------------------------------------------------------------

local function close_dropdown(option : dropdown_input_option)
    local frame = option.frame.get()
	if not frame:FindFirstAncestorOfClass("ScreenGui") then return end
	
	option.focused:Fire()

    if frame.dropdown.choice:FindFirstChild("arrow_indicator") then
        frame.dropdown.choice.arrow_indicator.ImageRectOffset = Vector2.new(0, 0)
        frame.dropdown.choice.arrow_indicator.ImageRectSize = Vector2.new(0,0)    
    end
    
    frame.dropdown.options.Visible = false
end

local function open_dropdown(option : dropdown_input_option)
    local frame = option.frame.get()
	if not frame:FindFirstAncestorOfClass("ScreenGui") then return end
	
	option.focused:Fire()
    
    frame.dropdown.choice.arrow_indicator.ImageRectOffset = Vector2.new(0, 500)
    frame.dropdown.choice.arrow_indicator.ImageRectSize = Vector2.new(1000, -500)

    local current_value = option.get()

    map_children_of_class(frame.dropdown.options, "TextButton", function(child : TextButton)
        if child.Name == current_value then
            child.Visible = false
        else
            child.Visible = true
        end
    end)

    frame.dropdown.options.Visible = true
end

local function on_dropdown_toggle_click(option : dropdown_input_option)
    local frame = option.frame.get()
    if not option.enabled.get() then
        close_dropdown(option)
        frame.dropdown.choice.arrow_indicator.Visible = false
    end

    frame.dropdown.choice.arrow_indicator.Visible = true

    if frame.dropdown.options.Visible then
        close_dropdown(option)
    else
        open_dropdown(option)
    end
end

local function dropdown_option_click(option : dropdown_input_option, choice : string, close : () -> ())
    if choice == option.get() or not find(option.choices.get(), choice) then
        return
	end
	
	option.focused:Fire()

    option.set(choice)
    close()
end

local function generate_choices(option : dropdown_input_option)
    local frame = option.frame.get()
    clear_children_of_class(frame.dropdown.options, "TextButton")

    local choices = option.choices.get()

    foreach(choices, function(v : string)
        local choice = choice_template:Clone()

        choice.Name = v
        choice.option_name.Text = v

        choice.MouseButton1Click:Connect(function()
            dropdown_option_click(option, v, function()
                close_dropdown(option)
            end)
        end)

        choice.Parent = frame.dropdown.options
    end)
end

----------------------------------------------------------------------------------------------------------------

local function new(data : dropdown_data) : (boolean, dropdown_input_option?)
    local success, option_new = input_option(data)

    if not (option_new and success) then
        return false
    end

    --[[----------------------------------------------------------------------]]--

    local option = option_new :: dropdown_input_option

    --[[----------------------------------------------------------------------]]--

    local cancel = get_cancel_fn(option)

    --[[----------------------------------------------------------------------]]--

    local nil_placeholder_middleware = {
        set = {
            function (new_value : string)
                if find(option.choices.get(), new_value) then
                    warn("Nil placeholder found in choices", "\n", option.choices.get())
                    return cancel("nil_placeholder")
                end

                return package(new_value)
            end
        }
    }

    --[[----------------------------------------------------------------------]]--
    
    local function choices_changed(new_value : {string})
        generate_choices(option)
    end

    local function value_changed(new_value : string)
        local frame = option.frame.get()
        local choice_btn = frame.dropdown.choice

        choice_btn.option_name.Text = new_value or option.nil_placeholder.get()

        close_dropdown(option)
    end

    local function nil_placeholder_changed(new_value : string)
        option.frame.get().dropdown.choice.option_name.Text = option.get() or new_value
    end

    --[[----------------------------------------------------------------------]]--

    local function frame_init(frame : dropdown_frame)
        local choice_btn = frame.dropdown.choice

        choice_btn.MouseButton1Click:Connect(function()
            on_dropdown_toggle_click(option)
        end)

        option.changed:Fire(option.get())
        option.choices.changed:Fire(option.choices.get())
        option.nil_placeholder.changed:Fire(option.nil_placeholder.get())

        close_dropdown(option)
    end

    --[[----------------------------------------------------------------------]]--

    option.choices.middleware.set.add(function(new_value : {string})
        if find(new_value, option.nil_placeholder.get()) then
            warn("Nil placeholder found in choices", "\n", new_value)
            return cancel("choices")
        end

        return package(new_value)
    end)

    --[[----------------------------------------------------------------------]]--

    option.nil_placeholder = props(data.nil_placeholder or default_nil_placeholder, nil_placeholder_middleware)

    --[[----------------------------------------------------------------------]]--

    option.nil_placeholder.changed:Connect(nil_placeholder_changed)
    option.changed:Connect(value_changed)
    option.choices.changed:Connect(choices_changed)

    --[[----------------------------------------------------------------------]]--
    
    frame_init(option.frame.get())

    --[[----------------------------------------------------------------------]]--

    return true, option
end

----------------------------------------------------------------------------------------------------------------

return new

----------------------------------------------------------------------------------------------------------------