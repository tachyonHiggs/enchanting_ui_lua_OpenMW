local core = require('openmw.core')
local types = require('openmw.types')
local self = require('openmw.self')
local UI = require('openmw.ui')
local storage = require('openmw.storage')

-- Main object
local enchanter = {}

enchanter.name = ""
enchanter.item = {
    id = "",
    icon = nil,
    type = 0,
    enchantment_capacity = 0
}
enchanter.soul = {
    id = "",
    icon = nil
}

enchanter.reset_effect_to_add = function()
    enchanter.effect_to_modify = false
    enchanter.effect_to_add = {
        affectedAttribute = nil,
        affectedSkill = nil,
        area = 0,
        duration = 0,
        id = 0,
        index = 0,
        magnitudeMax = 0,
        magnitudeMin = 0,
        range = 0
    }
end

enchanter.reset = function()
    enchanter.enchantment = {}
    enchanter.enchantment.charge = 0
    enchanter.enchantment.cost = 0
    enchanter.effects_with_params = {}
    enchanter.reset_effect_to_add()
    enchanter.enchantment.id = 0 -- should be generated
    enchanter.enchantment.isAutocalc = 0
    enchanter.enchantment.type = 0

    enchanter.chance = 0
end

enchanter.reset()

enchanter.get_known_magic_effects = function()

    local known_magic_effects = {}
    local seen = {}
    local spells = types.Player.spells(self)

    for _, spell in ipairs(spells) do
        if (spell.type ~= core.magic.SPELL_TYPE.Power) then
            for _, effect in ipairs(spell.effects) do
                known_magic_effects[effect.effect.id] = effect.effect.name
            end
        end
    end

    return known_magic_effects
end

enchanter.get_enchantable_inventory_items = function()

    local enchantable_inventory_items = {}
    local weapons = types.Actor.inventory(self.object):getAll(types.Weapon)
    local armors = types.Actor.inventory(self.object):getAll(types.Armor)
    local clothing = types.Actor.inventory(self.object):getAll(types.Clothing)

    for _, item in ipairs(weapons) do
        -- check not enchanted
        if types.Weapon.records[item.recordId].enchant == nil then
            local icon = types.Weapon.records[item.recordId].icon
            local name = types.Weapon.records[item.recordId].name
            local enchant_pts = types.Weapon.records[item.recordId].enchantCapacity
            table.insert(enchantable_inventory_items, {item.recordId, icon, item.type, name, enchant_pts})
            -- print(item.recordId)
        end
    end
    for _, item in ipairs(armors) do
        -- check not enchanted
        if types.Armor.records[item.recordId].enchant == nil then
            local icon = types.Armor.records[item.recordId].icon
            local name = types.Armor.records[item.recordId].name
            local enchant_pts = types.Armor.records[item.recordId].enchantCapacity
            table.insert(enchantable_inventory_items, {item.recordId, icon, item.type, name, enchant_pts})
            -- print(item.recordId)
        end
    end
    for _, item in ipairs(clothing) do
        -- check not enchanted
        if types.Clothing.records[item.recordId].enchant == nil then
            local icon = types.Clothing.records[item.recordId].icon
            local name = types.Clothing.records[item.recordId].name
            local enchant_pts = types.Clothing.records[item.recordId].enchantCapacity
            table.insert(enchantable_inventory_items, {item.recordId, icon, item.type, name, enchant_pts})
            -- print(item.recordId)
        end
    end

    return enchantable_inventory_items
end

enchanter.get_inventory_souls = function ()

    local souls = {}
    local items = types.Actor.inventory(self.object):getAll(types.Miscellaneous)

    for _, item in ipairs(items) do
        -- check for soul
        local soul = types.Item.itemData(item).soul
        if soul ~= nil then
            local soul_value = types.Creature.records[soul].soulValue
            local icon = types.Miscellaneous.records[item.recordId].icon
            local soul_name = types.Creature.records[soul].name
            local name = types.Miscellaneous.records[item.recordId].name
            -- local quantity = 
            table.insert(souls, {item.recordId, soul_value, icon, name, soul_name})
        end
    end

    return souls
end

enchanter.check_requirements = function()
    print("check_requirements")

    -- Check item
    if enchanter.item.id == "" then
        UI.showMessage("No item selected")
        print("Failed: no item selected")
        return false
    end 

    -- Check soul
    if enchanter.soul.id == "" then
        UI.showMessage("No soul selected")
        print("Failed: no soul selected")
        return false
    end

    -- Check effects
    if enchanter.effects_with_params[1] == nil then
        UI.showMessage("No effects selected")
        print("Failed: no effects selected")
        return false
    end

    -- Check enchantment capacity limit
    if storage.globalSection("cheats_enchanting_ui"):get("remove_enchant_cap_limit") == false then
        
    end

    -- Check charge

    -- Check cost

    -- Check price

    return true
