import entities/cache
    , entities/packer
    , msgpack4nim
    , options
    , strutils

proc dumpCacheToFile*(filepath: string, packer: Packer) : bool =
    try:
        writeFile(filepath, pack(packer))
        return true
    except:
        return false

# proc loadDumpFileToMemory*(filepath: string) : Option[CacheTableLock] =
#     var c : CacheTableLock
#     try:
#         let dumpStr = readFile(filepath)
#         unpack(dumpStr,c)
#         return some(c)
#     except:
#         echo "[!!!] $1".format(getCurrentExceptionMsg())
#         return none(CacheTableLock)
        
proc loadDumpFileToMemory*(filepath: string) : Option[Packer] =
    var c : Packer
    try:
        let dumpStr = readFile(filepath)
        unpack(dumpStr,c)
        return some(c)
    except:
        echo "[!!!] $1".format(getCurrentExceptionMsg())
        return none(Packer)