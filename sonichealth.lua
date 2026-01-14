-- name: .Sonic Health
-- description: Makes you lose coins on hit if you have no coins on hit you die \nCreated by wereyoshi. \n\nExtra coding by \\#00ffff\\steven.
-- pausable: true

local ringcount = 0 --the number of rings the local player has
gGlobalSyncTable.friendlyringloss = false --whether other players can cause you to lose rings
gGlobalSyncTable.maxringloss = 0 --maximum amount of rings you are allowed to lose at once if its equal to 0 you lose all rings at once
gGlobalSyncTable.maxrecollectablerings = 999 --maximum amount of rings you can get back per hit
gGlobalSyncTable.loseringsonlevelchange = true --whether to lose rings on level change
gPlayerSyncTable[0].losingrings = 0 --rings to deduct from the coin counter for a player
gGlobalSyncTable.ringscrushinstadeath = true --whether to instantly die when crushed
gGlobalSyncTable.decreasecoincounter = true --whether to decrease the coin counter on hit and have coins spawned on hit equal 1 coin or have the coin counter not decease on hit and have coins spawned only count for the ring counter
gPlayerSyncTable[0].shieldhits = 0  --current number of hits remaining for current shield
gPlayerSyncTable[0].shieldtype = 0  --current type for current shield
gGlobalSyncTable.recoveryheartshield = true --whether recovery hearts should give an overshield on touch
gGlobalSyncTable.sonicfalldamage = false --toggles fall damage
gGlobalSyncTable.sonicsuperallow = false --toggles super forms
gPlayerSyncTable[0].issuper = false  --if the current player is super
gGlobalSyncTable.superstarreq = 50 --min number of stars for super
gGlobalSyncTable.superstarsetting = 0 --which config to use for super 0 for x stars for super and 1 for 7 100 coin stars for super
gGlobalSyncTable.disablelavabounce = false --whether to disable lava bounce
local timer = 0 --timer that increments once per frame when super used for making the super forms lose 1 ring per second
local superformfunction --used by external mods for custom super requirements
local servermodsync = false --used for making some things run for the host only once which is when the host starts hosting
local nointeracttable = {} -- for objects with interacttype 0
local customenemyfunctions = {} --table of functions from other mods for unique interactions with objects with each key being a behaviorid
local supermovesetfunctions = {}--functions that tell other movesets that you are super
local superformfunctiontablelength = 0 --the number of functions in supermovesetfunctions
local bool_to_str = {[false] = "\\#A02200\\off\\#ffffff\\",[true] = "\\#00C7FF\\on\\#ffffff\\"} --table for converting boolean into string
local bool_to_num = {[false] = 0,[true] = 1} --table for converting boolean into numbers
local version = "2.4.0" --string containing the sonic health version
local settingsuperbutton = false --used for checking if the local player is setting the 1st super button
local movingui = false --used for checking if the local player is moving the ui with the dpad
local set2ndsuperbutton = false --used for checking if the local player is setting the 2nd super button
local allycheck --a function used for checking if a player is on a team set through _G.sonichealth.addallycheck 
local lastnumcoin --the last m.numCoins value the local player had used for detecting coin changes from objects with interacttype 0
local lastcoinobj --the last coin obj touched
local modsupporthelperfunctions = {} --local references to functions from other mods


local sonichealthconfig_command --this is the function for save server settings or loading them
local sonichealthsuperbutton_command --this is the function for changing the super button
local disablelavabounce_command --this function toggles the ability to lava bounce
local friendlyringloss_command --this function toggles ring loss by pvp
local loseringsonlevelchange_command --this function toggles whether to lose rings on level change
local ringscrushinstadeath_command --this function toggles being crushed being an instadeath
local decreasecoincounter_command --this function toggles whether to decrease the coin counter on hit
local recoveryheartshield_command --this function toggles recovery heart shield
local sonicfalldamage_command --this function toggles fall damage

if INTERACT_UNKNOWN_08 == nil then --code for if legacy variable INTERACT_UNKNOWN_08 was removed INTERACT_UNKNOWN_08 = INTERACT_SPINY_WALKING 
	INTERACT_UNKNOWN_08 = INTERACT_SPINY_WALKING
end

local buttons = {--doubly linked list of the different buttons
    [A_BUTTON] = {name = "A ",prev = nil ,next = B_BUTTON},
    [B_BUTTON] = {name = "B ",prev = A_BUTTON ,next = Z_TRIG},
    [Z_TRIG] = {name = "Z ",prev = B_BUTTON ,next = L_TRIG},
    [L_TRIG] = {name = "L ",prev = Z_TRIG ,next = R_TRIG},
    [R_TRIG] = {name = "R ",prev = L_TRIG ,next = X_BUTTON},
    [X_BUTTON] = {name = "X ",prev = R_TRIG ,next = Y_BUTTON},
    [Y_BUTTON] = {name = "Y ",prev = X_BUTTON ,next = L_JPAD},
    [L_JPAD] = {name = "dpad left ",prev = Y_BUTTON ,next = R_JPAD},
    [R_JPAD] = {name = "dpad right ",prev = L_JPAD ,next = U_JPAD},
    [U_JPAD] = {name = "dpad up ",prev = R_JPAD ,next = D_JPAD},
    [D_JPAD] = {name = "dpad down ",prev = U_JPAD ,next = L_CBUTTONS},
    [L_CBUTTONS] = {name = "c left ",prev = D_JPAD ,next = R_CBUTTONS},
    [R_CBUTTONS] = {name = "c right ",prev = L_CBUTTONS ,next = U_CBUTTONS},
    [U_CBUTTONS] = {name = "c up ",prev = R_CBUTTONS ,next = D_CBUTTONS},
    [D_CBUTTONS] = {name = "c down ",prev = U_CBUTTONS ,next = nil}
}

--function for converting strings to boolean
local function toboolean(s)
    if s == "false" then
        return false
    else
        return true
    end
end

local usingcoopdx = 0 --variable used to check for coopdx if 0 then the local player isn't using coopdx,1 for coopdx with coop compatibility on ,and 2 for coopdx with coop compatibility off
if  get_coop_compatibility_enabled ~= nil then --if the local user is using coopdx
    if get_coop_compatibility_enabled() == true then --if the local user is using coopdx's coop compatibility mode
        usingcoopdx = 1 --coop compatibility is on
    elseif SM64COOPDX_VERSION >= "1.0.0" then --excoop and coopdx merger
        usingcoopdx = 3
    else
        usingcoopdx = 2 --coop compatibility is off
    end
elseif SM64COOPDX_VERSION ~= nil then--if the local user is using a version of coopdx without the get_coop_compatibility_enabled function
	if gControllers == nil then --sm64coopdx v0.1 and sm64coopdx  v0.1.2 check
		usingcoopdx = 1
	else --versions of sm64coopdx after sm64coopdx v0.2 would use this since coop compatability would be deprecated
		usingcoopdx = 3 --post excoop and coopdx merge
	end
end

--table containg the different shield types
local shieldtypetable = {
	["default"] = 0,
	["flame"] = 1,
	["lightning"] = 2,
	["bubble"] = 3
}

local superbutton1 --button 1 to press to activate super form
local superbutton2 --button 2 to press to activate super form
local ringui_x --ring count ui's x coordinate
local ringui_y --ring count ui's y coordinate

if usingcoopdx == 0 then
	if (mod_storage_load("superbutton1") == nil) or (mod_storage_load("superbutton2") == nil) then
    	mod_storage_save("superbutton1", tostring(X_BUTTON))
    	mod_storage_save("superbutton2", tostring(X_BUTTON))
	end
	superbutton1 = tonumber(mod_storage_load("superbutton1"))
	superbutton2 = tonumber(mod_storage_load("superbutton2"))
	if mod_storage_load("ringcount_ui_x") == nil or mod_storage_load("ringcount_ui_y") == nil then
		mod_storage_save("ringcount_ui_x", "0")
		mod_storage_save("ringcount_ui_y", "0")
	end
	ringui_x = tonumber(mod_storage_load("ringcount_ui_x"))
	ringui_y = tonumber(mod_storage_load("ringcount_ui_y"))
else
	if (mod_storage_load("ringcount_ui_x") == nil) or (mod_storage_load("ringcount_ui_y") == nil) then
		mod_storage_save_number("ringcount_ui_x", 0)
		mod_storage_save_number("ringcount_ui_y", 0)
	end
	ringui_x = mod_storage_load_number("ringcount_ui_x")
	ringui_y = mod_storage_load_number("ringcount_ui_y")
	if (buttons[mod_storage_load_number("superbutton1")] == nil) or (buttons[mod_storage_load_number("superbutton2")] == nil) then
    	mod_storage_save_number("superbutton1", X_BUTTON)
    	mod_storage_save_number("superbutton2", X_BUTTON)
	end
	superbutton1 = mod_storage_load_number("superbutton1")
	superbutton2 = mod_storage_load_number("superbutton2")
	
end

--variable used for showing/hiding the sonic health ui
local toggleui = true

--- @param o Object
--function used for the id_bhvcoinring on init
function bhv_coinring_init(o)
	bhv_moving_yellow_coin_init()
	obj_set_billboard(o)
	cur_obj_init_animation(0)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.oInteractType = INTERACT_COIN
	o.hitboxDownOffset = 0
	o.oHealth = 0
	o.oNumLootCoins = 0
    o.hitboxRadius = 100
    o.hitboxHeight = 64
    o.hurtboxRadius= 0
	o.hurtboxHeight = 0
	if gGlobalSyncTable.decreasecoincounter == true then
		o.oDamageOrCoinValue = 1
	else
		o.oDamageOrCoinValue = 0
	end
	cur_obj_update_floor_and_walls()
end

--- @param o Object
--this sets an object used for making sure bowser dies when he is set to 0 or less health by sonic health's super form
function bhv_sonichealthbowserdeathconfirm_init(o)
    cur_obj_scale(1.0)
    cur_obj_set_hitbox_radius_and_height(100, 160)
    cur_obj_set_hurtbox_radius_and_height(0, 0)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
end

--- @param obj Object
--function used for the id_bhvcoinring after init
function bhv_coinring_loop(obj)
	bhv_yellow_coin_loop()
	bhv_moving_yellow_coin_loop()
	cur_obj_update_floor_and_walls()
	if obj.oFloorHeight ==  obj.oPosY then
		obj.oVelY = 40
	end
end

--- @param obj Object
--function used for making recovery hearts able to give shields
function bhv_sonicshield_heart_loop(obj)
	if (gMarioStates[0].playerIndex ~= 0) or gGlobalSyncTable.recoveryheartshield == false  then
		return
	elseif (nearest_interacting_mario_state_to_object(obj)).playerIndex == 0 and is_within_100_units_of_mario(obj.oPosX, obj.oPosY, obj.oPosZ) == 1 and ((gPlayerSyncTable[0].shieldhits ~= 1) or (gPlayerSyncTable[0].shieldtype ~= shieldtypetable["default"])) then
		if (gPlayerSyncTable[0].shieldtype ~= shieldtypetable["default"]) then
			djui_chat_message_create(string.format('Your %d hit %s shield got replaced with a generic 1-hit shield.',modsupporthelperfunctions.sonichealth.getshield("shieldtypeandhits")))
		else
			djui_chat_message_create('You got a 1-hit shield.')
		end
		gPlayerSyncTable[0].shieldhits = 1
		gPlayerSyncTable[0].shieldtype = 0
		
	end
end

--- @param o Object
--this is a loop for an object used for making sure bowser dies when he is set to 0 or less health by sonic health's super form
function bhv_sonichealthbowserdeathconfirm_loop(o)
    if (o.parentObj == nil) or (o.parentObj.oAction ~= 4) then
        obj_mark_for_deletion(o)
    elseif o.parentObj.oAction == 4 and (o.parentObj.oPosY < o.parentObj.oHomeY - 100.0 )then --check for bowser falling off stage while dead
        o.parentObj.oPosX = o.parentObj.oHomeX
        o.parentObj.oPosY = o.parentObj.oHomeY
        o.parentObj.oPosZ = o.parentObj.oHomeZ
    else
        o.oPosX = o.parentObj.oPosX
        o.oPosY = o.parentObj.oPosY
        o.oPosZ = o.parentObj.oPosZ
    end
end

--determines what happens on level start
local function ringInitialize()
	lastnumcoin = gMarioStates[0].numCoins
	lastcoinobj = nil
	if (gGlobalSyncTable.loseringsonlevelchange == true)  then
		ringcount = 0
	end
