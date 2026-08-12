from typing import List, Optional
import strawberry
from strawberry.types import Info
from auth.domain.services.auth_service import AuthService
from auth.domain.services.jwt_service import JwtService
from auth.adapters.driving.graphql.helpers import check_access, enforce_access
from redis_services.redis_client import RedisClient
from person.domain.services.person_service import PersonService
from person.adapters.driven.postgres_person_repository import PostgresPersonRepository
from user_account.domain.services.user_account_service import UserAccountService
from user_account.adapters.driven.postgres_user_account_repository import PostgresUserAccountRepository
from db.config import AsyncSessionLocal


@strawberry.type
class PermissionType:
    code: str = ""
    name: str = ""
    module: Optional[str] = None
    description: Optional[str] = None


@strawberry.type
class LoginPayload:
    success: bool
    access_token: Optional[str] = None
    refresh_token: Optional[str] = None
    token_created_at: Optional[str] = None
    access_token_expires_at: Optional[str] = None
    refresh_token_expires_at: Optional[str] = None
    roles: List[str] = strawberry.field(default_factory=list)
    permissions: List[PermissionType] = strawberry.field(default_factory=list)


@strawberry.type
class RefreshPayload:
    success: bool
    access_token: Optional[str] = None
    refresh_token: Optional[str] = None
    token_created_at: Optional[str] = None
    access_token_expires_at: Optional[str] = None
    refresh_token_expires_at: Optional[str] = None


@strawberry.type
class LogoutPayload:
    success: bool


@strawberry.type
class Query:
    @strawberry.field
    async def is_redis_available(self) -> bool:
        return await RedisClient.ping()

    @strawberry.field
    async def go_admin_page(self, info: Info, token: str) -> bool:
        return await check_access(token, "go_admin_page")

    @strawberry.field
    async def go_observer_page(self, info: Info, token: str) -> bool:
        return await check_access(token, "go_observer_page")

    @strawberry.field
    async def go_superior_page(self, info: Info, token: str) -> bool:
        return await check_access(token, "go_superior_page")

    @strawberry.field
    async def go_participant_page(self, info: Info, token: str) -> bool:
        return await check_access(token, "go_participant_page")


@strawberry.type
class Mutation:
    @strawberry.mutation
    async def login(self, identification_number: str, password: str) -> LoginPayload:
        async with AsyncSessionLocal() as session:
            person_repo = PostgresPersonRepository(session)
            user_account_repo = PostgresUserAccountRepository(session)
            service = AuthService(PersonService(person_repo), UserAccountService(user_account_repo))
            result = await service.login(identification_number, password)
            if not result["success"]:
                return LoginPayload(success=False)
            jwt_service = JwtService()
            tokens = jwt_service.create_token_pair(result["user_id"], result["roles"])
            perms = [PermissionType(**p) for p in result["permissions"]]
            return LoginPayload(
                success=True,
                access_token=tokens["access_token"],
                refresh_token=tokens["refresh_token"],
                token_created_at=tokens["token_created_at"],
                access_token_expires_at=tokens["access_token_expires_at"],
                refresh_token_expires_at=tokens["refresh_token_expires_at"],
                roles=result["roles"],
                permissions=perms,
            )

    @strawberry.mutation
    async def refresh_token(self, refresh_token: str) -> RefreshPayload:
        jwt_service = JwtService()
        payload = jwt_service.decode_token(refresh_token)
        if not payload or payload.get("type") != "refresh":
            return RefreshPayload(success=False)
        user_id = payload["sub"]
        async with AsyncSessionLocal() as session:
            person_repo = PostgresPersonRepository(session)
            user_account_repo = PostgresUserAccountRepository(session)
            auth_service = AuthService(PersonService(person_repo), UserAccountService(user_account_repo))
            data = await auth_service.refresh_user_roles(user_id)
            tokens = jwt_service.create_token_pair(user_id, data["roles"])
            await auth_service.blacklist_token(refresh_token, user_id, ttl=604800)
            return RefreshPayload(
                success=True,
                access_token=tokens["access_token"],
                refresh_token=tokens["refresh_token"],
                token_created_at=tokens["token_created_at"],
                access_token_expires_at=tokens["access_token_expires_at"],
                refresh_token_expires_at=tokens["refresh_token_expires_at"],
            )

    @strawberry.mutation
    async def logout(self, info: Info, token: str, refresh_token: str | None = None) -> LogoutPayload:
        try:
            user_data = await enforce_access(token, "logout")
            jwt_service = JwtService()
            payload = jwt_service.decode_token(token)
            if not payload:
                return LogoutPayload(success=False)
            user_id = payload["sub"]
            async with AsyncSessionLocal() as session:
                person_repo = PostgresPersonRepository(session)
                user_account_repo = PostgresUserAccountRepository(session)
                service = AuthService(PersonService(person_repo), UserAccountService(user_account_repo))
                result = await service.logout(user_id, token, refresh_token)
                return LogoutPayload(success=result["success"])
        except Exception:
            return LogoutPayload(success=False)
