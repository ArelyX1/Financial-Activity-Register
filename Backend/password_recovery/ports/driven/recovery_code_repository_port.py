from abc import ABC, abstractmethod


class RecoveryCodeRepositoryPort(ABC):
    @abstractmethod
    async def save(self, identification_number: str, code: str, ttl_seconds: int) -> None: ...

    @abstractmethod
    async def verify(self, identification_number: str, code: str) -> bool: ...

    @abstractmethod
    async def delete(self, identification_number: str) -> None: ...