end

--- @param obj Object
-- randomize velocity and angle of the rings
local function ring_randomization(obj)
	obj.oVelY = math.random(30, 50)
	obj.oForwardVel = math.random(5, 10)
	obj.oMoveAngleYaw = math.random(0x0000, 0x10000)
end

--- @param m MarioState
--this function handles coins spawned on hit, deducting spawned coins from coin counter, and reducing ring counter
local function spawn_coin(m)
	local radius = 256
	m.hurtCounter = 0
	local ringposy
	if m.vel.y <= 0 then
		ringposy = m.pos.y + 161
	else
		ringposy = m.pos.y + 161 + m.vel.y
	end
	if m.invincTimer <= 0 then
		m.invincTimer = 60
	elseif ((m.flags & MARIO_METAL_CAP) ~= 0) or m.invincTimer > 0 then
		if (m.action == ACT_BURNING_GROUND or m.action == ACT_BURNING_JUMP or m.action == ACT_BURNING_FALL) and (m.input & INPUT_IN_POISON_GAS == 0)  then
			m.health = 0x880
		end
		return
	end
	if gPlayerSyncTable[0].issuper == true then
		return
	elseif  gPlayerSyncTable[0].shieldhits > 0 then
		gPlayerSyncTable[0].shieldhits = gPlayerSyncTable[0].shieldhits - 1
		if gPlayerSyncTable[0].shieldhits == 0 then
			gPlayerSyncTable[0].shieldtype = 0
		end
		djui_chat_message_create('Your shield took the hit.')
		return
	elseif ringcount == 0 then
		m.health = 0xff
		return
	end

	if (m.action == ACT_BURNING_GROUND or m.action == ACT_BURNING_JUMP or m.action == ACT_BURNING_FALL) and (m.input & INPUT_IN_POISON_GAS == 0) then
		m.health = 0x880
	end

	if (gGlobalSyncTable.maxringloss == 0 or ringcount < gGlobalSyncTable.maxringloss) then
			for i = 0,ringcount -1,1 do
				if i >= gGlobalSyncTable.maxrecollectablerings then
					break
				end
				spawn_sync_object(id_bhvCoinring,E_MODEL_YELLOW_COIN,m.pos.x , ringposy, m.pos.z,ring_randomization)
			end
			if gGlobalSyncTable.decreasecoincounter == true then
				for i = 0,MAX_PLAYERS - 1,1 do
					if gNetworkPlayers[i].currLevelNum == gNetworkPlayers[0].currLevelNum and gNetworkPlayers[i].currActNum == gNetworkPlayers[0].currActNum then
						gPlayerSyncTable[i].losingrings = gPlayerSyncTable[i].losingrings + ringcount
					end
				end
			end
			ringcount = 0
	else
		for i = 0,gGlobalSyncTable.maxringloss -1,1 do
			if i >= gGlobalSyncTable.maxrecollectablerings then
				break
			end
			spawn_sync_object(id_bhvCoinring,E_MODEL_YELLOW_COIN,m.pos.x, ringposy, m.pos.z,ring_randomization)
		end
		if gGlobalSyncTable.decreasecoincounter == true then
			for i = 0,MAX_PLAYERS - 1,1 do
				if gNetworkPlayers[i].currLevelNum == gNetworkPlayers[0].currLevelNum and gNetworkPlayers[i].currActNum == gNetworkPlayers[0].currActNum then
					gPlayerSyncTable[i].losingrings = gPlayerSyncTable[i].losingrings + gGlobalSyncTable.maxringloss
				end
			end
		end
		ringcount = ringcount - gGlobalSyncTable.maxringloss
	end
end

---@param attacker MarioState --attacking player's MarioState 
---@param victim MarioState -- attacked player's MarioState
--determines if an attacked player loses a coin on hit or dies by another player
local function sonicPvpHurt(attacker, victim)
	if victim.playerIndex ~= 0 then
        return
	elseif ((gGlobalSyncTable.friendlyringloss == false) and (gServerSettings.playerInteractions ~= PLAYER_INTERACTIONS_PVP))  or ((victim.flags & MARIO_METAL_CAP) ~= 0) or (allycheck ~= nil and allycheck(attacker,victim) == 2) then
		victim.hurtCounter = 0
	else
		victim.invincTimer = 0
		spawn_coin(victim)
	end

end

---@param attacker MarioState --attacking player's MarioState 
---@param victim MarioState -- attacked player's MarioState
--determines if an attacking player is allowed to attack a player
local function allow_pvp_attack(attacker, victim)
	if (allycheck ~= nil and (allycheck(attacker,victim)== bool_to_num[true])) then
		return false
	end

end

---@param m MarioState 
---@param o Object
--sets what happens when a character picks up a coin
local function sonicCoinGet(m, o,interactType)
	if (m.playerIndex ~= 0) then
		return
    elseif (m.playerIndex == 0) then
		if interactType == INTERACT_COIN and (get_id_from_behavior(o.behavior) == id_bhvCoinring)  then --checking that a ring was interacted with
			ringcount = ringcount + 1
			m.healCounter = 0
			lastnumcoin = m.numCoins
			lastcoinobj = o
		elseif interactType == INTERACT_COIN and (o.oDamageOrCoinValue > 0) then --checking that a coin was interacted with
			ringcount = ringcount + o.oDamageOrCoinValue
			m.healCounter = 0
			lastnumcoin = m.numCoins
			lastcoinobj = o
		end
    end
end

--sets up a clientside ring counter
local function ringDisplay()
	local hidetextactions = {[ACT_READING_AUTOMATIC_DIALOG] = true,[ACT_READING_NPC_DIALOG] = true,[ACT_READING_SIGN] = true, [ACT_INTRO_CUTSCENE] = true,[ACT_IN_CANNON] = true,[ACT_CREDITS_CUTSCENE] = true,[ACT_END_PEACH_CUTSCENE] = true,[ACT_END_WAVING_CUTSCENE] = true,[ACT_STAR_DANCE_NO_EXIT] = true}
	local m = gMarioStates[0]
	if (hidetextactions[m.action] == true) or ( (m.action == ACT_IDLE) and (hidetextactions[m.prevAction] == true)) or ((toggleui == false) and (settingsuperbutton ~= true) and (movingui ~= true)) then
		return
	end
    djui_hud_set_font(FONT_HUD)
    djui_hud_set_resolution(RESOLUTION_N64)

    local scale = 1
	local superbutton1name

    local superbutton2name

	local ringui_x_scaled = (ringui_x/320)*djui_hud_get_screen_width()
	local ringui_y_scaled = (ringui_y/240)*djui_hud_get_screen_height()
	local ringtext

	djui_hud_set_color(255, 255, 255, 255);
	if settingsuperbutton == true then
        if buttons[superbutton1] ~= nil then
            superbutton1name = buttons[superbutton1].name
        else
            superbutton1name = "nil"
        end

        if buttons[superbutton2] ~= nil then
            superbutton2name = buttons[superbutton2].name
        else
            superbutton2name = "nil"
        end
		ringtext = string.format("superbutton combo %s +%s",superbutton1name, superbutton2name)
		if (djui_hud_measure_text(ringtext) + ringui_x_scaled) > djui_hud_get_screen_width() then
			djui_hud_print_text(ringtext, djui_hud_get_screen_width() - djui_hud_measure_text(ringtext), -ringui_y_scaled, scale)
		else
    		djui_hud_print_text(ringtext, ringui_x_scaled, -ringui_y_scaled, scale)
		end
		if ringui_y > -120 then
            djui_hud_print_text("pick button using dpad, a to save, b to cancel", 0, 220, 0.8)
        else
            djui_hud_print_text("pick button using dpad, a to save, b to cancel", 0, 0, 0.8)
        end
	else
		ringtext = string.format("rings %d", ringcount)
		if (djui_hud_measure_text(ringtext) + ringui_x_scaled) > djui_hud_get_screen_width() then
			djui_hud_print_text(ringtext, djui_hud_get_screen_width() - djui_hud_measure_text(ringtext), -ringui_y_scaled, scale)
		else
    		djui_hud_print_text(ringtext, ringui_x_scaled, -ringui_y_scaled, scale)
		end
		if  movingui == true  then
        	if ringui_y > -120 then
            	djui_hud_print_text("move ui using dpad, a to save, b to cancel", 0, 220, 0.8)
        	else
            	djui_hud_print_text("move ui using dpad, a to save,b to cancel", 0, 0, 0.8)
			end
        end
	end
end

---@param m MarioState
--Called once per player per frame before physics code is run
local function before_phys_step(m)
    if (m.playerIndex ~= 0) then
		return
	elseif ((m.flags & MARIO_METAL_CAP) ~= 0) or (m.invincTimer ~= 0)  then
		m.hurtCounter = 0
	elseif (m.floor.type == SURFACE_BURNING and (m.pos.y == m.floorHeight) and (m.action ~= ACT_SLIDE_KICK))  then --checking if mario is standing on lava
		if ((gPlayerSyncTable[0].shieldtype == shieldtypetable["flame"]) or (gPlayerSyncTable[0].issuper == true)) and (m.invincTimer <=0) then
			m.invincTimer = 1
		end
		spawn_coin(m)
	elseif  m.wall ~= nil and m.wall.type == SURFACE_BURNING then --checking if mario is touching a lava wall
		if ((gPlayerSyncTable[0].shieldtype == shieldtypetable["flame"]) or (gPlayerSyncTable[0].issuper == true)) and (m.invincTimer <=0) then
			m.invincTimer = 1
		end
		spawn_coin(m)
    end
	local obj
	if nointeracttable ~= nil then
		for key,value in pairs(nointeracttable)do
            obj = obj_get_nearest_object_with_behavior_id(m.marioObj,key)
            if obj ~= nil and ((nearest_mario_state_to_object(obj)).playerIndex == 0) and obj_check_hitbox_overlap(m.marioObj,obj) then

                if (nointeracttable[key] ~= nil) then --call an external function to determine interaction
                    local customfunc = nointeracttable[key]
                    if customfunc ~= nil then
                        customfunc(obj)--custom object interacting
                    end
                end
            end
        end
	end
end

---@param bool boolean
--this function toggles super form
local function supertoggle(bool)
	local customfunc
	if bool == true then
		gPlayerSyncTable[0].issuper = true
		timer = 0
	else
		gPlayerSyncTable[0].issuper = false
	end
	if (supermovesetfunctions ~= nil) and (superformfunctiontablelength > 0) then
		for i=0,(superformfunctiontablelength),1 do
			customfunc = supermovesetfunctions[i]
			if customfunc ~= nil then
				customfunc(bool)
			end
		end
	end
end

