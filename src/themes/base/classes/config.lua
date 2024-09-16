--!strict

------------------------------------------------------------------------------------------------------------------------------

local TweenService = game:GetService("TweenService")

------------------------------------------------------------------------------------------------------------------------------

local types = require(script.Parent.Parent.types)
local util = require(script.Parent.Parent.util)

local datatypes = script.Parent:WaitForChild("datatypes")

------------------------------------------------------------------------------------------------------------------------------

local props = util.props
local get_cancel_fn = util.get_cancel_fn
local option_type_from_data = util.option_type_from_data

------------------------------------------------------------------------------------------------------------------------------

local function new(data : types.config_setup) : (boolean, types.config_window?)
    if not util.valid_config_setup(data) then
        warn("Invalid config setup", "\n", data)
        return false
    end

    --[[----------------------------------------------------------------------]]--

    local container_new = require(script.Parent:WaitForChild("container"))

    --[[----------------------------------------------------------------------]]--

    local config : types.config_window_internal = nil
    local config_frame_initial = util.presets.config:Clone() :: types.config_frame

    local frame_prop = props(config_frame_initial)

    local changed_signal = util.signal()
    local apply_signal = util.signal()

    --[[----------------------------------------------------------------------]]--

    local success, dragger = util.dragger.new({
        object = config_frame_initial.header,
        target = config_frame_initial,
        update = true,
    })

    if not (success and dragger) then
        warn("Failed to create dragger", "\n", dragger)
        return false
    end

    --[[----------------------------------------------------------------------]]--

    local _cancel = get_cancel_fn(config)

    local function foreach(callback : (key : string, object : types.input_option | types.input_container) -> ())
        local objects = config.__objects

        for key, object in pairs(objects) do
            callback(key, object)
        end
    end

    local function foreach_recursive(callback : (object : types.input_option | types.input_container) -> ())
        local objects = config.__objects

        for _, object in pairs(objects) do
            callback(object)

            if object.__type == "input_container" then
                (object :: any).__foreach_recursive(callback)
            end
        end
    end

    local function export()
        local objects = config.__objects
        local exported = {}

        for key, object in pairs(objects) do
            exported[key] = (object.export :: any)()
        end

        return exported
    end

    --[[----------------------------------------------------------------------]]--

    local close_btn_mouse_enter_tween = TweenService:Create(config_frame_initial.header.close, TweenInfo.new(0.2), {
        BackgroundColor3 = Color3.fromRGB(255, 0, 0),
    })

    local close_btn_mouse_leave_tween = TweenService:Create(config_frame_initial.header.close, TweenInfo.new(0.2), {
        BackgroundColor3 = Color3.fromRGB(43, 43, 43),
    })

    --[[----------------------------------------------------------------------]]--

    local function close_btn_mouse_enter()
        close_btn_mouse_enter_tween:Play()
    end

    local function close_btn_mouse_leave()
        close_btn_mouse_leave_tween:Play()
    end

    local function close_btn_mouse_click()
        config.visible.set(false)
    end

    --[[----------------------------------------------------------------------]]--

    local function visible_changed(new_value : boolean)
        config.frame.get().Visible = new_value
    end

    local function draggable_changed(new_value : boolean)
        if new_value then
            dragger:enable()
        else
            dragger:disable()
        end
    end

    local function title_changed(new_value : string)
        config.frame.get().header.title.Text = new_value
    end

    local function requires_apply_info_changed(new_value : boolean)
        config.frame.get().bottom_bar.Visible = new_value
    end

    local function sidebar_visible_changed(visible : boolean)
        config.frame.get().config.sidebar.Visible = visible
    end

    --[[----------------------------------------------------------------------]]--

    local function view()
        local frame = config.frame.get()
        local parent = frame.Parent

        if not (parent and frame:FindFirstAncestorWhichIsA("ScreenGui")) then
            warn("Config window has no valid ancestry")
            return
        end

        frame.ZIndex = 1

        for _, inst in ipairs(parent:GetChildren()) do
            if inst:IsA("GuiObject") and inst ~= frame :: any then
                inst.ZIndex = 0
            end
        end
    end
    

    local function create_objects(data : types.objects) : (boolean, types.input_objects?)
        local objects : types.input_objects = {}

		for key, object in ipairs(data) do
			local __type = util.data_type_from_data(object)
			
            if __type == "container" then
                local success, container_initial = container_new(object :: types.container_data)
                if not success then
                    warn("Failed to create container", "\n", object)
                    return false
                end

                local new_container = container_initial :: types.input_container

                objects[object.key] = new_container :: any
            elseif __type == "option" then
                local option_type = option_type_from_data(object :: types.data)
                local datatype_class = datatypes:FindFirstChild(option_type) :: ModuleScript?
                
                if not datatype_class then
                    warn("Could not find datatype class", "\n", option_type)
                    return false
                end

                local success, input_option = (require(datatype_class) :: any)(object)
    
                if success then
                    objects[object.key] = input_option :: any
                else
                    warn("Failed to create option", "\n", object)
                    return false
                end
            end
        end

        return true, objects
    end

    local function get_object(key : string) : types.input_option?
        return config.__objects[key] :: any
    end

    local function to_list_path(path : {[number] : string} | string) : {[number] : string}
        if type(path) == "string" then
            return string.split(path, "/")
        end

        return path
    end

    local function get_object_from_path(path : {[number] : string} | string) : types.input_option | types.input_container | nil
        local decoded_path = to_list_path(path)

        local current : any = config

        for i, v in ipairs(decoded_path) do
            if v == "." then
                continue
            end

            if not current then
                return nil
            end

            if current.__type == "input_container" or current.__type == "config_window" then
                current = current.__objects[v]
            elseif current.__type == "input_option" then
                if i ~= #decoded_path then
                    return nil
                end

                return current
            end
        end

        return current
    end

    local function apply()
        if not config.requires_apply.get() then
            return
        end

        local has_changed = false

        foreach_recursive(function (object : types.input_option | types.input_container)
            if object.__type == "input_option" then
                local x : any = object
                if x.original_value.get() ~= x.get() then
                    has_changed = true
                    x.original_value.set(x.get())
                end
            end
        end)

        if has_changed then
            print("Config has changed")
            apply_signal:Fire()
        end
    end

    --[[----------------------------------------------------------------------]]--

    local success_, objects_initial = create_objects(data.objects)
    if not (success_ and objects_initial) then
        warn("Failed to create objects")
        return false
    end

    local objects_prop = props(objects_initial)

    --[[----------------------------------------------------------------------]]--

	local function frame_init(frame : types.config_frame)
		frame.config.sidebar.title.Text = ""
		frame.config.sidebar.info.description.Text = ""
		
        frame.header.title.Text = config.title.get()
        frame.bottom_bar.Visible = config.requires_apply.get()
        frame.Visible = config.visible.get()

        config.draggable.changed:Fire(config.draggable.get())
        config.sidebar_visible.changed:Fire(config.sidebar_visible.get())
        config.visible.changed:Fire(config.visible.get())
        config.requires_apply.changed:Fire(config.requires_apply.get())

        frame.header.close.MouseButton1Click:Connect(close_btn_mouse_click)
        frame.header.close.MouseEnter:Connect(close_btn_mouse_enter)
        frame.header.close.MouseLeave:Connect(close_btn_mouse_leave)

        frame.bottom_bar.apply.MouseButton1Click:Connect(apply)
        
        for key, object in pairs(config.__objects) do
            local object_frame = (object.frame :: any).get()

            local x = object :: any
            x.__config = config

            object_frame.Parent = frame.config.config
            object_frame.LayoutOrder = (object.layout_order :: any).get()
		end
		
		util.interface_util.ui_adjust(frame, false, true)
    end

    --[[----------------------------------------------------------------------]]--

    config.title = props(data.title or "Config")
    config.draggable = props(if data.draggable == nil then true else data.draggable)
    config.visible = props(if data.visible == nil then true else data.visible)
    config.sidebar_visible = props(if data.sidebar_visible == nil then false else data.sidebar_visible)
    
    config.objects = objects_prop.immutable
    config.requires_apply = props(if data.requires_apply == nil then true else data.requires_apply)
    config.frame = frame_prop.immutable

    config.close = close_btn_mouse_click
    config.view = view
    config.get_object = get_object
    config.get_object_from_path = get_object_from_path
    config.foreach = foreach
    config.foreach_recursive = foreach_recursive
    config.export = export
    config.apply = apply

    config.applied = apply_signal.Restricted
    config.changed = changed_signal.Restricted

    config.__changed = changed_signal
    config.__applied = apply_signal

    config.__type = "config_window"

    --[[----------------------------------------------------------------------]]--

    config.title.changed:Connect(title_changed)
    config.requires_apply.changed:Connect(requires_apply_info_changed)
    config.visible.changed:Connect(visible_changed)
    config.draggable.changed:Connect(draggable_changed)
    config.sidebar_visible.changed:Connect(sidebar_visible_changed)

    --[[----------------------------------------------------------------------]]--

    frame_init(config.frame.get())

    --[[----------------------------------------------------------------------]]--
    
    return true, config
end

------------------------------------------------------------------------------------------------------------------------------

return new