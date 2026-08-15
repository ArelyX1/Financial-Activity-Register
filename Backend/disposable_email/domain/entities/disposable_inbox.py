from dataclasses import dataclass, field
from datetime import datetime


@dataclass
class DisposableInbox:
    address: str
    password: str
    account_id: str | None = None
    discarded: bool = False
    created_at: datetime | None = field(default=None, compare=False)
