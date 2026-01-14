-- name: Sonic Health
-- description: Makes you lose coins on hit if you have no coins on hit you die \nCreated by wereyoshi. \n\nExtra coding by \\#00ffff\\steven.

local ringcount = 0
gGlobalSyncTable.friendlyringloss = false --whether other players can cause you to lose rings
gGlobalSyncTable.maxringloss = 0 --maximum amount of rings you are allowed to lose at once if its equal to 0 you lose all rings at once
gGlobalSyncTable.loseringsonlevelchange = true --whether to lose rings on level change
gPlayerSyncTable[0].losingrings = 0 --rings to deduct from the coin counter for a player
gGlobalSyncTable.ringscrushinstadeath = true --whether to instantly die when crushed
gGlobalSyncTable.decreasecoincounter = true --whether to decrease the coin counter on hit and have coins spawned on hit equal 1 coin or have the coin counter not decease on hit and have coins spawned only count for the ring counter
gPlayerSyncTable[0].shieldhits = 0  --current number of hits remaining for current shield
gGlobalSyncTable.recoveryheartshield = true --whether recovery hearts should give an overshield on touch


--- @param o Object
function bhv_coinring_init(o)
	bhv_moving_yellow_coin_init()
	obj_set_billboard(o)
	cur_obj_init_animation(0)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.oInteractType = INTERACT_COIN
	o.hitboxDownOffset = 0
	o.oDamageOrCoinValue = 0
	o.oHealth = 0
	o.oNumLootCoins = 0
    o.hitboxRadius = 100
    o.hitboxHeight = 64
    o.hurtboxRadius= 0
	o.hurtboxHeight = 0
	
	
	cur_obj_update_floor_and_walls()
	
end

function bhv_coinring_loop(obj)
	bhv_yellow_coin_loop()
	bhv_moving_yellow_coin_loop()
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
function ringInitialize()

	if (gGlobalSyncTable.loseringsonlevelchange == true)  then
		ringcount = 0
	end
end

---@param m MarioState 
---@param o Object
--determines if mario loses a coin on hit or dies by an object
function sonicHurt(m,o,interactType)
	if (m.playerIndex ~= 0) then
		return
	elseif (interactType == INTERACT_WATER_RING or interactType == INTERACT_KOOPA_SHELL) or ((m.flags & ACT_FLAG_RIDING_SHELL) ~= 0) or ((m.flags & ACT_RIDING_SHELL_GROUND) ~= 0) or ((m.flags & ACT_RIDING_SHELL_FALL) == 0) or ((m.flags & ACT_RIDING_SHELL_JUMP) == 0) or get_id_from_behavior(o.behavior) == id_bhvKingBobomb or get_id_from_behavior(o.behavior) == id_bhvChuckya or ( o.oInteractStatus == INT_STATUS_WAS_ATTACKED) then
		return
    elseif (m.invincTimer == 0) and ((m.flags & MARIO_METAL_CAP) == 0) then
		if ( get_id_from_behavior(o.behavior) == id_bhvSpiny or (interactType == INTERACT_DAMAGE ) )  then
			if  (o.oDamageOrCoinValue > 0) then
					if (get_id_from_behavior(o.behavior) == id_bhvSpiny) then  ---fixed spiny crash by making dropped rings non sync objects instead of synced objects for now. spiny crash happened when 2 or more rings spawned when spiny existed
						spawn_coin(m)
					else
						spawn_coin(m)
					end
					return				
			end
		elseif (interactType == INTERACT_FLAME) or (interactType == INTERACT_SNUFIT_BULLET)  or (o.oDamageOrCoinValue > 0) then
			if  (take_damage_and_knock_back(m, o) ~= 0 or interactType == INTERACT_SNUFIT_BULLET ) then
					spawn_coin(m)
					return
			end
		end
	end

end

---@param attacker MarioState --attacking player's MarioState 
---@param victim MarioState -- attacked player's MarioState
--determines if an attacked player loses a coin on hit or dies by another player
function sonicPvpHurt(attacker, victim)	
	if (gGlobalSyncTable.friendlyringloss == false)  or ((victim.flags & MARIO_METAL_CAP) ~= 0) then
		return
    elseif victim.playerIndex == 0 then
		spawn_coin(victim)
	end

