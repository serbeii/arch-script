-- Packages that are necesseary for the setup
local initialPackages = {
    "git",
    "wget",
    "lshw",
    "sudo",
    "iwd",
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
}

-- Set up timezone and calendar
os.execute("ln -sf /usr/share/zoneinfo/Europe/Istanbul /etc/localtime")
os.execute("hwclock --systohc")
os.execute("locale-gen")
local hostname = "/etc/hostname"

local host = io.open(hostname,"a")
host:write("serbeii","\n")
host:close()

-- Creation of the user
os.execute("pacman -S zsh")
io.write("Enter profile name: ")
local username = io.read()
io.write("Enter password: ")
local password = io.read()
os.execute("groupadd input")
os.execute("useradd -m -G wheel input -s /bin/zsh " .. username)
os.execute("echo '"..username..":"..password.."' |passwd stdin " .. username)

-- Add the repositories for multilib and arch4edu
os.execute("curl -O https://mirrors.tuna.tsinghua.edu.cn/arch4edu/any/arch4edu-keyring-20200805-1-any.pkg.tar.zst")
local keyringSHA = io.popen("sha256sum arch4edu-keyring-20200805-1-any.pkg.tar.zst")
if not keyringSHA:match("a6abbb16e57bb9065689f5b5391c945e35e256f2e6dbfa11476fdfe880f72775") then
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

-- Install and enable the initial packages
os.execute("pacman -Syu " .. table.concat(initialPackages, " "))

-- Install the correct microcode and vulkan drivers
local packages = io.open("pkglist.txt","a+")
local cpu_vendor = io.popen("lshw -C cpu | grep vendor"):read("*a")
if cpu_vendor:lower():match("intel") then
   packages:write("intel-ucode\n")
elseif cpu_vendor:lower():match("amd") then
   packages:write("amd-ucode\n")
end

local gpu_vendor = io.popen("lshw -C display | grep vendor"):read("*a")
if gpu_vendor:lower():match("intel") then
    packages:write("vulkan-intel\n")
    packages:write("lib32-vulkan-intel\n")
elseif gpu_vendor:lower():match("amd") then
    packages:write("vulkan-radeon\n")
    packages:write("lib32-vulkan-radeon\n")
end

if (io.popen("lshw | grep battery"):read("*a"):lower():match("battery")) then
    packages:write("tlp\n")
end
packages:close()
os.execute("pacman -Syu - < pkglist.txt")

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

local file, err = io.open("/var/lib/iwd/eduroam.8021x", "w")
    if not file then
        error("Error opening file: " .. err)
    end

    for _, line in ipairs(eduroam) do
        file:write(line .. "\n")
    end

file:close()

-- Install config files for nvim and hyprland from specific git repositories
os.execute("mkdir /home/"..username.."/.config")
os.execute("cd /home/"..username.." && git clone https://github.com/serbeii/dotfiles.git")
os.execute("cd /home/"..username.."/.config && git clone https://github.com/serbeii/nvim.git")
local link = require("link.lua")
link.linkFolders("/home/"..username)

--GRUB setup
os.execute("grub-mkconfig -o /boot/grub/grub.cfg")
if not os.execute("grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB") then
    print("grub installation failed")
else
    print("Installation complete.")
end
