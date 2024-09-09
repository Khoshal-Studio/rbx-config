--!strict

---------------------------------------------------------------------------------------------

local module = {}

---------------------------------------------------------------------------------------------

local workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

---------------------------------------------------------------------------------------------

local camera = workspace.CurrentCamera
local size_change_event = RunService.PreRender

---------------------------------------------------------------------------------------------

local UDim2_new = UDim2.new
local UDim_new = UDim.new
local insert = table.insert

---------------------------------------------------------------------------------------------

export type xy = "X" | "Y"
export type xyz = xy | "XY"

export type text_object = TextButton | TextLabel | TextBox
export type connection = RBXScriptConnection
export type connection_list = {[number] : connection}

---------------------------------------------------------------------------------------------

export type axes = {
	Top : boolean,
	Bottom : boolean,
	Left : boolean,
	Right : boolean
}

export type inline_padding_attributes = {
	PaddingAmountPixels : number,
	Axes : axes,
	ViewportSize : Vector2,
}

export type padding_attributes = {
	PaddingAmountScale : number,
	PaddingAxis : xy
}

export type text_attributes = {
	TextSize : number,
	ViewportSize : Vector2,
	TextAxis : xyz
}

export type size_attributes = {
	Size : UDim2,
	ViewportSize : Vector2
}

export type layout_padding_attributes = {
	LayoutPaddingPixels : number,
	ViewportSize : Vector2,
}

---------------------------------------------------------------------------------------------

module.padding_adjust = function(padding : UIPadding, padding_amount_scale : number, axis : xy, connect : boolean?) : connection?
	local parent = padding.Parent

	if not (parent and parent:IsA("GuiObject")) then
		error("Need a parent")
	end

	local function update_padding()
		if not (parent and parent:IsA("GuiObject")) then
			return
		end

		if axis == "X" then
			padding.PaddingLeft = UDim_new(padding_amount_scale, 0)
			padding.PaddingRight = UDim_new(padding_amount_scale, 0)

			local padding_x_pixels = padding_amount_scale * parent.AbsoluteSize.X
			local padding_y_scale = padding_x_pixels / parent.AbsoluteSize.Y

			padding.PaddingTop = UDim_new(padding_y_scale, 0)
			padding.PaddingBottom = UDim_new(padding_y_scale, 0)
		elseif axis == "Y" then
			padding.PaddingTop = UDim_new(padding_amount_scale, 0)
			padding.PaddingBottom = UDim_new(padding_amount_scale, 0)

			local padding_y_pixels = padding_amount_scale * parent.AbsoluteSize.Y
			local padding_x_scale = padding_y_pixels / parent.AbsoluteSize.X

			padding.PaddingLeft = UDim_new(padding_x_scale, 0)
			padding.PaddingRight = UDim_new(padding_x_scale, 0)
		end
	end

	update_padding()

	if connect then
		return parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(update_padding)
	end

	return nil
end


module.padding_list_adjust = function(padding_list : {[number] : UIPadding}, padding_amount_scale : number, axis : xy, connect : boolean?) : connection_list?
	if connect then
		local connections = {}

		for _, v in ipairs(padding_list) do
			local connection = module.padding_adjust(v, padding_amount_scale, axis, connect) :: RBXScriptConnection
			insert(connections, connection)
		end

		return connections
	else
		for _, v in ipairs(padding_list) do
			module.padding_adjust(v, padding_amount_scale, axis, connect)
		end

		return nil
	end
end

---------------------------------------------------------------------------------------------

module.text_adjust = function(obj : text_object, text_size : number, viewport_size : Vector2, axis : xyz, connect : boolean?) : connection?
	local x = obj :: any

	if not (obj:IsA("TextLabel") or obj:IsA("TextBox") or obj:IsA("TextButton")) then
		return
	end

	local function update_text()

		local current_vp_size = camera.ViewportSize
		local scale_factor

		if axis == "X" then
			scale_factor = current_vp_size.X / viewport_size.X
		elseif axis == "Y" then
			scale_factor = current_vp_size.Y / viewport_size.Y
		elseif axis == "XY" then
			local scale_factor_x = current_vp_size.X / viewport_size.X
			local scale_factor_y = current_vp_size.Y / viewport_size.Y

			scale_factor = (scale_factor_x * scale_factor_y)^(1/2)
		end

		x.TextSize = text_size * scale_factor
	end

	update_text()

	if connect then
		return size_change_event:Connect(update_text)
	end

	return nil
