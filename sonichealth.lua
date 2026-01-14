-- name: .Sonic Health
-- description: Makes you lose coins on hit if you have no coins on hit you die \nCreated by wereyoshi. \n\nExtra coding by \\#00ffff\\steven.

local ringcount = 0
gGlobalSyncTable.friendlyringloss = false --whether other players can cause you to lose rings
gGlobalSyncTable.maxringloss = 0 --maximum amount of rings you are allowed to lose at once if its equal to 0 you lose all rings at once
gGlobalSyncTable.maxrecollectablerings = 999 --maximum amount of rings you can get back per hit
gGlobalSyncTable.loseringsonlevelchange = true --whether to lose rings on level change
gPlayerSyncTable[0].losingrings = 0 --rings to deduct from the coin counter for a player
gGlobalSyncTable.ringscrushinstadeath = true --whether to instantly die when crushed
gGlobalSyncTable.decreasecoincounter = true --whether to decrease the coin counter on hit and have coins spawned on hit equal 1 coin or have the coin counter not decease on hit and have coins spawned only count for the ring counter
gPlayerSyncTable[0].shieldhits = 0  --current number of hits remaining for current shield
gGlobalSyncTable.recoveryheartshield = true --whether recovery hearts should give an overshield on touch
gGlobalSyncTable.sonicfalldamage = false --toggles fall damage
gGlobalSyncTable.sonicsuperallow = false --toggles super forms
gPlayerSyncTable[0].issuper = false  --if the current player is super
gGlobalSyncTable.superstarreq = 50 --min number of stars for super
gGlobalSyncTable.superstarsetting = 0 --which config to use for super 0 for x stars for super and 1 for 7 100 coin stars for super
local timer = 0
local superformfunction = nil

local supermovesetfunctions = {}--functions that tell other movesets that you are super
local superformfunctiontablelength = 0
local bool_to_str = {[false] = "\\#A02200\\off\\#ffffff\\",[true] = "\\#00C7FF\\on\\#ffffff\\"} --table for converting boolean into string
local superenemyfunctions = {}--table of functions from other mods for unique super interactions with objects with each key being a behaviorid
local version = "2.1.0"
local settingsuperbutton = false

local set2ndsuperbutton = false

