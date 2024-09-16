--!strict

----------------------------------------------------------------------------------------------------------------

local dependencies = script.Parent.dependencies

local prop_types = require(dependencies:WaitForChild("props"):WaitForChild("props_types"))
local signal_types = require(dependencies:WaitForChild("signal"):WaitForChild("signal_types"))
local dragger_types = require(dependencies:WaitForChild("dragger"):WaitForChild("dragger_types"))

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

export type primitive_datatype =
    boolean
  | string
  | number

export type option_type = 
    "boolean"
  | "string"
  | "number"
  | "dropdown"

export type table<I,V> = 
{
    [I] : V
}

----------------------------------------------------------------------------------------------------------------

export type num_info = 
{
    signed : boolean?,
    decimal_limit : number?,
    int : boolean?,

    limit : 
    {
        min : number?,
        max : number?,
    }?
}

----------------------------------------------------------------------------------------------------------------

export type data_base<option_type, datatype> = 
{
    key : string,

    default_value : datatype,

    resetable : boolean?,
    enabled : boolean?,

    description : string?,
}

----------------------------------------------------------------------------------------------------------------

export type dropdown_data = data_base<"dropdown", string> & 
{
    choices : table<number, string>,
}

export type string_data = data_base<"string", string> & 
{
    max_length : number?,
}

export type number_data = data_base<"number", number> & 
{
    num_info : num_info,
}

export type boolean_data = data_base<"boolean", boolean>

----------------------------------------------------------------------------------------------------------------

export type data = 
    boolean_data
  | string_data 
  | number_data
  | dropdown_data

export type container_data<option_data_type, container_data_type> =
{
    key : string,
    objects : config_setup<option_data_type, container_data_type>,
}

export type config_objects<T, V> = table<number, T | V>

export type config_setup<T,V> = 
{
    objects : config_objects<T, V>,
}

-----------------------------------------------------------------------------------------------------------------

export type input_option_base<type, datatype, self, export_type> =
{    
    key            : prop<string>,
    description    : prop<string>,
    original_value : prop<type>,
    default_value  : prop<type>,
    resetable      : prop<boolean>,
    enabled        : prop<boolean>,

    datatype       : immutable_prop<datatype>,
    config         : prop<any>,
    container      : prop<any>,

    middleware     : middleware_info<type>,

    get            : get<type>,
    set            : set<type>,

    export         : () -> export_type,
    get_path       : () -> string,
    delete         : () -> (),
    reset          : () -> (),

    changed        : signal,

    __type         : "input_option",
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
    choices : prop< table<number, string> >,
}

export type boolean_input_option = input_option_base<boolean, "boolean", boolean_input_option, boolean>

-----------------------------------------------------------------------------------------------------------------

export type input_option = 
    number_input_option 
  | string_input_option 
  | dropdown_input_option
  | boolean_input_option

-----------------------------------------------------------------------------------------------------------------

export type input_container =
{
    key         : prop<string>,
    enabled     : prop<boolean>,
    objects     : immutable_prop<any>,

    container   : prop<any>,
    config      : prop<any>,

    delete      : () -> (),
    get_object  : (key : string) -> any?,
    get_path    : () -> string,
    export      : () -> table<string, any>,

    __type      : "input_container",
}

----------------------------------------------------------------------------------------------------------------

return nil

----------------------------------------------------------------------------------------------------------------