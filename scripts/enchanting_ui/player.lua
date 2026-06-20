local I = require('openmw.interfaces')

local enchanting_ui = require("scripts.enchanting_ui.enchanting_ui")


local function show()
    enchanting_ui.show()
end
    
local function hide()
    enchanting_ui.hide()
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