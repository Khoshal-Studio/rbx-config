--!strict

-----------------------------------------------------------------------------------------------------

local config_util = require(script.Parent.Parent.Parent:WaitForChild("config_util"))
local config_types : nil = require(script.Parent.Parent.Parent:WaitForChild("config_types"))

local input_option_backend = require(script.Parent.Parent:WaitForChild("input_option"))

------------------------------------------------------------------------------------------------------

type prop<T> = config_types.prop<T>
type immutable_prop<T> = config_types.immutable_prop<T>
type dropdown_data = config_types.dropdown_data
type dropdown_input_option = config_types.dropdown_input_option
type input_container = config_types.input_container

------------------------------------------------------------------------------------------------------

local find = table.find

local props = config_util.props
local package = config_util.package
local get_cancel_fn = config_util.get_cancel_fn

------------------------------------------------------------------------------------------------------

local function new(data : dropdown_data) : (boolean, dropdown_input_option?)
    local success, option : dropdown_input_option? = input_option_backend(data)

    if not (success and option) then
        return false
    end

    --[[----------------------------------------------------------------------]]--

    local cancel = get_cancel_fn(option)

    local function export()
        return option.get() or ""
    end

    --[[----------------------------------------------------------------------]]--

    local choices_middleware = {
        set = {
            function (new_value : {string})
                if #new_value == 0 then
                    warn("No choices", "\n", new_value)
                    return cancel("choices")
                end

                return package(new_value)
            end,

            function (new_value : {string})
                local seen = {}

                for _, choice in ipairs(new_value) do
                    if seen[choice] then
                        warn("Duplicate choice", "\n", choice)
                        return cancel("choices")
                    else
                        seen[choice] = true    
                    end
                    
                    if choice == "" then
                        warn("Empty choice", "\n", new_value)
                        return cancel("choices")
                    end
                end

                return package(new_value)
            end,

            function (new_value : {string})
                local current_value = option.get()

                if current_value and not find(new_value, current_value) then
                    option.set(new_value[1], true)
                end

                return package(new_value)
            end
        }
    }

    --[[----------------------------------------------------------------------]]--
    
    option.middleware.set.add(function(new_value : string?)
        if new_value == "" then
            warn("Empty value", "\n", new_value)
            return cancel()
        end

        if new_value and not find(option.choices.get(), new_value) then
            warn("Invalid value", "\n", new_value)
            return cancel()
        end

        return package(new_value)
    end)

    option.default_value.middleware.set.add(function(new_value : string?)
        if new_value == "" then
            warn("Empty default value", "\n", new_value)
            return cancel("default_value")
        end

        if new_value then
            if not find(option.choices.get(), new_value) then
                warn("Invalid default value", "\n", new_value)
                return cancel("default_value")
            end
        end

        return package(new_value)
    end)

    --[[----------------------------------------------------------------------]]--

    option.export = export
    option.choices = props(data.choices, choices_middleware)

    --[[----------------------------------------------------------------------]]--

    return true, option
end

------------------------------------------------------------------------------------------------------

return new

------------------------------------------------------------------------------------------------------