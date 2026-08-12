import os
from datetime import datetime, timedelta, timezone
from typing import Any
import jwt
from pathlib import Path
from dotenv import load_dotenv

load_dotenv(dotenv_path=Path(__file__).parent.parent.parent.parent / "db" / ".env")


class JwtService:
    def __init__(
        self,
        secret_key: str | None = None,
        algorithm: str | None = None,
        access_expire_minutes: int | None = None,
        refresh_expire_days: int | None = None,
    ):
        self._secret_key = secret_key or os.getenv("JWT_SECRET_KEY", "super-secret-key-change-in-production")
        self._algorithm = algorithm or os.getenv("JWT_ALGORITHM", "HS256")
        self._access_expire = access_expire_minutes or int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "15"))
        self._refresh_expire = refresh_expire_days or int(os.getenv("REFRESH_TOKEN_EXPIRE_DAYS", "7"))

    def create_access_token(self, user_id: str, roles: list[str]) -> str:
        now = datetime.now(timezone.utc)
        payload: dict[str, Any] = {
            "sub": user_id,
            "roles": roles,
            "iat": now,
            "exp": now + timedelta(minutes=self._access_expire),
            "type": "access",
        }
        return jwt.encode(payload, self._secret_key, algorithm=self._algorithm)

    def create_refresh_token(self, user_id: str) -> str:
        now = datetime.now(timezone.utc)
        payload: dict[str, Any] = {
            "sub": user_id,
            "iat": now,
            "exp": now + timedelta(days=self._refresh_expire),
            "type": "refresh",
        }
        return jwt.encode(payload, self._secret_key, algorithm=self._algorithm)

    def create_token_pair(self, user_id: str, roles: list[str]) -> dict[str, str]:
        now = datetime.now(timezone.utc)
        access_exp = now + timedelta(minutes=self._access_expire)
        refresh_exp = now + timedelta(days=self._refresh_expire)
        return {
            "access_token": self.create_access_token(user_id, roles),
            "refresh_token": self.create_refresh_token(user_id),
            "token_created_at": now.isoformat(),
            "access_token_expires_at": access_exp.isoformat(),
            "refresh_token_expires_at": refresh_exp.isoformat(),
        }

    def decode_token(self, token: str) -> dict[str, Any] | None:
        try:
            return jwt.decode(token, self._secret_key, algorithms=[self._algorithm])
        except jwt.InvalidTokenError:
            return None
