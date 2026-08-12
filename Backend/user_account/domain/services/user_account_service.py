from typing import List, Optional
import rust_services as rs
from user_account.ports.driving.user_account_input_port import UserAccountInputPort
from user_account.ports.driven.user_account_repository_port import UserAccountRepositoryPort
from user_account.domain.entities.user_account import UserAccount


class UserAccountService(UserAccountInputPort):
    def __init__(self, repo: UserAccountRepositoryPort):
        self._repo = repo

    async def get_all(self) -> List[UserAccount]:
        return await self._repo.find_all()

    async def find_by_id(self, n_id_user: str) -> Optional[UserAccount]:
        return await self._repo.find_by_id(n_id_user)

    async def create(self, data: UserAccount, password: str) -> UserAccount:
        existing = await self._repo.find_by_email(data.c_email)
        if existing:
            raise ValueError(f"Email '{data.c_email}' is already registered")
        enc_pwd, enc_phrase, salt, wallet = rs.register(password)
        data.c_hashed_password = enc_pwd.hex()
        data.c_phrase = enc_phrase.hex()
        data.c_salt = salt
        data.c_wallet = wallet
        return await self._repo.save(data)

    async def update_status(self, n_id_user: str, b_is_active: bool) -> None:
        await self._repo.update_status(n_id_user, b_is_active)