end

--- @param m MarioState
--this function handles coins spawned on hit, deducting spawned coins from coin counter, and reducing ring counter
function spawn_coin(m)
	local radius = 256
	m.hurtCounter = 0
	m.invincTimer = 60

	if  gPlayerSyncTable[0].shieldhits > 0 then
		gPlayerSyncTable[0].shieldhits = gPlayerSyncTable[0].shieldhits - 1
		djui_chat_message_create('Your shield took the hit.')
		return
	elseif ringcount == 0 then
		m.health = 0xff
		return
	end

	if (gGlobalSyncTable.maxringloss == 0 or ringcount < gGlobalSyncTable.maxringloss) and (gGlobalSyncTable.decreasecoincounter == true) then
		for i = 0,ringcount -1,1 do
			spawn_non_sync_object(
			id_bhvMovingYellowCoin,
			E_MODEL_YELLOW_COIN,
			m.pos.x, m.pos.y, m.pos.z,
			function (coin)
				return ring_randomization(coin)
			end)
		end
		for i = 0,MAX_PLAYERS - 1,1 do
			if gNetworkPlayers[i].currLevelNum == gNetworkPlayers[0].currLevelNum and gNetworkPlayers[i].currActNum == gNetworkPlayers[0].currActNum then
				gPlayerSyncTable[i].losingrings = gPlayerSyncTable[i].losingrings + ringcount
			end
		end
		ringcount = 0
	elseif (gGlobalSyncTable.decreasecoincounter == true) then
		for i = 0,gGlobalSyncTable.maxringloss -1,1 do
			spawn_non_sync_object(
			id_bhvMovingYellowCoin,
			E_MODEL_YELLOW_COIN,
			m.pos.x, m.pos.y, m.pos.z,
			function (coin)
				return ring_randomization(coin)
			end)
		end
		for i = 0,MAX_PLAYERS - 1,1 do
			if gNetworkPlayers[i].currLevelNum == gNetworkPlayers[0].currLevelNum and gNetworkPlayers[i].currActNum == gNetworkPlayers[0].currActNum then
				gPlayerSyncTable[i].losingrings = gPlayerSyncTable[i].losingrings + gGlobalSyncTable.maxringloss
			end
		end
		ringcount = ringcount - gGlobalSyncTable.maxringloss
	elseif (gGlobalSyncTable.maxringloss == 0 or ringcount < gGlobalSyncTable.maxringloss) and (gGlobalSyncTable.decreasecoincounter == false) then
			for i = 0,ringcount -1,1 do
				spawn_non_sync_object(
				id_bhvCoinring,
				E_MODEL_YELLOW_COIN,
				m.pos.x, m.pos.y, m.pos.z,
				function (coin)
				    return ring_randomization(coin)
				end)
			end
			ringcount = 0
		elseif (gGlobalSyncTable.decreasecoincounter == false) then
			for i = 0,gGlobalSyncTable.maxringloss -1,1 do
				spawn_non_sync_object(
				id_bhvCoinring,
				E_MODEL_YELLOW_COIN,
				m.pos.x, m.pos.y, m.pos.z,
				function (coin)
				    return ring_randomization(coin)
				end)
			end
			ringcount = ringcount - gGlobalSyncTable.maxringloss
	end
end

-- randomize velocity and angle of the rings
function ring_randomization(obj)
	obj.oVelY = math.random(30, 50)
	obj.oForwardVel = math.random(5, 10)
	obj.oMoveAngleYaw = math.random(0x0000, 0x10000)
end

---@param m MarioState 
---@param o Object
--sets what happens when a character picks up a coin
function sonicCoinGet(m, o,interactType)
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
		else 
			sonicHurt(m,o,interactType)
		end
    end
end

