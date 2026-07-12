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
        effect.effect = core.magic.effects.records[effect.id]
    end

    -- Create enchantment
    local template_enchantment_record = core.magic.enchantments.records[1]
    local enchantment_table = {id = enchantment.id, charge = soul.charge, cost = enchantment.cost, effects = effects, isAutocalc = enchantment.isAutocalc, type = enchantment.type, template = template_enchantment_record}
    local new_enchantment_draft = core.magic.enchantments.createRecordDraft(enchantment_table)
    local new_enchantment = world.createRecord(new_enchantment_draft)
    print(new_enchantment.id)
    print("Cost: ", new_enchantment.cost)
    print("Cost: ", new_enchantment.isAutocalc)

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
    print("Count: ", count)
    local object = data.object
    print("Object: ", object)

    object:remove(count)
end

local function move_into_player(data)
    print("move_into_player")
    local count = data.count
    print("Count: ", count)
    local id = data.id
    print("Id: ", id)

    world.createObject(id, count):moveInto(world.players[1])
end

return {
    eventHandlers = {
        create_enchantment_and_item = create_enchantment_and_item,
        remove_object = remove_object,
        move_into_player = move_into_player,
    }
}