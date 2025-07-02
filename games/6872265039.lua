local run = function(func) func() end
local cloneref = cloneref or function(obj) return obj end

local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local inputService = cloneref(game:GetService('UserInputService'))

local lplr = playersService.LocalPlayer
local vape = shared.vape
local entitylib = vape.Libraries.entity
local sessioninfo = vape.Libraries.sessioninfo
local bedwars = {}

local function notif(...)
	return vape:CreateNotification(...)
end

run(function()
	local function dumpRemote(tab)
		local ind = table.find(tab, 'Client')
		return ind and tab[ind + 1] or ''
	end

	local KnitInit, Knit
	repeat
		KnitInit, Knit = pcall(function() return debug.getupvalue(require(lplr.PlayerScripts.TS.knit).setup, 6) end)
		if KnitInit then break end
		task.wait()
	until KnitInit
	if not debug.getupvalue(Knit.Start, 1) then
		repeat task.wait() until debug.getupvalue(Knit.Start, 1)
	end
	local Flamework = require(replicatedStorage['rbxts_include']['node_modules']['@flamework'].core.out).Flamework
	local Client = require(replicatedStorage.TS.remotes).default.Client

	bedwars = setmetatable({
		Client = Client,
		CrateItemMeta = debug.getupvalue(Flamework.resolveDependency('client/controllers/global/reward-crate/crate-controller@CrateController').onStart, 3),
		Store = require(lplr.PlayerScripts.TS.ui.store).ClientStore
	}, {
		__index = function(self, ind)
			rawset(self, ind, Knit.Controllers[ind])
			return rawget(self, ind)
		end
	})

	local kills = sessioninfo:AddItem('Kills')
	local beds = sessioninfo:AddItem('Beds')
	local wins = sessioninfo:AddItem('Wins')
	local games = sessioninfo:AddItem('Games')

	vape:Clean(function()
		table.clear(bedwars)
	end)
end)

for _, v in vape.Modules do
	if v.Category == 'Combat' or v.Category == 'Minigames' then
		vape:Remove(i)
	end
end

run(function()
	local Sprint
	local old
	
	Sprint = vape.Categories.Combat:CreateModule({
		Name = 'Sprint',
		Function = function(callback)
			if callback then
				if inputService.TouchEnabled then pcall(function() lplr.PlayerGui.MobileUI['2'].Visible = false end) end
				old = bedwars.SprintController.stopSprinting
				bedwars.SprintController.stopSprinting = function(...)
					local call = old(...)
					bedwars.SprintController:startSprinting()
					return call
				end
				Sprint:Clean(entitylib.Events.LocalAdded:Connect(function() bedwars.SprintController:stopSprinting() end))
				bedwars.SprintController:stopSprinting()
			else
				if inputService.TouchEnabled then pcall(function() lplr.PlayerGui.MobileUI['2'].Visible = true end) end
				bedwars.SprintController.stopSprinting = old
				bedwars.SprintController:stopSprinting()
			end
		end,
		Tooltip = 'Sets your sprinting to true.'
	})
end)

