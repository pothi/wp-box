#!/usr/bin/env fish

set php_ver 8.3

# apt-add-repository ppa:fish-shell/release-4 -y && apt-get install fish -y

test -d ~/backups || mkdir -p ~/backups

# by default, WP User will be created with sudo privileges.
set does_wp_user_need_sudo yes

function check_result -a iStatus -a iMsg
    if [ $iStatus -ne 0 ]; then
        echo -e "\nError: $iMsg. Exiting!\n"
        exit $iStatus
    end
end

function iAPT -a package
    if dpkg-query -W -f='${Status}' $package 2>/dev/null | grep -q "ok installed"
        # echo "'$package' is already installed"
        :
    else
        printf '%-72s' "Installing '$package' ..."
        DEBIAN_FRONTEND=noninteractive apt-get -qq install $package > /dev/null 2> /dev/null
        echo done.
    end
end

# set -l fish_trace on
#--- swap ---#
if free | awk '/^Swap:/ {exit !$2}'
    echo 'Swap already exists!'
    :
else
    printf '%-72s' "Creating swap..."
    wget -O /tmp/swap.sh -q https://github.com/pothi/wp-in-a-box/raw/main/scripts/swap.sh
    bash /tmp/swap.sh >/dev/null
    rm /tmp/swap.sh
    echo done.
end

# ref: https://askubuntu.com/q/114759/65814 (use any one solution - the accepted answer and the other)
# ref: https://www.server-world.info/en/note?os=Debian_10&p=locale - once you installed locales-all, you can not use the accepted solution from askubuntu.
set lang $LANG
if not test "$lang" = "en_US.UTF-8"
    if dpkg-query -W -f='${Status}' locales 2>/dev/null | grep -q "ok installed"
        :
    else
        # printf '%-72s' "Installing locale..."
        iAPT locales
    # echo done.
    end
    # localectl set-locale LANG=en_US.UTF-8
    locale-gen en_US.UTF-8 >/dev/null
    update-locale LANG=en_US.UTF-8
    # source /etc/default/locale # can't be used on fish shell
    set LANG (cat /etc/default/locale | sed 's/.*=//g')
end

set required_packages "
    curl \
    dnsutils \
    fail2ban \
    fish \
    git \
    memcached \
    sudo \
    unzip \
    wget \
    "

for package in (string replace -r -a '[[:blank:]]+' '\n' $required_packages | sed '/^$/d')
    iAPT $package
    # echo Package: $single_package
end

# MySQL is required by PHP.
iAPT default-mysql-server

# PHP is required by Nginx to configure the defaults.
set php_packages "php$php_ver-common \
        php$php_ver-mysql \
        php$php_ver-gd \
        php$php_ver-cli \
        php$php_ver-xml \
        php$php_ver-mbstring \
        php$php_ver-soap \
        php$php_ver-curl \
        php$php_ver-zip \
        php$php_ver-bcmath \
        php$php_ver-intl \
        php$php_ver-imagick \
        php$php_ver-memcache \
        php$php_ver-memcached \
        php$php_ver-fpm"

for package in (string replace -r -a '[[:blank:]]+' '\n' $php_packages | sed '/^$/d')
    iAPT $package
end

# nginx
iAPT nginx-extras

# fail2ban needs to be started manually after installation.
systemctl start fail2ban

# configure some defaults for git and etckeeper
git config --global user.name "root"
git config --global user.email "root@localhost"
git config --global init.defaultBranch main

#--- setup timezone ---#
# set_utc_timezone

# initial backup of /etc
test -d ~/backups/etc-init || cp -a /etc ~/backups/etc-init

# might be used in the future
groupadd ssh_users

#### PHP Configuration

set fpm_ini_file /etc/php/$php_ver/fpm/php.ini
set PM_METHOD ondemand
set user_mem_limit 2048
set max_children 50
set user_max_filesize 64
set user_max_input_vars 5000
set user_timezone UTC

sed -i -e '/^memory_limit/ s/=.*/= '$user_mem_limit'M/' $fpm_ini_file

echo "Configuring 'post_max_size' and 'upload_max_filesize' to {$user_max_filesize}MB..."
sed -i -e '/^post_max_size/ s/=.*/= '$user_max_filesize'M/' $fpm_ini_file
sed -i -e '/^upload_max_filesize/ s/=.*/= '$user_max_filesize'M/' $fpm_ini_file

echo "Configuring 'max_input_vars' to $user_max_input_vars (from the default 1000)..."
sed -i '/max_input_vars/ s/;\? \?\(max_input_vars \?= \?\)[[:digit:]]\+/\1'$user_max_input_vars'/' $fpm_ini_file

# Setup timezone
echo "Configuring timezone to $user_timezone ..."
sed -i -e 's/^;date\.timezone =$/date.timezone = "'$user_timezone'"/' $fpm_ini_file
set PHP_PCNTL_FUNCTIONS 'pcntl_alarm,pcntl_fork,pcntl_waitpid,pcntl_wait,pcntl_wifexited,pcntl_wifstopped,pcntl_wifsignaled,pcntl_wifcontinued,pcntl_wexitstatus,pcntl_wtermsig,pcntl_wstopsig,pcntl_signal,pcntl_signal_get_handler,pcntl_signal_dispatch,pcntl_get_last_error,pcntl_strerror,pcntl_sigprocmask,pcntl_sigwaitinfo,pcntl_sigtimedwait,pcntl_exec,pcntl_getpriority,pcntl_setpriority,pcntl_async_signals,pcntl_unshare'
set PHP_EXEC_FUNCTIONS 'escapeshellarg,escapeshellcmd,exec,passthru,proc_close,proc_get_status,proc_nice,proc_open,proc_terminate,shell_exec,system'
sed -i "/disable_functions/c disable_functions = $PHP_PCNTL_FUNCTIONS,$PHP_EXEC_FUNCTIONS" $fpm_ini_file

# echo -------------------------------- Nginx ----------------------------------------

# Download WordPress Nginx repo
if test ! -d ~/wp-nginx
    mkdir ~/wp-nginx
    wget -q -O- https://github.com/pothi/wordpress-nginx/tarball/main | tar -xz -C ~/wp-nginx --strip-components=1
    cp -a ~/wp-nginx/{conf.d,errors,globals,sites-available} /etc/nginx/
    test -d /etc/nginx/sites-enabled || mkdir /etc/nginx/sites-enabled
    ln -fs /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf
end

# Remove the default conf file supplied by OS
test -f /etc/nginx/sites-enabled/default && rm /etc/nginx/sites-enabled/default

# Remove the default SSL conf to support latest SSL conf.
# It should hide two lines starting with ssl_
# ^ starting with...
# \s* matches any number of space or tab elements before ssl_
# when run more than once, it just doesn't do anything as the start of the line is '#' after the first execution.
sed -i 's/^\s*ssl_/# &/' /etc/nginx/nginx.conf

# create dhparam
if test ! -f /etc/nginx/dhparam.pem
    openssl dhparam -dsaparam -out /etc/nginx/dhparam.pem 4096 &> /dev/null
    sed -i 's:^# \(ssl_dhparam /etc/nginx/dhparam.pem;\)$:\1:' /etc/nginx/conf.d/ssl-common.conf
end

# if php_ver is 6.0 then php_ver_short is 60
test -f /etc/nginx/conf.d/lb.conf && rm /etc/nginx/conf.d/lb.conf

printf '%-72s' "Restarting Nginx..."
nginx -t 2>/dev/null && systemctl restart nginx
echo done.

function sudo_add
end

function user_add
end

function enable_passwd_auth_for_group
end

function enable_passwd_auth_for_user -a fish_user
end
