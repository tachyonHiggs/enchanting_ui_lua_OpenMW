local core = require('openmw.core')
local types = require('openmw.types')
local self = require('openmw.self')
local UI = require('openmw.ui')
local storage = require('openmw.storage')
local ambient = require('openmw.ambient')

-- Main object
local enchanter = {}

enchanter.reset_effect_to_add = function()
    enchanter.effect_to_modify = false
    enchanter.effect_to_add = {
        affectedAttribute = nil,
        affectedSkill = nil,
        area = 0,
        duration = 1,
        id = 0,
        index = 0,
        magnitudeMax = 1,
        magnitudeMin = 1,
        range = 0,
        cost = 0,
    }
end

enchanter.reset_item = function()
    enchanter.item = {
        id = "",
        object = {},
        icon = nil,
        type = 0,
        enchantment_capacity = 0
    }
end

enchanter.reset_soul = function()
    enchanter.soul = {
        id = "",
        object = {},
        icon = nil,
        charge = 0
    }
end

enchanter.reset_enchantment = function()
    enchanter.chance = 0
    enchanter.name = ""

    enchanter.effects_with_params = {}
    enchanter.reset_effect_to_add()

    enchanter.enchantment = {}
    enchanter.enchantment.id = 0
    enchanter.enchantment.isAutocalc = true
    enchanter.enchantment.type = 0
    enchanter.enchantment.base_cost = 0
    enchanter.enchantment.effective_cost = 0
end

enchanter.reset = function()
    enchanter.reset_enchantment()
    enchanter.reset_soul()
    enchanter.reset_item()
end

enchanter.get_effect_to_add_cost = function ()

    local cost

    local constant_effect_bool = enchanter.enchantment.type == core.magic.ENCHANTMENT_TYPE.ConstantEffect
    local base_cost = core.magic.effects.records[enchanter.effect_to_add.id].baseCost
    local min_plus_max = enchanter.effect_to_add.magnitudeMin + enchanter.effect_to_add.magnitudeMax

    if constant_effect_bool then
        local fEnchantmentConstantDurationMult = core.getGMST('fEnchantmentConstantDurationMult')
        cost = base_cost * (min_plus_max*fEnchantmentConstantDurationMult + enchanter.effect_to_add.area) / 40
    elseif enchanter.effect_to_add.range == core.magic.RANGE.Self or enchanter.effect_to_add.range == core.magic.RANGE.Touch then
        cost = base_cost * (min_plus_max*enchanter.effect_to_add.duration + enchanter.effect_to_add.area) / 40
    elseif enchanter.effect_to_add.range == core.magic.RANGE.Target then
        cost = 1.5 * base_cost * (min_plus_max*enchanter.effect_to_add.duration + enchanter.effect_to_add.area) / 40
    end 

    return cost
end

enchanter.get_effects_total_base_cost = function()
    local sum = 0

    if storage.globalSection("options_enchanting_ui"):get("remove_compound_effect_cost") then
        for _, effect in ipairs(enchanter.effects_with_params) do
            sum = sum + effect.cost
        end

    else
        local total_num_effects = #enchanter.effects_with_params
        for index, effect in ipairs(enchanter.effects_with_params) do
            sum = sum + (effect.cost * (total_num_effects - index + 1))
        end
    end
    
    return sum
end

enchanter.get_effective_cost = function()
    local enchant_skill = types.Player.stats["skills"]["enchant"](self.object).modified
    local effective_cost = enchanter.enchantment.base_cost - (enchanter.enchantment.base_cost / 100) * (enchant_skill - 10)

    if effective_cost < 1 then
        effective_cost = 1
    end

    return effective_cost
end

