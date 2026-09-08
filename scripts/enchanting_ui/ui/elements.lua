local UI = require('openmw.ui')
local I = require('openmw.interfaces')
local Util = require('openmw.util')
local v2 = Util.vector2
local core = require('openmw.core')

local templates = require("scripts.enchanting_ui.templates")
local enchanter = require("scripts.enchanting_ui.enchanter")
local tooltips_text = require("scripts.enchanting_ui.ui.tooltips_text")

-- TODO: add description

local elements = {}
elements.text_size = 20
elements.title_text_size = 22
elements.padding_size = 10

-- Inputs
elements.count_input = {}

-- Stats
elements.stats_max_enchantment_pts = templates.text_output.new("   Max:", 200, 10, "0", UI.ALIGNMENT.End, tooltips_text.stats_max_enchantment_pts, elements.tooltip)
elements.stats_in_use_enchantment_pts = templates.text_output.new("   In Use:", 200, 10, "0", UI.ALIGNMENT.End, tooltips_text.stats_in_use_enchantment_pts, elements.tooltip)
elements.stats_charge = templates.text_output.new("   Charge:", 200, 10, "0", UI.ALIGNMENT.End, tooltips_text.stats_charge, elements.tooltip)
elements.stats_num_uses = templates.text_output.new("   Uses:", 200, 10, "0", UI.ALIGNMENT.End, tooltips_text.stats_num_uses, elements.tooltip)
elements.stats_skill_bonus = templates.text_output.new("Enchant Skill Bonus:", 200, 10, "+0%", UI.ALIGNMENT.End, nil, nil) -- TODO: this

elements.create_stats = function()

    local enchantment_points_header = {
        name = "Enchantment Points",
        type = UI.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            text = "Enchantment Points",
            textSize = elements.text_size,
            size = v2(elements.stats_panel_size[1],elements.text_size),
            autoSize = true,
            textAlignH = UI.ALIGNMENT.Start,
            textAlignV = UI.ALIGNMENT.Start,
        },
    }
    local soul_charge_header = {
        name = "Soul Charge",
        type = UI.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            text = "Soul Charge",
            textSize = elements.text_size,
            size = v2(elements.stats_panel_size[1],elements.text_size),
            autoSize = true,
            textAlignH = UI.ALIGNMENT.Start,
            textAlignV = UI.ALIGNMENT.Start,
        },
    }
    
    local content = {
        enchantment_points_header,
        elements.stats_max_enchantment_pts:create(),
        elements.stats_in_use_enchantment_pts:create(),
        templates.padding(10,5),

        soul_charge_header,
        elements.stats_charge:create(),
        elements.stats_num_uses:create(),
        templates.padding(10,5),

        elements.stats_skill_bonus:create(),
        templates.padding(10,10),
        elements.chance:create(),
        elements.price:create(),
    }
    return templates.flex(content, "stats_panel_content", false, UI.ALIGNMENT.Start, UI.ALIGNMENT.Start, 10, 10, nil, v2(0, 0), v2(0, 0))
end

elements.set_stats_enchantment = function()
    print("set_stats_enchantment")
    local current_cap = string.format("%.1f", enchanter.item.enchantment_capacity)
    local modified_cap_by = " (" .. string.format("%.1f", enchanter.item.enchantment_capacity - enchanter.item.default_enchantment_capacity) .. ")"
    
    elements.stats_max_enchantment_pts:set_text(current_cap .. modified_cap_by)
    elements.stats_in_use_enchantment_pts:set_text(string.format("%.1f", enchanter.enchantment.base_cost))
end
elements.set_stats_charge = function()
    print("set_stats_charge")
    elements.stats_charge:set_text(string.format("%.1f", enchanter.soul.charge))
    local uses = 0

    if enchanter.enchantment.effective_cost ~= 0 then -- Some effects are in. To avoid infinite
        uses = enchanter.soul.charge/enchanter.enchantment.effective_cost
    end

    if enchanter.enchantment.type == core.magic.ENCHANTMENT_TYPE.CastOnce then
        elements.stats_num_uses:set_text("1")
        return
    elseif enchanter.enchantment.type == core.magic.ENCHANTMENT_TYPE.ConstantEffect then
        elements.stats_num_uses:set_text("Constant")
        return
    end
    
    elements.stats_num_uses:set_text(string.format("%.0f", uses)) -- round down/ floor value
end

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

-- lists

elements.effects = {}

-- Root UI constants
elements.main_menu_size = {575, 500}
elements.stats_panel_size = {250, 500}

-- Add Effect UI
elements.magic_effects_window_size = {620, 600}

-- Effect UI constants
elements.effects_root = {}
elements.effects_size = {500, 350}
elements.attribute_button_size = {120, 30}
elements.select_list_size = {200, 200}
elements.effects_sliders_size = {300, 30}
elements.effect_icon_size = v2(20,20)

elements.skill_select_root = {}
elements.attribute_select_root = {}

return elements