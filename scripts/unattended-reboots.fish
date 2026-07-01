#!/usr/bin/env fish

set -l VERSION "1.1.0"

# unattended-reboot-setup.fish
# Manages unattended automatic reboots on Ubuntu (LEMP stack)

# Usage:
#   ./unattended-reboot-setup.fish                  # Default 03:45
#   ./unattended-reboot-setup.fish --time 03:45     # Space separated now works
#   ./unattended-reboot-setup.fish -t 04:30
#   ./unattended-reboot-setup.fish --time="02:25"
#   ./unattended-reboot-setup.fish --disable

set -l DEFAULT_REBOOT_TIME "03:45"
set -l REBOOT_TIME $DEFAULT_REBOOT_TIME
set -l conf_file "/etc/apt/apt.conf.d/52unattended-reboot"

# Improved argument parsing to support space-separated values reliably
set -l time_arg

argparse 't/time=?' 'd/disable' -- $argv
or begin
    echo "Error parsing arguments." >&2
    echo "Usage:" >&2
    echo "  $0 [-t|--time HH:MM] [-d|--disable]" >&2
    exit 1
end

# Root check
if not fish_is_root_user
    echo "This script requires root privileges. Using sudo where needed..."
end

# Handle disable
if set -q _flag_disable
    if test -f $conf_file
        echo "Disabling unattended reboots..."
        sudo rm -f $conf_file
        echo "✅ Unattended reboots disabled."
    else
        echo "Already disabled (no config file found)."
    end
    exit 0
end

# Handle time argument - support both attached and space-separated
if set -q _flag_time
    set REBOOT_TIME $_flag_time
else
    # Check remaining arguments for time (fallback for space-separated without =)
    if test (count $argv) -gt 0
        set REBOOT_TIME $argv[1]
    end
end

# Validate time format
if not string match -qr '^[0-2][0-9]:[0-5][0-9]$' -- $REBOOT_TIME
    echo "❌ Invalid time format: '$REBOOT_TIME'" >&2
    echo "Use format HH:MM (00-23 hours, 00-59 minutes)" >&2
    echo "Examples: --time=03:45   or   --time=\"03:45\"" >&2
    exit 1
end

set -l hour (string split ':' -- $REBOOT_TIME)[1]
set -l min  (string split ':' -- $REBOOT_TIME)[2]

if test $hour -gt 23 -o $min -gt 59
    echo "❌ Invalid time '$REBOOT_TIME' — hours 00-23, minutes 00-59 only." >&2
    exit 1
end

if test "$REBOOT_TIME" = "$DEFAULT_REBOOT_TIME"
    echo "Using default reboot time: $REBOOT_TIME"
    echo "💡 To change it: $0 --time HH:MM"
else
    echo "✅ Using custom reboot time: $REBOOT_TIME"
end

printf '%-66s' "Setting up unattended reboots..."

# Write config (handle root vs sudo)
set -l config_content "// Automatically reboot *WITHOUT CONFIRMATION* if needed
Unattended-Upgrade::Automatic-Reboot \"true\";

// Reboot even if users are logged in? (recommended: false)
Unattended-Upgrade::Automatic-Reboot-WithUsers \"false\";

// Scheduled reboot time
Unattended-Upgrade::Automatic-Reboot-Time \"$REBOOT_TIME\";"

if fish_is_root_user
    echo "$config_content" > $conf_file
else
    echo "$config_content" | sudo tee $conf_file > /dev/null
end

echo "done."

echo "Version: $VERSION"
echo "Reboot Time: $REBOOT_TIME"
echo "Config file: $conf_file"

echo -e "\n📄 Config contents:"
cat $conf_file

echo -e "\nTo disable: $0 --disable"
echo "To change time: $0 --time=04:30"
