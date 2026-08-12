from abc import ABC, abstractmethod
from typing import List, Optional
from person.domain.entities.person import Person


class PersonInputPort(ABC):
    @abstractmethod
    async def get_all(self) -> List[Person]: ...

    @abstractmethod
    async def find_by_identification_number(self, identification_number: str) -> Optional[Person]: ...

    @abstractmethod
    async def create(self, data: Person) -> Person: ...

    @abstractmethod
    async def update_by_identification_number(self, identification_number: str, data: Person) -> Person: ...

    @abstractmethod
    async def update_by_id(self, n_id_person: str, data: Person) -> Person: ...

    @abstractmethod
    async def assign_role(self, n_id_person: str, n_id_role: int) -> None: ...

    @abstractmethod
    async def get_person_roles(self, n_id_person: str) -> List[str]: ...

    @abstractmethod
    async def get_person_permissions(self, n_id_person: str) -> List[dict]: ...

    @abstractmethod
    async def find_persons_by_roles(self, role_names: List[str]) -> List[dict]: ...
