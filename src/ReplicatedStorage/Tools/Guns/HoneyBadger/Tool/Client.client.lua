local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local animator = char:WaitForChild("Animator")

local tool = script.Parent
local Remotes = tool:WaitForChild("Remotes")

local Gun = require(ReplicatedStorage.Tools.Guns.HoneyBadgerClass).new (
	Remotes.ReplicateObject.OnClientEvent:Wait()
)

