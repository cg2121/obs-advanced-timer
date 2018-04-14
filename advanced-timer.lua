obs           = obslua
source_name   = ""
total_seconds = 0

total         = 0
hour          = 0
minute        = 0
last_text     = ""
stop_text     = ""
mode          = ""
a_mode        = ""
activated     = false
global        = false
pause         = false
show_tenths   = false
start_reset   = false

hotkey_id_reset     = obs.OBS_INVALID_HOTKEY_ID
hotkey_id_pause     = obs.OBS_INVALID_HOTKEY_ID

function delta_time()
	local now = os.time()
	local year = os.date("%Y", now)
	local month = os.date("%m", now)
	local day = os.date("%d", now)
	local future = os.time{year=year, month=month, day=day, hour=hour, min=minute}
	local seconds = os.difftime(future, now)

	if (seconds < 0) then
		seconds = seconds + 84600
	end

	seconds = seconds * 10

	return seconds
end

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

	if total < 1 and (mode == "Countdown" or mode == "Specific time") then
		text = stop_text
	elseif total < 1 and mode ~= "Countdown" and show_tenths then
		text = "00:00:00.0"
	elseif total < 1 and mode ~= "Countdown" and not show_tenths then
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
	if mode == "Countup" or mode == "Streaming timer" or mode == "Recording timer" then
		total = total + 1
	else
		total = total - 1
	end

	if total < 0 then
		stop_timer()
		total = 0
	end

	set_time_text()
end

function start_timer()
	obs.timer_add(timer_callback, 100)
end

function stop_timer()
	obs.timer_remove(timer_callback)
end

function on_event(event)
	if event == obs.OBS_FRONTEND_EVENT_STREAMING_STARTED then
		if mode == "Streaming timer" then
			total = 0
			stop_timer()
			start_timer()
		end
	elseif event == obs.OBS_FRONTEND_EVENT_STREAMING_STOPPED then
		if mode == "Streaming timer" then
			stop_timer()
		end
	elseif event == obs.OBS_FRONTEND_EVENT_RECORDING_STARTED then
		if mode == "Recording timer" then
			total = 0
			stop_timer()
			start_timer()
		end
	elseif event == obs.OBS_FRONTEND_EVENT_RECORDING_STOPPED then
		if mode == "Recording timer" then
			stop_timer()
		end
	end
end

function activate(activating)
	if activated == activating then
		return
	end

	if (mode == "Streaming timer" or mode == "Recording timer") then
		return
	end

	activated = activating

	if activating then
		if mode == "Specific time" then
			total_seconds = delta_time()
		end

		if not global then
			stop_timer()
		end
		if start_reset then
			total = total_seconds
			stop_timer()
			start_timer()
		end
		set_time_text()
	end
end

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

	if mode == "Streaming timer" or mode == "Recording timer" then
		return
	end

	pause = false

	if mode == "Specific time" then
		total_seconds = delta_time()
	end

	total = total_seconds
	stop_timer()
	set_time_text()
	local source = obs.obs_get_source_by_name(source_name)
	if source ~= nil then
		local active = obs.obs_source_active(source)
		obs.obs_source_release(source)
	end

	if start_reset then
		stop_timer()
		start_timer()
	end
end

function on_pause(pressed)
	if not pressed then
		return
	end

	if mode == "Specific time" then
		total_seconds = delta_time()
	elseif mode == "Streaming timer" or mode == "Recording timer" then
		return
	end

	if pause then
		stop_timer()
	else
		stop_timer()
		start_timer()
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

