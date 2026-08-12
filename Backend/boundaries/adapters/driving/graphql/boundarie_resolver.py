import strawberry
from typing import List
from boundaries.domain.services.boundarie_service import BoundarieService
from boundaries.adapters.driven.postgres_boundarie_repository import PostgresBoundarieRepository
from db.config import AsyncSessionLocal


@strawberry.type
class Location:
    id: int
    code: str
    name: str


@strawberry.type
class Query:
    @strawberry.field
    async def geo1(self) -> List[Location]:
        async with AsyncSessionLocal() as session:
            repo = PostgresBoundarieRepository(session)
            service = BoundarieService(repo)
            return [Location(id=c.uid, code=c.geo1, name=c.geo1_name) for c in await service.get_geo1()]

    @strawberry.field
    async def geo2(self, geo1_id: int) -> List[Location]:
        async with AsyncSessionLocal() as session:
            repo = PostgresBoundarieRepository(session)
            service = BoundarieService(repo)
            return [Location(id=r.uid, code=r.geo2, name=r.geo2_name) for r in await service.get_geo2(geo1_id)]

    @strawberry.field
    async def geo3(self, geo2_id: int) -> List[Location]:
        async with AsyncSessionLocal() as session:
            repo = PostgresBoundarieRepository(session)
            service = BoundarieService(repo)
            return [Location(id=p.uid, code=p.geo3, name=p.geo3_name) for p in await service.get_geo3(geo2_id)]

    @strawberry.field
    async def geo4(self, geo3_id: int) -> List[Location]:
        async with AsyncSessionLocal() as session:
            repo = PostgresBoundarieRepository(session)
            service = BoundarieService(repo)
            return [Location(id=d.uid, code=d.geo4, name=d.geo4_name) for d in await service.get_geo4(geo3_id)]
