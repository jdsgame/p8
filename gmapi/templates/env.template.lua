local boot = require("boot")

local USER = {
    -- KINGNET
    KINGNET_APP_ID = "${KINGNET_APP_ID}",
    KINGNET_APP_KEY = "${KINGNET_APP_KEY}",
    KINGNET_PLATFORM_ID = "${KINGNET_PLATFORM_ID}",
    KINGNET_GM_URL = "${KINGNET_GM_URL}",

    -- 外网端口
    NGINX_HTTP_PORT = 80,
    -- 内网端口
    NGINX_INTERNAL_PORT = 81,

    -- 数据库
    MYSQL_HOST = "${MYSQL_HOST}",
    MYSQL_USER = "${MYSQL_USER}",
    MYSQL_PASSWORD = "${MYSQL_PASSWORD}",
    MYSQL_DATABASE = "${MYSQL_DATABASE}",

    -- 共享内存
    SHM_CACHE = "p8_gm_api_cache_shm",
    SHM_CACHE_MISS = "p8_gm_api_cache_shm_miss",
    SHM_IPC = "p8_gm_api_ipc_shm",

    -- Redis 缓存
    CACHE_DATABASE = "${CACHE_DATABASE}",

    -- 游戏服
    GAME_GM_URL = "${GAME_GM_URL}",

    -- 华为OBS
    OBS_ACCESS_KEY_ID = "${OBS_ACCESS_KEY_ID}",
    OBS_ACCESS_KEY = "${OBS_ACCESS_KEY}",
    OBS_ENDPOINT = "${OBS_ENDPOINT}",
    OBS_BUCKET = "${OBS_BUCKET}",
    OBS_SERVERLIST_NAME = "${OBS_SERVERLIST_NAME}",
    OBS_NOTICE_NAME = "${OBS_NOTICE_NAME}",

    -- 华为CDN
    CDN_REFRESH_URL = "${CDN_REFRESH_URL}",
    CDN_URL = "${CDN_URL}",
    CDN_PROJECT_ID = "${CDN_PROJECT_ID}",
    CDN_ACCESS_KEY_ID = "${CDN_ACCESS_KEY_ID}",
    CDN_ACCESS_KEY = "${CDN_ACCESS_KEY}",
}
USER.__index = USER

return boot.getenv(USER) --[[@as env.USER]]