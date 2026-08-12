import strawberry
from typing import List, Optional
from db.config import AsyncSessionLocal
from dashboard.domain.services.dashboard_service import DashboardService
from dashboard.adapters.driven.postgres_dashboard_repository import PostgresDashboardRepository


@strawberry.type
class CountItemType:
    label: str
    count: int


@strawberry.type
class DashboardStatsType:
    total_persons: int
    total_participants: int
    total_employees: int
    total_superiors: int
    total_programs: int
    total_workshops: int
    total_active_users: int
    persons_by_role: List[CountItemType]
    workshops_by_status: List[CountItemType]
    programs_by_status: List[CountItemType]
    persons_by_boundary: List[CountItemType]


@strawberry.type
class Query:
    @strawberry.field
    async def dashboard_stats(self, gid0: Optional[str] = None, gid1: Optional[str] = None, gid2: Optional[str] = None, gid3: Optional[str] = None) -> DashboardStatsType:
        async with AsyncSessionLocal() as session:
            repo = PostgresDashboardRepository(session)
            service = DashboardService(repo)
            stats = await service.get_stats(gid0, gid1, gid2, gid3)
            return DashboardStatsType(
                total_persons=stats.total_persons,
                total_participants=stats.total_participants,
                total_employees=stats.total_employees,
                total_superiors=stats.total_superiors,
                total_programs=stats.total_programs,
                total_workshops=stats.total_workshops,
                total_active_users=stats.total_active_users,
                persons_by_role=[
                    CountItemType(label=i.label, count=i.count) for i in stats.persons_by_role
                ],
                workshops_by_status=[
                    CountItemType(label=i.label, count=i.count) for i in stats.workshops_by_status
                ],
                programs_by_status=[
                    CountItemType(label=i.label, count=i.count) for i in stats.programs_by_status
                ],
                persons_by_boundary=[
                    CountItemType(label=i.label, count=i.count) for i in stats.persons_by_boundary
                ],
            )
