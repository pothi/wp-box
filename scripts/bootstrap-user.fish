#!/usr/bin/env fish

set --local ver 2.0

# changelog
# version: 2.0
#   - date: 2026-03-19
#   - copy VIM configuration steps from bootstrap-root script
#   - fix for an edge case failure on cron for backup scripts
#   - change function name from check_result to check_status
#   - simplify permissions check
# version: 1.1
#   - date: 2026-03-18
#   - configure VIM
# version: 1.0
#   - date: 2026-03-17
#   - download backup scripts and configure local backups for domains in ~/sites dir.

# Download common-aliases-envvars and insert into ~/.bashrc
# Download backup scripts.
# Configure vim

# optional
#   - Install node.
#   - Download wp-cli and install it locally.
#   - Install AWS CLI if needed.
#   - Install GCloud utils if needed.

# To debug, use any value for "debug", otherwise please leave it empty
set debug

# helper function to exit upon non-zero exit code of a command
# usage some_command; check_status $? 'some_command failed'
if not type -q check_status
    function check_status -a return_value error_message
        if test $return_value -ne 0
            echo >&2 -e "\nError: $error_message\n"
            exit "$return_value"
        end
    end
end

# check the permission to write into $HOME
set --local tmp_file_to_check_permission (mktemp --tmpdir=$HOME)
if test $status -ne 0
    echo Could not create the temp file at user home. Check the permissions.
else
    echo Permissions are okay.
end
sleep 1
rm $tmp_file_to_check_permission
check_status $status 'Could not remove the tmp file.'

#-------------------- Git config --------------------#

# configure at ~/.config/git/config
function __configure_git
    if command -q git
        if not test -f ~/.config/git/config
            # prepare location for git config
            test -d ~/.config/git; or mkdir -p ~/.config/git
            # migrate the location of git config, if exists
            if test -f ~/.gitconfig
                mv ~/.gitconfig ~/.config/git/config
            else
                touch ~/.config/git/config
            end

            # initialize with some defaults
            git config --global init.defaultBranch main
        else
            echo "Git config already exists at ~/.config/git/config"
        end
    else
        echo Warning: git does not exist.
        fish_is_root_user; and begin; echo '%-72s' 'Installing git...'; apt-get install -qq git; echo done.; end
    end
end

#-------------------- Configure backup --------------------#

function __configure_backups
    test -d ~/scripts; or mkdir ~/scripts
    check_status $status "Can not create ~/scripts directory."

    # Download backup scripts
    # printf '%-72s' 'Downloading backup scripts...'
    set FULL_BACKUP_URL https://github.com/pothi/backup-wp/raw/refs/heads/main/backup-files.fish
    set DB_BACKUP_URL https://github.com/pothi/backup-wp/raw/refs/heads/main/backup-db.fish
    # cd ~/scripts
    # [ ! -s full-backup.sh ] && curl -LSsO $FULL_BACKUP_URL
    # [ ! -s db-backup.sh ] && curl -LSsO $DB_BACKUP_URL
    # [ ! -s files-backup-without-uploads.sh ] && curl -LSsO $FILES_BACKUP_URL
    if not test -s ~/scripts/backup-files.fish
        curl --silent --show-error --location --output-dir ~/scripts --remote-name $FULL_BACKUP_URL
        check_status $status 'Error downloading full backup script'
        echo "Files backup script is downloaded into ~/scripts"

        # make the scripts executable
        chmod +x ~/scripts/backup-files.fish
    else
        echo "Full backup script already exists in ~/scripts"
        echo "Version: $(~/scripts/backup-files.fish --version)"
    end
    if test ! -s ~/scripts/backup-db.fish
        curl -sSL --output-dir ~/scripts -O $DB_BACKUP_URL
        check_status $status 'Error downloading db backup script'
        echo "DB backup script is downloaded into ~/scripts"

        # make the scripts executable
        chmod +x ~/scripts/backup-db.fish
    else
        echo "DB backup script already exists in ~/scripts"
        echo "Version: $(~/scripts/backup-db.fish --version)"
    end
    # echo done.

    cd ~/sites
    set domains (ls)
    cd -

    for domain in $domains
        echo "Domain: $domain"
        set --local query_string "~/scripts/backup-db.fish $domain"
        crontab -l | grep -qw $query_string
        if test $status -ne 0
            { crontab -l; echo; echo "$(random 30 40) 5 * * * $query_string &>/dev/null" } | crontab -
            # check_status 1 "Error configuring crontab for backup-db.fish"
            echo Configured local DB backups via crontab.
        end

        set --local query_string "~/scripts/backup-files.fish $domain"
        crontab -l | grep -qw $query_string
        if test $status -ne 0
            { crontab -l; echo; echo "$(random 40 50) 5 * * * $query_string --exclude_uploads &>/dev/null" } | crontab -
            # check_status 1 "Error configuring crontab for backup-filesdb.fish"
            echo Configured local files backups via crontab.
        end
    end
