import 
    redisparser
    , net
    , strutils
    , entities/action
    , entities/cache
    , asyncdispatch
    , asyncnet
    , options


func convertInlineCommandToRESPCommand(s: string) : string =
    let data = s.split(" ")
    result = "*$1$2".format(data.len(),redisparser.CRLF)
    for str in data:
        result = result & "$1$2$3$4$5".format(
            "$"
            ,str.len()
            ,  redisparser.CRLF
            ,  str
            ,  redisparser.CRLF)
    return

proc handleRedisProtocol*(data: string, clientPipe: AsyncSocket,table: var CacheTableLock) {.async.}=
    var cmd = data

    if data[0] != '*':
        cmd = convertInlineCommandToRESPCommand(data)
    
    try:
        var protocolActionTree = newDbActionDFromRedisValue(redisparser.decodeString(cmd))
        case protocolActionTree.action:
        of daGet:
            var getValue = table.getKey(protocolActionTree.key)
            if getValue.isSome():
                var value = getValue.get()
                await clientPipe.send(encode(value))
                return
            await clientPipe.send(encode(newRedisError("not found")))
        of daDel:discard
        of daSet:
            let desc = protocolActionTree.desc
            var setStatOk = table.setKey(desc.key,desc.value)
            if setStatOk:
                await clientPipe.send(encode(newRedisString("OK")))
                return
            await clientPipe.send(encode(newRedisError("FAIL")))
            return
        of daSetx:discard

        await clientPipe.send(debugDbActionD(protocolActionTree))
    except:
        await clientPipe.send(getCurrentExceptionMsg())
    return

        

    