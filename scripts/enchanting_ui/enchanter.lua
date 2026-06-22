local core = require('openmw.core')
local types = require('openmw.types')
local self = require('openmw.self')

-- Main object
local enchanter = {}

-- Testing values
-- TODO: add item instead of item_id
enchanter.name = ""
enchanter.item = {
    id = "",
    icon = nil
}
enchanter.soul = {
    id = "",
    value = 0,
    icon = nil
}
enchanter.soul_value = types.Creature.records["golden saint"].soulValue
enchanter.enchantment = core.magic.enchantments.records[1] -- Just an initial value
enchanter.chance = 0

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
        if item.enchant == nil then
            local icon = types.Weapon.records[item.recordId].icon
            table.insert(enchantable_inventory_items, {item.recordId, icon})
            -- print(item.recordId)
        end
    end
    for _, item in ipairs(armors) do
        -- check not enchanted
        if item.enchant == nil then
            local icon = types.Armor.records[item.recordId].icon
            table.insert(enchantable_inventory_items, {item.recordId, icon})
            -- print(item.recordId)
        end
    end
    for _, item in ipairs(clothing) do
        -- check not enchanted
        if item.enchant == nil then
            local icon = types.Clothing.records[item.recordId].icon
            table.insert(enchantable_inventory_items, {item.recordId, icon})
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
            table.insert(souls, {item.recordId, soul_value, icon})
        end
    end

    return souls
end

enchanter.check_requirements = function()
    print("check_requirements")

    -- Check item is valid

    -- Check enchantment and soul value are valid

    -- check cast cost, charge etc, price
end

enchanter.get_enchant_success = function()
    print("get_enchant_success")

    -- if enchanter.chance < some random dice roll
        -- return true
    -- else
        -- return false

    return true
end

-- This fnc assumes passed in values have already been verified as valid
enchanter.create_item = function()
    print("create_item")

    -- core.sendGlobalEvent('create_enchantment', {id=enchanter.enchantment.id})
    -- TODO: update this to be not Weapon specific
    core.sendGlobalEvent('create_item', {name=enchanter.name, item_id=enchanter.item.id, enchantment_id=enchanter.enchantment.id})
end

-- TODO: make this return if item was created and message
enchanter.enchant_item = function(name)
    print("enchant_item")
    
    enchanter.check_requirements()

    enchanter.get_enchant_success()

    enchanter.create_item()

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

return enchanter