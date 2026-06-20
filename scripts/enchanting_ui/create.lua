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
    
    local name = data.name
    print("The item shall be called: ", name)

    -- Get Item record
    local item_id = data.item_id
    print("Item ID: ", item_id)
    local item_record = types.Weapon.records[item_id]

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

return {
    eventHandlers = {
        create_enchantment = create_enchantment,
        create_item = create_item,
    }
}