--!strict

----------------------------------------------------------------------------------------------------------------

local dependencies = script.Parent.dependencies

local prop_types = require(dependencies:WaitForChild("props"):WaitForChild("props_types"))
local signal_types = require(dependencies:WaitForChild("signal"):WaitForChild("signal_types"))
local dragger_types = require(dependencies:WaitForChild("dragger"):WaitForChild("dragger_types"))

----------------------------------------------------------------------------------------------------------------

local option_data_types = require(script:WaitForChild("option_data"))
local input_option_types = require(script:WaitForChild("input_option"))

----------------------------------------------------------------------------------------------------------------

export type restricted_signal = signal_types.restricted_signal
export type signal = signal_types.signal
export type fire<T> = signal_types.fire<T>
export type connection = signal_types.connection

export type dragger = dragger_types.dragger
export type dragger_info = dragger_types.dragger_info

export type prop<T> = prop_types.prop<T>
export type public_prop<T> = prop_types.public_prop<T>
export type immutable_prop<T> = prop_types.immutable_prop<T>

export type middleware_return<T> = prop_types.middleware_return<T>
export type middleware<T> = prop_types.middleware<T>
export type middleware_obj<T> = prop_types.middleware_obj<T>
export type middleware_info<T> = prop_types.middleware_info<T>

export type get<T> = prop_types.get<T>
export type set<T> = prop_types.set<T>

export type object_base<T> = prop_types.object_base<T>

----------------------------------------------------------------------------------------------------------------

export type num_info = option_data_types.num_info
export type data_base<option_type, datatype> = option_data_types.data_root<option_type, datatype>
export type dropdown_data = option_data_types.dropdown_data
export type string_data = option_data_types.string_data
export type number_data = option_data_types.number_data
export type boolean_data = option_data_types.boolean_data
export type data = option_data_types.data

----------------------------------------------------------------------------------------------------------------

export type container_data =
{
    key : string,
    objects : config_setup<data, container_data>,
}

-----------------------------------------------------------------------------------------------------------------

export type number_input_option = input_option_types.number_input_option
export type string_input_option = input_option_types.string_input_option
export type dropdown_input_option = input_option_types.dropdown_input_option
export type boolean_input_option = input_option_types.boolean_input_option
export type input_option = input_option_types.input_option

-----------------------------------------------------------------------------------------------------------------

export type input_container =
{
    key : prop<string>,
    objects : immutable_prop<any>,

    get_object : (key : string) -> any?,

    get_path : () -> string,

    export : () -> {[string] : any},

    enabled : prop<boolean>,
    container : immutable_prop<any>,
    config : immutable_prop<any>,

    delete : () -> (),

    __type : "input_container",
}

----------------------------------------------------------------------------------------------------------------

export type input = object_base<"input"> & 
{
    [string] : input_option | input_container
}

----------------------------------------------------------------------------------------------------------------

export type config_objects<T, V> = {
	[number] : T | V
}

export type config_setup<T,V> = 
{
	objects : config_objects<T, V>,
}

----------------------------------------------------------------------------------------------------------------

return nil

----------------------------------------------------------------------------------------------------------------