end

module.text_list_adjust = function(text_list : {[number] : text_object}, text_size : number, viewport_size : Vector2, axis : xyz, connect : boolean?) : connection_list?
	if connect then
		local connections = {}

		for _, v in ipairs(text_list) do
			local connection = module.text_adjust(v, text_size, viewport_size, axis, connect) :: RBXScriptConnection
			insert(connections, connection)
		end

		return connections
	else
		for _, v in ipairs(text_list) do
			module.text_adjust(v, text_size, viewport_size, axis, connect)
		end

		return nil
	end
end

---------------------------------------------------------------------------------------------

module.size_adjust = function(obj : GuiObject, original_size : UDim2, viewport_size : Vector2, connect : boolean?) : connection?
	local parent = obj.Parent

	local function update_size()
		if not (parent and parent:IsA("GuiObject")) then
			return
		end

		local current_vp_size = camera.ViewportSize
		local scale_factor = current_vp_size.X / viewport_size.X

		print(scale_factor)

		obj.Size = UDim2_new(original_size.X.Scale, original_size.X.Offset * scale_factor, original_size.Y.Scale, original_size.Y.Offset * scale_factor)
	end

	update_size()

	if connect then
		return size_change_event:Connect(update_size)
	end

	return nil
end

module.size_list_adjust = function(size_list : {[number] : GuiObject}, original_size : UDim2, viewport_size : Vector2, connect : boolean?) : connection_list?
	if connect then
		local connections = {}

		for _, v in ipairs(size_list) do
			local connection = module.size_adjust(v, original_size, viewport_size, connect) :: RBXScriptConnection
			insert(connections, connection)
		end

		return connections
	else
		for _, v in ipairs(size_list) do
			module.size_adjust(v, original_size, viewport_size, connect)
		end

		return nil
	end
end

---------------------------------------------------------------------------------------------

module.inline_padding_adjust = function(padding : UIPadding, padding_amount_pixels : number, viewport_size : Vector2, axes : axes, connect : boolean?) : connection?
	local parent = padding.Parent

	if not (parent and parent:IsA("GuiObject")) then
		error("Need a parent")
	end

	local function update_padding()
		if not (parent and parent:IsA("GuiObject")) then
			return
		end

		local current_vp_size = camera.ViewportSize
		local scale_factor = (current_vp_size.X*current_vp_size.Y)^0.5 / (viewport_size.X*viewport_size.Y)^0.5

		local new_padding = UDim_new(0, padding_amount_pixels * scale_factor)

		local x : any = padding

		for i, v in pairs(axes) do
			if v == true then
				x["Padding"..i] = new_padding
			end
		end
	end

	update_padding()

	if connect then
		return size_change_event:Connect(update_padding)
	end

	return nil
end

module.inline_padding_list_adjust = function(padding_list : {[number] : UIPadding}, padding_amount_pixels : number, viewport_size : Vector2, axes : axes, connect : boolean?) : connection_list?
	if connect then
		local connections = {}

		for _, v in ipairs(padding_list) do
			local connection = module.inline_padding_adjust(v, padding_amount_pixels, viewport_size, axes, connect) :: RBXScriptConnection
			insert(connections, connection)
		end

		return connections
	else
		for _, v in ipairs(padding_list) do
			module.inline_padding_adjust(v, padding_amount_pixels, viewport_size, axes, connect)
		end

		return nil
	end
end

---------------------------------------------------------------------------------------------

module.layout_padding_adjust = function(layout : UIListLayout, original_padding : number, viewport_size : Vector2, connect : boolean?) : connection?
	local parent = layout.Parent

	if not (parent and parent:IsA("GuiObject")) then
		error("Need a parent")
	end

	local function update_padding()
		if not (parent and parent:IsA("GuiObject")) then
			return
		end

		local current_vp_size = camera.ViewportSize

		local scale_factor_x = current_vp_size.X / viewport_size.X
		local scale_factor_y = current_vp_size.Y / viewport_size.Y

		local scale_factor = (scale_factor_x * scale_factor_y)^(1/2)

		-- offset
		layout.Padding = UDim_new(0, original_padding * scale_factor)
	end

	update_padding()

	if connect then
		return size_change_event:Connect(update_padding)
	end

	return nil
