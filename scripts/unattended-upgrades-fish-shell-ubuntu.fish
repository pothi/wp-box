#!/usr/bin/env fish

set ver 1.1

# TODO
#   - remove the apt_file with a flag.

# what's done here

# printf '%-72s' "Setting up unattended upgrade for fish shell..."
echo
echo "Setting up unattended upgrade for fish shell..."

set apt_file /etc/apt/apt.conf.d/51unattended-upgrades-fish-shell

set apt_origin LP-PPA-fish-shell-release-4
set apt_archive $(lsb_release -sc)

if not test -f $apt_file
    echo "Unattended-Upgrade::Allowed-Origins { \"$apt_origin:$apt_archive\"; };" > $apt_file
else
    echo "$apt_file exists."
end

echo
echo 'Unattended upgrade for fish-shell is configured. Test it out with the command `unattended-upgraded --dry-run`.'


echo
echo "To disable unattended upgrades for fish shell, remove the file $apt_file."
echo
