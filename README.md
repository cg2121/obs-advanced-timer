# obs-advanced-timer

This is a Lua script for OBS Studio that sets a text source as a timer with advanced options.  

**Modes**  
- Countdown (countdown from specified amount of seconds)  
- Countup (starts a stopwatch timer)  
- Specific time (starts to countdown to a specific time, such as countdown to 12:00 am)  
- Specific date & time (starts to countdown to a date and time)  
- Streaming timer (starts timer when streaming starts)  
- Recording timer (starts timer when recording start)  
- With the countdown modes, there is an option to countup when the countdown is finished

**Formatting**  
The default format is: %0H:%0m:%0s (00:00:00)  

```
%d - days
%0h - hours with leading zero (00..23)
%h - hours (0..23)
%0H - hours with leading zero (00..infinity)
%H - hours (0..infinity)
%0m - minutes with leading zero (00..59)
%m - minutes (0..59)
%0M - minutes with leading zero (00..infinity)
%M - minutes (0..infinity)
%0s - seconds with leading zero (00..59)
%s - seconds (0..59)
%0S - seconds with leading zero (00..infinity)
%S - seconds (0..infinity)
%t - tenths
%2t - hundredths
%3t - thousandths
```

**Activation Modes**  
- Global (the timer is always active)  
- Start timer on activation (starts timer when source is activated, such as when switching to a scene with that source or turning the visibility of the source to on)  


**Hotkeys**  
Hotkeys can be set for starting/stopping and to the reset timer.
