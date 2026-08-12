from typing import List
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import Column, Integer, String, Boolean
from account_provider.ports.driven.account_provider_repository_port import AccountProviderRepositoryPort
from account_provider.domain.entities.account_provider import AccountProvider
from db.base import Base


class S01AccountProviderORM(Base):
    __tablename__ = "S01ACCOUNT_PROVIDER"

    nIdAccountProvider = Column("nidaccountprovider", Integer, primary_key=True)
    cName = Column("cname", String(50), nullable=False)
    bIsActive = Column("bisactive", Boolean)


class PostgresAccountProviderRepository(AccountProviderRepositoryPort):
    def __init__(self, session: AsyncSession):
        self._session = session

    async def find_all(self) -> List[AccountProvider]:
        stmt = select(S01AccountProviderORM).order_by(S01AccountProviderORM.cName)
        result = await self._session.execute(stmt)
        return [self._to_entity(row) for row in result.scalars().all()]

    async def save(self, data: AccountProvider) -> AccountProvider:
        orm = S01AccountProviderORM(
            cName=data.c_name,
            bIsActive=data.b_is_active,
        )
        self._session.add(orm)
        await self._session.flush()
        await self._session.commit()
        return self._to_entity(orm)

    def _to_entity(self, orm: S01AccountProviderORM) -> AccountProvider:
        return AccountProvider(
            n_id_account_provider=orm.nIdAccountProvider,
            c_name=orm.cName,
            b_is_active=orm.bIsActive,
        )
