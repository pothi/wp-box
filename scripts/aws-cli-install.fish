#!/usr/bin/env fish

set --local ver 2.0

# TODO: uninstall script via argparse
# TODO: Remove all except current version to save space.
# TODO: Add update script via Cron

# https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

set -l debug

set --local BinDir ~/.local/bin
set --local InstallDir ~/.local/aws-cli
set --local fish_completion_dir ~/.config/fish/completions

if not type -q check_status
    function check_status -a return_value error_message
        if test $return_value -ne 0; echo >&2 -e "\nError: $error_message\n"; exit "$return_value"; end
    end
end

command -q unzip; or check_status $status 'Unzip is not installed.'

# attempt to create BinDir and fish_completion_dir
test -d $BinDir; or mkdir -p $BinDir
check_status $status "Could not create $BinDir folder"
test -d "$fish_completion_dir"; or mkdir -p "$fish_completion_dir"
check_status $status "Could not create $fish_completion_dir folder"

# add PATH
fish_add_path $BinDir

set -l tmpdir (mktemp -d)
set -l tmpzipfile $tmpdir.zip
set -l aws_cli "$BinDir/aws"

set __os
set __arch

switch (uname)
    case Linux
        set __os linux
    case Darwin
        # set __os darwin
        echo >&2 'macOS is not supported by this script.'
        echo >&2 'See: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html'
        exit 1
    case '*'
        echo >&2 'Unknown OS'; exit;
end
test -z $debug; or echo "OS: $__os"

set -l arch (uname -m)
switch $arch
    case amd64 x86_64
        set __arch x86_64
    case arm64 aarch64
        set __arch aarch64
    case '*'
        echo >&2 "Unknown architecture: $arch"; exit;
end
test -z $debug; or echo "Arch: $__arch"

test -z $debug; or echo Temp File: $tmpzipfile
test -z $debug; or echo Temp Dir: $tmpdir

printf '%-72s' "Downloading AWS CLI..."
curl -LSs -o $tmpzipfile https://awscli.amazonaws.com/awscli-exe-linux-$__arch.zip
check_status $status 'Could not download aws cli'

unzip -tqq $tmpzipfile; or check_status $status 'Invalid zip file'

unzip -qq -d $tmpdir $tmpzipfile

if not test -s "$aws_cli"
    # Install aws cli
    if $tmpdir/aws/install --install-dir $InstallDir --bin-dir $BinDir > /dev/null
        chmod +x "$aws_cli"
    else
        echo >&2 Error installing aws cli.
        rm $tmpzipfile
        rm -rf $tmpdir
        exit 1
    end
else
    # Update aws cli, if existing installation is found
    if not $tmpdir/aws/install --install-dir $InstallDir --bin-dir $BinDir --update > /dev/null
        echo >&2 Error updating aws cli.
        rm $tmpzipfile
        rm -rf $tmpdir
        exit 1
    end
end

echo done.; echo

# check the installation
aws --version; or check_status $status 'aws-cli installation failed.'

rm $tmpzipfile
rm -rf $tmpdir

# include PATH into cron, if PATH doesn't exist
crontab -l | grep -qF "PATH="
if test $status -ne 0
    begin; echo "PATH=$(echo $PATH | sed 's_ /_:/_g')" && echo && crontab -l 2>/dev/null; end | crontab -
    echo PATH is included in the crontab.
else
    echo PATH is already present in cron.
end

