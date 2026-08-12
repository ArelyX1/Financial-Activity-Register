import strawberry
from typing import List
from sqlalchemy.exc import DBAPIError
from person.domain.services.person_service import PersonService
from person.adapters.driven.postgres_person_repository import PostgresPersonRepository
from person.domain.entities.person import Person as PersonEntity
from role.domain.services.role_service import RoleService
from role.adapters.driven.postgres_role_repository import PostgresRoleRepository
from user_account.adapters.driven.postgres_user_account_repository import PostgresUserAccountRepository
from db.config import AsyncSessionLocal
from auth.adapters.driving.graphql.helpers import resolve_user_from_token, enforce_access


@strawberry.type
class Person:
    id: str
    name: str
    last_name: str
    id_identification_type: int
    identification_number: str
    birth_place_gadm: int | None = None
    residence_place_gadm: int | None = None
    created_at: str | None = None
    modified_at: str | None = None
    role: str
    photo_url: str | None = None
    username: str | None = None
    email: str | None = None


@strawberry.type
class WorkshopType:
    n_id_workshop: str
    c_description: str | None = None
    c_status: str | None = None
    t_date: str | None = None


@strawberry.type
class ProgramType:
    n_id_program: str
    c_name: str
    c_description: str | None = None
    c_status: str | None = None
    t_start_date: str | None = None
    t_end_time: str | None = None
    workshops: List[WorkshopType] | None = None
    b_is_active: bool = True


@strawberry.type
class PersonWithUser:
    id: str
    name: str
    last_name: str
    identification_number: str
    id_identification_type: int = 0
    email: str | None = None
    username: str | None = None
    is_active: bool | None = None
    photo_url: str | None = None
    latest_access: str | None = None
    wallet: str | None = None
    phrase: str | None = None
    provider_id: str | None = None
    email_verified: bool | None = None
    is_registered: bool = False
    employee_active: bool | None = None
    participant_active: bool | None = None
    superior_active: bool | None = None
    created_at: str | None = None
    modified_at: str | None = None
    residence_place_gadm: int | None = None
    birth_place_gadm: int | None = None
    roles: List[str]


@strawberry.type
class EmployeeProgramType:
    n_id_program: str
    c_name: str
    c_description: str | None = None
    c_status: str | None = None
    t_start_date: str | None = None
    t_end_time: str | None = None
    is_assigned: bool = False


@strawberry.type
class AvailableProgramType:
    n_id_program: str
    c_name: str
    c_description: str | None = None
    c_status: str | None = None
    t_start_date: str | None = None
    t_end_time: str | None = None


@strawberry.type
class ProgramParticipantType:
    n_id_participant: str
    n_id_person: str
    c_name: str
    c_last_name: str
    c_identification_number: str
    c_email: str | None = None
    c_username: str | None = None
    c_photo_url: str | None = None
    b_is_active: bool


@strawberry.input
class CreatePersonInput:
    id_identification_type: int
    identification_number: str
    role_names: List[str]


@strawberry.input
class RegisterInput:
    identification_number: str
    name: str
    lastName: str
    birth_place_gadm: int
    residence_place_gadm: int


@strawberry.input
class UpdatePersonInput:
    identification_number: str
    name: str
    last_name: str
    birth_place_gadm: int
    residence_place_gadm: int


@strawberry.input
class AssignPersonRoleInput:
    identification_number: str
    role_name: str


@strawberry.input
class AssignParticipantProgramInput:
    identification_number: str
    program_id: str
    token: str


@strawberry.input
class CreateWorkshopInput:
    n_id_program: str
    c_description: str
    c_status: str | None = None
    t_date: str | None = None


@strawberry.input
class UpdateWorkshopStatusInput:
    n_id_workshop: str
    c_status: str


