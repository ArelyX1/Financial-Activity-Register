from dataclasses import dataclass, field
from typing import List, Optional


@dataclass
class CountItem:
    label: str
    count: int


@dataclass
class DashboardStats:
    total_persons: int = 0
    total_participants: int = 0
    total_employees: int = 0
    total_superiors: int = 0
    total_programs: int = 0
    total_workshops: int = 0
    total_active_users: int = 0
    persons_by_role: List[CountItem] = field(default_factory=list)
    workshops_by_status: List[CountItem] = field(default_factory=list)
    programs_by_status: List[CountItem] = field(default_factory=list)
    persons_by_boundary: List[CountItem] = field(default_factory=list)
