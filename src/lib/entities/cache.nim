import times
    , tables
    , locks
    , options
    , redisparser
    , sets

type
    CacheType = enum
        ctInt, ctString, ctArray

    CacheValue = ref object
        case kind : CacheType
            of ctString: vStr: string
            of ctInt: vInt: int
            of ctArray: vArray: seq[CacheValue]
    
    CacheEntry = ref object 
        value: CacheValue
        ttl: Option[Duration]

    CacheTable = Table[string, CacheEntry]

    CacheTableLock* = object
        cache*: CacheTable
        # lock*: locks.Lock

func isString(v: CacheValue) : bool = return v.kind == ctString
func isInteger(v: CacheValue) : bool = return v.kind == ctInt
func isArray(v: CacheValue) : bool = return v.kind == ctArray
func getArray(v: CacheValue): seq[CacheValue] = return v.vArray
func getInt(v: CacheValue): int = return v.vInt
func getStr(v: CacheValue): string = return v.vStr

# TODO: complete cache table mecahnism
func newCacheTableLock*(): CacheTableLock =
    result.cache = CacheTable()
    # initLock(result.lock)

# proc lockTable*(t: var CacheTableLock) = locks.acquire(t.lock)

# proc unlockTable*(t: var CacheTableLock) = locks.release(t.lock)

proc mergeTable*(t: var CacheTableLock, tt: CacheTableLock) =
    var baseKeys: seq[string] = @[] 
    for key in t.cache.keys():
        baseKeys.add(key)
    
    var foreignKeys: seq[string] = @[]
    for key in tt.cache.keys():
        foreignKeys.add(key)
    let foreignKeysSet = foreignKeys.toHashSet()

    let unifiedKeys = baseKeys
        .toHashSet()
        .union(
            foreignKeysSet
        )
    for key in unifiedKeys:
        if foreignKeysSet.contains(key):
            t.cache[key] = tt.cache[key]

func convertArrayTypeRedisValueToSeqCacheValue(v: RedisValue) : seq[CacheValue] =
    if v.isArray():
        var values : seq[CacheValue] = @[]

        for item in v.getItems():
            var value = new(CacheValue)

            if item.isInteger():
                value.kind = ctInt
                value.vInt = v.getInt()

            if item.isString() or item.isBulkString():
                value.kind = ctString
                value.vStr = v.getStr()

            if item.isArray():
                value.kind = ctArray
                value.vArray = convertArrayTypeRedisValueToSeqCacheValue(v)

            values.add(value)

        return values

func convertCacheValueToRedisValue(v: CacheValue) : RedisValue =
    if v.isArray():
        var items : seq[RedisValue] = @[]

        for item in v.vArray:
            if item.isInteger():
                items.add(newRedisInt(item.getInt()))

            if item.isString():
                items.add(newRedisString(item.getStr()))

            if item.isArray():
                items.add(
                    convertCacheValueToRedisValue(item)
                )

        return newRedisArray(items)
        
    if v.isString():
        return  newRedisString(v.getStr())

    if v.isInteger():
        return newRedisInt(v.getInt())


# TODO: make getter and setter for cache table 
proc setKey*(t: var CacheTableLock, key: string, value: RedisValue) : bool =
    var cacheValue = new(CacheValue)
    if value.isString() or value.isBulkString():
        cacheValue.kind = ctString
        cacheValue.vStr = value.getStr()

    if value.isInteger():
        cacheValue.kind = ctInt
        cacheValue.vInt = value.getInt()

    if value.isArray():
        cacheValue.kind = ctArray
        cacheValue.vArray = convertArrayTypeRedisValueToSeqCacheValue(value)

    if cacheValue.isNil():
        return false

    var cacheEntry = CacheEntry(
        value: cacheValue
        , ttl: none(Duration)
    )

    t.cache[key] = cacheEntry
    return true


proc setExpiry(t: var CacheTableLock, key: string, sec: int) : bool = discard

proc getKey*(t: var CacheTableLock, key: string) : Option[RedisValue] = 
    try:
        return some(convertCacheValueToRedisValue(t.cache[key].value))
    except KeyError:
        return none(RedisValue)