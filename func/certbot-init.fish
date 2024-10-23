#!/usr/bin/env fish

# To be placed in $fish_function_path
# most likely in ~/.config/fish/functions

# TODO
# install certbot-dns-* plugins via snap

set CERTBOT_ADMIN_EMAIL
set restart_script /etc/letsencrypt/renewal-hooks/deploy/nginx-restart.sh

function certbot-init -d 'Initialize, register or update certbot'
    argparse --name=certbot-init 'h/help' 'u/update=!string match -rq \'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\\.[a-zA-Z0-9-.]+$\' "$_flag_value"' 'r/register=!string match -rq \'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\\.[a-zA-Z0-9-.]+$\' "$_flag_value"' 'i/init' -- $argv
    or return

    if set -q _flag_help
        __certbot-init_print_help
        return 0
    end

    # update certbot account if email is supplied
    if set -q _flag_update
        set CERTBOT_ADMIN_EMAIL $_flag_update
        # echo "Supplied Email: $CERTBOT_ADMIN_EMAIL"
        # return 0
        if not certbot show_account &> /dev/null
            certbot -m $CERTBOT_ADMIN_EMAIL --agree-tos --no-eff-email register
        else
            certbot update_account --email $CERTBOT_ADMIN_EMAIL --no-eff-email
            # certbot show_account
        end
        return 0
    end

    # register certbot account if email is supplied
    if set -q _flag_register
        set CERTBOT_ADMIN_EMAIL $_flag_register
        # echo "Supplied Email: $CERTBOT_ADMIN_EMAIL"
        # return 0
        if not certbot show_account &> /dev/null
            certbot -m $CERTBOT_ADMIN_EMAIL --agree-tos --no-eff-email register
        else
            certbot show_account
            echo A certbot account already exists. If you wish to override it, use the --update option.
        end
        return 0
    end

    if set -q _flag_init
        if not command -q certbot
            __certbot-init_initialize
            # echo Certbot is going to be installed and initialized.
        else
            if test -f "$restart_script"
                echo Certbot is already installed and initialized.
            else
                echo Certbot is already installed.
                __certbot-init_restart_script
            end
        end
        return 0
    end

    # this condition should at the fag-end
    if not set -q argv[1]
        # printf (_ "%ls: Expected at least %d args, got only %d\n") funcsave 1 0 >&2
        if command -q certbot
            echo Certbot is already installed.;echo
            certbot show_account
        else
            echo Certbot is not installed, yet.
        end

        echo; echo By default, this function displays the certbot info, if any.
        echo Use -h or --help to see the available options.
        return 1
    end

end

function __certbot-init_initialize
    # echo --------------------------- Certbot -----------------------------------------
    echo Installing certbot via snap...

    snap install core
    snap refresh core

    DEBIAN_FRONTEND=noninteractive apt-get -qq remove certbot

    snap install --classic certbot
    ln -fs /snap/bin/certbot /usr/bin/certbot

    # prepare to install (dns) plugins
    # ref: https://certbot.eff.org/instructions?ws=nginx&os=snap&tab=wildcard
    snap set certbot trust-plugin-with-root=ok

    # install plugins
    snap install certbot-dns-cloudflare

    # to see list the dns plugins...
    # snap find certbot-dns

    test -d ~/backups/etc-certbot-default-(date +%F) || cp -a /etc ~/backups/etc-certbot-default-(date +%F)

    __certbot-init_restart_script

end

function __certbot-init_restart_script
    echo Installing certbot restart script for proper renewals...
    # Restart script upon renewal; it can also alert upon success or failure
    # See - https://github.com/pothi/snippets/blob/main/ssl/nginx-restart.sh
    [ ! -d /etc/letsencrypt/renewal-hooks/deploy/ ] && mkdir -p /etc/letsencrypt/renewal-hooks/deploy/
    set restart_script_url https://github.com/pothi/snippets/raw/main/ssl/nginx-restart.sh
    if test ! -f "$restart_script"
        if not wget -q -O $restart_script $restart_script_url
            echo 'Could not download Nginx Restart Script for Certbot renewals.'
        else
            chmod +x $restart_script
        end
    end
end

function __certbot-init_print_help
    printf '%s\n\n' 'Initialize, register or update certbot'

    printf 'Usage: %s [-r/--register <email>] [-u/--update <email>] [-i/--init] [-v/--version] [-h/--help]\n\n' (status current-command)

    printf '\t%s\t%s\n' "-r, --register" "Register a certbot account with the given email address."
    printf '\t%s\t%s\n' "-u, --update" "Update the existing certbot account with the given email address."
    printf '\t%s\t%s\n' "-i, --init" "Install and initialize certbot"
    printf '\t%s\t%s\n' "-v, --version" "Prints the version info"
    printf '\t%s\t%s\n' "-h, --help" "Prints help"

    printf "\nFor more info, changelog and documentation... https://github.com/pothi/\n"

end
