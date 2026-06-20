local core = require('openmw.core')
local types = require('openmw.types')
local self = require('openmw.self')

-- Main object
local enchanter = {}

-- Testing values
-- TODO: add item instead of item_id
enchanter.name = ""
enchanter.item_id = "orcish warhammer"
enchanter.soul_value = types.Creature.records["golden saint"].soulValue
enchanter.enchantment = core.magic.enchantments.records[1] -- Just an initial value
enchanter.chance = 0

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
    core.sendGlobalEvent('create_item', {name=enchanter.name, item_id=enchanter.item_id, enchantment_id=enchanter.enchantment.id})
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