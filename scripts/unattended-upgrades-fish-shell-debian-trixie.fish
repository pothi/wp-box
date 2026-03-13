#!/usr/bin/env fish

set ver 1.1

# TODO
#   - remove the apt_file with a flag.

# what's done here

# printf '%-72s' "Setting up unattended upgrade for fish shell..."
echo
echo "Setting up unattended upgrade for fish shell..."

set apt_file /etc/apt/apt.conf.d/51unattended-upgrades-fish-shell

# run `apt-cache policy` to get the following values...
set apt_origin obs://build.opensuse.org/shells:fish:release:4/Debian_13
set apt_codename Debian_13

if not test -f $apt_file
    echo "Unattended-Upgrade::Origins-Pattern { \"o=$apt_origin,n=$apt_codename\"; };" > $apt_file
else
    echo "$apt_file exists."
end

echo
echo 'Unattended upgrade for fish-shell is configured. Test it out with the command `unattended-upgraded --dry-run`.'


echo
echo "To disable unattended upgrades for fish shell, remove the file $apt_file."
echo

exit

# Working
# Unattended-Upgrade::Origins-Pattern { "o=obs://build.opensuse.org/shells:fish:release:4/Debian_13,n=Debian_13"; };

# Not working on Debian
# Unattended-Upgrade::Allowed-Origins { "o=obs://build.opensuse.org/shells:fish:release:4/Debian_13,n=trixie"; };
# Unattended-Upgrade::Origins-Pattern { "o=obs://build.opensuse.org/shells:fish:release:4/Debian_13,n=Debian_13"; };

# Unattended-Upgrade::Origins-Pattern { "origin=LP-PPA-fish-shell-release-4,codename=trixie"; };
# Unattended-Upgrade::Origins-Pattern { "o=LP-PPA-fish-shell-release-4,n=trixie"; };
# Unattended-Upgrade::Origins-Pattern { "o=obs://build.opensuse.org/shells:fish:release:4/Debian_13,n=Debian_13"; };

# Not working on Debian
# Unattended-Upgrade::Allowed-Origins { "o=obs://build.opensuse.org/shells:fish:release:4/Debian_13,n=trixie"; };
# Unattended-Upgrade::Origins-Pattern { "o=obs://build.opensuse.org/shells:fish:release:4/Debian_13,n=Debian_13"; };

# Unattended-Upgrade::Origins-Pattern { "origin=LP-PPA-fish-shell-release-4,codename=trixie"; };
# Unattended-Upgrade::Origins-Pattern { "o=LP-PPA-fish-shell-release-4,n=trixie"; };
