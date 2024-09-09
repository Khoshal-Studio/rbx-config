--!strict

-------------------------------------------------------------------------------------------

export type disconnect = (self: connection) -> ()

--[=[
    @type connection {
        Disconnect: (self: connection) -> ()
    }
    @within signal
    A connection object that can be used to disconnect the signal handler.
]=]
export type connection = {
    Disconnect: disconnect
}

export type internal_connection = 
{
    connected : boolean,
    signal : internal_signal,
    fn : (...any) -> (),
    next : internal_connection?,

    Disconnect : disconnect
}

-------------------------------------------------------------------------------------------

export type connect<T> = (self: T, handler: (...any) -> ()) -> connection
export type disconnect_all<T> = (self: T) -> ()
export type fire<T> = (...any) -> ()
export type wait<T> = (self: T) -> ...any
export type once<T> = (self: T, handler: (...any) -> ()) -> connection
export type get_restricted<T> = (self : T) -> restricted_signal

--[=[
    @type signal {
        Connect: (self: signal, handler: (...any) -> ()) -> connection,
        DisconnectAll: (self: signal) -> (),
        Fire: (self: signal, ...any) -> (),
        Wait: (self: signal) -> ...any,
        Once: (self: signal, handler: (...any) -> ()) -> connection,
    }
    @within signal
    A signal object that can be connected to and fired.
]=]
export type signal = 
{
    Connect : connect<signal>,
    DisconnectAll : disconnect_all<signal>,
    Fire : fire<signal>,
    Wait : wait<signal>,
    Once : once<signal>,
    Restricted : restricted_signal
}

export type internal_signal = signal &
{
    handler_list_head : internal_connection?,
}

--[=[
    @type fire_fn {
        (...any) -> ()
    }
    @within signal
    A function that fires the signal with the given arguments.
]=]

--[=[
    @type restricted_signal {
        Connect: (self: restricted_signal, handler: (...any) -> ()) -> connection,
        DisconnectAll: (self: restricted_signal) -> (),
        Wait: (self: restricted_signal) -> ...any,
        Once: (self: restricted_signal, handler: (...any) -> ()) -> connection,
    }
    @within signal
    A restricted signal object that can be connected to and fired.
]=]
export type restricted_signal = 
{
    Connect : connect<restricted_signal>,
    DisconnectAll : disconnect_all<restricted_signal>,
    Wait : wait<restricted_signal>,
    Once : once<restricted_signal>,
}

-------------------------------------------------------------------------------------------

return nil

-------------------------------------------------------------------------------------------