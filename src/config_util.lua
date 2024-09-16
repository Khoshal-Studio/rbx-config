--!strict

------------------------------------------------------------------------------------------------------

local module = {}

-----------------------------------------------------------------------------------------------------

local config_types = require(script.Parent:WaitForChild("config_types"))

local dependencies = script.Parent:WaitForChild("dependencies")
local props = require(dependencies:WaitForChild("props"))

-----------------------------------------------------------------------------------------------------

type num_info = config_types.num_info
type num_data = config_types.number_data
type input_option = config_types.input_option
type input_option_base<T, V, C, B> = config_types.input_option_base<T, V, C, B>
type number_input_option = config_types.number_input_option

type string_data = config_types.string_data

type dragger_info = config_types.dragger_info
type dragger = config_types.dragger

type connection = config_types.connection
type signal = config_types.signal
type restricted_signal = config_types.restricted_signal
type fire<T> = config_types.fire<T>

type get<T> = config_types.get<T>
type set<T> = config_types.set<T>

type prop<T> = config_types.prop<T>
type immutable_prop<T> = config_types.immutable_prop<T>
type object_base<T> = config_types.object_base<T>

type data = config_types.data
type input_container = config_types.input_container

------------------------------------------------------------------------------------------------------

local clamp : (number, number, number) -> number = math.clamp
local floor : (number) -> number = math.floor
local abs : (number) -> number = math.abs

------------------------------------------------------------------------------------------------------

local is_integer : (number) -> boolean = function(value: number): boolean
	return type(value) == "number" and value % 1 == 0
end

local is_natural : (number) -> boolean = function(value: number): boolean
	return is_integer(value) and value > 0
end

local function has_duplicates(array: {any}): boolean
	local hash : { [any]: boolean } = {}

	for _, value in array do
		if hash[value] then
			return true
		end

		hash[value] = true
	end

	return false
end

local function round(number : number, sigFigs : number)
	return math.round(number * 10^sigFigs) / 10^sigFigs
end

local function package(value : any) : {value : any, cancel : boolean}
	return {value = value, cancel = false}
end

local function get_cancel_fn(t : any)
	return function(key : string?)
		if key then
			return {
				value = t[key].get(),
				cancel = true
			}
		end

		return {
			value = t.get(),
			cancel = true
		}
	end
end

local function get_path(data : any) : string
	local current = data
	local path = ""

	while current and current.__type ~= "config_window" :: any do
		path = "/" .. (current.key :: any).get() .. path

		current = current.container.get()
	end

	return "." .. path
end

------------------------------------------------------------------------------------------------------

module.enabled_bg_col = Color3.fromRGB(40, 40, 40)
module.disabled_bg_col = Color3.fromRGB(30, 30, 30)
module.enabled_text_col = Color3.fromRGB(255, 255, 255)
module.disabled_text_col = Color3.fromRGB(100, 100, 100)

module.default_description = "No description provided."

------------------------------------------------------------------------------------------------------

module.package = package

module.truncate = function(str : string, max_len : number) : string
	if str:len() > max_len then
		return string.sub(str, 1, max_len)
	end

	return str
end

module.option_type_from_data = function(data : data) : string?
	if type(data.default_value) == "number" then
		return "number"
	elseif type(data.default_value) == "string" then
		if (data :: any).choices then
			return "dropdown"
		end
		return "string"
	elseif data.default_value == false or data.default_value == true then
		return "boolean"
	end

	return nil
end

module.data_type_from_data = function(data : any) : "option" | "container" | nil
	if data.objects then
		return "container"
	elseif data.default_value ~= nil then
		return "option"
	end

	return nil
end

module.valid_data = function(data : data) : (boolean, string?)
	local default_value = data.default_value
	local key = data.key

	if default_value == nil then
		warn("Missing default_value", "\n", data)
		return false, "missing default_value"
	end

	if not key then
		warn("Missing key", "\n", data)
		return false, "missing key"
	end

	return true
end

module.valid_string_data = function(info : string_data) : (boolean, string?)
	if not info.max_length then
		warn("Missing max_length", "\n", info)
		return false, "missing max_length"
	end

	if not is_natural(info.max_length) then
		warn("Invalid max_length", "\n", info)
		return false, "max_length is not a natural number"
	end

	return true
end