-- hook that is called once per frame
local function health_hook_update()

	if gPlayerSyncTable[0].issuper == true then
		timer = timer + 1
		if (gGlobalSyncTable.sonicsuperallow == false) then
			supertoggle(false)
		elseif (timer % 30) == 0 then
			ringcount = ringcount - 1
			if ringcount <= 0 then
				supertoggle(false)
				if ringcount < 0 then
					ringcount = 0
				end
			end
			if gGlobalSyncTable.decreasecoincounter == true then
				for i = 0,MAX_PLAYERS - 1,1 do
					if gNetworkPlayers[i].currLevelNum == gNetworkPlayers[0].currLevelNum and gNetworkPlayers[i].currActNum == gNetworkPlayers[0].currActNum then
						gPlayerSyncTable[i].losingrings = gPlayerSyncTable[i].losingrings + 1
					end
				end
			end
		end

	end
	if settingsuperbutton == true then
        if (gMarioStates[0].controller.buttonPressed == A_BUTTON) then
            if set2ndsuperbutton == false then
                set2ndsuperbutton = true
                gMarioStates[0].controller.buttonPressed = gMarioStates[0].controller.buttonPressed & ~A_BUTTON
            else
                settingsuperbutton = false
                set2ndsuperbutton = false
                djui_chat_message_create(string.format("sonichealth superbutton1 is %s", buttons[superbutton1].name))
                djui_chat_message_create(string.format("sonichealth superbutton2 is %s", buttons[superbutton2].name))
				if usingcoopdx == 0 then
                	mod_storage_save("superbutton1", tostring(superbutton1))
                	mod_storage_save("superbutton2", tostring(superbutton2))
				else
					mod_storage_save_number("superbutton1", superbutton1)
                	mod_storage_save_number("superbutton2", superbutton2)
				end
                djui_chat_message_create('sonichealth super button combo  saved to mod storage')
            end
        elseif (gMarioStates[0].controller.buttonPressed == B_BUTTON) then
            settingsuperbutton = false
			if usingcoopdx == 0 then
            	superbutton1 = tonumber(mod_storage_load("superbutton1"))
            	superbutton2 = tonumber(mod_storage_load("superbutton2"))
			else
				superbutton1 = mod_storage_load_number("superbutton1")
            	superbutton2 = mod_storage_load_number("superbutton2")
			end
            djui_chat_message_create('sonichealth super button config loaded')
            djui_chat_message_create(string.format("sonichealth superbutton1 is %s", buttons[superbutton1].name))
            djui_chat_message_create(string.format("sonichealth superbutton2 is %s", buttons[superbutton2].name))
        else    
            if (gMarioStates[0].controller.buttonPressed == R_JPAD) and buttons[superbutton1].next ~= nil and set2ndsuperbutton == false then
                superbutton1 = buttons[superbutton1].next
            elseif (gMarioStates[0].controller.buttonPressed == L_JPAD) and buttons[superbutton1].prev ~= nil and set2ndsuperbutton == false then
                superbutton1 = buttons[superbutton1].prev
            elseif (gMarioStates[0].controller.buttonPressed == R_JPAD) and buttons[superbutton2].next ~= nil and set2ndsuperbutton == true then
                    superbutton2 = buttons[superbutton2].next
            elseif (gMarioStates[0].controller.buttonPressed == L_JPAD) and buttons[superbutton2].prev ~= nil and set2ndsuperbutton == true then
                    superbutton2 = buttons[superbutton2].prev
            end

        end
	elseif movingui == true then
        if (gMarioStates[0].controller.buttonPressed == A_BUTTON) then
            movingui = false
			djui_chat_message_create(string.format("ringcount ui's x coordinate is now %d", ringui_x))
			djui_chat_message_create(string.format("ringcount ui's y coordinate is now %d", ringui_y))
			if usingcoopdx == 0 then
				mod_storage_save("ringcount_ui_x", tostring(ringui_x))
				mod_storage_save("ringcount_ui_y", tostring(ringui_y))
			else
				mod_storage_save_number("ringcount_ui_x", ringui_x)
				mod_storage_save_number("ringcount_ui_y", ringui_y)
			end
            djui_chat_message_create('sonic health ui config saved to mod storage')
        elseif (gMarioStates[0].controller.buttonPressed == B_BUTTON) then
            movingui = false
			if usingcoopdx == 0 then
            	ringui_x = tonumber(mod_storage_load("ringcount_ui_x"))
            	ringui_y = tonumber(mod_storage_load("ringcount_ui_y"))
			else
				ringui_x = mod_storage_load_number("ringcount_ui_x")
            	ringui_y = mod_storage_load_number("ringcount_ui_y")
			end
            djui_chat_message_create('sonic health config loaded')
            djui_chat_message_create(string.format("ringcount ui's x coordinate is now %d", ringui_x))
        	djui_chat_message_create(string.format("ringcount ui's y coordinate is now %d", ringui_y))
        else
            if (gMarioStates[0].controller.buttonDown == R_JPAD) and (ringui_x < 320) then
                ringui_x= ringui_x + 1
            elseif (gMarioStates[0].controller.buttonDown == L_JPAD) and (ringui_x > 0) then
                ringui_x= ringui_x - 1
            end

            if (gMarioStates[0].controller.buttonDown == U_JPAD) and (ringui_y < 0) then
                ringui_y= ringui_y + 1
            elseif (gMarioStates[0].controller.buttonDown == D_JPAD) and (ringui_y > -240) then
                ringui_y= ringui_y - 1
            end

        end
    end

end
---@param m MarioState
--Called once per player per frame at the end of a mario update
local function coinstarcheck(m)
	local count = 0
	local starFlags
	for i = COURSE_BOB, COURSE_RR do
		starFlags = save_file_get_star_flags(get_current_save_file_num() - 1, i - 1)
		if (starFlags & (1 << 6) ~= 0) then --checking if a courses 100 coin star was collected
			count = count + 1
		end
	end
	if count >= 7 then
		return true
	else
		return false
	end
end

---@param m MarioState
--Called once per player per frame at the end of a mario update
function mario_update_end(m)
	if (m.playerIndex ~= 0) then
		return
	elseif gGlobalSyncTable.sonicfalldamage == false then
		m.peakHeight = m.pos.y --disabling fall damage
	end

	if (m.pos.y ~= m.floorHeight) and m.invincTimer > 0 and (m.action == ACT_FORWARD_AIR_KB or m.action == ACT_BACKWARD_AIR_KB or m.action == ACT_THROWN_BACKWARD or m.action == ACT_THROWN_FORWARD) then --making the invincibity timer not decrement until hitting the ground if in hitstun
		m.invincTimer = m.invincTimer + 1
	end

	if (gGlobalSyncTable.sonicsuperallow == true) and ( ( (m.controller.buttonPressed & superbutton1) ~= 0) and ( (m.controller.buttonPressed & superbutton2) ~= 0) ) then

		if gPlayerSyncTable[0].issuper == false and (ringcount >= 50) then
			if (superformfunction == nil) and (( (gGlobalSyncTable.superstarsetting == 0) and (m.numStars >= gGlobalSyncTable.superstarreq) ) or ( (gGlobalSyncTable.superstarsetting == 1) and (coinstarcheck(m) == true) ))  then
				supertoggle(true)
			elseif (superformfunction ~= nil) and superformfunction() == true then
				supertoggle(true)
			end

		elseif gPlayerSyncTable[0].issuper == true then
			if ((timer % 30 ~= 0) or (timer == 0)) and (ringcount > 0) then
				ringcount = ringcount - 1
			end
			supertoggle(false)
		end
	elseif gPlayerSyncTable[0].issuper == true then
		m.particleFlags = m.particleFlags | PARTICLE_SPARKLES
	end

	if ((gPlayerSyncTable[0].shieldtype == shieldtypetable["bubble"]) or (((m.input & INPUT_IN_POISON_GAS) == 0) and ((m.input & INPUT_IN_WATER) == 0) and ((m.input & INPUT_OFF_FLOOR) == 0)) ) and (m.health > 0xff) and (m.health < 0x880) then
		m.health = 0x880
	end

	if gPlayerSyncTable[0].losingrings ~= 0 then --deducting coins from current player's coin count if their losingrings field > 0
		m.numCoins = m.numCoins - gPlayerSyncTable[0].losingrings
		gPlayerSyncTable[0].losingrings = 0
		gPlayerSyncTable[0].numCoins = m.numCoins
		hud_set_value(HUD_DISPLAY_COINS, m.numCoins)
	end
end

---@param m MarioState
--Called when the local player dies, return false to prevent normal death sequence
function mario_death(m)
	if (m.playerIndex ~= 0) then
		return
	else
		ringcount = 0
		return
	end
end

---@param m MarioState
---@param o Object
---@param interactType InteractionType
--this function is for allowing mario to interact with objects.
local function allow_interact(m,o,interactType)
	local superimmunetable = {[INTERACT_DAMAGE] = true,[INTERACT_SHOCK] = true, [INTERACT_FLAME] = true , [INTERACT_SNUFIT_BULLET] = true ,[INTERACT_UNKNOWN_08] = true , [INTERACT_MR_BLIZZARD] = true, [INTERACT_CLAM_OR_BUBBA] = true} --interacttypes that super forms doesn't interact with by default
	if m.playerIndex ~= 0 then
        return
    end
	local customfuncresult
	local x = get_id_from_behavior(o.behavior)
	if  gPlayerSyncTable[0].issuper == true  then
		if (customenemyfunctions[x] ~= nil) and (type(customenemyfunctions[x]) == "function") then
			local customfunc = customenemyfunctions[x]
			if customfunc ~= nil then
                customfuncresult = customfunc(o)--whether the object can interact with mario return true to allow false disallow or a non boolean to have the object use default allow interaction settings for its type
            end
			if (type(customfuncresult) == "boolean")then
				return customfuncresult
			end
		end
		if superimmunetable[interactType] then
			o.oInteractStatus = ATTACK_KICK_OR_TRIP | INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED
			return false
		elseif (interactType == INTERACT_BOUNCE_TOP) or(interactType == INTERACT_BOUNCE_TOP2) or(interactType == INTERACT_HIT_FROM_BELOW) or (interactType == INTERACT_KOOPA and o.oKoopaMovementType < KOOPA_BP_KOOPA_THE_QUICK_BASE) then
			if (m.pos.y > o.oPosY) and (m.action & ACT_FLAG_AIR ~= 0) then
				return true
			else
				o.oInteractStatus =  ATTACK_GROUND_POUND_OR_TWIRL | INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED
				return false
			end
		elseif (interactType == INTERACT_BULLY) or ((customenemyfunctions[x] ~= nil) and (type(customenemyfunctions[x]) == "string") and (customenemyfunctions[x] == "INTERACT_BULLY")) then
			o.oInteractStatus = ATTACK_KICK_OR_TRIP | INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED
			o.oAction = BULLY_ACT_KNOCKBACK
			o.oFlags = o.oFlags & ~0x8
			o.oMoveAngleYaw = m.faceAngle.y
			o.oForwardVel = 3392 / o.hitboxRadius
			o.oBullyMarioCollisionAngle = o.oMoveAngleYaw
			o.oBullyLastNetworkPlayerIndex = gNetworkPlayers[0].globalIndex
			m.interactObj = o
			return false
		elseif (x == id_bhvChuckya) or ((customenemyfunctions[x] ~= nil) and (type(customenemyfunctions[x]) == "string") and (customenemyfunctions[x] == "id_bhvChuckya")) then
			o.oAction = 2
            o.oMoveFlags = o.oMoveFlags & OBJ_MOVE_LANDED
			return false
		elseif (x == id_bhvKingBobomb) or ((customenemyfunctions[x] ~= nil) and (type(customenemyfunctions[x]) == "string") and (customenemyfunctions[x] == "id_bhvKingBobomb")) then
			if (o.oAction ~= 0 and o.oAction ~= 4 and o.oAction ~= 5 and o.oAction ~= 6 and o.oAction ~= 7 and o.oAction ~= 8) then
				o.oPosY = o.oPosY + 20
                o.oVelY = 50
                o.oForwardVel = 20
                o.oAction = 4
			end
			return false
		elseif (x == id_bhvBowser) or ((customenemyfunctions[x] ~= nil) and (type(customenemyfunctions[x]) == "string") and (customenemyfunctions[x] == "id_bhvBowser")) then
			if (o.oAction ~= 0 and o.oAction ~= 4 and o.oAction ~= 5 and o.oAction ~= 6 and o.oAction ~= 12 and o.oAction ~= 20 ) then
				o.oHealth = o.oHealth - 1
                    if o.oHealth  <= 0 then
                        o.oMoveAngleYaw = o.oBowserAngleToCentre + 0x8000
                        o.oAction = 4
						spawn_non_sync_object(id_bhvbowserbossdeathconfirm,E_MODEL_NONE,o.oPosX,o.oPosY,o.oPosZ,function(newobj)
							newobj.parentObj = o
						end)
                    else
                        o.oAction = 12
                    end
			end
			return false
		end
	elseif (gPlayerSyncTable[0].shieldhits > 0) then
		if (customenemyfunctions ~= nil) and (customenemyfunctions[x] ~= nil) and (type(customenemyfunctions[x]) == "function")  then
			local customfunc = customenemyfunctions[x]
			if customfunc ~= nil then
				customfuncresult = customfunc(o)--whether the object can interact with mario return true to allow false disallow or a non boolean to have the object use default allow interaction settings for its type
            end
			if (type(customfuncresult) == "boolean")then
				return customfuncresult
			end
		end
		if (gPlayerSyncTable[0].shieldtype == shieldtypetable["flame"]) and interactType == INTERACT_FLAME then
			return false
		elseif (gPlayerSyncTable[0].shieldtype == shieldtypetable["lightning"]) and interactType == INTERACT_SHOCK then
			return false
		end
	elseif (customenemyfunctions ~= nil) and (customenemyfunctions[x] ~= nil) and (type(customenemyfunctions[x]) == "function")  then
		local customfunc = customenemyfunctions[x]
		if customfunc ~= nil then
			return customfunc(o)--whether the object can interact return true to allow false otherwise
		end
	end
