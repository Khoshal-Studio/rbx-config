--!strict

------------------------------------------------------------------------------------------------------------------------------

local types = require(script.Parent.Parent.types)
local util = require(script.Parent.Parent.util)

------------------------------------------------------------------------------------------------------------------------------

local format = string.format

local props = util.props
local package = util.package
local get_path = util.get_path
local delete = util.delete
local get_cancel_fn = util.get_cancel_fn
local create_objects = util.create_objects

------------------------------------------------------------------------------------------------------------------------------

local function new(data : types.container_data) : (boolean, types.input_container?)
    if not util.valid_container_data(data) then
        return false, nil
    end
    
    --[[----------------------------------------------------------------------]]--

    local container : types.internal_input_container = nil

    --[[----------------------------------------------------------------------]]--

    local function get_object(key : string) : types.input_option?
        local objects = container.objects.get()
        return objects[key]
    end

    --[[----------------------------------------------------------------------]]--

    local function get_path_method()
        return get_path(container)
    end

    --[[----------------------------------------------------------------------]]--

    local function foreach(callback : (key : string, object : types.input_option | types.input_container) -> ())
        local objects = container.__objects

        for key, object in pairs(objects) do
            callback(key, object)
        end
    end

    local function foreach_recursive(callback : (object : types.input_option | types.input_container) -> ())
        local objects = container.__objects

        for _, object in pairs(objects) do
            callback(object)

            if object.__type == "input_container" then
                object.__foreach_recursive(callback)
            end
        end
    end

    local function export()
        local objects = container.__objects
        local exported = {}

        for key, object in pairs(objects) do
            exported[key] = object.export()
        end

        return exported
    end

    local function container_delete()
        delete(container)
        
        if container.container.get() then
            container.container.get()[container.key.get()] = nil
        end
    end

    local function set_key_str(key : string)
        local str = format("%s%s", key, if container.enabled.get() then "" else " (Disabled)")
        local frame = container.frame.get()

        frame.container_label.Text = str
        frame.Name = str

        return str
    end
    
    local cancel = get_cancel_fn(container)

    --[[----------------------------------------------------------------------]]--

    local container_frame_initial = util.presets.container:Clone()

    local frame_prop = props(container_frame_initial)
    local success, objects_inital = create_objects(data.objects)
    if not (success and objects_inital) then
        return false
    end

    local objects_prop = props(objects_inital)

    --[[----------------------------------------------------------------------]]--

    local key_info = {
        set = {
            function (value : string)
                if container.container.get() and container.container.get()[value] then
                    return cancel("key")
                end

                return package(value)
            end,
        }
    }

    local layout_order_info = {
        set = {
            function (value : number)
                if not util.is_natural(value) then
                    return cancel("layout_order")
                end

                return package(value)
            end,
        }
    }

    --[[----------------------------------------------------------------------]]--

    local function key_changed(key : string, previous_key : string)
        set_key_str(key)

        local x = container.container.get() or container.config.get()

        if not x then
            return
        end

        x.__objects[key] = container
        x.__objects[previous_key] = nil
    end

    local function enabled_changed(enabled : boolean)
        set_key_str(container.key.get())
        
        for _, object in container.objects.get() do
            object.enabled.set(enabled)
        end
    end

    local function visible_changed(visible : boolean)
        container.frame.get().Visible = visible
    end

    local function layout_order_changed(layout_order : number)
        container.frame.get().LayoutOrder = layout_order
	end
	
	local function config_changed(new_value)
		container.foreach_recursive(function(object)
			object.config.set(new_value)
		end)
	end

    --[[----------------------------------------------------------------------]]--

    container = {
        key = props(data.key, key_info),
        frame = frame_prop.immutable,

        enabled = props(if data.enabled == nil then true else data.enabled),
        visible = props(if data.visible == nil then true else data.visible),
        layout_order = props(data.layout_order or 0, layout_order_info),

        objects = objects_prop.immutable,

        get_object = get_object,
        export = export,
        delete = container_delete,
        get_path = get_path_method,

        foreach = foreach,
        foreach_recursive = foreach_recursive,
        
        container = props(nil),
        config = props(nil),
        
        __type = "input_container" :: any,
        __objects = objects_inital,
    }

    --[[----------------------------------------------------------------------]]--

    local function frame_init(frame : types.container_frame)
        frame.container_label.Text = container.key.get()
        frame.LayoutOrder = container.layout_order.get()
        frame.Visible = container.visible.get()

        container.enabled.changed:Fire(container.enabled.get())

        for key, object in pairs(container.__objects) do
            local object_frame = object.frame.get()

            object.__container = container

            object_frame.Parent = frame
            object_frame.LayoutOrder = object.layout_order.get()
		end
		
		util.interface_util.ui_adjust(frame, false, true)
    end

    --[[----------------------------------------------------------------------]]--
    
    frame_init(container.frame.get())

    --[[----------------------------------------------------------------------]]--
	
	container.config.changed:Connect(config_changed)
    container.key.changed:Connect(key_changed)
    container.enabled.changed:Connect(enabled_changed)
    container.visible.changed:Connect(visible_changed)
    container.layout_order.changed:Connect(layout_order_changed)

    --[[----------------------------------------------------------------------]]--
    
    return true, container
end

------------------------------------------------------------------------------------------------------------------------------

return new