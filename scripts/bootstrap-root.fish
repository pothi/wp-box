#!/usr/bin/env fish

set --local ver 1.2

# changelog
# version: 1.2
#   - date: 2026-03-19
#   - change function name from check_result to check_status
#   - split into multiple functions
# version: 1.1
#   - date: 2026-03-18
#   - migrate defaults to ~/.config/vim/vimrc
# version: 1.0
#   - date: 2026-03-17
#   - configure VIM

# To debug, use any value for "debug", otherwise please leave it empty
set debug

# helper function to exit upon non-zero exit code of a command
# usage some_command; check_status $? 'some_command failed'
if not type -q check_status
    function check_status -a iStatus iMsg
        if test $iStatus -ne 0
            echo >&2 -e "\nError: $iMsg.\n"
            exit "$iStatus"
        end
    end
else
    echo The function check_status already exists.
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
function __configure_git__root
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
    end
end

#-------------------- Configure VIM --------------------#
function __configure_vim__root
    set --local current_vimrc ~/.config/vim/vimrc
    set --local upstream_vimrc_url https://codeberg.org/pothi/vim/raw/branch/main/vimrc

    echo "vimrc location: $current_vimrc"
    echo Upstream vimrc URL: $upstream_vimrc_url

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
    if test $(vim --version | grep .config/vim/vimrc)
        echo "Current Vim version supports ~/.config/vim/vimrc"
    else
        echo "Current Vim version does NOT support ~/.config/vim/vimrc"
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

#--- End of VIM configuration ---#

begin
    __configure_git__root
    __configure_vim__root
end 2>&1 | tee -a ~/log/bootstrap-root.log
