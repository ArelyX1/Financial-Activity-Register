from abc import ABC, abstractmethod
from typing import List
from identification_type.domain.entities.identification_type import IdentificationType


class IdentificationTypeRepositoryPort(ABC):
    @abstractmethod
    async def find_all(self) -> List[IdentificationType]: ...

    @abstractmethod
    async def save(self, data: IdentificationType) -> IdentificationType: ...
