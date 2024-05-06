--!strict

export type EncodedData = {any}

local Serializer = {
    Encoders = {
        ['Vector3'] = function(val: Vector3): EncodedData
            return {'Vector3', val.X, val.Y, val.Z}
        end,
        ['CFrame'] = function(val: CFrame): EncodedData
            return {'CFrame', val:GetComponents()}
        end,
        ['Color3'] = function(val: Color3): EncodedData
            return {'Color3', val:ToHex()}
        end
    },
    Decoders = {
        ['Vector3'] = function(val: EncodedData): Vector3
            return Vector3.new(val[2], val[3], val[4])
        end,
        ['CFrame'] = function(val: EncodedData): CFrame
            return CFrame.new(table.unpack(val, 2))
        end,
        ['Color3'] = function(val: EncodedData): Color3
            return Color3.fromHex(val[2])
        end
    }
}

function Serializer.serialize(data: {[any]: any}): {[any]: any}
    data = table.clone(data)

    for k, val in pairs(data) do
        local encode = Serializer.Encoders[typeof(val)]
        if encode then
            data[k] = encode(val)
        elseif typeof(val) == "table" then
            data[k] = Serializer.serialize(val)
            table.insert(val, 1, "table")
        end
    end

    return data
end

function Serializer.deserialize(data: {[any]: any}): {[any]: any}
    data = table.clone(data)

    for k, val in pairs(data) do
        local decode = Serializer.Decoders[val[1]]
        if decode then
            data[k] = decode(val)
            table.remove(val, 1)
        elseif val[1] == "table" then
            data[k] = Serializer.deserialize(val)
            table.remove(val[1])
        end
    end

    return data
end

return Serializer