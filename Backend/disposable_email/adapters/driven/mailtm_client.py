import asyncio
import json
import secrets
import urllib.error
import urllib.request

from disposable_email.domain.entities.disposable_inbox import DisposableInbox
from disposable_email.ports.driven.mailtm_client_port import MailtmClientPort

API_BASE = "https://api.mail.tm"


class MailtmClient(MailtmClientPort):
    def _request(self, method: str, path: str, body: dict | None = None, token: str | None = None):
        headers = {"Content-Type": "application/json", "Accept": "application/json"}
        if token:
            headers["Authorization"] = f"Bearer {token}"
        data = json.dumps(body).encode() if body is not None else None
        req = urllib.request.Request(API_BASE + path, data=data, headers=headers, method=method)
        try:
            with urllib.request.urlopen(req, timeout=15) as resp:
                raw = resp.read()
                return resp.status, json.loads(raw) if raw else None
        except urllib.error.HTTPError as e:
            return e.code, None

    def _random_address(self, domain: str) -> str:
        return f"recov-{secrets.token_hex(6)}@{domain}"

    async def create_account(self) -> DisposableInbox:
        return await asyncio.to_thread(self._create_account_sync)

    def _create_account_sync(self) -> DisposableInbox:
        status, body = self._request("GET", "/domains")
        if status != 200 or not body:
            raise ValueError("No se pudo consultar los dominios de Mail.tm")
        domains = body if isinstance(body, list) else body.get("hydra:member", [])
        domain = next((d["domain"] for d in domains if d.get("isActive")), None)
        if not domain:
            raise ValueError("Mail.tm no tiene dominios activos disponibles")

        address = self._random_address(domain)
        password = secrets.token_urlsafe(12)
        status, body = self._request(
            "POST", "/accounts", {"address": address, "password": password}
        )
        if status not in (200, 201):
            raise ValueError(f"Mail.tm no pudo crear la cuenta descartable (HTTP {status})")
        return DisposableInbox(
            address=address,
            password=password,
            account_id=body.get("id"),
        )

    async def is_account_active(self, address: str, password: str) -> bool:
        return await asyncio.to_thread(self._is_account_active_sync, address, password)

    def _is_account_active_sync(self, address: str, password: str) -> bool:
        status, body = self._request("POST", "/token", {"address": address, "password": password})
        return status == 200 and bool(body and body.get("token"))

    async def delete_account(self, account_id: str, address: str, password: str) -> bool:
        return await asyncio.to_thread(self._delete_account_sync, account_id, address, password)

    def _delete_account_sync(self, account_id: str, address: str, password: str) -> bool:
        status, body = self._request("POST", "/token", {"address": address, "password": password})
        if status != 200 or not body or not body.get("token"):
            return False
        status, _ = self._request("DELETE", f"/accounts/{account_id}", token=body["token"])
        return status in (200, 204)
