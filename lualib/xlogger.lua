local skynet = require "skynet"
require "skynet.manager"
local lutil = require "lutil"

xlogger = xlogger or {}
function xlogger.init(num)
    skynet.register_protocol {
        name = "text",
        id = skynet.PTYPE_TEXT,
        pack = function(text) return text end,
        unpack = function(buf, sz) return skynet.tostring(buf, sz) end,
    }

    if not xlogger.addresses then
        xlogger.msgtable = { "", "" }
        xlogger.addresses = {}
        num = num or 4
        local logpath = skynet.getenv("logpath") or "log"
        for i = 1, num, 1 do
            local addr = assert(skynet.launch("xlogger", logpath))
            xlogger.addresses[i] = addr
        end
    end
end

function xlogger.getAddr(filename)
    assert(#filename > 0)
    assert(#xlogger.addresses > 0)
    local hashkey = lutil.elfhash(filename)
    local index = (hashkey % #xlogger.addresses) + 1
    return xlogger.addresses[index]
end

function xlogger.format(fmt, ...)
    local msg
    if select("#", ...) == 0 then
        msg = fmt
    else
        msg = string.format(fmt, ...)
    end
    return msg
end

function xlogger.logf(filename, fmt, ...)
    local msgtable = xlogger.msgtable
    local addr = xlogger.getAddr(filename)
    msgtable[1] = filename
    msgtable[2] = xlogger.format(fmt, ...)
    skynet.send(addr, "text", table.concat(msgtable, " "))
end

function xlogger.print(...)
    local t = { ... }
    for i, value in ipairs(t) do
        t[i] = type(value) == "table" and table.dump(value) or value
    end
    local info = debug.getinfo(2)
    local prefix = (info.source or "?") .. ":" .. info.currentline
    skynet.error("[xlogger.print]", prefix, table.unpack(t))
end
