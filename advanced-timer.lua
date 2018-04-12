obs           = obslua
source_name   = ""
total_seconds = 0

total         = 0
last_text     = ""
stop_text     = ""
mode          = ""
activated     = false
global        = false
pause         = false
show_tenths   = false
start_reset   = false

hotkey_id_reset     = obs.OBS_INVALID_HOTKEY_ID
hotkey_id_pause     = obs.OBS_INVALID_HOTKEY_ID

-- Function to set the time text
function set_time_text()
	local tenths   = math.floor(total % 10)
	local seconds  = math.floor((total / 10) % 60)
	local minutes  = math.floor((total / 600) % 60)
	local hours    = math.floor(total / 36000)
	local text

	if show_tenths then
		text = string.format("%02d:%02d:%02d.%d", hours, minutes, seconds, tenths)
	else
		text = string.format("%02d:%02d:%02d", hours, minutes, seconds)
	end

	if total < 1 and mode == "Countdown" then
		text = stop_text
	elseif total < 1 and mode == "Countup" and show_tenths then
		text = "00:00:00.0"
	elseif total < 1 and mode == "Countup" and not show_tenths then
		text = "00:00:00"
	end

	if text ~= last_text then
		local source = obs.obs_get_source_by_name(source_name)
		if source ~= nil then
			local settings = obs.obs_data_create()
			obs.obs_data_set_string(settings, "text", text)
			obs.obs_source_update(source, settings)
			obs.obs_data_release(settings)
			obs.obs_source_release(source)
		end
	end

	last_text = text
end

function timer_callback()
	if mode == "Countup" then
		total = total + 1
	elseif mode == "Countdown" then
		total = total - 1
	end

	if total < 0 then
		obs.remove_current_callback()
		total = 0
	end

	set_time_text()
end

function activate(activating)
	if activated == activating then
		return
	end

	activated = activating

	if activating then
		if not global then
			obs.timer_remove(timer_callback)
		end
		if start_reset then
			total = total_seconds
			obs.timer_remove(timer_callback)
			obs.timer_add(timer_callback, 100)
		end
		set_time_text()
	end
end

-- Called when a source is activated/deactivated
function activate_signal(cd, activating)
	local source = obs.calldata_source(cd, "source")
	if source ~= nil then
		local name = obs.obs_source_get_name(source)
		if (name == source_name) then
			activate(activating)
		end
	end
end

function source_activated(cd)
	activate_signal(cd, true)
end

function source_deactivated(cd)
	activate_signal(cd, false)
end

function reset(pressed)
	if not pressed then
		return
	end

	pause = false

	total = total_seconds
	obs.timer_remove(timer_callback)
	set_time_text()
	local source = obs.obs_get_source_by_name(source_name)
	if source ~= nil then
		local active = obs.obs_source_active(source)
		obs.obs_source_release(source)
	end

	if start_reset then
		obs.timer_remove(timer_callback)
		obs.timer_add(timer_callback, 100)
	end
end

function on_pause(pressed)
	if not pressed then
		return
	end

	if pause then
		obs.timer_remove(timer_callback)
	else
		obs.timer_remove(timer_callback)
		obs.timer_add(timer_callback, 100)
	end

	pause = not pause
end

function pause_button_clicked(props, p)
	on_pause(true)
	return false
end

function reset_button_clicked(props, p)
	reset(true)
	return false
end

----------------------------------------------------------

