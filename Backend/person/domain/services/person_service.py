from typing import List, Optional
from person.ports.driving.person_input_port import PersonInputPort
from person.ports.driven.person_repository_port import PersonRepositoryPort
from person.domain.entities.person import Person


class PersonService(PersonInputPort):
    def __init__(self, repo: PersonRepositoryPort):
        self._repo = repo

    async def get_all(self) -> List[Person]:
        return await self._repo.find_all()

    async def find_by_id(self, n_id_person: str) -> Optional[Person]:
        return await self._repo.find_by_id(n_id_person)

    async def find_by_identification_number(self, identification_number: str) -> Optional[Person]:
        return await self._repo.find_by_identification_number(identification_number)

    async def create(self, data: Person) -> Person:
        return await self._repo.save(data)

    async def update_by_identification_number(self, identification_number: str, data: Person) -> Person:
        existing = await self._repo.find_by_identification_number(identification_number)
        if not existing:
            raise ValueError(f"Person with identification number '{identification_number}' not found")
        return await self._repo.update(data)

    async def update_by_id(self, n_id_person: str, data: Person) -> Person:
        existing = await self._repo.find_by_id(n_id_person)
        if not existing:
            raise ValueError(f"Person with id '{n_id_person}' not found")
        data.n_id_person = n_id_person
        return await self._repo.update_by_id(data)

    async def assign_role(self, n_id_person: str, n_id_role: int) -> None:
        await self._repo.save_person_role(n_id_person, n_id_role)

    async def remove_role(self, n_id_person: str, n_id_role: int) -> None:
        await self._repo.delete_person_role(n_id_person, n_id_role)

    async def conform_role_assign(self, n_id_person: str, role_name: str) -> None:
        await self._repo.activate_user(n_id_person)
        r = role_name.lower()
        if r in ("admin", "observer", "papu"):
            await self._repo.activate_employee(n_id_person)
        elif r == "participant":
            await self._repo.activate_participant(n_id_person)
        elif r == "superior":
            await self._repo.activate_superior(n_id_person)

    async def conform_role_remove(self, n_id_person: str, role_name: str) -> None:
        r = role_name.lower()
        if r in ("admin", "observer", "papu"):
            await self._repo.deactivate_employee(n_id_person)
        elif r == "participant":
            await self._repo.deactivate_participant(n_id_person)
        elif r == "superior":
            await self._repo.deactivate_superior(n_id_person)

    async def get_person_roles(self, n_id_person: str) -> List[str]:
        return await self._repo.find_role_names_by_person_id(n_id_person)

    async def get_person_permissions(self, n_id_person: str) -> List[dict]:
        return await self._repo.find_permissions_by_person_id(n_id_person)

    async def find_persons_by_roles(self, role_names: List[str]) -> List[dict]:
        return await self._repo.find_by_role_names(role_names)

    async def find_employee_programs(self, n_id_employee: str) -> List[dict]:
        return await self._repo.find_employee_programs(n_id_employee)

    async def assign_employee_program(self, n_id_employee: str, n_id_program: str) -> None:
        await self._repo.save_employee_program(n_id_employee, n_id_program)

    async def find_program_workshops(self, n_id_program: str) -> List[dict]:
        return await self._repo.find_program_workshops(n_id_program)

    async def activate_user(self, n_id_person: str) -> None:
        await self._repo.activate_user(n_id_person)

    async def deactivate_user(self, n_id_person: str) -> None:
        await self._repo.deactivate_user(n_id_person)

    async def find_participants_by_program(self, program_id: str) -> List[dict]:
        return await self._repo.find_participants_by_program(program_id)

    async def deactivate_participant_program(self, n_id_participant: str, n_id_program: str) -> None:
        await self._repo.deactivate_participant_program(n_id_participant, n_id_program)

    async def activate_participant_program(self, n_id_participant: str, n_id_program: str) -> None:
        await self._repo.activate_participant_program(n_id_participant, n_id_program)

    async def create_workshop(self, n_id_program: str, c_description: str, c_status: str | None, t_date: str | None) -> dict:
        return await self._repo.save_workshop(n_id_program, c_description, c_status, t_date)

    async def update_workshop_status(self, n_id_workshop: str, c_status: str) -> dict | None:
        return await self._repo.update_workshop_status(n_id_workshop, c_status)