module.valid_num_info = function(info : num_info, default_value : number?) : (boolean, string?)
	local limit = info.limit
	local signed = info.signed
	local int = info.int
	local decimal_limit = info.decimal_limit

	if limit then
		if not limit.min then
			warn("Missing min in limit", "\n", info)
			return false, "missing min in limit"
		elseif not limit.max then
			warn("Missing max in limit", "\n", info)
			return false, "missing max in limit"
		end
	end

	if limit then
		if limit.min and limit.max then
			if limit.min > limit.max then
				warn("Invalid num_info, min is greater than max", "\n", "min:", limit.min, "max:", limit.max, info)
				return false, "min is greater than max"
			end
			if limit.min == limit.max then
				warn("Invalid num_info, min is equal to max", "\n", "min:", limit.min, "max:", limit.max, info)
				return false, "min is equal to max"
			end

			if not signed then
				if limit.min < 0 then
					warn("Invalid num_info, min is negative for unsigned number", "\n", "min:", limit.min, info)
					return false, "min is negative for unsigned number"
				end
				if limit.max < 0 then
					warn("Invalid num_info, max is negative for unsigned number", "\n", "max:", limit.max, info)
					return false, "max is negative for unsigned number"
				end
			end

			if int then
				if not is_integer(limit.min) then
					warn("Invalid num_info, min is not an integer for integer number", "\n",  "min:", limit.min, info)
					return false, "min is not an integer for integer number"
				end
				if not is_integer(limit.max) then
					warn("Invalid num_info, max is not an integer for integer number", "\n", "max:", limit.max, info)
					return false, "max is not an integer for integer number"
				end
			end
		end
	end

	if default_value then
		if limit then
			if limit.min then
				if default_value < limit.min then
					warn("Invalid num_info, default value is less than min", "\n", "default value:", default_value, "min:", limit.min, info)
					return false, "default value is less than min"
				end
			end
			if limit.max then
				if default_value > limit.max then
					warn("Invalid num_info, default value is greater than max", "\n", "default value:", default_value, "max:", limit.max, info)
					return false, "default value is greater than max"
				end
			end
		end
	end

	if int then
		if default_value and not is_integer(default_value) then
			warn("Invalid num_info, default value is not an integer for integer number", "\n", "default value:", default_value, info)
			return false, "default value is not an integer for integer number"
		end
	end

	if not signed then
		if default_value and default_value < 0 then
			warn("Invalid num_info, default value is negative for unsigned number", "\n", "default value:", default_value, info)
			return false, "default value is negative for unsigned number"
		end
	end

	if decimal_limit then
		if default_value then
			local decimal = default_value % 1
			local decimal_str = tostring(decimal)
			local decimal_len = #decimal_str - 2

			if decimal_len > decimal_limit then
				warn("Invalid num_info, default value has more decimal places than decimal_limit", "\n", "default value:", default_value, "decimal_limit:", decimal_limit, info)
				return false, "default value has more decimal places than decimal_limit"
			end
		end

		if decimal_limit < 0 then
			warn("Invalid num_info, decimal_limit is negative", "\n", "decimal_limit:", decimal_limit, info)
			return false, "decimal_limit is negative"
		end

		if not is_natural(decimal_limit) then
			warn("Invalid num_info, decimal_limit is not a natural number", "\n", "decimal_limit:", decimal_limit, info)
			return false, "decimal_limit is not a natural number"
		end
	end

	return true
end

module.num_constrain = function(info : num_info, value : number) : number
	local limit = info.limit

	if info.int then
		value = floor(value)
	end

	if not info.signed then
		value = abs(value)
	end

	if limit then
		if limit.max and limit.min then
			value = clamp(value, limit.min, limit.max)
			return value
		elseif limit.max and value > limit.max then
			value = limit.max
		elseif limit.min and value < limit.min then
			value = limit.min
		end
	end

	if info.decimal_limit then
		value = round(value, info.decimal_limit)
	end

	return value
end

module.valid_dropdown_data = function(info : config_types.dropdown_data) : (boolean, string?)
	local choices : {string} = info.choices

	if has_duplicates(choices) then
		warn("Invalid choices", "\n", info)
		return false, "choices contain duplicates"
	end

	if not choices then
		warn("Missing choices", "\n", info)
		return false, "missing choices"
	end

	return true
end

module.delete = function(data : any)
	for key: any, v in pairs(data) do
		rawset(data, key, nil)
	end

	data = nil
end

module.universal_valid_data = function(data : data) : (boolean, string?)
	local initial_valid = module.valid_data(data)
	if not initial_valid then
		return false, "invalid data"
	end

	local option_type = module.option_type_from_data(data)

	if option_type == "number" and type(data.default_value) == "number" then
		local valid = module.valid_num_info(data :: any, data.default_value)
		if not valid then
			return false, "invalid num_info"
		end
	elseif option_type == "string" then
		local valid = module.valid_string_data(data :: any)
		if not valid then
			return false, "invalid string_data"
		end
	elseif option_type == "dropdown" then
		local valid = module.valid_dropdown_data(data :: any)
		if not valid then
			return false, "invalid dropdown_data"
		end
	end

	return true
end

module.get_config = function(data : any) : any?
	local current = data

	while current do
		if current.__type == "config_window" :: any then
			return current
		end

		current = current.container.get() or current.config.get() or nil
	end

	return nil
end

------------------------------------------------------------------------------------------------------

module.map_children_of_class = function(parent : Instance, class : string, callback : (child : any) -> ()): ()
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA(class) then
			callback(child :: any)
		end
	end
end

module.clear_children_of_class = function(parent : Instance, class : string): ()
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA(class) then
			child:Destroy()
		end
	end
end

module.foreach = function(t : {any}, callback : (value : any, key : any) -> ()): ()
	for key : any, value : any in t do
		callback(value, key)
	end
end

module.foreach_array = function(t : {any}, callback : (value : any, index : number) -> ()): ()
	for index : number, value : any in ipairs(t) do
		callback(value, index)
	end
end

module.has_duplicates = has_duplicates
module.round = round
module.is_integer = is_integer
module.is_natural = is_natural
module.get_cancel_fn = get_cancel_fn
module.get_path = get_path

------------------------------------------------------------------------------------------------------

module.signal = require(dependencies:WaitForChild("signal"))
module.props = props
module.dragger = require(dependencies:WaitForChild("dragger"))
module.interface_util = require(dependencies:WaitForChild("interface_util"))

------------------------------------------------------------------------------------------------------

return module

------------------------------------------------------------------------------------------------------