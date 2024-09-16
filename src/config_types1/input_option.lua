--!strict

-----------------------------------------------------------------------------------------------------------------

local dependencies = script.Parent.Parent:WaitForChild("dependencies")

local prop_types = require(dependencies:WaitForChild("props"):WaitForChild("props_types"))
local signal_types = require(dependencies:WaitForChild("signal"):WaitForChild("signal_types"))

local option_data = require(script.Parent:WaitForChild("option_data"))

-----------------------------------------------------------------------------------------------------------------

type object_base<T> = prop_types.object_base<T>
type middleware_info<T> = prop_types.middleware_info<T>
type get<T> = prop_types.get<T>
type set<T> = prop_types.set<T>
type signal = signal_types.signal
type prop<T> = prop_types.prop<T>
type immutable_prop<T> = prop_types.immutable_prop<T>
type num_info = option_data.num_info

-----------------------------------------------------------------------------------------------------------------

export type input_option_base<_type, datatype, _self, export_type> =
{
	get : get<_type>,
	set : set<_type>,
	changed : signal,
	middleware : middleware_info<_type>,

	export : () -> export_type,
	get_path : () -> string,

	delete : (self : _self) -> (),
	reset : (self : _self) -> (),

	key : prop<string>,
	description : prop<string>,

	original_value : prop<_type>,
	default_value : prop<_type>,

	resetable : prop<boolean>,
	enabled : prop<boolean>,

	container : immutable_prop<any>,
	config : immutable_prop<any>,
	datatype : immutable_prop<datatype>,

	__type : "input_option",
}

-----------------------------------------------------------------------------------------------------------------

export type number_input_option = input_option_base<number, "number", number_input_option, number> & 
{
	num_info : prop<num_info>,
}

export type string_input_option = input_option_base<string, "string", string_input_option, string> & 
{
	max_length : prop<number>,
}

export type dropdown_input_option = input_option_base<string?, "dropdown", dropdown_input_option, string> & 
{
	choices : prop<{
		[number] : string
	}>,
}

export type boolean_input_option = input_option_base<boolean, "boolean", boolean_input_option, boolean>

-----------------------------------------------------------------------------------------------------------------

export type input_option = 
	  number_input_option 
	| string_input_option 
	| dropdown_input_option
	| boolean_input_option

-----------------------------------------------------------------------------------------------------------------

return nil

-----------------------------------------------------------------------------------------------------------------