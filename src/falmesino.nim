import 
    net
    , strutils
    , asyncdispatch
    , asyncnet
    , lib/semantic
    , lib/entities/cache

const SERVER_PORT = Port(6789)

proc asyncSocketListen(t: var CacheTableLock) {.async.} =
    var server = newAsyncSocket(buffered=false)
    server.setSockOpt(OptReuseAddr, true)
    server.bindAddr(SERVER_PORT)
    server.listen()
    echo "falmesino service run on: $1".format(SERVER_PORT)
  
    while true:
        let client = await server.accept()
        echo "* Connected with $1".format(client.getPeerAddr())

        let data = await client.recv(1024)
        try:
            # Memory Issue
            await semantic.handleRedisProtocol(data, client,t)
        except:
            await client.send(getCurrentExceptionMsg())
        finally:
            client.close()  

proc main() =
    var t = newCacheTableLock()
    try:
      # TODO:
      # - make accept-reply mechanism on socket.
      # - parse the socket body based on RESP. 
      # - make semantic that moving things.

      # REF:
      # - https://xmonader.github.io/nimdays/day15_tcprouter.html
      # - https://blog.tejasjadhav.xyz/simple-chat-server-in-nim-using-sockets/
      asyncCheck asyncSocketListen(t)
    except OSError:
        echo "error"
        return

main()
runForever()