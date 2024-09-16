--!strict

----------------------------------------------------------------------------------------------------------------------------------------

local config_util = require(script.Parent.Parent:WaitForChild("config_util"))
local config_types = require(script.Parent.Parent:WaitForChild("config_types"))

------------------------------------------------------------------------------------------------------

type data = config_types.data
type input_option_base<type, datatype, self, export_type> = config_types.input_option_base<type, datatype, self, export_type>

------------------------------------------------------------------------------------------------------

local universal_valid_data = config_util.universal_valid_data
local option_type_from_data = config_util.option_type_from_data
local delete = config_util.delete
local get_path = config_util.get_path
local get_cancel_fn = config_util.get_cancel_fn
local package = config_util.package

local default_description = config_util.default_description

local props = config_util.props

------------------------------------------------------------------------------------------------------

local function new(data : data) : (boolean, config_types.input_option?)
    local valid = universal_valid_data(data)

    if not valid then
        return false
    end

    --[[----------------------------------------------------------------------]]--

    local option_type = option_type_from_data(data)

    local option : input_option_base<any,any,any,any> = ({} :: any)

    --[[----------------------------------------------------------------------]]--

    local function delete_method()
        delete(option)

        local container = option.container.get()
        
        if container then
            local key = option.key.get()
            container[key] = nil
        end
    end

    local function reset()
        if not option.resetable.get() then
            return
        end
        
        local default_value = option.default_value.get()

        option.set(default_value)
    end

    local function get_path_method()
        return get_path(option)
    end

    local function key_changed(new_value : string)
        local parent : config_types.input_container = option.container.get() or option.config.get()

        if not parent then
            return
        end

        parent.objects.get()[new_value] = option
    end

    local cancel = get_cancel_fn(option)

    --[[----------------------------------------------------------------------]]--

    local option_info = {
        set = {
            function(new_value : any)
                if (not option.enabled.get()) then
                    warn("Option disabled")
                    return cancel()
                end

                return package(new_value)
            end
        }
    }

    local key_info = {
        set = {
            function(new_value : any)
                if option.container.get() and option.container.get().__type == "input_container" and option.container.get()[new_value] then
                    warn(string.format("key %s already used", new_value))
                    return cancel("key")
                end

                return package(new_value)
            end
        }
    }

    --[[----------------------------------------------------------------------]]--

	local option_base = props(data.default_value, option_info)

    --[[----------------------------------------------------------------------]]--

    option.key = props(data.key, key_info)
    option.resetable = props(if data.resetable == nil then true else data.resetable)
    option.description = props(data.description or default_description)
    option.original_value = props(data.default_value)
    option.default_value = props(data.default_value)
    option.enabled = props(if data.enabled == nil then true else data.enabled)    

    option.get = option_base.get
    option.set = option_base.set
    option.delete = delete_method
    option.reset = reset
    option.get_path = get_path_method
    option.export = nil :: any

    option.changed = option_base.changed
    
	option.config = props(nil)
	option.container = props(nil)
    option.datatype = props(option_type).immutable

    option.middleware = option_base.middleware

	option.__type = "input_option"

    --[[----------------------------------------------------------------------]]--

    option.key.changed:Connect(key_changed)

    --[[----------------------------------------------------------------------]]--

    return true, option
end

------------------------------------------------------------------------------------------------------

return new

------------------------------------------------------------------------------------------------------