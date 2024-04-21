--!strict

type DataIdImpl = {
    generateId: () -> string,
    toGUID: (id: string, wrapInCurlyBraces: boolean) -> string
}

local HttpService = game:GetService("HttpService")

local DataId = {} :: DataIdImpl

function DataId.generateId(): string
    return string.lower((string.gsub(HttpService:GenerateGUID(false), "-", "")))
end

function DataId.toGUID(id: string, wrapInCurlyBraces: boolean): string
    if wrapInCurlyBraces then
        return string.upper(string.format("{%s-%s-%s-%s-%s}", string.sub(id, 1, 8), string.sub(id, 9, 12), string.sub(id, 13, 16), string.sub(id, 17, 20), string.sub(id, 21, 32)))
    else
        return string.upper(string.format("%s-%s-%s-%s-%s", string.sub(id, 1, 8), string.sub(id, 9, 12), string.sub(id, 13, 16), string.sub(id, 17, 20), string.sub(id, 21, 32)))
    end
end

return DataId