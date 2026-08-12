from dataclasses import dataclass
from typing import Optional
from datetime import datetime


@dataclass
class UserAccount:
    n_id_user: Optional[str] = None
    c_username: str = ""
    c_email: str = ""
    c_hashed_password: str = ""
    c_wallet: str = ""
    c_phrase: str = ""
    c_salt: str = ""
    c_provider_id: str = ""
    n_id_account_provider: Optional[int] = None
    b_email_verified: Optional[bool] = False
    t_latest_access: Optional[datetime] = None
    created_at: Optional[datetime] = None
    c_photo_url: str = ""
    b_is_active: Optional[bool] = True
