-- dps meter for monster hunter rise
-- written by github.com/coavins

--
-- configuration
--

local CFG = {};

-- general settings
CFG['UPDATE_RATE'] = 0.5; -- in seconds, so 0.5 means two updates per second

-- when the settings window is open, test data will be shown in the graph
CFG['SHOW_TEST_DATA_WHILE_MENU_IS_OPEN'] = true;

-- when true, damage from palicoes and palamutes will be counted as if dealt by their hunter
-- when false, damage from palicoes and palamutes will be ignored completely
CFG['OTOMO_DMG_IS_PLAYER_DMG'] = true;

-- table settings
CFG['DRAW_BAR_BACKGROUNDS'] = true;
CFG['DRAW_BAR_OUTLINES']    = false;

CFG['DRAW_BAR_TEXT_NAME']                = true; -- shows name of combatant
CFG['DRAW_BAR_TEXT_YOU']                 = true; -- shows "YOU" on your bar
CFG['DRAW_BAR_TEXT_NAME_USE_REAL_NAMES'] = false; -- show real player names instead of IDs
CFG['DRAW_BAR_TEXT_TOTAL_DAMAGE']        = false; -- shows total damage dealt
CFG['DRAW_BAR_TEXT_PERCENT_OF_PARTY']    = true; -- shows your share of party damage
CFG['DRAW_BAR_TEXT_PERCENT_OF_BEST']     = false; -- shows how close you are to the top damage dealer
CFG['DRAW_BAR_TEXT_HIT_COUNT']           = false; -- shows how many hits you've landed
CFG['DRAW_BAR_TEXT_BIGGEST_HIT']         = false; -- shows how much damage your biggest hit did

-- the damage bars will be removed, and the player blocks will receive shading instead
CFG['USE_MINIMAL_BARS'] = false;

-- rows will be added on top of the title bar instead of underneath, making it easier to place the table at the bottom of the screen
CFG['TABLE_GROWS_UPWARD'] = false;

-- when true, the row with the highest damage will be on bottom. you might want to use this with TABLE_GROWS_UPWARD
CFG['TABLE_SORT_ASC'] = false;
-- when true, player 1 will be first and player 4 will be last
CFG['TABLE_SORT_IN_ORDER'] = false;

-- table position
-- X/Y here is expressed as a percentage
-- 0 is left/top of screen, 1 is right/bottom
CFG['TABLE_X'] = 0.65;
CFG['TABLE_Y'] = 0.00;
CFG['TABLE_SCALE'] = 1.0; -- multiplier for width and height

-- pixels
CFG['TABLE_WIDTH'] = 350;
CFG['TABLE_ROWH'] = 18;

-- colors
-- 0x 12345678
-- 12 = alpha
-- 34 = green
-- 56 = blue
-- 78 = red

-- basic palette
CFG['COLOR_WHITE']  = 0xFFFFFFFF;
CFG['COLOR_GRAY']   = 0xFFAFAFAF;
CFG['COLOR_BLACK']  = 0xFF000000;
CFG['COLOR_RED']    = 0xAF3232FF;
CFG['COLOR_BLUE']   = 0xAFFF3232;
CFG['COLOR_YELLOW'] = 0xAF32FFFF;
CFG['COLOR_GREEN']  = 0xAF32FF32;

-- players
CFG['COLOR_PLAYER'] = {};
CFG['COLOR_PLAYER'][0] = CFG['COLOR_RED'];
CFG['COLOR_PLAYER'][1] = CFG['COLOR_BLUE'];
CFG['COLOR_PLAYER'][2] = CFG['COLOR_YELLOW'];
CFG['COLOR_PLAYER'][3] = CFG['COLOR_GREEN'];

-- table colors
CFG['COLOR_TITLE_BG']         = 0x88000000;
CFG['COLOR_TITLE_FG']         = 0xFFDADADA;
CFG['COLOR_BAR_BG']           = 0x44000000;
CFG['COLOR_BAR_OUTLINE']      = 0x44000000;

CFG['COLOR_BAR_DMG_PHYSICAL'] = 0xAF616658;
CFG['COLOR_BAR_DMG_PHYSICAL_UNIQUE'] = {};
CFG['COLOR_BAR_DMG_PHYSICAL_UNIQUE'][0] = 0xAF2828CC; -- red
CFG['COLOR_BAR_DMG_PHYSICAL_UNIQUE'][1] = 0xAFCC2828; -- blue
CFG['COLOR_BAR_DMG_PHYSICAL_UNIQUE'][2] = 0xAF28CCCC; -- yellow
CFG['COLOR_BAR_DMG_PHYSICAL_UNIQUE'][3] = 0xAF28CC28; -- green

