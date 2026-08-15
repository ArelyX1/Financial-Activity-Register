from abc import ABC, abstractmethod


class EmailSenderPort(ABC):
    @abstractmethod
    async def send_recovery_code(self, to_email: str, code: str) -> None:
        ...
