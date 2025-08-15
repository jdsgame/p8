local config = require "lapis.config"

-- Lua 库路径
local lua_path = "../?.lua;../src/?.lua;../src/?/init.lua"
local lua_cpath = ""

config("development", {
    server      = "nginx",
    code_cache  = "on",
    num_workers = 4,
    port        = 80,
    lua_path    = lua_path,
    lua_cpath   = lua_cpath,
    
    mysql = {
        host     = "${DEV_MYSQL_HOST}",
        user     = "${DEV_MYSQL_USER}",
        password = "${DEV_MYSQL_PASSWORD}",
        database = "${DEV_MYSQL_DATABASE}",
        adapter  = "mysql",
        charset  = "utf8mb4",
        timezone = "${DEV_TIMEZONE}"
    },

    redis = {
        host     = "${DEV_REDIS_HOST}",
        port     = "${DEV_REDIS_PORT}",
        database = "${DEV_REDIS_DATABASE}",
        password = "${DEV_REDIS_PASSWORD}"
    },

    cache = {
        shm_name = "cache_shm",
        ipc_shm  = "ipc_shm",         -- IPC 通信共享内存
        lru_size = 1024 * 1024 * 10,  -- L1 缓存大小
        ttl      = 300,               -- 命中缓存过期时间 (秒)
        neg_ttl  = 60                 -- 未命中缓存过期时间 (秒)
    }
})

config("production", {
    server      = "nginx",
    code_cache  = "on",
    num_workers = 4,
    port        = 80,
    lua_path    = lua_path,
    lua_cpath   = lua_cpath,
    
    mysql = {
        host     = "${PRO_MYSQL_HOST}",
        user     = "${PRO_MYSQL_USER}",
        password = "${PRO_MYSQL_PASSWORD}",
        database = "${PRO_MYSQL_DATABASE}",
        adapter  = "mysql",
        charset  = "utf8mb4",
        timezone = "${PRO_TIMEZONE}"
    },

    redis = {
        host     = "${PRO_REDIS_HOST}",
        port     = "${PRO_REDIS_PORT}",
        database = "${PRO_REDIS_DATABASE}",
        password = "${PRO_REDIS_PASSWORD}"
    },

    cache = {
        shm_name = "cache_shm",
        ipc_shm  = "ipc_shm",         -- IPC 通信共享内存
        lru_size = 1024 * 1024 * 10,  -- L1 缓存大小
        ttl      = 300,               -- 命中缓存过期时间 (秒)
        neg_ttl  = 60                 -- 未命中缓存过期时间 (秒)
    }
})