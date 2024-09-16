--!strict

------------------------------------------------------------------------------------------------

export type data_root<option_type, datatype> = 
{
	key : string,

	default_value : datatype,

	resetable : boolean?,
	enabled : boolean?,

	description : string?,
}

------------------------------------------------------------------------------------------------

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

------------------------------------------------------------------------------------------------

export type dropdown_data = data_root<"dropdown", string> & 
{
	choices : 
	{
		[number] : string
	},  
}

export type string_data = data_root<"string", string> & 
{
	max_length : number?,
}

export type number_data = data_root<"number", number> & 
{
	num_info : num_info,
}

export type boolean_data = data_root<"boolean", boolean>

export type vector3 = data_root<"vector3", Vector3>

------------------------------------------------------------------------------------------------

export type data = 
    boolean_data
  | string_data 
  | number_data
  | dropdown_data

------------------------------------------------------------------------------------------------

return nil

------------------------------------------------------------------------------------------------