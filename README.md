# sm64coop-sonic-health
This is a repository for the sonic health mod for sm64excoop and coopdx
<details>
  <summary>commands</summary>
/decreasecoincounter - [on|off] turn decreasecoincounter on or off to choose whether to decrease the coin counter on hit and rings equal 1 coin or have the coin counter not decease on hit and rings only affect ring counter
  
/loseringsonlevelchange - turn loseringsonlevelchange on or off to choose if you want to keep your rings between levels.

/maxrecollectablerings - maxrecollectablerings [number] this sets the maximum amount of rings you can get back per hit

/maxringloss [number] this sets the max number of rings you can lose at once set it to 0 to always lose all rings.

/recoveryheartshield = [on|off] turn recoveryheartshield on or off to choose whether recovery hearts should give an overshield on touch.

/ringscrushinstadeath - [on|off] turn ringscrushinstadeath on or off to choose if you want being crushed to be instadeath.

/ringui_x - ringui_x [number|dpad|toggleui] this sets the x position of the ring counter should be a value between 0 and 320, ringui_x \\#A02200\\dpad\\#ffffff\\ for moving the ui with dpad,or ringui_x toggleui to toggle the ui

/ringui_y - ringui_y [number|dpad|toggleui] this sets the y position of the ring counter should be a value between 0 and -240, ringui_y \\#A02200\\dpad\\#ffffff\\ for moving the ui with dpad,or ringui_y toggleui to toggle the ui

/sonicfalldamage - [on|off] turn sonicfalldamage on or off to choose whether you can take fall damage

/sonichealthconfig = [save|load|savesuperpreqpref|loadsuperpreqpref|printserver|printlocal] to save the current sonic health settings to a file or load them (loading only works if used by a moderator or the server)

/sonichealthsuperbutton - [reset|change] set the button/buttons to turn super, reset sets it back to default(default x) and change allows you to change it

/sonicsuper - [on|off|prereq|7coinstar|number] toggle the ability to go super with 50+ rings + requirement, get the requirement by typing prereq ,change prereq by entering number of stars needed or entering 7coinstar to make super require 7 100 coin stars.

/disablelavabounce', [on|off] turn disablelavabounce \\#00C7FF\\on \\#ffffff\\or \\#A02200\\off \\#ffffff\\to choose if you want to lava bounce on lava.

so you can do /maxringloss 0 and /maxrecollectablerings 20 to lose all rings on hit but only be able to recover 20 of them.
</details>
this mod also contains an api that other mods can use _G.sonichealth
<details>
  <summary>api</summary>
  customsupercheck --function to allow another mod to pass its own super prereq check for if a romhack wants to set a specific super requirement
  
supermoveset--function to store super toggles for other mods with the functions having false for off and true for this mod to toggle which allows other mods such as movesets to act differently when super

getringcount --this function allows other mods to check ringcount

increaseringcount --this function allows other mods to modify ringcount

getversion --this function returns the sonic health version

addallycheck --expects the function to have parameters customfunc(attacker,victim) param victim mariostate of the player being attacked and param attacker mariostate of the player attacking and the function should return 1 (when the hit player is an ally and you don't want the player to affect their ally),return 2 (when the hit player is an ally and you want the interaction to happen without ring loss), and return 0 otherwise(which causes the hit player to lose rings on hit).

get_serversetting -- function that returns the value of a gGlobalSyncTable variable or variables used by sonichealth mod

getshield --this function allows other mods to check the player's shield

giveshield ----this function allows other mods to give/take away a shield

addcustomenemyfunction --this function allows other mods to have custom interactions

isplayersuper --this function returns whether a player is super

deprecated addsuperenemyfunction--this function allows other mod's objects to have unique interactions with super forms use addcustomenemyfunction instead
  </details>
