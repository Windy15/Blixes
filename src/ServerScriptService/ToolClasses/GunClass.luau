--!nonstrict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Characters = require(ReplicatedStorage.Players.Characters)
local EnumList = require(ReplicatedStorage.Modules.General.EnumList)
local FastCast = require(ReplicatedStorage.Modules.Collisions.FastCastRedux)
local FastCastSignal = require(ReplicatedStorage.Modules.Collisions.FastCastRedux.Signal)
local FastCastTypes = require(ReplicatedStorage.Modules.Collisions.FastCastRedux.TypeDefinitions)
local GameEnums = require(ReplicatedStorage.GameEnums)
local RandUtils = require(ReplicatedStorage.Modules.General.RandUtils)
local Signal = require(ReplicatedStorage.Modules.General.Signal)
local Stat = require(ReplicatedStorage.Modules.General.Stat)
local StringUtils = require(ReplicatedStorage.Modules.General.StringUtils)
local ToolClass = require(ServerScriptService.ToolClasses.ToolClass)

local CreateProjectile = ReplicatedStorage.Remotes.Projectiles.CreateProjectile
local UpdatePosition = ReplicatedStorage.Remotes.Projectiles.UpdatePosition
local RemoveProjectile = ReplicatedStorage.Remotes.Projectiles.RemoveProjectile

local Gun = setmetatable({
	ToolType = "Gun"
}, ToolClass)
Gun.__index = Gun

type GunImpl = {
	__index: GunImpl,
	ToolType: string,

	new: (config: GunConfig) -> GunObject,
	_ConfigBullets: (self: GunObject) -> (),
	Init: (self: GunObject) -> (),
	Shoot: (self: GunObject, direction: Vector3, castBehvaiour: FastCastTypes.FastCastBehavior) -> (),
	Reload: (self: GunObject) -> (),
	GetMode: (self: GunObject) -> EnumList.EnumItem,
	SetCurrentMode: (self: GunObject, index: number) -> (),
	ChangeMode: (self: GunObject, firingMode: EnumList.EnumItem) -> ()
}

type GunConfig = {
	Damage: Stat.Stat<number>,
	FireRate: Stat.Stat<number>,
	ReloadTime: Stat.Stat<number>,

	GunState: EnumList.EnumItem,
	FiringModes: {EnumList.EnumItem},
	CurrentMode: number,
	ShootType: EnumList.EnumItem,

	CurrentProjectile: {
		Name: string,
		Caster: FastCastTypes.Caster,
		HitConnection: FastCastSignal.Connection?
	},
	_ProjectileIds: {
		[string]: {
			player: Player,
			id: string
		}
	},

	OnShot: Signal.Signal,
	OnReloading: Signal.Signal,
	OnModeChanged: Signal.Signal,
}
export type GunObject = typeof(setmetatable({} :: GunConfig & ToolClass.ToolObject, {} :: GunImpl))

function Gun.new(config): GunObject
	local new = setmetatable(ToolClass.new(config), Gun)
	new.Damage = Stat.new(config.Damage or 0)
	new.FireRate = Stat.new(config.FireRate or 1)
	new.ReloadTime = Stat.new(config.ReloadTime or 3)

	new.GunState = GameEnums.GunState.Idle
	new.FiringModes = config.FiringModes or {GameEnums.GunMode.Semi}
	new.CurrentMode = config.CurrentMode or 1

	new.ShootType = GameEnums.ShootType.Projectile

	new.CurrentProjectile = {
		Name = "Bullet",
		Caster = FastCast.new(),
		HitConnection = nil
	}
	new._ProjectileIds = {}

	new.OnShot = Signal.new()
	new.OnReloading = Signal.new()
	new.OnModeChanged = Signal.new()

	return new
end

--[[
function Gun:_ConfigBullets()
	if self.Projectiles.Bullet then
		self.Projectiles.Bullet.HitConnection = self.Projectiles.Bullet.Caster.RayHit:Connect(function(activeCast, result)
			activeCast:Terminate()

			local char = Characters:GetCharFromInstance(result.Instance)
			if not char then return end
			char:TakeDamage(self.Damage.Value)
		end)
	end

	for name, projectile in pairs(self.Projectiles) do
		local caster = projectile.Caster

		local projIds = {}
		self._ProjectileIds[name] = projIds

		caster.LengthChanged:Connect(function(activeCast, lastPoint, rayDir, displacement, segmentVelocity)
			if not projIds[activeCast] then return end
			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= projIds[activeCast].player then
					UpdatePosition:FireClient(player, projIds[activeCast].id, CFrame.lookAt(lastPoint, rayDir), os.clock())
				end
			end
		end)

		caster.CastTerminating:Connect(function(activeCast)
			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= projIds[activeCast].player then
					RemoveProjectile:FireClient(player, projIds[activeCast].id)
				end
			end
		end)
	end
end
]]

function Gun:Init()
	ToolClass.Init(self)
end

function Gun:Shoot(direction, castBehvaiour)
	local activeCast = self.CurrentProjectile.Caster:Fire(direction, castBehvaiour)
	local projId = RandUtils.generateId()
	self._ProjectileIds.Bullet[activeCast] = {
		id = projId,
		player = self.Player
	}

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= self.Player then
			CreateProjectile:FireClient(projId, ReplicatedStorage.Projectiles[self.CurrentProjectile])
		end
	end
end

function Gun:Reload()
	if self.Reloading then return end
	self.Reloading = true

	task.delay(self.ReloadTime.Value, function()
		self.Reloading = false
	end)
end

function Gun:GetMode()
	return self.FiringModes[self.CurrentMode]
end

function Gun:SetCurrentMode(index)
	local mode = self.FiringModes[index]
	if not self.FiringModes[index] then
		error(string.format("'%d' is not a valid index in FiringModes for %s", index, StringUtils.formatAddress(self, "Gun")), 2)
	end

	self.CurrentMode = index
	self.OnModeChanged:Fire(mode)

	return mode
end

function Gun:ChangeMode(firingMode)
	local index = table.find(self.FiringModes, firingMode)
	if index then
		return self:SetCurrentMode(index)
	end
	return false
end

return Gun