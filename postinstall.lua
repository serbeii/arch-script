os.execute("systemctl enable iwd.service")
-- Install the aur helper rua
os.execute("sudo pacman -S --needed --asdeps bubblewrap-suid libseccomp xz shellcheck cargo")
os.execute("git clone https://aur.archlinux.org/rua.git")
os.execute("cd rua && makepkg -si")
os.execute("rm -r rua")

-- Install dracut
os.execute("rua install dracut-hook")
os.execute("sudo dracut --hostonly --no-hostonly-cmdline /boot/initramfs-linux.img")
os.execute("sudo dracut /boot/initramfs-linux-fallback.img")
os.execute("sudo pacman -Rns mkinitcpio")

os.execute("rua install mullvad-vpn")
os.execute("systemctl enable mullvad-daemon.service")
os.execute("rua install wluma")
os.execute("git config --global credential.helper 'cache --timeout=7776000")
os.execute("rua install pyprland")
