--!strict

local RunService = game:GetService("RunService")

type StudioDebug = {
    Logs: {Log},

    log: (message: string) -> (),
    warn: (message: string) -> (),
    error: (message: string, level: number?) -> (),
    filterLogTypes: (...string) -> {Log},
}

type Log = {
    Message: string,
    LogType: string,
    Traceback: string,
}

local Log = {}

function Log.new(message, logType): Log
    return table.freeze({
        Message = message,
        LogType = logType,
        Traceback = debug.traceback("StudioDebug: ", 2),
    })
end

local StudioDebug = {
    Logs = {},
} :: StudioDebug

function StudioDebug.log(message)
    if not RunService:IsStudio() then return end
    table.insert(StudioDebug.Logs, Log.new(message, "Info"))
    print(message)
end

function StudioDebug.warn(message)
    if not RunService:IsStudio() then return end
    table.insert(StudioDebug.Logs, Log.new(message, "Warning"))
    warn(message)
end

function StudioDebug.error(message, level)
    if not RunService:IsStudio() then return end
    table.insert(StudioDebug.Logs, Log.new(message, "Error"))
    error(message, level)
end

function StudioDebug.filterLogTypes(...)
    local filtered = {}
    local len = select("#", ...)
    for _, log in StudioDebug.Logs do
        for i = 1, len do
            if log.LogType == select(i, ...) then
                table.insert(filtered, log)
            end
        end
    end
    return filtered
end

return StudioDebug