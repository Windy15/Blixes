local ServerSettings = {
	DataSaving = true,
	AntiCheat = true
}

if game.PrivateServerOwnerId ~= 0 then -- Datasaving off for private servers
	ServerSettings.DataSaving = false
end

return ServerSettings