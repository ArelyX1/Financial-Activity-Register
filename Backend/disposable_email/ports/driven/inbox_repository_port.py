from abc import ABC, abstractmethod

from disposable_email.domain.entities.disposable_inbox import DisposableInbox


class InboxRepositoryPort(ABC):
    @abstractmethod
    async def get(self) -> DisposableInbox | None:
        ...

    @abstractmethod
    async def save(self, inbox: DisposableInbox) -> None:
        ...

    @abstractmethod
    async def mark_discarded(self) -> None:
        ...

    @abstractmethod
    async def delete(self) -> None:
        ...
