local STATE  = require 'mhrise-coavins-dps.state'
local CORE   = require 'mhrise-coavins-dps.core'
local ENUM   = require 'mhrise-coavins-dps.enum'
local DATA   = require 'mhrise-coavins-dps.data'
local REPORT = require 'mhrise-coavins-dps.report'

local this = {}

this.showTextboxForSetting = function(setting)
	local changed, value = imgui.input_text(CORE.TXT(setting), CORE.CFG(setting))
	if changed then
		CORE.SetCFG(setting, value)
	end
end

this.showCheckboxForSetting = function(setting)
	local changed, value = imgui.checkbox(CORE.TXT(setting), CORE.CFG(setting))
	if changed then
		CORE.SetCFG(setting, value)
	end
end

this.showSliderForFloatSetting = function(setting)
	local changed, value =
		imgui.slider_float(CORE.TXT(setting), CORE.CFG(setting), CORE.MIN(setting), CORE.MAX(setting), '%.2f')
	if changed then
		CORE.SetCFG(setting, value)
	end
end

this.showSliderForIntSetting = function(setting)
	local changed, value =
		imgui.slider_int(CORE.TXT(setting), CORE.CFG(setting), CORE.MIN(setting), CORE.MAX(setting), '%d')
	if changed then
		CORE.SetCFG(setting, value)
	end
end

this.showInputsForTableColumns = function()
	if imgui.tree_node('Select data') then
		-- draw combo and slider for each column
		for i,currentCol in ipairs(STATE._CFG['TABLE_COLS']) do
			local selected = 1
			-- find option id for selected column
			for idxId,key in ipairs(ENUM.TABLE_COLUMNS_OPTIONS_ID) do
				if key == currentCol then
					selected = idxId
				end
			end
			-- show combo for choice
			local changedCol, newCol = imgui.combo('Column ' .. i, selected, ENUM.TABLE_COLUMNS_OPTIONS_READABLE)
			if changedCol then
				STATE._CFG['TABLE_COLS'][i] = ENUM.TABLE_COLUMNS_OPTIONS_ID[newCol]
			end
		end
		imgui.new_line()
		imgui.tree_pop()
	end
	if imgui.tree_node('Column width') then
		for i,currentWidth in ipairs(STATE._CFG['TABLE_COLS_WIDTH']) do
			-- skip 'None'
			if i > 1 then
				-- show slider for width
				local changedWidth, newWidth = imgui.slider_int(ENUM.TABLE_COLUMNS[i], currentWidth, 0, 250)
				if changedWidth then
					STATE._CFG['TABLE_COLS_WIDTH'][i] = newWidth
				end
			end
		end
		imgui.new_line()
		imgui.tree_pop()
	end
end

