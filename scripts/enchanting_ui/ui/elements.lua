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
elements.text_size = 20
elements.padding_size = 20

-- Inputs
elements.name_input = templates.text_input.new("Name", 200, function(text) enchanter.name = text end, function() elements.root:update() end)
elements.soul_input = {}
elements.item_input = {}

-- Stats
elements.stats_enchantment = templates.text_output.new("Enchantment:", 200, 10, "0/0", UI.ALIGNMENT.End)
elements.stats_charge = templates.text_output.new("Charge:", 200, 10, "0/0", UI.ALIGNMENT.End)

elements.cast_type_btn = {}
elements.price = templates.text_output.new("Price:", 100, 10, "0", UI.ALIGNMENT.End)
elements.chance = templates.text_output.new("Chance:", 200, 10, "0", UI.ALIGNMENT.End)

-- lists
elements.items_list = {}
elements.souls_list = {}
elements.magic_effects = {}
elements.effects = {}

elements.root = {}
elements.root_size = {800, 600}
elements.enable_ui = function(element)
    if element.layout.type == UI.TYPE.Widget then
        element.layout.props.visible = true
        return
    end
    element.layout.content[2].template = I.MWUI.templates.padding
    element:update()
end
elements.disable_ui = function(element)
    if element.layout.type == UI.TYPE.Widget then
        element.layout.props.visible = false
        return
    end
    element.layout.content[2].template = I.MWUI.templates.disabled
    element:update()
end

elements.effects_root = {}
elements.effects_size = {500, 300}
elements.attribute_button_size = {120, 30}
elements.effects_sliders_size = {300, 30}
elements.effect_icon_size = v2(20,20)
elements.attribute_names = {"Strength", "Intelligence", "Willpower", "Agility", "Speed", "Endurance", "Personality", "Luck"}
elements.skill_names = {}

elements.souls_root = {}
elements.souls_list_column_names = {"Icon", "Name", "Charge", "Soul Name", "Count"}
elements.souls_list_sizes = {50, 250, 80, 200, 80}
elements.souls_list_sorting = {false, true, true, true, true}

elements.items_root = {}
elements.items_list_column_names = {"Icon", "Name", "Enchant Pts", "Type", "Count"}
elements.items_list_sizes = {50, 250, 120, 100, 80}
elements.items_list_sorting = {false, true, true, true, true}

return elements