import strawberry
from strawberry.types import Info
from password_recovery.domain.services.password_recovery_service import PasswordRecoveryService
from password_recovery.adapters.driven.redis_recovery_code_repository import RedisRecoveryCodeRepository
from password_recovery.adapters.driven.smtp_email_sender import SmtpEmailSender
# from password_recovery.adapters.driven.guerrilla_email_sender import GuerrillaEmailSender
# from password_recovery.adapters.driven.direct_smtp_email_sender import DirectSmtpEmailSender
# from disposable_email.domain.services.disposable_email_service import DisposableEmailService
# from disposable_email.adapters.driven.mailtm_client import MailtmClient
# from disposable_email.adapters.driven.redis_inbox_repository import RedisInboxRepository
from person.domain.services.person_service import PersonService
from person.adapters.driven.postgres_person_repository import PostgresPersonRepository
from user_account.domain.services.user_account_service import UserAccountService
from user_account.adapters.driven.postgres_user_account_repository import PostgresUserAccountRepository
from redis_services.permission_cache import PermissionCache
from db.config import AsyncSessionLocal


@strawberry.type
class RecoveryCodePayload:
    success: bool
    expires_in: int | None = None
    delivered_to: str | None = None
    inbox_password: str | None = None


@strawberry.type
class PasswordChangePayload:
    success: bool


@strawberry.type
class Mutation:
    @strawberry.mutation
    async def generate_recovery_code(self, info: Info, identification_number: str) -> RecoveryCodePayload:
        async with AsyncSessionLocal() as session:
            person_service = PersonService(PostgresPersonRepository(session))
            user_account_service = UserAccountService(PostgresUserAccountRepository(session))
            service = PasswordRecoveryService(
                person_service,
                user_account_service,
                RedisRecoveryCodeRepository(),
                SmtpEmailSender(),
            )
            result = await service.generate_recovery_code(identification_number)
            return RecoveryCodePayload(
                success=result["success"],
                expires_in=result["expires_in"],
                delivered_to=result.get("delivered_to"),
            )

    @strawberry.mutation
    async def change_password(
        self, info: Info, identification_number: str, code: str, new_password: str
    ) -> PasswordChangePayload:
        async with AsyncSessionLocal() as session:
            person_service = PersonService(PostgresPersonRepository(session))
            user_account_service = UserAccountService(PostgresUserAccountRepository(session))
            service = PasswordRecoveryService(
                person_service,
                user_account_service,
                RedisRecoveryCodeRepository(),
                SmtpEmailSender(),
            )
            result = await service.change_password(identification_number, code, new_password)
            if result["success"]:
                person = await person_service.find_by_identification_number(identification_number)
                if person:
                    await PermissionCache().invalidate(person.n_id_person)
            return PasswordChangePayload(success=result["success"])
