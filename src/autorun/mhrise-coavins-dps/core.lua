local STATE = require 'mhrise-coavins-dps.state'

local this = {}

this.debug_line = function(text)
	STATE.DEBUG_Y = STATE.DEBUG_Y + 20
	d2d.text(STATE.FONT, text, 0, STATE.DEBUG_Y, 0xCFAFAFAF)
end

this.makeTableEmpty = function(table)
	for k,_ in pairs(table) do table[k]=nil end
end

this.log_info = function(text)
	log.info('mhrise-coavins-dps: ' .. text)
end

this.log_error = function(text)
	log.error('mhrise-coavins-dps: ' .. text)
end

this.readScreenDimensions = function()
	local size = STATE.SCENE_MANAGER_VIEW:call("get_Size")
	if not size then
		this.log_error('could not get screen size')
	end

	STATE.SCREEN_W = size:get_field("w")
	STATE.SCREEN_H = size:get_field("h")
end

this.getScreenXFromX = function(x)
	return STATE.SCREEN_W * x
end

this.getScreenYFromY = function(y)
	return STATE.SCREEN_H * y
end

this.hasNativeResources = function()
	if not STATE.MANAGER.SCENE then
		STATE.MANAGER.SCENE = sdk.get_native_singleton("via.SceneManager")
		if not STATE.MANAGER.SCENE then
			return false
		end
	end

	return true
end

this.hasManagedResources = function()
	if not STATE.MANAGER.PLAYER then
		STATE.MANAGER.PLAYER = sdk.get_managed_singleton("snow.player.PlayerManager")
		if not STATE.MANAGER.PLAYER then
			return false
		end
	end

	if not STATE.MANAGER.QUEST then
		STATE.MANAGER.QUEST = sdk.get_managed_singleton("snow.QuestManager")
		if not STATE.MANAGER.QUEST then
			return false
		end
	end

	if not STATE.MANAGER.ENEMY then
		STATE.MANAGER.ENEMY = sdk.get_managed_singleton("snow.enemy.EnemyManager")
		if not STATE.MANAGER.ENEMY then
			return false
		end
	end

	if not STATE.MANAGER.MESSAGE then
		STATE.MANAGER.MESSAGE = sdk.get_managed_singleton("snow.gui.MessageManager")
		if not STATE.MANAGER.MESSAGE then
			return false
		end
	end

	if not STATE.MANAGER.LOBBY then
		STATE.MANAGER.LOBBY = sdk.get_managed_singleton("snow.LobbyManager")
		if not STATE.MANAGER.LOBBY then
			return false
		end
	end

	if not STATE.MANAGER.OTOMO then
		STATE.MANAGER.OTOMO = sdk.get_managed_singleton("snow.otomo.OtomoManager")
		if not STATE.MANAGER.OTOMO then
			return false
		end
	end

	if not STATE.MANAGER.KEYBOARD then
		local softKeyboard = sdk.get_managed_singleton("snow.GameKeyboard")
		if softKeyboard then
			STATE.MANAGER.KEYBOARD = softKeyboard:get_field("hardKeyboard")
			if not STATE.MANAGER.KEYBOARD then
				return false
			end
		else
			return false
		end
	end

	if not STATE.MANAGER.PROGRESS then
		STATE.MANAGER.PROGRESS = sdk.get_managed_singleton("snow.progress.ProgressManager")
		if not STATE.MANAGER.PROGRESS then
			return false
		end
	end

	return true
end

this.CFG = function(name)
	return STATE._CFG[name].VALUE
end

this.SetCFG = function(name, value)
	STATE._CFG[name].VALUE = value
end

this.TXT = function(name)
	return STATE._CFG[name].TEXT
end

this.MIN = function(name)
	return STATE._CFG[name].MIN
end

this.MAX = function(name)
	return STATE._CFG[name].MAX
end

this.COLOR = function(name)
	return STATE._COLORS[name]
end

--[[
core.SetColor(name, value)
	_COLORS[name] = value
end
]]

-- returns file json
this.readDataFile = function(filename)
	filename = STATE.DATADIR .. filename
	return json.load_file(filename)
end

-- merges second cfg into first
-- returns true if anything was done
this.mergeCfgIntoLeft = function(cfg1, cfg2)
	if cfg2 then
		for name,setting in pairs(cfg2) do
			if name == 'TABLE_COLS' or name == 'TABLE_COLS_WIDTH' then
				local t1 = cfg1[name]
				local t2 = setting
				for i, v in ipairs(t2) do
					t1[i] = v
				end
			else
				cfg1[name].VALUE = setting.VALUE -- load only the values
			end
		end
	end