CFG['COLOR_BAR_DMG_ELEMENT']  = 0xAF919984;
CFG['COLOR_BAR_DMG_ELEMENT_UNIQUE'] = {};
CFG['COLOR_BAR_DMG_ELEMENT_UNIQUE'][0] = 0xAF1C1C8C; -- red
CFG['COLOR_BAR_DMG_ELEMENT_UNIQUE'][1] = 0xAF8C1C1C; -- blue
CFG['COLOR_BAR_DMG_ELEMENT_UNIQUE'][2] = 0xAF1C8C8C; -- yellow
CFG['COLOR_BAR_DMG_ELEMENT_UNIQUE'][3] = 0xAF1C8C1C; -- green

CFG['COLOR_BAR_DMG_AILMENT']  = 0xAF3E37A3;
CFG['COLOR_BAR_DMG_OTOMO']    = 0xAFFCC500;
CFG['COLOR_BAR_DMG_OTHER']    = 0xAF616658;

--
-- end configuration
--

--
-- presets
--

local PRESET_FYLEX = {};
PRESET_FYLEX['DRAW_BAR_TEXT_NAME']                = false;
PRESET_FYLEX['DRAW_BAR_TEXT_YOU']                 = false;
PRESET_FYLEX['DRAW_BAR_TEXT_NAME_USE_REAL_NAMES'] = false;
PRESET_FYLEX['DRAW_BAR_TEXT_TOTAL_DAMAGE']        = true;
PRESET_FYLEX['DRAW_BAR_TEXT_PERCENT_OF_PARTY']    = true;
PRESET_FYLEX['DRAW_BAR_TEXT_PERCENT_OF_BEST']     = true;
PRESET_FYLEX['DRAW_BAR_TEXT_HIT_COUNT']           = false;
PRESET_FYLEX['DRAW_BAR_TEXT_BIGGEST_HIT']         = false;
PRESET_FYLEX['USE_MINIMAL_BARS']                  = true;
PRESET_FYLEX['TABLE_SORT_IN_ORDER']               = true;

--
-- globals
--

local DPS_ENABLED = true;
local DRAW_WINDOW = false;
local WINDOW_FLAGS = 0x10062;

local PRESETS = {};
local PRESET_OPTIONS = {};
local PRESET_OPTIONS_SELECTED = 1;

local SCREEN_W = 0;
local SCREEN_H = 0;
local DEBUG_Y = 0;

local LARGE_MONSTERS = {};
local TEST_MONSTERS = nil; -- like LARGE_MONSTERS, but holds dummy/test data
local DAMAGE_REPORTS = {};
local LAST_UPDATE_TIME = 0;

local MY_PLAYER_ID = nil;
local PLAYER_NAMES = {};

-- initialized later when they become available
local PLAYER_MANAGER  = nil;
local ENEMY_MANAGER   = nil;
local QUEST_MANAGER   = nil;
local MESSAGE_MANAGER = nil;
local LOBBY_MANAGER   = nil;

local SCENE_MANAGER      = sdk.get_native_singleton("via.SceneManager");
local SCENE_MANAGER_TYPE = sdk.find_type_definition("via.SceneManager");
local SCENE_MANAGER_VIEW = sdk.call_native_func(SCENE_MANAGER, SCENE_MANAGER_TYPE, "get_MainView");

local SNOW_ENEMY_ENEMYCHARACTERBASE = sdk.find_type_definition("snow.enemy.EnemyCharacterBase");
local SNOW_ENEMY_ENEMYCHARACTERBASE_AFTERCALCDAMAGE_DAMAGESIDE = SNOW_ENEMY_ENEMYCHARACTERBASE:get_method("afterCalcDamage_DamageSide");

-- helper functions

function debug_line(text)
	DEBUG_Y = DEBUG_Y + 20;
	draw.text(text, 0, DEBUG_Y, 0xFFFFFFFF);
end

function log_info(text)
	log.info('mhrise-coavins-dps: ' .. text);
end

function log_error(text)
	log.error('mhrise-coavins-dps: ' .. text);
end

-- sanity checking

