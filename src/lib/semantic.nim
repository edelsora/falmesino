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

proc handleRedisProtocol*(data: string, clientPipe: AsyncSocket,t: CacheTableLock): Future[CacheTableLock] {.async.}=
    var table = t
    var cmd = data

    if data[0] != '*':
        cmd = convertInlineCommandToRESPCommand(data)
    
    try:
        var protocolActionTree = newDbActionDFromRedisValue(redisparser.decodeString(cmd))
        case protocolActionTree.action:
        of daGet:
            var getValue = table.getKey(protocolActionTree.key)
            if getValue.isSome():
                # table.lockTable()
                var value = getValue.get()
                # table.unlockTable()
                await clientPipe.send(encode(value))
                return t
            let errorMsg : string = encode(newRedisError("not found"))
            await clientPipe.send(errorMsg)
        of daDel:discard
        of daSet:
            let desc = protocolActionTree.desc
            # table.lockTable()
            var setStatOk = table.setKey(desc.key,desc.value)
            # table.unlockTable()
            if setStatOk:
                await clientPipe.send(encode(newRedisString("OK")))
                return table
            await clientPipe.send(encode(newRedisError("FAIL")))
            return
        of daSetx:discard

        await clientPipe.send(debugDbActionD(protocolActionTree))
    except:
        let
            e = getCurrentException()
            msg = getCurrentExceptionMsg()
        echo "Got exception ", repr(e), " with message ", msg
        await clientPipe.send(getCurrentExceptionMsg())
    return table

        

    