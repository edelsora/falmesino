import 
    redisparser
    , net
    , strutils
    , entities/action
    , asyncdispatch
    , asyncnet


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

proc handleRedisProtocol*(data: string, clientPipe: AsyncSocket) {.async.}=
    var cmd = data

    if data[0] != '*':
        cmd = convertInlineCommandToRESPCommand(data)
    
    try:
        var protocolActionTree = newDbActionDFromRedisValue(redisparser.decodeString(cmd))
        await clientPipe.send(debugDbActionD(protocolActionTree))
    except:
        await clientPipe.send(getCurrentExceptionMsg())

        

    