end

---@param victim MarioState of player being attacked
---@param attacker MarioState  of player attacking
---this function is for kirby projectile interaction in the mariohunt mod
local function sonichealthmariohuntallycheck(attacker,victim)

    if (_G.mhApi.getGlobalField("anarchy") == 0) and _G.mhApi.getTeam(attacker.playerIndex) == _G.mhApi.getTeam(victim.playerIndex)then --if team attack if off
         return bool_to_num[true]
    elseif (_G.mhApi.getGlobalField("anarchy") == 1) and (_G.mhApi.getTeam(attacker.playerIndex) == _G.mhApi.getTeam(victim.playerIndex) and (_G.mhApi.getTeam(victim.playerIndex) == 0)) then --if team attack is only on for runners
        return bool_to_num[true]
    elseif (_G.mhApi.getGlobalField("anarchy") == 2) and (_G.mhApi.getTeam(attacker.playerIndex) == _G.mhApi.getTeam(victim.playerIndex) and (_G.mhApi.getTeam(victim.playerIndex) == 1)) then --if team attack is only on for hunters
        return bool_to_num[true]
    elseif _G.mhApi.isSpectator(victim.playerIndex) == true then
        return bool_to_num[true]
    else
        return bool_to_num[false]
    end
end

local function arenaitempickup(o)
	if lastnumcoin ~= gMarioStates[0].numCoins and lastcoinobj ~= nil then
		ringcount = ringcount + 1
		gMarioStates[0].numCoins = lastnumcoin
		lastcoinobj = o
	elseif lastcoinobj == nil then
		lastnumcoin = gMarioStates[0].numCoins
		lastcoinobj = o
	end

end

--function used for built in support for some external mods
local function modsupport()
	hook_event(HOOK_ALLOW_INTERACT, allow_interact) --Called before mario interacts with an object, return true to allow the interaction
	hook_event(HOOK_BEFORE_PHYS_STEP, before_phys_step)--Called once per player per frame before physics code is run, return an integer to cancel it with your own step result
	hook_event(HOOK_ALLOW_PVP_ATTACK, allow_pvp_attack) --Called before mario interacts with an object, return true to allow the interaction
	if _G.mhApi ~= nil and (allycheck == nil) then
        _G.sonichealth.addallycheck(sonichealthmariohuntallycheck)
	elseif _G.Arena ~= nil then
		_G.sonichealth.addcustomenemyfunction(arenaitempickup,bhvArenaCustom002,"nointeract") --adding an interaction for arena's item pickup object
    end
	if _G.charSelect ~= nil then --if the character select mod is on
		if _G.charSelect.credit_add ~= nil then
            _G.charSelect.credit_add(string.format("sonic health version %s", version),"wereyoshi","sonic health mod maker")
			_G.charSelect.credit_add(string.format("sonic health version %s", version),"steven.","code helper")
		end
	end
	for key,value in pairs(gActiveMods) do
        if (value.incompatible ~= nil) and string.match((value.incompatible), "romhack") then
			if value.name == nil then

            elseif ((value.name == "Star Road")) then --star road support
				if (bhvBowser ~= nil) and (customenemyfunctions[bhvBowser] == nil) then
                    _G.sonichealth.addcustomenemyfunction(function(o)
						if  gPlayerSyncTable[0].issuper == true  then
							if (o.oAction ~= 0 and o.oAction ~= 4 and o.oAction ~= 5 and o.oAction ~= 6 and o.oAction ~= 12 and o.oAction ~= 20 ) then
								o.oHealth = o.oHealth - 1
									if o.oHealth  <= 0 then
										o.oMoveAngleYaw = o.oBowserAngleToCentre + 0x8000
										o.oAction = 4
										spawn_non_sync_object(id_bhvbowserbossdeathconfirm,E_MODEL_NONE,o.oPosX,o.oPosY,o.oPosZ,function(newobj)
											newobj.parentObj = o
										end)
									else
										o.oAction = 12
									end
							elseif o.oAction == 4 and o.oSubAction == 11 and o.oHealth  > 0 then
								o.oHealth = o.oHealth - 1
								o.oAction = 12
							end
							return false
						end
					end,bhvBowser) --making star road's bowser killable by sonic health super form
				else
					_G.sonichealth.addcustomenemyfunction(function(o)
						if  gPlayerSyncTable[0].issuper == true  then
							if (o.oAction ~= 0 and o.oAction ~= 4 and o.oAction ~= 5 and o.oAction ~= 6 and o.oAction ~= 12 and o.oAction ~= 20 ) then
								o.oHealth = o.oHealth - 1
									if o.oHealth  <= 0 then
										o.oMoveAngleYaw = o.oBowserAngleToCentre + 0x8000
										o.oAction = 4
										spawn_non_sync_object(id_bhvbowserbossdeathconfirm,E_MODEL_NONE,o.oPosX,o.oPosY,o.oPosZ,function(newobj)
											newobj.parentObj = o
										end)
									else
										o.oAction = 12
									end
							elseif o.oAction == 4 and o.oSubAction == 11 and o.oHealth  > 0 then
								o.oHealth = o.oHealth - 1
								o.oAction = 12
							end
							return false
						end
					end,id_bhvBowser) --making star road's bowser killable by sonic health super form
                end
			end
		elseif value.name == nil then

		elseif (string.match(value.name,"Brutal Bosses")) then
			_G.sonichealth.addcustomenemyfunction(function(o)
				if  gPlayerSyncTable[0].issuper == true  then
					local immuneactions = {[2] = true,[4] = true}
                	if (o.oInteractType ~= INTERACT_TEXT) then
						if (immuneactions[o.oAction] ~= true) then
                    		o.oInteractStatus = INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED
						end
						return false
                	end
				end
			end,bhvBossCustomToadMessage)--making brutal boss's toad boss killable by sonic health super form
			_G.sonichealth.addcustomenemyfunction(function(o)
				if  gPlayerSyncTable[0].issuper == true  then
					local YOSHI_ACT_DAMAGED = YOSHI_ACT_CREDITS + 4
                	if (o.oAction > YOSHI_ACT_CREDITS) and (o.oInteractType ~= INTERACT_TEXT) and (o.oAction ~= YOSHI_ACT_DAMAGED) then
                    	o.oInteractStatus = INT_STATUS_INTERACTED | INT_STATUS_TOUCHED_BOB_OMB
                    	return false
                	end
				end
			end,bhvYoshi)--making brutal boss's yoshi boss killable by sonic health super form
		end

	end
	if servermodsync then --if using coopdx after the merge
		if (mod_storage_load("friendlyringloss") == nil) or (mod_storage_load("loseringsonlevelchange") == nil) or (mod_storage_load("ringscrushinstadeath") == nil) or (mod_storage_load("decreasecoincounter") == nil) or (mod_storage_load("recoveryheartshield") == nil) or (mod_storage_load("sonicfalldamage") == nil) or (mod_storage_load("sonicsuperallow") == nil) or (mod_storage_load("maxringloss") == nil) or (mod_storage_load("maxrecollectablerings") == nil) then
			mod_storage_save_bool("friendlyringloss", gGlobalSyncTable.friendlyringloss)
			mod_storage_save_bool("loseringsonlevelchange", true)
			mod_storage_save_bool("ringscrushinstadeath", true)
			mod_storage_save_bool("decreasecoincounter", true)
			mod_storage_save_bool("recoveryheartshield", true)
			mod_storage_save_bool("sonicfalldamage", gGlobalSyncTable.sonicfalldamage)
			mod_storage_save_bool("sonicsuperallow", gGlobalSyncTable.sonicsuperallow)
			mod_storage_save_number("maxringloss", gGlobalSyncTable.maxringloss)
			mod_storage_save_number("maxrecollectablerings", 999)
		else
			gGlobalSyncTable.friendlyringloss = mod_storage_load_bool("friendlyringloss")
			gGlobalSyncTable.loseringsonlevelchange = mod_storage_load_bool("loseringsonlevelchange")
			gGlobalSyncTable.ringscrushinstadeath = mod_storage_load_bool("ringscrushinstadeath")
			gGlobalSyncTable.decreasecoincounter = mod_storage_load_bool("decreasecoincounter")
			gGlobalSyncTable.recoveryheartshield = mod_storage_load_bool("recoveryheartshield")
			gGlobalSyncTable.sonicfalldamage = mod_storage_load_bool("sonicfalldamage")
			gGlobalSyncTable.sonicsuperallow = mod_storage_load_bool("sonicsuperallow")
			gGlobalSyncTable.maxringloss =  mod_storage_load_number("maxringloss")
			gGlobalSyncTable.maxrecollectablerings = mod_storage_load_number("maxrecollectablerings")
		end
		if (mod_storage_load("superstarreq") == nil) or (mod_storage_load("superstarsetting") == nil) or (mod_storage_load("disablelavabounce") == nil) then
			mod_storage_save_number("superstarsetting",gGlobalSyncTable.superstarsetting)
			mod_storage_save_number("superstarreq",gGlobalSyncTable.superstarreq)
			mod_storage_save_bool("disablelavabounce", false)
		else
			gGlobalSyncTable.superstarsetting = mod_storage_load_number("superstarsetting")
			gGlobalSyncTable.superstarreq = mod_storage_load_number("superstarreq")
			gGlobalSyncTable.disablelavabounce = toboolean( mod_storage_load("disablelavabounce"))
		end
		if hook_mod_menu_text ~= nil then
            hook_mod_menu_text(string.format("mod version %s",version))
        end
		hook_mod_menu_button("print sonic health server config",function(index)
            sonichealthconfig_command('printserver')
        end)
        hook_mod_menu_button("print sonic health local config",function(index)
            sonichealthconfig_command('printlocal')
        end)

        hook_mod_menu_button("save current sonic health config",function(index)
            sonichealthconfig_command('save')
        end)
        hook_mod_menu_button("load sonic health config",function(index)
            sonichealthconfig_command('load')
        end)
		hook_mod_menu_button("save current sonic health super pref",function(index)
            sonichealthconfig_command('savesuperpreqpref')
        end)
		hook_mod_menu_button("load sonic health super pref",function(index)
            sonichealthconfig_command('loadsuperpreqpref')
        end)
		hook_mod_menu_button("toggle bounce on lava",function(index)
            local s
            if gGlobalSyncTable.disablelavabounce then
                s = 'off'
            else
                s = 'on'
            end
            disablelavabounce_command(s)
        end)
		hook_mod_menu_button("toggle friendly ring loss",function(index)
            local s
            if gGlobalSyncTable.friendlyringloss then
                s = 'off'
            else
                s = 'on'
            end
            friendlyringloss_command(s)
        end)
		hook_mod_menu_button("toggle ring loss on level change",function(index)
            local s
            if gGlobalSyncTable.loseringsonlevelchange then
                s = 'off'
            else
                s = 'on'
            end
            loseringsonlevelchange_command(s)
        end)
		hook_mod_menu_button("toggle crushing being instadeath",function(index)
            local s
            if gGlobalSyncTable.ringscrushinstadeath then
                s = 'off'
            else
                s = 'on'
            end
            ringscrushinstadeath_command(s)
        end)
		hook_mod_menu_button("toggle losing rings decreasing coin counter",function(index)
            local s
            if gGlobalSyncTable.decreasecoincounter then
                s = 'off'
            else
                s = 'on'
            end
            decreasecoincounter_command(s)
        end)
		hook_mod_menu_button("toggle recovery hearts giving shields",function(index)
            local s
            if gGlobalSyncTable.recoveryheartshield then
                s = 'off'
            else
                s = 'on'
            end
            recoveryheartshield_command(s)
        end)
		hook_mod_menu_button("toggle fall damage",function(index)
            local s
            if gGlobalSyncTable.sonicfalldamage then
                s = 'off'
            else
                s = 'on'
            end
            sonicfalldamage_command(s)
        end)
		
		hook_mod_menu_checkbox("change sonic health super button",false,function(index,value)
            
            if value then
                if (settingsuperbutton == false) and (set2ndsuperbutton == false) then
                    settingsuperbutton = value
                end
            end
        end)
		hook_mod_menu_checkbox("toggle sonichealth ui",false,function(index,value)
            toggleui = value
        end)
		if _G.cheatsApi ~= nil then
            hook_mod_menu_button("999 rings",function(index)
				ringcount = 999
			end)
        end

	end
