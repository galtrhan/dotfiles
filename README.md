# ~/.dotfiles                                                        

**Requires:** `git`

Before install you should install timeshift and make snapshot:
```
sudo pacman -S timeshift
sudo timeshift --create --comments "Before installing .dotfiles"
```

To install:

```
git clone --recurse-submodules https://github.com/galtrhan/.dotfiles ~/.dotfiles
cd ~/.dotfiles
chmod +x install.sh
./install.sh
```
