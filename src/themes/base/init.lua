--!strict

----------------------------------------------------------------------------------------------------------------

local module = {}

----------------------------------------------------------------------------------------------------------------

local theme_classes = script:WaitForChild("classes")
local theme_datatypes = theme_classes:WaitForChild("datatypes")
local theme_presets = script:WaitForChild("presets")

----------------------------------------------------------------------------------------------------------------

module.util = require(script:WaitForChild("util"))
module.types = script:WaitForChild("types")

module.config = require(theme_classes.config)
module.container = require(theme_classes.container)

module.classes = theme_classes
module.datatype_classes = theme_datatypes
module.presets = theme_presets

----------------------------------------------------------------------------------------------------------------

return module

----------------------------------------------------------------------------------------------------------------