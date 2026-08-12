from abc import ABC, abstractmethod
from typing import List, Optional
from user_account.domain.entities.user_account import UserAccount


class UserAccountInputPort(ABC):
    @abstractmethod
    async def get_all(self) -> List[UserAccount]: ...

    @abstractmethod
    async def find_by_id(self, n_id_user: str) -> Optional[UserAccount]: ...

    @abstractmethod
    async def create(self, data: UserAccount, password: str) -> UserAccount: ...

    @abstractmethod
    async def update_status(self, n_id_user: str, b_is_active: bool) -> None: ...
