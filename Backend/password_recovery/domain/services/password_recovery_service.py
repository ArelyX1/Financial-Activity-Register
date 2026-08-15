import rust_services as rs
from password_recovery.ports.driving.password_recovery_input_port import PasswordRecoveryInputPort
from password_recovery.ports.driven.recovery_code_repository_port import RecoveryCodeRepositoryPort
from password_recovery.ports.driven.email_sender_port import EmailSenderPort
from person.ports.driving.person_input_port import PersonInputPort
from user_account.ports.driving.user_account_input_port import UserAccountInputPort
from disposable_email.domain.services.disposable_email_service import DisposableEmailService

RECOVERY_CODE_TTL_SECONDS = 600


class PasswordRecoveryService(PasswordRecoveryInputPort):
    def __init__(
        self,
        person_service: PersonInputPort,
        user_account_service: UserAccountInputPort,
        recovery_code_repo: RecoveryCodeRepositoryPort,
        email_sender: EmailSenderPort,
        disposable_email_service: DisposableEmailService | None = None,
    ):
        self._person_service = person_service
        self._user_account_service = user_account_service
        self._recovery_code_repo = recovery_code_repo
        self._email_sender = email_sender
        self._disposable_email_service = disposable_email_service

    async def generate_recovery_code(self, identification_number: str) -> dict:
        person = await self._person_service.find_by_identification_number(identification_number)
        if not person:
            raise ValueError(f"Person with identification number '{identification_number}' not found")

        account = await self._user_account_service.find_by_id(person.n_id_person)
        if not account or not account.c_salt:
            raise ValueError("No user account found for the given identification number")
        if not account.c_email:
            raise ValueError("The user has no registered email to send the recovery code")

        code = rs.generate_recovery_code()
        await self._recovery_code_repo.save(identification_number, code, RECOVERY_CODE_TTL_SECONDS)
        await self._email_sender.send_recovery_code(account.c_email, code)

        return {
            "success": True,
            "expires_in": RECOVERY_CODE_TTL_SECONDS,
            "delivered_to": account.c_email,
        }

    async def change_password(self, identification_number: str, code: str, new_password: str) -> dict:
        person = await self._person_service.find_by_identification_number(identification_number)
        if not person:
            raise ValueError(f"Person with identification number '{identification_number}' not found")

        account = await self._user_account_service.find_by_id(person.n_id_person)
        if not account or not account.c_salt:
            raise ValueError("No user account found for the given identification number")

        is_valid = await self._recovery_code_repo.verify(identification_number, code)
        if not is_valid:
            raise ValueError("Invalid or expired recovery code")

        enc_pwd, salt = rs.register(new_password)
        await self._user_account_service.update_password(
            person.n_id_person, enc_pwd.hex(), salt
        )

        return {"success": True}
