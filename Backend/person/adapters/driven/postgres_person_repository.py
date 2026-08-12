from datetime import datetime
from typing import List, Optional
from sqlalchemy import select, text, Column, Integer, String, Boolean, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import joinedload
from sqlalchemy.ext.asyncio import AsyncSession
from person.ports.driven.person_repository_port import PersonRepositoryPort
from person.domain.entities.person import Person
from db.base import Base
from role.adapters.driven.postgres_role_repository import S02PermissionORM, S02RolePermissionORM, S02RoleORM
from user_account.adapters.driven.postgres_user_account_repository import S02UserORM


class S02PersonORM(Base):
    __tablename__ = "S02PERSON"

    nIdPerson = Column("nidperson", UUID, primary_key=True, server_default=text("gen_random_uuid()"))
    cName = Column("cname", String(100), nullable=False)
    cLastName = Column("clastname", String(100), nullable=False)
    nIdIdentificationType = Column("nididentificationtype", Integer, nullable=False)
    cIdentificationNumber = Column("cidentificationnumber", String(20), nullable=False)
    nBirthPlaceGadm = Column("nBirthPlaceGadm", Integer, quote=True)
    nResidencePlaceGadm = Column("nResidencePlaceGadm", Integer, quote=True)
    tCreatedAt = Column("tcreatedat", DateTime, server_default=text("NOW()"))
    tModifiedAt = Column("tmodifiedat", DateTime)


class S02PersonRoleORM(Base):
    __tablename__ = "S02PERSON_ROLE"

    nIdRole = Column("nidrole", Integer, ForeignKey("S02ROLE.nidrole"), primary_key=True)
    nIdPerson = Column("nidperson", UUID, ForeignKey("S02PERSON.nidperson"), primary_key=True)
    tCreatedAt = Column("tcreatedat", DateTime, server_default=text("NOW()"))


class S02ParticipantORM(Base):
    __tablename__ = "S02PARTICIPANT"

    nIdParticipant = Column("nidparticipant", UUID, ForeignKey("S02USER.niduser"), primary_key=True)
    bIsActive = Column("bisactive", Boolean, default=True)


class S02EmployeeORM(Base):
    __tablename__ = "S02EMPLOYEE"

    nIdEmployee = Column("nidemployee", UUID, ForeignKey("S02USER.niduser"), primary_key=True)
    bIsActive = Column("bisactive", Boolean, default=True)


class S02SuperiorORM(Base):
    __tablename__ = "S02SUPERIOR"

    nIdSuperior = Column("nidsuperior", UUID, ForeignKey("S02USER.niduser"), primary_key=True)
    bIsActive = Column("bisactive", Boolean, default=True)
    tCreatedAt = Column("tcreatedat", DateTime, server_default=text("NOW()"))


class S02ParticipantProgramORM(Base):
    __tablename__ = "S02PARTICIPANT_PROGRAM"

    nIdParticipant = Column("nidparticipant", UUID, ForeignKey("S02PARTICIPANT.nidparticipant"), primary_key=True)
    nIdProgram = Column("nidprogram", UUID, primary_key=True)
    bIsActive = Column("bisactive", Boolean, default=True)


class S02EmployeeProgramORM(Base):
    __tablename__ = "S02EMPLOYEE_PROGRAM"

    nIdEmployee = Column("nidemployee", UUID, ForeignKey("S02EMPLOYEE.nidemployee"), primary_key=True)
    nIdProgram = Column("nidprogram", UUID, primary_key=True)
    bIsActive = Column("bisactive", Boolean, default=True)
    tCreatedAt = Column("tcreatedat", DateTime, server_default=text("NOW()"))


class S01WorkshopORM(Base):
    __tablename__ = "S01WORKSHOP"

    nIdWorkshop = Column("nidworkshop", UUID, primary_key=True, server_default=text("gen_random_uuid()"))
    nIdProgram = Column("nidprogram", UUID, nullable=False)
    cDescription = Column("cdescription", String(200), nullable=False)
    cStatus = Column("cstatus", String(50))
    tDate = Column("tdate", DateTime)
    bIsActive = Column("bisactive", Boolean, default=True)


