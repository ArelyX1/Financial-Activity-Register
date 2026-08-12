from abc import ABC, abstractmethod
from typing import List
from boundaries.domain.entities.boundarie import Boundarie


class BoundarieRepositoryPort(ABC):
    @abstractmethod
    async def get_geo1(self) -> List[Boundarie]: ...

    @abstractmethod
    async def get_geo2_by_geo1(self, geo1_id: int) -> List[Boundarie]: ...

    @abstractmethod
    async def get_geo3_by_geo2(self, geo2_id: int) -> List[Boundarie]: ...

    @abstractmethod
    async def get_geo4_by_geo3(self, geo3_id: int) -> List[Boundarie]: ...
