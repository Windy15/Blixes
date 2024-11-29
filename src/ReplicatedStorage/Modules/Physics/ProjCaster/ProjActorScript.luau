--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProjCaster = ReplicatedStorage.Modules.Physics.ProjCaster
local Types = require(ProjCaster.TypeHolder)

local HitFuncFolder = ProjCaster.HitFunctions
local Bindables = ProjCaster.Bindables
local ProjGroupSimulated = Bindables.ProjGroupSimulated

local HitFuncs = {} :: {[string]: (Types.ProjData) -> RaycastResult?}

for _, module in HitFuncFolder:GetChildren() do
	HitFuncs[module.Name] = require(module) :: any
end

local function main(actor: Actor)
	local Projectiles = {} :: {[string]: Types.ProjData}

	actor:BindToMessage("ProjCreated", function(id: number, data: any)
		local projData = data
		projData.HitCalc = HitFuncs[data.HitCalc] or HitFuncs.Default

		Projectiles[tostring(id)] = projData :: Types.ProjData
	end)

	@native
	local function calculatePosition(gravity: Vector3, initVelocity: Vector3, initPos: Vector3, time: number)
		return 0.5 * gravity * time ^ 2 + initVelocity * time + initPos
	end

	@native
	local function calculateVelocity(gravity: Vector3, time: number, initVelocity: Vector3)
		return gravity * time + initVelocity
	end

	@native
	local function simulate(currentTime: number)
		local simulatedGroup = {}
		local hits = {}
		for id, proj in Projectiles do
			local totalTime = currentTime - proj.StartTime

			local newpos = calculatePosition(proj.Gravity, proj.InitVelocity, proj.Origin, totalTime)
			local velocity = calculateVelocity(proj.Gravity, totalTime, proj.InitVelocity)
			proj.LastPosition = proj.Position
			proj.Velocity = velocity

			proj.Position = newpos

			local sim = {
				Position = newpos,
				Velocity = velocity,
			}
			simulatedGroup[id] = sim

			local hit = proj:HitCalc()
			if hit then
				hits[id] = hit
			end
		end
		ProjGroupSimulated:Fire(simulatedGroup, hits)
	end

	local function newTrajectory(id: number, origin: Vector3, startTime: number, velocity: Vector3)
		local proj = Projectiles[tostring(id)]
		if proj then
			proj.Origin = origin
			proj.StartTime = startTime
			proj.InitVelocity = velocity
		end
	end

	local function updatePosition(id: number, pos: Vector3, lastPos: Vector3)
		local idstr = tostring(id)
		local proj = Projectiles[idstr]
		if proj then
			proj.LastPosition = lastPos
			proj.Position = pos
		end
	end

	local function removeProj(id: number)
		Projectiles[tostring(id)] = nil
	end

	actor:BindToMessageParallel("Simulate", simulate)
	actor:BindToMessage("NewTrajectory", newTrajectory)
	actor:BindToMessage("UpdatePosition", updatePosition)
	actor:BindToMessage("ProjRemoved", removeProj)
end

return main