end

this.mergeColorsIntoLeft = function(colors1, colors2)
	if colors2 then
		for name,setting in pairs(colors2) do
			colors1[name] = setting
		end
	end
end

this.mergeFiltersIntoLeft = function(filters1, filters2)
	if filters2 then
		for name,setting in pairs(filters2) do
			if name == 'ATTACKER_TYPES' then
				for k,v in pairs(filters2[name]) do
					filters1[name][k] = v
				end
			else
				filters1[name] = setting
			end
		end
	end
end

-- returns true on success
this.loadDefaultConfig = function()
	local file = this.readDataFile('default.json')
	if not file then
		this.log_error('failed to load default.json (did you install the data files?)')
		return false
	end

	STATE._CFG = file['CFG']
	STATE._COLORS = file['COLORS']
	STATE._FILTERS = file['FILTERS']

	this.log_info('loaded default config from default.json')

	return true
end

this.loadSavedConfigIfExist = function()
	local file = this.readDataFile('saves/save.json') -- file might not exist
	if file then
		-- load save file on top of current config
		this.mergeCfgIntoLeft(STATE._CFG, file.CFG)
		this.mergeColorsIntoLeft(STATE._COLORS, file.COLORS)
		this.mergeFiltersIntoLeft(STATE._FILTERS, file.FILTERS)

		this.log_info('loaded user config from saves/save.json')
	end
end

this.saveCurrentConfig = function()
	local file = {}
	file['CFG'] = STATE._CFG
	file['COLORS'] = STATE._COLORS
	file['FILTERS'] = STATE._FILTERS

	-- save current config to disk, replacing any existing file
	local success = json.dump_file(STATE.DATADIR .. 'saves/save.json', file)
	if success then
		this.log_info('saved user config to saves/save.json')
	else
		this.log_error('failed to save user config to saves/save.json')
	end
end

-- load presets
this.loadPresets = function()
	local paths = fs.glob([[mhrise-coavins-dps\\presets\\.*json]])

	for _,path in ipairs(paths) do
		local name = string.match(path, '\\([%a%s]+).json')
		local file = this.readDataFile('presets/' .. name .. '.json')
		if file then
			STATE._PRESETS[name] = file
			this.log_info('loaded preset ' .. name .. ' from ' .. path)
		end
	end

	-- build preset options list
	for name,_ in pairs(STATE._PRESETS) do
		table.insert(STATE.PRESET_OPTIONS, name)
	end
	table.sort(STATE.PRESET_OPTIONS)
	table.insert(STATE.PRESET_OPTIONS, 1, 'Select a preset')
end

this.applySelectedPreset = function()
	local name = STATE.PRESET_OPTIONS[STATE.PRESET_OPTIONS_SELECTED]
	local preset = STATE._PRESETS[name]
	if preset then
		-- load save file on top of current config
		this.mergeCfgIntoLeft(STATE._CFG, preset.CFG)
		this.mergeColorsIntoLeft(STATE._COLORS, preset.COLORS)

		this.log_info(string.format('loaded preset %s', name))
	end
end

this.SetQuestDuration = function(value)
	STATE.QUEST_DURATION = value
end

this.cleanUpData = function()
	STATE.LAST_UPDATE_TIME = 0
	this.SetQuestDuration(0.0)
	this.makeTableEmpty(STATE.LARGE_MONSTERS)
	this.makeTableEmpty(STATE.DAMAGE_REPORTS)
	this.makeTableEmpty(STATE.REPORT_MONSTERS)
	this.log_info('cleared captured data')
end

this.AddMonsterToReport = function(enemyToAdd, bossInfo)
	STATE.REPORT_MONSTERS[enemyToAdd] = bossInfo
end

this.RemoveMonsterFromReport = function(enemyToRemove)
	for enemy,_ in pairs(STATE.REPORT_MONSTERS) do
		if enemy == enemyToRemove then
			STATE.REPORT_MONSTERS[enemy] = nil
			return
		end
	end
end

this.AddAttackerTypeToReport = function(typeToAdd)
	STATE._FILTERS.ATTACKER_TYPES[typeToAdd] = true
	this.log_info(string.format('damage type %s added to report', typeToAdd))
end

this.RemoveAttackerTypeFromReport = function(typeToRemove)
	STATE._FILTERS.ATTACKER_TYPES[typeToRemove] = false
	this.log_info(string.format('damage type %s removed from report', typeToRemove))
end

