--[[ OBS Studio Dynamic Schedule display with clock, countdown and event info

URL: https://github.com/glowinthedark/obs-conference-schedule-clock-countdown/blob/master/conference-schedule-clock-countdown.lua

USAGE: 

1. OBS Menu > Tools > Scripts > [+] to add script
2. Set the clock format, e.g. %H:%M to display 14:57 or %I:%M%p for 02:57PM
3. Select the pre-existing text widgets in your current scene for:

 - clock
 - event from/to time
 - event description
 - presenter name
 - countdown (see below for details)

4. Click Edit Script and in the editor configure the schedule in the "schedule" variable

NOTE:
* If the current time is within the [from..to] range then the event details are shown,
	and a countown to event END.

* If there is no current event then the next event details are shown prefixed with "NEXT:",
	and a countdown to the next event START.

DATE FORMATTING:
	%a weekday (Wed)\
	%A weekday (Wednesday)\
	%b month (Sep)\
	%B month  (September)\
	%c datetime (09/16/98 23:48:10)\
	%d day [01-31]\
	%H hour [00-23]\
	%I hour [01-12]\
	%M minute [00-59]\
	%m month [01-12]\
	%p am/pm\
	%S second [00-61]\
	%w weekday [Sunday-Saturday]\
	%x date (09/16/98)\
	%X time (23:48:10)\
	%Y year (1998)\
	%y year [00-99]\
	%% literal %

Inspired by:
- https://gitlab.com/albinou/obs-scripts/
- https://github.com/sebo-b/obs-scripts
]]

-- START SCHEDULE CONFIGURATION --
schedule = {
	{from = "7:25", to = "9:50", description = "Awakening", by = "Dr Dinsdale"},
	{from = "12:00", to = "12:55", description = "Intro: Defending against attack with fruit", by = "Dr Dinsdale"},
	{from = "13:00", to = "13:55", description = "Intermediate: How to Irritate People", by = "Prof Pandale"},
	{from = "14:15", to = "15:30", description = "Advanced: Something Completely Different", by = "Br Rindale"},
	{from = "17:00", to = "19:55", description = "Professional: Bicycle Repair Man Presentation", by = "Sr Lindale"},
	{from = "20:00", to = "21:15", description = "Academy: How to Recognise Different Types of Trees", by = "Hon Pindale"},
}
-- END SCHEDULE CONFIGURATION --

obs = obslua

-- default clock format
datetime_format = "%H:%M"

source_name_clock = ""
source_name_time = ""
source_name_description = ""
source_name_by = ""
source_name_countdown = ""

activated = false

-- Function to set the time text
function seconds_to_string(cur_seconds)
	local seconds = math.floor(cur_seconds % 60)
	local total_minutes = math.floor(cur_seconds / 60)
	local minutes = math.floor(total_minutes % 60)
	local hours = math.floor(total_minutes / 60)
	local text = string.format("%02d:%02d:%02d", hours, minutes, seconds)

	return text
end

function mktime(hour, min, sec)
	return hour * 3600 + min * 60 + sec
end

function parseTime(str)
	local hour, min = string.match(str, "^(%d?%d):(%d%d)$")
	return mktime(hour, min, 0)
end

function now()
	local timeS = os.date("*t")
	return mktime(timeS.hour, timeS.min, timeS.sec)
end

