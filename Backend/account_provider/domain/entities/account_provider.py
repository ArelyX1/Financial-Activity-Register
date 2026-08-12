from dataclasses import dataclass
from typing import Optional


@dataclass
class AccountProvider:
    n_id_account_provider: Optional[int] = None
    c_name: str = ""
    b_is_active: Optional[bool] = True
