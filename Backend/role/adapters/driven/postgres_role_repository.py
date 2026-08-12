from datetime import datetime
from typing import List, Optional
from sqlalchemy import select, Column, Integer, String, Text, Boolean, DateTime, ForeignKey
from sqlalchemy.orm import relationship, joinedload
from sqlalchemy.ext.asyncio import AsyncSession
from role.ports.driven.role_repository_port import RoleRepositoryPort
from role.domain.entities.role import Role, Permission
from db.base import Base


class S02RoleORM(Base):
    __tablename__ = "S02ROLE"

    nIdRole = Column("nidrole", Integer, primary_key=True)
    cName = Column("cname", String, nullable=False)
    cDescription = Column("cdescription", Text)
    bIsSystemRole = Column("bissystemrole", Boolean)
    bIsActive = Column("bisactive", Boolean)
    tCreatedAt = Column("tcreatedat", DateTime)

    permissions = relationship("S02RolePermissionORM", lazy="joined")


class S02PermissionORM(Base):
    __tablename__ = "S02PERMISSION"

    nIdPermission = Column("nidpermission", Integer, primary_key=True)
    cCode = Column("ccode", String, nullable=False)
    cName = Column("cname", String, nullable=False)
    cDescription = Column("cdescription", Text)
    cModule = Column("cmodule", String)
    bIsActive = Column("bisactive", Boolean)
    tCreatedAt = Column("tcreatedat", DateTime)


class S02RolePermissionORM(Base):
    __tablename__ = "S02ROLE_PERMISSION"

    nIdRole = Column("nidrole", Integer, ForeignKey("S02ROLE.nidrole"), primary_key=True)
    nIdPermission = Column("nidpermission", Integer, ForeignKey("S02PERMISSION.nidpermission"), primary_key=True)
    tCreatedAt = Column("tcreatedat", DateTime)

    permission = relationship("S02PermissionORM", lazy="joined")


class PostgresRoleRepository(RoleRepositoryPort):
    def __init__(self, session: AsyncSession):
        self._session = session

    async def find_by_name(self, name: str) -> Optional[Role]:
        stmt = (
            select(S02RoleORM)
            .options(joinedload(S02RoleORM.permissions))
            .where(S02RoleORM.cName == name)
        )
        result = await self._session.execute(stmt)
        orm = result.unique().scalar_one_or_none()
        return self._to_entity(orm) if orm else None

    async def find_all_with_permissions(self) -> List[Role]:
        stmt = (
            select(S02RoleORM)
            .options(joinedload(S02RoleORM.permissions))
            .order_by(S02RoleORM.cName)
        )
        result = await self._session.execute(stmt)
        orm_roles = result.unique().scalars().all()
        return [self._to_entity(orm) for orm in orm_roles]

    def _to_entity(self, orm: S02RoleORM) -> Role:
        return Role(
            n_id_role=orm.nIdRole,
            c_name=orm.cName,
            c_description=orm.cDescription,
            b_is_system_role=orm.bIsSystemRole,
            b_is_active=orm.bIsActive,
            t_created_at=orm.tCreatedAt,
            permissions=[
                Permission(
                    n_id_permission=rp.permission.nIdPermission,
                    c_code=rp.permission.cCode,
                    c_name=rp.permission.cName,
                    c_description=rp.permission.cDescription,
                    c_module=rp.permission.cModule,
                    b_is_active=rp.permission.bIsActive,
                    t_created_at=rp.permission.tCreatedAt,
                )
                for rp in orm.permissions
            ],
        )