--sets up a clientside ring counter
function ringDisplay()

	
    djui_hud_set_font(FONT_HUD)
    djui_hud_set_resolution(RESOLUTION_N64)

    local screenHeight = djui_hud_get_screen_height()
    local screenWidth = djui_hud_get_screen_width()
    local textLength = djui_hud_measure_text(string.format("rings %d", ringcount))

    local y = screenHeight - (screenHeight/1.40)
    local x = (screenWidth - textLength)/screenWidth

    local scale = 1

    x = screenWidth - textLength
	djui_hud_set_color(255, 255, 255, 255);
    djui_hud_print_text(string.format("rings %d", ringcount), x - 15, y, scale)

end

---@param m MarioState
--Called once per player per frame before physics code is run
function mario_update(m)
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

---@param m MarioState
--Called once per player per frame at the end of a mario update
function mario_update_end(m)
	local stepResult
	local waterstepResult
	if (m.playerIndex ~= 0) then
		return
	elseif (m.action == ACT_SQUISHED )  then --checking if mario is squished
		if (gGlobalSyncTable.ringscrushinstadeath == true) then
				m.health = 0xff
			elseif ((m.flags & MARIO_METAL_CAP) == 0 and m.invincTimer == 0)  then
				spawn_coin(m)
				return
			end
	elseif (m.action == ACT_THROWN_BACKWARD or m.action == ACT_THROWN_FORWARD)  then --checking if mario was thrown 
			stepResult = perform_air_step(m, 0)
			if m.pos.y - m.floorHeight <= 60 then --checking if mario is close to the floor to check for shallow water
				waterstepResult = perform_water_step(m)
			end
			if ((m.flags & MARIO_METAL_CAP) == 0 and m.invincTimer == 0) and (stepResult == AIR_STEP_LANDED or waterstepResult == WATER_STEP_HIT_FLOOR)  then
				spawn_coin(m)
				return
			end
	else
		m.peakHeight = m.pos.y --disabling fall damage
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

function friendlyringloss_command(msg)
    if not network_is_server() then
        djui_chat_message_create('Only the host can change this setting!')
        return true
    end

    if msg == 'on' then
        djui_chat_message_create('Friendly ring loss is \\#00C7FF\\on\\#ffffff\\!')
		gGlobalSyncTable.friendlyringloss = true 
        return true
	elseif msg == 'off' then
		djui_chat_message_create('Friendly ring loss is \\#A02200\\off\\#ffffff\\!')
		gGlobalSyncTable.friendlyringloss = false 
		return true
    end
    return false
end

function maxringloss_command(msg)
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

function loseringsonlevelchange_command(msg)
    if not network_is_server() then
        djui_chat_message_create('Only the host can change this setting!')
        return true
    end

    if msg == 'on' then
        djui_chat_message_create('Lose rings on level change is \\#00C7FF\\on\\#ffffff\\!')
		gGlobalSyncTable.loseringsonlevelchange = true 
        return true
	elseif msg == 'off' then
		djui_chat_message_create('Lose ringson level change is \\#A02200\\off\\#ffffff\\!')
		gGlobalSyncTable.loseringsonlevelchange = false 
		return true
    end
    return false
end

function ringscrushinstadeath_command(msg)
    if not network_is_server() then
        djui_chat_message_create('Only the host can change this setting!')
        return true
    end

    if msg == 'on' then
        djui_chat_message_create('Crushed instadeath is \\#00C7FF\\on\\#ffffff\\!')
		gGlobalSyncTable.ringscrushinstadeath = true 
        return true
	elseif msg == 'off' then
		djui_chat_message_create('Crushed instadeath is \\#A02200\\off\\#ffffff\\!')
		gGlobalSyncTable.ringscrushinstadeath = false 
		return true
    end
    return false
end

function decreasecoincounter_command(msg)
    if not network_is_server() then
        djui_chat_message_create('Only the host can change this setting!')
        return true
    end

    if msg == 'on' then
        djui_chat_message_create('\\#00C7FF\\The coin counter will now decrease if you take a hit\\#ffffff\\!')
		gGlobalSyncTable.decreasecoincounter = true 
        return true
	elseif msg == 'off' then
		djui_chat_message_create('\\#A02200\\The coin counter will no longer decrease if you take a hit\\#ffffff\\!')
		gGlobalSyncTable.decreasecoincounter = false 
		return true
    end
    return false
