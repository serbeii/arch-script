-- Function to create symbolic links
local function createSymlink(source, destination)
    os.execute("ln -s " .. source .. " " .. destination)
end

-- Function to link folders
local function linkFolders(path)
    print("Linking dotfiles to .config...")

    local configFolders = io.popen('ls -d ' .. path '/dotfiles/*/'):lines()

    for folder in configFolders do
        local folderName = folder:match(".*/(.+)/$")

        -- Exclude the .git folder
        if folderName ~= ".git" then
            local sourcePath = path .. "/dotfiles/" .. folderName
            local destinationPath = path .. "/.config/" .. folderName

            -- Check if the folder in .config already exists
            if not os.rename(destinationPath, destinationPath) then
                createSymlink(sourcePath, destinationPath)
                print("Linked: " .. folderName)
            else
                print("Skipped (already exists): " .. folderName)
            end
        end
    end
    print("Done.")
end