class PostgresPersonRepository(PersonRepositoryPort):
    def __init__(self, session: AsyncSession):
        self._session = session

    async def find_all(self) -> List[Person]:
        sql = text("""
            SELECT
                p.nidperson,
                p.cname,
                p.clastname,
                p.nididentificationtype,
                p.cidentificationnumber,
                p.tcreatedat,
                p.tmodifiedat,
                p."nBirthPlaceGadm",
                p."nResidencePlaceGadm",
                r.cname AS role_name
            FROM "S02PERSON" p
            LEFT JOIN "S02PERSON_ROLE" pr ON pr.nidperson = p.nidperson
            LEFT JOIN "S02ROLE" r ON r.nidrole = pr.nidrole
            ORDER BY p.tcreatedat DESC
        """)
        result = await self._session.execute(sql)
        rows = result.fetchall()
        return [
            Person(
                n_id_person=str(row[0]) if row[0] else None,
                c_name=row[1],
                c_last_name=row[2],
                n_id_identification_type=row[3],
                c_identification_number=row[4],
                t_created_at=row[5],
                t_modified_at=row[6],
                n_birth_place_gadm=row[7],
                n_residence_place_gadm=row[8],
                role_name=row[9] or "",
            )
            for row in rows
        ]

    async def find_by_identification_number(self, identification_number: str) -> Optional[Person]:
        sql = text("""
            SELECT
                p.nidperson,
                p.cname,
                p.clastname,
                p.nididentificationtype,
                p.cidentificationnumber,
                p.tcreatedat,
                p.tmodifiedat,
                p."nBirthPlaceGadm",
                p."nResidencePlaceGadm",
                r.cname AS role_name,
                u.cphotourl,
                u.cusername,
                u.cemail
            FROM "S02PERSON" p
            LEFT JOIN "S02PERSON_ROLE" pr ON pr.nidperson = p.nidperson
            LEFT JOIN "S02ROLE" r ON r.nidrole = pr.nidrole
            LEFT JOIN "S02USER" u ON u.niduser = p.nidperson
            WHERE p.cidentificationnumber = :identification_number
        """)
        result = await self._session.execute(sql, {"identification_number": identification_number})
        row = result.fetchone()
        if not row:
            return None
        return Person(
            n_id_person=str(row[0]) if row[0] else None,
            c_name=row[1],
            c_last_name=row[2],
            n_id_identification_type=row[3],
            c_identification_number=row[4],
            t_created_at=row[5],
            t_modified_at=row[6],
            n_birth_place_gadm=row[7],
            n_residence_place_gadm=row[8],
            role_name=row[9] or "",
            c_photo_url=row[10],
            c_username=row[11],
            c_email=row[12],
        )

    async def save(self, data: Person) -> Person:
        orm = S02PersonORM(
            cName=data.c_name,
            cLastName=data.c_last_name,
            nIdIdentificationType=data.n_id_identification_type,
            cIdentificationNumber=data.c_identification_number,
        )
        self._session.add(orm)
        await self._session.flush()
        await self._session.commit()
        await self._session.refresh(orm)
        return self._to_entity(orm)

    async def save_participant(self, n_id_person: str) -> None:
        orm = S02ParticipantORM(nIdParticipant=n_id_person)
        self._session.add(orm)
        await self._session.flush()
        await self._session.commit()

    async def save_employee(self, n_id_person: str) -> None:
        orm = S02EmployeeORM(nIdEmployee=n_id_person)
        self._session.add(orm)
        await self._session.flush()
        await self._session.commit()

    async def save_superior(self, n_id_person: str) -> None:
        orm = S02SuperiorORM(
            nIdSuperior=n_id_person,
        )
        self._session.add(orm)
        await self._session.flush()
        await self._session.commit()

    async def update_participant_status(self, n_id_person: str, b_is_active: bool) -> None:
        stmt = select(S02ParticipantORM).where(S02ParticipantORM.nIdParticipant == n_id_person)
        result = await self._session.execute(stmt)
        orm = result.scalar_one_or_none()
        if orm:
            orm.bIsActive = b_is_active
            await self._session.flush()
            await self._session.commit()

    async def update_employee_status(self, n_id_person: str, b_is_active: bool) -> None:
        stmt = select(S02EmployeeORM).where(S02EmployeeORM.nIdEmployee == n_id_person)
        result = await self._session.execute(stmt)
        orm = result.scalar_one_or_none()
        if orm:
            orm.bIsActive = b_is_active
            await self._session.flush()
            await self._session.commit()

    async def update_superior_status(self, n_id_person: str, b_is_active: bool) -> None:
        stmt = select(S02SuperiorORM).where(S02SuperiorORM.nIdSuperior == n_id_person)
        result = await self._session.execute(stmt)
        orm = result.scalar_one_or_none()
        if orm:
            orm.bIsActive = b_is_active
            await self._session.flush()
            await self._session.commit()

    async def save_person_role(self, n_id_person: str, n_id_role: int) -> None:
        stmt = select(S02PersonRoleORM).where(
            S02PersonRoleORM.nIdPerson == n_id_person,
            S02PersonRoleORM.nIdRole == n_id_role,
        )
        result = await self._session.execute(stmt)
        if result.scalar_one_or_none():
            return
        orm = S02PersonRoleORM(
            nIdPerson=n_id_person,
            nIdRole=n_id_role,
        )
        self._session.add(orm)
        await self._session.flush()
        await self._session.commit()

    async def delete_person_role(self, n_id_person: str, n_id_role: int) -> None:
        stmt = select(S02PersonRoleORM).where(
            S02PersonRoleORM.nIdPerson == n_id_person,
            S02PersonRoleORM.nIdRole == n_id_role,
        )
        result = await self._session.execute(stmt)
        orm = result.scalar_one_or_none()
        if orm:
            await self._session.delete(orm)
            await self._session.flush()
            await self._session.commit()

    async def find_employee_by_id(self, n_id_person: str) -> Optional[S02EmployeeORM]:
        stmt = select(S02EmployeeORM).where(S02EmployeeORM.nIdEmployee == n_id_person)
        result = await self._session.execute(stmt)
        return result.scalar_one_or_none()

    async def find_participant_by_id(self, n_id_person: str) -> Optional[S02ParticipantORM]:
        stmt = select(S02ParticipantORM).where(S02ParticipantORM.nIdParticipant == n_id_person)
        result = await self._session.execute(stmt)
        return result.scalar_one_or_none()

    async def find_superior_by_id(self, n_id_person: str) -> Optional[S02SuperiorORM]:
        stmt = select(S02SuperiorORM).where(S02SuperiorORM.nIdSuperior == n_id_person)
        result = await self._session.execute(stmt)
        return result.scalar_one_or_none()

    async def activate_employee(self, n_id_person: str) -> None:
        orm = await self.find_employee_by_id(n_id_person)
        if orm:
            orm.bIsActive = True
        else:
            self._session.add(S02EmployeeORM(nIdEmployee=n_id_person))
        await self._session.flush()
        await self._session.commit()

    async def activate_participant(self, n_id_person: str) -> None:
        orm = await self.find_participant_by_id(n_id_person)
        if orm:
            orm.bIsActive = True
        else:
            self._session.add(S02ParticipantORM(nIdParticipant=n_id_person))
        await self._session.flush()
        await self._session.commit()

    async def activate_superior(self, n_id_person: str) -> None:
        orm = await self.find_superior_by_id(n_id_person)
        if orm:
            orm.bIsActive = True
        else:
            self._session.add(S02SuperiorORM(nIdSuperior=n_id_person))
        await self._session.flush()
        await self._session.commit()

    async def deactivate_employee(self, n_id_person: str) -> None:
        orm = await self.find_employee_by_id(n_id_person)
        if orm:
            orm.bIsActive = False
            await self._session.flush()
            await self._session.commit()

    async def deactivate_participant(self, n_id_person: str) -> None:
        orm = await self.find_participant_by_id(n_id_person)
        if orm:
            orm.bIsActive = False
            await self._session.flush()
            await self._session.commit()

    async def deactivate_superior(self, n_id_person: str) -> None:
        orm = await self.find_superior_by_id(n_id_person)
        if orm:
            orm.bIsActive = False
            await self._session.flush()
            await self._session.commit()

    async def activate_user(self, n_id_person: str) -> None:
        stmt = select(S02UserORM).where(S02UserORM.nIdUser == n_id_person)
        result = await self._session.execute(stmt)
        orm = result.scalar_one_or_none()
        if orm:
            orm.bIsActive = True
            await self._session.flush()
            await self._session.commit()

    async def deactivate_user(self, n_id_person: str) -> None:
        stmt = select(S02UserORM).where(S02UserORM.nIdUser == n_id_person)
        result = await self._session.execute(stmt)
        orm = result.scalar_one_or_none()
        if orm:
            orm.bIsActive = False
            await self._session.flush()
            await self._session.commit()

    async def update(self, data: Person) -> Person:
        sql = text("""
            UPDATE "S02PERSON" SET
                cname = :cname,
                clastname = :clastname,
                "nBirthPlaceGadm" = :birth_place,
                "nResidencePlaceGadm" = :residence_place,
                tmodifiedat = :modified_at
            WHERE cidentificationnumber = :identification_number
            RETURNING *
        """)
        result = await self._session.execute(sql, {
            "cname": data.c_name,
            "clastname": data.c_last_name,
            "birth_place": data.n_birth_place_gadm,
            "residence_place": data.n_residence_place_gadm,
            "modified_at": datetime.now(),
            "identification_number": data.c_identification_number,
        })
        await self._session.commit()
        row = result.fetchone()
        if not row:
            raise ValueError(f"Person with identification number '{data.c_identification_number}' not found")
        return Person(
            n_id_person=str(row[0]) if row[0] else None,
            c_name=row[1],
            c_last_name=row[2],
            n_id_identification_type=row[3],
            c_identification_number=row[4],
            t_created_at=row[5],
            t_modified_at=row[6],
            n_birth_place_gadm=row[7],
            n_residence_place_gadm=row[8],
        )

    async def find_role_names_by_person_id(self, n_id_person: str) -> List[str]:
        sql = text("""
            SELECT r.cname
            FROM "S02PERSON_ROLE" pr
            JOIN "S02ROLE" r ON r.nidrole = pr.nidrole
            WHERE pr.nidperson = :person_id
        """)
        result = await self._session.execute(sql, {"person_id": n_id_person})
        return [row[0] for row in result.fetchall()]

    async def find_permissions_by_person_id(self, n_id_person: str) -> List[dict]:
        stmt = (
            select(S02PermissionORM)
            .join(S02RolePermissionORM, S02RolePermissionORM.nIdPermission == S02PermissionORM.nIdPermission)
            .join(S02PersonRoleORM, S02PersonRoleORM.nIdRole == S02RolePermissionORM.nIdRole)
            .where(S02PersonRoleORM.nIdPerson == n_id_person)
            .where(S02PermissionORM.bIsActive == True)
            .distinct()
        )
        result = await self._session.execute(stmt)
        orms = result.scalars().all()
        return [
            {
                "name": p.cName,
                "code": p.cCode,
                "module": p.cModule,
                "description": p.cDescription,
            }
            for p in orms
        ]

    async def save_participant_program(self, n_id_participant: str, n_id_program: str) -> None:
        orm = S02ParticipantProgramORM(
            nIdParticipant=n_id_participant,
            nIdProgram=n_id_program,
        )
        self._session.add(orm)
        await self._session.flush()
        await self._session.commit()

    async def find_programs_by_participant_id(self, n_id_person: str) -> List[dict]:
        sql = text("""
            SELECT
                p.nidprogram, p.cname, p.cdescription, p.cstatus,
                p.tstartdate, p.tendtime,
                w.nidworkshop, w.cdescription AS workshop_description,
                w.cstatus AS workshop_status, w.tdate,
                pp.bisactive
            FROM "S02PARTICIPANT_PROGRAM" pp
            JOIN "S01PROGRAM" p ON p.nidprogram = pp.nidprogram
            LEFT JOIN "S01WORKSHOP" w ON w.nidprogram = p.nidprogram AND w.bisactive = true
            WHERE pp.nidparticipant = :person_id AND p.bisactive = true
            ORDER BY p.tstartdate, w.tdate
        """)
        result = await self._session.execute(sql, {"person_id": n_id_person})
        rows = result.fetchall()
        programs: dict = {}
        for row in rows:
            pid = str(row[0])
            if pid not in programs:
                programs[pid] = {
                    "n_id_program": pid,
                    "c_name": row[1],
                    "c_description": row[2],
                    "c_status": row[3],
                    "t_start_date": str(row[4]) if row[4] else None,
                    "t_end_time": str(row[5]) if row[5] else None,
                    "b_is_active": row[10],
                    "workshops": [],
                }
            if row[6]:
                programs[pid]["workshops"].append({
                    "n_id_workshop": str(row[6]),
                    "c_description": row[7],
                    "c_status": row[8],
                    "t_date": str(row[9]) if row[9] else None,
                })
        return list(programs.values())

    async def find_available_programs(self, n_id_person: str) -> List[dict]:
        sql = text("""
            SELECT p.nidprogram, p.cname, p.cdescription, p.cstatus,
                   p.tstartdate, p.tendtime
            FROM "S01PROGRAM" p
            WHERE p.bisactive = true
              AND p.nidprogram NOT IN (
                SELECT pp.nidprogram FROM "S02PARTICIPANT_PROGRAM" pp
                WHERE pp.nidparticipant = :person_id
              )
            ORDER BY p.tstartdate
        """)
        result = await self._session.execute(sql, {"person_id": n_id_person})
        return [
            {
                "n_id_program": str(row[0]),
                "c_name": row[1],
                "c_description": row[2],
                "c_status": row[3],
                "t_start_date": str(row[4]) if row[4] else None,
                "t_end_time": str(row[5]) if row[5] else None,
            }
            for row in result.fetchall()
        ]

    async def find_employee_programs(self, n_id_employee: str) -> List[dict]:
        sql = text("""
            SELECT
                p.nidprogram, p.cname, p.cdescription, p.cstatus,
                p.tstartdate, p.tendtime,
                CASE WHEN ep.nidemployee IS NOT NULL THEN true ELSE false END AS is_assigned
            FROM "S01PROGRAM" p
            LEFT JOIN "S02EMPLOYEE_PROGRAM" ep
                ON ep.nidprogram = p.nidprogram AND ep.nidemployee = :employee_id
            WHERE p.bisactive = true
            ORDER BY p.tstartdate
        """)
        result = await self._session.execute(sql, {"employee_id": n_id_employee})
        return [
            {
                "n_id_program": str(row[0]),
                "c_name": row[1],
                "c_description": row[2],
                "c_status": row[3],
                "t_start_date": str(row[4]) if row[4] else None,
                "t_end_time": str(row[5]) if row[5] else None,
                "is_assigned": row[6],
            }
            for row in result.fetchall()
        ]

    async def save_employee_program(self, n_id_employee: str, n_id_program: str) -> None:
        orm = S02EmployeeProgramORM(
            nIdEmployee=n_id_employee,
            nIdProgram=n_id_program,
        )
        self._session.add(orm)
        await self._session.flush()
        await self._session.commit()

    async def find_program_workshops(self, n_id_program: str) -> List[dict]:
        sql = text("""
            SELECT nidworkshop, cdescription, cstatus, tdate
            FROM "S01WORKSHOP"
            WHERE nidprogram = :program_id AND bisactive = true
            ORDER BY tdate
        """)
        result = await self._session.execute(sql, {"program_id": n_id_program})
        return [
            {
                "n_id_workshop": str(row[0]),
                "c_description": row[1],
                "c_status": row[2],
                "t_date": str(row[3]) if row[3] else None,
            }
            for row in result.fetchall()
        ]

    async def save_workshop(self, n_id_program: str, c_description: str, c_status: str | None, t_date: str | None) -> dict:
        orm = S01WorkshopORM(
            nIdProgram=n_id_program,
            cDescription=c_description,
            cStatus=c_status,
            tDate=datetime.fromisoformat(t_date) if t_date else None,
        )
        self._session.add(orm)
        await self._session.flush()
        await self._session.commit()
        await self._session.refresh(orm)
        return {
            "n_id_workshop": str(orm.nIdWorkshop),
            "n_id_program": str(orm.nIdProgram),
            "c_description": orm.cDescription,
            "c_status": orm.cStatus,
            "t_date": str(orm.tDate) if orm.tDate else None,
        }

    async def update_workshop_status(self, n_id_workshop: str, c_status: str) -> dict | None:
        stmt = select(S01WorkshopORM).where(S01WorkshopORM.nIdWorkshop == n_id_workshop)
        result = await self._session.execute(stmt)
        orm = result.scalar_one_or_none()
        if not orm:
            return None
        orm.cStatus = c_status
        await self._session.flush()
        await self._session.commit()
        return {
            "n_id_workshop": str(orm.nIdWorkshop),
            "c_status": orm.cStatus,
        }

    async def find_by_role_names(self, role_names: List[str]) -> List[dict]:
        subq = (
            select(S02PersonRoleORM.nIdPerson)
            .join(S02RoleORM, S02RoleORM.nIdRole == S02PersonRoleORM.nIdRole)
            .where(S02RoleORM.cName.in_(role_names))
        )
        stmt = (
            select(
                S02PersonORM,
                S02UserORM,
                S02EmployeeORM.bIsActive,
                S02ParticipantORM.bIsActive,
                S02SuperiorORM.bIsActive,
            )
            .select_from(S02PersonORM)
            .outerjoin(S02UserORM, S02UserORM.nIdUser == S02PersonORM.nIdPerson)
            .outerjoin(S02EmployeeORM, S02EmployeeORM.nIdEmployee == S02UserORM.nIdUser)
            .outerjoin(S02ParticipantORM, S02ParticipantORM.nIdParticipant == S02UserORM.nIdUser)
            .outerjoin(S02SuperiorORM, S02SuperiorORM.nIdSuperior == S02UserORM.nIdUser)
            .where(S02PersonORM.nIdPerson.in_(subq))
            .order_by(S02PersonORM.cName, S02PersonORM.cLastName)
        )
        result = await self._session.execute(stmt)
        rows = result.fetchall()
        person_ids = [str(row[0].nIdPerson) for row in rows]
        roles_map = {}
        if person_ids:
            roles_stmt = (
                select(S02PersonRoleORM.nIdPerson, S02RoleORM.cName)
                .join(S02RoleORM, S02RoleORM.nIdRole == S02PersonRoleORM.nIdRole)
                .where(S02PersonRoleORM.nIdPerson.in_(person_ids))
            )
            roles_result = await self._session.execute(roles_stmt)
            for pid, rname in roles_result:
                roles_map.setdefault(str(pid), []).append(rname)
        return [
            {
                "id": str(row[0].nIdPerson),
                "name": row[0].cName,
                "last_name": row[0].cLastName,
                "identification_number": row[0].cIdentificationNumber,
                "id_identification_type": row[0].nIdIdentificationType,
                "birth_place_gadm": row[0].nBirthPlaceGadm,
                "residence_place_gadm": row[0].nResidencePlaceGadm,
                "created_at": str(row[0].tCreatedAt) if row[0].tCreatedAt else None,
                "modified_at": str(row[0].tModifiedAt) if row[0].tModifiedAt else None,
                "is_registered": row[1] is not None,
                "email": row[1].cEmail if row[1] else None,
                "username": row[1].cUsername if row[1] else None,
                "wallet": row[1].cWallet if row[1] else None,
                "phrase": row[1].cPhrase if row[1] else None,
                "provider_id": row[1].cProviderId if row[1] else None,
                "is_active": row[1].bIsActive if row[1] else None,
                "photo_url": row[1].cPhotoUrl if row[1] else None,
                "latest_access": str(row[1].tLatestAccess) if row[1] and row[1].tLatestAccess else None,
                "user_created_at": str(row[1].tCreatedAt) if row[1] and row[1].tCreatedAt else None,
                "email_verified": row[1].bEmailVerified if row[1] else None,
                "employee_active": row[2],
                "participant_active": row[3],
                "superior_active": row[4],
                "roles": roles_map.get(str(row[0].nIdPerson), []),
            }
            for row in rows
        ]

    async def find_participants_by_program(self, program_id: str) -> List[dict]:
        sql = text("""
            SELECT
                pp.nidparticipant,
                p.nidperson,
                p.cname,
                p.clastname,
                p.cidentificationnumber,
                u.cemail,
                u.cusername,
                u.cphotourl,
                pp.bisactive
            FROM "S02PARTICIPANT_PROGRAM" pp
            JOIN "S02PARTICIPANT" pt ON pt.nidparticipant = pp.nidparticipant
            JOIN "S02USER" u ON u.niduser = pt.nidparticipant
            JOIN "S02PERSON" p ON p.nidperson = u.niduser
            WHERE pp.nidprogram = :program_id
            ORDER BY p.cname, p.clastname
        """)
        result = await self._session.execute(sql, {"program_id": program_id})
        return [
            {
                "n_id_participant": str(row[0]),
                "n_id_person": str(row[1]),
                "c_name": row[2],
                "c_last_name": row[3],
                "c_identification_number": row[4],
                "c_email": row[5],
                "c_username": row[6],
                "c_photo_url": row[7],
                "b_is_active": row[8],
            }
            for row in result.fetchall()
        ]

    async def deactivate_participant_program(self, n_id_participant: str, n_id_program: str) -> None:
        stmt = select(S02ParticipantProgramORM).where(
            S02ParticipantProgramORM.nIdParticipant == n_id_participant,
            S02ParticipantProgramORM.nIdProgram == n_id_program,
        )
        result = await self._session.execute(stmt)
        orm = result.scalar_one_or_none()
        if orm:
            orm.bIsActive = False
            await self._session.flush()
            await self._session.commit()

    async def activate_participant_program(self, n_id_participant: str, n_id_program: str) -> None:
        stmt = select(S02ParticipantProgramORM).where(
            S02ParticipantProgramORM.nIdParticipant == n_id_participant,
            S02ParticipantProgramORM.nIdProgram == n_id_program,
        )
        result = await self._session.execute(stmt)
        orm = result.scalar_one_or_none()
        if orm:
            orm.bIsActive = True
            await self._session.flush()
            await self._session.commit()

    def _to_entity(self, orm: S02PersonORM) -> Person:
        return Person(
            n_id_person=str(orm.nIdPerson) if orm.nIdPerson else None,
            c_name=orm.cName,
            c_last_name=orm.cLastName,
            n_id_identification_type=orm.nIdIdentificationType,
            c_identification_number=orm.cIdentificationNumber,
            n_birth_place_gadm=orm.nBirthPlaceGadm,
            n_residence_place_gadm=orm.nResidencePlaceGadm,
            t_created_at=orm.tCreatedAt,
            t_modified_at=orm.tModifiedAt,
        )
