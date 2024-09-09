--!strict

----------------------------------------------------------------------------------------------------------------

local config_util = require(script.Parent.Parent.Parent:WaitForChild("config_util"))
local config_types = require(script.Parent.Parent.Parent:WaitForChild("config_types"))

local input_option_backend = require(script.Parent.Parent:WaitForChild("input_option"))

----------------------------------------------------------------------------------------------------------------

type prop<T> = config_types.prop<T>
type immutable_prop<T> = config_types.immutable_prop<T>

type number_input_option = config_types.number_input_option
type number_data = config_types.number_data
type num_info = config_types.num_info
type input_container = config_types.input_container

----------------------------------------------------------------------------------------------------------------

local valid_num_info = config_util.valid_num_info
local constrain = config_util.num_constrain
local package = config_util.package
local get_cancel_fn = config_util.get_cancel_fn

local props = config_util.props

----------------------------------------------------------------------------------------------------------------

local function new(data : number_data) : (boolean, number_input_option?)
    local success, option : number_input_option? = input_option_backend(data)

    if not (success and option) then
        return false
    end

    --[[----------------------------------------------------------------------]]--

    local cancel = get_cancel_fn(option)

    local function export()
        return option.get()
    end

    --[[----------------------------------------------------------------------]]--

    local num_info_middleware = {
        set = {
            function (new_value : num_info)
                local valid, err : string? = valid_num_info(new_value, option.get())

                if not valid then
                    warn(err)
                    return cancel("num_info")
                end

                return package(new_value)
            end
        }
    }

    local function set_middleware (new_value : number)
        return package(constrain(option.num_info.get(), new_value))
    end

    --[[----------------------------------------------------------------------]]--

    local function num_info_changed(new_value : num_info)
        option.default_value.set(constrain(new_value, option.default_value.get()))
        option.set(constrain(new_value, option.get()))
    end

    --[[----------------------------------------------------------------------]]--

    option.middleware.set.add(set_middleware)
    option.default_value.middleware.set.add(set_middleware)

    --[[----------------------------------------------------------------------]]--

    option.export = export
    option.num_info = props(data.num_info, num_info_middleware)

    --[[----------------------------------------------------------------------]]--

	option.num_info.changed:Connect(num_info_changed)
	
	print(constrain(option.num_info.get(), -120))

    --[[----------------------------------------------------------------------]]--
    
    return true, option
end

----------------------------------------------------------------------------------------------------------------

return new

----------------------------------------------------------------------------------------------------------------