end

module.layout_padding_list_adjust = function(layout_list : {[number] : UIListLayout}, original_padding : number, viewport_size : Vector2, connect : boolean?) : connection_list?
	if connect then
		local connections = {}

		for _, v in ipairs(layout_list) do
			local connection = module.layout_padding_adjust(v, original_padding, viewport_size, connect) :: RBXScriptConnection
			insert(connections, connection)
		end

		return connections
	else
		for _, v in ipairs(layout_list) do
			module.layout_padding_adjust(v, original_padding, viewport_size, connect)
		end

		return nil
	end
end

---------------------------------------------------------------------------------------------

-- function that adjusts UI based on attributes
module.ui_adjust = function(obj : Instance, connect : boolean?, recursive : boolean?) : connection_list?
	local connections = {}
	local attributes = obj:GetAttributes()
	local full_name = obj:GetFullName()

	if obj:IsA("UIPadding") then
		local padding_attributes = attributes :: padding_attributes & inline_padding_attributes

		local padding_type = if padding_attributes.PaddingAmountPixels then "inline" else "scale"

		if padding_type == "inline" then
			local padding_amount_pixels = padding_attributes.PaddingAmountPixels
			local viewport_size = padding_attributes.ViewportSize
			local axes = HttpService:JSONDecode(tostring(padding_attributes.Axes)) :: axes

			if not padding_amount_pixels then
				warn("Need padding amount pixels", full_name)
				return
			end

			if not viewport_size then
				warn("Need viewport size", full_name)
				return
			end

			if connect then
				insert(connections, module.inline_padding_adjust(obj, padding_amount_pixels, viewport_size, axes, connect))
			else
				module.inline_padding_adjust(obj, padding_amount_pixels, viewport_size, axes, connect)
			end
		elseif padding_type == "scale" then
			local padding_amount_scale = padding_attributes.PaddingAmountScale
			local axis = padding_attributes.PaddingAxis :: xy

			if not padding_amount_scale then
				warn("Need padding amount scale", full_name)
				return
			end

			if not axis then
				warn("Need padding axis", full_name)
				return
			end

			if connect then
				insert(connections, module.padding_adjust(obj, padding_amount_scale, axis :: any, connect))
			else
				module.padding_adjust(obj, padding_amount_scale, axis :: any, connect)
			end
		end
	elseif obj:IsA("UIListLayout") then
		local layout_attributes = attributes :: layout_padding_attributes

		local original_padding = layout_attributes.LayoutPaddingPixels
		local original_vp_size = layout_attributes.ViewportSize

		if not original_padding then
			warn("Need original padding", full_name)
			return
		end

		if not original_vp_size then
			warn("Need original viewport size", full_name)
			return
		end

		insert(connections, module.layout_padding_adjust(obj, original_padding, original_vp_size, connect))
	elseif obj:IsA("GuiObject") then
		local size_attributes = attributes :: size_attributes

		local original_size = size_attributes.Size
		local original_vp_size = size_attributes.ViewportSize

		if obj:IsA("TextButton") or obj:IsA("TextLabel") or obj:IsA("TextBox") then
			task.spawn(function()
				local text_attributes = attributes :: text_attributes

				local original_text_size = text_attributes.TextSize
				local axis = text_attributes.TextAxis :: any

				if not original_size then
					warn("Need text size", full_name)
					return
				end

				if not original_vp_size then
					warn("Need viewport size (TextObject)", full_name)
					return
				end

				if not axis then
					warn("Need text size axis", full_name)
					return
				end

				insert(connections, module.text_adjust(obj, original_text_size, original_vp_size, axis, connect))
			end)
		end

		if not original_size then
			warn("Need original UI size", full_name)
			return
		end

		if not original_vp_size then
			warn("Need original viewport size (GuiObject)", full_name)
			return
		end

		insert(connections, module.size_adjust(obj, original_size, original_vp_size, connect))
	end

	if recursive then
		for _, v in obj:GetChildren() do
			local child_connections = module.ui_adjust(v, connect, recursive)

			if child_connections then
				for _, v in child_connections do
					insert(connections, v)
				end
			end
		end
	end

	return connections :: any
end

