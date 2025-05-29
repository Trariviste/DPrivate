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

    local function modifyHRP()
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hrp = character:WaitForChild("HumanoidRootPart")
        hrp.Transparency = 0.3
        hrp.Color = Color3.new(1, 1, 1)
        hrp.Material = Enum.Material.Plastic
        hrp.CanCollide = true
        hrp.Anchored = false
    end

    local function makeInvisible()
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.LocalTransparencyModifier = 1
            elseif part:IsA("Decal") then
                part.Transparency = 1
            elseif part:IsA("LayerCollector") then
                part.Enabled = false
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
                modifyHRP()
                makeInvisible()
                startLoop(character)
            else
                if loopConn then
                    loopConn:Disconnect()
                    loopConn = nil
                end
            end
        end,
        Default = false,
        Tooltip = "Reworked Invis with working toggle and respawn support"
    })

    -- Reapply on respawn if still enabled
    LocalPlayer.CharacterAdded:Connect(function()
        if invisibilityEnabled then
            task.wait(0.5)
            Invisibility.Function(true)
        end
    end)
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
	
