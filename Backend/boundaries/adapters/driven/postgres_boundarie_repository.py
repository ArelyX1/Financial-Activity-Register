from typing import List
from sqlalchemy import select, and_, func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import Column, Integer, String
from boundaries.ports.driven.boundarie_repository_port import BoundarieRepositoryPort
from boundaries.domain.entities.boundarie import Boundarie
from db.base import Base


class S01BoundarieORM(Base):
    __tablename__ = "S01BOUNDARIE"

    nUidGadm = Column("nuidgadm", Integer, primary_key=True)
    cGid0 = Column("cgid0", String(5))
    cName0 = Column("cname0", String(100))
    cGid1 = Column("cgid1", String(20))
    cName1 = Column("cname1", String(100))
    cGid2 = Column("cgid2", String(20))
    cName2 = Column("cname2", String(100))
    cGid3 = Column("cgid3", String(20))
    cName3 = Column("cname3", String(100))


class PostgresBoundarieRepository(BoundarieRepositoryPort):
    def __init__(self, session: AsyncSession):
        self._session = session

    async def get_geo1(self) -> List[Boundarie]:
        stmt = (
            select(S01BoundarieORM.cGid0, S01BoundarieORM.cName0, func.min(S01BoundarieORM.nUidGadm))
            .where(S01BoundarieORM.cGid0.isnot(None))
            .group_by(S01BoundarieORM.cGid0, S01BoundarieORM.cName0)
            .order_by(S01BoundarieORM.cName0)
        )
        result = await self._session.execute(stmt)
        return [Boundarie(geo1=row[0], geo1_name=row[1], uid=row[2]) for row in result.all()]

    async def get_geo2_by_geo1(self, geo1_id: int) -> List[Boundarie]:
        parent = await self._session.get(S01BoundarieORM, geo1_id)
        if not parent:
            return []
        stmt = (
            select(S01BoundarieORM.cGid1, S01BoundarieORM.cName1, func.min(S01BoundarieORM.nUidGadm))
            .where(
                and_(
                    S01BoundarieORM.cGid0 == parent.cGid0,
                    S01BoundarieORM.cGid1.isnot(None)
                )
            )
            .group_by(S01BoundarieORM.cGid1, S01BoundarieORM.cName1)
            .order_by(S01BoundarieORM.cName1)
        )
        result = await self._session.execute(stmt)
        return [Boundarie(geo2=row[0], geo2_name=row[1], uid=row[2]) for row in result.all()]

    async def get_geo3_by_geo2(self, geo2_id: int) -> List[Boundarie]:
        parent = await self._session.get(S01BoundarieORM, geo2_id)
        if not parent:
            return []
        stmt = (
            select(S01BoundarieORM.cGid2, S01BoundarieORM.cName2, func.min(S01BoundarieORM.nUidGadm))
            .where(
                and_(
                    S01BoundarieORM.cGid0 == parent.cGid0,
                    S01BoundarieORM.cGid1 == parent.cGid1,
                    S01BoundarieORM.cGid2.isnot(None)
                )
            )
            .group_by(S01BoundarieORM.cGid2, S01BoundarieORM.cName2)
            .order_by(S01BoundarieORM.cName2)
        )
        result = await self._session.execute(stmt)
        return [Boundarie(geo3=row[0], geo3_name=row[1], uid=row[2]) for row in result.all()]

    async def get_geo4_by_geo3(self, geo3_id: int) -> List[Boundarie]:
        parent = await self._session.get(S01BoundarieORM, geo3_id)
        if not parent:
            return []
        stmt = (
            select(S01BoundarieORM.cGid3, S01BoundarieORM.cName3, func.min(S01BoundarieORM.nUidGadm))
            .where(
                and_(
                    S01BoundarieORM.cGid0 == parent.cGid0,
                    S01BoundarieORM.cGid1 == parent.cGid1,
                    S01BoundarieORM.cGid2 == parent.cGid2,
                    S01BoundarieORM.cGid3.isnot(None)
                )
            )
            .group_by(S01BoundarieORM.cGid3, S01BoundarieORM.cName3)
            .order_by(S01BoundarieORM.cName3)
        )
        result = await self._session.execute(stmt)
        return [Boundarie(geo4=row[0], geo4_name=row[1], uid=row[2]) for row in result.all()]