@strawberry.type
class Query:
    @strawberry.field
    async def persons(self) -> List[Person]:
        async with AsyncSessionLocal() as session:
            repo = PostgresPersonRepository(session)
            service = PersonService(repo)
            items = await service.get_all()
            return [
                Person(
                    id=p.n_id_person,
                    name=p.c_name,
                    last_name=p.c_last_name,
                    id_identification_type=p.n_id_identification_type,
                    identification_number=p.c_identification_number,
                    birth_place_gadm=p.n_birth_place_gadm,
                    residence_place_gadm=p.n_residence_place_gadm,
                    created_at=str(p.t_created_at) if p.t_created_at else None,
                    modified_at=str(p.t_modified_at) if p.t_modified_at else None,
                    role=p.role_name,
                )
                for p in items
            ]

    @strawberry.field
    async def person(self, identification_number: str) -> Person | None:
        async with AsyncSessionLocal() as session:
            repo = PostgresPersonRepository(session)
            service = PersonService(repo)
            p = await service.find_by_identification_number(identification_number)
            if not p:
                return None
            return Person(
                id=p.n_id_person,
                name=p.c_name,
                last_name=p.c_last_name,
                id_identification_type=p.n_id_identification_type,
                identification_number=p.c_identification_number,
                birth_place_gadm=p.n_birth_place_gadm,
                residence_place_gadm=p.n_residence_place_gadm,
                created_at=str(p.t_created_at) if p.t_created_at else None,
                modified_at=str(p.t_modified_at) if p.t_modified_at else None,
                role=p.role_name or "",
                photo_url=p.c_photo_url,
                username=p.c_username,
                email=p.c_email,
            )

    @strawberry.field
    async def participant_programs(self, identification_number: str, token: str) -> List[ProgramType]:
        await resolve_user_from_token(token)
        async with AsyncSessionLocal() as session:
            repo = PostgresPersonRepository(session)
            service = PersonService(repo)
            person = await service.find_by_identification_number(identification_number)
            if not person:
                raise ValueError(f"Person with identification number '{identification_number}' not found")
            data = await repo.find_programs_by_participant_id(str(person.n_id_person))
            return [
                ProgramType(
                    n_id_program=p["n_id_program"],
                    c_name=p["c_name"],
                    c_description=p["c_description"],
                    c_status=p["c_status"],
                    t_start_date=p["t_start_date"],
                    t_end_time=p["t_end_time"],
                    workshops=[WorkshopType(**w) for w in p["workshops"]] if p["workshops"] else [],
                    b_is_active=p["b_is_active"],
                )
                for p in data
            ]

    @strawberry.field
    async def persons_by_role(self, role_names: List[str], token: str) -> List[PersonWithUser]:
        await enforce_access(token, "persons_by_role")
        async with AsyncSessionLocal() as session:
            repo = PostgresPersonRepository(session)
            service = PersonService(repo)
            items = await service.find_persons_by_roles(role_names)
            return [
                PersonWithUser(
                    id=row["id"],
                    name=row["name"],
                    last_name=row["last_name"],
                    identification_number=row["identification_number"],
                    id_identification_type=row["id_identification_type"],
                    email=row["email"],
                    username=row["username"],
                    is_active=row["is_active"],
                    photo_url=row["photo_url"],
                    latest_access=row["latest_access"],
                    wallet=row["wallet"],
                    phrase=row["phrase"],
                    provider_id=row["provider_id"],
                    email_verified=row["email_verified"],
                    is_registered=row["is_registered"],
                    employee_active=row["employee_active"],
                    participant_active=row["participant_active"],
                    superior_active=row["superior_active"],
                    created_at=row["user_created_at"],
                    modified_at=row["modified_at"],
                    residence_place_gadm=row["residence_place_gadm"],
                    birth_place_gadm=row["birth_place_gadm"],
                    roles=row["roles"],
                )
                for row in items
            ]

    @strawberry.field
    async def available_programs(self, identification_number: str, token: str) -> List[AvailableProgramType]:
        await resolve_user_from_token(token)
        async with AsyncSessionLocal() as session:
            repo = PostgresPersonRepository(session)
            service = PersonService(repo)
            person = await service.find_by_identification_number(identification_number)
            if not person:
                raise ValueError(f"Person with identification number '{identification_number}' not found")
            data = await repo.find_available_programs(str(person.n_id_person))
            return [AvailableProgramType(**p) for p in data]

    @strawberry.field
    async def employee_programs(self, token: str) -> List[EmployeeProgramType]:
        user_data = await resolve_user_from_token(token)
        async with AsyncSessionLocal() as session:
            repo = PostgresPersonRepository(session)
            service = PersonService(repo)
            data = await service.find_employee_programs(user_data["user_id"])
            return [EmployeeProgramType(**p) for p in data]

    @strawberry.field
    async def program_workshops(self, program_id: str, token: str) -> List[WorkshopType]:
        await resolve_user_from_token(token)
        async with AsyncSessionLocal() as session:
            repo = PostgresPersonRepository(session)
            service = PersonService(repo)
            data = await service.find_program_workshops(program_id)
            return [
                WorkshopType(
                    n_id_workshop=w["n_id_workshop"],
                    c_description=w["c_description"],
                    c_status=w["c_status"],
                    t_date=w["t_date"],
                )
                for w in data
            ]

    @strawberry.field
    async def participants_by_program(self, program_id: str, token: str) -> List[ProgramParticipantType]:
        await enforce_access(token, "participants_by_program")
        async with AsyncSessionLocal() as session:
            repo = PostgresPersonRepository(session)
            service = PersonService(repo)
            data = await service.find_participants_by_program(program_id)
            return [ProgramParticipantType(**p) for p in data]

