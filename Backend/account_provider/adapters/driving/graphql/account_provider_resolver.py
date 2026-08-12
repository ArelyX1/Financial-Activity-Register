import strawberry
from typing import List
from strawberry.types import Info
from account_provider.domain.services.account_provider_service import AccountProviderService
from account_provider.adapters.driven.postgres_account_provider_repository import PostgresAccountProviderRepository
from account_provider.domain.entities.account_provider import AccountProvider as AccountProviderEntity
from db.config import AsyncSessionLocal
from auth.adapters.driving.graphql.helpers import enforce_access


@strawberry.type
class AccountProvider:
    id: int
    name: str
    is_active: bool | None


@strawberry.type
class Query:
    @strawberry.field
    async def account_providers(self) -> List[AccountProvider]:
        async with AsyncSessionLocal() as session:
            repo = PostgresAccountProviderRepository(session)
            service = AccountProviderService(repo)
            items = await service.get_all()
            return [
                AccountProvider(
                    id=item.n_id_account_provider,
                    name=item.c_name,
                    is_active=item.b_is_active,
                )
                for item in items
            ]


@strawberry.input
class CreateAccountProviderInput:
    name: str
    is_active: bool | None = True


@strawberry.type
class Mutation:
    @strawberry.mutation
    async def create_account_provider(self, info: Info, token: str, input: CreateAccountProviderInput) -> AccountProvider:
        await enforce_access(token, "create_account_provider")
        async with AsyncSessionLocal() as session:
            repo = PostgresAccountProviderRepository(session)
            service = AccountProviderService(repo)
            entity = AccountProviderEntity(
                c_name=input.name,
                b_is_active=input.is_active,
            )
            created = await service.create(entity)
            return AccountProvider(
                id=created.n_id_account_provider,
                name=created.c_name,
                is_active=created.b_is_active,
            )
