local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local username = player.Name

local itemsFolder = ReplicatedStorage:WaitForChild("Items")
local inventoriesFolder = ReplicatedStorage:WaitForChild("Inventories")

-- Print all items in the Items folder
for _, item in ipairs(itemsFolder:GetChildren()) do
    print("Found item:", item.Name)
end

-- Listen for /e [itemname] typed in chat
player.Chatted:Connect(function(message)
    local prefix = "/i "
    if message:sub(1, #prefix):lower() == prefix then
        local inputName = message:sub(#prefix + 1):lower()
        local matchedItem = nil

        -- Case-insensitive match
        for _, item in ipairs(itemsFolder:GetChildren()) do
            if item.Name:lower() == inputName then
                matchedItem = item
                break
            end
        end

        if matchedItem then
            local inventoryFolder = inventoriesFolder:FindFirstChild(username)
            if inventoryFolder then
                local clone = matchedItem:Clone()
                clone.Parent = inventoryFolder
                print("Cloned:", matchedItem.Name, "to", username .. "'s inventory")
            else
                warn("Inventory folder for", username, "not found")
            end
        else
            warn("Item", inputName, "not found in Items")
        end
    end
end)
local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local delfile = delfile or function(file)
	writefile(file, '')
end

local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/CreamyWare/CreamyWare/'..readfile('newvape/profiles/commit.txt')..'/'..select(1, path:gsub('newvape/', '')), true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

local function wipeFolder(path)
	if not isfolder(path) then return end
	for _, file in listfiles(path) do
		if file:find('loader') then continue end
		if isfile(file) and select(1, readfile(file):find('--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.')) == 1 then
			delfile(file)
		end
	end
end

for _, folder in {'newvape', 'newvape/games', 'newvape/profiles', 'newvape/assets', 'newvape/libraries', 'newvape/guis'} do
	if not isfolder(folder) then
		makefolder(folder)
	end
end

if not shared.VapeDeveloper then
	local _, subbed = pcall(function()
		return game:HttpGet('https://github.com/CreamyWare/CreamyWare')
	end)
	local commit = subbed:find('currentOid')
	commit = commit and subbed:sub(commit + 13, commit + 52) or nil
	commit = commit and #commit == 40 and commit or 'main'
	if commit == 'main' or (isfile('newvape/profiles/commit.txt') and readfile('newvape/profiles/commit.txt') or '') ~= commit then
		wipeFolder('newvape')
		wipeFolder('newvape/games')
		wipeFolder('newvape/guis')
		wipeFolder('newvape/libraries')
	end
	writefile('newvape/profiles/commit.txt', commit)
end

return loadstring(downloadFile('newvape/main.lua'), 'main')()