end

--- @param m MarioState
--Called when a player connects
function on_player_connected(m)
    -- only run on server
    if not network_is_server() then
        return
	end
	if servermodsync == false then
        modsupport()
		if usingcoopdx == 0 then
			if (mod_storage_load("friendlyringloss") == nil) or (mod_storage_load("loseringsonlevelchange") == nil) or (mod_storage_load("ringscrushinstadeath") == nil) or (mod_storage_load("decreasecoincounter") == nil) or (mod_storage_load("recoveryheartshield") == nil) or (mod_storage_load("sonicfalldamage") == nil) or (mod_storage_load("sonicsuperallow") == nil) or (mod_storage_load("maxringloss") == nil) or (mod_storage_load("maxrecollectablerings") == nil) then
				mod_storage_save("friendlyringloss", tostring(gGlobalSyncTable.friendlyringloss))
				mod_storage_save("loseringsonlevelchange", tostring(gGlobalSyncTable.loseringsonlevelchange))
				mod_storage_save("ringscrushinstadeath", tostring(gGlobalSyncTable.ringscrushinstadeath))
				mod_storage_save("decreasecoincounter", tostring(gGlobalSyncTable.decreasecoincounter))
				mod_storage_save("recoveryheartshield", tostring(gGlobalSyncTable.recoveryheartshield))
				mod_storage_save("sonicfalldamage", tostring(gGlobalSyncTable.sonicfalldamage))
				mod_storage_save("sonicsuperallow", tostring(gGlobalSyncTable.sonicsuperallow))
				mod_storage_save("maxringloss", tostring(gGlobalSyncTable.maxringloss))
				mod_storage_save("maxrecollectablerings", tostring(gGlobalSyncTable.maxrecollectablerings))
			else
				gGlobalSyncTable.friendlyringloss = toboolean( mod_storage_load("friendlyringloss"))
				gGlobalSyncTable.loseringsonlevelchange = toboolean( mod_storage_load("loseringsonlevelchange"))
				gGlobalSyncTable.ringscrushinstadeath = toboolean( mod_storage_load("ringscrushinstadeath"))
				gGlobalSyncTable.decreasecoincounter = toboolean( mod_storage_load("decreasecoincounter"))
				gGlobalSyncTable.recoveryheartshield = toboolean( mod_storage_load("recoveryheartshield"))
				gGlobalSyncTable.sonicfalldamage = toboolean( mod_storage_load("sonicfalldamage"))
				gGlobalSyncTable.sonicsuperallow = toboolean( mod_storage_load("sonicsuperallow"))
				gGlobalSyncTable.maxringloss = tonumber(mod_storage_load("maxringloss"))
				gGlobalSyncTable.maxrecollectablerings = tonumber(mod_storage_load("maxrecollectablerings"))
			end
			if (mod_storage_load("superstarreq") ~= nil) and (mod_storage_load("superstarsetting") ~= nil) or (mod_storage_load("superstarreq") ~= nil) then
				gGlobalSyncTable.superstarsetting = tonumber(mod_storage_load("superstarsetting"))
				gGlobalSyncTable.superstarreq = tonumber(mod_storage_load("superstarreq"))
				gGlobalSyncTable.disablelavabounce = toboolean( mod_storage_load("disablelavabounce"))
			end
		else
			if (mod_storage_load("friendlyringloss") == nil) or (mod_storage_load("loseringsonlevelchange") == nil) or (mod_storage_load("ringscrushinstadeath") == nil) or (mod_storage_load("decreasecoincounter") == nil) or (mod_storage_load("recoveryheartshield") == nil) or (mod_storage_load("sonicfalldamage") == nil) or (mod_storage_load("sonicsuperallow") == nil) or (mod_storage_load("maxringloss") == nil) or (mod_storage_load("maxrecollectablerings") == nil) then
				mod_storage_save_bool("friendlyringloss", gGlobalSyncTable.friendlyringloss)
				mod_storage_save_bool("loseringsonlevelchange", true)
				mod_storage_save_bool("ringscrushinstadeath", true)
				mod_storage_save_bool("decreasecoincounter", true)
				mod_storage_save_bool("recoveryheartshield", true)
				mod_storage_save_bool("sonicfalldamage", gGlobalSyncTable.sonicfalldamage)
				mod_storage_save_bool("sonicsuperallow", gGlobalSyncTable.sonicsuperallow)
				mod_storage_save_number("maxringloss", gGlobalSyncTable.maxringloss)
				mod_storage_save_number("maxrecollectablerings", 999)
			else
				gGlobalSyncTable.friendlyringloss = mod_storage_load_bool("friendlyringloss")
				gGlobalSyncTable.loseringsonlevelchange = mod_storage_load_bool("loseringsonlevelchange")
				gGlobalSyncTable.ringscrushinstadeath = mod_storage_load_bool("ringscrushinstadeath")
				gGlobalSyncTable.decreasecoincounter = mod_storage_load_bool("decreasecoincounter")
				gGlobalSyncTable.recoveryheartshield = mod_storage_load_bool("recoveryheartshield")
				gGlobalSyncTable.sonicfalldamage = mod_storage_load_bool("sonicfalldamage")
				gGlobalSyncTable.sonicsuperallow = mod_storage_load_bool("sonicsuperallow")
				gGlobalSyncTable.maxringloss =  mod_storage_load_number("maxringloss")
				gGlobalSyncTable.maxrecollectablerings = mod_storage_load_number("maxrecollectablerings")
			end
			if (mod_storage_load("superstarreq") == nil) or (mod_storage_load("superstarsetting") == nil) or (mod_storage_load("disablelavabounce") == nil) then
				mod_storage_save_number("superstarsetting",gGlobalSyncTable.superstarsetting)
				mod_storage_save_number("superstarreq",gGlobalSyncTable.superstarreq)
				mod_storage_save_bool("disablelavabounce", false)
			else
				gGlobalSyncTable.superstarsetting = mod_storage_load_number("superstarsetting")
				gGlobalSyncTable.superstarreq = mod_storage_load_number("superstarreq")
				gGlobalSyncTable.disablelavabounce = toboolean( mod_storage_load("disablelavabounce"))
			end
		end
        servermodsync = true
		if usingcoopdx == 0 then
			log_to_console('You are using a version of excoop before the merging of coopdx and excoop some features are unavailable')
			log_to_console('To use some features of this mod you need to update at https://sm64coopdx.com/ or https://github.com/coop-deluxe/sm64coopdx/releases')
		else
			log_to_console('You are using a version of coopdx before the merging of coopdx and excoop some features are unavailable',2)
			log_to_console('To use some features of this mod you need to update at https://sm64coopdx.com/ or https://github.com/coop-deluxe/sm64coopdx/releases',2)
		end
    end
	for i=0,(MAX_PLAYERS-1) do
		if gPlayerSyncTable[i].losingrings == nil then
			gPlayerSyncTable[i].losingrings = 0
			gPlayerSyncTable[i].shieldhits = 0
			gPlayerSyncTable[i].shieldtype = 0
		end

    end
end

