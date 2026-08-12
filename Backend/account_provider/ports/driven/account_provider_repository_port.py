from abc import ABC, abstractmethod
from typing import List
from account_provider.domain.entities.account_provider import AccountProvider


class AccountProviderRepositoryPort(ABC):
    @abstractmethod
    async def find_all(self) -> List[AccountProvider]: ...

    @abstractmethod
    async def save(self, data: AccountProvider) -> AccountProvider: ...
