from typing import List
import rust_services as rs
from auth.ports.driving.auth_input_port import AuthInputPort
from person.ports.driving.person_input_port import PersonInputPort
from user_account.ports.driving.user_account_input_port import UserAccountInputPort
from redis_services.permission_cache import PermissionCache
from redis_services.redis_client import RedisClient
import hashlib


class AuthService(AuthInputPort):
    def __init__(self, person_service: PersonInputPort, user_account_service: UserAccountInputPort):
        self._person_service = person_service
        self._user_account_service = user_account_service

    async def login(self, identification_number: str, password: str) -> dict:
        person = await self._person_service.find_by_identification_number(identification_number)
        if not person:
            return {"success": False, "user_id": None, "roles": []}

        user = await self._user_account_service.find_by_id(person.n_id_person)
        if not user or not user.c_salt:
            return {"success": False, "user_id": None, "roles": []}

        enc_pwd_bytes = bytes.fromhex(user.c_hashed_password)
        is_valid = rs.ok_password(enc_pwd_bytes, user.c_salt, password)

        roles: List[str] = []
        if is_valid:
            roles = await self._person_service.get_person_roles(person.n_id_person)

        permissions: List[dict] = []
        if is_valid:
            permissions = await self._person_service.get_person_permissions(person.n_id_person)

        return {
            "success": is_valid,
            "user_id": person.n_id_person if is_valid else None,
            "roles": roles,
            "permissions": permissions,
        }

    async def blacklist_token(self, token: str, user_id: str, ttl: int = 900) -> None:
        token_hash = hashlib.sha256(token.encode()).hexdigest()
        redis = RedisClient.get_instance()
        await redis.setex(f"blacklist:token:{token_hash}", ttl, user_id)

    async def logout(self, user_id: str, token: str, refresh_token: str | None = None) -> dict:
        permission_cache = PermissionCache()
        await permission_cache.invalidate(user_id)
        await self.blacklist_token(token, user_id)
        if refresh_token:
            await self.blacklist_token(refresh_token, user_id, ttl=604800)
        return {"success": True}

    async def refresh_user_roles(self, user_id: str) -> dict:
        roles = await self._person_service.get_person_roles(user_id)
        permissions = await self._person_service.get_person_permissions(user_id)
        return {"roles": roles, "permissions": permissions}
