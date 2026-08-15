import asyncio
import email.utils
import random
import smtplib
import socket
import struct
from email.message import EmailMessage
from pathlib import Path

from dotenv import load_dotenv

from password_recovery.ports.driven.email_sender_port import EmailSenderPort

load_dotenv(dotenv_path=Path(__file__).resolve().parents[2] / ".env")

DEFAULT_FROM = "noreply@incasur.local"


def _read_system_nameservers() -> list[str]:
    servers = []
    try:
        for line in Path("/etc/resolv.conf").read_text().splitlines():
            parts = line.split()
            if len(parts) >= 2 and parts[0] == "nameserver":
                servers.append(parts[1])
    except OSError:
        pass
    return servers or ["8.8.8.8"]


def _resolve_mx(domain: str, timeout: float = 5.0) -> str | None:
    qname = b"".join(bytes([len(label)]) + label.encode() for label in domain.split(".")) + b"\x00"
    question = qname + struct.pack(">HH", 15, 1)  # MX, IN
    txid = random.randint(0, 0xFFFF)
    packet = struct.pack(">HHHHHH", txid, 0x0100, 1, 0, 0, 0) + question

    for nameserver in _read_system_nameservers():
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.settimeout(timeout)
        try:
            sock.sendto(packet, (nameserver, 53))
            data, _ = sock.recvfrom(4096)
        except OSError:
            continue
        finally:
            sock.close()

        if len(data) < 12 or struct.unpack(">H", data[:2])[0] != txid:
            continue
        answers = struct.unpack(">H", data[6:8])[0]
        if answers == 0:
            continue

        offset = 12
        while offset < len(data) and data[offset] != 0:
            offset += data[offset] + 1
        offset += 5

        best = None
        for _ in range(answers):
            if offset >= len(data):
                break
            if data[offset] & 0xC0 == 0xC0:
                offset += 2
            else:
                while offset < len(data) and data[offset] != 0:
                    offset += data[offset] + 1
                offset += 1
            if offset + 10 > len(data):
                break
            rtype, _rclass, _ttl, rdlen = struct.unpack(">HHIH", data[offset : offset + 10])
            offset += 10
            if rtype == 15 and offset + rdlen <= len(data):
                preference = struct.unpack(">H", data[offset : offset + 2])[0]
                host = _decode_compressed_name(data, offset + 2, offset)
                if host:
                    best = min((best, (preference, host))) if best else (preference, host)
            offset += rdlen

        if best:
            return best[1]
    return None


def _decode_compressed_name(data: bytes, start: int, base: int) -> str | None:
    labels = []
    offset = start
    seen = set()
    while offset < len(data) and len(seen) < 32:
        length = data[offset]
        if length == 0:
            return ".".join(labels) if labels else None
        if length & 0xC0 == 0xC0:
            if offset + 1 >= len(data):
                return None
            pointer = ((length & 0x3F) << 8) | data[offset + 1]
            if pointer in seen or pointer >= len(data):
                return None
            seen.add(pointer)
            offset = pointer
            continue
        offset += 1
        if offset + length > len(data):
            return None
        labels.append(data[offset : offset + length].decode("utf-8", "replace"))
        offset += length
    return ".".join(labels) if labels else None


class DirectSmtpEmailSender(EmailSenderPort):
    def __init__(self, from_email: str | None = None, port: int = 25):
        self._from_email = from_email or DEFAULT_FROM
        self._port = port

    async def send_recovery_code(self, to_email: str, code: str) -> None:
        body = (
            "Has solicitado recuperar tu contraseña.\n\n"
            f"Tu código de recuperación es: {code}\n"
            "El código expira en 10 minutos.\n\n"
            "Si no solicitaste este cambio, ignora este correo."
        )
        await asyncio.to_thread(self._send_sync, to_email, body)

    def _send_sync(self, to_email: str, body: str) -> None:
        domain = to_email.rsplit("@", 1)[-1]
        mx_host = _resolve_mx(domain)
        if not mx_host:
            raise ValueError(f"No se pudo resolver el servidor MX para '{domain}'")

        msg = EmailMessage()
        msg["Subject"] = "Código de recuperación de contraseña"
        msg["From"] = self._from_email
        msg["To"] = to_email
        msg["Message-ID"] = email.utils.make_msgid(domain=self._from_email.rsplit("@", 1)[-1])
        msg["Date"] = email.utils.formatdate(localtime=True)
        msg.set_content(body)

        with smtplib.SMTP(mx_host, self._port, timeout=20) as server:
            server.ehlo_or_helo_if_needed()
            server.send_message(msg)
