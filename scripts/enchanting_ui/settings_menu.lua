local I = require('openmw.interfaces')

I.Settings.registerGroup {
    key = 'options_enchanting_ui',
    page = 'enchanting_ui_page',
    l10n = 'enchanting_ui',
    name = 'Enchanting Remastered Options',
    description = 'Options - Vanilla Plus',
    permanentStorage = true,
    settings = {
        {
            key = 'projectiles_enchant_multiplier',
            renderer = 'number',
            name = 'Projectiles Enchant Multiplier',
            description = 'Similar to Vanilla OpenMW, sets how many projectiles can be enchanted with one soul gem. When set to 0, only a maximum of one item can be enchanted. At 1, Soul Charge / Enchantment Points can be enchanted at once. Follows: Max Count of projectiles = Minimum of either ((Soul Charge / Enchantment Points) * Projectiles Enchant Multiplier) OR Projectile Count.',
            default = 1,
			argument = {
                disabled = false,
                integer = false,
                min = 0,
                max = 100,
            }
        },
        {
            key = 'remove_compound_effect_cost',
            renderer = 'checkbox',
            name = 'Remove compounding cost of multiple effects',
            description = 'When enabled, makes added effects past the first one have the same cost instead of the Vanilla implementation (Vanilla uses compounding effects costs after the first effect)',
            default = false,
			argument = {
                disabled = false,
            }
        },
        {
            key = 'make_fortify_skill_interactions_costlier',
            renderer = 'checkbox',
            name = 'Make Fortify Skill Interactions Costlier',
            description = 'When enabled, forces interaction based fortify skill effects to have a significantly higher enchanting cost. IE alchemy, speechcraft, mercantile, enchant, and armorer. This is to discourage the creation of "Fortify Speechcraft 100 points for 1 second" type effects',
            default = false,
			argument = {
                disabled = false,
            }
        },
   	},
}


I.Settings.registerGroup {
    key = 'enchantment_points_enchanting_ui',
    page = 'enchanting_ui_page',
    l10n = 'enchanting_ui',
    name = 'Enchanting Remastered Enchantment Points Settings',
    description = "Settings relevant to an Item's Enchantment points",
    permanentStorage = true,
    settings = {
        {
            key = 'soul_charge_scales_item_enchant_cap',
            renderer = 'checkbox',
            name = 'Soul Charge Scales Item Enchantment Capacity',
            description = "When enabled, all new enchantments will have their item's enchantment capacity scaled depending on the selected Soul gem. This scales via equation: sqrt(soul charge / 'Soul Charge to Enchantment Capacity factor'). Where constant effects can be less than 1, but other types are a minimum of 1. For only constant effect items to be affected, see 'Soul Charge Scales Item Enchantment Capacity - Constant Effects Only' ",
            default = false,
			argument = {
                disabled = false,
            }
        },
        {
            key = 'soul_charge_scales_item_enchant_cap_constant_effect_only',
            renderer = 'checkbox',
            name = 'Soul Charge Scales Item Enchantment Capacity - Constant Effects Only',
            description = "If 'Soul Charge Scales Item Enchantment Capacity' is enabled, this is enabled. When enabled, all new enchantments can create a constant effect from ANY Soul value. However, the value of the soul affects the item's enchantment capacity. This scales via equation: sqrt(selected soul charge / 'Soul Charge to Enchantment Capacity factor') .",
            
            default = false,
			argument = {
                disabled = false,
            }
        },
        {
            key = 'soul_charge_to_enchant_cap_factor',
            renderer = 'number',
            name = 'Soul Charge to Enchantment Capacity factor',
            description = "This determines how an item's enchantment points scale in relation to the selected soul gem's value. Larger values mean larger souls are needed to increase enchantment capacity",
            default = 400,
			argument = {
                disabled = false,
                integer = true,
                min = 1,
                max = 1000,
            }
        },
   	},
}


I.Settings.registerGroup {
    key = 'constant_enchanting_ui',
    page = 'enchanting_ui_page',
    l10n = 'enchanting_ui',
    name = 'Enchanting Remastered Options',
    description = 'Constant Effect - Vanilla Plus',
    permanentStorage = true,
    settings = {
        {
            key = 'constant_effect_threshold',
            renderer = 'number',
            name = 'Constant Effect Threshold',
            description = 'Sets the threshold a Soul needs to have to allow constant effects.',
            default = 400,
			argument = {
                disabled = false,
                integer = true,
                min = 1,
                max = 1000,
            }
        },
        {
            key = 'constant_effect_constant_magnitude',
            renderer = 'checkbox',
            name = 'Constant Effect Constant Magnitude',
            description = 'When enabled, new Constant Effect enchantments have a constant magnitude. Max and min become equal. This is to discourage enchanting items with wide ranges and re-equiping them until the max is reached.',
            default = false,
			argument = {
                disabled = false,
            }
        },

   	},
}

I.Settings.registerGroup {
    key = 'cheats_enchanting_ui',
    page = 'enchanting_ui_page',
    l10n = 'enchanting_ui',
    name = 'Enchanting Remastered Cheats',
    description = 'Cheats',
    permanentStorage = true,
    settings = {
        {
            key = 'remove_enchant_cap_limit',
            renderer = 'checkbox',
            name = 'Remove Enchantment Capacitiy limit',
            description = 'When enabled, allows enchantments to ignore an items enchantment capacity.',
            default = false,
			argument = {
                disabled = false,
            }
        },
        {
            key = 'remove_soul_charge_limit',
            renderer = 'checkbox',
            name = 'Remove Soul Charge limit',
            description = 'When enabled, allows enchantments to ignore a Souls charge.',
            default = false,
			argument = {
                disabled = false,
            }
        },
        {
            key = 'always_success',
            renderer = 'checkbox',
            name = 'Sets enchantment creation chance to 100%',
            description = 'When enabled, all player created enchantments will succeed if requirements are meet',
            default = false,
			argument = {
                disabled = false,
            }
        },
        {
            key = 'dont_consume_item_and_soul',
            renderer = 'checkbox',
            name = 'Do not consume Soul Gem and Item on Enchant',
            description = 'When enabled, attempts and successfull enchantments no longer consume soul gems and items',
            default = false,
			argument = {
                disabled = false,
            }
        },
        {
            key = 'free_enchantments_from_vendors',
            renderer = 'checkbox',
            name = 'Free Enchantments from Vendors',
            description = 'When enabled, enchantmented items created by Vendors are free and cost 0 gold',
            default = false,
			argument = {
                disabled = false,
            }
        },
        {
            key = 'show_all_magic_effects',
            renderer = 'checkbox',
            name = 'Show all Magic effects',
            description = 'When enabled, the enchanting menu will feature all possible magic effects instead of only player known ones.',
            default = false,
			argument = {
                disabled = false,
            }
        },
   	},
}