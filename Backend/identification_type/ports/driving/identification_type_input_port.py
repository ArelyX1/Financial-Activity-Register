from abc import ABC, abstractmethod
from typing import List
from identification_type.domain.entities.identification_type import IdentificationType


class IdentificationTypeInputPort(ABC):
    @abstractmethod
    async def get_all(self) -> List[IdentificationType]: ...

    @abstractmethod
    async def create(self, data: IdentificationType) -> IdentificationType: ...
