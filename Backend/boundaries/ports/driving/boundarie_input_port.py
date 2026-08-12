from abc import ABC, abstractmethod
from typing import List
from boundaries.domain.entities.boundarie import Boundarie


class BoundarieInputPort(ABC):
    @abstractmethod
    async def get_geo1(self) -> List[Boundarie]: ...

    @abstractmethod
    async def get_geo2(self, geo1_id: int) -> List[Boundarie]: ...

    @abstractmethod
    async def get_geo3(self, geo2_id: int) -> List[Boundarie]: ...

    @abstractmethod
    async def get_geo4(self, geo3_id: int) -> List[Boundarie]: ...
