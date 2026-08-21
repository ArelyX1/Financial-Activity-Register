from typing import List, Optional
from role.ports.driving.role_input_port import RoleInputPort
from role.ports.driven.role_repository_port import RoleRepositoryPort
from role.domain.entities.role import Role, Permission


class RoleService(RoleInputPort):
    def __init__(self, repo: RoleRepositoryPort):
        self._repo = repo

    async def get_all_with_permissions(self) -> List[Role]:
        return await self._repo.find_all_with_permissions()

    async def find_by_name(self, name: str) -> Optional[Role]:
        return await self._repo.find_by_name(name)

    async def assign_permissions(self, role_id: int, permission_codes: List[str]) -> Role:
        existing = await self._repo.find_by_id(role_id)
        if not existing:
            raise ValueError(f"Role with id '{role_id}' not found")
        if not permission_codes:
            raise ValueError("At least one permission is required")
        return await self._repo.assign_permissions(role_id, permission_codes)

    async def create(self, data: Role) -> Role:
        name = data.c_name.strip()
        if not name:
            raise ValueError("Role name is required")
        if len(name) > 50:
            raise ValueError("Role name must be 50 characters or less")
        category = (data.c_category or "").strip()
        if not category:
            raise ValueError("Role category is required")
        existing = await self._repo.find_by_name(name)
        if existing:
            raise ValueError(f"Role '{name}' already exists")
        data.c_name = name
        data.c_category = category
        return await self._repo.create(data)

    async def update(self, role_id: int, data: Role) -> Role:
        existing = await self._repo.find_by_id(role_id)
        if not existing:
            raise ValueError(f"Role with id '{role_id}' not found")
        name = (data.c_name or "").strip()
        if not name:
            raise ValueError("Role name is required")
        if len(name) > 50:
            raise ValueError("Role name must be 50 characters or less")
        category = (data.c_category or "").strip()
        if category not in ("Employee", "Client"):
            raise ValueError("Role category must be 'Employee' or 'Client'")
        duplicate = await self._repo.find_by_name(name)
        if duplicate and duplicate.n_id_role != role_id:
            raise ValueError(f"Role '{name}' already exists")
        data.c_name = name
        data.c_category = category
        return await self._repo.update(role_id, data)

    async def create_permission(self, data: Permission) -> Permission:
        code = (data.c_code or "").strip()
        if not code:
            raise ValueError("Permission code is required")
        if len(code) > 50:
            raise ValueError("Permission code must be 50 characters or less")
        name = (data.c_name or "").strip()
        if not name:
            raise ValueError("Permission name is required")
        if len(name) > 100:
            raise ValueError("Permission name must be 100 characters or less")
        existing = await self._repo.find_permission_by_code(code)
        if existing:
            raise ValueError(f"Permission with code '{code}' already exists")
        data.c_code = code
        data.c_name = name
        return await self._repo.create_permission(data)

    async def get_all_permissions(self) -> List[Permission]:
        return await self._repo.find_all_permissions()
