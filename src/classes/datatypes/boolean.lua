--!strict

----------------------------------------------------------------------------------------------------------------

local _config_util = require(script.Parent.Parent.Parent:WaitForChild("config_util"))
local config_types = require(script.Parent.Parent.Parent:WaitForChild("config_types"))

local input_option_backend = require(script.Parent.Parent:WaitForChild("input_option"))

----------------------------------------------------------------------------------------------------------------

type boolean_data = config_types.boolean_data
type boolean_input_option = config_types.boolean_input_option

----------------------------------------------------------------------------------------------------------------

local function new(data : boolean_data) : (boolean, boolean_input_option?)
    local success, option : boolean_input_option? = input_option_backend(data)

    if not (success and option) then
        return false
    end

    --[[----------------------------------------------------------------------]]--

    local function export()
        return option.get()
    end

    --[[----------------------------------------------------------------------]]--

    option.export = export

    --[[----------------------------------------------------------------------]]--

    return true, option
end

----------------------------------------------------------------------------------------------------------------

return new

----------------------------------------------------------------------------------------------------------------