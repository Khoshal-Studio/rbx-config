--!strict

-------------------------------------------------------------------------------------------

local signal = require(script.Parent.Parent:WaitForChild("signal"))

-------------------------------------------------------------------------------------------

type signal = signal.signal
type restricted_signal = signal.restricted_signal

-------------------------------------------------------------------------------------------

export type get<T> = (...any?) -> T
export type set<T> = (new_value : T, ...any?) -> ()

-- @type immutable_prop
-- Public interface of an immutable prop, intended to be read-only
export type immutable_prop<T> = 
{
    get : get<T>,

    changed : restricted_signal,
}

-- @type public_prop
-- Public interface of a mutable prop
export type public_prop<T> = 
{
    get : get<T>,
    set : set<T>,
    
    changed : restricted_signal,
}

-- @type middleware_return
-- Return type of a middleware function
-- value : The value that will be passed to the next middleware
-- cancel : If true, the middleware chain will be stopped
export type middleware_return<T> = 
{
    value : T,
    cancel : boolean
}

export type middleware<T> = (value : T, ...any?) -> middleware_return<T>

export type middleware_info<T> = 
{
    get : middleware_obj<T>,
    set : middleware_obj<T>,
}

-- @type middleware_obj
-- A proxy object that manages a list of middleware functions
export type middleware_obj<T> = 
{
    get : (index : number) -> middleware<T>,

    add : (middleware : middleware<T>, index : number?) -> (),
    add_list : (list : {[number] : middleware<T>}) -> (),
    remove : (index : number) -> (),

    clear : () -> (),

    apply : (value : T, ...any?) -> T,
}

-- @type middleware_init
-- Initial middleware that will be applied to the prop
-- Optional parameter when creating a prop
export type middleware_init<T> = 
{
    get : {
        [number] : middleware<T>
    }?,
    set : {
        [number] : middleware<T>
    }?
}

export type prop<T> = 
{
    get : get<T>,
    set : set<T>,

    middleware : middleware_info<T>,

    changed : signal,

    immutable : immutable_prop<T>,
    public : public_prop<T>,
}

export type object_base<T> = 
{
    __type : T
}

-------------------------------------------------------------------------------------------

return nil

-------------------------------------------------------------------------------------------