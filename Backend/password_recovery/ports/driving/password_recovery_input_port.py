from abc import ABC, abstractmethod


class PasswordRecoveryInputPort(ABC):
    @abstractmethod
    async def generate_recovery_code(self, identification_number: str) -> dict: ...

    @abstractmethod
    async def change_password(self, identification_number: str, code: str, new_password: str) -> dict: ...
