# Enchanting UI

## TODO / Change Log

### Vanilla Features
- Add openmw enchant multiple projectiles at once: https://openmw.readthedocs.io/en/latest/reference/modding/settings/game.html#projectiles-enchant-multiplier
- Add soul gem used to start player enchanting to fil the soul gem spot
- Add tool tips
- Add consistent sound effects
- Add limits on max and min mag
- Allow multiple affect skill/attribute effects 


### Expanded Features
- Implement constant effect as always possible with any soul but reduces enchantment capacity
- Implement cheat modes: disable enchantment capacity, disable cost, disable charge, etc
- Potentially add the ability use vendor's soul gems while enchanting
- Allow bartering for vendor enchanted items services
- Option to remove constant effect max and min magnitude


### Development
- Add descriptions, params, fields etc to functions and files
- Make it so that changing item does not cause the enchanting menu to reset
- Have Flex UI wrap skills
- Clean up Skill and attribute select menus


## Known Issues
 - Opening the enchantment menu immediately upon starting causes the menus to not load all items, souls, and magic effects
 - Minimum sized magic effects cause the item to have 0 charge
 - Menus layering issue