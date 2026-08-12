from typing import Any, Optional
from starlette.requests import Request
from starlette.responses import Response
from auth.domain.services.jwt_service import JwtService
from redis_services.permission_cache import PermissionCache
from redis_services.redis_client import RedisClient
from person.domain.services.person_service import PersonService
from person.adapters.driven.postgres_person_repository import PostgresPersonRepository
from db.config import AsyncSessionLocal
import hashlib


async def _is_token_blacklisted(token: str) -> bool:
    token_hash = hashlib.sha256(token.encode()).hexdigest()
    redis = RedisClient.get_instance()
    exists = await redis.exists(f"blacklist:token:{token_hash}")
    return bool(exists)


async def get_context(request: Request, response: Response) -> dict[str, Any]:
    ctx: dict[str, Any] = {
        "request": request,
        "response": response,
        "user_id": None,
        "roles": [],
        "permissions": [],
    }

    auth_header = request.headers.get("Authorization", "")
    if not auth_header.startswith("Bearer "):
        return ctx

    token = auth_header[7:]

    if await _is_token_blacklisted(token):
        return ctx

    jwt_service = JwtService()
    payload = jwt_service.decode_token(token)
    if not payload or payload.get("type") != "access":
        return ctx

    user_id: str = payload["sub"]
    roles: list[str] = payload.get("roles", [])
    permission_cache = PermissionCache()

    permissions = await permission_cache.get_permissions(user_id)
    if permissions is None:
        async with AsyncSessionLocal() as session:
            repo = PostgresPersonRepository(session)
            service = PersonService(repo)
            permissions = await service.get_person_permissions(user_id)
        await permission_cache.set_permissions(user_id, permissions)

    ctx["user_id"] = user_id
    ctx["roles"] = roles
    ctx["permissions"] = permissions
    return ctx
