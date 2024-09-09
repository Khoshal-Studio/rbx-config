--!strict

----------------------------------------------------------------------------------------------------------------

local module = {}

----------------------------------------------------------------------------------------------------------------

local config_util = require(script.Parent.Parent.Parent:WaitForChild("config_util"))
local types = require(script.Parent:WaitForChild("types"))

----------------------------------------------------------------------------------------------------------------

local classes = script.Parent:WaitForChild("classes")
local datatypes = classes:WaitForChild("datatypes")
local presets = script.Parent:WaitForChild("presets")

----------------------------------------------------------------------------------------------------------------

export type input_option = types.input_option
export type input_option_base<T, V> = types.input_option_base<T, V>
export type input_option_root = types.input_option_root
export type prop<T> = types.prop<T>

----------------------------------------------------------------------------------------------------------------

local find = table.find

local foreach = config_util.foreach
local delete = config_util.delete
local has_duplicates = config_util.has_duplicates
local is_natural = config_util.is_natural
local is_integer = config_util.is_integer
local map_children_of_class = config_util.map_children_of_class
local clear_children_of_class = config_util.clear_children_of_class
local valid_num_info = config_util.valid_num_info
local truncate = config_util.truncate
local option_type_from_data = config_util.option_type_from_data
local get_config = (config_util.get_config :: any) :: (types.input_object) -> types.config_window
local package = config_util.package
local get_cancel_fn = config_util.get_cancel_fn
local data_type_from_data = config_util.data_type_from_data
local constrain = config_util.num_constrain

local props = config_util.props
local dragger = config_util.dragger
local signal = config_util.signal
local interface_util = config_util.interface_util

----------------------------------------------------------------------------------------------------------------

module.get_frame = function(option : types.data) : Frame
    local option_type = config_util.option_type_from_data(option)

    if option_type == "string" or option_type == "number" then
        return presets.datatypes.input:Clone()
    end

    local frame = presets.datatypes[option_type]:Clone()

    return frame
end

module.get_desc_text = function(option : types.input_option) : string
	local desc = option.description.get()
	local datatype = option.__datatype
	
	if not datatype then
		return desc
	end
	
	return string.format("%s\n\nDefault Value: %s", desc, tostring((option :: any).default_value.get()))
end

module.valid_data = function(data : types.data) : (boolean, string?)
    if not config_util.valid_data(data) then
        warn("Invalid data", "\n", data)
        return false, "Invalid data"
    end

    if data.layout_order then
        if not is_natural(data.layout_order) then
            warn("Invalid layout_order", "\n", data)
            return false, "Invalid layout_order"
        end
    end

    return true
end

module.valid_dropdown_data = function(data : types.dropdown_data) : (boolean, string?)
    local choices : {string} = data.choices
    local nil_placeholder : string? = data.nil_placeholder

    if not config_util.valid_dropdown_data(data) then
        warn("Invalid dropdown_info", "\n", data)
        return false, "Invalid dropdown_info"
    end

    if nil_placeholder and find(choices, nil_placeholder) then
        warn("Invalid nil_placeholder, already exists in choices", "\n", data)
        return false, "nil_placeholder already exists in choices"
    end

    return true
end

module.universal_valid_data = function(data : types.data) : boolean
    local success, _ = module.valid_data(data)

    if not success then
        return false
    end

    local option_type = config_util.option_type_from_data(data)

    if option_type == "dropdown" then
        local valid = module.valid_dropdown_data(data :: any)
        if not valid then
            return false
        end
    elseif option_type == "number" and type(data.default_value) == "number" then
        local valid = valid_num_info(data :: any, data.default_value :: any)
        if not valid then
            return false
        end
    elseif option_type == "string" and type(data.default_value) == "string" then
        local valid = config_util.valid_string_data(data :: any)
        if not valid then
            return false
        end
    elseif option_type == "boolean" and type(data.default_value) == "boolean" then
        -- do nothing because boolean is the simplest and the initial check is enough
    end

    return true
end

module.valid_objects = function(data : types.objects) : (boolean, string?)
    if not data then
        warn("Missing objects", "\n", data)
        return false, "missing objects"
    end

    local seen_keys = {}

    for key, value in ipairs(data) do
        local __type = data_type_from_data(value)
        
        if __type == "container" then
            local valid = module["valid_container_data"](value :: types.container_data)
            if not valid then
                return false, "invalid sub-container data"
            end
        elseif __type == "option" then
            if seen_keys[value.key] then
                warn("Duplicate key", "\n", value)
                return false, "duplicate key"
            else
                seen_keys[value.key] = true
            end
            
            local valid = module.universal_valid_data(value :: types.data)
            if not valid then
                return false, "invalid option data"
            end
        end
    end

    return true
end

module.valid_container_data = function(data : types.container_data) : (boolean, string?)
    if not data.key then
        warn("Missing key", "\n", data)
        return false, "missing key"
	end

    if not module.valid_objects(data.objects) then
        return false, "invalid objects"
    end

    return true
end

module.valid_config_setup = function(data : types.config_setup) : (boolean, string?)
    if not module.valid_objects(data.objects) then
        return false, "invalid objects"
    end

    return true
end

module.create_objects = function(data : types.objects) : (boolean, types.input_objects?)
    if not module.valid_objects(data) then
        return false, nil
    end

    --[[----------------------------------------------------------------------]]--

    local objects : types.input_objects = {}

    local container_new = require(script.Parent.classes.container) :: any

    --[[----------------------------------------------------------------------]]--

    for key, object in ipairs(data) do
        local __type = data_type_from_data(object)
        
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

module.inherit = function(class, inheritor)
    for key, value in pairs(class) do
        inheritor[key] = value
    end
end

module.merge = function(class, merger)
    for key, value in pairs(merger) do
        class[key] = value
    end
end

----------------------------------------------------------------------------------------------------------------

module.presets = presets
module.interface_util = interface_util
module.foreach = foreach
module.clear_children_of_class = clear_children_of_class
module.map_children_of_class = map_children_of_class
module.has_duplicates = has_duplicates
module.is_natural = is_natural
module.is_integer = is_integer
module.delete = delete
module.props = props
module.dragger = dragger
module.signal = signal
module.truncate = truncate
module.package = package
module.option_type_from_data = option_type_from_data
module.get_config = get_config
module.get_cancel_fn = get_cancel_fn
module.get_path = config_util.get_path
module.data_type_from_data = data_type_from_data
module.constrain = constrain

----------------------------------------------------------------------------------------------------------------

return module

----------------------------------------------------------------------------------------------------------------