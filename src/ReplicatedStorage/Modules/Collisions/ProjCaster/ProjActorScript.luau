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
	local function simulate()
		local simulatedGroup = {}
		local hits = {}
		local newTime = os.clock()
		for id, proj in Projectiles do
			local newpos = calculatePosition(proj.Gravity, proj.Velocity, proj.Origin, newTime - proj.StartTime)
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

	actor:BindToMessageParallel("Simulate", simulate)

	actor:BindToMessage("ProjUpdated", function(id: number, key: string, val: any)
		if Projectiles[tostring(id)] then
			Projectiles[tostring(id)][key] = val
		end
	end)

	actor:BindToMessage("ProjRemoved", function(id: number)
		Projectiles[tostring(id)] = nil
	end)
end

return main