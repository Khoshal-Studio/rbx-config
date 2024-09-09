--!strict

---------------------------------------------------------------------------------------

local dependencies = script.Parent.Parent

local props = require(dependencies:WaitForChild("props"))
local signal = require(dependencies:WaitForChild("signal"))

---------------------------------------------------------------------------------------

export type get<T> = props.get<T>
export type set<T> = props.set<T>
export type immutable_prop<T> = props.immutable_prop<T>
export type prop<T> = props.prop<T>

export type signal = signal.signal
export type restricted_signal = signal.restricted_signal
export type fire<T> = signal.fire<T>

---------------------------------------------------------------------------------------

export type dragger_info = 
{
    object : GuiObject,
    target : GuiObject?,
    rate_limit : number?,
    update : boolean?,
}

export type dragger = 
{
    object : prop<GuiObject>,
    target : prop<GuiObject>,

    rate_limit : prop<number>,
    update : prop<boolean?>,

    dragging : immutable_prop<boolean>,
    drag_count : immutable_prop<number>,

    enabled : immutable_prop<boolean>,

    drag_started : restricted_signal,
    dragged : restricted_signal,
    drag_ended : restricted_signal,

    enable : (self : any, key_code : Enum.KeyCode?) -> (),
    disable : (self : any) -> ()
}

export type internal_dragger = dragger & 
{
    input_began : RBXScriptConnection?,
    input_changed : RBXScriptConnection?,
    input_changed_2 : RBXScriptConnection?,

    drag_start_internal : signal,
    drag_end_internal : signal,
    dragged_internal : signal,

    enabled_internal : prop<boolean>,
    dragging_internal : prop<boolean>,
    drag_count_internal : prop<number>,
}

return nil

---------------------------------------------------------------------------------------