import entities/cache
    , msgpack4nim
    , options
    , strutils

proc dumpCacheToFile*(filepath: string, table: CacheTableLock) : bool =
    try:
        writeFile(filepath, pack(table))
        return true
    except:
        return false

proc loadDumpFileToMemory*(filepath: string) : Option[CacheTableLock] =
    var c : CacheTableLock
    try:
        let dumpStr = readFile(filepath)
        unpack(dumpStr,c)
        return some(c)
    except:
        echo "[!!!] $1".format(getCurrentExceptionMsg())
        return none(CacheTableLock)
        