@strawberry.type
class Mutation:
    @strawberry.mutation
    async def create_person(self, input: CreatePersonInput) -> Person:
        try:
            async with AsyncSessionLocal() as session:
                role_repo = PostgresRoleRepository(session)
                role_service = RoleService(role_repo)

                if not input.role_names:
                    raise ValueError("At least one role is required")

                roles = []
                for rn in input.role_names:
                    role = await role_service.find_by_name(rn)
                    if not role:
                        raise ValueError(f"Role '{rn}' not found")
                    roles.append(role)

                repo = PostgresPersonRepository(session)
                service = PersonService(repo)
                entity = PersonEntity(
                    c_name="",
                    c_last_name="",
                    n_id_identification_type=input.id_identification_type,
                    c_identification_number=input.identification_number,
                )
                created = await service.create(entity)
                for role in roles:
                    await service.assign_role(str(created.n_id_person), role.n_id_role)
                return Person(
                    id=created.n_id_person,
                    name=created.c_name,
                    last_name=created.c_last_name,
                    id_identification_type=created.n_id_identification_type,
                    identification_number=created.c_identification_number,
                    birth_place_gadm=created.n_birth_place_gadm,
                    residence_place_gadm=created.n_residence_place_gadm,
                    created_at=str(created.t_created_at) if created.t_created_at else None,
                    modified_at=str(created.t_modified_at) if created.t_modified_at else None,
                    role=created.role_name or "",
                )
        except DBAPIError as e:
            if e.orig:
                raise ValueError(str(e.orig))
            raise ValueError(str(e))

    @strawberry.mutation
    async def register(self, input: RegisterInput) -> Person:
        async with AsyncSessionLocal() as session:
            repo = PostgresPersonRepository(session)
            service = PersonService(repo)
            existing = await service.find_by_identification_number(input.identification_number)
            if not existing:
                raise ValueError(f"Person with identification number '{input.identification_number}' not found")

            role_name = existing.role_name.lower()
            entity = PersonEntity(
                c_name=input.name.strip(),
                c_last_name=input.lastName.strip(),
                c_identification_number=input.identification_number,
                n_birth_place_gadm=input.birth_place_gadm,
                n_residence_place_gadm=input.residence_place_gadm,
            )
            updated = await service.update_by_identification_number(
                identification_number=input.identification_number,
                data=entity,
            )

            return Person(
                id=updated.n_id_person,
                name=updated.c_name,
                last_name=updated.c_last_name,
                id_identification_type=updated.n_id_identification_type,
                identification_number=updated.c_identification_number,
                birth_place_gadm=updated.n_birth_place_gadm,
                residence_place_gadm=updated.n_residence_place_gadm,
                created_at=str(updated.t_created_at) if updated.t_created_at else None,
                modified_at=str(updated.t_modified_at) if updated.t_modified_at else None,
                role=role_name,
            )

    @strawberry.mutation
    async def update_person(self, input: UpdatePersonInput) -> Person:
        async with AsyncSessionLocal() as session:
            repo = PostgresPersonRepository(session)
            service = PersonService(repo)
            existing = await service.find_by_identification_number(input.identification_number)
            if not existing:
                raise ValueError(f"Person with identification number '{input.identification_number}' not found")

            role_name = existing.role_name.lower()
            entity = PersonEntity(
                c_name=input.name.strip(),
                c_last_name=input.last_name.strip(),
                c_identification_number=input.identification_number,
                n_birth_place_gadm=input.birth_place_gadm,
                n_residence_place_gadm=input.residence_place_gadm,
            )
            updated = await service.update_by_identification_number(
                identification_number=input.identification_number,
                data=entity,
            )

            return Person(
                id=updated.n_id_person,
                name=updated.c_name,
                last_name=updated.c_last_name,
                id_identification_type=updated.n_id_identification_type,
                identification_number=updated.c_identification_number,
                birth_place_gadm=updated.n_birth_place_gadm,
                residence_place_gadm=updated.n_residence_place_gadm,
                created_at=str(updated.t_created_at) if updated.t_created_at else None,
                modified_at=str(updated.t_modified_at) if updated.t_modified_at else None,
                role=role_name,
            )

    @strawberry.mutation
    async def assign_person_role(self, input: AssignPersonRoleInput) -> Person:
        async with AsyncSessionLocal() as session:
            role_repo = PostgresRoleRepository(session)
            role_service = RoleService(role_repo)
            role = await role_service.find_by_name(input.role_name)
            if not role:
                raise ValueError(f"Role '{input.role_name}' not found")

            repo = PostgresPersonRepository(session)
            service = PersonService(repo)
            person = await service.find_by_identification_number(input.identification_number)
            if not person:
                raise ValueError(f"Person with identification number '{input.identification_number}' not found")

            await service.assign_role(str(person.n_id_person), role.n_id_role)
            user_repo = PostgresUserAccountRepository(session)
            existing_user = await user_repo.find_by_id(person.n_id_person)
            if existing_user:
                await service.conform_role_assign(str(person.n_id_person), input.role_name)

            return Person(
                id=person.n_id_person,
                name=person.c_name,
                last_name=person.c_last_name,
                id_identification_type=person.n_id_identification_type,
                identification_number=person.c_identification_number,
                birth_place_gadm=person.n_birth_place_gadm,
                residence_place_gadm=person.n_residence_place_gadm,
                created_at=str(person.t_created_at) if person.t_created_at else None,
                modified_at=str(person.t_modified_at) if person.t_modified_at else None,
                role=role.c_name,
            )

    @strawberry.mutation
    async def remove_person_role(self, person_id: str, role_name: str) -> bool:
        async with AsyncSessionLocal() as session:
            role_repo = PostgresRoleRepository(session)
            role_service = RoleService(role_repo)
            role = await role_service.find_by_name(role_name)
            if not role:
                raise ValueError(f"Role '{role_name}' not found")
            repo = PostgresPersonRepository(session)
            service = PersonService(repo)

            current_roles = await service.get_person_roles(person_id)
            if len(current_roles) <= 1:
                raise ValueError("No se puede eliminar el último rol. Cada persona debe tener al menos un rol.")

            await service.remove_role(person_id, role.n_id_role)
            await service.conform_role_remove(person_id, role_name)
            return True

    @strawberry.mutation
    async def assign_employee_program(self, program_id: str, token: str) -> str:
        user_data = await resolve_user_from_token(token)
        async with AsyncSessionLocal() as session:
            repo = PostgresPersonRepository(session)
            service = PersonService(repo)
            await service.assign_employee_program(user_data["user_id"], program_id)
            return "OK"

    @strawberry.mutation
    async def assign_participant_program(self, input: AssignParticipantProgramInput) -> str:
        await resolve_user_from_token(input.token)
        async with AsyncSessionLocal() as session:
            repo = PostgresPersonRepository(session)
            service = PersonService(repo)
            person = await service.find_by_identification_number(input.identification_number)
            if not person:
                raise ValueError(f"Person with identification number '{input.identification_number}' not found")
            await repo.save_participant_program(str(person.n_id_person), input.program_id)
            return "OK"

    @strawberry.mutation
    async def deactivate_participant_program(self, participant_id: str, program_id: str, token: str) -> str:
        await enforce_access(token, "deactivate_participant_program")
        async with AsyncSessionLocal() as session:
            repo = PostgresPersonRepository(session)
            service = PersonService(repo)
            await service.deactivate_participant_program(participant_id, program_id)
            return "OK"

    @strawberry.mutation
    async def activate_participant_program(self, participant_id: str, program_id: str, token: str) -> str:
        await enforce_access(token, "activate_participant_program")
        async with AsyncSessionLocal() as session:
            repo = PostgresPersonRepository(session)
            service = PersonService(repo)
            await service.activate_participant_program(participant_id, program_id)
            return "OK"

    @strawberry.mutation
    async def create_workshop(self, input: CreateWorkshopInput, token: str) -> str:
        await enforce_access(token, "create_workshop")
        async with AsyncSessionLocal() as session:
            repo = PostgresPersonRepository(session)
            service = PersonService(repo)
            await service.create_workshop(
                n_id_program=input.n_id_program,
                c_description=input.c_description,
                c_status=input.c_status,
                t_date=input.t_date,
            )
            return "OK"

    @strawberry.mutation
    async def update_workshop_status(self, input: UpdateWorkshopStatusInput, token: str) -> str:
        await enforce_access(token, "update_workshop_status")
        async with AsyncSessionLocal() as session:
            repo = PostgresPersonRepository(session)
            service = PersonService(repo)
            result = await service.update_workshop_status(input.n_id_workshop, input.c_status)
            if not result:
                raise ValueError(f"Workshop with id '{input.n_id_workshop}' not found")
            return "OK"
