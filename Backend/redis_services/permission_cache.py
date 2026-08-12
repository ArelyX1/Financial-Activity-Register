import json
import os
import logging
from typing import Any
from redis.asyncio import Redis
from redis.exceptions import RedisError
from redis_services.redis_client import RedisClient


class PermissionCache:
    def __init__(self, redis: Redis | None = None, ttl_minutes: int = 0):
        self._redis = redis or RedisClient.get_instance()
        self._ttl = ttl_minutes or int(os.getenv("PERMISSION_CACHE_TTL_MINUTES", "15"))
        self._ttl_seconds = self._ttl * 60
        self._enabled = True

    async def get_permissions(self, user_id: str) -> list[dict[str, Any]] | None:
        if not self._enabled:
            return None
        try:
            key = f"user:{user_id}:permissions"
            data = await self._redis.get(key)
            if data is not None:
                return json.loads(data)
        except RedisError:
            self._enabled = False
        except Exception:
            self._enabled = False
        return None

    async def set_permissions(self, user_id: str, permissions: list[dict[str, Any]]) -> None:
        if not self._enabled:
            return
        try:
            key = f"user:{user_id}:permissions"
            await self._redis.setex(key, self._ttl_seconds, json.dumps(permissions, default=str))
        except RedisError:
            self._enabled = False
        except Exception:
            self._enabled = False

    async def invalidate(self, user_id: str) -> None:
        if not self._enabled:
            return
        try:
            key = f"user:{user_id}:permissions"
            await self._redis.delete(key)
        except RedisError:
            self._enabled = False
        except Exception:
            self._enabled = False
