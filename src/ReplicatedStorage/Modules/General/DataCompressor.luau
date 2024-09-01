--!native
--!strict

local DataCompressor = {
    Encoders = {},
    Decoders = {},
}

-- VECTOR3
-----------------------------------------------

local VEC_SIZE = 12

function DataCompressor.Encoders.Vector3(vectors: {Vector3}): buffer
    local data = buffer.create(#vectors * VEC_SIZE)
    for i, vec in ipairs(vectors) do
        local offset = (i - 1) * VEC_SIZE
        buffer.writef32(data, offset, vec.X)
        buffer.writef32(data, offset + 4, vec.Y)
        buffer.writef32(data, offset + 8, vec.Z)
    end
    return data
end

function DataCompressor.Decoders.Vector3(data: buffer): {Vector3}
    local vectors = table.create(buffer.len(data) / VEC_SIZE)
    for i = 0, buffer.len(data) - 1, VEC_SIZE do
        local vec = Vector3.new(
            buffer.readf32(data, i),
            buffer.readf32(data, i + 4),
            buffer.readf32(data, i + 8)
        )
        table.insert(vectors, vec)
    end
    return vectors
end

-- COLOR3
-----------------------------------------------

local COL_SIZE = 3

function DataCompressor.Encoders.Color3(cols: {Color3}): buffer
    local data = buffer.create(#cols * COL_SIZE)
    for i, col in ipairs(cols) do
        local offset = (i - 1) * COL_SIZE
        buffer.writeu8(data, offset, col.R * 255)
        buffer.writeu8(data, offset + 1, col.G * 255)
        buffer.writeu8(data, offset + 2, col.B * 255)
    end
    return data
end

function DataCompressor.Decoders.Color3(data: buffer): {Color3}
    local cols = table.create(buffer.len(data) / COL_SIZE)
    for i = 0, buffer.len(data) - 1, COL_SIZE do
        local col = Color3.fromRGB(
            buffer.readu8(data, i),
            buffer.readu8(data, i + 1),
            buffer.readu8(data, i + 2)
        )
        table.insert(cols, col)
    end
    return cols
end

-- CFRAME
-----------------------------------------------

local CF_SIZE = 24

function DataCompressor.Encoders.CFrame(cframes: {CFrame}): buffer
    local data = buffer.create(#cframes * CF_SIZE)
    for i, cf in ipairs(cframes) do
        local offset = (i - 1) * CF_SIZE
        local pos = cf.Position
        buffer.writef32(data, offset, pos.X)
        buffer.writef32(data, offset + 4, pos.Y)
        buffer.writef32(data, offset + 8, pos.Z)
        local rx, ry, rz = cf:ToEulerAnglesXYZ()
        buffer.writef32(data, offset + 12, rx)
        buffer.writef32(data, offset + 16, ry)
        buffer.writef32(data, offset + 20, rz)
    end
    return data
end

function DataCompressor.Decoders.CFrame(data: buffer): {CFrame}
    local cframes = table.create(buffer.len(data) / CF_SIZE)
    for i = 0, buffer.len(data) - 1, CF_SIZE do
        local cf = CFrame.new(
            buffer.readf32(data, i),
            buffer.readf32(data, i + 4),
            buffer.readf32(data, i + 8)
        ) * CFrame.fromEulerAnglesXYZ(
            buffer.readf32(data, i + 12),
            buffer.readf32(data, i + 16),
            buffer.readf32(data, i + 20)
        )
        table.insert(cframes, cf)
    end
    return cframes
end

-- BOOLEAN
-----------------------------------------------

function DataCompressor.Encoders.boolean(bools: {boolean}): buffer
	local arrayLength = #bools
	local data = buffer.create(math.ceil(arrayLength / 8))

	local byte = 0

	for offset: number, bool: boolean in ipairs(bools) do
		if bool then
			byte = bit32.bor(byte, bit32.lshift(1, bit32.band(offset - 1, 0b111)))
		end

		-- bit32.band faster than offset % 8
		if bit32.band(offset, 0b111) == 0 then
			buffer.writeu8(data, offset / 8 - 1, byte)
			byte = 0
		end
	end

	if bit32.band(arrayLength, 0b111) ~= 0 then
		buffer.writeu8(data, math.ceil(arrayLength / 8 - 1), byte)
	end

	return data
end

function DataCompressor.Decoders.boolean(data: buffer, maxBools: number?): {boolean}
    local buffLen = buffer.len(data)
	local array: {boolean} = table.create(buffer.len(data) * 8)

    maxBools = maxBools or buffLen * 8

	local byte: number = nil
	local arrayLength: number = 0

	for offset = 0, buffLen - 1 do
		byte = buffer.readu8(data, offset)

		for n = 0, 7 do
			table.insert(array, bit32.btest(byte, bit32.lshift(1, n)))
			arrayLength += 1
			if arrayLength == maxBools then
				break
			end
		end

		if arrayLength == maxBools then
			break
		end
	end

	return array
end

-----------------------------------------------

function DataCompressor.bufferToString(buff: buffer): string
    local str = ""
    local finish = buffer.len(buff) - 1
    for i = 0, finish do
        local byte = buffer.readu8(buff, i)
        for bit = 8, 1, -1 do
            str ..= bit32.band(byte, bit32.lshift(1, bit - 1)) == 0 and "0" or "1"
        end
        if i ~= finish then
            str ..= " "
        end
    end
    return str
end

return DataCompressor