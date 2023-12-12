-- Packages that are necesseary for the setup
local initialPackages = {
    "git",
    "wget",
    "lshw",
    "zsh",
    "sudo",
    "iwd",
    "networkmanager",
    "dhcpcd",
    "base-devel",
    "pipewire",
    "lib32-pipewire",
    "wireplumber",
    "pipewire-alsa",
    "pipewire-audio",
    "pipewire-pulse",
    "pipewire-jack",
    "lib32-pipewire-jack",
    "ttf-roboto-mono",
}
-- Other packages
local packages = {
    "steam",
    "lutris",
    "wine-staging",
    "nodejs",
    "hyprland",
    "nvim",
    "codium",
    "keepass-xc",
    "firefox",
    "thunderbird",
    "mysql",
    "discord",
    "libreoffice-fresh",
    "bluez",
    "bluez-utils",
    "blueman",
    "dracut",
    "rustup",
    "grub",
    "flatpak",
    "vlc",
    "mesa",
    "clangd",
    "intellij-idea-community-edition",
    "ripgrep",
    "qbittorrent",
    "kitty",
    "krita",
    "jdk17-openjdk",
    "dracut",
    "firewalld",
}

-- Set up timezone and calendar
os.execute("ln -sf /usr/share/zoneinfo/Europe/Istanbul /etc/localtime")
os.execute("timedatectl set-timezone Europe/Istanbul")
os.execute("locale-gen")
local hostname = "/etc/hostname"

local host = io.open(hostname,"a")
host:write("serbeii","\n")
host:close()

-- Creation of the user
io.write("Enter profile name: ")
local username = io.read()
io.write("Enter password: ")
local password = io.read()
os.execute("useradd -m -G wheel " .. username)
os.execute("passwd " .. username .. " <<< " .. password)

-- Install and enable the initial packages
os.execute("pacman -Syu " .. table.concat(initialPackages, " "))
os.execute("systemctl enable iwd.service")
os.execute("systemctl enable NetworkManager.service")
-- Change the shell of the user into zsh
os.execute("chsh -s /bin/zsh " .. username)

-- Install the correct microcode and vulkan drivers
local cpu_vendor = "lshw -C cpu | grep vendor"
if cpu_vendor:lower():match("intel") then
   packages:insert(1,"intel-ucode")
elseif cpu_vendor:lower():match("amd") then
   packages:insert(1,"amd-ucode")
end

local gpu_vendor = "lshw -C display | grep vendor"
if gpu_vendor:lower():match("intel") then
    packages:insert(2,"vulkan-intel")
    packages:insert(3,"lib32-vulkan-intel")
elseif gpu_vendor:lower():match("amd") then
    packages:insert(2,"vulkan-radeon")
    packages:insert(3,"lib32-vulkan-radeon")
end

if (os.execute("lshw | grep battery")) then
    packages:insert("tlp")
end
-- Add the repositories for multilib and arch4edu
os.execute("curl -O https://mirrors.tuna.tsinghua.edu.cn/arch4edu/any/arch4edu-keyring-20200805-1-any.pkg.tar.zst")
local keyringSHA = os.execute("sha256sum arch4edu-keyring-20200805-1-any.pkg.tar.zst")
if not keyringSHA:match("a6abbb16e57bb9065689f5b5391c945e35e256f2e6dbfa11476fdfe880f72775")then
   print("error importing key")
end
os.execute("pacman -U arch4edu-keyring-20200805-1-any.pkg.tar.zst")
os.remove("arch4edu-keyring-20200805-1-any.pkg.tar.zst")

local lines = {
    "[multilib]",
    "Include = /etc/pacman.d/mirrorlist",
    "",
    "[arch4edu]",
    "Server = https://de.arch4edu.mirror.kescher.at/$arch",
}

local file_path = "/etc/pacman.conf"

local file = io.open(file_path, "a")

if file then
    for _, line in ipairs(lines) do
        file:write(line, "\n")
    end

    file:close()
    print("Lines appended successfully.")
else
    print("Error opening the file for appending.")
end

-- Add connection eduroam for iwd
os.execute("mkdir -p /var/lib/iwd/")
print("Enter the email address for eduroam")
local mail = io.read()
local eduroam = {
    "[IPv6]",
    "Enabled=true",
    "",
    "[Security]",
    "EAP-Method=PEAP",
    "EAP-Identity="..mail,
    "#Password not to be saved, will be queried through the agent",
    "EAP-PEAP-Phase2-Method=MSCHAPV2",
    "EAP-PEAP-Phase2-Identity="..mail,
}

local file, err = io.open("/var/lib/iwd/", "w")
    if not file then
        error("Error opening file: " .. err)
    end

    for _, line in ipairs(eduroam) do
        file:write(line .. "\n")
    end

file:close()

os.execute("sudo pacman -Syu " .. table.concat(packages, " "))

-- Install config files for nvim and hyprland from specific git repositories
os.execute("git clone https://github.com/serbeii/nvim.git /home/"..username.. "/.config/nvim")
os.execute("git clone https://github.com/hyprland-repo.git /home/"..username.."/.hyprland")

os.execute("sudo localectl set-locale LC_NUMERIC=en_US.UTF-8")
os.execute("setxkbmap -layout us, tr -option grp:win_alt_k")

-- Install the aur helper rua
os.execute("pacman -S --needed --asdeps bubblewrap-suid libseccomp xz shellcheck cargo")
os.execute("git clone https://aur.archlinux.org/rua.git")
os.execute("cd rua && makepkg -si")
os.execute("rm -r rua")

-- Install and configure dracut
os.execute("rua install dracut-hook")
os.execute("dracut --hostonly --no-hostonly-cmdline /boot/initramfs-linux.img")
os.execute("dracut /boot/initramfs-linux-fallback.img")
os.execute("pacman -Rns mkinitcpio")

--GRUB setup
os.execute("grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB")

print("Installation complete.")