this.SetReportOtomo = function(value)
	STATE._FILTERS.INCLUDE_OTOMO = value
end

this.SetReportOther = function(value)
	STATE._FILTERS.INCLUDE_OTHER = value
end

this.attackerIdIsPlayer = function(attackerId)
	if attackerId >= 0 and attackerId <= 3 then
		return true
	else
		return false
	end
end

this.attackerIdIsOtomo = function(attackerId)
	if attackerId >= STATE.FAKE_OTOMO_RANGE_START
	and attackerId <= STATE.FAKE_OTOMO_RANGE_START + 4
	then
		return true
	else
		return false
	end
end

this.getFakeAttackerIdForOtomoId = function(otomoId)
	return STATE.FAKE_OTOMO_RANGE_START + otomoId
end

this.getOtomoIdFromFakeAttackerId = function(fakeAttackerId)
	return fakeAttackerId - STATE.FAKE_OTOMO_RANGE_START
end

this.updatePlayers = function()
	local oldNames = {}
	oldNames[1] = STATE.PLAYER_NAMES[1]
	oldNames[2] = STATE.PLAYER_NAMES[2]
	oldNames[3] = STATE.PLAYER_NAMES[3]
	oldNames[4] = STATE.PLAYER_NAMES[4]

	-- clear existing info
	this.makeTableEmpty(STATE.PLAYER_NAMES)
	this.makeTableEmpty(STATE.PLAYER_RANKS)
	this.makeTableEmpty(STATE.OTOMO_NAMES)

	-- get offline player name
	local myHunter = STATE.MANAGER.LOBBY:get_field("_myHunterInfo")
	if myHunter then
		STATE.PLAYER_NAMES[STATE.MY_PLAYER_ID + 1] = myHunter:get_field("_name")
	end

	-- get offline player rank
	STATE.PLAYER_RANKS[STATE.MY_PLAYER_ID + 1] = STATE.MANAGER.PROGRESS:call("get_HunterRank")

	-- get online players
	local hunterInfo
	if STATE.IS_IN_QUEST then
		hunterInfo = STATE.MANAGER.LOBBY:get_field("_questHunterInfo")
	else
		hunterInfo = STATE.MANAGER.LOBBY:get_field("_hunterInfo")
	end

	if hunterInfo then
		local hunterCount = hunterInfo:call("get_Count")
		if hunterCount then
			for i = 0, hunterCount-1 do
				local hunter = hunterInfo:call("get_Item", i)
				if hunter then
					local playerId = hunter:get_field("_memberIndex")
					local name = hunter:get_field("_name")
					local rank = hunter:get_field("_hunterRank")

					if playerId then
						if name then STATE.PLAYER_NAMES[playerId + 1] = name end
						if rank then STATE.PLAYER_RANKS[playerId + 1] = rank end
					end
				end
			end
		end
	end

	for key, value in ipairs(STATE.PLAYER_NAMES) do
		-- update enter time for this player when the name changes
		if oldNames[key] ~= value then
			this.log_info(string.format('updated quest time for player %d to %.0f', key, STATE.QUEST_DURATION))
			STATE.PLAYER_TIMES[key] = STATE.QUEST_DURATION
		end
	end

	-- get offline otomo names
	local firstOtomo = STATE.MANAGER.OTOMO:call("getMasterOtomoInfo", 0)
	if firstOtomo then
		local name = firstOtomo:get_field("Name")
		--local level = firstOtomo:get_field("Level")
		STATE.OTOMO_NAMES[1] = name
	end

	local secondOtomo = STATE.MANAGER.OTOMO:call("getMasterOtomoInfo", 1)
	if secondOtomo then
		local name = secondOtomo:get_field("Name")
		--local level = firstOtomo:get_field("Level")
		-- the secondary otomo is actually the fifth one!
		STATE.OTOMO_NAMES[5] = name
	end

	-- get online otomo names
	local otomoInfo
	if STATE.IS_IN_QUEST then
		otomoInfo = STATE.MANAGER.LOBBY:get_field("_questOtomoInfo")
	else
		otomoInfo = STATE.MANAGER.LOBBY:get_field("_OtomoInfo")
	end

	if otomoInfo then
		local otomoCount = otomoInfo:call("get_Count")
		if otomoCount then
			for i=0, otomoCount-1 do
				local otomo = otomoInfo:call("get_Item", i)
				if otomo then
					local otomoId = i
					local name = otomo:get_field("_Name")

					if otomoId and name then
						STATE.OTOMO_NAMES[otomoId + 1] = name
					end
				end
			end
		end
	end
end

return this
