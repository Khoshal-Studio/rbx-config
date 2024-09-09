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
    choices : 
    {
        [number] : string
    },  
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

export type container_data =
{
    key : string,
    objects : config_setup<data, container_data>,
}

export type config_objects<T, V> = {
    [number] : T | V
}

export type config_setup<T,V> = 
{
    objects : config_objects<T, V>,
}

-----------------------------------------------------------------------------------------------------------------

export type input_option_base<type, datatype, self, export_type> = object_base<"input_option"> & 
{
    get : get<type>,
    set : set<type>,
    changed : signal,
    middleware : middleware_info<type>,

    export : () -> export_type,
    get_path : () -> string,
    
    delete : (self : self) -> (),
    reset : (self : self) -> (),
    
    key : prop<string>,
    description : prop<string>,

    original_value : prop<type>,
    default_value : prop<type>,

    resetable : prop<boolean>,
    enabled : prop<boolean>,
    
    __container : any?,
    __config : any?,
    __type : "input_option",
    __datatype : datatype,
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

export type input_container = object_base<"input_container"> & 
{
    key : prop<string>,
    objects : immutable_prop<any>,

    get_object : (key : string) -> any?,

    get_path : () -> string,

    export : () -> {[string] : any},

    enabled : prop<boolean>,
    __container : any?,
    __config : any?,

    delete : (self: any) -> (),
}

----------------------------------------------------------------------------------------------------------------

export type input = object_base<"input"> & 
{
    [string] : input_option | input_container
}

----------------------------------------------------------------------------------------------------------------

return nil

----------------------------------------------------------------------------------------------------------------