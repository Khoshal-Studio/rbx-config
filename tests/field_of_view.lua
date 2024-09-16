--!nonstrict

--------------------------------------------------------------------

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--------------------------------------------------------------------

-- Place config in replicated storage!
local config = require(ReplicatedStorage:WaitForChild("config"))
local base = config.themes.base

--------------------------------------------------------------------

local data = {
	title = "FOV Changer",
	objects = {
		{
			key = "Field of View",
			default_value = 60,
			num_info = {
				int = true,
				signed = false,
				limit = {
					max = 130,
					min = 1
				}
			}
		}
	},
	requires_apply = false
}

local function fov_test()
	local success, config = base.config(data)

	if not (success and config) then
		return
	end

	local fov : any = config.objects.get()["Field of View"]

	fov.changed:Connect(function(value : number)
		workspace.CurrentCamera.FieldOfView = value
	end)

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Parent = Player.PlayerGui

	config.frame.get().Parent = ScreenGui
	config.frame.get().Position = UDim2.fromScale(0.5, 0.5)
	config.frame.get().Size = UDim2.fromScale(0.3, 0.15)
end

--------------------------------------------------------------------

local function main()
	fov_test()
end

--------------------------------------------------------------------

main()

--------------------------------------------------------------------