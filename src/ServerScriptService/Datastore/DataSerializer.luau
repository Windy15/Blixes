--!native

type DataKey = string | number
type EncodedData = {any}
type EncodedTable = {[DataKey]: EncodedData}

local Serializer = {
    WarnUnknownType = true,
    Encoders = {
        ['Vector3'] = function(val: Vector3): EncodedData
            return {'Vector3', val.X, val.Y, val.Z}
        end,
        ['CFrame'] = function(val: CFrame): EncodedData
            return {'CFrame', val.Position.X, val.Position.Y, val.Position.Z, val:ToEulerAnglesXYZ()}
        end,
        ['Color3'] = function(val: Color3): EncodedData
            return {'Color3', val:ToHex()}
        end,
        ['UDim2'] = function(val: UDim2): EncodedData
            return {'UDim2', val.X.Scale, val.X.Offset, val.Y.Scale, val.Y.Offset}
        end,
        ['UDim'] = function(val: UDim): EncodedData
            return {'UDim', val.Scale, val.Offset}
        end,
        ['Vector2'] = function(val: Vector2): EncodedData
            return {'Vector3', val.X, val.Y}
        end,
    },
    Decoders = {
        ['Vector3'] = function(val: EncodedData): Vector3
            return Vector3.new(val[2], val[3], val[4])
        end,
        ['CFrame'] = function(val: EncodedData): CFrame
            return CFrame.new(val[2], val[3], val[4]) * CFrame.fromEulerAnglesXYZ(val[5], val[6], val[7])
        end,
        ['Color3'] = function(val: EncodedData): Color3
            return Color3.fromHex(val[2])
        end,
        ['UDim2'] = function(val: EncodedData): UDim2
            return UDim2.new(val[2], val[3], val[4], val[5])
        end,
        ['UDim'] = function(val: EncodedData): UDim
            return UDim.new(val[2], val[3])
        end,
        ['Vector2'] = function(val: EncodedData): Vector2
            return Vector2.new(val[2], val[3])
        end,
    }
}

local function isProperNum(num: number)
	return num < math.huge
end

function Serializer.dataEncode(data: {[DataKey]: any}): {[DataKey]: EncodedTable}
    for k, val in data do
        local encode = Serializer.Encoders[typeof(val)]
        if encode then
            data[k] = encode(val)
        elseif typeof(val) == "table" then
            data[k] = {'table', Serializer.dataEncode(val)}
        elseif type(val) == "userdata" and Serializer.WarnUnknownType then
            warn("DataSerializer: Could not serialize datatype "..typeof(val))
        elseif type(val) == "number" and not isProperNum(val) then
            warn("Number "..tostring(val).." of key "..tostring(k).." cannot be encoded, converted to 0 instead")
            data[k] = 0
        end
    end

    return data
end

function Serializer.dataDecode(data: {[DataKey]: EncodedData}): {[DataKey]: any}
    for k, val in data do
        if type(val) == "table" then
            local typedata = val[1]
            local decode = Serializer.Decoders[typedata]
            if typedata == 'table' then
                (data :: {[DataKey]: any})[k] = Serializer.dataDecode(val[2])
            elseif decode then
                data[k] = decode(val)
            else
                warn("DataSerializer: Could not deserialize datatype "..typedata)
            end
        end
    end

    return data
end

return Serializer