if not SCENE_MANAGER then
	log_error('could not find scene manager');
	return;
end

if not SCENE_MANAGER_TYPE then
	log_error('could not find scene manager type');
	return;
end

if not SCENE_MANAGER_VIEW then
	log_error('could not find scene manager view');
	return;
end

if not SNOW_ENEMY_ENEMYCHARACTERBASE then
	log_error('could not find type snow.enemy.EnemyCharacterBase');
	return;
end

if not SNOW_ENEMY_ENEMYCHARACTERBASE_AFTERCALCDAMAGE_DAMAGESIDE then
	log_error('could not find method snow.enemy.EnemyCharacterBase::afterCalcDamage_DamageSide');
	return;
end

if not CFG['UPDATE_RATE'] or tonumber(CFG['UPDATE_RATE']) == nil then
	CFG['UPDATE_RATE'] = 0.5;
end
if CFG['UPDATE_RATE'] < 0.01 then
	CFG['UPDATE_RATE'] = 0.01;
end
if CFG['UPDATE_RATE'] > 3 then
	CFG['UPDATE_RATE'] = 3;
end

-- load presets
PRESETS['Fylex'] = PRESET_FYLEX;

-- build preset options list
for name,_ in pairs(PRESETS) do
	table.insert(PRESET_OPTIONS, name);
end
table.sort(PRESET_OPTIONS);
table.insert(PRESET_OPTIONS, 1, 'Select a preset');

function applySelectedPreset()
	local name = PRESET_OPTIONS[PRESET_OPTIONS_SELECTED];
	local preset = PRESETS[name];
	if preset then
		for setting,value in pairs(preset) do
			CFG[setting] = value;
		end
	end
end

-- system functions
function readScreenDimensions()
	local size = SCENE_MANAGER_VIEW:call("get_Size");
	if not size then
		log_error('could not get screen size');
	end;

	SCREEN_W = size:get_field("w");
	SCREEN_H = size:get_field("h");
end

function getScreenXFromX(x)
	return SCREEN_W * x;
end

function getScreenYFromY(y)
	return SCREEN_H * y;
end

function updatePlayerNames()
	local hunterInfo = LOBBY_MANAGER:get_field("_questHunterInfo");
	if not hunterInfo then
		return nil;
	end

	-- get my hunter info first, in case i'm playing single player
	local myHunter = LOBBY_MANAGER:get_field("_myHunterInfo");
	if myHunter then
		PLAYER_NAMES[MY_PLAYER_ID + 1] = myHunter:get_field("_name");
	end


	local hunterCount = hunterInfo:call("get_Count");
	if not hunterCount then
		return nil;
	end

	for i = 0, hunterCount-1 do
		local hunter = hunterInfo:call("get_Item", i);
		if hunter then
			local playerId = hunter:get_field("_memberIndex");
			local name = hunter:get_field("_name");

			if playerId and name then
				PLAYER_NAMES[playerId + 1] = name;
			end
		end
	end
end

-- callback functions

-- used to track damage taken by monsters
function read_AfterCalcInfo_DamageSide(args)
	local enemy = sdk.to_managed_object(args[2]);
	if not enemy then
		return;
	end

	local boss = LARGE_MONSTERS[enemy];
	if not boss then
		return;
	end

	if enemy:call('getHpVital') == 0 then
		return;
	end

	local info = sdk.to_managed_object(args[3]); -- snow.hit.EnemyCalcDamageInfo.AfterCalcInfo_DamageSide
	local attackerId     = info:call("get_AttackerID");
	local attackerType   = info:call("get_DamageAttackerType");
	local isPlayer  = (attackerType == 0);
	local isOtomo   = (attackerType == 19);
	local isMonster = (attackerType == 23);

	local totalDamage    = info:call("get_TotalDamage");
	local physicalDamage = info:call("get_PhysicalDamage");
	local elementDamage  = info:call("get_ElementDamage");
	local ailmentDamage  = info:call("get_ConditionDamage");

	local sources = boss.damageSources;
	if isPlayer or isOtomo then
		if not sources[attackerId] then
			sources[attackerId] = initializeDamageSource(attackerId);
		end

		-- get this damage source
		local s = sources[attackerId];

		-- add damage facts
		if isPlayer then
			s.damageTotal     = s.damageTotal + totalDamage + ailmentDamage;
			s.damagePhysical  = s.damagePhysical  + physicalDamage;
			s.damageElemental = s.damageElemental + elementDamage;
			s.damageAilment   = s.damageAilment   + ailmentDamage;
			s.numHit = s.numHit + 1;
			if totalDamage > s.maxHit then
				s.maxHit = totalDamage;
			end
		elseif isOtomo and CFG['OTOMO_DMG_IS_PLAYER_DMG'] then
			s.damageTotal     = s.damageTotal + totalDamage + ailmentDamage
			s.damageOtomo = s.damageOtomo + totalDamage + ailmentDamage;
			s.numHit = s.numHit + 1;
			if totalDamage > s.maxHit then
				s.maxHit = totalDamage;
			end
		end
	end
