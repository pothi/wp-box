#!/usr/bin/env fish

# available in two places
# frankenphp/unattended-upgrades.fish
# wp-box/scripts/unattended-upgrades-frankenphp.fish

set ver 1.1

set package_name "FrankenPHP"
set apt_identifier frankenphp

# what's done here

# printf '%-72s' "Setting up unattended upgrade for $package..."
echo
echo "Setting up unattended upgrade for $package..."

set apt_file /etc/apt/apt.conf.d/51unattended-upgrades-$apt_identifier

set apt_origin Static-PHP
set apt_archive php-zts

set os (grep -w ID /etc/os-release | awk -F= '{print $2}')

echo "OS: $os"

if not test -f $apt_file
    switch $os
        case ubuntu
            echo "Unattended-Upgrade::Allowed-Origins { \"$apt_origin:$apt_archive\"; };" > $apt_file
        case debian
            echo "Unattended-Upgrade::Origins-Pattern { \"o=$apt_origin,a=$apt_archive\"; };" > $apt_file
        case '*'
            echo >&2 'Unknown OS'
            exit
    end
else
    echo "$apt_file exists."
    cat $apt_file
end

echo
echo 'Unattended upgrade for $package_name is configured. Test it out with the command `unattended-upgraded --dry-run`.'


echo
echo "To disable unattended upgrades for $package_name, remove the file $apt_file."
echo

set disable_warning /etc/apt/apt.conf.d/90disablescriptwarning
echo Creating $disable_warning to disable warning message/s from apt.
test -f $disable_warning; or echo "Apt::Cmd::Disable-Script-Warning \"true\";" > $disable_warning
echo

echo Running tests...

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
