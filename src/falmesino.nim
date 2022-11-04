import 
    net
    , strutils
    , asyncdispatch
    , asyncnet
    , lib/semantic
    , lib/entities/cache
    , options
    , tables

const SERVER_PORT = Port(6789)

proc acceptClient(table: CacheTableLock, server: AsyncSocket) : Future[Option[CacheTableLock]] {.async.} =  
    var t = table
    var r = none(CacheTableLock)
    let client = await server.accept()
    echo "* Connected with $1".format(client.getPeerAddr())

    let data = await client.recv(1024)
    try:
        # Memory Issue
        await semantic.handleRedisProtocol(data, client,t)
        r = some(t)
    except:
        await client.send(getCurrentExceptionMsg())
    finally:
        client.close()  
        return r

proc main() =
    var t = newCacheTableLock()
    try:
      # TODO:
      # - make accept-reply mechanism on socket.
      # - parse the socket body based on RESP. 
      # - make semantic that moving things.

        var server = newAsyncSocket(buffered=false)
        server.setSockOpt(OptReuseAddr, true)
        server.bindAddr(SERVER_PORT)
        server.listen()
        echo "falmesino service run on: $1".format(SERVER_PORT)

      # REF:
      # - https://xmonader.github.io/nimdays/day15_tcprouter.html
      # - https://blog.tejasjadhav.xyz/simple-chat-server-in-nim-using-sockets/
        while true:
            let tc = acceptClient(t,server)
            proc cb(f:Future[Option[CacheTableLock]]) {.gcsafe.} =
                let fr = f.read()
                if fr.isSome:
                    t.mergeTable(fr.get())

            tc.callback= cb
            asyncCheck tc
    except OSError:
        echo "error"
        return

main()
runForever()