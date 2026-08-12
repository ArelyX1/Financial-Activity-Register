from datetime import datetime
from typing import List, Optional
from sqlalchemy import select, text
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import Column, Integer, String, DateTime, Boolean
from sqlalchemy.dialects.postgresql import UUID
from user_account.ports.driven.user_account_repository_port import UserAccountRepositoryPort
from user_account.domain.entities.user_account import UserAccount
from db.base import Base


class S02UserORM(Base):
    __tablename__ = "S02USER"

    nIdUser = Column("niduser", UUID, primary_key=True, server_default=text("gen_random_uuid()"))
    cUsername = Column("cusername", String(20), nullable=False)
    cEmail = Column("cemail", String(100), nullable=False)
    cHashedPassword = Column("chashedpassword", String(256), nullable=False)
    cWallet = Column("cwallet", String(49), nullable=False)
    cPhrase = Column("cphrase", String)
    cSalt = Column("csalt", String)
    cProviderId = Column("cproviderid", String)
    nIdAccountProvider = Column("nidaccountprovider", Integer)
    bEmailVerified = Column("bemailverified", Boolean)
    tLatestAccess = Column("tlatestaccess", DateTime)
    tCreatedAt = Column("createdat", DateTime, server_default=text("NOW()"))
    cPhotoUrl = Column("cphotourl", String)
    bIsActive = Column("bisactive", Boolean)


class PostgresUserAccountRepository(UserAccountRepositoryPort):
    def __init__(self, session: AsyncSession):
        self._session = session

    async def find_all(self) -> List[UserAccount]:
        stmt = select(S02UserORM).order_by(S02UserORM.tCreatedAt.desc())
        result = await self._session.execute(stmt)
        return [self._to_entity(row) for row in result.scalars().all()]

    async def save(self, data: UserAccount) -> UserAccount:
        orm = S02UserORM(
            nIdUser=data.n_id_user,
            cUsername=data.c_username,
            cEmail=data.c_email,
            cHashedPassword=data.c_hashed_password,
            cWallet=data.c_wallet,
            cPhrase=data.c_phrase,
            cSalt=data.c_salt,
            cProviderId=data.c_provider_id,
            nIdAccountProvider=data.n_id_account_provider,
            bEmailVerified=data.b_email_verified,
            cPhotoUrl=data.c_photo_url,
            bIsActive=data.b_is_active,
        )
        self._session.add(orm)
        await self._session.flush()
        await self._session.commit()
        await self._session.refresh(orm)
        return self._to_entity(orm)

    async def find_by_email(self, email: str) -> Optional[UserAccount]:
        stmt = select(S02UserORM).where(S02UserORM.cEmail == email)
        result = await self._session.execute(stmt)
        orm = result.scalar_one_or_none()
        return self._to_entity(orm) if orm else None

    async def find_by_id(self, n_id_user: str) -> Optional[UserAccount]:
        stmt = select(S02UserORM).where(S02UserORM.nIdUser == n_id_user)
        result = await self._session.execute(stmt)
        orm = result.scalar_one_or_none()
        return self._to_entity(orm) if orm else None

    async def update_status(self, n_id_user: str, b_is_active: bool) -> None:
        stmt = (
            select(S02UserORM)
            .where(S02UserORM.nIdUser == n_id_user)
        )
        result = await self._session.execute(stmt)
        orm = result.scalar_one_or_none()
        if not orm:
            raise ValueError(f"User account with id '{n_id_user}' not found")
        orm.bIsActive = b_is_active
        await self._session.flush()
        await self._session.commit()

    def _to_entity(self, orm: S02UserORM) -> UserAccount:
        return UserAccount(
            n_id_user=str(orm.nIdUser) if orm.nIdUser else None,
            c_username=orm.cUsername,
            c_email=orm.cEmail,
            c_hashed_password=orm.cHashedPassword,
            c_wallet=orm.cWallet,
            c_phrase=orm.cPhrase or "",
            c_salt=orm.cSalt or "",
            c_provider_id=orm.cProviderId or "",
            n_id_account_provider=orm.nIdAccountProvider,
            b_email_verified=orm.bEmailVerified,
            t_latest_access=orm.tLatestAccess,
            created_at=orm.tCreatedAt,
            c_photo_url=orm.cPhotoUrl or "",
            b_is_active=orm.bIsActive,
        )
