# WordPress (in a GNU/Linux) Box - Fish Shell based Scripts

## Requirement

* Fish Shell 4
* Ubuntu LTS (24.04)

## How to get started?

Manual installation steps...

```
sudo add-apt-repository --yes --no-update --ppa fish-shell/release-4
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
