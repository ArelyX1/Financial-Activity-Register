from typing import Optional
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession
from dashboard.ports.driven.dashboard_repository_port import DashboardRepositoryPort
from dashboard.domain.entities.dashboard import DashboardStats, CountItem


class PostgresDashboardRepository(DashboardRepositoryPort):
    def __init__(self, session: AsyncSession):
        self._session = session

    async def get_stats(self, gid0: Optional[str] = None, gid1: Optional[str] = None, gid2: Optional[str] = None, gid3: Optional[str] = None) -> DashboardStats:
        boundary_where = ""
        params: dict = {}
        if gid0 or gid1 or gid2 or gid3:
            boundary_where = """
                AND EXISTS (
                    SELECT 1 FROM "S01BOUNDARIE" b
                    WHERE b."nuidgadm" = p."nBirthPlaceGadm"
            """
            if gid0:
                boundary_where += ' AND b."cgid0" = :gid0'
                params["gid0"] = gid0
            if gid1:
                boundary_where += ' AND b."cgid1" = :gid1'
                params["gid1"] = gid1
            if gid2:
                boundary_where += ' AND b."cgid2" = :gid2'
                params["gid2"] = gid2
            if gid3:
                boundary_where += ' AND b."cgid3" = :gid3'
                params["gid3"] = gid3
            boundary_where += ')'

        sql_total = text(f"""
            SELECT COUNT(DISTINCT p.nidperson)
            FROM "S02PERSON" p
            WHERE 1=1 {boundary_where}
        """)
        result = await self._session.execute(sql_total, params)
        total_persons = result.scalar() or 0

        sql_roles = text(f"""
            SELECT r.cname, COUNT(DISTINCT p.nidperson)
            FROM "S02PERSON" p
            JOIN "S02PERSON_ROLE" pr ON pr.nidperson = p.nidperson
            JOIN "S02ROLE" r ON r.nidrole = pr.nidrole
            WHERE 1=1 {boundary_where}
            GROUP BY r.cname
        """)
        result = await self._session.execute(sql_roles, params)
        persons_by_role = [CountItem(label=row[0], count=row[1]) for row in result.fetchall()]

        total_participants = next(
            (item.count for item in persons_by_role if item.label == "PARTICIPANT"), 0
        )
        total_employee_admin = next(
            (item.count for item in persons_by_role if item.label == "ADMIN"), 0
        )
        total_employee_observer = next(
            (item.count for item in persons_by_role if item.label == "OBSERVER"), 0
        )
        total_superiors = next(
            (item.count for item in persons_by_role if item.label == "SUPERIOR"), 0
        )
        total_employees = total_employee_admin + total_employee_observer

        sql_programs = text("""
            SELECT cstatus, COUNT(*)
            FROM "S01PROGRAM"
            WHERE bisactive = true
            GROUP BY cstatus
        """)
        result = await self._session.execute(sql_programs)
        programs_by_status = [CountItem(label=row[0], count=row[1]) for row in result.fetchall()]
        total_programs = sum(item.count for item in programs_by_status)

        sql_workshops = text("""
            SELECT cstatus, COUNT(*)
            FROM "S01WORKSHOP"
            WHERE bisactive = true
            GROUP BY cstatus
        """)
        result = await self._session.execute(sql_workshops)
        workshops_by_status = [CountItem(label=row[0], count=row[1]) for row in result.fetchall()]
        total_workshops = sum(item.count for item in workshops_by_status)

        sql_users = text("""
            SELECT COUNT(DISTINCT u.niduser)
            FROM "S02USER" u
            WHERE u.bisactive = true
        """)
        result = await self._session.execute(sql_users)
        total_active_users = result.scalar() or 0

        gid_filter = ""
        gid_params: dict = {}
        if gid0:
            gid_filter = ' AND b."cgid0" = :bgid0'
            gid_params["bgid0"] = gid0
        if gid1:
            gid_filter += ' AND b."cgid1" = :bgid1'
            gid_params["bgid1"] = gid1
        if gid2:
            gid_filter += ' AND b."cgid2" = :bgid2'
            gid_params["bgid2"] = gid2
        if gid3:
            gid_filter += ' AND b."cgid3" = :bgid3'
            gid_params["bgid3"] = gid3

        gid_level = "cname1"
        if gid0 and not gid1:
            gid_level = "cname0"
        elif gid1 and not gid2:
            gid_level = "cname1"
        elif gid2 and not gid3:
            gid_level = "cname2"
        elif gid3:
            gid_level = "cname3"

        sql_boundary = text(f"""
            SELECT b."{gid_level}" AS name, COUNT(DISTINCT p.nidperson) AS cnt
            FROM "S02PERSON" p
            JOIN "S01BOUNDARIE" b ON b."nuidgadm" = p."nBirthPlaceGadm"
            WHERE 1=1 {gid_filter}
            GROUP BY b."{gid_level}"
            ORDER BY cnt DESC
            LIMIT 10
        """)
        result = await self._session.execute(sql_boundary, gid_params)
        persons_by_boundary = [CountItem(label=row[0], count=row[1]) for row in result.fetchall()]

        return DashboardStats(
            total_persons=total_persons,
            total_participants=total_participants,
            total_employees=total_employees,
            total_superiors=total_superiors,
            total_programs=total_programs,
            total_workshops=total_workshops,
            total_active_users=total_active_users,
            persons_by_role=persons_by_role,
            workshops_by_status=workshops_by_status,
            programs_by_status=programs_by_status,
            persons_by_boundary=persons_by_boundary,
        )
