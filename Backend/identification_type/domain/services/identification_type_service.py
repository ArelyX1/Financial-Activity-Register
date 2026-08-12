from typing import List
from identification_type.ports.driving.identification_type_input_port import IdentificationTypeInputPort
from identification_type.ports.driven.identification_type_repository_port import IdentificationTypeRepositoryPort
from identification_type.domain.entities.identification_type import IdentificationType


class IdentificationTypeService(IdentificationTypeInputPort):
    def __init__(self, repo: IdentificationTypeRepositoryPort):
        self._repo = repo

    async def get_all(self) -> List[IdentificationType]:
        return await self._repo.find_all()

    async def create(self, data: IdentificationType) -> IdentificationType:
        return await self._repo.save(data)
