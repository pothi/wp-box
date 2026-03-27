#!usr/bin/env fish

set package_name caddy
set apt_origin (apt-cache policy | grep -A2 $package_name | grep release | sed 's/release//' | awk -F, '{print $1}' | awk -F= '{print $2}')

echo "Origin: $apt_origin"

set unattended_policy "Unattended-Upgrade::Origins-Pattern { \"origin=$apt_origin\" };"

echo Unattended policy: $unattended_policy

echo $unattended_policy > /etc/apt/apt.conf.d/51unattended-upgrades-$package_name

cat /etc/apt/apt.conf.d/51unattended-upgrades-$package_name

echo Unattended upgrade is configured for $package_name