enchanter.get_known_magic_effects = function()

    local known_magic_effects = {}
    local spells = types.Player.spells(self)

    for _, spell in ipairs(spells) do
        if spell.type == core.magic.SPELL_TYPE.Spell then
            for _, effect in ipairs(spell.effects) do
                known_magic_effects[effect.effect.id] = effect.effect.name
                print(effect.effect.name)
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
    local books = types.Actor.inventory(self.object):getAll(types.Book)

    for _, item in ipairs(weapons) do
        -- check not enchanted
        if types.Weapon.records[item.recordId].enchant == nil then
            local icon = types.Weapon.records[item.recordId].icon
            local name = types.Weapon.records[item.recordId].name
            local enchant_pts = types.Weapon.records[item.recordId].enchantCapacity
            table.insert(enchantable_inventory_items, {item.recordId, item, icon, item.type, name, enchant_pts})
            -- print(item.recordId)
        end
    end
    for _, item in ipairs(armors) do
        -- check not enchanted
        if types.Armor.records[item.recordId].enchant == nil then
            local icon = types.Armor.records[item.recordId].icon
            local name = types.Armor.records[item.recordId].name
            local enchant_pts = types.Armor.records[item.recordId].enchantCapacity
            table.insert(enchantable_inventory_items, {item.recordId, item, icon, item.type, name, enchant_pts})
            -- print(item.recordId)
        end
    end
    for _, item in ipairs(clothing) do
        -- check not enchanted
        if types.Clothing.records[item.recordId].enchant == nil then
            local icon = types.Clothing.records[item.recordId].icon
            local name = types.Clothing.records[item.recordId].name
            local enchant_pts = types.Clothing.records[item.recordId].enchantCapacity
            table.insert(enchantable_inventory_items, {item.recordId, item, icon, item.type, name, enchant_pts})
            -- print(item.recordId)
        end
    end
    for _, item in ipairs(books) do
        -- check not enchanted
        if types.Book.records[item.recordId].enchant == nil then
            local icon = types.Book.records[item.recordId].icon
            local name = types.Book.records[item.recordId].name
            local enchant_pts = types.Book.records[item.recordId].enchantCapacity
            table.insert(enchantable_inventory_items, {item.recordId, item, icon, item.type, name, enchant_pts})
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
            table.insert(souls, {item.recordId, item, soul_value, icon, name, soul_name})
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
        if enchanter.enchantment.base_cost > enchanter.item.enchantment_capacity then
            UI.showMessage("Enchantment Cost beyond Item Capacity")
            print("Failed: Enchantment Cost beyond Item Capacity")
            return false
        end
    end

    -- Check charge
    if storage.globalSection("cheats_enchanting_ui"):get("remove_soul_charge_limit") == false then
        if enchanter.enchantment.type == core.magic.ENCHANTMENT_TYPE.ConstantEffect then
            local constant_effect_threshold = storage.globalSection("options_enchanting_ui"):get("constant_effect_threshold")
            if enchanter.soul.charge < constant_effect_threshold then
                UI.showMessage("Soul Charge below Constant Effect Threshold")
                print("Failed: Soul Charge below Constant Effect Threshold")
                return false
            end
        end
    else 

        enchanter.enchantment.base_cost = 0
        enchanter.enchantment.isAutocalc = false -- Override this to use the above "0" cost
    end

    

    -- Check price
    -- if player has enough gold

    return true
end

enchanter.get_enchant_success = function()
    print("get_enchant_success")
    
    if storage.globalSection("cheats_enchanting_ui"):get("always_success") == false then

        -- Vanilla success rate
        local success_percent = enchanter.calculate_vanilla_success_rate()
        print("calculated success is at: ", success_percent)
        
        local dice_roll = math.random(0, 100)
        print("random dice roll: ", dice_roll)
        if success_percent < dice_roll then
            UI.showMessage("Failed to Create Enchanted Item")
            print("Failed: Failed to create enchanted item")
            ambient.playSound('enchant fail')
            return false
        end

    end

    UI.showMessage("Created Enchanted Item")
    print("Success: Passed")
    ambient.playSound('enchant success')
    return true
end

-- This fnc assumes passed in values have already been verified as valid
enchanter.create_item = function()
    print("create_item")

    core.sendGlobalEvent('create_enchantment_and_item', {name=enchanter.name, item=enchanter.item, soul = enchanter.soul, enchantment = enchanter.enchantment, effects = enchanter.effects_with_params})

end

