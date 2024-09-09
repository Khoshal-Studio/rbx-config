--!strict

-------------------------------------------------------------------------------------------

local signal_types : nil = require(script:WaitForChild("signal_types"))

export type connection = signal_types.connection
export type signal = signal_types.signal
type internal_signal = signal_types.internal_signal
type internal_connection = signal_types.internal_connection
export type fire<T> = signal_types.fire<T>
export type restricted_signal = signal_types.restricted_signal

-------------------------------------------------------------------------------------------

--[=[
    Creates a connection object that can be used to disconnect the signal handler.

    @within signal
    @param signal : signal — The signal object.
    @param fn : `(...any) -> ()` — The signal handler function.
    @return connection : connection — The connection object.
]=]
local function connection_new(signal: internal_signal, fn: (...any) -> ()) : connection

    --[[----------------------------------------------------------------------]]--s

    local connection : internal_connection = nil

    --[[----------------------------------------------------------------------]]--

    local function disconnect(self : internal_connection)
        if not self.connected then return end

        self.connected = false

        if self.signal.handler_list_head == self then
            self.signal.handler_list_head = self.next
        else
            local prev : internal_connection? = self.signal.handler_list_head

            while prev and prev.next ~= self do
                prev = prev.next
            end

            if prev then
                prev.next = self.next
            end
        end
    end

    --[[----------------------------------------------------------------------]]--

    connection = {
        connected = true,
        signal = signal,
        fn = fn,
        next = nil,

        Disconnect = disconnect
    } :: any

    --[[----------------------------------------------------------------------]]--

    return (connection :: any) :: connection
end

-------------------------------------------------------------------------------------------

--[=[
    Creates a new signal object.

    @function signal.new
    @within signal
    @return signal : `signal` — The signal object.
]=]
local function signal_new() : signal

    --[[----------------------------------------------------------------------]]--
    
    local signal : internal_signal = nil

    --[[----------------------------------------------------------------------]]--

    
    --[=[
        Connects a handler function to the signal.

        @within signal
        @method Connect
        @param self : signal — The signal object.
        @param fn : `(...any) -> ()` — The signal handler function.
        @return connection : `connection` — The connection object.
    ]=]
    local function connect(self : internal_signal, fn: (...any) -> ()) : connection
        if (self :: any).__index then self = (self :: any).__index end

        local connection : internal_connection = connection_new(self, fn) :: any

        if self.handler_list_head then
            connection.next = self.handler_list_head
            self.handler_list_head = connection
        else
            self.handler_list_head = connection
        end

        return connection :: connection
    end

    --[=[
        Disconnects all handler functions from the signal.

        @function signal.DisconnectAll
        @within signal
        @param self : `signal` — The signal object.
    ]=]

    local function disconnect_all(self : internal_signal)
        if (self :: any).__index then self = (self :: any).__index end

        self.handler_list_head = nil
    end

    --[=[
        Fires the signal with the given arguments.

        @function signal.Fire
        @within signal
        @param self : `signal` — The signal object.
        @param ... : `any` — The arguments to pass to the signal handlers.
    ]=]
    local function fire(self : internal_signal, ...)
        local item = (self.handler_list_head :: any) :: internal_connection 

        while item do
            if item.connected then
                task.spawn(item.fn, ...)
            end

            item = item.next :: any
        end
    end

    --[=[
        Yields the current thread until the signal is fired.

        @function signal.Wait
        @within signal
        @param self : `signal` — The signal object.
        @return ... : `any` — The arguments passed to the signal handlers.
        @yields
    ]=]
    local function wait(self : internal_signal, ...)
        if (self :: any).__index then self = (self :: any).__index end

        local waiting_coroutine = coroutine.running()

        local connection : connection = nil
        connection = self:Connect(function(...)
            connection:Disconnect()
            task.spawn(waiting_coroutine, ...)
        end)

        return coroutine.yield()
    end

    --[=[
        Connects a handler function to the signal that will only be called once.

        @function signal.Once
        @within signal
        @param self : `signal` — The signal object.
        @param fn : `(...any) -> ()` — The signal handler function.
        @return connection : `connection` — The connection object.
    ]=]
    local function once(self : internal_signal, fn: (...any) -> ())
        if (self :: any).__index then self = (self :: any).__index end

        local connection : connection = nil
        connection = self:Connect(function(...)
            local internal = connection :: internal_connection
            if internal.connected then
                connection:Disconnect()
            end

            fn(...)
        end)

        return connection
    end
    
    --[[----------------------------------------------------------------------]]--

    local restricted = {
        Connect = connect,
        DisconnectAll = disconnect_all,
        Wait = wait,
        Once = once,
    }

    --[[----------------------------------------------------------------------]]--

    signal = {
        handler_list_head = nil,

        Connect = connect,
        DisconnectAll = disconnect_all,
        Fire = fire,
        Wait = wait,
        Once = once,
        Restricted = restricted
    } :: any

    --[[----------------------------------------------------------------------]]--

    restricted.__index = signal

    --[[----------------------------------------------------------------------]]--

    return (signal :: any) :: signal
end 

-------------------------------------------------------------------------------------------

return signal_new

-------------------------------------------------------------------------------------------