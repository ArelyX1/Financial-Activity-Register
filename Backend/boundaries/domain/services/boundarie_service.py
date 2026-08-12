from typing import List
from boundaries.ports.driving.boundarie_input_port import BoundarieInputPort
from boundaries.ports.driven.boundarie_repository_port import BoundarieRepositoryPort
from boundaries.domain.entities.boundarie import Boundarie


class BoundarieService(BoundarieInputPort):
    def __init__(self, boundarie_repo: BoundarieRepositoryPort):
        self._boundarie_repo = boundarie_repo

    async def get_geo1(self) -> List[Boundarie]:
        return await self._boundarie_repo.get_geo1()

    async def get_geo2(self, geo1_id: int) -> List[Boundarie]:
        return await self._boundarie_repo.get_geo2_by_geo1(geo1_id)

    async def get_geo3(self, geo2_id: int) -> List[Boundarie]:
        return await self._boundarie_repo.get_geo3_by_geo2(geo2_id)

    async def get_geo4(self, geo3_id: int) -> List[Boundarie]:
        return await self._boundarie_repo.get_geo4_by_geo3(geo3_id)