function settings_modified(props, prop, settings)
	local mode_setting = obs.obs_data_get_string(settings, "mode")
	local p_duration = obs.obs_properties_get(props, "duration")
	local p_hour = obs.obs_properties_get(props, "hour")
	local p_minutes = obs.obs_properties_get(props, "minutes")
	local p_stop_text = obs.obs_properties_get(props, "stop_text")
	local p_a_mode = obs.obs_properties_get(props, "a_mode")
	local button_pause = obs.obs_properties_get(props, "pause_button")
	local button_reset = obs.obs_properties_get(props, "reset_button")

	if (mode_setting == "Countdown") then
		obs.obs_property_set_visible(p_duration, true)
		obs.obs_property_set_visible(p_hour, false)
		obs.obs_property_set_visible(p_minutes, false)
		obs.obs_property_set_visible(p_stop_text, true)
		obs.obs_property_set_visible(button_pause, true)
		obs.obs_property_set_visible(button_reset, true)
		obs.obs_property_set_visible(p_a_mode, true)
	elseif (mode_setting == "Countup") then
		obs.obs_property_set_visible(p_duration, false)
		obs.obs_property_set_visible(p_hour, false)
		obs.obs_property_set_visible(p_minutes, false)
		obs.obs_property_set_visible(p_stop_text, false)
		obs.obs_property_set_visible(button_pause, true)
		obs.obs_property_set_visible(button_reset, true)
			obs.obs_property_set_visible(p_a_mode, true)
	elseif (mode_setting == "Specific time") then
		obs.obs_property_set_visible(p_duration, false)
		obs.obs_property_set_visible(p_hour, true)
		obs.obs_property_set_visible(p_minutes, true)
		obs.obs_property_set_visible(p_stop_text, true)
		obs.obs_property_set_visible(button_pause, true)
		obs.obs_property_set_visible(button_reset, true)
		obs.obs_property_set_visible(p_a_mode, true)
	elseif (mode_setting == "Streaming timer") then
		obs.obs_property_set_visible(p_duration, false)
		obs.obs_property_set_visible(p_hour, false)
		obs.obs_property_set_visible(p_minutes, false)
		obs.obs_property_set_visible(p_stop_text, false)
		obs.obs_property_set_visible(button_pause, false)
		obs.obs_property_set_visible(button_reset, false)
		obs.obs_property_set_visible(p_a_mode, false)
	elseif (mode_setting == "Recording timer") then
		obs.obs_property_set_visible(p_duration, false)
		obs.obs_property_set_visible(p_hour, false)
		obs.obs_property_set_visible(p_minutes, false)
		obs.obs_property_set_visible(p_stop_text, false)
		obs.obs_property_set_visible(button_pause, false)
		obs.obs_property_set_visible(button_reset, false)
		obs.obs_property_set_visible(p_a_mode, false)
	end

	return true
end

function script_properties()
	local props = obs.obs_properties_create()

	local p_mode = obs.obs_properties_add_list(props, "mode", "Mode", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	obs.obs_property_list_add_string(p_mode, "Countdown", "countdown")
	obs.obs_property_list_add_string(p_mode, "Countup", "countup")
	obs.obs_property_list_add_string(p_mode, "Specific time", "specific_time")
	obs.obs_property_list_add_string(p_mode, "Streaming timer", "stream")
	obs.obs_property_list_add_string(p_mode, "Recording timer", "recording")

	obs.obs_properties_add_int(props, "duration", "Countdown duration (seconds)", 1, 100000, 1)
	obs.obs_properties_add_int(props, "hour", "Hour (0-24)", 0, 24, 1)
	obs.obs_properties_add_int(props, "minutes", "Minutes (0-59)", 0, 59, 1)

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

	local p_a_mode = obs.obs_properties_add_list(props, "a_mode", "Activation mode", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	obs.obs_property_list_add_string(p_a_mode, "Global (timer always active)", "global")
	obs.obs_property_list_add_string(p_a_mode, "Start timer on activation", "start_reset")

	obs.obs_properties_add_bool(props, "tenths", "Show tenths")
	obs.obs_properties_add_button(props, "pause_button", "Start/Stop Timer", pause_button_clicked)
	obs.obs_properties_add_button(props, "reset_button", "Reset Timer", reset_button_clicked)

	obs.obs_property_set_modified_callback(p_mode, settings_modified)

	return props
end

function script_description()
	return "Sets a text source to act as a timer with advanced options"
end

function script_update(settings)
	stop_timer()

	mode = obs.obs_data_get_string(settings, "mode")
	a_mode = obs.obs_data_get_string(settings, "a_mode")

	if mode == "Countdown" then
		total_seconds = obs.obs_data_get_int(settings, "duration") * 10
	else
		total_seconds = 0
	end

	if a_mode == "Global (timer always active)" then
		global = true
		start_reset = false
	else
		global = false
		start_reset = true
	end

	source_name = obs.obs_data_get_string(settings, "source")
	stop_text = obs.obs_data_get_string(settings, "stop_text")
	show_tenths = obs.obs_data_get_bool(settings, "tenths")
	hour = obs.obs_data_get_int(settings, "hour")
	minute = obs.obs_data_get_int(settings, "minutes")

	reset(true)
end

function script_defaults(settings)
	obs.obs_data_set_default_int(settings, "duration", 5)
	obs.obs_data_set_default_string(settings, "stop_text", "Starting soon (tm)")
	obs.obs_data_set_default_string(settings, "mode", "Countdown")
	obs.obs_data_set_default_string(settings, "a_mode", "Global (timer always active)")
end

function script_save(settings)
	local hotkey_save_array_reset = obs.obs_hotkey_save(hotkey_id_reset)
	local hotkey_save_array_pause = obs.obs_hotkey_save(hotkey_id_pause)
	obs.obs_data_set_array(settings, "reset_hotkey", hotkey_save_array_reset)
	obs.obs_data_set_array(settings, "pause_hotkey", hotkey_save_array_pause)
	obs.obs_data_array_release(hotkey_save_array_pause)
	obs.obs_data_array_release(hotkey_save_array_reset)
end

function script_load(settings)
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

	obs.obs_frontend_add_event_callback(on_event)
end
