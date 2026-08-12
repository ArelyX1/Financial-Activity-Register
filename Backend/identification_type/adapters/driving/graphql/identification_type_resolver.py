import strawberry
from typing import List
from strawberry.types import Info
from identification_type.domain.services.identification_type_service import IdentificationTypeService
from identification_type.adapters.driven.postgres_identification_type_repository import PostgresIdentificationTypeRepository
from identification_type.domain.entities.identification_type import IdentificationType as IdentificationTypeEntity
from db.config import AsyncSessionLocal
from auth.adapters.driving.graphql.helpers import enforce_access


@strawberry.type
class IdentificationType:
    id: int
    country_iso: str
    code: str | None
    name: str
    min_length: int
    max_length: int
    is_numeric: bool | None
    regex: str | None
    is_active: bool | None


@strawberry.type
class Query:
    @strawberry.field
    async def identification_types(self, info: Info, token: str) -> List[IdentificationType]:
        await enforce_access(token, "identification_types")
        async with AsyncSessionLocal() as session:
            repo = PostgresIdentificationTypeRepository(session)
            service = IdentificationTypeService(repo)
            items = await service.get_all()
            return [
                IdentificationType(
                    id=item.n_id_identification_type,
                    country_iso=item.c_country_iso,
                    code=item.c_code,
                    name=item.c_name,
                    min_length=item.n_min_length,
                    max_length=item.n_max_length,
                    is_numeric=item.b_is_numeric,
                    regex=item.c_regex,
                    is_active=item.b_is_active,
                )
                for item in items
            ]


@strawberry.input
class CreateIdentificationTypeInput:
    country_iso: str
    code: str | None = None
    name: str
    min_length: int = 1
    max_length: int
    is_numeric: bool | None = True
    regex: str
    is_active: bool | None = True


@strawberry.type
class Mutation:
    @strawberry.mutation
    async def create_identification_type(self, info: Info, token: str, input: CreateIdentificationTypeInput) -> IdentificationType:
        await enforce_access(token, "create_identification_type")
        async with AsyncSessionLocal() as session:
            repo = PostgresIdentificationTypeRepository(session)
            service = IdentificationTypeService(repo)
            entity = IdentificationTypeEntity(
                c_country_iso=input.country_iso,
                c_code=input.code,
                c_name=input.name,
                n_min_length=input.min_length,
                n_max_length=input.max_length,
                b_is_numeric=input.is_numeric,
                c_regex=input.regex,
                b_is_active=input.is_active,
            )
            created = await service.create(entity)
            return IdentificationType(
                id=created.n_id_identification_type,
                country_iso=created.c_country_iso,
                code=created.c_code,
                name=created.c_name,
                min_length=created.n_min_length,
                max_length=created.n_max_length,
                is_numeric=created.b_is_numeric,
                regex=created.c_regex,
                is_active=created.b_is_active,
            )
