from abc import ABC, abstractmethod
from typing import List, Optional


class AuthInputPort(ABC):
    @abstractmethod
    async def login(self, identification_number: str, password: str) -> dict: ...

    @abstractmethod
    async def refresh_user_roles(self, user_id: str) -> dict: ...

    @abstractmethod
    async def logout(self, user_id: str, token: str) -> dict: ...
