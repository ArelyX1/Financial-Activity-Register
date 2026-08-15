from datetime import datetime, timezone

from disposable_email.domain.entities.disposable_inbox import DisposableInbox
from disposable_email.ports.driven.inbox_repository_port import InboxRepositoryPort
from disposable_email.ports.driven.mailtm_client_port import MailtmClientPort


class DisposableEmailService:
    def __init__(self, client: MailtmClientPort, repo: InboxRepositoryPort):
        self._client = client
        self._repo = repo

    async def get_or_create_active(self) -> DisposableInbox:
        stored = await self._repo.get()
        if stored and not stored.discarded:
            if await self._client.is_account_active(stored.address, stored.password):
                return stored
            await self._discard_stored(stored)

        inbox = await self._client.create_account()
        inbox.created_at = datetime.now(timezone.utc)
        await self._repo.save(inbox)
        return inbox

    async def discard(self) -> None:
        stored = await self._repo.get()
        if stored:
            await self._discard_stored(stored)

    async def _discard_stored(self, inbox: DisposableInbox) -> None:
        await self._client.delete_account(inbox.account_id, inbox.address, inbox.password)
        await self._repo.mark_discarded()
