import 
    redisparser 
    , strutils

type
    DbAction* = enum
        daGet, daSet, daSetx, daDel

    DbExpiry* = enum
        deNeverExpire, deExpireAt

    DbExpiryD* = object 
        case mode: DbExpiry
        of deExpireAt : sec: int
        of deNeverExpire: discard

    # DbActionSet Description
    DaSetD* = object
        key*: string
        value*: RedisValue
        expiry*: DbExpiryD

    DbActionD* = object
        case action*: DbAction
        of daDel, daGet : key*: string
        of daSet, daSetx: desc*: DaSetD

# This basicly parsing token into semantic tree.
proc newDbActionDFromRedisValue*(protocolValue: RedisValue) : DbActionD =
    if protocolValue.isNil:
        raise newException(ValueError, "protocol value is nil")

    if protocolValue.isArray():
        var data = protocolValue.getItems()
        let header = data[0]
        if header.isString() or header.isBulkString():
            case header.getStr():
            # GET [KEY]
            of "GET":
                if data.len != 2:
                    raise newException(TypeError, "you forget put key for GET operation, GET [key]")

                var key = data[1]
                if not(key.isString() or key.isBulkString()):
                    raise newException(TypeError,"Invalid data type key for GET command, it should be string")

                result = DbActionD(
                    action:daGet
                    , key: key.getStr()
                )
            # DEL [KEY]
            of "DEL":
                if data.len != 3:
                    raise newException(TypeError, "you forget put key for DEL operation, DEL [key]")

                var key = data[1]
                if not (key.isString() or key.isBulkString()):
                    raise newException(TypeError,"Invalid data type key for DEL command, it should be string")

                result = DbActionD(
                    action:daDel
                    , key: key.getStr()
                )
            # SET [KEY] [DATA]
            of "SET":
                if data.len != 3:
                    raise newException(TypeError, "you forget put key or value for SET operation, SET [key] [value]")

                var key = data[1]
                if not (key.isString() or key.isBulkString()):
                    raise newException(TypeError,"Invalid data type key for SET command, it should be string")

                result = DbActionD(
                    action:daSet
                    , desc: DaSetD(
                        key: key.getStr()
                        , value: data[2]
                        , expiry: DbExpiryD(
                            mode: deNeverExpire
                        )
                    )                    
                )
            # SETX [KEY] [EXPIRY] [DATA]
            of "SETX":
                if data.len != 4:
                    raise newException(TypeError, "you forget put key, expiry second, or data for SETX operation, SETX [key]")

                var key = data[1]
                if not (key.isString() or key.isBulkString()):
                    raise newException(TypeError,"Invalid data type key for SETX command, it should be string")

                var expiry = data[2]
                if not expiry.isInteger():
                    raise newException(TypeError,"Invalid data type expiry for SETX command, it should be int")

                result = DbActionD(
                    action:daSet
                    , desc: DaSetD(
                        key: key.getStr()
                        , value: data[3]
                        , expiry: DbExpiryD(
                            mode: deExpireAt
                            , sec: expiry.getInt()
                        )
                    )                    
                )
            
proc debugDbActionD*(action: DbActionD): string =
    return "Order: $1".format(action.action)