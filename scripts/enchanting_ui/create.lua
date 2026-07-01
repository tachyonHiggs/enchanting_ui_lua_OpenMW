local world = require('openmw.world')
local types = require('openmw.types')
local core = require('openmw.core')
local util = require('openmw.util')
local storage = require('openmw.storage')



local function create_enchantment_and_item(data)
    print("create_enchantment_and_item")
    local name = data.name
    local item_id = data.item_id
    local item_type = data.item_type
    local enchantment = data.enchantment
    local effects = data.effects
    local effects_with_params = {}

    -- for each effect in effects
    for _, effect in ipairs(effects) do
        effect.effect = core.magic.effects.records[effect.id]
    end

    -- Create enchantment
    local template_enchantment_record = core.magic.enchantments.records[1]
    local enchantment_table = {id = enchantment.id, charge = enchantment.charge, cost = enchantment.cost, effects = effects, isAutocalc = enchantment.isAutocalc, type = enchantment.type, template = template_enchantment_record}
    local new_enchantment_draft = core.magic.enchantments.createRecordDraft(enchantment_table)
    local new_enchantment = world.createRecord(new_enchantment_draft)
    print(new_enchantment.id)

    -- Create item
    local type = 0
    if type_text == "Weapon" then
        type = types.Weapon
    elseif type_text == "Weapon" then
        type = types.Armor
    else
        type = types.Clothing
    end

    local originalRecord = type.records[item_id]

    if name == "" then
        name = originalRecord.name
    end
    print("The item shall be called: ", name)
    
    local item_table = {name = name, enchant = new_enchantment.id, template = originalRecord}
    local new_item_draft = type.createRecordDraft(item_table)
    local new_item = world.createRecord(new_item_draft) 
    local new_item_instance = world.createObject(new_item.id, 1)

    -- Move to player inventory
    new_item_instance:moveInto(world.players[1])
    -- world.players[1]
    -- TODO: remove OG item from player inventory
end

return {
    eventHandlers = {
        create_enchantment_and_item = create_enchantment_and_item,
    }
}