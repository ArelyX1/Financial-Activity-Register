import strawberry
from typing import List
from role.domain.services.role_service import RoleService
from role.adapters.driven.postgres_role_repository import PostgresRoleRepository
from db.config import AsyncSessionLocal

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
    is_system_role: bool | None = None
    is_active: bool | None = None
    created_at: str | None = None
    permissions: List[Permission]


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