-- TODO: make this return if item was created and message
enchanter.enchant_item = function()
    print("enchant_item")
    
    if enchanter.check_requirements() == false then
        
        return 0  -- Don't reset any icons
    end

    -- Remove Soul gem

    if not storage.globalSection("cheats_enchanting_ui"):get("dont_consume_item_and_soul") then
        core.sendGlobalEvent('remove_object', {object = enchanter.soul.object, count = 1, type = "soul"})
    end

    if (enchanter.soul.id == 'misc_soulgem_azura') then
        core.sendGlobalEvent('move_into_player', { id = "misc_soulgem_azura", count = 1 })
    end

    if enchanter.get_enchant_success() == false then
        enchanter.reset_soul()
        return 1 -- reset soul gem icon
    end

    enchanter.create_item()

    -- Remove unenchanted item
    if not storage.globalSection("cheats_enchanting_ui"):get("dont_consume_item_and_soul") then
        core.sendGlobalEvent('remove_object', {object = enchanter.item.object, count = 1, type = "item"})
    end

    -- Clean up enchanter
    enchanter.reset() 

    return 2 -- Reset both soul gem and item icon
end

-- This fnc is used to calculate the current success rate
enchanter.calculate_vanilla_success_rate = function()
    print("calculate_vanilla_success_rate")

    -- Get relevant skills and attributes
    local enchant_skill = types.Player.stats["skills"]["enchant"](self.object).modified
    local intelligence = types.Player.stats["attributes"]["intelligence"](self.object).modified
    local luck = types.Player.stats["attributes"]["luck"](self.object).modified

    -- Get fatigue percent
    local fatigue_base = types.Player.stats["dynamic"]["fatigue"](self.object).base
    local fatigue_current = types.Player.stats["dynamic"]["fatigue"](self.object).current
    local fatigue_percent = fatigue_current/fatigue_base
    print("Fatigue percent: ", fatigue_percent)

    -- Get GMST
    local enchantment_chance_mult = core.getGMST('fEnchantmentChanceMult')
    local enchantment_const_chance_mult = core.getGMST('fEnchantmentConstantChanceMult')
    print("enchantment_chance_mult: ", enchantment_chance_mult)
    print("enchantment_const_chance_mult: ", enchantment_const_chance_mult)

    -- Get is constant effect
    local is_effect_constant = enchanter.enchantment.type == core.magic.ENCHANTMENT_TYPE.ConstantEffect and 1 or 0
    print("Is effect constant: ", is_effect_constant)

    -- From: "Enchanting success rate" at https://en.uesp.net/wiki/Morrowind:Enchant
    local rate = (0.75 + (fatigue_percent/2)) * (1 - (enchantment_const_chance_mult * is_effect_constant)) * (enchant_skill + (intelligence/5) + (luck/10) - (enchantment_chance_mult * enchanter.enchantment.base_cost))

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
        local weapon_type = types.Weapon.records[enchanter.item.id].type
        print("Weapon type: ", weapon_type)

        if weapon_type == types.Weapon.TYPE.Arrow or weapon_type == types.Weapon.TYPE.Bolt or weapon_type == types.Weapon.TYPE.MarksmanThrown then
            valid_types = {
                core.magic.ENCHANTMENT_TYPE.CastOnStrike
            }
        elseif weapon_type == types.Weapon.TYPE.MarksmanBow or weapon_type == types.Weapon.TYPE.MarksmanCrossbow then
            valid_types = {
                core.magic.ENCHANTMENT_TYPE.CastOnUse,
                core.magic.ENCHANTMENT_TYPE.ConstantEffect, -- TODO: in vanilla this is not allowed, should it be here? or add a settings menu
            }
        else
            valid_types = {
                core.magic.ENCHANTMENT_TYPE.CastOnStrike,
                core.magic.ENCHANTMENT_TYPE.CastOnUse,
                core.magic.ENCHANTMENT_TYPE.ConstantEffect,
            }
        end
    elseif enchanter.item.type == "Armor" or enchanter.item.type == "Clothing" then
        valid_types = {
            core.magic.ENCHANTMENT_TYPE.CastOnUse,
            core.magic.ENCHANTMENT_TYPE.ConstantEffect,
        }
    else 
        valid_types = {
            core.magic.ENCHANTMENT_TYPE.CastOnce,
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

    enchanter.enchantment.isAutocalc = true
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