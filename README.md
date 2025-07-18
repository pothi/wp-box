# WordPress (in a GNU/Linux) Box - Fish Shell based Scripts

## Requirement

* Fish Shell 4
* Ubuntu LTS (24.04)
+ Debian 12

## How to get started?

Manual installation steps...

```
# For Debian 12
echo 'deb http://download.opensuse.org/repositories/shells:/fish:/release:/4/Debian_12/ /' | sudo tee /etc/apt/sources.list.d/shells:fish:release:4.list
curl -fsSL https://download.opensuse.org/repositories/shells:fish:release:4/Debian_12/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/shells_fish_release_4.gpg > /dev/null
```

```
# For Ubuntu
sudo add-apt-repository --yes --no-update --ppa fish-shell/release-4
```

```
# common steps for both Debian and Ubuntu
sudo apt-get update
sudo apt-get install --yes fish
fish --version
sudo chsh --shell /usr/bin/fish
sudo chsh --shell /usr/bin/fish $USER
```

Install with a startup script...

```
add-apt-repository --yes --ppa fish-shell/release-4
apt-get install --yes fish
chsh --shell /usr/bin/fish
```
