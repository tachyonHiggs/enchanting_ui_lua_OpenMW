local core = require('openmw.core')
local types = require('openmw.types')
local self = require('openmw.self')
local UI = require('openmw.ui')
local I = require('openmw.interfaces')
local storage = require('openmw.storage')
local ambient = require('openmw.ambient')

local vendor = {}

vendor.calculate_vanilla_price = function(base_cost)
    local price = 1

    local fEnchantmentValueMult = core.getGMST('fEnchantmentValueMult')
    price = base_cost * fEnchantmentValueMult
    price = math.max(1, price) -- set to at least 1

    return price
end

-- FROM: https://gitlab.com/OpenMW/openmw/-/merge_requests/5396/diffs#c09212161591c36efefeae4c9bfecd2764cc1fab
local function getFatigueTerm(actor)
    local fatigue = actor.type.stats.dynamic.fatigue(actor)
    local max, current, normalized = fatigue.base, fatigue.current, nil

    if math.floor(max) == 0 then normalized = 1 else normalized = math.max(0., current / max) end

    local fFatigueBase = core.getGMST('fFatigueBase')
    local fFatigueMult = core.getGMST('fFatigueMult')

    return fFatigueBase - fFatigueMult * (1 - normalized)
end
local function getBarterOffer(merchant, basePrice, buying)
    print("vendor is: ", merchant)
    if merchant == {} then
        print("ERROR")
        return 0
    end
    if basePrice == 0 or types.Creature.objectIsInstance(merchant) then
        return basePrice
    end

    local playerMerc = self.type.stats.skills.mercantile(self).modified
    local playerLuck  = self.type.stats.attributes.luck(self).modified
    local playerPers  = self.type.stats.attributes.personality(self).modified

    local merchantMerc = merchant.type.stats.skills.mercantile(merchant).modified
    local merchantLuck  = merchant.type.stats.attributes.luck(merchant).modified
    local merchantPers  = merchant.type.stats.attributes.personality(merchant).modified

    -- :todo look into getDerivedDisposition details
    local disposition = merchant.type.getDisposition(merchant, self)
    local a = math.min(playerMerc, 100.)
    local b = math.min(playerLuck * .1, 10.)
    local c = math.min(playerPers * .2, 10.)
    local d = math.min(merchantMerc, 100.)
    local e = math.min(merchantLuck * .1, 10.)
    local f = math.min(merchantPers * .2, 10.)

    local pcTerm = (disposition - 50 + a + b + c) * getFatigueTerm(self)
    local npcTerm = (d + e + f) * getFatigueTerm(merchant)
    local buyTerm = 0.01 * (100 - 0.5 * (pcTerm - npcTerm))
    local sellTerm = 0.01 * (50 - 0.5 * (npcTerm - pcTerm))
    -- util.round may be more correct
    local offerPrice = math.floor(basePrice * (buying and buyTerm or sellTerm))
    return math.max(1, offerPrice)
end

local function getEffectiveValue(item, count)
    local basePrice = item.type.record(item).value

    local itemData = item.type.itemData(item)
    local itemRecord = item.type.record(item)

    local x = 1

    return x * count
end

local function haggle(npc, playerOffer, merchantOffer)
    if playerOffer <= merchantOffer then
        return true
    end

    if types.Creature.objectIsInstance(npc) then
        return false
    end

    local buying = merchantOffer < 0
    local a = math.abs(merchantOffer)
    local b = math.abs(playerOffer)
    local d = buying and math.modf(100 * (a - b) / a) or math.modf(100 * (b - a) / b)

    local clampedDisposition = util.clamp(npc.type.getDisposition(npc, self), 0, 100)

    local a1 = self.type.stats.skills.mercantile(self).modified
    local b1 = 0.1 * self.type.stats.attributes.luck(self).modified
    local c1 = 0.2 * self.type.stats.attributes.personality(self).modified
    local d1 = npc.type.stats.skills.mercantile(npc).modified
    local e1 = 0.1 * npc.type.stats.attributes.luck(npc).modified
    local f1 = 0.2 * npc.type.stats.attributes.personality(npc).modified

    local dispositionTerm = core.getGMST('fDispositionMod') * (clampedDisposition - 50)
    local pcTerm = (dispositionTerm + a1 + b1 + c1) * getFatigueTerm(self)
    local npcTerm = (d1 + e1 + f1) * getFatigueTerm(npc)
    local x = core.getGMST('fBargainOfferMulti') * d + core.getGMST('fBargainOfferBase') + math.modf(pcTerm - npcTerm)

    local roll = math.random(1, 100)

    if roll > x or (merchantOffer < 0 and 0 < playerOffer) then
        return false
    end

    local skillGain = 0
    local finalPrice = math.abs(playerOffer)
    local initialMerchantOffer = math.abs(merchantOffer)

    if (not buying and (finalPrice > initialMerchantOffer)) then
        skillGain = math.floor(100 * (finalPrice - initialMerchantOffer) / finalPrice)
    elseif (buying and (finalPrice < initialMerchantOffer)) then
        skillGain = math.floor(100 * (initialMerchantOffer - finalPrice) / initialMerchantOffer)
    end

    return true, skillGain
end

local function updateOffer(ctx)
    local state = ctx.barterState
    local merchant = ctx.windowArgs.Trade
    if not state or not merchant then
        return
    end

    local merchantOffer = 0
    for _, buyingData in pairs(state.buying) do
        local basePrice = getEffectiveValue(buyingData.item, buyingData.count)
        local cap = math.modf(math.max(1, 0.75 * basePrice))
        local buyingPrice = getBarterOffer(merchant, basePrice, true)
        merchantOffer = merchantOffer - math.max(cap, buyingPrice)
    end

    for _, sellingData in pairs(state.selling) do
        local basePrice = getEffectiveValue(sellingData.item, sellingData.count)
        local cap = math.modf(math.max(1, 0.75 * basePrice))
        local sellingPrice = getBarterOffer(merchant, basePrice, false)
        merchantOffer = merchantOffer + (types.NPC.objectIsInstance(merchant) and math.min(cap, sellingPrice) or sellingPrice)
    end

    local diff = merchantOffer - (state.currentMerchantOffer or 0)
    state.currentMerchantOffer = merchantOffer
    state.currentBalance = (state.currentBalance or 0) + diff
end

vendor.check_price = function()
    print("check_price")

    enchanter.price = vendor.calculate_price()

    -- Compare with Player gold
    local player_gold = types.Actor.inventory(self):countOf('Gold_001')
    print("Player has: ", player_gold)

    if player_gold >= enchanter.price then
        enchanter.price = enchanter.price
        print("Success")
        return true
    end

    UI.showMessage("You do not have enough gold for this transaction")
    print("Failed to pay Vendor")
    return false
end

return vendor