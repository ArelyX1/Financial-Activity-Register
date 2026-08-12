from typing import Optional
from dashboard.domain.entities.dashboard import DashboardStats
from dashboard.ports.driven.dashboard_repository_port import DashboardRepositoryPort
from dashboard.ports.driving.dashboard_input_port import DashboardInputPort


class DashboardService(DashboardInputPort):
    def __init__(self, repo: DashboardRepositoryPort):
        self._repo = repo

    def get_stats(self, gid0: Optional[str] = None, gid1: Optional[str] = None, gid2: Optional[str] = None, gid3: Optional[str] = None) -> DashboardStats:
        return self._repo.get_stats(gid0, gid1, gid2, gid3)
