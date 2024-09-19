--!strict

--------------------------------------------------------------------------------------------------------------------------

assert(game:GetService("RunService"):IsClient(), "rbx-config can only be used on the client!")

--------------------------------------------------------------------------------------------------------------------------

local module = {
	dependencies = script:WaitForChild("dependencies"),
	types = script:WaitForChild("config_types"),
	
    util = require(script:WaitForChild("config_util")),
	themes = require(script:WaitForChild("themes")),
	
	classes = script:WaitForChild("classes"),
	datatype_classes = script.classes:WaitForChild("datatypes")
}

--------------------------------------------------------------------------------------------------------------------------

return table.freeze(module)