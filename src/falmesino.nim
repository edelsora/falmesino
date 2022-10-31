import 
  net
  , strutils
  , asyncdispatch
  , asyncnet
  , redisparser

const SERVER_PORT = Port(6789)

proc asyncSocketListen() {.async.} =
  var server = newAsyncSocket(buffered=false)
  server.setSockOpt(OptReuseAddr, true)
  server.bindAddr(SERVER_PORT)
  server.listen()
  
  while true:
    let client = await server.accept()
    echo "* Connected with $1".format(client.getPeerAddr())

    # TODO: Investigate this why not work as usual sting.
    let data = await client.recv(1024)
    echo data
    echo data.len()
    echo data.find("\r\n")
    # try:
    let parsedRESPContent = redisparser.decodeString(data)
    await client.send("What redis thingy : $1".format(parsedRESPContent))
    client.close()
    # except:
    #   echo getCurrentException()
    #   await client.send(getCurrentExceptionMsg())
    # finally:
    #   client.close()  

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