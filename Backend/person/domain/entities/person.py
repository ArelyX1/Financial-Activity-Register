from dataclasses import dataclass
from typing import Optional
from datetime import datetime


@dataclass
class Person:
    n_id_person: Optional[str] = None
    c_name: str = ""
    c_last_name: str = ""
    n_id_identification_type: int = 0
    c_identification_number: str = ""
    n_birth_place_gadm: Optional[int] = None
    n_residence_place_gadm: Optional[int] = None
    t_created_at: Optional[datetime] = None
    t_modified_at: Optional[datetime] = None
    role_name: str = ""
    c_photo_url: Optional[str] = None
    c_username: Optional[str] = None
    c_email: Optional[str] = None
