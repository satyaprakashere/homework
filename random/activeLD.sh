#!/bin/bash

# Get list of loaded launchd services
loaded_services=$(sudo launchctl list | awk '{print $3}' | tail -n +2)

# Get all .plist filenames (no path, just basename) in LaunchDaemons folders
daemon_plists=(
  $(ls /Library/LaunchDaemons 2>/dev/null | sed 's/\.plist$//')
  $(ls /Library/LaunchAgents 2>/dev/null | sed 's/\.plist$//')
  $(ls ~/Library/LaunchAgents 2>/dev/null | sed 's/\.plist$//')
)

echo "Active launch daemons:"
for plist in "${daemon_plists[@]}"; do
  if echo "$loaded_services" | grep -qx "$plist"; then
    echo "$plist"
  fi
done
