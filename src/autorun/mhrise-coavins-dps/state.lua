local this = {}

this.DPS_ENABLED = true
this.DPS_DEBUG = false
this.LAST_UPDATE_TIME = 0
this.DRAW_OVERLAY = true
this.DRAW_WINDOW_SETTINGS = false
this.DRAW_WINDOW_REPORT = false
this.DRAW_WINDOW_HOTKEYS = false
this.WINDOW_FLAGS = 0x20
this.IS_ONLINE = false
this.QUEST_DURATION = 0.0
this.IS_IN_QUEST = false
this.IS_IN_TRAININGHALL = false

this.NEEDS_UPDATE = false

this._CFG = {}
this.DATADIR = 'mhrise-coavins-dps/'
this._COLORS = {}
--state._HOTKEYS = {} -- todo

this.FONT = nil

this._PRESETS = {}
this.PRESET_OPTIONS = {}
this.PRESET_OPTIONS_SELECTED = 1

this.CURRENTLY_HELD_MODIFIERS = {}
this.ASSIGNED_HOTKEY_THIS_FRAME = false
this.HOTKEY_TOGGLE_OVERLAY = 109 -- 109 is numpad minus
this.HOTKEY_TOGGLE_OVERLAY_MODIFIERS = {} -- modifiers that must be held for this hotkey
this.HOTKEY_TOGGLE_OVERLAY_WAITING_TO_REGISTER = false -- if true, will register next key press as the new hotkey
this.HOTKEY_TOGGLE_OVERLAY_WAITING_TO_REGISTER_WITH_MODIFIER = {} -- table of modifiers for new hotkey

this.SCREEN_W = 0
this.SCREEN_H = 0
this.DEBUG_Y = 0
this.FAKE_OTOMO_RANGE_START = 9990 -- it is important that attacker ids near this are never used by the game

this.LARGE_MONSTERS = {}
this.TEST_MONSTERS = nil -- like LARGE_MONSTERS, but holds dummy/test data
this.DAMAGE_REPORTS = {}

this.REPORT_MONSTERS = {} -- a subset of LARGE_MONSTERS or TEST_MONSTERS that will appear in reports
this._FILTERS = {}

this.MY_PLAYER_ID = nil
this.PLAYER_NAMES = {}
this.OTOMO_NAMES = {}
this.PLAYER_RANKS = {}
this.PLAYER_TIMES = {} -- the time when they entered the quest

-- initialized later when they become available
local MANAGER = {}
this.MANAGER = MANAGER
MANAGER.PLAYER   = nil
MANAGER.ENEMY    = nil
MANAGER.QUEST    = nil
MANAGER.MESSAGE  = nil
MANAGER.LOBBY    = nil
MANAGER.AREA     = nil
MANAGER.OTOMO    = nil
MANAGER.KEYBOARD = nil
MANAGER.STAGE    = nil
MANAGER.SCENE    = nil
MANAGER.PROGRESS = nil

this.SCENE_MANAGER_TYPE = nil
this.SCENE_MANAGER_VIEW = nil

this.QUEST_MANAGER_TYPE = nil
this.QUEST_MANAGER_METHOD_ONCHANGEDGAMESTATUS = nil
this.SNOW_ENEMY_ENEMYCHARACTERBASE = nil
this.SNOW_ENEMY_ENEMYCHARACTERBASE_AFTERCALCDAMAGE_DAMAGESIDE = nil
this.SNOW_ENEMY_ENEMYCHARACTERBASE_UPDATE = nil

this.STAGE_MANAGER_TYPE = nil
this.STAGE_MANAGER_METHOD_ENDTRAININGROOM = nil

return this