this.DrawWindowSettings = function()
	local changed, wantsIt, value

	wantsIt = imgui.begin_window('coavins dps meter - settings', STATE.DRAW_WINDOW_SETTINGS, STATE.WINDOW_FLAGS)
	if STATE.DRAW_WINDOW_SETTINGS and not wantsIt then
		STATE.DRAW_WINDOW_SETTINGS = false

		if DATA.isInTestMode() then
			DATA.clearTestData()
		end

		STATE.NEEDS_UPDATE = true
	end

	-- Enabled
	changed, wantsIt = imgui.checkbox('Enabled', STATE.DPS_ENABLED)
	if changed then
		STATE.DPS_ENABLED = wantsIt
		STATE.NEEDS_UPDATE = true
	end

	imgui.same_line()
	-- Show test data
	changed, wantsIt = imgui.checkbox('Show test data while menu is open', CORE.CFG('SHOW_TEST_DATA_WHILE_MENU_IS_OPEN'))
	if changed then
		CORE.SetCFG('SHOW_TEST_DATA_WHILE_MENU_IS_OPEN', wantsIt)
		if wantsIt then
			DATA.initializeTestData()
		else
			DATA.clearTestData()
		end

		STATE.NEEDS_UPDATE = true
	end


	if imgui.button('Save settings') then
		CORE.saveCurrentConfig()
	end
	imgui.same_line()
	if imgui.button('Load settings') then
		CORE.loadSavedConfigIfExist()
		if CORE.CFG('SHOW_TEST_DATA_WHILE_MENU_IS_OPEN') then
			DATA.initializeTestData()
		else
			DATA.clearTestData()
		end

		STATE.NEEDS_UPDATE = true
	end

	if imgui.button('Reset to default') then
		CORE.loadDefaultConfig()
		if CORE.CFG('SHOW_TEST_DATA_WHILE_MENU_IS_OPEN') then
			DATA.initializeTestData()
		else
			DATA.clearTestData()
		end

		STATE.NEEDS_UPDATE = true
	end

	imgui.same_line()
	if imgui.button('Clear combat data') then
		if DATA.isInTestMode() then
			-- reinitialize test data
			DATA.initializeTestData()
		else
			DATA.cleanUpData()
		end

		STATE.NEEDS_UPDATE = true
	end

	-- Presets
	imgui.new_line()
	imgui.text('Presets')

	changed, value = imgui.combo('', STATE.PRESET_OPTIONS_SELECTED, STATE.PRESET_OPTIONS)
	if changed then
		STATE.PRESET_OPTIONS_SELECTED = value
	end
	imgui.same_line()
	if imgui.button('Apply') then
		CORE.applySelectedPreset()
	end

	-- Settings
	imgui.new_line()
	imgui.text('Settings')

	--showSliderForFloatSetting('UPDATE_RATE')
	this.showCheckboxForSetting('COMBINE_OTOMO_WITH_HUNTER')
	this.showCheckboxForSetting('CONDITION_LIKE_DAMAGE')

	imgui.new_line()

	this.showCheckboxForSetting('DRAW_BAR_TEXT_YOU')
	this.showCheckboxForSetting('DRAW_BAR_TEXT_NAME_USE_REAL_NAMES')
	this.showCheckboxForSetting('DRAW_BAR_REVEAL_HR')

	imgui.new_line()

	imgui.text('Scale Overlay')
	this.showSliderForFloatSetting('TABLE_SCALE')
	imgui.text('Save changes and RESET SCRIPTS to apply scaling to text')

	imgui.new_line()

	this.showInputsForTableColumns()

	imgui.new_line()

	if imgui.tree_node('Appearance') then
		this.showSliderForFloatSetting('TABLE_X')
		this.showSliderForFloatSetting('TABLE_Y')

		imgui.new_line()

		this.showCheckboxForSetting('DRAW_TITLE')
		this.showCheckboxForSetting('DRAW_TITLE_TEXT')
		this.showCheckboxForSetting('DRAW_TITLE_MONSTER')
		this.showSliderForIntSetting('DRAW_TITLE_HEIGHT')
		this.showCheckboxForSetting('DRAW_TITLE_BACKGROUND')

		imgui.new_line()

		this.showCheckboxForSetting('DRAW_HEADER')
		this.showSliderForIntSetting('DRAW_HEADER_HEIGHT')
		this.showCheckboxForSetting('DRAW_HEADER_BACKGROUND')

		imgui.new_line()

		this.showCheckboxForSetting('DRAW_TABLE_BACKGROUND')
		this.showCheckboxForSetting('DRAW_BAR_OUTLINES')
		this.showCheckboxForSetting('DRAW_BAR_COLORBLOCK')
		this.showCheckboxForSetting('DRAW_BAR_USE_PLAYER_COLORS')
		this.showCheckboxForSetting('DRAW_BAR_USE_UNIQUE_COLORS')

		imgui.new_line()

		this.showCheckboxForSetting('DRAW_BAR_RELATIVE_TO_PARTY')
		this.showCheckboxForSetting('USE_MINIMAL_BARS')
		this.showCheckboxForSetting('TABLE_GROWS_UPWARD')
		this.showCheckboxForSetting('TABLE_SORT_ASC')
		this.showCheckboxForSetting('TABLE_SORT_IN_ORDER')

		imgui.new_line()

		this.showSliderForIntSetting('TABLE_WIDTH')

		imgui.new_line()

		this.showSliderForIntSetting('TABLE_ROWH')
		this.showSliderForIntSetting('TABLE_ROW_PADDING')

		imgui.new_line()

		imgui.tree_pop()
	end

	if imgui.tree_node('Text') then
		this.showTextboxForSetting('FONT_FAMILY')
		imgui.text('Save changes and RESET SCRIPTS to apply changes to font')

		imgui.new_line()

		this.showCheckboxForSetting('TEXT_DRAW_SHADOWS')
		this.showSliderForIntSetting('TEXT_SHADOW_OFFSET_X')
		this.showSliderForIntSetting('TEXT_SHADOW_OFFSET_Y')

		imgui.new_line()

		this.showSliderForIntSetting('TABLE_HEADER_TEXT_OFFSET_X')
		this.showSliderForIntSetting('TABLE_ROW_TEXT_OFFSET_X')
		this.showSliderForIntSetting('TABLE_ROW_TEXT_OFFSET_Y')


		imgui.new_line()

		imgui.tree_pop()
	end

	imgui.new_line()

	imgui.end_window()
