from abc import ABC, abstractmethod
from typing import List, Optional
from role.domain.entities.role import Role, Permission


class RoleRepositoryPort(ABC):
    @abstractmethod
    async def find_all_with_permissions(self) -> List[Role]: ...

    @abstractmethod
    async def find_by_name(self, name: str) -> Optional[Role]: ...

    @abstractmethod
    async def create(self, data: Role) -> Role: ...

    @abstractmethod
    async def assign_permissions(self, role_id: int, permission_codes: List[str]) -> Role: ...

    @abstractmethod
    async def find_by_id(self, role_id: int) -> Optional[Role]: ...

    @abstractmethod
    async def create_permission(self, data: Permission) -> Permission: ...

    @abstractmethod
    async def find_permission_by_code(self, code: str) -> Optional[Permission]: ...

    @abstractmethod
    async def find_all_permissions(self) -> List[Permission]: ...