local buttons = {
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

local function toboolean(s)
    if s == "false" then
        return false
    else
        return true
    end
end

if mod_storage_load("ringcount_ui_x") == nil or mod_storage_load("ringcount_ui_y") == nil then
	mod_storage_save("ringcount_ui_x", "0")
	mod_storage_save("ringcount_ui_y", "0")
end

if (mod_storage_load("superbutton1") == nil) or (mod_storage_load("superbutton2") == nil) then
    mod_storage_save("superbutton1", tostring(X_BUTTON))
    mod_storage_save("superbutton2", tostring(X_BUTTON))
end

local ringui_x = tonumber(mod_storage_load("ringcount_ui_x"))
local ringui_y = tonumber(mod_storage_load("ringcount_ui_y"))
local superbutton1 = tonumber(mod_storage_load("superbutton1"))
local superbutton2 = tonumber(mod_storage_load("superbutton2"))

if network_is_server() then
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

end

--- @param o Object
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

function bhv_coinring_loop(obj)
	bhv_yellow_coin_loop()
	bhv_moving_yellow_coin_loop()
	cur_obj_update_floor_and_walls()
	if obj.oFloorHeight ==  obj.oPosY then
		obj.oVelY = 40
	end
	
end


function bhv_sonicshield_heart_loop(obj)
	if (gMarioStates[0].playerIndex ~= 0) or gGlobalSyncTable.recoveryheartshield == false  then
		return
	elseif (nearest_interacting_mario_state_to_object(obj)).playerIndex == 0 and is_within_100_units_of_mario(obj.oPosX, obj.oPosY, obj.oPosZ) == 1 then
		gPlayerSyncTable[0].shieldhits = 1
		djui_chat_message_create('You got a 1-hit shield.')
	end
end

--determines what happens on level start
local function ringInitialize()

	if (gGlobalSyncTable.loseringsonlevelchange == true)  then
		ringcount = 0
	end
end

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
				spawn_sync_object(id_bhvCoinring,E_MODEL_YELLOW_COIN,m.pos.x , m.pos.y + 161, m.pos.z,ring_randomization)
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
			spawn_sync_object(id_bhvCoinring,E_MODEL_YELLOW_COIN,m.pos.x, m.pos.y + 161, m.pos.z,ring_randomization)
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
	elseif (gGlobalSyncTable.friendlyringloss == false)  or ((victim.flags & MARIO_METAL_CAP) ~= 0) then
		victim.hurtCounter = 0
	else
		victim.invincTimer = 0
		spawn_coin(victim)
	end

end


---@param m MarioState 
---@param o Object
--sets what happens when a character picks up a coin
local function sonicCoinGet(m, o,interactType)
	if (m.playerIndex ~= 0) then
		return
    elseif (m.playerIndex == 0) then
		if interactType == INTERACT_COIN and (o.oDamageOrCoinValue == 1 or (get_id_from_behavior(o.behavior) == id_bhvCoinring) )  then --checking that a yellow coin was interacted with
			ringcount = ringcount + 1
			m.healCounter = 0
		elseif interactType == INTERACT_COIN and o.oDamageOrCoinValue == 2 then --checking that a red coin was interacted with
			ringcount = ringcount + 2
			m.healCounter = 0
		elseif interactType == INTERACT_COIN and o.oDamageOrCoinValue == 5  then--checking that a blue coin was interacted with
			ringcount = ringcount + 5
			m.healCounter = 0
		end
    end
end

--sets up a clientside ring counter
local function ringDisplay()
	
    djui_hud_set_font(FONT_HUD)
    djui_hud_set_resolution(RESOLUTION_N64)

    local scale = 1
	local superbutton1name

    local superbutton2name

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
        djui_hud_print_text(string.format("superbutton combo %s +%s",superbutton1name, superbutton2name), 0, -ringui_y, scale)
		if ringui_y > -120 then
            djui_hud_print_text("pick button using dpad, a to save, b to cancel", 0, 220, 0.8)
        else
            djui_hud_print_text("pick button using dpad, a to save, b to cancel", 0, 0, 0.8)
        end
	else
    	djui_hud_print_text(string.format("rings %d", ringcount), ringui_x, -ringui_y, scale)
	end
end

---@param m MarioState
--Called once per player per frame before physics code is run
local function before_phys_step(m)
    if (m.playerIndex ~= 0) then
		return
	elseif ((m.flags & MARIO_METAL_CAP) ~= 0) or (m.invincTimer ~= 0)  then
		m.hurtCounter = 0
		return
	elseif (m.floor.type == SURFACE_BURNING and (m.pos.y == m.floorHeight) and (m.action ~= ACT_SLIDE_KICK))  then --checking if mario is standing on lava
		spawn_coin(m)
		return
	elseif  m.wall ~= nil and m.wall.type == SURFACE_BURNING  then --checking if mario is touching a lava wall
		spawn_coin(m)
		return
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

local function health_hook_update()

	if gPlayerSyncTable[0].issuper == true then
		timer = timer + 1
		if (gGlobalSyncTable.sonicsuperallow == false) then
			supertoggle(false)
		elseif (timer % 30) == 0 then
			ringcount = ringcount - 1
			if ringcount <= 0 then
				supertoggle(false)
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
                mod_storage_save("superbutton1", tostring(superbutton1))
                mod_storage_save("superbutton2", tostring(superbutton2))
                djui_chat_message_create('sonichealth super button combo  saved to mod storage')
            end
        elseif (gMarioStates[0].controller.buttonPressed == B_BUTTON) then
            settingsuperbutton = false
            superbutton1 = tonumber(mod_storage_load("superbutton1"))
            superbutton2 = tonumber(mod_storage_load("superbutton2"))
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

--- @param m MarioState
--Called when a player connects
function on_player_connected(m)
    -- only run on server
    if not network_is_server() then
        return
	end
	for i=0,(MAX_PLAYERS-1) do
		if gPlayerSyncTable[i].losingrings == nil then
			gPlayerSyncTable[i].losingrings = 0
			gPlayerSyncTable[i].shieldhits = 0
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
	
	if (incomingAction == ACT_HARD_BACKWARD_GROUND_KB or incomingAction == ACT_HARD_FORWARD_GROUND_KB or incomingAction == ACT_BACKWARD_GROUND_KB or incomingAction == ACT_FORWARD_GROUND_KB) and m.vel.y < 0  then
		if  m.hurtCounter > 0 and m.invincTimer <= 0 then
			spawn_coin(m)
		end
		return ACT_IDLE
	elseif incomingAction == ACT_BURNING_GROUND and m.pos.y == m.floorHeight and m.floor.type ~= SURFACE_BURNING then
		spawn_coin(m)
		return ACT_IDLE
	elseif incomingAction == ACT_BURNING_FALL then
		spawn_coin(m)
		return ACT_BACKWARD_AIR_KB
	elseif  m.hurtCounter > 0 or (incomingAction == ACT_BURNING_GROUND and (m.wall == nil or ( m.wall ~= nil and m.wall.type ~= SURFACE_BURNING)) and (m.floor.type ~= SURFACE_BURNING and m.pos.y == m.floorHeight) ) then
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
---@param o Object
---@param interactType InteractionType
--this function is for allowing mario to interact with objects.
local function allow_interact(m,o,interactType)
	local superimmunetable = {[INTERACT_DAMAGE] = true,[INTERACT_SHOCK] = true, [INTERACT_FLAME] = true , [INTERACT_SNUFIT_BULLET] = true ,[INTERACT_UNKNOWN_08] = true, [INTERACT_MR_BLIZZARD] = true, [INTERACT_CLAM_OR_BUBBA] = true}
	if m.playerIndex ~= 0 then
        return
    end
	local x = get_id_from_behavior(o.behavior)
	if  gPlayerSyncTable[0].issuper == true  then
		if superenemyfunctions[x] ~= nil then
			local customfunc = superenemyfunctions[x]
			if customfunc ~= nil then
                return customfunc(o)--whether the object can interact with super form return true to allow false otherwise
            end
		elseif superimmunetable[interactType] then
			o.oInteractStatus = ATTACK_KICK_OR_TRIP | INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED
			return false
		elseif (interactType == INTERACT_BOUNCE_TOP) or(interactType == INTERACT_BOUNCE_TOP2) or(interactType == INTERACT_HIT_FROM_BELOW) or (interactType == INTERACT_KOOPA and o.oKoopaMovementType < KOOPA_BP_KOOPA_THE_QUICK_BASE) then
			if (m.pos.y > o.oPosY) and (m.action & ACT_FLAG_AIR ~= 0) then
				return true
			else
				o.oInteractStatus =  ATTACK_GROUND_POUND_OR_TWIRL | INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED
				
				return false
			end
		elseif interactType == INTERACT_BULLY then
			o.oInteractStatus = ATTACK_KICK_OR_TRIP | INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED
			o.oAction = BULLY_ACT_KNOCKBACK
			o.oFlags = o.oFlags & ~0x8
			o.oMoveAngleYaw = m.faceAngle.y
			o.oForwardVel = 3392 / o.hitboxRadius
			o.oBullyMarioCollisionAngle = o.oMoveAngleYaw
			o.oBullyLastNetworkPlayerIndex = gNetworkPlayers[0].globalIndex
			m.interactObj = o
			return false
		elseif x == id_bhvChuckya then
			o.oAction = 2
            o.oMoveFlags = o.oMoveFlags & OBJ_MOVE_LANDED
			return false
		elseif x == id_bhvKingBobomb then
			if (o.oAction ~= 0 and o.oAction ~= 4 and o.oAction ~= 5 and o.oAction ~= 6 and o.oAction ~= 7 and o.oAction ~= 8) then
				o.oPosY = o.oPosY + 20
                o.oVelY = 50
                o.oForwardVel = 20
                o.oAction = 4
			end
			return false
		elseif x == id_bhvBowser then
			if (o.oAction ~= 0 and o.oAction ~= 4 and o.oAction ~= 5 and o.oAction ~= 6 and o.oAction ~= 12 and o.oAction ~= 20 ) then
				o.oHealth = o.oHealth - 1
                    if o.oHealth  <= 0 then
                        o.oMoveAngleYaw = o.oBowserAngleToCentre + 0x8000
                        o.oAction = 4
                    else
                        o.oAction = 12
                    end
			end
			return false
		end
		
	end
end

--- @param msg string
--this function toggles ring loss by pvp
local function friendlyringloss_command(msg)
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
    end
    return false
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
    return false
end

--- @param msg string
--this function toggles whether to lose rings on level change
local function loseringsonlevelchange_command(msg)
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
    end
    return false
end

--- @param msg string
--this function toggles being crushed being an instadeath
local function ringscrushinstadeath_command(msg)
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
    end
    return false
end

--- @param msg string
--this function toggles whether to decrease the coin counter on hit
local function decreasecoincounter_command(msg)
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
    end
    return false
end

--- @param msg string
--this function toggles recovery heart shield
local function recoveryheartshield_command(msg)
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
    end
    return false
end

--- @param msg string
--this function toggles fall damage
local function sonicfalldamage_command(msg)
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
    end
    return false
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
    return false
end

--- @param msg string
--this is the function sets the ring counts y position
local function ringui_x_command(msg)
    
    if tonumber(msg) and (tonumber(msg) >= 0) then
		mod_storage_save("ringcount_ui_x", msg)
		ringui_x = tonumber(mod_storage_load("ringcount_ui_x"))
        djui_chat_message_create(string.format("ringcount ui's x coordinate is now %d", ringui_x))
        return true
	else 
		djui_chat_message_create('Invalid input. Must be a number like ringui_x 5 and the number needs to be 0 or greater.')
		return true
    end
    return false
end

--- @param msg string
--this is the function sets the ring counts y position
local function ringui_y_command(msg)
    
	
    if tonumber(msg) and (tonumber(msg) <= 0) then
		mod_storage_save("ringcount_ui_y", msg)
		ringui_y = tonumber(mod_storage_load("ringcount_ui_y"))
        djui_chat_message_create(string.format("ringcount ui's y coordinate is now %d", ringui_y))
        return true
	else 
		djui_chat_message_create('Invalid input. Must be a number like ringui_y -5 and the number needs to be 0 or greater.')
		return true
    end
    return false
end

--- @param msg string
--this is the function toggles super forms
local function sonicsuper_command(msg)
	local m = string.lower(msg)
	if m == 'prereq' then
		djui_chat_message_create('you need 50 rings')
		if superformfunction == nil then
			if gGlobalSyncTable.superstarsetting == 0 then
				djui_chat_message_create(string.format("and %d stars",gGlobalSyncTable.superstarreq))
			elseif gGlobalSyncTable.superstarsetting == 1 then
				djui_chat_message_create('and 7 100 coin stars')
			end
		elseif superformfunction() ~= nil then
			superformfunction(m)
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
    end
    return false
end

--- @param msg string
--this is the function for save server settings or loading them
local function sonichealthconfig_command(msg)
	local m = string.lower(msg)
    if m == 'save' then
        mod_storage_save("friendlyringloss", tostring(gGlobalSyncTable.friendlyringloss))
        mod_storage_save("loseringsonlevelchange", tostring(gGlobalSyncTable.loseringsonlevelchange))
        mod_storage_save("ringscrushinstadeath", tostring(gGlobalSyncTable.ringscrushinstadeath))
        mod_storage_save("decreasecoincounter", tostring(gGlobalSyncTable.decreasecoincounter))
        mod_storage_save("recoveryheartshield", tostring(gGlobalSyncTable.recoveryheartshield))
        mod_storage_save("sonicfalldamage", tostring(gGlobalSyncTable.sonicfalldamage))
        mod_storage_save("sonicsuperallow", tostring(gGlobalSyncTable.sonicsuperallow))
		mod_storage_save("maxringloss", tostring(gGlobalSyncTable.maxringloss))
        mod_storage_save("maxrecollectablerings", tostring(gGlobalSyncTable.maxrecollectablerings))
		
        djui_chat_message_create('current sonichealth server config saved')
        return true
	elseif m == 'load' then
		if not network_is_server() and not network_is_moderator then
            djui_chat_message_create('Only the host or a mod can change this setting!')
            return true
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
            djui_chat_message_create('sonichealth server config loaded')
            return true
        end
	elseif m == 'printserver' then
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
		return true
	elseif m == 'printlocal'then
		djui_chat_message_create(string.format("ring ui x pos is %d",ringui_x))
		djui_chat_message_create(string.format("ring ui y pos is %d",ringui_y))
		djui_chat_message_create(string.format("sonichealth superbutton1 is %s", buttons[superbutton1].name))
        djui_chat_message_create(string.format("sonichealth superbutton2 is %s", buttons[superbutton2].name))
		return true
    end
    return false
end

--- @param msg string
--this is the function for changing the super button
local function sonichealthsuperbutton_command(msg)
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
    end
    return false
end

hook_event(HOOK_ON_LEVEL_INIT, ringInitialize) --hook for setting coins to 0 on level change
hook_event(HOOK_ON_INTERACT, sonicCoinGet) --hook for interacting with coins
hook_event(HOOK_ON_HUD_RENDER, ringDisplay) -- hook for displaying ring count
hook_event(HOOK_MARIO_UPDATE, mario_update_end)
hook_event(HOOK_ON_PVP_ATTACK, sonicPvpHurt) --hook for pvp attacks
hook_event(HOOK_ON_DEATH, mario_death) -- hook for mario dying 
hook_event(HOOK_ON_PLAYER_CONNECTED, on_player_connected) -- hook for player joining
hook_event(HOOK_BEFORE_SET_MARIO_ACTION, before_set_mario_action) --hook which is called before every time a player's current action is changed.Return an action to change the incoming action or 1 to cancel the action change.
hook_event(HOOK_BEFORE_PHYS_STEP, before_phys_step)
hook_event(HOOK_UPDATE,health_hook_update) -- hook that is called once per frame	
hook_event(HOOK_ON_SET_MARIO_ACTION,on_set_mario) -- hook that is called every time a player's current action is changed
hook_event(HOOK_ALLOW_INTERACT, allow_interact) --Called before mario interacts with an object, return true to allow the interaction



id_bhvCoinring = hook_behavior(nil, OBJ_LIST_LEVEL, true, bhv_coinring_init, bhv_coinring_loop)
hook_behavior(id_bhvRecoveryHeart, OBJ_LIST_LEVEL, false, nil, bhv_sonicshield_heart_loop)

hook_chat_command('friendlyringloss', "[on|off] turn friendlyringloss \\#00C7FF\\on \\#ffffff\\or \\#A02200\\off \\#ffffff\\to choose if you want to lose rings due to other players hitting you.", friendlyringloss_command)
hook_chat_command('maxringloss', "maxringloss [number] this sets the max number of rings you can lose at once set it to 0 to always lose all rings.", maxringloss_command)

hook_chat_command('loseringsonlevelchange', "[on|off] turn loseringsonlevelchange \\#00C7FF\\on \\#ffffff\\or \\#A02200\\off \\#ffffff\\to choose if you want to keep your rings between levels.", loseringsonlevelchange_command)
hook_chat_command('ringscrushinstadeath', "[on|off] turn ringscrushinstadeath \\#00C7FF\\on \\#ffffff\\or \\#A02200\\off \\#ffffff\\to choose if you want being crushed to be instadeath.", ringscrushinstadeath_command)
hook_chat_command('decreasecoincounter', "[on|off] turn decreasecoincounter on or off to choose if whether to decrease the coin counter on hit and rings equal 1 coin or have the coin counter not decease on hit and rings only affect ring counter", decreasecoincounter_command)
hook_chat_command('recoveryheartshield', "[on|off] turn recoveryheartshield \\#00C7FF\\on \\#ffffff\\or \\#A02200\\ off \\#ffffff\\ to choose whether recovery hearts should give an overshield on touch.", recoveryheartshield_command)
hook_chat_command('sonicfalldamage', "[on|off] turn sonicfalldamage on or off to choose whether you can take fall damage", sonicfalldamage_command)
hook_chat_command('maxrecollectablerings', "maxrecollectablerings [number] this sets the maximum amount of rings you can get back per hit", maxrecollectablerings_command)
hook_chat_command('ringui_x', "ringui_x [number] this sets the x position of the ring counter should be a value  between 0 and 320", ringui_x_command)
hook_chat_command('ringui_y', "ringui_y [number] this sets the y position of the ring counter should be a value between 0 and  -240", ringui_y_command)
hook_chat_command('sonicsuper', "[on|off|prereq|7coinstar] toggle the ability to go super with 50+ rings + requirement, get the requirement by typing prereq ,change prereq by entering number of stars needed or entering 7coinstar to make super require 7 100 coin stars.", sonicsuper_command)
hook_chat_command('sonichealthconfig', "[save|load|printserver|printlocal] to save the current sonic health settings to a file or load them (loading only works if used by a moderator or the server)", sonichealthconfig_command)
hook_chat_command('sonichealthsuperbutton', "[reset|change] set the button/buttons to turn super, reset sets it back to default(default x) and change allows you to change it ", sonichealthsuperbutton_command)


--sonic health mod api functions
_G.sonichealth = {

	customsupercheck = function(...)--function to allow other mod to pass its own super prereq check
		local arg  = table.pack(...)
		if (type(arg[1]) == "function") then
			superformfunction = arg[1]
		end
	end,
	supermoveset = function(...)--function to store super toggles for other mods with the functions having false for off and true for on
		local arg  = table.pack(...)
		if (arg[1] ~= nil) and (type(arg[1]) == "function") then
			supermovesetfunctions[superformfunctiontablelength] = (arg[1])
			superformfunctiontablelength = superformfunctiontablelength + 1
		end
	end,
	--this function allows other mods to check ringcount
	getringcount = function()
		return ringcount
	end,
	--- @param n number
	--this function allows other mods to modify ringcount
	increaseringcount = function(n)
		ringcount = n + ringcount
		if ringcount < 0 then
			ringcount = 0
		end
	end,
		--this function allows other mods to interact with super forms
	addsuperenemyfunction = function(...)
		local arg  = table.pack(...)
		local customfunction
		local bhvid
		if arg.n < 2 then
            return
		end
		if (type(arg[1]) == "function") then
			customfunction = arg[1]
		else 
			return
		end
		bhvid = arg[2]
		superenemyfunctions[bhvid] = customfunction
	end,
	getversion = function()--this function returns the sonic health version
		return version
	end
}

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