end

this.showCheckboxForAttackerType = function(type)
	local typeIsInReport = STATE._FILTERS.ATTACKER_TYPES[type]
	local changed, wantsIt = imgui.checkbox(ENUM.ATTACKER_TYPE_TEXT[type], typeIsInReport)
	if changed then
		if wantsIt then
			CORE.AddAttackerTypeToReport(type)
		else
			CORE.RemoveAttackerTypeFromReport(type)
		end
		REPORT.generateReport(STATE.REPORT_MONSTERS)
	end
end

this.DrawWindowReport = function()
	local changed, wantsIt

	wantsIt = imgui.begin_window('coavins dps meter - filters', STATE.DRAW_WINDOW_REPORT, STATE.WINDOW_FLAGS)
	if STATE.DRAW_WINDOW_REPORT and not wantsIt then
		STATE.DRAW_WINDOW_REPORT = false
	end

	changed, wantsIt = imgui.checkbox('Include buddies', STATE._FILTERS.INCLUDE_OTOMO)
	if changed then
		STATE._FILTERS.INCLUDE_OTOMO = wantsIt
		REPORT.generateReport(STATE.REPORT_MONSTERS)
	end

	changed, wantsIt = imgui.checkbox('Include monsters, etc', STATE._FILTERS.INCLUDE_OTHER)
	if changed then
		STATE._FILTERS.INCLUDE_OTHER = wantsIt
		REPORT.generateReport(STATE.REPORT_MONSTERS)
	end

	imgui.new_line()

	-- draw buttons for each boss monster in the cache
	imgui.text('Monsters')

	local monsterCollection = STATE.TEST_MONSTERS or STATE.LARGE_MONSTERS
	local foundMonster = false
	for enemy,boss in pairs(monsterCollection) do
		foundMonster = true
		local monsterIsInReport = STATE.REPORT_MONSTERS[enemy]
		changed, wantsIt = imgui.checkbox(boss.name, monsterIsInReport)
		if changed then
			if wantsIt then
				CORE.AddMonsterToReport(enemy, boss)
			else
				CORE.RemoveMonsterFromReport(enemy)
			end
			REPORT.generateReport(STATE.REPORT_MONSTERS)
		end
	end
	if not foundMonster then
		imgui.text('(n/a)')
	end

	imgui.new_line()

	-- draw buttons for attacker types
	imgui.text('Attack type')

	this.showCheckboxForAttackerType('weapon')
	this.showCheckboxForAttackerType('otomo')
	this.showCheckboxForAttackerType('monster')

	imgui.new_line()

	this.showCheckboxForAttackerType('barrelbombs')
	this.showCheckboxForAttackerType('barrelbombl')
	this.showCheckboxForAttackerType('nitro')
	this.showCheckboxForAttackerType('capturesmokebomb')
	this.showCheckboxForAttackerType('capturebullet')
	this.showCheckboxForAttackerType('kunai')

	imgui.new_line()

	this.showCheckboxForAttackerType('hmballista')
	this.showCheckboxForAttackerType('hmcannon')
	this.showCheckboxForAttackerType('hmgatling')
	this.showCheckboxForAttackerType('hmtrap')
	this.showCheckboxForAttackerType('hmnpc')
	this.showCheckboxForAttackerType('hmflamethrower')
	this.showCheckboxForAttackerType('hmdragonator')

	imgui.new_line()

	this.showCheckboxForAttackerType('makimushi')
	this.showCheckboxForAttackerType('onibimine')
	this.showCheckboxForAttackerType('ballistahate')
	this.showCheckboxForAttackerType('waterbeetle')
	this.showCheckboxForAttackerType('detonationgrenade')
	this.showCheckboxForAttackerType('fg005')
	this.showCheckboxForAttackerType('ecbatexplode')

	imgui.end_window()
