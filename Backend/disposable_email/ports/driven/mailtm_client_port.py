from abc import ABC, abstractmethod

from disposable_email.domain.entities.disposable_inbox import DisposableInbox


class MailtmClientPort(ABC):
    @abstractmethod
    async def create_account(self) -> DisposableInbox:
        ...

    @abstractmethod
    async def is_account_active(self, address: str, password: str) -> bool:
        ...

    @abstractmethod
    async def delete_account(self, account_id: str, address: str, password: str) -> bool:
        ...