end

-- hook into afterCalcDamage_DamageSide function to track incoming damage on monster
-- stockDamage function also works, for host only
sdk.hook(SNOW_ENEMY_ENEMYCHARACTERBASE_AFTERCALCDAMAGE_DAMAGESIDE,
function(args)
	read_AfterCalcInfo_DamageSide(args);
end,
function(retval)
	return retval
end);

-- main

-- initializes a new damageSource
function initializeDamageSource(attackerId)
	local s = {};
	s.id = attackerId;

	s.damageTotal     = 0.0;
	s.damagePhysical  = 0.0;
	s.damageElemental = 0.0;
	s.damageAilment   = 0.0;
	s.damageOtomo     = 0.0;

	s.numHit = 0; -- how many hits
	s.maxHit = 0; -- biggest hit

	return s;
end

function initializeDamageSourceWithDummyData(attackerId)
	local s = initializeDamageSource(attackerId);
	s.damagePhysical  = math.random(1,1000);
	s.damageElemental = math.random(1,600);
	s.damageAilment   = math.random(1,100);
	s.damageOtomo     = math.random(1,400);
	s.damageTotal     = s.damagePhysical + s.damageElemental + s.damageAilment + s.damageOtomo;

	s.numHit = math.random(1,1000);
	s.maxHit = math.random(1,1000);

	return s;
end

function combineDamageSources(a, b)
	local s = initializeDamageSource();
	if a.id == b.id then
		s.id = a.id;

		s.damageTotal     = a.damageTotal     + b.damageTotal;
		s.damagePhysical  = a.damagePhysical  + b.damagePhysical;
		s.damageElemental = a.damageElemental + b.damageElemental;
		s.damageAilment   = a.damageAilment   + b.damageAilment;
		s.damageOtomo     = a.damageOtomo     + b.damageOtomo;

		s.numHit = a.numHit + b.numHit;
		s.maxHit = math.max(a.maxHit, b.maxHit);
	else
		log_error('tried to combine damage sources belonging to different attackers');
	end

	return s;
end

-- initializes a new boss object
function initializeBossMonster(bossEnemy)
	local boss = {};

	boss.enemy = bossEnemy;

	boss.species = bossEnemy:call("get_EnemySpecies");
	boss.genus   = bossEnemy:call("get_BossEnemyGenus");

	-- get name
	local enemyType = bossEnemy:get_field("<EnemyType>k__BackingField");
	boss.name = MESSAGE_MANAGER:call("getEnemyNameMessage", enemyType);

	boss.damageSources = {};

	-- store it in the table
	LARGE_MONSTERS[bossEnemy] = boss;
end

function initializeBossMonsterWithDummyData(fakeId, name)
	local boss = {};

	boss.enemy = fakeId;

	boss.genus = 999;
	boss.species = 0;

	boss.name = name;

	local s = {};
	s[0] = initializeDamageSourceWithDummyData(0);
	s[1] = initializeDamageSourceWithDummyData(1);
	s[2] = initializeDamageSourceWithDummyData(2);
	s[3] = initializeDamageSourceWithDummyData(3);
	boss.damageSources = s;

	TEST_MONSTERS[fakeId] = boss;
end

function initializeTestData()
	TEST_MONSTERS = {};
	initializeBossMonsterWithDummyData(1, 'Sample Monster A');
	initializeBossMonsterWithDummyData(2, 'Sample Monster B');
	initializeBossMonsterWithDummyData(3, 'Sample Monster C');

	dpsUpdate();
end

function clearTestData()
	TEST_MONSTERS = nil;

	dpsUpdate();
end

-- compares two damage sources
function sortFn_DESC(a, b)
	return a.source.damageTotal > b.source.damageTotal;
