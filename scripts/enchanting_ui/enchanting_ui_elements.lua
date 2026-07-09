local UI = require('openmw.ui')
local I = require('openmw.interfaces')
local Util = require('openmw.util')
local v2 = Util.vector2
local auxUi = require("openmw_aux.ui")
local ambient = require('openmw.ambient')
local self = require('openmw.self')
local async = require('openmw.async')
local core = require('openmw.core')
local types = require('openmw.types')

local templates = require("scripts.enchanting_ui.templates")

local elements = {}

elements.stats_enchantment = templates.text_output.new("Enchantment:", 200, 10, "0/0", UI.ALIGNMENT.End)
elements.stats_chance = templates.text_output.new("Chance:", 200, 10, "0", UI.ALIGNMENT.End)
elements.stats_charge = templates.text_output.new("Charge:", 200, 10, "0/0", UI.ALIGNMENT.End)

elements.root = {}
elements.effects_root = {}

return elements