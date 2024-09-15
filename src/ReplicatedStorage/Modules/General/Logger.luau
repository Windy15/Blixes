--!strict

local RunService = game:GetService("RunService")

type Logger = {
    Logs: {Log},

    info: (message: string) -> (),
    warn: (message: string) -> (),
    error: (message: string, level: number?) -> (),
    filterLogTypes: (...string) -> {Log},
}

type Log = {
    Message: string,
    LogType: string,
    Traceback: string,
    TimeLogged: number,
}

local Log = {}

function Log.new(message: string, logType: string): Log
    return table.freeze({
        Message = message,
        LogType = logType,
        Traceback = debug.traceback("Logger: ", 2),
        TimeLogged = DateTime.now().UnixTimestamp,
    })
end

local Logger = {
    Logs = {},
} :: Logger

function Logger.info(message)
    table.insert(Logger.Logs, Log.new(message, "Info"))
    if not RunService:IsStudio() then return end
    print(message)
end

function Logger.warn(message)
    table.insert(Logger.Logs, Log.new(message, "Warning"))
    if not RunService:IsStudio() then return end
    warn(message)
end

function Logger.error(message, level)
    table.insert(Logger.Logs, Log.new(message, "Error"))
    if not RunService:IsStudio() then return end
    error(message, level)
end

function Logger.filterLogTypes(...)
    local filtered = {}
    local typeFilter = {...}
    for _, log in Logger.Logs do
        if table.find(typeFilter, log.LogType) then
            table.insert(filtered, log)
        end
    end
    return filtered
end

return Logger