from abc import ABC, abstractmethod
from typing import List, Optional
from role.domain.entities.role import Role


class RoleInputPort(ABC):
    @abstractmethod
    async def get_all_with_permissions(self) -> List[Role]: ...

    @abstractmethod
    async def find_by_name(self, name: str) -> Optional[Role]: ...
