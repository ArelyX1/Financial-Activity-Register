import json
from datetime import datetime

from redis_services.redis_client import RedisClient

from disposable_email.domain.entities.disposable_inbox import DisposableInbox
from disposable_email.ports.driven.inbox_repository_port import InboxRepositoryPort

KEY = "disposable_email:inbox"


class RedisInboxRepository(InboxRepositoryPort):
    def __init__(self, redis=None):
        self._redis = redis or RedisClient.get_instance()

    async def get(self) -> DisposableInbox | None:
        raw = await self._redis.get(KEY)
        if not raw:
            return None
        data = json.loads(raw)
        return DisposableInbox(
            address=data["address"],
            password=data["password"],
            account_id=data.get("account_id"),
            discarded=data.get("discarded", False),
            created_at=datetime.fromisoformat(data["created_at"]) if data.get("created_at") else None,
        )

    async def save(self, inbox: DisposableInbox) -> None:
        await self._redis.set(
            KEY,
            json.dumps(
                {
                    "address": inbox.address,
                    "password": inbox.password,
                    "account_id": inbox.account_id,
                    "discarded": inbox.discarded,
                    "created_at": inbox.created_at.isoformat() if inbox.created_at else None,
                }
            ),
        )

    async def mark_discarded(self) -> None:
        raw = await self._redis.get(KEY)
        if not raw:
            return
        data = json.loads(raw)
        data["discarded"] = True
        await self._redis.set(KEY, json.dumps(data))

    async def delete(self) -> None:
        await self._redis.delete(KEY)
