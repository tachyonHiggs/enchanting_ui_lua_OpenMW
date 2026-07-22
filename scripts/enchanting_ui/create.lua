local world = require('openmw.world')
local types = require('openmw.types')
local core = require('openmw.core')
local util = require('openmw.util')
local storage = require('openmw.storage')



local function create_enchantment_and_item(data)

    print("create_enchantment_and_item")
    local name = data.name
    local item = data.item
    local soul = data.soul
    local enchantment = data.enchantment
    local effects = data.effects

    -- for each effect in effects
    for _, effect in ipairs(effects) do
        print("AffectedAttribute: ", effect.affectedAttribute)
        effect.affectedAttribute = string.lower(effect.affectedAttribute)
        effect.affectedSkill = string.lower(effect.affectedSkill)
    end

    -- Create enchantment
    local template_enchantment_record = core.magic.enchantments.records[1]

    -- Update the enchantment field cost for specific cases
    if enchantment.type == core.magic.ENCHANTMENT_TYPE.ConstantEffect then
        enchantment.base_cost = 0
    elseif enchantment.type == core.magic.ENCHANTMENT_TYPE.CastOnce then
        enchantment.base_cost = enchantment.charge
    end

    local enchantment_table = {id = enchantment.id, charge = soul.charge, cost = enchantment.base_cost, effects = effects, isAutocalc = enchantment.isAutocalc, type = enchantment.type, template = template_enchantment_record}
    local new_enchantment_draft = core.magic.enchantments.createRecordDraft(enchantment_table)
    local new_enchantment = world.createRecord(new_enchantment_draft)

    -- Create item
    local originalRecord
    if item.type == "Weapon" then
        originalRecord = types.Weapon.records[item.id]
    elseif item.type == "Armor" then
        originalRecord = types.Armor.records[item.id]
    elseif item.type == "Clothing" then
        originalRecord = types.Clothing.records[item.id]
    else
        originalRecord = types.Book.records[item.id]
    end

    if name == "" then
        name = originalRecord.name
    end
    print("The item shall be called: ", name)
    
    local item_table = {name = name, enchant = new_enchantment.id, template = originalRecord}
    local new_item_draft
    if item.type == "Weapon" then
        new_item_draft = types.Weapon.createRecordDraft(item_table)
    elseif item.type == "Armor" then
        new_item_draft = types.Armor.createRecordDraft(item_table)
    elseif item.type == "Clothing" then
        new_item_draft = types.Clothing.createRecordDraft(item_table)
    else
        new_item_draft = types.Book.createRecordDraft(item_table)
    end
    local new_item = world.createRecord(new_item_draft) 
    local new_item_instance = world.createObject(new_item.id, 1)

    -- Move to player inventory
    new_item_instance:moveInto(world.players[1])

end

local function remove_object(data)
    print("remove_object")
    local count = data.count
    local object = data.object
    local type = data.type

    object:remove(count)

    world.players[1]:sendEvent("update_enchant_ui_after_object_removed", {})
end

local function move_into_player(data)
    local id = data.id
    local count = data.count
    print("move_into_player ID: ", id)

    world.createObject(id, count):moveInto(world.players[1])
end

return {
    eventHandlers = {
        create_enchantment_and_item = create_enchantment_and_item,
        remove_object = remove_object,
        move_into_player = move_into_player,
    }
}