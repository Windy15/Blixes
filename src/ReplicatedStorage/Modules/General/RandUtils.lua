--!strict

type RandUtilsImpl = {
    generateId: () -> string,
    toGUID: (id: string, wrapInCurlyBraces: boolean) -> string,
    idToGUID: (id: string, wrapInCurlyBraces: boolean) -> string
}

local HttpService = game:GetService("HttpService")

local RandUtils = {} :: RandUtilsImpl

function RandUtils.generateId(): string
    return string.lower((string.gsub(HttpService:GenerateGUID(false), "-", "")))
end

function RandUtils.idToGUID(id: string, wrapInCurlyBraces: boolean): string
    if wrapInCurlyBraces then
        return string.upper(string.format("{%s-%s-%s-%s-%s}", string.sub(id, 1, 8), string.sub(id, 9, 12), string.sub(id, 13, 16), string.sub(id, 17, 20), string.sub(id, 21, 32)))
    else
        return string.upper(string.format("%s-%s-%s-%s-%s", string.sub(id, 1, 8), string.sub(id, 9, 12), string.sub(id, 13, 16), string.sub(id, 17, 20), string.sub(id, 21, 32)))
    end
end

return RandUtils