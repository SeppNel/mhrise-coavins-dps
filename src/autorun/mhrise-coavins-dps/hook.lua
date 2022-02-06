local STATE  = require 'mhrise-coavins-dps.state'
local CORE   = require 'mhrise-coavins-dps.core'
local DATA   = require 'mhrise-coavins-dps.data'

local this = {}

-- know when we left the training room
this.read_endTrainingRoom = function()
	CORE.cleanUpData()
end

-- know when we return from a quest
this.read_onChangedGameStatus = function(args)
	local status = sdk.to_int64(args[3])
	if status == 1 then
		-- entered the village
		CORE.cleanUpData()
	end
end

-- keep track of some things on monsters
this.updateBossEnemy = function(args)
	local enemy = sdk.to_managed_object(args[2])

	-- get this boss from the table
	local boss = STATE.LARGE_MONSTERS[enemy]
	if not boss then
		return
	end

	-- get health
	local physicalParam = enemy:get_field("<PhysicalParam>k__BackingField")
	if physicalParam then
		local vitalParam = physicalParam:call("getVital", 0, 0)
		if vitalParam then
			boss.hp.current = vitalParam:call("get_Current")
			boss.hp.max = vitalParam:call("get_Max")
			boss.hp.missing = boss.hp.max - boss.hp.current
			if boss.hp.max ~= 0 then
				boss.hp.percent = boss.hp.current / boss.hp.max
			else
				boss.hp.percent = 0
			end
		end
	end

	local isCapture = enemy:call("isCapture")
	local isCombatMode = enemy:call("get_IsCombatMode")
	local isInCombat = isCombatMode and boss.hp.current > 0 and not isCapture
	local wasInCombat = boss.isInCombat

	if STATE.QUEST_DURATION > 0 and wasInCombat ~= isInCombat then
		boss.timeline[STATE.QUEST_DURATION] = isInCombat
		boss.lastTime = STATE.QUEST_DURATION
		boss.isInCombat = isInCombat
		if isInCombat then
			CORE.log_info(string.format('%s entered combat at %.4f', boss.name, STATE.QUEST_DURATION))
		else
			CORE.log_info(string.format('%s exited combat at %.4f', boss.name, STATE.QUEST_DURATION))
		end
	end

	-- get poison and blast damage
	local damageParam = enemy:get_field("<DamageParam>k__BackingField")
	if damageParam then
		local blastParam = damageParam:get_field("_BlastParam")
		if blastParam then
			-- if applied, then calculate share for blast and apply damage
			local activateCnt = blastParam:call("get_ActivateCount"):get_element(0):get_field("mValue")
			if activateCnt > boss.ailment.count[5] then
				boss.ailment.count[5] = activateCnt
				DATA.calculateAilmentContrib(boss, 5)

				local blastDamage = blastParam:call("get_BlastDamage")
				DATA.addAilmentDamageToBoss(boss, 5, blastDamage)
			end
		end

		local poisonParam = damageParam:get_field("_PoisonParam")
		if poisonParam then
			-- if applied, then calculate share for poison
			local activateCnt = poisonParam:call("get_ActivateCount"):get_element(0):get_field("mValue")
			if activateCnt > boss.ailment.count[4] then
				boss.ailment.count[4] = activateCnt
				DATA.calculateAilmentContrib(boss, 4)
			end

			-- if poison tick, apply damage
			local poisonDamage = poisonParam:get_field("<Damage>k__BackingField")
			local isDamage = poisonParam:call("get_IsDamage")
			if isDamage then
				DATA.addAilmentDamageToBoss(boss, 4, poisonDamage)
			end
		end
	end
end

-- track damage taken by monsters
this.read_AfterCalcInfo_DamageSide = function(args)
	local enemy = sdk.to_managed_object(args[2])
	if not enemy then
		return
	end

	local boss = STATE.LARGE_MONSTERS[enemy]
	if not boss then
		return
	end

	if boss.hp.current == 0 then
		return
	end

	local info = sdk.to_managed_object(args[3]) -- snow.hit.EnemyCalcDamageInfo.AfterCalcInfo_DamageSide

	local attackerId     = info:call("get_AttackerID")
	local attackerTypeId = info:call("get_DamageAttackerType")

	local physicalDamage  = tonumber(info:call("get_PhysicalDamage"))
	local elementDamage   = tonumber(info:call("get_ElementDamage"))
	local conditionDamage = tonumber(info:call("get_ConditionDamage"))
	local conditionType   = tonumber(info:call("get_ConditionDamageType")) -- snow.enemy.EnemyDef.ConditionDamageType

	local criticalType = tonumber(info:call("get_CriticalResult")) -- snow.hit.CriticalType (0: not, 1: crit, 2: bad crit)

	--log.info(string.format('%.0f:%.0f = %.0f:%.0f:%.0f:%.0f'
	--, attackerId, attackerTypeId, physicalDamage, elementDamage, conditionDamage, conditionType))

	DATA.addDamageToBoss(boss, attackerId, attackerTypeId
	, physicalDamage, elementDamage, conditionDamage, conditionType, 0, 0, criticalType)
