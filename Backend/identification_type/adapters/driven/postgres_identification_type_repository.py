from typing import List
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import Column, Integer, String, Boolean
from identification_type.ports.driven.identification_type_repository_port import IdentificationTypeRepositoryPort
from identification_type.domain.entities.identification_type import IdentificationType
from db.base import Base


class S02IdentificationTypeORM(Base):
    __tablename__ = "S01IDENTIFICATION_TYPE"

    nIdIdentificationType = Column("nididentificationtype", Integer, primary_key=True)
    cCountryIso = Column("ccountryiso", String(3), nullable=False)
    cCode = Column("ccode", String(5))
    cName = Column("cname", String(100), nullable=False)
    nMinLength = Column("nminlength", Integer, nullable=False)
    nMaxLength = Column("nmaxlength", Integer, nullable=False)
    bIsNumeric = Column("bisnumeric", Boolean)
    cRegex = Column("cregex", String(100))
    bIsActive = Column("bisactive", Boolean)


class PostgresIdentificationTypeRepository(IdentificationTypeRepositoryPort):
    def __init__(self, session: AsyncSession):
        self._session = session

    async def find_all(self) -> List[IdentificationType]:
        stmt = select(S02IdentificationTypeORM).order_by(S02IdentificationTypeORM.cName)
        result = await self._session.execute(stmt)
        return [self._to_entity(row) for row in result.scalars().all()]

    async def save(self, data: IdentificationType) -> IdentificationType:
        orm = S02IdentificationTypeORM(
            cCountryIso=data.c_country_iso,
            cCode=data.c_code,
            cName=data.c_name,
            nMinLength=data.n_min_length,
            nMaxLength=data.n_max_length,
            bIsNumeric=data.b_is_numeric,
            cRegex=data.c_regex,
            bIsActive=data.b_is_active,
        )
        self._session.add(orm)
        await self._session.flush()
        await self._session.commit()
        return self._to_entity(orm)

    def _to_entity(self, orm: S02IdentificationTypeORM) -> IdentificationType:
        return IdentificationType(
            n_id_identification_type=orm.nIdIdentificationType,
            c_country_iso=orm.cCountryIso,
            c_code=orm.cCode,
            c_name=orm.cName,
            n_min_length=orm.nMinLength,
            n_max_length=orm.nMaxLength,
            b_is_numeric=orm.bIsNumeric,
            c_regex=orm.cRegex,
            b_is_active=orm.bIsActive,
        )
