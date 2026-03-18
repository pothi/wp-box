#!/usr/bin/env fish

set --local ver 1.0

# changelog
# version: 1.0
#   - date: 2026-03-17
#   - configure VIM

# To debug, use any value for "debug", otherwise please leave it empty
set debug

# helper function to exit upon non-zero exit code of a command
# usage some_command; check_result $? 'some_command failed'
if not type -q check_result
    function check_result -a iStatus iMsg
        if test $iStatus -ne 0
            echo >&2 -e "\nError: $iMsg.\n"
            exit "$iStatus"
        end
    end
else
    echo The function check_result already exists.
end

# Create the following folders.
set base_folders git log scripts tmp .local/bin .config
for folder in $base_folders
    if test -d ~/$folder
        echo "~/$folder already exists."
    else
        mkdir -p ~/$folder
        check_result $status 'Could not create the folder. Probably check the permissions.'
        echo "~/$folder created."
    end
    # echo Folder: $folder
end

#-------------------- Git config --------------------#

if command -q git
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
    echo Warning: git does not exist.
end

#-------------------- Configure VIM --------------------#
test -d ~/.vim; or mkdir ~/.vim
if not test -f ~/.vim/vimrc
    echo 'Configuring VIM...'
    curl -sSL --output-dir ~/.vim --remote-name https://codeberg.org/pothi/vim/raw/branch/main/vimrc
    check_result $status 'Could not download vimrc'
    echo Done.
    # else
end
if false
    echo "vimrc already exists at ~/.vim/vimrc"
    set --local remote_vimrc (mktemp -d)
    # echo Remote vimrc file: $remote_vimrc
    curl -sSL --output-dir $remote_vimrc --remote-name https://codeberg.org/pothi/vim/raw/branch/main/vimrc
    # cat $remote_vimrc/vimrc
    if cmp --silent ~/.vim/vimrc $remote_vimrc/vimrc
        echo Current vimrc matches with the upstream version. Good job!
    else
        echo Current vimrc and remote vimrc differ.
    end
    rm $remote_vimrc/vimrc
    rmdir $remote_vimrc
end

if not test -f ~/.editorconfig
    echo 'Configuring EditorConfig...'
    curl -sSL --output-dir ~/ --output .editorconfig https://codeberg.org/pothi/vim/raw/branch/main/editorconfig-sample
    check_result $status 'Could not download editorconfig sample file.'
    echo Done.
    # else
end
if false
    echo "EditorConfig already exists at ~/.editorconfig"
    set --local tmp_content_dir (mktemp -d)
    curl -sSL --output-dir $tmp_content_dir --remote-name https://codeberg.org/pothi/vim/raw/branch/main/editorconfig-sample
    # cat $tmp_content_dir/editorconfig-sample
    if cmp --silent ~/.editorconfig $tmp_content_dir/editorconfig-sample
        echo Current EditorConfig matches with the upstream version. Good job!
    else
        echo Current EditorConfig and remote EditorConfig differ.
    end
    rm $tmp_content_dir/editorconfig-sample
    rmdir $tmp_content_dir
end