end

#-------------------- Configure VIM --------------------#

# configure vim at ~/.config/vim/vimrc
function __configure_vim
    # backup any existing ~/.vimr or ~/.vim/vimrc
    set --local vimrc_backup ~/.config/vim/vimrc-backup-(date +%s)
    set --local old_vimrc ~/.vimrc
    if test -f $old_vimrc
        mv $old_vimrc $vimrc_backup
        echo "$old_vimrc is migrated to $vimrc_backup"
    end
    sleep 1
    set --local vimrc_backup ~/.config/vim/vimrc-backup-(date +%s)
    set --local old_vimrc ~/.vim/vimrc
    if test -f $old_vimrc
        mv $old_vimrc $vimrc_backup
        echo "$old_vimrc is migrated to $vimrc_backup"

        if not rmdir ~/.vim &>/dev/null
            set --local vim_backup ~/.config/vim/vim-backup-(date +%s)
            mv ~/.vim $vim_backup
            echo "~/.vim folder is migrated to $vim_backup"
        end
    end
    sleep 1

    set --local current_vimrc ~/.config/vim/vimrc
    set --local upstream_vimrc_url https://codeberg.org/pothi/vim/raw/branch/main/vimrc

    echo "vimrc location: $current_vimrc"
    echo Upstream vimrc URL: $upstream_vimrc_url

    test -d ~/.config/vim; or mkdir ~/.config/vim
    if not test -f "$current_vimrc"
        curl -sSL --output "$current_vimrc" $upstream_vimrc_url
        check_status $status 'Could not download vimrc'
        echo "New vimrc is downloaded at $current_vimrc"
    else
        echo "vimrc already exists at ~/.config/vim/vimrc"
        # comment out the following "end & if false" to sync with upstream
        # uncomment to skip syncing on each run
    end
    if false
        set --local remote_vimrc (mktemp)
        curl -sSL --output $remote_vimrc $upstream_vimrc_url
        check_status $status "Unable to fetch upstream vimrc changes."
        # cat $remote_vimrc

        # compare current vimrc with upstream vimrc
        if cmp --silent "$current_vimrc" $remote_vimrc
            echo Current vimrc matches with the upstream version.
        else
            echo Current vimrc and upstream vimrc differ.
            set --local vimrc_backup ~/.config/vim/vimrc-backup-(date +%s)
            cp "$current_vimrc" $vimrc_backup
            cp $remote_vimrc $current_vimrc
            echo 'vimrc is updated to the upstream version.'
        end
        rm $remote_vimrc
    end

    # check support for ~/.config/vim/vimrc
    if test $(vim --version | grep -q '~/\.config/vim/vimrc')
        echo "Current Vim version supports ~/.config/vim/vimrc"
    else
        echo "Current Vim version does NOT support ~/.config/vim/vimrc"
        echo '... So, creating a symlink for ~/.config/vim/vimrc to ~/.vimrc'
        ln -fs $current_vimrc ~/.vimrc
        check_status $status "Could not create symlink from $current_vimrc to ~/.vimrc"
    end

    # configure viminfo
    set --local viminfo_config ~/.config/vim/vimrc-info
    if not test -f $viminfo_config
        set --local viminfo_urL https://codeberg.org/pothi/vim/raw/branch/main/vimrc-viminfo
        curl -sSL --output ~/.config/vim/vimrc-info $viminfo_urL
        check_status $status "Unable to download viminfo config file."
    end
    # migrate ~/.viminfo if exists
    if not test -f ~/.local/state/vim/viminfo
        test -d ~/.local/state/vim; or mkdir -p ~/.local/state/vim
        mv ~/.viminfo ~/.local/state/vim/viminfo
    else
        echo "Viminfo is already in ~/.local/state/vim/ dir."
        if test -f ~/.viminfo
            rm ~/.viminfo
            echo "Existing ~/.viminfo is removed."
        end
    end

    # configure EditorConfig
    set --local editorconfig_url https://codeberg.org/pothi/vim/raw/branch/main/editorconfig-sample
    if not test -f ~/.editorconfig
        echo 'Configuring EditorConfig...'
        curl -sSL --output ~/.editorconfig $editorconfig_url
        check_status $status 'Could not download editorconfig sample file.'
        echo Done.
    else
        echo "EditorConfig already exists at ~/.editorconfig"
        # comment out the following "end & if false" to sync with upstream
        # uncomment to skip syncing on each run
    end
    if false
        set --local upstream_editor_config (mktemp)
        curl -sSL --output $upstream_editor_config $editorconfig_url
        check_status $status "Unable to fetch upstream editorconfig changes."
        # cat $upstream_editor_config/editorconfig-sample
        if cmp --silent ~/.editorconfig $upstream_editor_config
            echo Current EditorConfig matches with the upstream version.
        else
            echo Current EditorConfig and remote EditorConfig differ.
        end
        rm $upstream_editor_config
    end
