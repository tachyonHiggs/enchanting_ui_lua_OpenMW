local core = require('openmw.core')
local storage = require('openmw.storage')

local templates = require("scripts.enchanting_ui.components.templates")

local debug = true

local effects = {}

effects.get_hasDuration = function(effect_id, type)
    if core.magic.effects.records[effect_id].hasDuration and type ~= core.magic.ENCHANTMENT_TYPE.ConstantEffect then
        return true
    else 
        return false
    end
end

effects.get_hasMag = function(effect_id)
    if core.magic.effects.records[effect_id].hasMagnitude then
        return true
    else 
        return false
    end
end

effects.is_effect_applied_once = function(effect_id)
    return core.magic.effects.records[effect_id].isAppliedOnce
end

effects.get_effect_cost = function (effect, type, index, total_effects)

    local cost = 0

    local constant_effect_bool = type == core.magic.ENCHANTMENT_TYPE.ConstantEffect
    local base_cost = core.magic.effects.records[effect.id].baseCost

    local duration = effect.duration
    if constant_effect_bool then
        duration = core.getGMST('fEnchantmentConstantDurationMult')
    else
        templates.print(debug, "effects", "Forcing duration to be 1 for effect cost: " .. duration)
                
        duration = math.max(1, duration) -- make duration at least be 1 if applied once=true and duration = 0
    end
    
    cost = (((effect.magnitudeMin + effect.magnitudeMax) * duration) + effect.area) * base_cost * core.getGMST('fEffectCostMult') * 0.05

    if effect.range == core.magic.RANGE.Target then
        cost = cost * 1.5
    end

    -- TODO: convert this into a constant for easier modification
    if storage.globalSection("effects_enchanting_ui"):get("make_fortify_skill_interactions_costlier") then
        if effect.affectedSkill then
            if effect.affectedSkill.text == "Armorer" or effect.affectedSkill.text == "Enchant" or effect.affectedSkill.text == "Alchemy" or effect.affectedSkill.text == "Mercantile" or effect.affectedSkill.text == "Speechcraft" then
                templates.print(debug, "effects", "make_fortify_skill_interactions_costlier is TRUE and affectedSkill is: " .. effect.affectedSkill.text)
                cost = cost * 100
            end
        end
    end

    if not storage.globalSection("effects_enchanting_ui"):get("remove_compound_effect_cost") and index then
        cost = cost * (total_effects - index + 1)
    end

    return cost
end

return effects