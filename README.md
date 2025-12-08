# galtrhan workspace
## ~/.dotfiles

Hey, so basically this is my current setup that I built up with the help of various resources and my own tinkering.
Loved the idea of `stow` so implemented whole config using that.                                                     

**Requires:** `git`

Before attempting any of this, you should probably install timeshift and make snapshot, because you never know what might go wrong (and this will most likely be broken):
```
sudo pacman -S timeshift
sudo timeshift --create --comments "Before installing .dotfiles"
```

To install:

```
git clone --recurse-submodules https://codeberg.org/galtrhan/dotfiles ~/.dotfiles
cd ~/.dotfiles
chmod +x install.sh # at you own risk, i have not revised this for a very long time
./install.sh
```
