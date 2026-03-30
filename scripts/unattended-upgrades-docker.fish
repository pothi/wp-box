#!/usr/bin/env fish

set ver 1.0

# what's done here

printf '%-72s' "Setting up unattended upgrade for Docker ..."

set apt_file /etc/apt/apt.conf.d/51unattended-upgrades-docker

set apt_origin Docker
# set apt_archive $(lsb_release -sc)

echo "Unattended-Upgrade::Allowed-Origins { \"$apt_origin:\${distro_codename}\"; };" > $apt_file
# echo "Unattended-Upgrade::Allowed-Origins { \"$apt_origin:$apt_archive\"; };" > $apt_file

echo done.

set disable_warning /etc/apt/apt.conf.d/90disablescriptwarning
echo Creating $disable_warning to disable warning message/s from apt.
test -f $disable_warning; or echo "Apt::Cmd::Disable-Script-Warning \"true\";" > $disable_warning
echo

echo Running tests...

set package_name docker

# check if the package is available for upgrade
echo Checking if $package_name has a pending upgrade...
apt list --installed | grep -q $package_name
if test $status -eq 0
    echo $package_name has a pending upgrade.

    echo Dry-running unattended-upgrade...
    unattended-upgrade --dry-run 2>&1 | grep -q $package_name
    if test $status -eq 0
        echo Dry-run successfully upgraded $package_name.
    else
        echo Dry-run did not upgrade $package_name
        echo Check if anything went wrong above.
    end
else
    echo $package_name does not have any pending upgrade.
end
