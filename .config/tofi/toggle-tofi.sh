#!/bin/bash

# Check if tofi is already running
if pgrep -x "tofi-drun" > /dev/null; then 
  # if it is, kill it
  pkill -x tofi-drun

else 
  # Launch with a small fade-in effect using opacity rule temporarily
  hyprctl dispatch focuswindow tofi-drum
  # If not, launch it 
  tofi-drun -c ~/.config/tofi/configA --drun-launch=true

  # Fake delay for perceived animation 
  sleep 0.05

fi