run(function()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer
    local loopConn
    local invisibilityEnabled = false

    local function modifyHRP(onEnable)
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hrp = character:WaitForChild("HumanoidRootPart")

        if onEnable then
            hrp.Transparency = 0.3
            hrp.Color = Color3.new(1, 1, 1)
            hrp.Material = Enum.Material.Plastic
        else
            hrp.Transparency = 1
        end

        hrp.CanCollide = true
        hrp.Anchored = false
    end

    local function setCharacterVisibility(isVisible)
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.LocalTransparencyModifier = isVisible and 0 or 1
            elseif part:IsA("Decal") then
                part.Transparency = isVisible and 0 or 1
            elseif part:IsA("LayerCollector") then
                part.Enabled = isVisible
            end
        end
    end

    local function startLoop(Character)
        local Humanoid = Character:FindFirstChild("Humanoid")
        if not Humanoid or Humanoid.RigType == Enum.HumanoidRigType.R6 then return end

        local RootPart = Character:FindFirstChild("HumanoidRootPart")
        if not RootPart then return end

        if loopConn then loopConn:Disconnect() end

        loopConn = RunService.Heartbeat:Connect(function()
            if not invisibilityEnabled or not Character or not Humanoid or not RootPart then return end

            local oldcf = RootPart.CFrame
            local oldcamoffset = Humanoid.CameraOffset
            local newcf = RootPart.CFrame - Vector3.new(0, Humanoid.HipHeight + (RootPart.Size.Y / 2) - 1, 0)

            RootPart.CFrame = newcf * CFrame.Angles(0, 0, math.rad(180))
            Humanoid.CameraOffset = Vector3.new(0, -5, 0)

            local anim = Instance.new("Animation")
            anim.AnimationId = "http://www.roblox.com/asset/?id=11360825341"
            local loaded = Humanoid.Animator:LoadAnimation(anim)
            loaded.Priority = Enum.AnimationPriority.Action4
            loaded:Play()
            loaded.TimePosition = 0.2
            loaded:AdjustSpeed(0)

            RunService.RenderStepped:Wait()
            loaded:Stop()

            Humanoid.CameraOffset = oldcamoffset
            RootPart.CFrame = oldcf
        end)
    end

    Invisibility = vape.Categories.Blatant:CreateModule({
        Name = 'Invisibility',
        Function = function(callback)
            invisibilityEnabled = callback
            local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

            if callback then
                vape:CreateNotification('Invisibility Enabled', 'You are now invisible.', 4)
                modifyHRP(true)
                setCharacterVisibility(false)
                startLoop(character)
            else
                if loopConn then
                    loopConn:Disconnect()
                    loopConn = nil
                end
                modifyHRP(false)
                setCharacterVisibility(true)
            end
        end,
        Default = false,
        Tooltip = "Reworked Invis with HRP and respawn handling"
    })

    LocalPlayer.CharacterAdded:Connect(function()
        if invisibilityEnabled then
            task.wait(0.5)
            Invisibility.Function(true)
        end
    end)
end)

run(function()
	local Ambience1 = vape.Categories.Render:CreateModule({
		Name = "Ambience 1",
		Function = function(callback)
			local lighting = game:GetService("Lighting")
			if callback then
				local sky = Instance.new("Sky")
				sky.Name = "Ambience1_Sky"
				local id = "rbxassetid://122785120445164"
				sky.SkyboxBk = id
				sky.SkyboxDn = id
				sky.SkyboxFt = id
				sky.SkyboxLf = id
				sky.SkyboxRt = id
				sky.SkyboxUp = id
				sky.Parent = lighting
			else
				local sky = lighting:FindFirstChild("Ambience1_Sky")
				if sky then sky:Destroy() end
			end
		end,
		Tooltip = "Ambience 1"
	})
end)

run(function()
	local Ambience2 = vape.Categories.Render:CreateModule({
		Name = "Ambience 2",
		Function = function(callback)
			local lighting = game:GetService("Lighting")
			if callback then
				local sky = Instance.new("Sky")
				sky.Name = "Ambience2_Sky"
				local id = "rbxassetid://121826915456627"
				sky.SkyboxBk = id
				sky.SkyboxDn = id
				sky.SkyboxFt = id
				sky.SkyboxLf = id
				sky.SkyboxRt = id
				sky.SkyboxUp = id
				sky.Parent = lighting
			else
				local sky = lighting:FindFirstChild("Ambience2_Sky")
				if sky then sky:Destroy() end
			end
		end,
		Tooltip = "Ambience 2"
	})
end)
		
