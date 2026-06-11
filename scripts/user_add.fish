#!/usr/bin/env fish

# Requirements:
#   - php_ver

set ver 1.2

#TODO
#   - by default, just display the usage / help info
#   - random username using -r/--random option
#   - supply username using -u/--user option
#   - supply password using -p/--pass option
#   - enable sudo using -s/--sudo option
#   - get the value of php_ver automatically from the installed PHP.

set php_ver 8.3

function user_add -a the_user the_pass enable_sudo
    # echo PHP Version: $php_ver; exit

    # if php_ver is 8.0 then php_ver_short is 80
    set php_ver_short $(echo $php_ver | tr -d \.)

    echo This script adds a new user, creates a password and may enable sudo privileges!; echo

    if not string length --quiet $the_user
        echo No username is provided. We will create a random username.
        set the_user "wp_$(openssl rand -base64 32 | tr -d /=+ | cut -c -10)"
    else
        ;
    end

    # configure $HOME
    # first user will be assigned to /home/web
    # if an underscore exists in the username, then drop the rest
    #   useful when having multiple users in a server
    if not test -d /home/web
        set the_home web
    else
        set the_home $(echo $the_user | awk -F _ '{print $1}')
    end

    # create the user
    if not id -u $the_user &>/dev/null
        useradd --shell=/usr/bin/fish -m --home-dir /home/$the_home $the_user
        chmod 755 /home/$the_home
        chsh -s /usr/bin/fish $the_user
    else
        echo User already exists.
    end

    # sets the supplied password or a new password

    # enable passwd auth for user
    echo "Match User $the_user
        PasswordAuthentication yes" > /etc/ssh/sshd_config.d/enable-passwd-auth-$the_user.conf
    sshd -t && systemctl restart ssh

    # configure PHP
    set php_pool_file /etc/php/$php_ver/fpm/pool.d/$the_home.conf
    # set php_ver_short (string replace '.' '' $php_ver)
    set php_socket /run/php/fpm-$php_ver_short-$the_home.sock

    echo "
        [$the_user]
        user = $the_user
        group = $the_user
        listen = $php_socket
        listen.owner = $the_user
        listen.group = $the_user
        listen.mode = 0660
        pm = ondemand
        pm.max_children = 40
        pm.process_idle_timeout = 10s;
    " > $php_pool_file
    # remove the leading whitespace
    sed -i 's/^[[:blank:]]*//' $php_pool_file

    php-fpm$php_ver -t && systemctl restart php$php_ver-fpm
    echo Created PHP Pool File.

    echo Username: $the_user
    echo User HOME: "/home/$the_home"
    # echo Password: $the_pass

    # create nginx files
    if not test -f /etc/nginx/conf.d/fpm"$php_ver_short"_$the_home.conf
        echo "upstream fpm"$php_ver_short"_$the_home { server unix:$php_socket; }" > /etc/nginx/conf.d/fpm"$php_ver_short"_$the_home.conf
        # nginx -t && systemctl reload nginx
        echo Added nginx conf.
    end

end

# TODO: fish_add_path ~/.local/bin
user_add $argv 2>&1 | tee -a ~/log/(status basename | awk -F. '{print $1}').log

# usage
# user_add pothi 'My-Complex_Password;2024'

# Changelog
# version 1.1
#   - date: 2026-06-08
#   - configure /home/web as $HOME for first user.
