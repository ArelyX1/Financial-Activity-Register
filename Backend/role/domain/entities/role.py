from dataclasses import dataclass, field
from typing import Optional
from datetime import datetime


@dataclass
class Permission:
    n_id_permission: Optional[int] = None
    c_code: str = ""
    c_name: str = ""
    c_description: Optional[str] = None
    c_module: Optional[str] = None
    b_is_active: Optional[bool] = True
    t_created_at: Optional[datetime] = None


@dataclass
class Role:
    n_id_role: Optional[int] = None
    c_name: str = ""
    c_description: Optional[str] = None
    b_is_system_role: Optional[bool] = False
    b_is_active: Optional[bool] = True
    t_created_at: Optional[datetime] = None
    permissions: list[Permission] = field(default_factory=list)