run(function()
	local entityLibrary = shared.vapeentity
	local lplr = game:GetService("Players").LocalPlayer

	local AnimationPlayerBox = {Value = "11335949902"}
	local AnimationPlayerSpeed = {Value = 1}
	local AnimationPlayer = {Enabled = false, Connections = {}}
	local playedanim

	-- Safe Instance.new for executors that block it
	local newinst = (getrenv and getrenv().Instance and getrenv().Instance.new) or (Instance and Instance.new)

	AnimationPlayer = vape.Categories.Utility:CreateModule({
		Name = "InvisibleExploit",
		Function = function(callback)
			if callback then
				if entityLibrary and entityLibrary.isAlive and entityLibrary.isAlive() then
					if playedanim then
						playedanim:Stop()
						if playedanim.Animation then
							playedanim.Animation:Destroy()
						end
						playedanim = nil
					end

					local anim
					if newinst then
						anim = newinst("Animation")
					else
						warningNotification("AnimationPlayer", "Failed to create Animation instance", 5)
						return
					end

					local suc, id = pcall(function()
						local obj = game:GetObjects("rbxassetid://"..AnimationPlayerBox.Value)[1]
						return string.match(obj.AnimationId, "%?id=(%d+)")
					end)
					if not suc or not id then
						id = AnimationPlayerBox.Value
					end
					anim.AnimationId = "rbxassetid://"..id

					local suc2, res = pcall(function()
						playedanim = entityLibrary.character.Humanoid.Animator:LoadAnimation(anim)
					end)

					if suc2 and playedanim then
						lplr.Character.Humanoid.CameraOffset = Vector3.new(0, 3 / -2, 0)
						lplr.Character.HumanoidRootPart.Size = Vector3.new(2, 3, 1.1)

						playedanim.Priority = Enum.AnimationPriority.Action4
						playedanim.Looped = true
						playedanim:Play()
						playedanim:AdjustSpeed(0 / 10)

						table.insert(AnimationPlayer.Connections, playedanim.Stopped:Connect(function()
							if AnimationPlayer.Enabled then
								AnimationPlayer.ToggleButton(false)
								AnimationPlayer.ToggleButton(false)
							end
						end))
					else
						warningNotification("AnimationPlayer", "Failed to load animation: "..(res or "invalid animation id"), 5)
					end
				end

				table.insert(AnimationPlayer.Connections, lplr.CharacterAdded:Connect(function()
					repeat task.wait() until (entityLibrary and entityLibrary.isAlive and entityLibrary.isAlive()) or not AnimationPlayer.Enabled
					task.wait(0.5)
					if not AnimationPlayer.Enabled then return end

					if playedanim then
						playedanim:Stop()
						if playedanim.Animation then
							playedanim.Animation:Destroy()
						end
						playedanim = nil
					end

					local anim
					if newinst then
						anim = newinst("Animation")
					else
						warningNotification("AnimationPlayer", "Failed to create Animation instance", 5)
						return
					end

					local suc, id = pcall(function()
						local obj = game:GetObjects("rbxassetid://"..AnimationPlayerBox.Value)[1]
						return string.match(obj.AnimationId, "%?id=(%d+)")
					end)
					if not suc or not id then
						id = AnimationPlayerBox.Value
					end
					anim.AnimationId = "rbxassetid://"..id

					local suc2, res = pcall(function()
						playedanim = entityLibrary.character.Humanoid.Animator:LoadAnimation(anim)
					end)

					if suc2 and playedanim then
						playedanim.Priority = Enum.AnimationPriority.Action4
						playedanim.Looped = true
						playedanim:Play()
						playedanim:AdjustSpeed(AnimationPlayerSpeed.Value / 10)

						playedanim.Stopped:Connect(function()
							if AnimationPlayer.Enabled then
								AnimationPlayer.ToggleButton(false)
								AnimationPlayer.ToggleButton(false)
							end
						end)
					else
						warningNotification("AnimationPlayer", "Failed to load animation: "..(res or "invalid animation id"), 5)
					end
				end))
			else
				if playedanim then
					playedanim:Stop()
					if playedanim.Animation then
						playedanim.Animation:Destroy()
					end
					playedanim = nil
				end
			end
		end
	})
end)
		
run(function()
	local AutoGamble
	
	AutoGamble = vape.Categories.Minigames:CreateModule({
		Name = 'AutoGamble',
		Function = function(callback)
			if callback then
				AutoGamble:Clean(bedwars.Client:GetNamespace('RewardCrate'):Get('CrateOpened'):Connect(function(data)
					if data.openingPlayer == lplr then
						local tab = bedwars.CrateItemMeta[data.reward.itemType] or {displayName = data.reward.itemType or 'unknown'}
						notif('AutoGamble', 'Won '..tab.displayName, 5)
					end
				end))
	
				repeat
					if not bedwars.CrateAltarController.activeCrates[1] then
						for _, v in bedwars.Store:getState().Consumable.inventory do
							if v.consumable:find('crate') then
								bedwars.CrateAltarController:pickCrate(v.consumable, 1)
								task.wait(1.2)
								if bedwars.CrateAltarController.activeCrates[1] and bedwars.CrateAltarController.activeCrates[1][2] then
									bedwars.Client:GetNamespace('RewardCrate'):Get('OpenRewardCrate'):SendToServer({
										crateId = bedwars.CrateAltarController.activeCrates[1][2].attributes.crateId
									})
								end
								break
							end
						end
					end
					task.wait(1)
				until not AutoGamble.Enabled
			end
		end,
		Tooltip = 'Automatically opens lucky crates, piston inspired!'
	})
end)
	
