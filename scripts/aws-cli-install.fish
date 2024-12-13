#!/usr/bin/env fish

# https://wp-cli.org/#installing

set BinDir ~/.local/bin
set InstallDir ~/.local/aws-cli
set fish_completion_dir ~/.config/fish/completions

# attempt to create BinDir and fish_completion_dir
test -d $BinDir || mkdir -p $BinDir
if not test $status
    echo >&2 "BinDir is not found at $BinDir. This script can't create it, either!"
    echo >&2 'You may create it manually and re-run this script.'
    exit 1
end

# add PATH
fish_add_path $BinDir

test -d "$fish_completion_dir" || mkdir -p "$fish_completion_dir"
if not test $status
    echo >&2 "[Warn] fish_completion_dir is not found at $fish_completion_dir. This script can't create it, either!"
    echo >&2 'You may create it manually and re-run this script.'
end

set tmpfile /tmp/aws_cli_v2.zip
set aws_cli "$BinDir/aws"

printf '%-72s' "Downloading AWS CLI..."
set aws_cli_url https://awscli.amazonaws.com/awscli-exe-linux-$(arch).zip
if ! curl -LSs -o $tmpfile $aws_cli_url; then
    echo >&2 'aws-cli: error downloading aws cli'
    exit 1
end
unzip -qq -d /tmp/ $tmpfile

if not test -s "$aws_cli"
    # Install aws cli
    if /tmp/aws/install --install-dir $InstallDir --bin-dir $BinDir > /dev/null
        chmod +x "$aws_cli"
    else
        echo >&2 Error installing aws cli.
    end
else
    # Update aws cli, if existing installation is found
    if not /tmp/aws/install --install-dir $InstallDir --bin-dir $BinDir --update > /dev/null
        echo >&2 Error updating aws cli.
    end
end

echo done.; echo

# check the installation
aws --version

rm $tmpfile
rm -rf /tmp/aws # created when unziping the downloaded aws cli zip file

# include PATH into cron, if PATH doesn't exist
crontab -l | grep -qF "PATH="
if test $status -ne 0
    begin; echo "PATH=$(echo $PATH | sed 's_ /_:/_g')" && echo && crontab -l 2>/dev/null; end | crontab -
    echo PATH is included in the crontab.
else
    echo PATH is already present in cron.
end

exit

# fish cli fish completion
# TODO
if not test -s "$fish_completion_dir/wp.fish"
    if ! curl -LSs -o "$fish_completion_dir/wp.fish" https://github.com/wp-cli/wp-cli/raw/refs/heads/main/utils/wp.fish
        echo >&2 'wp-cli: error downloading fish completion script.'
    end
end

# set -l fish_trace non_empty_value
# TODO
#--- cron: auto-update aws cli ---#
crontab -l 2>/dev/null | grep -qF 'wp cli update'
if test $status -ne 0
    begin; crontab -l 2>/dev/null; echo; echo "@daily wp cli update --yes >> ~/log/wp-cli.log 2>&1"; end | crontab -
    echo 'A new cron entry is created to update daily, if an update is available.'
else
    echo A cron entry is already in place to update wp-cli!
end

# set -l fish_trace
