from typing import List, Optional
from role.ports.driving.role_input_port import RoleInputPort
from role.ports.driven.role_repository_port import RoleRepositoryPort
from role.domain.entities.role import Role


class RoleService(RoleInputPort):
    def __init__(self, repo: RoleRepositoryPort):
        self._repo = repo

    async def get_all_with_permissions(self) -> List[Role]:
        return await self._repo.find_all_with_permissions()

    async def find_by_name(self, name: str) -> Optional[Role]:
        return await self._repo.find_by_name(name)
