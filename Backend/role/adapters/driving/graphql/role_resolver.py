import strawberry
from typing import List
from strawberry.types import Info
from role.domain.services.role_service import RoleService
from role.adapters.driven.postgres_role_repository import PostgresRoleRepository
from role.domain.entities.role import Role as RoleEntity, Permission as PermissionEntity
from db.config import AsyncSessionLocal
from auth.adapters.driving.graphql.helpers import enforce_access

@strawberry.type
class Permission:
    id: int
    code: str
    name: str
    description: str | None = None
    module: str | None = None
    is_active: bool | None = None
    created_at: str | None = None


@strawberry.type
class Role:
    id: int
    name: str
    description: str | None = None
    category: str | None = None
    is_system_role: bool | None = None
    is_active: bool | None = None
    created_at: str | None = None
    permissions: List[Permission]


@strawberry.input
class CreateRoleInput:
    name: str
    category: str
    description: str | None = None
    is_system_role: bool = False
    is_active: bool = True
    permission_codes: List[str] = strawberry.field(default_factory=list)


@strawberry.input
class UpdateRoleInput:
    name: str
    category: str
    description: str | None = None
    is_system_role: bool = False
    is_active: bool = True


@strawberry.input
class AssignRolePermissionsInput:
    role_id: int
    permission_codes: List[str] = strawberry.field(default_factory=list)


@strawberry.input
class CreatePermissionInput:
    code: str
    name: str
    description: str | None = None
    module: str | None = None
    is_active: bool = True


@strawberry.type
class Mutation:
    @strawberry.mutation
    async def create_role(self, info: Info, token: str, input: CreateRoleInput) -> Role:
        await enforce_access(token, "create_role")
        async with AsyncSessionLocal() as session:
            repo = PostgresRoleRepository(session)
            service = RoleService(repo)
            entity = RoleEntity(
                c_name=input.name,
                c_description=input.description,
                c_category=input.category,
                b_is_system_role=input.is_system_role,
                b_is_active=input.is_active,
                permissions=[PermissionEntity(c_code=code) for code in input.permission_codes],
            )
            created = await service.create(entity)
            return Role(
                id=created.n_id_role,
                name=created.c_name,
                description=created.c_description,
                category=created.c_category,
                is_system_role=created.b_is_system_role,
                is_active=created.b_is_active,
                created_at=str(created.t_created_at) if created.t_created_at else None,
                permissions=[
                    Permission(
                        id=p.n_id_permission,
                        code=p.c_code,
                        name=p.c_name,
                        description=p.c_description,
                        module=p.c_module,
                        is_active=p.b_is_active,
                        created_at=str(p.t_created_at) if p.t_created_at else None,
                    )
                    for p in created.permissions
                ],
            )

    @strawberry.mutation
    async def update_role(self, info: Info, token: str, role_id: int, input: UpdateRoleInput) -> Role:
        await enforce_access(token, "update_role")
        async with AsyncSessionLocal() as session:
            repo = PostgresRoleRepository(session)
            service = RoleService(repo)
            entity = RoleEntity(
                c_name=input.name,
                c_description=input.description,
                c_category=input.category,
                b_is_system_role=input.is_system_role,
                b_is_active=input.is_active,
            )
            updated = await service.update(role_id, entity)
            return Role(
                id=updated.n_id_role,
                name=updated.c_name,
                description=updated.c_description,
                category=updated.c_category,
                is_system_role=updated.b_is_system_role,
                is_active=updated.b_is_active,
                created_at=str(updated.t_created_at) if updated.t_created_at else None,
                permissions=[
                    Permission(
                        id=p.n_id_permission,
                        code=p.c_code,
                        name=p.c_name,
                        description=p.c_description,
                        module=p.c_module,
                        is_active=p.b_is_active,
                        created_at=str(p.t_created_at) if p.t_created_at else None,
                    )
                    for p in updated.permissions
                ],
            )

    @strawberry.mutation
    async def assign_role_permissions(self, info: Info, token: str, input: AssignRolePermissionsInput) -> Role:
        await enforce_access(token, "assign_role_permissions")
        async with AsyncSessionLocal() as session:
            repo = PostgresRoleRepository(session)
            service = RoleService(repo)
            updated = await service.assign_permissions(input.role_id, input.permission_codes)
            return Role(
                id=updated.n_id_role,
                name=updated.c_name,
                description=updated.c_description,
                category=updated.c_category,
                is_system_role=updated.b_is_system_role,
                is_active=updated.b_is_active,
                created_at=str(updated.t_created_at) if updated.t_created_at else None,
                permissions=[
                    Permission(
                        id=p.n_id_permission,
                        code=p.c_code,
                        name=p.c_name,
                        description=p.c_description,
                        module=p.c_module,
                        is_active=p.b_is_active,
                        created_at=str(p.t_created_at) if p.t_created_at else None,
                    )
                    for p in updated.permissions
                ],
            )

    @strawberry.mutation
    async def create_permission(self, info: Info, token: str, input: CreatePermissionInput) -> Permission:
        await enforce_access(token, "create_permission")
        async with AsyncSessionLocal() as session:
            repo = PostgresRoleRepository(session)
            service = RoleService(repo)
            entity = PermissionEntity(
                c_code=input.code,
                c_name=input.name,
                c_description=input.description,
                c_module=input.module,
                b_is_active=input.is_active,
            )
            created = await service.create_permission(entity)
            return Permission(
                id=created.n_id_permission,
                code=created.c_code,
                name=created.c_name,
                description=created.c_description,
                module=created.c_module,
                is_active=created.b_is_active,
                created_at=str(created.t_created_at) if created.t_created_at else None,
            )


@strawberry.type
class Query:
    @strawberry.field
    async def roles(self) -> List[Role]:
        async with AsyncSessionLocal() as session:
            repo = PostgresRoleRepository(session)
            service = RoleService(repo)
            items = await service.get_all_with_permissions()
            return [
                Role(
                    id=r.n_id_role,
                    name=r.c_name,
                    description=r.c_description,
                    category=r.c_category,
                    is_system_role=r.b_is_system_role,
                    is_active=r.b_is_active,
                    created_at=str(r.t_created_at) if r.t_created_at else None,
                    permissions=[
                        Permission(
                            id=p.n_id_permission,
                            code=p.c_code,
                            name=p.c_name,
                            description=p.c_description,
                            module=p.c_module,
                            is_active=p.b_is_active,
                            created_at=str(p.t_created_at) if p.t_created_at else None,
                        )
                        for p in r.permissions
                    ],
                )
                for r in items
            ]

    @strawberry.field
    async def query_permissions(self) -> List[Permission]:
        async with AsyncSessionLocal() as session:
            repo = PostgresRoleRepository(session)
            service = RoleService(repo)
            items = await service.get_all_permissions()
            return [
                Permission(
                    id=p.n_id_permission,
                    code=p.c_code,
                    name=p.c_name,
                    description=p.c_description,
                    module=p.c_module,
                    is_active=p.b_is_active,
                    created_at=str(p.t_created_at) if p.t_created_at else None,
                )
                for p in items
            ]