end

function sortFn_ASC(a, b)
	return a.source.damageTotal < b.source.damageTotal;
end

function sortFn_Player(a, b)
	return a.id < b.id;
end

-- returns a report item (for rendering) from the specified damage source (from boss cache)
function generateReportItemFromDamageSource(source)
	-- init report item
	local item = {};

	-- id
	item.id = source.id;

	if item.id >= 0 and item.id <= 3 then
		item.playerNumber = item.id + 1;
	end

	-- name
	item.name = PLAYER_NAMES[item.playerNumber];

	-- damage source
	item.source = source;

	return item;
end

-- parse damage sources from the boss cache and save them in a way that is useful for drawing a graph
function generateReportFromDamageSources(enemy, damageSources)
	local report = {};
	report.items = {};

	local topDamage = 0;
	local totalDamage = 0;

	-- parse damage sources from the boss cache
	for id,source in pairs(damageSources) do
		local item = generateReportItemFromDamageSource(source);

		-- remember what the highest damage was
		if item.source.damageTotal > topDamage then
			topDamage = item.source.damageTotal;
		end;

		totalDamage = totalDamage + item.source.damageTotal;

		-- save this item in the report
		table.insert(report.items, item);
	end

	report.topDamage = topDamage;
	report.totalDamage = totalDamage;

	-- sort report items
	if CFG['TABLE_SORT_IN_ORDER'] then
		table.sort(report.items, sortFn_Player);
	elseif CFG['TABLE_SORT_ASC'] then
		table.sort(report.items, sortFn_ASC);
	else
		table.sort(report.items, sortFn_DESC);
	end

	-- finish writing data
	for _,item in ipairs(report.items) do
		item.percentOfTotal = tonumber(string.format("%.3f", item.source.damageTotal / totalDamage));
		item.percentOfBest  = tonumber(string.format("%.3f", item.source.damageTotal / topDamage));
	end

	-- save off result to be used by draw functions
	DAMAGE_REPORTS[enemy] = report;
end

function generateSummaryReport()
	local summaryReport = {};

	local totalDamageSources = {};

	-- read all reports
	for _,report in pairs(DAMAGE_REPORTS) do
		-- read all report items
		for i,item in ipairs(report.items) do
			if not totalDamageSources[item.id] then
				totalDamageSources[item.id] = initializeDamageSource(item.id);
			end
			totalDamageSources[item.id] = combineDamageSources(totalDamageSources[item.id], item.source);
		end
	end

	-- now generate a report from the damageSources
	generateReportFromDamageSources(0, totalDamageSources);
end

function generateAllReports()
	DAMAGE_REPORTS = {};

	local monsterCollection = LARGE_MONSTERS;
	if TEST_MONSTERS then
		monsterCollection = TEST_MONSTERS;
	end

	-- create reports for all cached bosses
	for bossEnemy,boss in pairs(monsterCollection) do
		generateReportFromDamageSources(bossEnemy, boss.damageSources);
	end

	-- now create a report using the sums from the previously generated reports
	generateSummaryReport();
end

function drawRichDamageBar(source, x, y, maxWidth, h, colorPhysical, colorElemental)
	local w = 0;

	-- draw physical damage
	--debug_line(string.format('damagePhysical: %d', source.damagePhysical));
	w = (source.damagePhysical / source.damageTotal) * maxWidth;
	draw.filled_rect(x, y, w, h, colorPhysical);
	x = x + w;
	-- draw elemental damage
	--debug_line(string.format('damageElemental: %d', source.damageElemental));
	w = (source.damageElemental / source.damageTotal) * maxWidth;
	draw.filled_rect(x, y, w, h, colorElemental);
	x = x + w;
	-- draw ailment damage
	--debug_line(string.format('damageAilment: %f', source.damageAilment));
	w = (source.damageAilment / source.damageTotal) * maxWidth;
	draw.filled_rect(x, y, w, h, CFG['COLOR_BAR_DMG_AILMENT']);
	x = x + w;
	-- draw otomo damage
	--debug_line(string.format('damageOtomo: %d', source.damageOtomo));
	w = (source.damageOtomo / source.damageTotal) * maxWidth;
	draw.filled_rect(x, y, w, h, CFG['COLOR_BAR_DMG_OTOMO']);
	x = x + w;
	-- draw whatever's left
	local remainder = source.damageTotal - source.damagePhysical - source.damageElemental - source.damageAilment - source.damageOtomo;
	--debug_line(string.format('remainder: %d', remainder));
	w = (remainder / source.damageTotal) * maxWidth;
	draw.filled_rect(x, y, w, h, CFG['COLOR_BAR_DMG_OTHER']);
	--debug_line(string.format('total: %d', source.damageTotal));
