# OBS Plugin: Conference Schedule with Clock and Countdown

OBS plugin that displays a clock, current event info, and a countdown to the end of the current event or, if no event is currently in progress, a countdown to the start of the next event along with the event details. The event schedule is hardcoded in the script in the variable named `schedule` as explained below.

![](obs-schedule-clock-countdown.png)


## Script Installation and Configuration

1. In OBS Menu > **Tools** > **Scripts** > click the :heavy_plus_sign: button to add the script [conference-schedule-clock-countdown.lua](conference-schedule-clock-countdown.lua).
2. Set the clock format, e.g. `%H:%M` to display `14:57` or `%I:%M%p` for `02:57PM`. For a complete list of formats see [below](#datetime-format-for-the-main-clock).
3. Configure the scene

  #### OPTION A: _Create scene from scratch_ 
	
> Select the pre-existing text widgets in your current scene for:
> - clock
> - event from/to time
> - event description
> - presenter name
> - countdown (see below for details)

After configuration your plugin config dialog will look similar to this:

![](obs-schedule-clock-countdown-plugin-config.png)

  #### OPTION B: _Use provided sample scene_:
  
> - Download the file [examples/example_scene_clock_countdown.json](examples/example_scene_clock_countdown.json) and import it via **Scene collection** > **Import** > replace missing assets with your own images for logo and background.


4. Click **Edit Script** and in the editor configure the schedule in the `schedule` variable, as in the following example:

```lua
schedule = {
	{from = "7:25", to = "9:50", description = "The Great Awakening", by = "Dr Andale"},
	{from = "12:00", to = "12:55", description = "Intro: Defending against attack with fruit", by = "Dr Dinsdale"},
	{from = "13:00", to = "13:55", description = "Intermediate: How to Irritate People", by = "Prof Pandale"},
	{from = "14:15", to = "15:30", description = "Advanced: Something Completely Different", by = "Br Rindale"},
	{from = "17:00", to = "19:55", description = "Professional: Bicycle Repair Man Presentation", by = "Sr Lindale"},
	{from = "20:00", to = "21:15", description = "Academy: How to Recognise Different Types of Trees", by = "Hon Pindale"},
}
```

5. After updating the `schedule` table in the script or making other changes click :arrows_counterclockwise: to reload the script. As an alternative, right-click the script in the **Scripts** panel and select **Reload**.

NOTE:
* If the current time is within the \[from..to\] range then the event details are shown,
	and a countdown to event **END** (the `to` field).

* If there is no current event then the next event details are shown prefixed with "NEXT:",
	and a countdown to the next event **START** (the `from` field).

### Date/time format for the main clock

```
	%a weekday (Wed)
	%A weekday (Wednesday)
	%b month (Sep)
	%B month  (September)
	%c datetime (09/16/98 23:48:10)
	%d day [01-31]
	%H hour [00-23]
	%I hour [01-12]
	%M minute [00-59]
	%m month [01-12]
	%p am/pm
	%S second [00-61]
	%w weekday [Sunday-Saturday]
	%x date (09/16/98)
	%X time (23:48:10)
	%Y year (1998)
	%y year [00-99]
	%% literal %
```

_Script inspired by_:
- https://gitlab.com/albinou/obs-scripts/
- https://github.com/sebo-b/obs-scripts