module.add_text_attributes = function(obj : Instance, recursive : boolean?)
	if obj:IsA("TextButton") or obj:IsA("TextLabel") or obj:IsA("TextBox") then
		local original_text_size = obj.TextSize
		local original_vp_size = camera.ViewportSize

		obj:SetAttribute("TextSize", original_text_size)
		obj:SetAttribute("ViewportSize", original_vp_size)
		obj:SetAttribute("TextAxis", "XY")
	end

	if recursive then
		for _, v in obj:GetChildren() do
			module.add_text_attributes(v, recursive)
		end
	end
end

module.add_size_attributes = function(obj : Instance, recursive : boolean?)
	if obj:IsA("GuiObject") then
		local original_size = obj.Size
		local original_vp_size = camera.ViewportSize

		obj:SetAttribute("Size", original_size)
		obj:SetAttribute("ViewportSize", original_vp_size)
	end

	if recursive then
		for _, v in obj:GetChildren() do
			module.add_size_attributes(v, recursive)
		end
	end
end

module.add_padding_attributes = function(obj : Instance, recursive : boolean?)
	if obj:IsA("UIPadding") then
		local x_padding = (obj.PaddingLeft.Scale + obj.PaddingRight.Scale) / 2
		local y_padding = (obj.PaddingTop.Scale + obj.PaddingBottom.Scale) / 2

		local padding_amount_scale = math.max(x_padding, y_padding)
		local axis = if x_padding > y_padding then "X" else "Y"

		obj:SetAttribute("PaddingAmountScale", padding_amount_scale)
		obj:SetAttribute("PaddingAxis", axis)
	end

	if recursive then
		for _, v in obj:GetChildren() do
			module.add_padding_attributes(v, recursive)
		end
	end
end

module.add_inline_padding_attributes = function(obj : Instance, recursive : boolean?)
	if obj:IsA("UIPadding") then
		local padding_amount_pixels = obj.PaddingLeft.Offset

		if padding_amount_pixels == 0 then
			padding_amount_pixels = obj.PaddingRight.Offset
		end

		if padding_amount_pixels == 0 then
			padding_amount_pixels = obj.PaddingTop.Offset
		end

		if padding_amount_pixels == 0 then
			padding_amount_pixels = obj.PaddingBottom.Offset
		end

		local axes = {
			Top = obj.PaddingTop.Offset > 0,
			Bottom = obj.PaddingBottom.Offset > 0,
			Left = obj.PaddingLeft.Offset > 0,
			Right = obj.PaddingRight.Offset > 0
		}

		local viewport_size = camera.ViewportSize

		obj:SetAttribute("PaddingAmountPixels", padding_amount_pixels)
		obj:SetAttribute("Axes", HttpService:JSONEncode(axes))
		obj:SetAttribute("ViewportSize", viewport_size)
	end

	if recursive then
		for _, v in obj:GetChildren() do
			module.add_inline_padding_attributes(v, recursive)
		end
	end
end

module.add_layout_padding_attributes = function(obj : Instance, recursive : boolean?)
	if obj:IsA("UIListLayout") then
		local original_padding = obj.Padding.Offset
		local viewport_size = camera.ViewportSize

		obj:SetAttribute("LayoutPaddingPixels", original_padding)
		obj:SetAttribute("ViewportSize", viewport_size)
	end

	if recursive then
		for _, v in obj:GetChildren() do
			module.add_layout_padding_attributes(v, recursive)
		end
	end
end

---------------------------------------------------------------------------------------------

module.clear_all_attributes = function(obj : Instance, recursive : boolean?)
	obj:SetAttribute("PaddingAmountScale", nil)
	obj:SetAttribute("PaddingAxis", nil)
	obj:SetAttribute("PaddingAmountPixels", nil)
	obj:SetAttribute("ViewportSize", nil)
	obj:SetAttribute("LayoutPadding", nil)
	obj:SetAttribute("LayoutViewportSize", nil)
	obj:SetAttribute("Axis", nil)
	obj:SetAttribute("Size", nil)
	obj:SetAttribute("TextSize", nil)
	obj:SetAttribute("TextAxis", nil)

	if recursive then
		for _, v in obj:GetChildren() do
			module.clear_all_attributes(v, recursive)
		end
	end
end

---------------------------------------------------------------------------------------------

return module

---------------------------------------------------------------------------------------------