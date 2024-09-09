--!strict

----------------------------------------------------------------------------------------------------------------

local config_util = require(script.Parent.Parent.Parent:WaitForChild("config_util"))
local config_types = require(script.Parent.Parent.Parent:WaitForChild("config_types"))

local input_option_backend = require(script.Parent.Parent:WaitForChild("input_option"))

----------------------------------------------------------------------------------------------------------------

type prop<T> = config_types.prop<T>
type immutable_prop<T> = config_types.immutable_prop<T>

type string_input_option = config_types.string_input_option
type string_data = config_types.string_data
type input_container = config_types.input_container

----------------------------------------------------------------------------------------------------------------

local truncate = config_util.truncate
local package = config_util.package
local get_cancel_fn = config_util.get_cancel_fn
local is_natural = config_util.is_natural

local props = config_util.props

----------------------------------------------------------------------------------------------------------------

local function new(data : string_data) : (boolean, string_input_option?)
    local success, option : string_input_option? = input_option_backend(data)
    if not (success and option) then
        return false
    end

    --[[----------------------------------------------------------------------]]--

    local cancel = get_cancel_fn(option)

    local function export()
        return option.get()
    end

    --[[----------------------------------------------------------------------]]--

    local set = function (new_value : string)
        return package(truncate(new_value, option.max_length.get()))
    end

    local max_length_middleware = {
        set = {
            function (new_value : number)
                if not is_natural(new_value) then
                    warn("Max length must be natural number", "\n", new_value)
                    return cancel("max_length")
                end

                return package(new_value)
            end,

            function (new_value : number)
                local default_value = option.default_value.get()
                local current_value = option.get()

                if default_value:len() > new_value then
                    option.default_value.set(truncate(default_value, new_value))
                end

                if current_value:len() > new_value then
                    option.set(truncate(current_value, new_value))
                end

                return package(new_value)
            end
        }
    }

    --[[----------------------------------------------------------------------]]--

    option.default_value.middleware.set.add(set)
    option.middleware.set.add(set)

    --[[----------------------------------------------------------------------]]--

    option.export = export
    option.max_length = props(data.max_length or 15, max_length_middleware)

    --[[----------------------------------------------------------------------]]--

    return true, option
end

----------------------------------------------------------------------------------------------------------------

return new

----------------------------------------------------------------------------------------------------------------