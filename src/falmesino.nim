import 
    net
    , strutils
    , asyncdispatch
    , asyncnet
    , lib/semantic
    , lib/store
    , lib/entities/cache
    , options
    , terminal

const SERVER_PORT = Port(6789)

var 
    tables : CacheTableLock

proc acceptClient(table: CacheTableLock, server: AsyncSocket) : Future[Option[CacheTableLock]] {.async.} =  
    var t = table
    var r = none(CacheTableLock)
    let client = await server.accept()
    echo "* Connected with $1".format(client.getPeerAddr())

    let data = await client.recv(1024)
    
    # Memory Issue
    var semanticProcess = semantic.handleRedisProtocol(data, client,t)
    yield semanticProcess
    if semanticProcess.failed:
        let e = semanticProcess.readError()
        await client.send("$1 : $2".format(e.name,e.msg))
    if semanticProcess.finished:
        client.close()  
        return some(semanticProcess.read())
        
    client.close()  
    return r

proc main() {.async.} =
    try:
      # TODO:
      # - make accept-reply mechanism on socket.
      # - parse the socket body based on RESP. 
      # - make semantic that moving things.
      
      # REF:
      # - https://xmonader.github.io/nimdays/day15_tcprouter.html
      # - https://blog.tejasjadhav.xyz/simple-chat-server-in-nim-using-sockets/

        var server = newAsyncSocket(buffered=false)
        server.setSockOpt(OptReuseAddr, true)
        server.bindAddr(SERVER_PORT)
        server.listen()
        echo "falmesino service run on: $1".format(SERVER_PORT)

        while true:
            var tc = acceptClient(tables,server)
            proc cb(f:Future[Option[CacheTableLock]]) {.gcsafe.} =
                let fr = f.read()
                if fr.isSome:
                    tables.mergeTable(fr.get())

            tc.callback= cb
            yield tc
    except OSError:
        echo "error"
        return

when isMainModule:
    tables = newCacheTableLock()
    proc exitHandler() {.noconv.} = 
        # TODO: make the CTRL+C Interupt to store data into filesystem with MsgPack format
        eraseScreen() #puts cursor at down
        setCursorPos(0, 0)
        if dumpCacheToFile("falmesino.kv",tables):
            echo "sucessfully, store to disk"
            quit 0
        
        echo "failed to store to disc"
        quit 1
        
    setControlCHook(exitHandler)
    waitFor main()