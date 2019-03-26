# obs-advanced-timer

This is a Lua script for OBS Studio that sets a text source as a timer with advanced options.  

**Modes**  
-Countdown (countdown from specified amount of seconds)  
-Countup (starts a stopwatch timer)  
-Specific time (starts to countdown to a specific time, such as countdown to 12:00 am)  
-Streaming timer (starts timer when streaming starts)  
-Recording timer (starts timer when recording start)  

**Formatting**  
The default format is: %hh:%mm:%ss (00:00:00)  

```
%d - days
%hh - hours with leading zero (00..23)
%h - hours (0..23)
%HH - hours with leading zero (00..infinity)
%H - hours (0..infinity)
%mm - minutes with leading zero (00..59)
%m - minutes (0..59)
%MM - minutes with leading zero (00..infinity)
%M - minutes (0..infinity)
%ss - seconds with leading zero (00..59)
%s - seconds (0..59)
%SS - seconds with leading zero (00..infinity)
%S - seconds (0..infinity)
%t - tenths
```

**Activation Modes**  
-Global (the timer is always active)  
-Start timer on activation (starts timer when source is activated, such as when switching to a scene with that source or turning the visibility of the source to on)  


**Hotkeys**  
Hotkeys can be set for starting/stopping and to the reset timer.
