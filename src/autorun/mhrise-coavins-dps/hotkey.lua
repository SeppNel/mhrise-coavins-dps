local STATE = require 'mhrise-coavins-dps.state'
local ENUM  = require 'mhrise-coavins-dps.enum'

local this = {}

this.updateHeldModifiers = function()
	for key,_ in pairs(ENUM.KEYBOARD_MODIFIERS) do
		if not STATE.CURRENTLY_HELD_MODIFIERS[key] and STATE.MANAGER.KEYBOARD:call("getTrg", key) then
			STATE.CURRENTLY_HELD_MODIFIERS[key] = true
		elseif STATE.CURRENTLY_HELD_MODIFIERS[key] and STATE.MANAGER.KEYBOARD:call("getRelease", key) then
			STATE.CURRENTLY_HELD_MODIFIERS[key] = false
		end
	end
end

-- TODO: enhance to accept whatever hotkey as param
this.checkHotkeyActivated = function()
	-- we pressed our hotkey and did not just assign it
	if not STATE.ASSIGNED_HOTKEY_THIS_FRAME and STATE.MANAGER.KEYBOARD:call("getTrg", STATE.HOTKEY_TOGGLE_OVERLAY) then
		-- if correct modifiers are not held, return
		for key,needsHeld in pairs(STATE.HOTKEY_TOGGLE_OVERLAY_MODIFIERS) do
			if STATE.CURRENTLY_HELD_MODIFIERS[key] ~= needsHeld then
				return
			end
		end
		-- perform hotkey action
		STATE.DRAW_OVERLAY = not STATE.DRAW_OVERLAY
	end
end

this.registerWaitingHotkeys = function()
	if STATE.HOTKEY_TOGGLE_OVERLAY_WAITING_TO_REGISTER then
		for key,_ in pairs(ENUM.KEYBOARD_KEY) do
			-- key released
			if ENUM.KEYBOARD_MODIFIERS[key] and STATE.MANAGER.KEYBOARD:call("getRelease", key) then
				log.info(string.format('unregister modifier %d', key))
				STATE.HOTKEY_TOGGLE_OVERLAY_WAITING_TO_REGISTER_WITH_MODIFIER[key] = nil
			end
			-- key pressed
			if STATE.MANAGER.KEYBOARD:call("getTrg", key) then
				if ENUM.KEYBOARD_MODIFIERS[key] then
					log.info(string.format('register modifier %d', key))
					STATE.HOTKEY_TOGGLE_OVERLAY_WAITING_TO_REGISTER_WITH_MODIFIER[key] = true
				else
					-- pressed a valid hotkey
					log.info(string.format('register hotkey %d', key))
					-- register it
					STATE.HOTKEY_TOGGLE_OVERLAY = key
					-- register modifiers
					-- first, require NO modifiers be held
					for modifierKey,_ in pairs(ENUM.KEYBOARD_MODIFIERS) do
						STATE.HOTKEY_TOGGLE_OVERLAY_MODIFIERS[modifierKey] = false
					end
					-- then change requirement for any modifiers the user did actually want
					for modifierKey,needsHeld in pairs(STATE.HOTKEY_TOGGLE_OVERLAY_WAITING_TO_REGISTER_WITH_MODIFIER) do
						STATE.HOTKEY_TOGGLE_OVERLAY_MODIFIERS[modifierKey] = needsHeld
					end
					-- clear flags
					STATE.HOTKEY_TOGGLE_OVERLAY_WAITING_TO_REGISTER = false
					-- remember that we assigned this frame so we don't actually toggle the overlay
					STATE.ASSIGNED_HOTKEY_THIS_FRAME = true
				end
			end
		end
	end
end

return this