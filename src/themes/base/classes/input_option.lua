--!strict

----------------------------------------------------------------------------------------------------------------

local types = require(script.Parent.Parent:WaitForChild("types"))
local util = require(script.Parent.Parent:WaitForChild("util"))

----------------------------------------------------------------------------------------------------------------

local backend_classes = script.Parent.Parent.Parent.Parent:WaitForChild("classes")
local backend_datatypes = backend_classes:WaitForChild("datatypes")

----------------------------------------------------------------------------------------------------------------

type prop<T> = types.prop<T>

----------------------------------------------------------------------------------------------------------------

local format = string.format

local get_config = util.get_config
local get_desc_text = util.get_desc_text
local universal_valid_data = util.universal_valid_data
local option_type_from_data = util.option_type_from_data
local get_frame = util.get_frame
local is_natural = util.is_natural
local get_cancel_fn = util.get_cancel_fn
local package = util.package
local delete = util.delete

local props = util.props
local signal = util.signal

----------------------------------------------------------------------------------------------------------------

local function frame_init(option : types.input_option)
	option.key.changed:Fire(option.key.get())
	option.enabled.changed:Fire(option.enabled.get())
	option.visible.changed:Fire(option.visible.get())
	option.resetable.changed:Fire(option.resetable.get())
	option.layout_order.changed:Fire(option.layout_order.get())

	local frame = (option.frame :: any).get() :: types.config_datatype_frame_base

	local function on_focus(reset : boolean?)
		local config = get_config(option)

		if not config then
			return
		end

		local config_frame = config.frame.get()
		
		if reset then
			config_frame.config.sidebar.title.Text = ""
			config_frame.config.sidebar.info.description.Text = ""
			return
		end

		config_frame.config.sidebar.title.Text = option.key.get()
		config_frame.config.sidebar.info.description.Text = get_desc_text(option)
	end

	frame.InputBegan:Connect(function(input : InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local config = get_config(option)
			
			if not config then
				return
			end
			
			local config_frame = config.frame.get()
			
			if config_frame.config.sidebar.title.Text == option.key.get() then
				option.focused:Fire(true)
			else
				option.focused:Fire()
			end
		end
	end)
	
	option.focused:Connect(on_focus)

	frame.reset_btn.MouseButton1Click:Connect(function()
		(option :: any):reset()
	end)
	
	util.interface_util.ui_adjust(frame, false, true)
end

----------------------------------------------------------------------------------------------------------------

local function new(data : types.data) : (boolean, types.input_option?, prop<any>?)
    if not universal_valid_data(data) then
        return false
    end

    --[[----------------------------------------------------------------------]]--

    local option_type = option_type_from_data(data)
    local frame_initial = get_frame(data)

    --[[----------------------------------------------------------------------]]--

    local datatype_class = backend_datatypes:FindFirstChild(option_type) :: ModuleScript?

    if not datatype_class then
        warn("Could not find datatype class", "\n", option_type)
        return false
    end

    --[[----------------------------------------------------------------------]]--

    local success, option_base = (require(datatype_class) :: any)(data)
    local option = option_base :: types.input_option_root

    if not success and option_base then
        return false
    end

    local frame_prop = props(frame_initial)
	local focused_signal = signal()
	
    --[[----------------------------------------------------------------------]]--

    local function delete_option(self : types.input_option_root)
        self.frame.get():Destroy()

        delete(self)
        frame_prop.set(nil :: any, true)
        
        if self.__container then
            self.__container[self.key.get()] = nil
        end
    end

    local cancel = get_cancel_fn(option)

    --[[----------------------------------------------------------------------]]--

    local layout_order_info = {
        set = {
            function (value : number)
                if not is_natural(value) then
                    return cancel("layout_order")
                end

                return package(value)
            end
        }
    }

    --[[----------------------------------------------------------------------]]--

    local function key_str(key : string)
        local config = get_config(option)

        return format("%s%s%s",
         if config and config.requires_apply.get() and option.get() ~= option.original_value.get() then "* " else "",
         key, 
         if option.enabled.get() then "" else " (Disabled)"
        )
    end

    local function value_changed(new_value : any)
        local frame = option.frame.get() :: any

        frame.option_name.Text = key_str(option.key.get())
        
        local config = get_config(option) :: types.config_window_internal
        if config then
            config.__changed:Fire(new_value, option.get_path())
		end
		
		option.focused:Fire()
    end

    local function layout_order_changed(new_value : number)
        option.frame.get().LayoutOrder = new_value
    end

    local function visible_changed(new_value : boolean)
        option.frame.get().Visible = new_value
    end

    local function key_changed(new_value : string)
        local frame = option.frame.get()

        local str = key_str(new_value)

        option_base.frame.get().option_name.Text = str
        frame.Name = new_value
    end

    local function resetable_changed(new_value : boolean)
        local frame = option.frame.get()
        local reset_btn = frame:FindFirstChild("reset_btn") :: ImageButton?

        if not reset_btn then
            return
        end

        reset_btn.Interactable = new_value
        reset_btn.ImageTransparency = if new_value then 0 else 1
        reset_btn.Active = new_value
    end

    local function original_value_changed(new_value : any)
        key_changed(option.key.get())
    end

    --[[----------------------------------------------------------------------]]--

    option.frame = frame_prop.immutable
    option.layout_order = props(data.layout_order or 0, layout_order_info)
    option.visible = props(if data.visible == nil then true else data.visible)
	option.focused = focused_signal
    option.delete = delete_option

    --[[----------------------------------------------------------------------]]--

    option.visible.changed:Connect(visible_changed)
    option.layout_order.changed:Connect(layout_order_changed)
    option.key.changed:Connect(key_changed)
    option.resetable.changed:Connect(resetable_changed)
    option.changed:Connect(value_changed)
    option.original_value.changed:Connect(original_value_changed)

    --[[----------------------------------------------------------------------]]--

    frame_init(option)

    --[[----------------------------------------------------------------------]]--

    return true, option, frame_prop
end

----------------------------------------------------------------------------------------------------------------

return new

----------------------------------------------------------------------------------------------------------------