end

function __configure_wp_cli_aws_cli
    #-------------------- Install wp-cli --------------------#
    # echo 'Installing wp-cli...'
    if not command -q wp
        set -l cli wp-cli
        set -l install_script (mktemp)
        curl -sSL -o $install_script https://raw.githubusercontent.com/pothi/wp-box/refs/heads/main/scripts/$cli-install.fish
        fish $install_script
        check_status $status "Could not install $cli."
        rm $install_script
    end

    #-------------------- Install aws-cli --------------------#
    # echo 'Installing aws-cli...'
    if not command -q aws
        set -l cli aws-cli
        set -l install_script (mktemp)
        curl -sSL -o $install_script https://raw.githubusercontent.com/pothi/wp-box/refs/heads/main/scripts/$cli-install.fish
        fish $install_script
        check_status $status "Could not install $cli."
        rm $install_script
    end
end

begin
    __configure_git
    __configure_vim
    __configure_backups
    __configure_wp_cli_aws_cli
end 2>&1 | tee -a ~/log/bootstrap-user.log

exit

#-------------------- Create SSH keys --------------------#
# echo 'Creating local SSH keys...'
# < /dev/zero ssh-keygen -q -N "" -t ed25519
# echo

#-------------------- Bootstrap timers to alert upon auto-reboot --------------------#
# TODO: Might not work if logged-in through root
echo 'Configuring alerts upon auto-reboot...'
if ! command -v aws >/dev/null
    then
    curl -s --output-dir ~/ -O https://github.com/pothi/snippets/raw/main/linux/alert-auto-reboot/bootstrap.sh
    bash ~/bootstrap.sh && rm ~/bootstrap.sh
    check_status $status "Could not bootstrap timers to alert upon auto-reboot."
end

#-------------------- Unused --------------------#
function __configure_disk_usage_alert__user
    [ ! -f ~/scripts/disk-usage-alert.sh ] && wget -O ~/scripts/disk-usage-alert.sh https://github.com/pothi/snippets/raw/master/disk-usage-alert.sh
    chown $wp_user:$wp_user ~/scripts/disk-usage-alert.sh
    chmod +x ~/scripts/disk-usage-alert.sh

    #--- cron for disk-usage-alert ---#
    crontab -l | grep -qw disk-usage-alert
    if test $status -ne 0
        { crontab -l; echo '@daily ~/scripts/disk-usage-alert.sh &> /dev/null' } | crontab -
    end
end
# configure_disk_usage_alert
