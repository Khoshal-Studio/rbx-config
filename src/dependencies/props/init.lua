--!strict

----------------------------------------------------------------------------------------------------------------

local props_types : nil = require(script:WaitForChild("props_types"))
local signal = require(script.Parent:WaitForChild("signal"))

----------------------------------------------------------------------------------------------------------------

type signal = signal.signal
type restricted_signal = signal.restricted_signal

export type get<T> = props_types.get<T>
export type set<T> = props_types.set<T>

export type immutable_prop<T> = props_types.immutable_prop<T>
export type prop<T> = props_types.prop<T>

export type object_base<T> = props_types.object_base<T>

export type middleware<T> = props_types.middleware<T>
export type middleware_obj<T> = props_types.middleware_obj<T>

export type middleware_init<T> = props_types.middleware_init<T>

----------------------------------------------------------------------------------------------------------------

local function new_middleware_obj<T>(list : {[number] : middleware<T>}?) : middleware_obj<T>
    local local_list : {
        [number] : middleware<T>
    } = list or {}

    local function add(middleware : middleware<T>, index : number?)
        if index then
            table.insert(local_list, index, middleware)
        else
            table.insert(local_list, middleware)
        end
    end

    local function add_list(list : {[number] : middleware<T>})
        for _, middleware in ipairs(list) do
            table.insert(local_list, middleware)
        end
    end

    local function remove(index : number)
        table.remove(local_list, index)
    end

    local function get(index : number) : middleware<T>
        return local_list[index]
    end
    
    local function clear()
        local_list = {}
    end

    local function apply(value : T, ... : any?): T
        local current_value = value
        
        for _, middleware in ipairs(local_list) do
            local result = middleware(current_value, ...)

            if result.cancel then
                break
            end

            current_value = result.value
        end

        return current_value
    end

    return {
        add = add,
        add_list = add_list,
        remove = remove,
        get = get,
        clear = clear,
        apply = apply
    }
end

----------------------------------------------------------------------------------------------------------------

local function __deep_clone<T>(value : T) : T
    local value_type = typeof(value)

    if value_type == "table" then
        local new_table = {}

        for key, x in value :: any do
            new_table[key] = __deep_clone(x)
        end

        return new_table :: any
    end

    return value
end

----------------------------------------------------------------------------------------------------------------

local function new_prop<T>(init_value : T, middleware : middleware_init<T>?, typecheck : boolean?) : prop<T>
    local prop : prop<T> = nil

    local current_value = init_value
    local changed = signal()
    local typecheck_toggle = typecheck or false
    local init_type = typeof(init_value)

    --[[----------------------------------------------------------------------]]--

    local get = function(... : any?) : T
        local value = prop.middleware.get.apply(current_value, ...)

        -- "no!" - @alliancecrusader
        --[[
        if init_type == "table" then
            return deep_clone(value)
        end
        ]]

        return value
    end

    local set = function(new_value : T, ... : any?)
        if typecheck_toggle and (typeof(new_value) ~= init_type) then
            warn("Invalid type for prop, expected: " .. init_type .. ", got: " .. typeof(new_value))
            return
        end

        local value = prop.middleware.set.apply(new_value, ...)

        if value == current_value then
            return
        end

        -- local previous_value = current_value
        current_value = value
        
        changed:Fire(current_value--[[, previous_value]])
    end

    --[[----------------------------------------------------------------------]]--

    local get_middleware_obj = new_middleware_obj(if middleware then middleware.get else nil)
    local set_middleware_obj = new_middleware_obj(if middleware then middleware.set else nil)
    
    --[[----------------------------------------------------------------------]]--

    local immutable = {
        get = get,
        
        changed = changed.Restricted
    }

    local public = {
        get = get,
        set = set,

        changed = changed.Restricted
    }

    --[[----------------------------------------------------------------------]]--

    prop = {
        get = get,
        set = set,

        middleware = {
            get = get_middleware_obj,
            set = set_middleware_obj
        },

        changed = changed,
        
        immutable = immutable,
        public = public
    }

    --[[----------------------------------------------------------------------]]--

    return prop
end

----------------------------------------------------------------------------------------------------------------

return new_prop

----------------------------------------------------------------------------------------------------------------
