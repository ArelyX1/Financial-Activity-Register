import asyncio
import json
import os
import urllib.error
import urllib.request
from pathlib import Path

from dotenv import load_dotenv

from password_recovery.ports.driven.email_sender_port import EmailSenderPort

load_dotenv(dotenv_path=Path(__file__).resolve().parents[2] / ".env")

RESEND_API_URL = "https://api.resend.com/emails"
RESEND_FROM = "Recuperación de contraseña <onboarding@resend.dev>"


class ResendEmailSender(EmailSenderPort):
    def __init__(self, api_key: str | None = None, from_email: str | None = None):
        self._api_key = api_key if api_key is not None else os.getenv("RESEND_API_KEY", "")
        self._from = from_email or os.getenv("RESEND_FROM", RESEND_FROM)

    async def send_recovery_code(self, to_email: str, code: str) -> None:
        if not self._api_key:
            raise ValueError("RESEND_API_KEY is not configured")
        body = (
            "Has solicitado recuperar tu contraseña.\n\n"
            f"Tu código de recuperación es: {code}\n"
            "El código expira en 10 minutos.\n\n"
            "Si no solicitaste este cambio, ignora este correo."
        )
        await asyncio.to_thread(self._send_sync, to_email, body)

    def _send_sync(self, to_email: str, body: str) -> None:
        payload = json.dumps(
            {
                "from": self._from,
                "to": [to_email],
                "subject": "Código de recuperación de contraseña",
                "text": body,
            }
        ).encode()
        req = urllib.request.Request(
            RESEND_API_URL,
            data=payload,
            method="POST",
            headers={
                "Authorization": f"Bearer {self._api_key}",
                "Content-Type": "application/json",
                "User-Agent": "financial-activity-register-backend/1.0",
            },
        )
        try:
            with urllib.request.urlopen(req, timeout=20) as resp:
                resp.read()
        except urllib.error.HTTPError as e:
            detail = e.read().decode(errors="replace")
            raise ValueError(f"Resend error (HTTP {e.code}): {detail}")