end

this.DrawWindowHotkeys = function()
	local wantsIt

	wantsIt = imgui.begin_window('coavins dps meter - hotkeys', STATE.DRAW_WINDOW_HOTKEYS, STATE.WINDOW_FLAGS)
	if STATE.DRAW_WINDOW_HOTKEYS and not wantsIt then
		STATE.DRAW_WINDOW_HOTKEYS = false
		STATE.HOTKEY_TOGGLE_OVERLAY_WAITING_TO_REGISTER = false
		STATE.HOTKEY_TOGGLE_OVERLAY_WAITING_TO_REGISTER_WITH_MODIFIER = false
	end

	imgui.text('Supports modifiers (Shift,Ctrl,Alt)')

	imgui.new_line()

	imgui.text('Toggle overlay:')
	imgui.same_line()
	local text = 'Set key'
	if STATE.HOTKEY_TOGGLE_OVERLAY_WAITING_TO_REGISTER then
		text = 'Press key...'
	end
	if imgui.button(text) then
		if STATE.HOTKEY_TOGGLE_OVERLAY_WAITING_TO_REGISTER then
			-- cancel registration
			STATE.HOTKEY_TOGGLE_OVERLAY_WAITING_TO_REGISTER = false
		else
			-- begin registration
			STATE.HOTKEY_TOGGLE_OVERLAY_WAITING_TO_REGISTER = true
			STATE.HOTKEY_TOGGLE_OVERLAY_WAITING_TO_REGISTER_WITH_MODIFIER = {}
		end
	end
	imgui.same_line()
	text = string.format('%s (%d)', ENUM.KEYBOARD_KEY[STATE.HOTKEY_TOGGLE_OVERLAY], STATE.HOTKEY_TOGGLE_OVERLAY)
	imgui.text(text)

	imgui.end_window()
end

this.OnDrawUI = function()
	imgui.begin_group()
	imgui.text('coavins dps meter')

	if imgui.button('settings') then
		STATE.DRAW_WINDOW_SETTINGS = not STATE.DRAW_WINDOW_SETTINGS

		if STATE.DRAW_WINDOW_SETTINGS then
			if CORE.CFG('SHOW_TEST_DATA_WHILE_MENU_IS_OPEN') then
				DATA.initializeTestData()
			end
		else
			if DATA.isInTestMode() then
				DATA.clearTestData()
			end
		end
	end

	imgui.same_line()

	if imgui.button('filters') then
		STATE.DRAW_WINDOW_REPORT = not STATE.DRAW_WINDOW_REPORT
	end

	imgui.same_line()

	if imgui.button('hotkeys') then
		STATE.DRAW_WINDOW_HOTKEYS = not STATE.DRAW_WINDOW_HOTKEYS
	end

	imgui.end_group()
end

return this