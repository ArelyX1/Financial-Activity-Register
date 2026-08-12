from abc import ABC, abstractmethod
from typing import List, Optional
from role.domain.entities.role import Role


class RoleRepositoryPort(ABC):
    @abstractmethod
    async def find_all_with_permissions(self) -> List[Role]: ...

    @abstractmethod
    async def find_by_name(self, name: str) -> Optional[Role]: ...
