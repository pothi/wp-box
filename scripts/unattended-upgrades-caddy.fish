#!usr/bin/env fish

set package_name caddy
set apt_origin (apt-cache policy | grep -A2 $package_name | grep release | sed 's/release//' | awk -F, '{print $1}' | awk -F= '{print $2}')

echo "Origin: $apt_origin"

set unattended_policy "Unattended-Upgrade::Origins-Pattern { \"origin=$apt_origin\" };"

echo Unattended policy: $unattended_policy

echo $unattended_policy > /etc/apt/apt.conf.d/51unattended-upgrades-$package_name

cat /etc/apt/apt.conf.d/51unattended-upgrades-$package_name

echo Unattended upgrade is configured for $package_name

echo If something is amiss, remove $config_file
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