function timer_callback()
	local timeNow = now()
	local timeFrom, timeTo, description, by, countdown, countdownNext = "", "", "", "", nil, nil

	local currentEnvent, nextEvent
	local isShowNext = false

	for i, event in ipairs(schedule) do
		local curTimeFrom = parseTime(event.from)
		local curTimeTo = parseTime(event.to)

		if timeNow > curTimeFrom and timeNow < curTimeTo then
			currentEnvent = event
			countdown = curTimeTo - timeNow
		end
		if
			currentEnvent == nil and timeNow < curTimeFrom and
				(nextEvent == nil or (curTimeFrom < parseTime(nextEvent.from) - timeNow))
		 then
			nextEvent = event
			countdownNext = curTimeFrom - timeNow
		end
	end

	if currentEnvent == nil and nextEvent ~= nil then
		currentEnvent = nextEvent
		isShowNext = true
		countdown = countdownNext
	end

	if currentEnvent ~= nil then
		timeFrom = currentEnvent.from
		timeTo = currentEnvent.to
		description = currentEnvent.description
		by = currentEnvent.by
	end

	if currentEnvent == nil then
		obs.script_log(obs.LOG_INFO, "DEBUG: No Event in progress..." .. os.date("%Y-%m-%d %H:%M:%S"))
	end

	local source_clock = obs.obs_get_source_by_name(source_name_clock)
	local source_event_time = obs.obs_get_source_by_name(source_name_time)
	local source_event_description = obs.obs_get_source_by_name(source_name_description)
	local source_event_by = obs.obs_get_source_by_name(source_name_by)
	local source_event_countdown = obs.obs_get_source_by_name(source_name_countdown)

	local text = os.date(datetime_format)
	local settings = obs.obs_data_create()

	-- CLOCK
	obs.obs_data_set_string(settings, "text", text)
	obs.obs_source_update(source_clock, settings)

	-- DESCRIPTION
	if isShowNext then
		description = "NEXT: " .. description
	end
	obs.obs_data_set_string(settings, "text", description)
	obs.obs_source_update(source_event_description, settings)

	-- EVENT TIME
	local timingText = ""
	if timeFrom ~= "" and timeTo ~= "" then
		timingText = timeFrom .. " - " .. timeTo
	end
	obs.obs_data_set_string(settings, "text", timingText)
	obs.obs_source_update(source_event_time, settings)

	-- PRESENTER
	obs.obs_data_set_string(settings, "text", by)
	obs.obs_source_update(source_event_by, settings)

	-- COUNTDOWN
	local countdown_value
	if countdown ~= nil then
		countdown_value = seconds_to_string(countdown)
	else
		countdown_value = ""
	end

	-- obs.script_log(obs.LOG_INFO, "countdown"..countdown_value.." cur secs ")

	obs.obs_data_set_string(settings, "text", countdown_value)

	obs.obs_source_update(source_event_countdown, settings)

	obs.obs_data_release(settings)
	obs.obs_source_release(source_clock)
	obs.obs_source_release(source_event_time)
	obs.obs_source_release(source_event_by)
	obs.obs_source_release(source_event_countdown)
	obs.obs_source_release(source_event_description)
end

function script_description()
	return "Dynamic schedule display with current time, countdown and event info."
end

function script_properties()
	local props = obs.obs_properties_create()

	obs.obs_properties_add_text(props, "format", "Clock format", obs.OBS_TEXT_DEFAULT)

	local prop_source_clock =
		obs.obs_properties_add_list(
		props,
		"source_clock",
		"Clock",
		obs.OBS_COMBO_TYPE_EDITABLE,
		obs.OBS_COMBO_FORMAT_STRING
	)
	local prop_source_time =
		obs.obs_properties_add_list(
		props,
		"source_time",
		"Start/End",
		obs.OBS_COMBO_TYPE_EDITABLE,
		obs.OBS_COMBO_FORMAT_STRING
	)
	local prop_source_description =
		obs.obs_properties_add_list(
		props,
		"source_description",
		"Description",
		obs.OBS_COMBO_TYPE_EDITABLE,
		obs.OBS_COMBO_FORMAT_STRING
	)
	local prop_source_by =
		obs.obs_properties_add_list(
		props,
		"source_by",
		"Presenter",
		obs.OBS_COMBO_TYPE_EDITABLE,
		obs.OBS_COMBO_FORMAT_STRING
	)
	local prop_source_countdown =
		obs.obs_properties_add_list(
		props,
		"source_countdown",
		"Countdown",
		obs.OBS_COMBO_TYPE_EDITABLE,
		obs.OBS_COMBO_FORMAT_STRING
	)
	local sources = obs.obs_enum_sources()

	if sources ~= nil then
		for _, source in ipairs(sources) do
			source_id = obs.obs_source_get_id(source)

			if source_id == "text_gdiplus" or source_id == "text_ft2_source" or source_id == "text_ft2_source_v2" then
				local name = obs.obs_source_get_name(source)
				obs.obs_property_list_add_string(prop_source_clock, name, name)
				obs.obs_property_list_add_string(prop_source_time, name, name)
				obs.obs_property_list_add_string(prop_source_description, name, name)
				obs.obs_property_list_add_string(prop_source_by, name, name)
				obs.obs_property_list_add_string(prop_source_countdown, name, name)
			end
		end
	end
	obs.source_list_release(sources)

	return props
end

function script_defaults(settings)
	obs.obs_data_set_default_string(settings, "format", "%H:%M")
end

function script_update(settings)
	source_name_clock = obs.obs_data_get_string(settings, "source_clock")
	datetime_format = obs.obs_data_get_string(settings, "format")

	source_name_time = obs.obs_data_get_string(settings, "source_time")
	source_name_description = obs.obs_data_get_string(settings, "source_description")
	source_name_by = obs.obs_data_get_string(settings, "source_by")
	source_name_countdown = obs.obs_data_get_string(settings, "source_countdown")
end

function script_load(settings)
	obs.timer_add(timer_callback, 1000)
end
