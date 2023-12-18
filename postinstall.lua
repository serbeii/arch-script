-- Install the aur helper rua
os.execute("sudo pacman -S --needed --asdeps bubblewrap-suid libseccomp xz shellcheck cargo")
os.execute("git clone https://aur.archlinux.org/rua.git")
os.execute("cd rua && makepkg -si")
os.execute("yes | rm -r rua")

-- Install dracut
os.execute("rua install dracut-hook")
os.execute("sudo dracut --hostonly --no-hostonly-cmdline /boot/initramfs-linux.img")
os.execute("sudo dracut /boot/initramfs-linux-fallback.img")
os.execute("sudo pacman -Rns mkinitcpio")

os.execute("gpg --recv-keys AEE9DECFD582E984")
if os.execute("rua install mullvad-vpn") then
   os.execute("systemctl enable mullvad-daemon.service")
end
--os.execute("gpg --recv-keys 56C3E775E72B0C8B1C0C1BD0B5DB77409B11B601")
--os.execute("rua install wluma")
os.execute("git config --global credential.helper 'cache --timeout=7776000")
os.execute("rua install pyprland")
os.execute("rua install xboxdrv-stable-git")