end

enchanter.get_enchant_success = function()
    print("get_enchant_success")

    success_percent = 100
    
    if storage.globalSection("cheats_enchanting_ui"):get("always_success") == false then
        -- success_percent = enchanter.calculate_success_rate 
    end

    -- if enchanter.chance < some random dice roll
        -- return true
    -- else
        -- return false

    return true
end

-- This fnc assumes passed in values have already been verified as valid
enchanter.create_item = function()
    print("create_item")

    -- Serialize data
    core.sendGlobalEvent('create_enchantment_and_item', {name=enchanter.name, item_id=enchanter.item.id, item_type = enchanter.item.type ,enchantment = enchanter.enchantment, effects = enchanter.effects_with_params})

end

-- TODO: make this return if item was created and message
enchanter.enchant_item = function()
    print("enchant_item")
    
    if enchanter.check_requirements() == false then
        
        return
    end

    -- TODO: Consume soul gems
    enchanter.get_enchant_success()

    enchanter.create_item()
    -- Destory unenchanted item

    -- Clean up enchanter
    enchanter.reset() 
end

-- This fnc is used to calculate the current success rate
enchanter.calculate_success_rate = function(isEffectConstant, enchantmentPoints)
    print("calculate_success_rate")

    -- Get relevant skills and attributes
    local enchant_skill = types.Player.stats["skills"]["enchant"](self.object).modified
    local intelligence = types.Player.stats["attributes"]["intelligence"](self.object).modified
    local luck = types.Player.stats["attributes"]["luck"](self.object).modified

    -- Get fatigue percent
    local fatigue_base = types.Player.stats["dynamic"]["fatigue"](self.object).base
    local fatigue_current = types.Player.stats["dynamic"]["fatigue"](self.object).current
    local fatigue_percent = fatigue_current/fatigue_base

    -- Get GMST
    local enchantment_chance_mult = core.getGMST('fEnchantmentChanceMult')
    local enchantment_const_chance_mult = core.getGMST('fEnchantmentConstantChanceMult')

    -- From: "Enchanting success rate" at https://en.uesp.net/wiki/Morrowind:Enchant
    local rate = (0.75 + fatigue_percent/2) * (1 - enchantment_const_chance_mult*isEffectConstant) * (enchant_skill + intelligence/5 + luck/10 - enchantment_chance_mult*enchantmentPoints)

    return rate
end

enchanter.toggle_cast_type = function()
    local text = ""

    local valid_types = {}

    if enchanter.item.type == nil or enchanter.item.type == 0 then
        valid_types = {
            core.magic.ENCHANTMENT_TYPE.CastOnce
        }
    elseif enchanter.item.type == "Weapon" then
        valid_types = {
            core.magic.ENCHANTMENT_TYPE.CastOnStrike,
            core.magic.ENCHANTMENT_TYPE.CastOnUse,
            core.magic.ENCHANTMENT_TYPE.ConstantEffect,
        }
    elseif enchanter.item.type == "Armor" or enchanter.item.type == "Clothing" then
        valid_types = {
            core.magic.ENCHANTMENT_TYPE.CastOnUse,
            core.magic.ENCHANTMENT_TYPE.ConstantEffect,
        }
    end

    local currentIndex = 0
    for i, enchantType in ipairs(valid_types) do
        if enchantType == enchanter.enchantment.type then
            currentIndex = i
            break
        end
    end

    -- Advance to the next valid type
    currentIndex = (currentIndex % #valid_types) + 1
    print(currentIndex)
    enchanter.enchantment.type = valid_types[currentIndex]
    print("New type: ", enchanter.enchantment.type)

    if enchanter.enchantment.type == core.magic.ENCHANTMENT_TYPE.CastOnce then
        text = "Cast Once"
    elseif enchanter.enchantment.type == core.magic.ENCHANTMENT_TYPE.CastOnStrike then
        text = "Cast on Strike"
    elseif enchanter.enchantment.type == core.magic.ENCHANTMENT_TYPE.CastOnUse then
        text = "Cast on Use"
    elseif enchanter.enchantment.type == core.magic.ENCHANTMENT_TYPE.ConstantEffect then
        text = "Constant Effect"
        enchanter.enchantment.isAutocalc = false
    end

    return text
end

return enchanter