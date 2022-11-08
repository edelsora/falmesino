import entities/cache
    , msgpack4nim
    , options

proc dumpCacheToFile*(filepath: string, table: CacheTableLock) : bool =
    try:
        writeFile(filepath, pack(table))
        return true
    except:
        return false

proc loadDumpFileToMemory(filepath: string) : Option[CacheTableLock] = discard