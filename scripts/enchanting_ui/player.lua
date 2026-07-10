local I = require('openmw.interfaces')

local enchanting_ui = require("scripts.enchanting_ui.enchanting_ui")

local is_vendor_enchant = true

-- For the menu settings tab
I.Settings.registerPage ({
    key = 'enchanting_ui_page',
    l10n = 'enchanting_ui',
    name = 'Enchanting Remastered',
    description = 'Enchanting Remastered Description and Settings.',
})


local function show()
    enchanting_ui.show(not is_vendor_enchant)
end
    
local function hide()
    enchanting_ui.hide(not is_vendor_enchant)
end

local function onMouseWheel()
    
end

local function onFrame()
    
end

local function onSave()
    
end

local function onLoad(data)
    I.UI.registerWindow('EnchantingDialog', show, hide)
end

return {
    engineHandlers = {
        onInit = onLoad,
        onLoad = onLoad,
        onSave = onSave,
        onMouseWheel = onMouseWheel,
        onFrame = onFrame,
    },
    eventHandlers = {

    }
}