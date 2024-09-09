--!strict

---------------------------------------------------------------------------------------------------------------

local module = {}

---------------------------------------------------------------------------------------------------------------

local UserInputService = game:GetService("UserInputService")

---------------------------------------------------------------------------------------------------------------

local dependencies = script.Parent

local dragger_types = require(script:WaitForChild("dragger_types"))

local props = require(dependencies:WaitForChild("props"))
local signal = require(dependencies:WaitForChild("signal"))

---------------------------------------------------------------------------------------------------------------

local currently_dragging : dragger? = nil

---------------------------------------------------------------------------------------------------------------

export type dragger_info = dragger_types.dragger_info
export type dragger = dragger_types.dragger
export type internal_dragger = dragger_types.internal_dragger

export type get<T> = props.get<T>
export type set<T> = props.set<T>
export type immutable_prop<T> = props.immutable_prop<T>
export type prop<T> = props.prop<T>

export type signal = signal.signal
export type restricted_signal = signal.restricted_signal
export type fire<T> = signal.fire<T>

---------------------------------------------------------------------------------------------------------------

local function is_natural(n : number)
    return (n > 0 and n % 1 == n)
end

local function package(value : any)
    return {
        value = value,
        cancel = false
    }
end

local function update(input : InputObject, drag_start : Vector3, start_pos : UDim2) : UDim2?
    if currently_dragging then
        local self = currently_dragging

        local delta : Vector3 = input.Position - drag_start
        local new_position : UDim2 = UDim2.new(start_pos.X.Scale, start_pos.X.Offset + delta.X, start_pos.Y.Scale, start_pos.Y.Offset + delta.Y)
        if self.update.get() then
            self.target.get().Position = new_position
        end

        return new_position
    end

    return nil
end

--[=[
    Enables the dragger to start dragging the target object.
]=]--
local function dragger_enable(self : internal_dragger, key_code : Enum.KeyCode?) : ()
    local object : GuiObject = self.object.get()

    local preparing_to_drag : boolean = false
    local drag_input : InputObject = nil
    local drag_start : Vector3 = nil
    local start_pos : UDim2 = nil

    self.input_began = object.InputBegan:Connect(function(input : InputObject)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if key_code and not UserInputService:IsKeyDown(key_code) then
                return
            end

            preparing_to_drag = true

            local connection : RBXScriptConnection = nil
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End and (self.dragging.get() or preparing_to_drag) then
                    self.dragging_internal.set(false)
                    connection:Disconnect()

                    if not preparing_to_drag then
                        self.drag_end_internal:Fire()
                    end

                    preparing_to_drag = false
                end
            end)
        end
    end)

    self.input_changed = object.InputChanged:Connect(function(input : InputObject) : ()
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            drag_input = input
        end
    end)

    self.input_changed_2 = UserInputService.InputChanged:Connect(function(input : InputObject) : ()
        if object.Parent == nil then
            self:disable()
            return
        end

        if preparing_to_drag then
            if key_code and not UserInputService:IsKeyDown(key_code) then
                preparing_to_drag = false
                return
            end

            self.drag_start_internal:Fire()
            self.dragging_internal.set(true)

            preparing_to_drag = false
            currently_dragging = self
            drag_start = input.Position
            start_pos = self.target.get().Position
        end

        if input == drag_input and self.dragging.get() and self.rate_limit.get() then
            if key_code and not UserInputService:IsKeyDown(key_code) then
                self.dragging_internal.set(false)
                return
            end

            self.drag_count_internal.set(self.drag_count.get() + 1)
            if self.drag_count.get() % self.rate_limit.get() ~= 0 then
                return
            end

            local new_position : UDim2? = update(input, drag_start, start_pos)
            self.dragged_internal:Fire(new_position)
        end
    end)

    self.enabled_internal.set(true)
end


--[=[
    Disables the dragger from dragging the target object.
]=]--
local function disable_dragger(self : internal_dragger) : ()
    if self.enabled.get() and self.input_began and self.input_changed and self.input_changed_2 then
        self.input_began:Disconnect()
        self.input_changed:Disconnect()
        self.input_changed_2:Disconnect()
    end

    if self.dragging.get() then
        self.dragging_internal.set(false)
        currently_dragging = nil

        self.drag_end_internal:Fire()
    end

    self.enabled_internal.set(false)
end

local function valid_dragger_info(info : dragger_info) : boolean
    if info.rate_limit then
        if info.rate_limit < 1 then
            warn("Rate limit must be greater than or equal to 1.")
            return false
        end
        if info.rate_limit % 1 ~= 0 then
            warn("Rate limit must be an integer.")
            return false
        end
    end

    return true
end

--[=[
    Creates a new dragger object.

    @param info : `dragger_info` — The information to create the dragger object.
    @return `dragger` : `dragger` — The dragger object.
]=]
module.new = function(info : dragger_info) : (boolean, dragger?)
    if not valid_dragger_info(info) then
        return false
    end

    --[[----------------------------------------------------------------------]]--

    local dragger : internal_dragger
    
    --[[----------------------------------------------------------------------]]--

    local dragging_internal = props(false)
    local drag_count_internal = props(0)
    local enabled_internal = props(false)
    local drag_start_internal = signal()
    local drag_end_internal = signal()
    local dragged_internal = signal()

    --[[----------------------------------------------------------------------]]--

    local function cancel(key : string)
        return {
            value = (dragger :: any)[key].get(),
            cancel = true
        }
    end

    --[[----------------------------------------------------------------------]]--

    local rate_limit_info = {
        set = {
            function(new_value : number)
                if not is_natural(new_value) then
                    return cancel("rate_limit")
                end

                return package(new_value)
            end
        }
    }

    local object_info = {
        set = {
            function(new_value : GuiObject)
                if not new_value:IsA("GuiObject") then
                    return cancel("object")
                end

                return package(new_value)
            end
        }
    }

    --[[----------------------------------------------------------------------]]--

    local function object_changed(new_value : GuiObject)
        dragger:disable()  

        if dragger.enabled.get() then
            dragger:enable()
        end
    end

    --[[----------------------------------------------------------------------]]--

    dragger = {
        input_began = nil,
        input_changed = nil,
        input_changed_2 = nil,

        drag_start_internal = drag_start_internal,
        drag_end_internal = drag_end_internal,
        dragged_internal = dragged_internal,

        enabled_internal = enabled_internal,
        dragging_internal = dragging_internal,
        drag_count_internal = drag_count_internal,

        object = props(info.object, object_info),
        target = props(info.target or info.object),

        drag_started = drag_start_internal.Restricted,
        dragged = dragged_internal.Restricted,
        drag_ended = drag_end_internal.Restricted,

        rate_limit = props(info.rate_limit or 1, rate_limit_info),
        update = props((info.update or true) :: any),

        dragging = dragging_internal.immutable,
        drag_count = drag_count_internal.immutable,
        enabled = enabled_internal.immutable,

        enable = function(self : any, key_code : Enum.KeyCode?) : ()
            dragger_enable(self)
        end,

        disable = function(self : any) : ()
            disable_dragger(self)
        end
    }

    --[[----------------------------------------------------------------------]]--

    dragger.object.changed:Connect(object_changed)

    --[[----------------------------------------------------------------------]]--

    return true, dragger
end

-------------------------------------------------------------------------------------

return table.freeze(module)

-------------------------------------------------------------------------------------