import asyncio
import os
import smtplib
from email.message import EmailMessage
from pathlib import Path

from dotenv import load_dotenv

from password_recovery.ports.driven.email_sender_port import EmailSenderPort

load_dotenv(dotenv_path=Path(__file__).resolve().parents[2] / ".env", override=True)


class SmtpEmailSender(EmailSenderPort):
    def __init__(
        self,
        host: str | None = None,
        port: int | None = None,
        username: str | None = None,
        password: str | None = None,
        from_email: str | None = None,
        starttls: bool | None = None,
    ):
        self._host = host or os.getenv("SMTP_HOST", "smtp.gmail.com")
        self._port = port if port is not None else int(os.getenv("SMTP_PORT", "587"))
        self._username = username if username is not None else os.getenv("SMTP_USERNAME", "")
        self._password = password if password is not None else os.getenv("SMTP_PASSWORD", "")
        self._from_email = from_email or os.getenv("SMTP_FROM", self._username)
        starttls_env = os.getenv("SMTP_STARTTLS", "true").lower() in ("1", "true", "yes")
        self._starttls = starttls if starttls is not None else starttls_env

    async def send_recovery_code(self, to_email: str, code: str) -> None:
        if not self._username or not self._password:
            raise ValueError("SMTP credentials are not configured (SMTP_USERNAME / SMTP_PASSWORD)")
        body = (
            "Has solicitado recuperar tu contraseña.\n\n"
            f"Tu código de recuperación es: {code}\n"
            "El código expira en 10 minutos.\n\n"
            "Si no solicitaste este cambio, ignora este correo."
        )
        await asyncio.to_thread(self._send_sync, to_email, body)

    def _send_sync(self, to_email: str, body: str) -> None:
        msg = EmailMessage()
        msg["Subject"] = "Código de recuperación de contraseña"
        msg["From"] = self._from_email
        msg["To"] = to_email
        msg.set_content(body)

        with smtplib.SMTP(self._host, self._port, timeout=15) as server:
            if self._starttls:
                server.starttls()
            server.login(self._username, self._password)
            server.send_message(msg)