-- A function named script_properties defines the properties that the user
-- can change for the entire script module itself
function script_properties()
	local props = obs.obs_properties_create()

	local p_mode = obs.obs_properties_add_list(props, "mode", "Mode", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	obs.obs_property_list_add_string(p_mode, "Countdown", "countdown")
	obs.obs_property_list_add_string(p_mode, "Countup", "countup")

	obs.obs_properties_add_int(props, "duration", "Countdown duration (seconds)", 1, 100000, 1)

	local p = obs.obs_properties_add_list(props, "source", "Text Source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	local sources = obs.obs_enum_sources()
	if sources ~= nil then
		for _, source in ipairs(sources) do
			source_id = obs.obs_source_get_id(source)
			if source_id == "text_gdiplus" or source_id == "text_ft2_source" then
				local name = obs.obs_source_get_name(source)
				obs.obs_property_list_add_string(p, name, name)
			end
		end
	end
	obs.source_list_release(sources)

	obs.obs_properties_add_text(props, "stop_text", "Countdown Final Text", obs.OBS_TEXT_DEFAULT)
	obs.obs_properties_add_bool(props, "tenths", "Show tenths")
	obs.obs_properties_add_bool(props, "global", "Global (timer always active)")
	obs.obs_properties_add_bool(props, "start_reset", "Start timer on activation")
	obs.obs_properties_add_button(props, "pause_button", "Start/Stop Timer", pause_button_clicked)
	obs.obs_properties_add_button(props, "reset_button", "Reset Timer", reset_button_clicked)

	return props
end

-- A function named script_description returns the description shown to
-- the user
function script_description()
	return "Sets a text source to act as a countdown or countup timer"
end

-- A function named script_update will be called when settings are changed
function script_update(settings)
	mode = obs.obs_data_get_string(settings, "mode")

	if mode == "Countdown" then
		total_seconds = obs.obs_data_get_int(settings, "duration") * 10
	elseif mode == "Countup" then
		total_seconds = 0
	end

	source_name = obs.obs_data_get_string(settings, "source")
	stop_text = obs.obs_data_get_string(settings, "stop_text")
	global = obs.obs_data_get_bool(settings, "global")
	show_tenths = obs.obs_data_get_bool(settings, "tenths")
	start_reset = obs.obs_data_get_bool(settings, "start_reset")

	reset(true)
end

-- A function named script_defaults will be called to set the default settings
function script_defaults(settings)
	obs.obs_data_set_default_int(settings, "duration", 5)
	obs.obs_data_set_default_string(settings, "stop_text", "Starting soon (tm)")
	obs.obs_data_set_default_string(settings, "mode", "Countdown")
end

-- A function named script_save will be called when the script is saved
--
-- NOTE: This function is usually used for saving extra data (such as in this
-- case, a hotkey's save data).  Settings set via the properties are saved
-- automatically.
function script_save(settings)
	local hotkey_save_array_reset = obs.obs_hotkey_save(hotkey_id_reset)
	local hotkey_save_array_pause = obs.obs_hotkey_save(hotkey_id_pause)
	obs.obs_data_set_array(settings, "reset_hotkey", hotkey_save_array_reset)
	obs.obs_data_set_array(settings, "pause_hotkey", hotkey_save_array_pause)
	obs.obs_data_array_release(hotkey_save_array_pause)
	obs.obs_data_array_release(hotkey_save_array_reset)
end

-- a function named script_load will be called on startup
function script_load(settings)
	-- Connect hotkey and activation/deactivation signal callbacks
	--
	-- NOTE: These particular script callbacks do not necessarily have to
	-- be disconnected, as callbacks will automatically destroy themselves
	-- if the script is unloaded.  So there's no real need to manually
	-- disconnect callbacks that are intended to last until the script is
	-- unloaded.
	local sh = obs.obs_get_signal_handler()
	obs.signal_handler_connect(sh, "source_activate", source_activated)
	obs.signal_handler_connect(sh, "source_deactivate", source_deactivated)

	hotkey_id_reset = obs.obs_hotkey_register_frontend("reset_timer_thingy", "Reset Timer", reset)
	hotkey_id_pause = obs.obs_hotkey_register_frontend("pause_timer", "Start/Stop Timer", on_pause)
	local hotkey_save_array_reset = obs.obs_data_get_array(settings, "reset_hotkey")
	local hotkey_save_array_pause = obs.obs_data_get_array(settings, "pause_hotkey")
	obs.obs_hotkey_load(hotkey_id_reset, hotkey_save_array_reset)
	obs.obs_hotkey_load(hotkey_id_pause, hotkey_save_array_pause)
	obs.obs_data_array_release(hotkey_save_array_reset)
	obs.obs_data_array_release(hotkey_save_array_pause)
end
