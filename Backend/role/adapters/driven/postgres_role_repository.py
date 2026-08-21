from datetime import datetime
from typing import List, Optional
from sqlalchemy import select, Column, Integer, String, Text, Boolean, DateTime, ForeignKey, func
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
    cCategory = Column("ccategory", String)
    bIsSystemRole = Column("bissystemrole", Boolean)
    bIsActive = Column("bisactive", Boolean)
    tCreatedAt = Column("tcreatedat", DateTime, server_default=func.now())

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
    tCreatedAt = Column("tcreatedat", DateTime, server_default=func.now())

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

    async def create(self, data: Role) -> Role:
        orm = S02RoleORM(
            cName=data.c_name,
            cDescription=data.c_description,
            cCategory=data.c_category,
            bIsSystemRole=data.b_is_system_role,
            bIsActive=data.b_is_active,
        )
        self._session.add(orm)
        await self._session.flush()

        permission_ids: list[int] = []
        for permission in data.permissions:
            code = permission.c_code.strip()
            if not code:
                continue
            perm_stmt = select(S02PermissionORM).where(S02PermissionORM.cCode == code)
            perm = (await self._session.execute(perm_stmt)).scalar_one_or_none()
            if not perm:
                raise ValueError(f"Permission '{code}' not found")
            permission_ids.append(perm.nIdPermission)

        for permission_id in permission_ids:
            self._session.add(S02RolePermissionORM(nIdRole=orm.nIdRole, nIdPermission=permission_id))

        await self._session.commit()
        return await self.find_by_name(data.c_name)

    async def assign_permissions(self, role_id: int, permission_codes: List[str]) -> Role:
        role_stmt = select(S02RoleORM).where(S02RoleORM.nIdRole == role_id)
        role_orm = (await self._session.execute(role_stmt)).unique().scalar_one_or_none()
        if not role_orm:
            raise ValueError(f"Role with id '{role_id}' not found")

        seen: set[str] = set()
        permission_ids: list[int] = []
        for code in permission_codes:
            code = (code or "").strip()
            if not code or code in seen:
                continue
            seen.add(code)
            perm_stmt = select(S02PermissionORM).where(S02PermissionORM.cCode == code)
            perm = (await self._session.execute(perm_stmt)).scalar_one_or_none()
            if not perm:
                raise ValueError(f"Permission '{code}' not found")
            permission_ids.append(perm.nIdPermission)

        existing_stmt = select(S02RolePermissionORM.nIdPermission).where(
            S02RolePermissionORM.nIdRole == role_id
        )
        existing_ids = {
            row[0]
            for row in (await self._session.execute(existing_stmt)).all()
        }

        new_ids = [pid for pid in permission_ids if pid not in existing_ids]
        for permission_id in new_ids:
            self._session.add(
                S02RolePermissionORM(nIdRole=role_id, nIdPermission=permission_id)
            )

        await self._session.commit()
        return await self.find_by_id(role_id)

    async def update(self, role_id: int, data: Role) -> Role:
        stmt = select(S02RoleORM).where(S02RoleORM.nIdRole == role_id)
        orm = (await self._session.execute(stmt)).unique().scalar_one_or_none()
        if not orm:
            raise ValueError(f"Role with id '{role_id}' not found")
        orm.cName = data.c_name
        orm.cDescription = data.c_description
        orm.cCategory = data.c_category
        orm.bIsSystemRole = data.b_is_system_role
        orm.bIsActive = data.b_is_active
        await self._session.commit()
        return await self.find_by_id(role_id)

    async def find_by_id(self, role_id: int) -> Optional[Role]:
        stmt = (
            select(S02RoleORM)
            .options(joinedload(S02RoleORM.permissions))
            .where(S02RoleORM.nIdRole == role_id)
        )
        result = await self._session.execute(stmt)
        orm = result.unique().scalar_one_or_none()
        return self._to_entity(orm) if orm else None

    async def create_permission(self, data: Permission) -> Permission:
        orm = S02PermissionORM(
            cCode=data.c_code,
            cName=data.c_name,
            cDescription=data.c_description,
            cModule=data.c_module,
            bIsActive=data.b_is_active,
        )
        self._session.add(orm)
        await self._session.commit()
        await self._session.refresh(orm)
        return Permission(
            n_id_permission=orm.nIdPermission,
            c_code=orm.cCode,
            c_name=orm.cName,
            c_description=orm.cDescription,
            c_module=orm.cModule,
            b_is_active=orm.bIsActive,
            t_created_at=orm.tCreatedAt,
        )

    async def find_permission_by_code(self, code: str) -> Optional[Permission]:
        stmt = select(S02PermissionORM).where(S02PermissionORM.cCode == code)
        result = await self._session.execute(stmt)
        orm = result.scalar_one_or_none()
        if not orm:
            return None
        return Permission(
            n_id_permission=orm.nIdPermission,
            c_code=orm.cCode,
            c_name=orm.cName,
            c_description=orm.cDescription,
            c_module=orm.cModule,
            b_is_active=orm.bIsActive,
            t_created_at=orm.tCreatedAt,
        )

    async def find_all_permissions(self) -> List[Permission]:
        stmt = select(S02PermissionORM).order_by(S02PermissionORM.cModule, S02PermissionORM.cCode)
        result = await self._session.execute(stmt)
        orm_perms = result.scalars().all()
        return [
            Permission(
                n_id_permission=orm.nIdPermission,
                c_code=orm.cCode,
                c_name=orm.cName,
                c_description=orm.cDescription,
                c_module=orm.cModule,
                b_is_active=orm.bIsActive,
                t_created_at=orm.tCreatedAt,
            )
            for orm in orm_perms
        ]

    def _to_entity(self, orm: S02RoleORM) -> Role:
        return Role(
            n_id_role=orm.nIdRole,
            c_name=orm.cName,
            c_description=orm.cDescription,
            c_category=orm.cCategory,
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
