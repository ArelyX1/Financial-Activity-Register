from password_recovery.ports.driven.recovery_code_repository_port import RecoveryCodeRepositoryPort
from redis_services.redis_client import RedisClient


class RedisRecoveryCodeRepository(RecoveryCodeRepositoryPort):
    def __init__(self, redis=None):
        self._redis = redis or RedisClient.get_instance()

    def _key(self, identification_number: str) -> str:
        return f"password_recovery:code:{identification_number}"

    async def save(self, identification_number: str, code: str, ttl_seconds: int) -> None:
        await self._redis.setex(self._key(identification_number), ttl_seconds, code)

    async def verify(self, identification_number: str, code: str) -> bool:
        stored = await self._redis.get(self._key(identification_number))
        if stored is None or stored != code:
            return False
        await self._redis.delete(self._key(identification_number))
        return True

    async def delete(self, identification_number: str) -> None:
        await self._redis.delete(self._key(identification_number))
