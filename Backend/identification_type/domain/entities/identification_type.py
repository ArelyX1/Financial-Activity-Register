from dataclasses import dataclass
from typing import Optional


@dataclass
class IdentificationType:
    n_id_identification_type: Optional[int] = None
    c_country_iso: str = "PE"
    c_code: Optional[str] = None
    c_name: str = ""
    n_min_length: int = 1
    n_max_length: int = 0
    b_is_numeric: Optional[bool] = True
    c_regex: Optional[str] = None
    b_is_active: Optional[bool] = True
