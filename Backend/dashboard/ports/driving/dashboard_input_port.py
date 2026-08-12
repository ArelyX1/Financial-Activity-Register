from abc import ABC, abstractmethod
from typing import Optional
from dashboard.domain.entities.dashboard import DashboardStats


class DashboardInputPort(ABC):
    @abstractmethod
    def get_stats(self, gid0: Optional[str] = None, gid1: Optional[str] = None, gid2: Optional[str] = None, gid3: Optional[str] = None) -> DashboardStats:
        pass
