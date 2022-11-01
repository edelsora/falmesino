import 
    net
    , strutils
    , asyncdispatch
    , asyncnet
    , lib/semantic

const SERVER_PORT = Port(6789)

proc asyncSocketListen() {.async.} =
    var server = newAsyncSocket(buffered=false)
    server.setSockOpt(OptReuseAddr, true)
    server.bindAddr(SERVER_PORT)
    server.listen()
  
    while true:
        let client = await server.accept()
        echo "* Connected with $1".format(client.getPeerAddr())

        let data = await client.recv(1024)
        try:
            await semantic.handleRedisProtocol(data, client)
        except:
            await client.send(getCurrentExceptionMsg())
        finally:
            client.close()  

proc main() =
    try:
      # TODO:
      # - make accept-reply mechanism on socket.
      # - parse the socket body based on RESP. 
      # - make semantic that moving things.

      # REF:
      # - https://xmonader.github.io/nimdays/day15_tcprouter.html
      # - https://blog.tejasjadhav.xyz/simple-chat-server-in-nim-using-sockets/
      asyncCheck asyncSocketListen()
    except OSError:
        echo "error"
        return

main()
runForever()