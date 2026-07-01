local world = require('openmw.world')
local types = require('openmw.types')
local core = require('openmw.core')
local util = require('openmw.util')
local storage = require('openmw.storage')

local function create_enchantment(data)
    -- TODO: this fnc

    print("create_enchantment")
    local passed_id = data.id
    print("ID: ", passed_id)

    -- Create enchantment
    -- local record_draft = core.magic.enchantments.createRecordDraft(passed_id)
    -- local record = world.createRecord(record_draft)

end

local function create_item(data)

    print("create_item")

    -- Get Item record
    local item_id = data.item_id
    print("Item ID: ", item_id)
    local item_record = types.Weapon.records[item_id]

    local name = data.name
    if name == "" then
        name = item_record.name
    end
    print("The item shall be called: ", name)

    -- Get Enchantment record
    local enchantment_id = data.enchantment_id
    print("Enchantment ID: ",enchantment_id)

    -- Create item table
    local itemTable = {enchant = enchantment_id, template = item_record}
    local newRecordDraft = types.Weapon.createRecordDraft(itemTable)
    local newRecord = world.createRecord(newRecordDraft) 
    local upgradedItem = world.createObject(newRecord.id, 1)
    print("Created item, now adding to player inventory")

    -- Move to player inventory
    upgradedItem:moveInto(world.players[1])
    
    -- TODO: remove OG item from player inventory
    -- remove soul gem
end

local function create_enchantment_and_item(data)
    print("create_enchantment_and_item")
    local name = data.name
    local item_id = data.item_id
    local enchantment = data.enchantment
    local effects = data.effects
    local effects_with_params = {}

    -- for each effect in effects
    for _, effect in ipairs(effects) do
        effect.effect = core.magic.effects.records[effect.id]
    end

    local template_enchantment_record = core.magic.enchantments.records[1]

    local enchantment_table = {id = enchantment.id, charge = enchantment.charge, cost = enchantment.cost, effects = effects, isAutocalc = enchantment.isAutocalc, type = enchantment.type, template = template_enchantment_record}
    local new_enchantment_draft = core.magic.enchantments.createRecordDraft(enchantment_table)
    local new_enchantment = world.createRecord(new_enchantment_draft)
    print(new_enchantment.id)
    
    local originalRecord = types.Armor.records[item_id]
    local item_table = {enchant = new_enchantment.id, template = originalRecord}
    local new_item_draft = types.Armor.createRecordDraft(item_table)
    local new_item = world.createRecord(new_item_draft) 
    local new_item_instance = world.createObject(new_item.id, 1)
    print(new_item)
    new_item_instance:moveInto(types.Actor.inventory(world.players[1]))
end

return {
    eventHandlers = {
        create_enchantment_and_item = create_enchantment_and_item,
    }
}