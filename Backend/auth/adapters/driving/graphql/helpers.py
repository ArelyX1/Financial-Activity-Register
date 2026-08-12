from typing import Any
import strawberry
from strawberry.types import Info
from auth.domain.services.jwt_service import JwtService
from auth.domain.services.auth_enforcer import PermissionEnforcer
from redis_services.permission_cache import PermissionCache
from redis_services.redis_client import RedisClient
from person.domain.services.person_service import PersonService
from person.adapters.driven.postgres_person_repository import PostgresPersonRepository
from db.config import AsyncSessionLocal
import hashlib


class AuthError(Exception):
    def __init__(self, message: str):
        super().__init__(message)


async def _is_token_blacklisted(token: str) -> bool:
    token_hash = hashlib.sha256(token.encode()).hexdigest()
    redis = RedisClient.get_instance()
    exists = await redis.exists(f"blacklist:token:{token_hash}")
    return bool(exists)


async def resolve_user_from_token(token: str) -> dict[str, Any]:
    if await _is_token_blacklisted(token):
        raise AuthError("Token has been revoked")

    jwt_service = JwtService()
    payload = jwt_service.decode_token(token)
    if not payload or payload.get("type") != "access":
        raise AuthError("Invalid or expired token")

    user_id = payload["sub"]
    roles = payload.get("roles", [])
    permission_cache = PermissionCache()

    permissions = await permission_cache.get_permissions(user_id)
    if permissions is None:
        async with AsyncSessionLocal() as session:
            repo = PostgresPersonRepository(session)
            service = PersonService(repo)
            permissions = await service.get_person_permissions(user_id)
        await permission_cache.set_permissions(user_id, permissions)

    return {"user_id": user_id, "roles": roles, "permissions": permissions}


async def enforce_access(token: str, operation: str) -> dict[str, Any]:
    user_data = await resolve_user_from_token(token)
    enforcer = PermissionEnforcer()
    if not enforcer.can_access(user_data["permissions"], operation):
        raise AuthError(f"Access denied. Missing required permission for '{operation}'")
    return user_data


async def check_access(token: str, operation: str) -> bool:
    try:
        await enforce_access(token, operation)
        return True
    except AuthError:
        return False


async def enforce_access_from_context(context: dict[str, Any], operation: str) -> dict[str, Any]:
    if not context.get("user_id"):
        raise AuthError("Not authenticated")
    enforcer = PermissionEnforcer()
    if not enforcer.can_access(context.get("permissions", []), operation):
        raise AuthError(f"Access denied. Missing required permission for '{operation}'")
    return context
