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
local enchanter = require("scripts.enchanting_ui.enchanter")

-- TODO: add description



local elements = {}

-- Inputs
elements.name_input = templates.text_input("Name", 200, function(text) enchanter.name = text end)

-- Stats
elements.stats_enchantment = templates.text_output.new("Enchantment:", 200, 10, "0/0", UI.ALIGNMENT.End)
elements.stats_chance = templates.text_output.new("Chance:", 200, 10, "0", UI.ALIGNMENT.End)
elements.stats_charge = templates.text_output.new("Charge:", 200, 10, "0/0", UI.ALIGNMENT.End)

elements.cast_type_btn = {}
elements.price = templates.text_output.new("Price:", 100, 10, "0", UI.ALIGNMENT.End)

-- lists
elements.items_list = {}
elements.souls_list = {}
elements.magic_effects = {}
elements.effects = {}

elements.root = {}
elements.effects_root = {}

return elements