import strawberry
from typing import List
from strawberry.types import Info
from person.domain.services.person_service import PersonService
from person.adapters.driven.postgres_person_repository import PostgresPersonRepository
from user_account.domain.services.user_account_service import UserAccountService
from user_account.adapters.driven.postgres_user_account_repository import PostgresUserAccountRepository
from user_account.domain.entities.user_account import UserAccount as UserAccountEntity
from db.config import AsyncSessionLocal
from auth.adapters.driving.graphql.helpers import enforce_access


@strawberry.type
class UserAccount:
    id: str
    username: str
    email: str
    hashed_password: str
    wallet: str
    phrase: str
    salt: str
    provider_id: str
    n_id_account_provider: int | None = None
    email_verified: bool | None = None
    is_active: bool | None = None
    photo_url: str | None = None
    latest_access: str | None = None
    created_at: str | None = None


@strawberry.type
class UserByDocument:
    id: str
    name: str
    last_name: str
    identification_number: str
    username: str
    email: str
    is_active: bool | None = None
    photo_url: str | None = None
    latest_access: str | None = None
    created_at: str | None = None


@strawberry.input
class CreateUserInput:
    identification_number: str
    username: str
    email: str
    password: str
    n_id_account_provider: int
    provider_id: str = ""
    email_verified: bool = False
    photo_url: str = ""


@strawberry.type
class Query:
    @strawberry.field
    async def user_by_document(self, identification_number: str) -> UserByDocument | None:
        async with AsyncSessionLocal() as session:
            person_repo = PostgresPersonRepository(session)
            person_service = PersonService(person_repo)
            person = await person_service.find_by_identification_number(identification_number)
            if not person:
                return None

            user_repo = PostgresUserAccountRepository(session)
            account = await user_repo.find_by_id(person.n_id_person)

            return UserByDocument(
                id=person.n_id_person,
                name=person.c_name,
                last_name=person.c_last_name,
                identification_number=person.c_identification_number,
                username=account.c_username if account else "",
                email=account.c_email if account else "",
                is_active=account.b_is_active if account else None,
                photo_url=account.c_photo_url if account else None,
                latest_access=str(account.t_latest_access) if account and account.t_latest_access else None,
                created_at=str(account.created_at) if account and account.created_at else None,
            )

    @strawberry.field
    async def user_accounts(self, info: Info, token: str) -> List[UserAccount]:
        await enforce_access(token, "user_accounts")
        async with AsyncSessionLocal() as session:
            repo = PostgresUserAccountRepository(session)
            service = UserAccountService(repo)
            items = await service.get_all()
            return [
                UserAccount(
                    id=u.n_id_user,
                    username=u.c_username,
                    email=u.c_email,
                    hashed_password=u.c_hashed_password,
                    wallet=u.c_wallet,
                    phrase=u.c_phrase,
                    salt=u.c_salt,
                    provider_id=u.c_provider_id,
                    n_id_account_provider=u.n_id_account_provider,
                    email_verified=u.b_email_verified,
                    is_active=u.b_is_active,
                    photo_url=u.c_photo_url,
                    latest_access=str(u.t_latest_access) if u.t_latest_access else None,
                    created_at=str(u.created_at) if u.created_at else None,
                )
                for u in items
            ]


@strawberry.type
class Mutation:
    @strawberry.mutation
    async def create_user(self, info: Info, input: CreateUserInput) -> UserAccount:
        async with AsyncSessionLocal() as session:
            person_repo = PostgresPersonRepository(session)
            person_service = PersonService(person_repo)
            person = await person_service.find_by_identification_number(input.identification_number)
            if not person:
                raise ValueError(f"Person with identification number '{input.identification_number}' not found")
            if not person.c_name or not person.c_last_name:
                raise ValueError("Person data is incomplete: name and last name are required")

            repo = PostgresUserAccountRepository(session)
            service = UserAccountService(repo)

            entity = UserAccountEntity(
                n_id_user=person.n_id_person,
                c_username=input.username.strip(),
                c_email=input.email,
                c_provider_id=input.provider_id,
                n_id_account_provider=input.n_id_account_provider,
                b_email_verified=input.email_verified,
                c_photo_url=input.photo_url,
            )
            created = await service.create(entity, password=input.password)

            user_id = person.n_id_person
            role_names = await person_repo.find_role_names_by_person_id(user_id)
            for role_name in role_names:
                r = role_name.lower()
                if r in ("admin", "observer", "papu"):
                    await person_repo.save_employee(user_id)
                elif r == "participant":
                    await person_repo.save_participant(user_id)
                elif r == "superior":
                    await person_repo.save_superior(user_id)

            return UserAccount(
                id=created.n_id_user,
                username=created.c_username,
                email=created.c_email,
                hashed_password=created.c_hashed_password,
                wallet=created.c_wallet,
                phrase=created.c_phrase,
                salt=created.c_salt,
                provider_id=created.c_provider_id,
                n_id_account_provider=created.n_id_account_provider,
                email_verified=created.b_email_verified,
                photo_url=created.c_photo_url,
                is_active=created.b_is_active,
                latest_access=str(created.t_latest_access) if created.t_latest_access else None,
                created_at=str(created.created_at) if created.created_at else None,
            )

    @strawberry.mutation
    async def update_user_status(self, token: str, n_id_user: str, b_is_active: bool) -> bool:
        await enforce_access(token, "update_user_status")
        async with AsyncSessionLocal() as session:
            repo = PostgresUserAccountRepository(session)
            service = UserAccountService(repo)
            await service.update_status(n_id_user, b_is_active)

            person_repo = PostgresPersonRepository(session)
            role_names = await person_repo.find_role_names_by_person_id(n_id_user)
            for role_name in role_names:
                r = role_name.lower()
                if r in ("admin", "observer", "papu"):
                    await person_repo.update_employee_status(n_id_user, b_is_active)
                elif r == "participant":
                    await person_repo.update_participant_status(n_id_user, b_is_active)
                elif r == "superior":
                    await person_repo.update_superior_status(n_id_user, b_is_active)

            return True
