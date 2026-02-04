# -*- coding: utf-8 -*-

TORTOISE_ORM = {
    "connections": {
        "default": {
            "engine": "tortoise.backends.mysql",
            "credentials": {
                "host": "${DB_HOST}",
                "port": "${DB_PORT}",
                "user": "${DB_USER}",
                "password": "${DB_PASSWORD}",
                "database": "${DB_DATABASE}",
            }
        }
    },
    "apps": {
        "models": {
            "models": ["db.models", "aerich.models"],
            "default_connection": "default",
        }
    }
}
