local ReplicatedStorage = game:GetService("ReplicatedStorage")

local tool = script.Parent
local Remotes = tool:WaitForChild("Remotes")

local Gun = require(ReplicatedStorage.Tools.Guns.HoneyBadgerClass).new (
	Remotes.ReplicateObject.OnClientSignal:Wait()
)