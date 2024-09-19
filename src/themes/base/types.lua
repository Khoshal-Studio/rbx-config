--!strict

----------------------------------------------------------------------------------------------------------------

local config_types = require(script.Parent.Parent.Parent:WaitForChild("config_types"))

----------------------------------------------------------------------------------------------------------------

export type prop<T> = config_types.prop<T>
export type public_prop<T> = config_types.public_prop<T>
export type immutable_prop<T> = config_types.immutable_prop<T>
export type object_base<T> = config_types.object_base<T>
export type get<T> = config_types.get<T>
export type set<T> = config_types.set<T>

export type signal = config_types.signal
export type fire<T> = config_types.fire<T>
export type connection = config_types.connection
export type restricted_signal = config_types.restricted_signal

----------------------------------------------------------------------------------------------------------------

type proto_data_base<T, V> = config_types.data_base<T, V>

export type data_base<option_type, datatype, frame> = proto_data_base<option_type, datatype> & 
{
    visible : boolean?,
    layout_order : number?,

    frame : frame?,
}

----------------------------------------------------------------------------------------------------------------

export type boolean_data = config_types.boolean_data & data_base<"boolean", boolean, boolean_frame>

export type number_data = config_types.number_data & data_base<"number", number, input_frame> & 
{
    enter_required : boolean?,
	zero_on_nil : boolean?,
	slider_enabled : boolean? -- TODO: Add slider feature
}

export type string_data = config_types.string_data & data_base<"string", string, input_frame> & 
{
    enter_required : boolean?
}

export type dropdown_data = config_types.dropdown_data & data_base<"dropdown", string, dropdown_frame> & 
{
    nil_placeholder : string?,
}

export type data = 
    boolean_data
  | number_data
  | string_data
  | dropdown_data

export type objects = {
    [number] : data | container_data
}

export type container_data =
{
    key : string,
    objects : {
        [number] : data | container_data
    },

    layout_order : number?,
    visible : boolean?,
    enabled : boolean?,
}

----------------------------------------------------------------------------------------------------------------

type proto_input_option_base<type, datatype, self, export_type> = config_types.input_option_base<type, datatype, self, export_type>

export type input_option_base<type, frame> =
{
    frame : immutable_prop<frame>,
    visible : prop<boolean>,
    layout_order : prop<number>,
		
	focused : signal,
		
    original_value : prop<type>,
}

export type input_option_root = input_option_base<any, any> & proto_input_option_base<any, any, any, any>

----------------------------------------------------------------------------------------------------------------

export type boolean_input_option = config_types.boolean_input_option & input_option_base<boolean, boolean_frame>

export type number_input_option = config_types.number_input_option & input_option_base<number, input_frame> & 
{
    enter_required : prop<boolean>,
	zero_on_nil : prop<boolean>,
	slider_enabled : prop<boolean>
}

export type string_input_option = config_types.string_input_option & input_option_base<string, input_frame> & 
{
    enter_required : prop<boolean>
}

export type dropdown_input_option = config_types.dropdown_input_option & input_option_base<string?, dropdown_frame> & 
{
    nil_placeholder : prop<string>
}

export type input_option = 
    boolean_input_option
  | number_input_option
  | string_input_option
  | dropdown_input_option

export type input_object = input_option | input_container

export type input_objects = 
{
    [string] : input_option | input_container
}

export type input_container = config_types.input_container & 
{
    frame : immutable_prop<container_frame>,
    visible : prop<boolean>,
    layout_order : prop<number>,

    foreach : (callback : (object : any) -> ()) -> (),
    foreach_recursive : (callback : (object : any) -> ()) -> (),
}

export type internal_input_container = input_container & 
{
    __objects : 
    {
        [string] : any
    },
}

----------------------------------------------------------------------------------------------------------------

export type config_setup = config_types.config_setup<data, container_data> & 
{
    requires_apply : boolean?,
    sidebar_visible : boolean?,
    title : string?,
    draggable : boolean?,
    visible : boolean?,
}

----------------------------------------------------------------------------------------------------------------

export type container_frame = Frame & 
{
    container_label : TextLabel
}

export type choice_template = TextButton &
{
    option_name : TextLabel
}

export type config_datatype_frame_base = Frame & 
{
    reset_btn: ImageButton,
    option_name : TextLabel
}

export type input_frame = config_datatype_frame_base & 
{
    input : TextBox,
}

export type boolean_frame = config_datatype_frame_base & 
{
	button_frame : Frame & {
		checkbox : TextButton
	}
}

export type dropdown_frame = config_datatype_frame_base & 
{
    dropdown : Frame & 
    {
        options : ScrollingFrame,
        choice : choice_template & {
            arrow_indicator : ImageLabel
        }
    },
}

export type config_frame = Frame & 
{
    config : Frame & 
    {
        config : ScrollingFrame,
        sidebar : Frame & 
        {
            title : TextLabel,
            info : ScrollingFrame & 
            {
                description : TextLabel
            }
        }
    },

    bottom_bar : Frame &
    {
        title : TextLabel,
        apply : TextButton,
    },

    header : Frame & 
    {
        title : TextLabel,
        close : TextButton,
    }
}

----------------------------------------------------------------------------------------------------------------

export type window = 
{
    title : prop<string>,
    draggable : prop<boolean>,
    visible : prop<boolean>,
    close : () -> (),
    view : () -> (),

    __type : "config_window",
}

export type config_window = window & 
{
    frame : immutable_prop<config_frame>,
    requires_apply : prop<boolean>,

    objects : immutable_prop<input_objects>,
    get_object : (key : string) -> input_option | input_container | nil, 
    get_object_from_path : (path : {[number] : string} | string) -> input_option | input_container | nil,

    sidebar_visible : prop<boolean>,

    export : () -> {[string] : any},
    apply : () -> (),

    changed : restricted_signal,
    applied : restricted_signal,
    
    foreach : (callback : (object : any) -> ()) -> (),
    foreach_recursive : (callback : (object : any) -> ()) -> (),
}

export type config_window_internal = config_window & 
{
    __objects : input_objects,
    __changed : signal,
    __applied : signal
}

----------------------------------------------------------------------------------------------------------------

return nil

----------------------------------------------------------------------------------------------------------------