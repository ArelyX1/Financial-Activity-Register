from typing import List
from account_provider.ports.driving.account_provider_input_port import AccountProviderInputPort
from account_provider.ports.driven.account_provider_repository_port import AccountProviderRepositoryPort
from account_provider.domain.entities.account_provider import AccountProvider


class AccountProviderService(AccountProviderInputPort):
    def __init__(self, repo: AccountProviderRepositoryPort):
        self._repo = repo

    async def get_all(self) -> List[AccountProvider]:
        return await self._repo.find_all()

    async def create(self, data: AccountProvider) -> AccountProvider:
        return await self._repo.save(data)
