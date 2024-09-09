--!strict

----------------------------------------------------------------------------------------------------------------------------------------

local config_util = require(script.Parent.Parent:WaitForChild("config_util"))
local config_types = require(script.Parent.Parent:WaitForChild("config_types"))

------------------------------------------------------------------------------------------------------

type data = config_types.data
type input_option_base<T, K, D, E> = config_types.input_option_base<T, K, D, E>

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

local function new(data : data) : (boolean, any?)
    local valid = universal_valid_data(data)
    if not valid then
        return false
    end

    --[[----------------------------------------------------------------------]]--

    local option_type = option_type_from_data(data)

    local option : input_option_base<any, any, any, any> = nil

    --[[----------------------------------------------------------------------]]--

    local function delete_option(self : any)
        delete(self)
        
        if self.__container then
            self.__container[self.key.get()] = nil
        end
    end

    local function reset(self : any)
        if not option.resetable.get() then
            return
        end
        self.set(self.default_value.get())
    end

    local function get_path_method()
        return get_path(option)
    end

    local function key_changed(new_value : string, previous_value : string)
        local x = option.__container or option.__config

        if not x then
            return
        end

        x.__objects[new_value] = option
        x.__objects[previous_value] = nil
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
                if option.__container and option.__container.__type == "input_container" and option.__container[new_value] then
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

    option = {
        get = option_base.get,
        set = option_base.set,
        middleware = option_base.middleware,
        changed = option_base.changed,

        delete = delete_option,
        reset = reset,
        get_path = get_path_method,

        key = props(data.key, key_info),
        export = nil :: any, 

        resetable = props(if data.resetable == nil then true else data.resetable),
        description = props(data.description or default_description),

        original_value = props(data.default_value),
        default_value = props(data.default_value),

        enabled = props(if data.enabled == nil then true else data.enabled),

        __type = "input_option" :: any,
        __config = nil,
        __container = nil,
        __datatype = option_type,
    }

    --[[----------------------------------------------------------------------]]--

    option.key.changed:Connect(key_changed)

    --[[----------------------------------------------------------------------]]--

    return true, option
end

------------------------------------------------------------------------------------------------------

return new

------------------------------------------------------------------------------------------------------