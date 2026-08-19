from abc import ABC, abstractmethod
from typing import List, Optional
from role.domain.entities.role import Role, Permission


class RoleInputPort(ABC):
    @abstractmethod
    async def get_all_with_permissions(self) -> List[Role]: ...

    @abstractmethod
    async def find_by_name(self, name: str) -> Optional[Role]: ...

    @abstractmethod
    async def create(self, data: Role) -> Role: ...

    @abstractmethod
    async def create_permission(self, data: Permission) -> Permission: ...