end

function recoveryheartshield_command(msg)
    if not network_is_server() then
        djui_chat_message_create('Only the host can change this setting!')
        return true
    end

    if msg == 'on' then
        djui_chat_message_create('\\#00C7FF\\Recovery hearts will now give shields\\#ffffff\\!')
		gGlobalSyncTable.recoveryheartshield = true 
        return true
	elseif msg == 'off' then
		djui_chat_message_create('\\#A02200\\Recovery hearts will no longer give shields\\#ffffff\\!')
		gGlobalSyncTable.recoveryheartshield = false 
		return true
    end
    return false
end

hook_event(HOOK_ON_LEVEL_INIT, ringInitialize) --hook for setting coins to 0 on level change
hook_event(HOOK_ON_INTERACT, sonicCoinGet) --hook for interacting with coins
hook_event(HOOK_ON_HUD_RENDER, ringDisplay) -- hook for displaying ring count
hook_event(HOOK_MARIO_UPDATE, mario_update_end)
hook_event(HOOK_ON_PVP_ATTACK, sonicPvpHurt) --hook for pvp attacks
hook_event(HOOK_BEFORE_PHYS_STEP, mario_update)
hook_event(HOOK_ON_DEATH, mario_death) -- hook for mario dying 
hook_event(HOOK_ON_PLAYER_CONNECTED, on_player_connected) -- hook for player joining

id_bhvCoinring = hook_behavior(nil, OBJ_LIST_LEVEL, true, bhv_coinring_init, bhv_coinring_loop)
hook_behavior(id_bhvRecoveryHeart, OBJ_LIST_LEVEL, false, nil, bhv_sonicshield_heart_loop)
--hook_on_sync_table_change(gPlayerSyncTable, 'losingrings', 'tag', on_testing_field_changed)

hook_chat_command('friendlyringloss', "[\\#00C7FF\\on\\#ffffff\\|\\#A02200\\off\\#ffffff\\] turn friendlyringloss \\#00C7FF\\on \\#ffffff\\or \\#A02200\\off \\#ffffff\\to choose if you want to lose rings due to other players hitting you", friendlyringloss_command)
hook_chat_command('maxringloss', "maxringloss [number] this sets the max number of rings you can lose at once set it to 0 to always lose all rings", maxringloss_command)

hook_chat_command('loseringsonlevelchange', "[\\#00C7FF\\on\\#ffffff\\|\\#A02200\\off\\#ffffff\\] turn loseringsonlevelchange \\#00C7FF\\on \\#ffffff\\or \\#A02200\\off \\#ffffff\\to choose if you want to keep your rings between levels", loseringsonlevelchange_command)
hook_chat_command('ringscrushinstadeath', "[\\#00C7FF\\on\\#ffffff\\|\\#A02200\\off\\#ffffff\\] turn ringscrushinstadeath \\#00C7FF\\on \\#ffffff\\or \\#A02200\\off \\#ffffff\\to choose if you want being crushed to be instadeath", ringscrushinstadeath_command)
hook_chat_command('decreasecoincounter', "[\\#00C7FF\\on\\#ffffff\\|\\#A02200\\off\\#ffffff\\] turn decreasecoincounter \\#00C7FF\\on \\#ffffff\\or \\#A02200\\off \\#ffffff\\to choose if whether to decrease the coin counter on hit and have coins spawned on hit equal 1 coin or have the coin counter not decease on hit and have coins spawned only count for the ring counter", decreasecoincounter_command)
hook_chat_command('recoveryheartshield', "[\\#00C7FF\\on\\#ffffff\\|\\#A02200\\off\\#ffffff\\] turn recoveryheartshield \\#00C7FF\\on \\#ffffff\\or \\#A02200\\off \\#ffffff\\to choose whether recovery hearts should give an overshield on touch ", recoveryheartshield_command)