--Called when the local player finishes the join process (if the player isn't the host)
local function on_join()
	if servermodsync == false then
    	modsupport()
		servermodsync = true
		if usingcoopdx == 0 then
			log_to_console('You are using a version of excoop before the merging of coopdx and excoop some features are unavailable')
			log_to_console('To use some features of this mod you need to update at https://sm64coopdx.com/ or https://github.com/coop-deluxe/sm64coopdx/releases')
		else
			log_to_console('You are using a version of coopdx before the merging of coopdx and excoop some features are unavailable',2)
			log_to_console('To use some features of this mod you need to update at https://sm64coopdx.com/ or https://github.com/coop-deluxe/sm64coopdx/releases',2)
		end
	end
end

---@param m MarioState
---@param incomingAction integer
--this function is called before every time a player's current action is changed
local function before_set_mario_action(m,incomingAction)
    if m.playerIndex ~= 0 then
        return
    end
	local waterdisolveshields = {[shieldtypetable["flame"]] = true,[shieldtypetable["lightning"]] = true} --table of shields that go away in water
	if (gPlayerSyncTable[0].shieldhits > 0) and (waterdisolveshields[gPlayerSyncTable[0].shieldtype] == true) and (((m.input & INPUT_IN_WATER) ~= 0)) then
		djui_chat_message_create('Your shield was lost due to water.')
		gPlayerSyncTable[0].shieldhits = 0
		gPlayerSyncTable[0].shieldtype = 0
	end
	if (incomingAction == ACT_HARD_BACKWARD_GROUND_KB or incomingAction == ACT_HARD_FORWARD_GROUND_KB or incomingAction == ACT_BACKWARD_GROUND_KB or incomingAction == ACT_FORWARD_GROUND_KB) and m.vel.y < 0  then
		if  m.hurtCounter > 0 and m.invincTimer <= 0 then
			spawn_coin(m)
		end
		return ACT_IDLE
	elseif (gGlobalSyncTable.disablelavabounce == true) and (incomingAction == ACT_LAVA_BOOST) then
		return ACT_BACKWARD_AIR_KB
	elseif incomingAction == ACT_BURNING_GROUND and m.pos.y == m.floorHeight and m.floor.type ~= SURFACE_BURNING then
		if ((gPlayerSyncTable[0].shieldtype == shieldtypetable["flame"]) or (gPlayerSyncTable[0].issuper == true)) and (m.invincTimer <=0) then
			m.invincTimer = 1
		end
		spawn_coin(m)
		return ACT_IDLE
	elseif incomingAction == ACT_BURNING_FALL then
		if ((gPlayerSyncTable[0].shieldtype == shieldtypetable["flame"]) or (gPlayerSyncTable[0].issuper == true)) and (m.invincTimer <=0) then
			m.invincTimer = 1
		end
		spawn_coin(m)
		return ACT_BACKWARD_AIR_KB
	elseif  m.hurtCounter > 0 or (incomingAction == ACT_BURNING_GROUND and (m.wall == nil or ( m.wall ~= nil and m.wall.type ~= SURFACE_BURNING)) and (m.floor.type ~= SURFACE_BURNING and m.pos.y == m.floorHeight) ) then
		if ((gPlayerSyncTable[0].shieldtype == shieldtypetable["flame"]) or (gPlayerSyncTable[0].issuper == true)) and (m.invincTimer <=0) then
			m.invincTimer = 1
		end
		spawn_coin(m)
		return
    end

end


---@param m MarioState
--this function is called every time a player's current action is changed
local function on_set_mario(m)

	if m.playerIndex ~= 0 then
        return
    end

	if (m.action == ACT_SQUISHED)  then 
		if (gGlobalSyncTable.ringscrushinstadeath == true) then
			m.health = 0xff
			m.invincTimer = 60
		else
			spawn_coin(m)
			return
		end
	end

end

---@param m MarioState
---@param hazardType integer
--Called once per player per frame. Return false to prevent the player from being affected by lava or quicksand.
local function allow_hazard_surface(m,hazardType)
	if m.playerIndex ~= 0 then
		return
	end
    if (gGlobalSyncTable.disablelavabounce == true) and  ((gPlayerSyncTable[0].issuper == true) or (m.invincTimer > 0) or (gPlayerSyncTable[0].shieldtype == shieldtypetable["flame"])) then
		if (hazardType == HAZARD_TYPE_LAVA_WALL) and (m.floorHeight ~= m.pos.y) then
			set_mario_action(m, ACT_AIR_HIT_WALL, 0)
			return false
		elseif  ((hazardType == HAZARD_TYPE_LAVA_FLOOR) or ((hazardType == HAZARD_TYPE_LAVA_WALL)))	then
			return false
		else
			return
		end

    end
end

---@param m MarioState
--Called once per player per frame at the beginning of a mario update
local function before_mario_update(m)
	if m.playerIndex ~= 0 then
		return
	end
	if ((m.marioObj.oInteractStatus & INT_STATUS_HIT_BY_SHOCKWAVE) ~= 0 ) and ((gPlayerSyncTable[0].shieldtype == shieldtypetable["lightning"]) or (gPlayerSyncTable[0].issuper == true)) then
		m.marioObj.oInteractStatus = m.marioObj.oInteractStatus & ~INT_STATUS_HIT_BY_SHOCKWAVE
	end
end

--- @param msg string
--this function toggles ring loss by pvp
friendlyringloss_command = function(msg)
    if not network_is_server() then
        djui_chat_message_create('Only the host can change this setting!')
        return true
    end
	local m = string.lower(msg)
    if m == 'on' then
        djui_chat_message_create('Friendly ring loss is \\#00C7FF\\on\\#ffffff\\!')
		gGlobalSyncTable.friendlyringloss = true 
        return true
	elseif m == 'off' then
		djui_chat_message_create('Friendly ring loss is \\#A02200\\off\\#ffffff\\!')
		gGlobalSyncTable.friendlyringloss = false 
		return true
	else
		return false
    end
end

--- @param msg string
--this function sets the max amount of rings that can be lost per hit
local function maxringloss_command(msg)
    if not network_is_server() then
        djui_chat_message_create('Only the host can change this setting!')
        return true
    end

    if tonumber(msg) and (tonumber(msg) >= 0) then
		gGlobalSyncTable.maxringloss = tonumber(msg)
        djui_chat_message_create(string.format("Max ring loss is now %d", gGlobalSyncTable.maxringloss))
        return true
	else 
		djui_chat_message_create('Invalid input. Must be a number like maxringloss 5 and the number needs to be 0 or greater.')
		return true
    end
end

--- @param msg string
--this function toggles whether to lose rings on level change
loseringsonlevelchange_command = function(msg)
    if not network_is_server() then
        djui_chat_message_create('Only the host can change this setting!')
        return true
    end
	local m = string.lower(msg)
    if m == 'on' then
        djui_chat_message_create('Lose rings on level change is \\#00C7FF\\on\\#ffffff\\!')
		gGlobalSyncTable.loseringsonlevelchange = true 
        return true
	elseif m == 'off' then
		djui_chat_message_create('Lose ringson level change is \\#A02200\\off\\#ffffff\\!')
		gGlobalSyncTable.loseringsonlevelchange = false 
		return true
	else
		return false
    end
end

--- @param msg string
--this function toggles being crushed being an instadeath
ringscrushinstadeath_command = function(msg)
    if not network_is_server() then
        djui_chat_message_create('Only the host can change this setting!')
        return true
    end
	local m = string.lower(msg)
    if m == 'on' then
        djui_chat_message_create('Crushed instadeath is \\#00C7FF\\on\\#ffffff\\!')
		gGlobalSyncTable.ringscrushinstadeath = true 
        return true
	elseif m == 'off' then
		djui_chat_message_create('Crushed instadeath is \\#A02200\\off\\#ffffff\\!')
		gGlobalSyncTable.ringscrushinstadeath = false 
		return true
	else
		return false
    end
end

--- @param msg string
--this function toggles whether to decrease the coin counter on hit
decreasecoincounter_command = function(msg)
    if not network_is_server() then
        djui_chat_message_create('Only the host can change this setting!')
        return true
    end
	local m = string.lower(msg)
    if m == 'on' then
        djui_chat_message_create('\\#00C7FF\\The coin counter will now decrease if you take a hit\\#ffffff\\!')
		gGlobalSyncTable.decreasecoincounter = true 
        return true
	elseif m == 'off' then
		djui_chat_message_create('\\#A02200\\The coin counter will no longer decrease if you take a hit\\#ffffff\\!')
		gGlobalSyncTable.decreasecoincounter = false 
		return true
	else
		return false
    end
end

--- @param msg string
--this function toggles recovery heart shield
recoveryheartshield_command = function(msg)
    if not network_is_server() then
        djui_chat_message_create('Only the host can change this setting!')
        return true
    end
	local m = string.lower(msg)
    if m == 'on' then
        djui_chat_message_create('\\#00C7FF\\Recovery hearts will now give shields\\#ffffff\\!')
		gGlobalSyncTable.recoveryheartshield = true 
        return true
	elseif m == 'off' then
		djui_chat_message_create('\\#A02200\\Recovery hearts will no longer give shields\\#ffffff\\!')
		gGlobalSyncTable.recoveryheartshield = false 
		return true
	else
		return false
    end
end

--- @param msg string
--this function toggles fall damage
sonicfalldamage_command = function(msg)
    if not network_is_server() then
        djui_chat_message_create('Only the host can change this setting!')
        return true
    end
	local m = string.lower(msg)
    if m == 'on' then
        djui_chat_message_create('\\#00C7FF\\you can now take fall damage\\#ffffff\\!')
		gGlobalSyncTable.sonicfalldamage = true 
        return true
	elseif m == 'off' then
		djui_chat_message_create('\\#A02200\\you now cannot take fall damage\\#ffffff\\!')
		gGlobalSyncTable.sonicfalldamage = false 
		return true
	else
		return false
    end
end

--- @param msg string
--this function sets the max amount of rings that could be recovered on hit
local function maxrecollectablerings_command(msg)
    if not network_is_server() then
        djui_chat_message_create('Only the host can change this setting!')
        return true
    end

    if tonumber(msg) and (tonumber(msg) >= 0) then
		gGlobalSyncTable.maxrecollectablerings = tonumber(msg)
        djui_chat_message_create(string.format("Max recollectable rings per hit is now %d", gGlobalSyncTable.maxrecollectablerings))
        return true
	else 
		djui_chat_message_create('Invalid input. Must be a number like maxrecollectablerings 5 and the number needs to be 0 or greater.')
		return true
    end
end

--- @param msg string
--this is the function sets the ring counts y position
local function ringui_x_command(msg)

    if tonumber(msg) and (tonumber(msg) >= 0) and (tonumber(msg) <= 320) then
		if usingcoopdx == 0 then
			mod_storage_save("ringcount_ui_x", msg)
			ringui_x = tonumber(mod_storage_load("ringcount_ui_x"))
		else
			mod_storage_save_number("ringcount_ui_x", tonumber(msg))
			ringui_x = mod_storage_load_number("ringcount_ui_x")
		end
        djui_chat_message_create(string.format("ringcount ui's x coordinate is now %d", ringui_x))
        return true
	elseif msg == 'dpad' then
        movingui = true
        return true
	elseif msg == 'toggleui' then
        toggleui = not toggleui
		djui_chat_message_create(string.format("the ui has been turned  %s",bool_to_str[toggleui]))
        return true
	else 
		djui_chat_message_create('Invalid input. Must be a number like ringui_x 5 and the number needs to be 0 or greater.')
		return true
    end
end

--- @param msg string
--this is the function sets the ring counts y position
local function ringui_y_command(msg)

    if tonumber(msg) and (tonumber(msg) <= 0) and (tonumber(msg) >= -240) then
		if usingcoopdx == 0 then
			mod_storage_save("ringcount_ui_y", msg)
			ringui_y = tonumber(mod_storage_load("ringcount_ui_y"))
		else
			mod_storage_save_number("ringcount_ui_y", tonumber(msg))
			ringui_y = mod_storage_load_number("ringcount_ui_y")
		end
        djui_chat_message_create(string.format("ringcount ui's y coordinate is now %d", ringui_y))
        return true
	elseif msg == 'dpad' then
        movingui = true
        return true
	elseif msg == 'toggleui' then
        toggleui = not toggleui
		djui_chat_message_create(string.format("the ui has been turned  %s",bool_to_str[toggleui]))
        return true
	else
		djui_chat_message_create('Invalid input. Must be a number like ringui_y -5 and the number needs to be 0 or less.')
		return true
    end
end

--- @param msg string
--this is the function toggles super forms
local function sonicsuper_command(msg)
	local m = string.lower(msg)
	if m == 'prereq' then
		djui_chat_message_create('you need 50 rings ')
		if superformfunction ~= nil and (type(superformfunction) == "function") then
			superformfunction(m)
		else
			if gGlobalSyncTable.superstarsetting == 0 then
				djui_chat_message_create(string.format("and %d stars",gGlobalSyncTable.superstarreq))
			elseif gGlobalSyncTable.superstarsetting == 1 then
				djui_chat_message_create('and 7 100 coin stars')
			end
		end
		return true
	end

    if not network_is_server() then
        djui_chat_message_create('Only the host can change this setting!')
        return true
    end

    if m == 'on' then
        djui_chat_message_create('\\#00C7FF\\you can now go super\\#ffffff\\!')
		gGlobalSyncTable.sonicsuperallow = true --toggles super forms 
        return true
	elseif m == 'off' then
		djui_chat_message_create('\\#A02200\\you now cannot go super\\#ffffff\\!')
		gGlobalSyncTable.sonicsuperallow = false --toggles super forms
		return true
	elseif m == '7coinstar' then
		djui_chat_message_create("super star requirement is now 7 100 coin stars(ignored if an external mod changed it)")
		gGlobalSyncTable.superstarsetting = 1
		return true
	elseif tonumber(m) and tonumber(m) >= 0 then
		gGlobalSyncTable.superstarreq = tonumber(m)
		gGlobalSyncTable.superstarsetting = 0
		djui_chat_message_create(string.format("super star requirement is now %d stars(ignored if an external mod changed it)",gGlobalSyncTable.superstarreq))
		return true
	else
		return false
    end
end

--- @param msg string
--this is the function for save server settings or loading them
sonichealthconfig_command = function(msg)
	local m = string.lower(msg)
    if m == 'save' then
		if usingcoopdx == 0 then
        	mod_storage_save("friendlyringloss", tostring(gGlobalSyncTable.friendlyringloss))
        	mod_storage_save("loseringsonlevelchange", tostring(gGlobalSyncTable.loseringsonlevelchange))
        	mod_storage_save("ringscrushinstadeath", tostring(gGlobalSyncTable.ringscrushinstadeath))
        	mod_storage_save("decreasecoincounter", tostring(gGlobalSyncTable.decreasecoincounter))
        	mod_storage_save("recoveryheartshield", tostring(gGlobalSyncTable.recoveryheartshield))
        	mod_storage_save("sonicfalldamage", tostring(gGlobalSyncTable.sonicfalldamage))
        	mod_storage_save("sonicsuperallow", tostring(gGlobalSyncTable.sonicsuperallow))
			mod_storage_save("maxringloss", tostring(gGlobalSyncTable.maxringloss))
        	mod_storage_save("maxrecollectablerings", tostring(gGlobalSyncTable.maxrecollectablerings))
			mod_storage_save("disablelavabounce", tostring(gGlobalSyncTable.disablelavabounce))
		else
			mod_storage_save_bool("friendlyringloss", gGlobalSyncTable.friendlyringloss)
        	mod_storage_save_bool("loseringsonlevelchange", gGlobalSyncTable.loseringsonlevelchange)
        	mod_storage_save_bool("ringscrushinstadeath", gGlobalSyncTable.ringscrushinstadeath)
        	mod_storage_save_bool("decreasecoincounter", gGlobalSyncTable.decreasecoincounter)
        	mod_storage_save_bool("recoveryheartshield", gGlobalSyncTable.recoveryheartshield)
        	mod_storage_save_bool("sonicfalldamage", gGlobalSyncTable.sonicfalldamage)
        	mod_storage_save_bool("sonicsuperallow", gGlobalSyncTable.sonicsuperallow)
			mod_storage_save_number("maxringloss", gGlobalSyncTable.maxringloss)
        	mod_storage_save_number("maxrecollectablerings", gGlobalSyncTable.maxrecollectablerings)
			mod_storage_save_bool("disablelavabounce", gGlobalSyncTable.disablelavabounce)
		end

        djui_chat_message_create('current sonichealth server config saved')
        return true
	elseif m == 'savesuperpreqpref'then
		djui_chat_message_create('saved super preference of needing 50 rings ')
		if gGlobalSyncTable.superstarsetting == 1 then
			if usingcoopdx == 0 then
				mod_storage_save("superstarsetting", tostring(gGlobalSyncTable.superstarsetting))
				mod_storage_save("superstarreq", tostring(gGlobalSyncTable.superstarreq))
			else
				mod_storage_save_number("superstarsetting", gGlobalSyncTable.superstarsetting)
				mod_storage_save_number("superstarreq", gGlobalSyncTable.superstarreq)
			end
			djui_chat_message_create('and 7 100 coin stars ')
		else
			if usingcoopdx == 0 then
				mod_storage_save("superstarsetting", tostring(gGlobalSyncTable.superstarsetting))
				mod_storage_save("superstarreq", tostring(gGlobalSyncTable.superstarreq))
			else
				mod_storage_save_number("superstarsetting", gGlobalSyncTable.superstarsetting)
				mod_storage_save_number("superstarreq", gGlobalSyncTable.superstarreq)
			end
			djui_chat_message_create(string.format("and %d stars",gGlobalSyncTable.superstarreq))
		end
		return true
	elseif m == 'load' then
		if not network_is_server() and not network_is_moderator then
            djui_chat_message_create('Only the host or a mod can change this setting!')
            return true
        else
			if usingcoopdx == 0 then
            	gGlobalSyncTable.friendlyringloss = toboolean( mod_storage_load("friendlyringloss"))
				gGlobalSyncTable.loseringsonlevelchange = toboolean( mod_storage_load("loseringsonlevelchange"))
            	gGlobalSyncTable.ringscrushinstadeath = toboolean( mod_storage_load("ringscrushinstadeath"))
            	gGlobalSyncTable.decreasecoincounter = toboolean( mod_storage_load("decreasecoincounter"))
            	gGlobalSyncTable.recoveryheartshield = toboolean( mod_storage_load("recoveryheartshield"))
            	gGlobalSyncTable.sonicfalldamage = toboolean( mod_storage_load("sonicfalldamage"))
            	gGlobalSyncTable.sonicsuperallow = toboolean( mod_storage_load("sonicsuperallow"))
				gGlobalSyncTable.maxringloss = tonumber(mod_storage_load("maxringloss"))
            	gGlobalSyncTable.maxrecollectablerings = tonumber(mod_storage_load("maxrecollectablerings"))
				gGlobalSyncTable.disablelavabounce = toboolean( mod_storage_load("disablelavabounce"))
			else
				gGlobalSyncTable.friendlyringloss = mod_storage_load_bool("friendlyringloss")
				gGlobalSyncTable.loseringsonlevelchange = mod_storage_load_bool("loseringsonlevelchange")
            	gGlobalSyncTable.ringscrushinstadeath = mod_storage_load_bool("ringscrushinstadeath")
            	gGlobalSyncTable.decreasecoincounter = mod_storage_load_bool("decreasecoincounter")
            	gGlobalSyncTable.recoveryheartshield = mod_storage_load_bool("recoveryheartshield")
            	gGlobalSyncTable.sonicfalldamage = mod_storage_load_bool("sonicfalldamage")
            	gGlobalSyncTable.sonicsuperallow = mod_storage_load_bool("sonicsuperallow")
				gGlobalSyncTable.maxringloss = mod_storage_load_number("maxringloss")
            	gGlobalSyncTable.maxrecollectablerings = mod_storage_load_number("maxrecollectablerings")
				gGlobalSyncTable.disablelavabounce = mod_storage_load_bool("disablelavabounce")
			end
            djui_chat_message_create('sonichealth server config loaded')
            return true
        end
	elseif m == 'loadsuperpreqpref' then
		if not network_is_server() and not network_is_moderator then
            djui_chat_message_create('Only the host or a mod can change this setting!')
            return true
        else
			if usingcoopdx == 0 then
				gGlobalSyncTable.superstarsetting = tonumber(mod_storage_load("superstarsetting"))
            	gGlobalSyncTable.superstarreq = tonumber(mod_storage_load("superstarreq"))
			else
				gGlobalSyncTable.superstarsetting = mod_storage_load_number("superstarsetting")
            	gGlobalSyncTable.superstarreq = mod_storage_load_number("superstarreq")
			end
			if gGlobalSyncTable.superstarsetting == 1 then 
				djui_chat_message_create("super star requirement is now 7 100 coin stars(ignored if an external mod changed it)")
			else
				djui_chat_message_create(string.format("super star requirement is now %d stars(ignored if an external mod changed it)",gGlobalSyncTable.superstarreq))
			end
            djui_chat_message_create('sonichealth server config loaded')
            return true
        end
	elseif m == 'printserver' then
		djui_chat_message_create(string.format("This server is using version %s of the sonic health mod with the following settings", version))
		djui_chat_message_create(string.format("friendlyringloss is %s",bool_to_str[gGlobalSyncTable.friendlyringloss]))
		if gGlobalSyncTable.maxringloss == 0 then
			djui_chat_message_create("all rings will be lost on hit")
		else
			djui_chat_message_create(string.format("max ring loss is %d",gGlobalSyncTable.maxringloss))
		end
		djui_chat_message_create(string.format("lose rings on level change is %s",bool_to_str[gGlobalSyncTable.loseringsonlevelchange]))
		djui_chat_message_create(string.format("crushing instadeath is %s",bool_to_str[gGlobalSyncTable.ringscrushinstadeath]))
		djui_chat_message_create(string.format("fall damage is %s",bool_to_str[gGlobalSyncTable.sonicfalldamage]))
		djui_chat_message_create(string.format("max recollectable rings is %d",gGlobalSyncTable.maxrecollectablerings))
		djui_chat_message_create(string.format("decrease coin counter on hit is %s",bool_to_str[gGlobalSyncTable.decreasecoincounter]))
		djui_chat_message_create(string.format("recovery heart shield is %s",bool_to_str[gGlobalSyncTable.recoveryheartshield]))
		djui_chat_message_create(string.format("super forms are %s",bool_to_str[gGlobalSyncTable.sonicsuperallow]))
		djui_chat_message_create(string.format("disablelavabounce is %s",bool_to_str[gGlobalSyncTable.disablelavabounce]))
		return true
	elseif m == 'printlocal'then
		djui_chat_message_create(string.format("ring ui x pos is %d",ringui_x))
		djui_chat_message_create(string.format("ring ui y pos is %d",ringui_y))
		djui_chat_message_create(string.format("sonichealth superbutton1 is %s", buttons[superbutton1].name))
        djui_chat_message_create(string.format("sonichealth superbutton2 is %s", buttons[superbutton2].name))
		return true
	else
		return false
    end
end

--- @param msg string
--this is the function for changing the super button
sonichealthsuperbutton_command = function(msg)
    local m = string.lower(msg)
    if m == 'reset' then
        djui_chat_message_create('sonichealth super button was set to default')
        superbutton1 = X_BUTTON
        superbutton2 = X_BUTTON
        djui_chat_message_create(string.format("sonichealth superbutton1 is %s", buttons[superbutton1].name))
        djui_chat_message_create(string.format("sonichealth superbutton2 is %s", buttons[superbutton2].name))
        return true
    elseif m == 'change' then
        settingsuperbutton = true
        set2ndsuperbutton = false
        return true
	else
		return false
    end
end

--- @param msg string
--this function toggles the ability to lava bounce
disablelavabounce_command = function(msg)
    if not network_is_server() then
        djui_chat_message_create('Only the host can change this setting!')
        return true
    end
	local m = string.lower(msg)
    if m == 'on' then
        djui_chat_message_create('Lava bouncing is \\#00C7FF\\disabled\\#ffffff\\!')
		gGlobalSyncTable.disablelavabounce = true
        return true
	elseif m == 'off' then
		djui_chat_message_create('lava bouncing is \\#A02200\\enabled\\#ffffff\\!')
		gGlobalSyncTable.disablelavabounce = false
		return true
	else
		return false
    end
end


hook_event(HOOK_ON_LEVEL_INIT, ringInitialize) --hook for setting coins to 0 on level change
hook_event(HOOK_ON_INTERACT, sonicCoinGet) --hook for interacting with coins
hook_event(HOOK_ON_HUD_RENDER, ringDisplay) -- hook for displaying ring count
hook_event(HOOK_MARIO_UPDATE, mario_update_end)
hook_event(HOOK_ON_PVP_ATTACK, sonicPvpHurt) --hook for pvp attacks
hook_event(HOOK_ON_DEATH, mario_death) -- hook for mario dying 
hook_event(HOOK_ON_PLAYER_CONNECTED, on_player_connected) -- hook for player joining
hook_event(HOOK_BEFORE_SET_MARIO_ACTION, before_set_mario_action) --hook which is called before every time a player's current action is changed.Return an action to change the incoming action or 1 to cancel the action change.
hook_event(HOOK_UPDATE,health_hook_update) -- hook that is called once per frame	
hook_event(HOOK_ON_SET_MARIO_ACTION,on_set_mario) -- hook that is called every time a player's current action is changed
hook_event(HOOK_JOINED_GAME, on_join) -- Called when the local player finishes the join process (if the player isn't the host)
hook_event(HOOK_ALLOW_HAZARD_SURFACE, allow_hazard_surface) --Called once per player per frame. Return false to prevent the player from being affected by lava or quicksand.
hook_event(HOOK_BEFORE_MARIO_UPDATE, before_mario_update) --Called once per player per frame at the beginning of a mario update


id_bhvCoinring = hook_behavior(nil, OBJ_LIST_LEVEL, true, bhv_coinring_init, bhv_coinring_loop)--The behavior for sonic health's rings
hook_behavior(id_bhvRecoveryHeart, OBJ_LIST_LEVEL, false, nil, bhv_sonicshield_heart_loop)
id_bhvbowserbossdeathconfirm = hook_behavior(nil, OBJ_LIST_LEVEL, true, bhv_sonichealthbowserdeathconfirm_init, bhv_sonichealthbowserdeathconfirm_loop) --the function for the object that is used for making sure bowser dies when he is set to 0 or less health by a kirby move or projectile


hook_chat_command('maxringloss', "maxringloss [number] this sets the max number of rings you can lose at once set it to 0 to always lose all rings.", maxringloss_command)
hook_chat_command('sonichealthconfig', "[save|load|savesuperpreqpref|loadsuperpreqpref|printserver|printlocal] to save the current sonic health settings to a file or load them (loading only works if used by a moderator or the server)", sonichealthconfig_command)
hook_chat_command('sonichealthsuperbutton', "[reset|change] set the button/buttons to turn super, reset sets it back to default(default x) and change allows you to change it ", sonichealthsuperbutton_command)
hook_chat_command('disablelavabounce', "[on|off] turn disablelavabounce \\#00C7FF\\on \\#ffffff\\or \\#A02200\\off \\#ffffff\\to choose if you want to lava bounce on lava.", disablelavabounce_command)
hook_chat_command('friendlyringloss', "[on|off] turn friendlyringloss \\#00C7FF\\on \\#ffffff\\or \\#A02200\\off \\#ffffff\\to choose if you want to lose rings due to other players hitting you.", friendlyringloss_command)
hook_chat_command('loseringsonlevelchange', "[on|off] turn loseringsonlevelchange \\#00C7FF\\on \\#ffffff\\or \\#A02200\\off \\#ffffff\\to choose if you want to keep your rings between levels.", loseringsonlevelchange_command)
hook_chat_command('ringscrushinstadeath', "[on|off] turn ringscrushinstadeath \\#00C7FF\\on \\#ffffff\\or \\#A02200\\off \\#ffffff\\to choose if you want being crushed to be instadeath.", ringscrushinstadeath_command)
hook_chat_command('decreasecoincounter', "[on|off] turn decreasecoincounter on or off to choose whether to decrease the coin counter on hit and rings equal 1 coin or have the coin counter not decease on hit and rings only affect ring counter", decreasecoincounter_command)
hook_chat_command('recoveryheartshield', "[on|off] turn recoveryheartshield \\#00C7FF\\on \\#ffffff\\or \\#A02200\\ off \\#ffffff\\ to choose whether recovery hearts should give an overshield on touch.", recoveryheartshield_command)
hook_chat_command('sonicfalldamage', "[on|off] turn sonicfalldamage on or off to choose whether you can take fall damage", sonicfalldamage_command)
hook_chat_command('maxrecollectablerings', "maxrecollectablerings [number] this sets the maximum amount of rings you can get back per hit", maxrecollectablerings_command)
hook_chat_command('ringui_x', "ringui_x [number|dpad|toggleui] this sets the x position of the ring counter should be a value  between 0 and 320, ringui_x \\#A02200\\dpad\\#ffffff\\ for moving the ui with dpad,or ringui_x toggleui to toggle the ui", ringui_x_command)
hook_chat_command('ringui_y', "ringui_y [number|dpad|toggleui] this sets the y position of the ring counter should be a value between 0 and  -240, ringui_y \\#A02200\\dpad\\#ffffff\\ for moving the ui with dpad,or ringui_y toggleui to toggle the ui", ringui_y_command)
hook_chat_command('sonicsuper', "[on|off|prereq|7coinstar|number] toggle the ability to go super with 50+ rings + requirement, get the requirement by typing prereq ,change prereq by entering number of stars needed or entering 7coinstar to make super require 7 100 coin stars.", sonicsuper_command)


--sonic health mod api functions
_G.sonichealth = {

	customsupercheck = function(...)--function to allow other mod to pass its own super prereq check
		local arg  = table.pack(...)
		if (type(arg[1]) == "function") then
			superformfunction = arg[1]
		else
			if usingcoopdx > 0 then
                log_to_console(string.format("arg[1] that was passed to _G.sonichealth.customsupercheck wasn't a function this occured on sonic health version %s",version), 1)
            else
                log_to_console(string.format("arg[1] that was passed to _G.sonichealth.customsupercheck wasn't a function this occured on sonic health version %s",version))
            end
		end
	end,
	supermoveset = function(...)--function to store super toggles for other mods with the functions having false for off and true for on
		local arg  = table.pack(...)
		if (arg[1] ~= nil) and (type(arg[1]) == "function") then
			supermovesetfunctions[superformfunctiontablelength] = (arg[1])
			superformfunctiontablelength = superformfunctiontablelength + 1
		else
			if usingcoopdx > 0 then
                log_to_console(string.format("arg[1] that was passed to _G.sonichealth.supermoveset wasn't a function this occured on sonic health version %s",version), 1)
            else
                log_to_console(string.format("arg[1] that was passed to _G.sonichealth.supermoveset wasn't a function this occured on sonic health version %s",version))
            end
		end
	end,
	--this function allows other mods to check ringcount
	getringcount = function()
		return ringcount
	end,
	--this function allows other mods to check the player's shield
	getshield = function(...)
		local arg  = table.pack(...)
		local shieldtypename --a string containing the name of the current shield
		local playerindex --the player index of the player to check their shield 
		if (arg.n >= 3) and (type(arg[3]) == "number") and (arg[3] >= 0) and (arg[3] < MAX_PLAYERS) then
			playerindex = arg[3]
		else
			playerindex = 0
		end
		if (arg[1] ~= nil) and (type(arg[1]) == "string") then
			if arg[1] == "shieldhits" then
				return gPlayerSyncTable[playerindex].shieldhits
			elseif arg[1] == "shieldtype" then
				for key,value in pairs(shieldtypetable)do
					if value == gPlayerSyncTable[playerindex].shieldtype then
						shieldtypename = key
					end
				end
				return shieldtypename
			elseif arg[1] == "shieldtypeandhits" then
				for key,value in pairs(shieldtypetable)do
					if value == gPlayerSyncTable[playerindex].shieldtype then
						shieldtypename = key
					end
				end
				return gPlayerSyncTable[playerindex].shieldhits,shieldtypename
			else
				if usingcoopdx > 0 then
					log_to_console(string.format("arg[1] that was passed to _G.sonichealth.getshield was an invalid input this occured on sonic health version %s",version), 1)
				else
					log_to_console(string.format("arg[1] that was passed to _G.sonichealth.getshield was an invalid input this occured on sonic health version %s",version))
				end
			end
		else
			if usingcoopdx > 0 then
                log_to_console(string.format("arg[1] that was passed to _G.sonichealth.getshield wasn't a string this occured on sonic health version %s",version), 1)
            else
                log_to_console(string.format("arg[1] that was passed to _G.sonichealth.getshield wasn't a string this occured on sonic health version %s",version))
            end
		end
		return ringcount
	end,
	--this function allows other mods to give/take away a shield
	giveshield = function(...)
		local arg  = table.pack(...)
		local playerindex --the player index of the player receiving the shield
		if (arg.n >= 3) and (type(arg[3]) == "number") and (arg[3] >= 0) and (arg[3] < MAX_PLAYERS) then
			playerindex = arg[3]
		else
			playerindex = 0
		end
		if (arg[1] ~= nil) and (type(arg[1]) == "number") then
			if arg[1] <= 0 then
				gPlayerSyncTable[playerindex].shieldhits = 0
				gPlayerSyncTable[playerindex].shieldtype = 0
			else
				gPlayerSyncTable[playerindex].shieldhits = math.floor(arg[1])
			end
			if (arg[2] ~= nil) and (type(arg[2]) == "string") then
				if shieldtypetable[arg[2]] ~= nil then
					gPlayerSyncTable[playerindex].shieldtype = shieldtypetable[arg[2]]
				else
					gPlayerSyncTable[playerindex].shieldtype = 0
					if usingcoopdx > 0 then
						log_to_console(string.format("arg[2] that was passed to _G.sonichealth.giveshield was an invalid input setting to default shield. this occured on sonic health version %s",version), 1)
					else
						log_to_console(string.format("arg[2] that was passed to _G.sonichealth.giveshield was an invalid input setting to default shield. this occured on sonic health version %s",version))
					end
				end
			else
				gPlayerSyncTable[playerindex].shieldtype = 0
			end
		else
			if usingcoopdx > 0 then
                log_to_console(string.format("arg[1] that was passed to _G.sonichealth.getshield wasn't a number this occured on sonic health version %s",version), 1)
            else
                log_to_console(string.format("arg[1] that was passed to _G.sonichealth.getshield wasn't a number this occured on sonic health version %s",version))
            end
		end
	end,
	--- @param n number
	--this function allows other mods to modify ringcount
	increaseringcount = function(n)
		ringcount = n + ringcount
		if ringcount < 0 then
			ringcount = 0
		end
	end,
		--this function allows other mods to interact with super forms deprecated
	addsuperenemyfunction = function(...)
			if usingcoopdx > 0 then
                log_to_console(string.format("the function _G.sonichealth.addsuperenemyfunction was deprecated  use _G.sonichealth.addcustomenemyfunction instead. this occured on sonic health version %s",version), 1)
            else
                log_to_console(string.format("the function _G.sonichealth.addsuperenemyfunction was deprecated  use _G.sonichealth.addcustomenemyfunction instead. this occured on sonic health version %s",version))
            end
            return
	
	end,
	--this function allows other mods to have custom interactions
	addcustomenemyfunction = function(...)
		local arg  = table.pack(...)
		local customfunction
		local bhvid --the behavior id of an object
		if arg.n < 2 then
			if usingcoopdx > 0 then
                log_to_console(string.format("too few arguments where passed to _G.sonichealth.addcustomenemyfunction this occured on sonic health version %s",version), 1)
            else
                log_to_console(string.format("too few arguments where passed to _G.sonichealth.addcustomenemyfunction this occured on sonic health version %s",version))
            end
            return
		end
		if (type(arg[1]) == "function") then
			customfunction = arg[1]
		elseif (type(arg[1]) == "string") then
			bhvid = arg[2]
			customenemyfunctions[bhvid] = customfunction
			return
		else 
			if usingcoopdx > 0 then
                log_to_console(string.format("arg[1] that was passed to _G.sonichealth.addcustomenemyfunction wasn't a function this occured on sonic health version %s",version), 1)
            else
                log_to_console(string.format("arg[1] that was passed to _G.sonichealth.addcustomenemyfunction wasn't a function this occured on sonic health version %s",version))
            end
			return
		end
		bhvid = arg[2]

		customenemyfunctions[bhvid] = customfunction
		if arg[3] ~= nil and arg[3] == "nointeract" then
			nointeracttable[bhvid] = customfunction
		elseif arg[3] ~= nil then
			if usingcoopdx > 0 then
                log_to_console(string.format("arg[3] that was passed to _G.sonichealth.addcustomenemyfunction was an invalid input this occured on sonic health version %s",version), 1)
            else
                log_to_console(string.format("arg[3] that was passed to _G.sonichealth.addcustomenemyfunction was an invalid input this occured on sonic health version %s",version))
            end
		end
	end,
	--- @param func function function to check if a player being attacked is on the same team as the person attacking them
    --function for other mods to add a team check for gamemodes 
    addallycheck = function(func)
        allycheck = func --expects the function to have parameters customfunc(attacker,victim) param victim mariostate of the player being attacked and param attacker mariostate of the player attacking and the function should return 1 (when the hit player is an ally and you don't want the player to affect their ally),return 2 (when the hit player is an ally and you want the interaction to happen without ring loss), and return 0 otherwise(which cause the hit player to lose rings on hit).
    end,
	---@param name string 
    get_serversetting = function(name) -- function that returns the value of a gGlobalSyncTable variable or variables used by sonichealth mod
        local sonichealthsettingtable = {["friendlyringloss"] = gGlobalSyncTable.friendlyringloss,["maxringloss"] = gGlobalSyncTable.maxringloss,["maxrecollectablerings"] = gGlobalSyncTable.maxrecollectablerings,["loseringsonlevelchange"] = gGlobalSyncTable.loseringsonlevelchange,["ringscrushinstadeath"] = gGlobalSyncTable.ringscrushinstadeath,["decreasecoincounter"] = gGlobalSyncTable.decreasecoincounter,["recoveryheartshield"] = gGlobalSyncTable.recoveryheartshield,["sonicfalldamage"] = gGlobalSyncTable.sonicfalldamage,["sonicsuperallow"] = gGlobalSyncTable.sonicsuperallow,["superstarreq"] = gGlobalSyncTable.superstarreq,["superstarsetting"] = gGlobalSyncTable.superstarsetting}--table containg the values of the sonic health server settings

		if name == "table" then --return a table containing all sonic health server settings
            return sonichealthsettingtable
        elseif sonichealthsettingtable[name] ~= nil then
            return sonichealthsettingtable[name]
        else
            if usingcoopdx > 0 then
                log_to_console(string.format("sonic health setting not found either sonic health mod may be out of date or another mod may be out of date current sonic health version is %s",version), 1)
            else
                log_to_console(string.format("sonic health setting not found either sonic health mod may be out of date or another mod may be out of date current sonic health version is %s",version))
            end
            return
        end
    end,
	isplayersuper = function(...)--this function returns whether a player is super
		local arg  = table.pack(...)
		local playerindex --the local player index of the player to check
		if arg.n == 0 then
			playerindex = 0
			return gPlayerSyncTable[playerindex].issuper
		elseif (type(arg[1]) == "number") and (arg[1] >= 0) and (arg[1] < MAX_PLAYERS) then
			playerindex = arg[1]
			return gPlayerSyncTable[playerindex].issuper
		else
			if usingcoopdx > 0 then
				log_to_console(string.format("arg[1] that was passed to _G.sonichealth.isplayersuper was an invalid input this occured on sonic health version %s",version), 1)
			else
				log_to_console(string.format("arg[1] that was passed to _G.sonichealth.isplayersuper was an invalid input this occured on sonic health version %s",version))
			end
			return
		end
	
		
	end,
	getversion = function()--this function returns the sonic health version
		return version
	end
}

modsupporthelperfunctions.sonichealth = _G.sonichealth

if usingcoopdx == 3 then
    hook_event(HOOK_ON_MODS_LOADED, modsupport) --Called directly after every mod file is loaded in by smlua
    servermodsync = true
else
	

end

--below are some examples of using the mod api in another mod
--[[ 
local servermodsync = false
local super = false

---@param bool boolean
--this function is an example for a super form toggle for sonic health mod 
function kirbysuper(bool)
    local str
    if bool == false then
        str = 'kirby stopped being super'
    else
        str = 'kirby went super'
    end
    if gPlayerSyncTable[0].kirby == true then
        djui_chat_message_create(str)
    end
	super = bool
end

--this function is an example of setting a prereq for super form through an external mod
function kirbypreq(...)
    local arg  = table.pack(...)
    if arg.n == 0 then
        if gMarioStates[0].numStars == 120 then
            return true
        else
            djui_chat_message_create("you need 120 stars")
            return false
        end
    elseif arg.n == 1 and (type(arg[1]) == "string") then
        djui_chat_message_create("you need 120 stars")
    end
end

--- @param m MarioState
--Called when a player connects
local function on_player_connected(m)
    -- only run on server
    if not network_is_server() then
        return
	end
    if servermodsync == false then
        if _G.sonichealth ~= nil then
            _G.sonichealth.supermoveset(kirbysuper)
            _G.sonichealth.customsupercheck(kirbypreq)
        end 
        servermodsync = true
    end
end

--Called when the local player finishes the join process (if the player isn't the host)
local function on_join()
    if _G.sonichealth ~= nil then
        _G.sonichealth.supermoveset(kirbysuper)
    end 
end

hook_event(HOOK_JOINED_GAME, on_join) -- Called when the local player finishes the join process (if the player isn't the host)
hook_event(HOOK_ON_PLAYER_CONNECTED, on_player_connected) -- hook for player joining

 ]]

