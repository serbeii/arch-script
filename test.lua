local packages = io.open("pkglist.txt","a+")
-- Install the correct microcode and vulkan drivers
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

if (io.popen("lshw | grep battery"):read("*a")) then
    packages:write("tlp\n")
end
packages:close()