end

function drawReport(index)
	local report = DAMAGE_REPORTS[index];
	if not report then
		return;
	end

	local origin_x = getScreenXFromX(CFG['TABLE_X']);
	local origin_y = getScreenYFromY(CFG['TABLE_Y']);
	local tableWidth = CFG['TABLE_WIDTH'] * CFG['TABLE_SCALE'];
	local rowHeight = CFG['TABLE_ROWH'] * CFG['TABLE_SCALE'];
	local colorBlockWidth = 20;

	local boss = LARGE_MONSTERS[index];
	local title = "All large monsters";
	if boss then
		title = boss.name;
	end

	if CFG['TABLE_GROWS_UPWARD'] then
		origin_y = origin_y - rowHeight;
	end

	-- title bar
	local timeMinutes = QUEST_MANAGER:call("getQuestElapsedTimeMin");
	local timeSeconds = QUEST_MANAGER:call("getQuestElapsedTimeSec");
	timeSeconds = timeSeconds - (timeMinutes * 60);

	if not CFG['USE_MINIMAL_BARS'] then
		-- title background
		draw.filled_rect(origin_x, origin_y, tableWidth, rowHeight, CFG['COLOR_TITLE_BG'])
	end

	-- title text
	local titleText = string.format("%d:%02.0f - %s", timeMinutes, timeSeconds, title);
	draw.text(titleText, origin_x, origin_y, CFG['COLOR_TITLE_FG']);

	if CFG['TABLE_GROWS_UPWARD'] then
		-- adjust starting position for drawing report items
		origin_y = origin_y - rowHeight * (#report.items + 1);
	end

	-- draw report items
	for i,item in ipairs(report.items) do
		local y = origin_y + rowHeight * i;

		local damageBarWidth = tableWidth - colorBlockWidth;

		local playerColor = CFG['COLOR_PLAYER'][item.id];
		if not playerColor then
			playerColor = CFG['COLOR_GRAY'];
		end

		local physicalColor = CFG['COLOR_BAR_DMG_PHYSICAL_UNIQUE'][item.id];
		if not physicalColor then
			physicalColor = CFG['COLOR_BAR_DMG_PHYSICAL'];
		end

		local elementalColor = CFG['COLOR_BAR_DMG_ELEMENT_UNIQUE'][item.id];
		if not elementalColor then
			elementalColor = CFG['COLOR_BAR_DMG_ELEMENT'];
		end

		if CFG['USE_MINIMAL_BARS'] then
			-- color block
			draw.filled_rect(origin_x, y, colorBlockWidth, rowHeight, elementalColor);

			-- damage bar
			draw.filled_rect(origin_x, y, colorBlockWidth * item.percentOfBest, rowHeight, playerColor);
		else
			if CFG['DRAW_BAR_BACKGROUNDS'] then
				-- draw background
				draw.filled_rect(origin_x, y, tableWidth, rowHeight, CFG['COLOR_BAR_BG']);
			end

			-- color block
			draw.filled_rect(origin_x, y, colorBlockWidth, rowHeight, playerColor);

			-- damage bar
			drawRichDamageBar(item.source, origin_x + colorBlockWidth, y, damageBarWidth * item.percentOfBest, rowHeight, physicalColor, elementalColor);
		end

		-- draw text
		local barText = '';
		local spacer = '   ';

		if CFG['DRAW_BAR_TEXT_NAME'] then
			-- player names
			if item.playerNumber then
				if CFG['DRAW_BAR_TEXT_YOU'] and item.id == MY_PLAYER_ID then
					if not CFG['DRAW_BAR_TEXT_NAME_USE_REAL_NAMES'] then
						barText = barText .. 'YOU          ';
					else
						barText = barText .. 'YOU' .. spacer;
					end
				elseif CFG['DRAW_BAR_TEXT_NAME_USE_REAL_NAMES'] and item.name then
					barText = barText .. string.format('%s', item.name)  .. spacer;
				else
					barText = barText .. string.format('Player %.0f', item.id + 1) .. spacer;
				end
			else
				-- it's not a player, just draw the name
				barText = barText .. string.format('%s', item.name or '') .. spacer;
			end
			-- TODO: otomo, monster
		elseif CFG['DRAW_BAR_TEXT_YOU'] then
			if item.id == MY_PLAYER_ID then
				barText = barText .. 'YOU  ';
			else
				barText = barText .. '          ';
			end
		end

		if CFG['DRAW_BAR_TEXT_TOTAL_DAMAGE'] then
			barText = barText .. string.format('%.0f', item.source.damageTotal)  .. spacer;
		end

		if CFG['DRAW_BAR_TEXT_PERCENT_OF_PARTY'] then
			barText = barText .. string.format('%.1f%%', item.percentOfTotal * 100.0)  .. spacer;
		end

		if CFG['DRAW_BAR_TEXT_PERCENT_OF_BEST'] then
			barText = barText .. string.format('(%.1f%%)', item.percentOfBest * 100.0)  .. spacer;
		end

		if CFG['DRAW_BAR_TEXT_HIT_COUNT'] then
			barText = barText .. string.format('%d', item.source.numHit)  .. spacer;
		end

		if CFG['DRAW_BAR_TEXT_BIGGEST_HIT'] then
			barText = barText .. string.format('[%d]', item.source.maxHit)  .. spacer;
		end

		draw.text(barText, origin_x + colorBlockWidth + 2, y, CFG['COLOR_WHITE']);

		if CFG['DRAW_BAR_OUTLINES'] then
			-- draw outline
			draw.outline_rect(origin_x, y, tableWidth, rowHeight, CFG['COLOR_BAR_OUTLINE']);
		end
	end
end

-- main update function
function dpsUpdate()
	-- update screen dimensions
	readScreenDimensions();

	-- get player id
	MY_PLAYER_ID = PLAYER_MANAGER:call("getMasterPlayerID");

	if CFG['DRAW_BAR_TEXT_NAME_USE_REAL_NAMES'] then
		-- get player names
		updatePlayerNames();
	end

	-- update bosses
	local bossCount = ENEMY_MANAGER:call("getBossEnemyCount");
	for i = 0, bossCount-1 do
		local bossEnemy = ENEMY_MANAGER:call("getBossEnemy", i);

		if not LARGE_MONSTERS[bossEnemy] then
			-- initialize data for this boss
			initializeBossMonster(bossEnemy);
		end

		-- get this boss from the table
		local boss = LARGE_MONSTERS[bossEnemy];

		-- update boss
		boss.isInCombat = bossEnemy:call("get_IsCombatMode");
	end

	-- update all reports
	generateAllReports();
end

-- main draw function
function dpsDraw()
	DEBUG_Y = 0;

	-- just draw the summary report
	drawReport(0);

	--drawDebugStats();
end

-- debug info stuff
function drawDebugStats()
	--local kpiData         = QUEST_MANAGER:call("get_KpiData");
	--local playerPhysical  = kpiData:call("get_PlayerTotalAttackDamage");
	--local playerElemental = kpiData:call("get_PlayerTotalElementalAttackDamage");
	--local playerAilment   = kpiData:call("get_PlayerTotalStatusAilmentsDamage");
	--local playerDamage    = playerPhysical + playerElemental + playerAilment;

	-- get player
	local myPlayerId = PLAYER_MANAGER:call("getMasterPlayerID");
	local myPlayer = PLAYER_MANAGER:call("getPlayer", myPlayerId);

	-- get enemy
	local bossCount = ENEMY_MANAGER:call("getBossEnemyCount");

	for i = 0, bossCount-1 do
		local bossEnemy = ENEMY_MANAGER:call("getBossEnemy", i);

		-- get this boss from the table
		local boss = LARGE_MONSTERS[bossEnemy];
		if not boss then
			return;
		end

		local is_combat_str = "";
		if boss.isInCombat then is_combat_str = " (In Combat)";
		                   else is_combat_str = "";
		end

		debug_line(string.format("%s%s", boss.name, is_combat_str));

		for key,value in pairs(boss.damageSources) do
			if key == myPlayerId then
				debug_line(string.format("  YOU     : %d", value));
			else
				debug_line(string.format("  Player %s: %d", key+1, value));
			end
		end
	end

	debug_line('');
	debug_line(string.format('Total damage (KPI): %d', playerDamage));

	-- monster state
	-- isEnableFastTravelCondition

	--[[
		snow.enemy.EnemyCombatSystemData
		snow.enemy.EnemyCombatSystemData.CombatTimeInfo

		EnemyManager.get_CombatMonsterSystem()
			returns:
		snow.enemy.EnemyCombatMonsterManager
			getGroupInfo(EnemyCharacterBase)
			returns:
		snow.enemy.EnemyCombatMonsterManager.GroupInfo
			get_CombatTime()
			getSelfCombatMonsterResult(EnemyCharacterBase)
	]]
end

function hasManagedResources()
	if not PLAYER_MANAGER then
		PLAYER_MANAGER = sdk.get_managed_singleton("snow.player.PlayerManager");
		if not PLAYER_MANAGER then
			return false;
		end
	end

	if not QUEST_MANAGER then
		QUEST_MANAGER = sdk.get_managed_singleton("snow.QuestManager");
		if not QUEST_MANAGER then
			return false;
		end
	end

	if not ENEMY_MANAGER then
		ENEMY_MANAGER = sdk.get_managed_singleton("snow.enemy.EnemyManager");
		if not ENEMY_MANAGER then
			return false;
		end
	end

	if not MESSAGE_MANAGER then
		MESSAGE_MANAGER = sdk.get_managed_singleton("snow.gui.MessageManager");
		if not MESSAGE_MANAGER then
			return false;
		end
	end

	if not LOBBY_MANAGER then
		LOBBY_MANAGER = sdk.get_managed_singleton("snow.LobbyManager");
		if not LOBBY_MANAGER then
			return false;
		end
	end

	return true;
end

-- runs every frame
function dpsFrame()
	-- make sure managed resources are initialized
	if not hasManagedResources() then
		return;
	end

	local questStatus = QUEST_MANAGER:get_field("_QuestStatus");

	-- update only when a quest is active
	if questStatus >= 2 then
		local totalSeconds = QUEST_MANAGER:call("getQuestElapsedTimeSec");

		-- update occasionally
		if totalSeconds > LAST_UPDATE_TIME + CFG['UPDATE_RATE'] then
			dpsUpdate();
			LAST_UPDATE_TIME = totalSeconds;
		end
	else
		-- clean up some things in between quests
		if LAST_UPDATE_TIME ~= 0 then
			LAST_UPDATE_TIME = 0;
			LARGE_MONSTERS = {};
		end
	end

	-- draw on every frame
	if DRAW_WINDOW or TEST_MONSTERS or questStatus >= 2 then
		dpsDraw();
	end
end

function dpsWindow()
	local changed, wantsIt = false;
	local value = nil;

	wantsIt = imgui.begin_window('coavins dps meter', DRAW_WINDOW, WINDOW_FLAGS);
	if DRAW_WINDOW and not wantsIt then
		DRAW_WINDOW = false;

		if TEST_MONSTERS then
			clearTestData();
		end
	end

	-- Enabled
	changed, wantsIt = imgui.checkbox('Enabled', DPS_ENABLED);
	if changed then
		DPS_ENABLED = wantsIt;
	end

	-- Show test data
	local changed, wantsIt = imgui.checkbox('Show test data while menu is open', CFG['SHOW_TEST_DATA_WHILE_MENU_IS_OPEN']);
	if changed then
		CFG['SHOW_TEST_DATA_WHILE_MENU_IS_OPEN'] = wantsIt;
		if wantsIt then
			initializeTestData();
		else
			clearTestData();
		end
	end

	-- Presets
	imgui.text('Presets');

	changed, value = imgui.combo('', PRESET_OPTIONS_SELECTED, PRESET_OPTIONS);
	if changed then
		PRESET_OPTIONS_SELECTED = value;
	end
	imgui.same_line();
	if imgui.button('Apply') then
		applySelectedPreset();
	end

	imgui.end_window();
end

re.on_frame(function()
	if DRAW_WINDOW then
		dpsWindow();
	end

	if DPS_ENABLED then
		dpsFrame();
	end
end)

re.on_draw_ui(function()
	imgui.text('coavins dps meter');
	imgui.same_line();
	if imgui.button('settings') and not DRAW_WINDOW then
		DRAW_WINDOW = true;

		if CFG['SHOW_TEST_DATA_WHILE_MENU_IS_OPEN'] then
			initializeTestData();
		end
	end
end)

log_info('init complete');