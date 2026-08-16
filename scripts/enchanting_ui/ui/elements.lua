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
local tooltips_text = require("scripts.enchanting_ui.ui.tooltips_text")

-- TODO: add description

local elements = {}
elements.text_size = 20
elements.padding_size = 10

elements.tooltip = templates.tooltips.new("GeneralToolTip")

-- Inputs
elements.name_input = {}
elements.soul_input = {}
elements.item_input = {}
elements.count_input = {}

-- Stats
elements.stats_enchantment = templates.text_output.new("Enchantment Pts:", 200, 10, "0/0", UI.ALIGNMENT.End, tooltips_text.stats_enchantment, elements.tooltip)
elements.stats_base_cost = templates.text_output.new("  Enchantment:", 200, 10, "0/0", UI.ALIGNMENT.End, tooltips_text.stats_enchantment, elements.tooltip)
elements.stats_charge = templates.text_output.new("Charge:", 200, 10, "0/0", UI.ALIGNMENT.End, tooltips_text.stats_charge, elements.tooltip)
elements.stats_effective_cost = templates.text_output.new("  Charge:", 200, 10, "0/0", UI.ALIGNMENT.End, tooltips_text.stats_charge, elements.tooltip)

elements.create_stats = function()
    
    local content = {
        elements.stats_enchantment:create(),
        elements.stats_base_cost:create(),
        elements.stats_charge:create(),
        elements.stats_effective_cost:create(),
        elements.chance:create(),
        elements.price:create(),
    }
    return templates.flex(content, "stats_panel_content", false, UI.ALIGNMENT.Start, UI.ALIGNMENT.Start, 10, 10, nil, v2(0, 0), v2(0, 0))
end

elements.set_stats_enchantment = function()
    print("set_stats_enchantment")
    
    elements.stats_enchantment:set_text(string.format("%.1f", enchanter.enchantment.base_cost).."/"..string.format("%.1f", enchanter.item.enchantment_capacity))
end
elements.set_stats_charge = function()
    print("set_stats_charge")
    elements.stats_charge:set_text(string.format("%.1f", enchanter.enchantment.effective_cost) .. "/" .. string.format("%.1f", enchanter.soul.charge))
end

-- TODO: move this into enchanting_ui
elements.set_cast_type = function()

    elements.effects:clear()
    elements.cast_type_btn:set_text(enchanter.toggle_cast_type())
    elements.set_stats_enchantment()
    elements.set_chance()
    elements.root:update()
end
elements.cast_type_btn = {}

-- Type
elements.cast_once = {}
elements.cast_on_strike = {}
elements.cast_on_use = {}
elements.constant = {}

elements.set_price = function()
    print("set_price")
    elements.price:set_text(tostring(enchanter.price))
end
elements.price = templates.text_output.new("Price:", 100, 10, "1", UI.ALIGNMENT.End, tooltips_text.price, elements.tooltip)
elements.set_chance = function()
    print("set_chance")
    elements.chance:set_text(string.format("%.1f", enchanter.chance))
end
elements.chance = templates.text_output.new("Chance:", 100, 10, "0", UI.ALIGNMENT.End, tooltips_text.chance, elements.tooltip)
elements.is_vendor = false

-- lists

elements.root = {}

elements.items_list = {}
elements.souls_list = {}
elements.magic_effects_list = {}
elements.effects = {}

-- Root UI constants
elements.root_size = {800, 450}
elements.main_menu_size = {550, 450}
elements.stats_panel_size = {250, 450}

-- Header UI constants
elements.input_image_size = {75, 75}

-- Main Content UI constants
elements.mc_effects_size = {525, 200}
elements.mc_list_gap = 5
elements.mc_size = {800, 350}

-- Footer UI constants
elements.footer_size = {800, 80}

-- Add Effect UI
elements.add_effects_root = {}
elements.add_effects_size = {620, 600}
elements.add_effects_list_column_names = {"", "Name", "School"}
elements.add_effects_list_sizes = {25, 250, 100, 120}
elements.add_effects_list_sorting = {false, true, true}

-- Effect UI constants
elements.effects_root = {}
elements.effects_size = {500, 350}
elements.attribute_button_size = {120, 30}
elements.select_list_size = {250, 250}
elements.effects_sliders_size = {300, 30}
elements.effect_icon_size = v2(20,20)

-- Souls UI constants
elements.souls_root = {}
elements.souls_list_column_names = {"", "Name", "Charge", "Soul Name", "Count"}
elements.souls_list_sizes = {50, 250, 80, 200, 80}
elements.souls_list_sorting = {false, true, true, true, true}

-- Items UI constants
elements.items_root = {}
elements.items_list_column_names = {"", "Name", "Enchant Pts", "Type", "Count"}
elements.items_list_sizes = {50, 250, 120, 100, 80}
elements.items_list_sorting = {false, true, true, true, true}

return elements