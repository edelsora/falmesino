import 
    net
    , strutils
    , asyncdispatch
    , asyncnet
    , lib/semantic
    , lib/store
    , lib/entities/cache
    , lib/entities/packer
    , options
    , terminal

const SERVER_PORT = Port(6789)

# Always change VERSION when you want to release this shit
const VERSION : Version = (0,0,1,"alpha","202211081307")

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
      # REF:
      # - https://xmonader.github.io/nimdays/day15_tcprouter.html
      # - https://blog.tejasjadhav.xyz/simple-chat-server-in-nim-using-sockets/

        var server = newAsyncSocket(buffered=false)
        server.setSockOpt(OptReuseAddr, true)
        server.bindAddr(SERVER_PORT)
        server.listen()
        echo "[***] falmesino service run on: $1, CTRL+C to stop.".format(SERVER_PORT)

        while true:
            var tc = acceptClient(tables,server)
            proc cb(f:Future[Option[CacheTableLock]]) {.gcsafe.} =
                let fr = f.read()
                if fr.isSome:
                    tables.mergeTable(fr.get())

            tc.callback= cb
            yield tc
    except OSError:
        echo "[!!!] $1".format(getCurrentExceptionMsg())
        return

proc loadFromDumpFile() =
    echo "[...] load from dump file"
    let tablesFromDumpFile = loadDumpFileToMemory("key-value-pair.falmesino")
    if tablesFromDumpFile.isSome:
        tables = tablesFromDumpFile.get().database
        return

    echo "[!!!] dump file not found, start new database in memory"
    tables = newCacheTableLock()

when isMainModule:
    echo "[...] falmesino $1 starting".format(VERSION.toVersionString)
    loadFromDumpFile()
    proc exitHandler() {.noconv.} = 
        # TODO: make the CTRL+C Interupt to store data into filesystem with MsgPack format
        eraseScreen() #puts cursor at down
        setCursorPos(0, 0)
        echo "[...] falmesino backup the current tables to filesystem...."
        if dumpCacheToFile("key-value-pair.falmesino",newPacker(tables,VERSION)):
            echo "[***] sucessfully, store to disk"
            quit 0
        
        echo "[!!!] failed to store to disc"
        quit 1
        
    setControlCHook(exitHandler)
    waitFor main()