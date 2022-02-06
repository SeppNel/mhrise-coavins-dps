-- dps meter for monster hunter rise
-- written by github.com/coavins

local STATE  = require 'mhrise-coavins-dps.state'
local CORE   = require 'mhrise-coavins-dps.core'
local ENUM   = require 'mhrise-coavins-dps.enum'
local DATA   = require 'mhrise-coavins-dps.data'
local REPORT = require 'mhrise-coavins-dps.report'
local DRAW   = require 'mhrise-coavins-dps.draw'
local HOTKEY = require 'mhrise-coavins-dps.hotkey'
local UI     = require 'mhrise-coavins-dps.ui'
local HOOK   = require 'mhrise-coavins-dps.hook'

local function sanityCheck()
	if not CORE.CFG('UPDATE_RATE') or tonumber(CORE.CFG('UPDATE_RATE')) == nil then
		CORE.SetCFG('UPDATE_RATE', 0.5)
	end
	if CORE.CFG('UPDATE_RATE') < 0.01 then
		CORE.SetCFG('UPDATE_RATE', 0.01)
	end
	if CORE.CFG('UPDATE_RATE') > 3 then
		CORE.SetCFG('UPDATE_RATE', 3)
	end
end

--#region Updating

-- main update function
local function update()
	-- update screen dimensions
	CORE.readScreenDimensions()

	-- get player id
	STATE.MY_PLAYER_ID = STATE.MANAGER.PLAYER:call("getMasterPlayerID")

	-- get info for players
	CORE.updatePlayers()

	-- ensure bosses are initialized
	local bossCount = STATE.MANAGER.ENEMY:call("getBossEnemyCount")
	for i = 0, bossCount-1 do
		local bossEnemy = STATE.MANAGER.ENEMY:call("getBossEnemy", i)

		if not STATE.LARGE_MONSTERS[bossEnemy] then
			-- initialize data for this boss
			DATA.initializeBossMonster(bossEnemy)
		end
	end

	-- generate report for selected bosses
	REPORT.generateReport(STATE.REPORT_MONSTERS)
end

-- update based on wall clock
local function updateOccasionally(realSeconds)
	if realSeconds > STATE.LAST_UPDATE_TIME + CORE.CFG('UPDATE_RATE') then
		update()
		STATE.LAST_UPDATE_TIME = realSeconds
	end
end

--#endregion

--#region REFramework

-- runs every frame
local function frame()
	-- make sure resources are initialized
	if not CORE.hasManagedResources() then
		return
	end

	if not CORE.hasNativeResources() then
		return
	end

	-- get our function hooks if we don't have them yet
	HOOK.tryHookSdk()

	local villageArea = 0
	local questStatus = STATE.MANAGER.QUEST:get_field("_QuestStatus")
	STATE.IS_IN_QUEST = (questStatus >= 2)

	if STATE.IS_IN_QUEST then
		CORE.SetQuestDuration(STATE.MANAGER.QUEST:call("getQuestElapsedTimeSec"))
	else
		-- VillageAreaManager is unreliable, not always there, stale references
		-- get a new reference
		STATE.MANAGER.AREA = sdk.get_managed_singleton("snow.VillageAreaManager")
		if STATE.MANAGER.AREA then
			villageArea = STATE.MANAGER.AREA:get_field("<_CurrentAreaNo>k__BackingField")
		end
	end

	STATE.IS_IN_TRAININGHALL = (villageArea == 5)
	if STATE.IS_IN_TRAININGHALL then
		CORE.SetQuestDuration(STATE.MANAGER.AREA:call("get_TrainingHallStayTime"))
	end

	STATE.IS_ONLINE = (STATE.MANAGER.LOBBY and STATE.MANAGER.LOBBY:call("IsQuestOnline")) or false

	HOTKEY.updateHeldModifiers()
	HOTKEY.checkHotkeyActivated()

	-- if the window is open
	if STATE.DRAW_WINDOW_SETTINGS or STATE.NEEDS_UPDATE then
		-- update every frame
		update()
		STATE.NEEDS_UPDATE = false
	-- when a quest is active
	elseif STATE.IS_IN_QUEST then
		updateOccasionally(STATE.QUEST_DURATION)
	-- when you are in the training area
	elseif STATE.IS_IN_TRAININGHALL then
		updateOccasionally(STATE.QUEST_DURATION)
	else
		-- clean up some things in between quests
		if STATE.LAST_UPDATE_TIME ~= 0 then
			CORE.cleanUpData()
		end
	end
end

re.on_frame(function()
	if STATE.DRAW_WINDOW_SETTINGS then
		UI.DrawWindowSettings()
	end

	if STATE.DRAW_WINDOW_REPORT then
		UI.DrawWindowReport()
	end

	if STATE.DRAW_WINDOW_HOTKEYS then
		UI.DrawWindowHotkeys()
	else
		STATE.HOTKEY_TOGGLE_OVERLAY_WAITING_TO_REGISTER = false
	end

	HOTKEY.registerWaitingHotkeys()

	if STATE.DPS_ENABLED then
		frame()
	end

	STATE.ASSIGNED_HOTKEY_THIS_FRAME = false
end)

re.on_draw_ui(function()
	UI.OnDrawUI()
end)

--#endregion

-- last minute initialization

-- load default settings
if not CORE.loadDefaultConfig() then
	return -- halt script
end

-- load any saved settings
CORE.loadSavedConfigIfExist()

-- load presets into cache
CORE.loadPresets()

-- perform sanity checks
sanityCheck()

-- make sure this table has all modifiers in it
for key,_ in pairs(ENUM.KEYBOARD_MODIFIERS) do
	STATE.CURRENTLY_HELD_MODIFIERS[key] = false
end

-- register with d2d plugin
d2d.register(function()
	STATE.FONT = d2d.create_font(CORE.CFG('FONT_FAMILY'), 14 * CORE.CFG('TABLE_SCALE'))
end, DRAW.d2dDraw)

CORE.log_info('init complete')
