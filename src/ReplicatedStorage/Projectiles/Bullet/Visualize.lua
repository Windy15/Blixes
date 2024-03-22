local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FastCast = require(ReplicatedStorage.Modules.Collisions.FastCastRedux)

local function visualizeProjectile(render, caster, origin, direction, velocity, fastCastBehaviour) -- fire FastCast data to clients so they can mimic the hitbox's movements
    render = render:Clone()

    local newCaster = FastCast.new()
    for k, v in pairs(caster) do
        newCaster[k] = v
    end

    local newBehavior = FastCast.newBehavior()
    for k, v in pairs(fastCastBehaviour) do
        newBehavior[k] = v
    end

    caster:Fire(origin, direction, velocity, fastCastBehaviour)
end

return visualizeProjectile