from abc import ABC, abstractmethod
from typing import List
from account_provider.domain.entities.account_provider import AccountProvider


class AccountProviderInputPort(ABC):
    @abstractmethod
    async def get_all(self) -> List[AccountProvider]: ...

    @abstractmethod
    async def create(self, data: AccountProvider) -> AccountProvider: ...