end

this.tryHookSdk = function()
	if not STATE.SCENE_MANAGER_TYPE then
		STATE.SCENE_MANAGER_TYPE = sdk.find_type_definition("via.SceneManager")
		if STATE.MANAGER.SCENE and STATE.SCENE_MANAGER_TYPE then
			STATE.SCENE_MANAGER_VIEW = sdk.call_native_func(STATE.MANAGER.SCENE, STATE.SCENE_MANAGER_TYPE, "get_MainView")
		else
			CORE.log_error('Failed to find via.SceneManager')
		end
	end

	if not STATE.QUEST_MANAGER_TYPE then
		STATE.QUEST_MANAGER_TYPE = sdk.find_type_definition("snow.QuestManager")
		if STATE.QUEST_MANAGER_TYPE then
			STATE.QUEST_MANAGER_METHOD_ONCHANGEDGAMESTATUS = STATE.QUEST_MANAGER_TYPE:get_method("onChangedGameStatus")
			-- register function hook
			sdk.hook(STATE.QUEST_MANAGER_METHOD_ONCHANGEDGAMESTATUS,
				function(args) this.read_onChangedGameStatus(args) end,
				function(retval) return retval end)
			CORE.log_info('Hooked snow.QuestManager:onGameChangeStatus()')
		else
			CORE.log_error('Failed to find snow.QuestManager')
		end
	end

	if not STATE.SNOW_ENEMY_ENEMYCHARACTERBASE then
		--local QUEST_MANAGER_METHOD_ADDKPIATTACKDAMAGE = QUEST_MANAGER_TYPE:get_method("addKpiAttackDamage")
		STATE.SNOW_ENEMY_ENEMYCHARACTERBASE = sdk.find_type_definition("snow.enemy.EnemyCharacterBase")
		if STATE.SNOW_ENEMY_ENEMYCHARACTERBASE then
			STATE.SNOW_ENEMY_ENEMYCHARACTERBASE_UPDATE = STATE.SNOW_ENEMY_ENEMYCHARACTERBASE:get_method("update")
			-- register function hook
			sdk.hook(STATE.SNOW_ENEMY_ENEMYCHARACTERBASE_UPDATE,
				function(args) this.updateBossEnemy(args) end,
				function(retval) return retval end)
			CORE.log_info('Hooked snow.enemy.EnemyCharacterBase:update()')

			-- stockDamage function also works, for host only
			STATE.SNOW_ENEMY_ENEMYCHARACTERBASE_AFTERCALCDAMAGE_DAMAGESIDE =
			STATE.SNOW_ENEMY_ENEMYCHARACTERBASE:get_method("afterCalcDamage_DamageSide")
			-- register function hook
			sdk.hook(STATE.SNOW_ENEMY_ENEMYCHARACTERBASE_AFTERCALCDAMAGE_DAMAGESIDE,
				function(args) this.read_AfterCalcInfo_DamageSide(args) end,
				function(retval) return retval end)
			CORE.log_info('Hooked snow.enemy.EnemyCharacterBase:afterCalcDamage_DamageSide()')
		else
			CORE.log_error('Failed to find snow.enemy.EnemyCharacterBase')
		end
	end

	if not STATE.STAGE_MANAGER_TYPE then
		STATE.STAGE_MANAGER_TYPE = sdk.find_type_definition("snow.stage.StageManager")
		if STATE.STAGE_MANAGER_TYPE then
			STATE.STAGE_MANAGER_METHOD_ENDTRAININGROOM = STATE.STAGE_MANAGER_TYPE:get_method("endTrainingRoom")
			-- register function hook
			sdk.hook(STATE.STAGE_MANAGER_METHOD_ENDTRAININGROOM,
				function() this.read_endTrainingRoom() end,
				function(retval) return retval end)
		else
			CORE.log_error('Failed to find snow.stage.StageManager')
		end
	end
end

return this