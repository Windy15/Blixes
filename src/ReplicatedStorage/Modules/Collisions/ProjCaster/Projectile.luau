--!native
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local GenerationId = require(ReplicatedStorage.Modules.General.GenerationId)
local TypeHolder = require(script.Parent.TypeHolder)

local ProjCaster = script.Parent

local ProjGroupSimulated = ProjCaster.Bindables.ProjGroupSimulated
local ThreadTemplate = ProjCaster.ProjThreadTemplate
local ThreadsFolder = if RunService:IsServer() then ServerScriptService.ProjThreadsServer else ReplicatedStorage.ProjThreadsClient

local PROJ_INIT_SIZE = 1000
local THREAD_COUNT = 16
local MAX_TIME_DIFF = 0.25 -- maximum time a projectile can travel in a frame

local ProjIdGen = GenerationId.new(PROJ_INIT_SIZE)
local GlobalProjectiles = table.create(PROJ_INIT_SIZE)

local Actors = {} :: {Actor}

for i = 1, THREAD_COUNT do
	local actor = ThreadTemplate:Clone()
	actor.Name = "ProjThread"..i
	actor:SetAttribute("Projs", 0)

	if RunService:IsServer() then
		actor.ProjHandlerServer.Enabled = true
	elseif RunService:IsClient() then
		actor.ProjHandlerClient.Enabled = true
	end

	table.insert(Actors, actor)
	actor.Parent = ThreadsFolder
end

RunService.PostSimulation:Wait() -- wait for actor scripts to load

local function getAvailableActor()
	local min, lowest = math.huge, Actors[1]
	for _, actor in Actors do
		local count = actor:GetAttribute("Projs") :: number
		if count < min then
			min = count
			lowest = actor
		end
	end
	return lowest
end

local function serializeProjectile(proj: TypeHolder.Projectile)
	local rayParams = proj.Caster.RayParams
	return {
		Position = proj.Position,
		LastPosition = proj.LastPosition,
		StartTime = proj.TrajectoryList.StartTime,
		Origin = proj.TrajectoryList.Origin,
		Velocity = proj.Velocity,
		Gravity = proj.Caster.Gravity,
		RayParams = rayParams,
		HitCalc = proj.Caster.HitFuncName,
	}
end

local LostTime = 0

local function clock()
	return os.clock() - LostTime
end

local Projectile = {} :: TypeHolder.ProjectileImpl
Projectile.__index = Projectile
Projectile.__type = "Projectile"

function Projectile.new(caster, origin, velocity)
    local timeCreated = clock()
    local self = setmetatable({
        Caster = caster,
        TimeCreated = timeCreated,

        InitialOrigin = origin,
        TrajectoryList = {Origin = origin, StartTime = timeCreated, Next = nil},
        _TrajectoryStepped = false, -- If the current trajectory has been used

        Velocity = velocity,
        Position = origin,
        LastPosition = origin,

		Rotation = CFrame.identity,
		
		HitCalc = "Default",
		_Actor = nil,
    }, Projectile)

    local id = ProjIdGen:CreateId(self)
    self.Id = id
    GlobalProjectiles[id] = self
	
	local actor = getAvailableActor()
	actor:SetAttribute("Projs", actor:GetAttribute("Projs") :: number + 1)
	actor:SendMessage("ProjCreated", id, serializeProjectile(self))
	self._Actor = actor :: any
	
    return self
end

function Projectile.buffToId(buff)
    return buffer.readu16(buff, 0)
end

function Projectile.idToBuff(id)
    local buff = buffer.create(2)
    buffer.writeu16(buff, 0, id)
    return buff
end

function Projectile:ChangeVelocity(velocity)
    if self._TrajectoryStepped then -- if a new trajectory hasn't been simulated yet we don't need to create a new one
		local startTime = clock()
		local origin = self.Position
		self.TrajectoryList = {
            Origin = origin,
			StartTime = startTime,
            Next = self.TrajectoryList,
		}
		if self._Actor then
			self._Actor:SendMessage("NewTrajectory", origin, startTime)
		end
    end
	self.Velocity = velocity
	if self._Actor then
		self._Actor:SendMessage("ProjUpdated", "Velocity", velocity)
	end
end

function Projectile:ApplyImpulse(velocity)
    self:ChangeVelocity(self.Velocity + velocity)
end

function Projectile:GetPivot()
    return CFrame.new(self.Position) * self.Rotation
end

function Projectile:GetFirstTrajectory()
    local traj = self.TrajectoryList
    while traj.Next do
        traj = traj.Next
    end
    return traj
end

function Projectile:Destroy()
    if RunService:IsServer() then
        GlobalProjectiles[self.Id] = nil
        ProjIdGen:RemoveId(self)
    end
	
	if self._Actor then
		self._Actor:SendMessage("ProjRemoved", self.Id)
		self._Actor:SetAttribute("Projs", self._Actor:GetAttribute("Projs") :: number - 1)
	end
	
    self.Caster.OnProjDestroyed:Fire(self)
end

local lastTime = os.clock() -- deltaTime parameter in PreSimulation won't detecting freezing so deltaTime calculation needed

RunService.PreSimulation:Connect(function()
	local currentTime = os.clock()
	local deltaTime = currentTime - lastTime
	lastTime = currentTime
	if deltaTime > MAX_TIME_DIFF then -- prevent projectiles teleporting far after lag spikes for better hit detection
		LostTime += deltaTime - MAX_TIME_DIFF
	end
	for _, actor in Actors do
		actor:SendMessage("Simulate", clock())
	end
end)

local function finishSimulationGroup(simulated: {[string]: Vector3}, hits: {[string]: RaycastResult})
	for id, newpos in simulated do
		local proj = GlobalProjectiles[tonumber(id) :: number]
		proj.LastPosition = proj.Position
		proj.Position = newpos
		proj._TrajectoryStepped = true
		proj.Caster.OnProjMoved:Fire(proj, newpos)
	end
	for id, result in hits do
		local proj = GlobalProjectiles[tonumber(id) :: number]
		proj.Caster.OnProjHit:Fire(proj, result)
		if proj.Caster.DestroyOnHit then
			proj:Destroy()
		end
	end
end

ProjGroupSimulated.Event:Connect(finishSimulationGroup)

return Projectile