import asyncio
import email.utils
import smtplib
import socket
from email.message import EmailMessage
from pathlib import Path

from dotenv import load_dotenv

from password_recovery.ports.driven.email_sender_port import EmailSenderPort

load_dotenv(dotenv_path=Path(__file__).resolve().parents[2] / ".env")

GUERRILLA_HOST = "mail.guerrillamail.com"
GUERRILLA_PORT = 25
GUERRILLA_SENDER_DOMAIN = "guerrillamail.com"


class GuerrillaEmailSender(EmailSenderPort):
    def __init__(self, from_address: str | None = None):
        self._from_address = from_address or f"recov-{self._random_suffix()}@{GUERRILLA_SENDER_DOMAIN}"

    @staticmethod
    def _random_suffix() -> str:
        return __import__("secrets").token_hex(6)

    async def send_recovery_code(self, to_email: str, code: str) -> None:
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
        msg["From"] = self._from_address
        msg["To"] = to_email
        msg["Message-ID"] = email.utils.make_msgid(domain=GUERRILLA_SENDER_DOMAIN)
        msg["Date"] = email.utils.formatdate(localtime=True)
        msg.set_content(body)

        socket.setdefaulttimeout(25)
        with smtplib.SMTP(GUERRILLA_HOST, GUERRILLA_PORT, timeout=25) as server:
            server.ehlo()
            server.starttls()
            server.ehlo()
            server.send_message(msg)
