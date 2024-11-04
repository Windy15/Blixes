--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProjCaster = ReplicatedStorage.Modules.Collisions.ProjCaster
local Types = require(ProjCaster.TypeHolder)

local HitFuncFolder = ProjCaster.HitFunctions
local Bindables = ProjCaster.Bindables
local ProjSimulated = Bindables.ProjGroupSimulated

local HitFuncs = {} :: {[string]: (Types.ProjData) -> RaycastResult?}

for _, module in HitFuncFolder:GetChildren() do
	HitFuncs[module.Name] = require(module) :: any
end

local function main(actor: Actor)
	local Projectiles = {} :: {[string]: Types.ProjData}

	actor:BindToMessage("ProjCreated", function(id: number, data: any, b)
		local projData = data
		projData.HitCalc = HitFuncs[data.HitCalc]

		Projectiles[tostring(id)] = projData :: Types.ProjData
	end)

	@native
	local function calculatePosition(gravity: Vector3, velocity: Vector3, initPos: Vector3, time: number)
		return 0.5 * gravity * time ^ 2 + velocity * time + initPos
	end

	@native
	local function simulate(currentTime: number)
		local simulatedGroup = {}
		local hits = {}
		for id, proj in Projectiles do
			local newpos = calculatePosition(proj.Gravity, proj.Velocity, proj.Origin, currentTime - proj.StartTime)
			proj.LastPosition = proj.Position
			proj.Position = newpos
			simulatedGroup[id] = newpos
			local hit = proj:HitCalc()
			if hit then
				hits[id] = hit
			end
		end
		ProjSimulated:Fire(simulatedGroup, hits)
	end

	local function newTrajectory(id: number, origin: Vector3, startTime: number)
		local proj = Projectiles[tostring(id)]
		if proj then
			proj.Origin = origin
			proj.StartTime = startTime
		end
	end

	local function updateProj(id: number, key: string, val: any)
		if Projectiles[tostring(id)] then
			Projectiles[tostring(id)][key] = val
		end
	end

	local function removeProj(id: number)
		Projectiles[tostring(id)] = nil
	end

	actor:BindToMessageParallel("Simulate", simulate)
	actor:BindToMessage("NewTrajectory", newTrajectory)
	actor:BindToMessage("ProjUpdated", updateProj)
	actor:BindToMessage("ProjRemoved", removeProj)
end

return main