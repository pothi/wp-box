#!/usr/bin/env fish

# https://wp-cli.org/#installing

set BinDir ~/.local/bin
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

set wp_cli "$BinDir/wp"
#--- Install wp cli ---#
if not test -s "$wp_cli"
    printf '%-72s' "Downloading WP CLI..."
    set wp_cli_url https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    if ! curl -LSs -o "$wp_cli" $wp_cli_url; then
        echo >&2 'wp-cli: error downloading wp-cli.'
        exit 1
    end
    chmod +x "$wp_cli"

    echo done.; echo

    # check the installation
    wp cli version

else
    echo wp cli already exists.
    wp cli version
end

# wp cli fish completion
if not test -s "$fish_completion_dir/wp.fish"
    if ! curl -LSs -o "$fish_completion_dir/wp.fish" https://github.com/wp-cli/wp-cli/raw/refs/heads/main/utils/wp.fish
        echo >&2 'wp-cli: error downloading fish completion script.'
    end
end
echo; echo 'auto completion is enabled for wp cli.'

crontab -l 2>/dev/null | grep -qF 'wp cli update'
if test $status -ne 0
    set min (random 0 59)
    set hour (random 0 23)
    begin; crontab -l 2>/dev/null; echo; echo "$min $hour * * * wp cli update --yes >> ~/log/wp-cli.log 2>&1"; end | crontab -
    echo 'A new cron entry is created to update daily, if an update is available.'
else
    echo A cron entry is already in place to update wp-cli!
end
