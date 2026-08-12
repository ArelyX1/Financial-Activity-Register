import os
from pathlib import Path
from dotenv import load_dotenv
from redis.asyncio import Redis

load_dotenv(dotenv_path=Path(__file__).parent / ".env")


class RedisClient:
    _instance: Redis | None = None

    @classmethod
    def get_instance(cls) -> Redis:
        if cls._instance is None:
            url = os.getenv("REDIS_URL", "redis://localhost:6379/0")
            cls._instance = Redis.from_url(url, decode_responses=True)
        return cls._instance

    @classmethod
    async def ping(cls) -> bool:
        try:
            instance = cls.get_instance()
            return await instance.ping()
        except Exception:
            return False

    @classmethod
    async def close(cls) -> None:
        if cls._instance is not None:
            await cls._instance.close()
            cls._instance = None
