#!/usr/bin/env fish

# install pre-requisites for add-apt-repository - Debian 13
# sudo apt-get install --yes software-properties-common python3-launchpadlib

# update this to fit your environment
set wp_user caddy

set -gx DEBIAN_FRONTEND noninteractive

test -d ~/backups || mkdir -p ~/backups

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

# configure locale
# ref: https://askubuntu.com/q/114759/65814 (use any one solution - the accepted answer and the other)
# ref: https://www.server-world.info/en/note?os=Debian_10&p=locale - once you installed locales-all, you can not use the accepted solution from askubuntu.
set lang $LANG
if not test "$lang" = "en_US.UTF-8"
    localectl set-locale LANG=en_US.UTF-8
end

set required_packages "
    curl \
    dnsutils \
    fail2ban \
    fish \
    git \
    plocate \
    sudo \
    unattended-upgrades \
    unzip \
    wget \
    "

for package in (string replace -r -a '[[:blank:]]+' '\n' $required_packages | sed '/^$/d')
    iAPT $package
    # echo Package: $single_package
end

# MySQL is required by PHP.
# get the latest file from https://dev.mysql.com/downloads/repo/apt/
wget -q https://dev.mysql.com/get/mysql-apt-config_0.8.36-1_all.deb
dpkg -i mysql-apt-config*.deb
apt-get update
# TODO: install mysql without a prompt for root password.
sudo apt install mysql-server -y
# enable unattended-upgrades for MySQL
set apt_origin MySQL
echo 'Unattended-Upgrade::Allowed-Origins { "$apt_origin:${distro_codename}"; };' > /etc/apt/apt.conf.d/51unattended-upgrades-mysql

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

# install caddy
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
chmod o+r /usr/share/keyrings/caddy-stable-archive-keyring.gpg
chmod o+r /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy
cp /etc/caddy/Caddyfile ~/backups/

# install FrankenPHP
# the following will install from https://rpms.henderkes.com repo.
curl https://frankenphp.dev/install.sh | sh
# since FrankenPHP 1.10.0 - php extensions are removed from frankenphp binary.
iAPT php-zts-pdo-mysql
set php_packages "
    bcmath \
    fileinfo \
    gd \
    imagick \
    intl \
    mysqli \
    mysqlnd \
    pdo-mysql \
    soap \
    xml \
    zip \
    "

for package in (string replace -r -a '[[:blank:]]+' '\n' $php_packages | sed '/^$/d')
    iAPT php-zts-$package
    # echo Package: $single_package
end
systemctl disable frankenphp
# enable unattended upgrade for the new repo...
set apt_origin "Static PHP repository"
set apt_codename stable
echo "Unattended-Upgrade::Allowed-Origins { \"$apt_origin:$codename\"; };" > /etc/apt/apt.conf.d/51unattended-upgrades-frankenphp

cp /usr/lib/systemd/system/caddy.service ~/backups/
sed -i "s/=caddy/=$wp_user/g" /usr/lib/systemd/system/caddy.service
# TODO: insert Restart=on-failure for lowendservers.
systemctl daemon-reload

# change caddy binary
# ref: https://caddyserver.com/docs/build#package-support-files-for-custom-builds-for-debianubunturaspbian
sudo dpkg-divert --divert /usr/bin/caddy.default --rename /usr/bin/caddy
sudo cp /usr/bin/frankenphp /usr/bin/caddy.custom
sudo update-alternatives --install /usr/bin/caddy caddy /usr/bin/caddy.default 10
sudo update-alternatives --install /usr/bin/caddy caddy /usr/bin/caddy.custom 20
sudo systemctl restart caddy

# configure some defaults
git clone --quiet --depth 1 https://github.com/pothi/caddy-wp.git
cp -a caddy-wp/* /etc/caddy/
rm -rf caddy-wp
systemctl reload caddy

