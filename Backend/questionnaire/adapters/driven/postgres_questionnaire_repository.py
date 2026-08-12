from typing import List, Optional
from sqlalchemy import text, Column, String, Boolean, Integer, select, func, and_, null
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.ext.asyncio import AsyncSession
from questionnaire.ports.driven.questionnaire_repository_port import QuestionnaireRepositoryPort
from questionnaire.domain.entities.questionnaire import (
    WorkshopQuestionnaire, QuestionnaireGroup, Question, AnswerLog, NewQuestion, NewMetric, Metric,
    ParticipantMetricEntry, WorkshopMetric,
)
from questionnaire.domain.rules.questionnaire_rules import get_type_config
from person.adapters.driven.postgres_person_repository import S01WorkshopORM
from db.base import Base


class S03QuestionnaireGroupORM(Base):
    __tablename__ = "S03QUESTIONNAIRE_GROUP"

    nIdQuestionnaireGroup = Column("nidquestionnairegroup", UUID, primary_key=True)
    cName = Column("cname", String(200), nullable=False)
    cDescription = Column("cdescription", String(500))
    bIsActive = Column("bisactive", Boolean, default=True)


class S03QuestionnaireORM(Base):
    __tablename__ = "S03QUESTIONNAIRE"

    nIdQuestionnaire = Column("nidquestionnaire", UUID, primary_key=True)
    nIdQuestionnaireGroup = Column("nidquestionnairegroup", UUID)
    cQuestion = Column("cquestion", String)
    nIdQuestionnaireType = Column("nidquestionnairetype", Integer)
    jAlternatives = Column("jalternatives")
    bIsPre = Column("bispre", Boolean)
    bIsPost = Column("bispost", Boolean)
    bIsActive = Column("bisactive", Boolean, default=True)


class S03QuestionnaireTypeORM(Base):
    __tablename__ = "S03QUESTIONNAIRE_TYPE"

    nIdQuestionnaireType = Column("nidquestionnairetype", Integer, primary_key=True)
    cName = Column("cname", String)


class S03MetricORM(Base):
    __tablename__ = "S03METRIC"

    nIdMetric = Column("nidmetric", UUID, primary_key=True)
    nIdQuestionnaireGroup = Column("nidquestionnairegroup", UUID)
    cName = Column("cname", String)
    cDescription = Column("cdescription", String)
    cDataType = Column("cdatatype", String)
    bIsActive = Column("bisactive", Boolean, default=True)


class S03MetricWorkshopORM(Base):
    __tablename__ = "S03METRIC_WORKSHOP"

    nIdMetricWorkshop = Column("nidmetricworkshop", UUID, primary_key=True)
    nIdMetric = Column("nidmetric", UUID)
    nIdWorkshop = Column("nidworkshop", UUID)


class S01ChallengeORM(Base):
    __tablename__ = "S01CHALLENGE"

    nIdChallenge = Column("nidchallenge", UUID, primary_key=True)
    cName = Column("cname", String(30))
    cDescription = Column("cdescription")


class S01WorkshopChallengeORM(Base):
    __tablename__ = "S01WORKSHOP_CHALLENGE"

    nIdWorkshop = Column("nidworkshop", UUID, primary_key=True)
    nIdChallenge = Column("nidchallenge", UUID, primary_key=True)


class PostgresQuestionnaireRepository(QuestionnaireRepositoryPort):
    def __init__(self, session: AsyncSession):
        self._session = session

    async def find_workshops_with_questionnaires(
        self, program_id: str
    ) -> List[WorkshopQuestionnaire]:
        sql = text("""
            WITH group_types AS (
                SELECT
                    q.nidquestionnairegroup,
                    bool_or(q.bispre) AS has_pre,
                    bool_or(q.bispost) AS has_post,
                    bool_or(NOT q.bispre AND NOT q.bispost) AS has_mid
                FROM "S03QUESTIONNAIRE" q
                WHERE q.bisactive = true
                GROUP BY q.nidquestionnairegroup
            )
            SELECT
                w.nidworkshop,
                w.cdescription,
                w.cstatus,
                w.tdate,
                mw.nidmetricworkshop,
                m.nidmetric,
                m.cname AS metric_name,
                m.cdescription AS metric_description,
                m.cdatatype AS metric_data_type,
                qg.nidquestionnairegroup,
                qg.cname AS group_name,
                qg.cdescription AS group_description,
                COALESCE(gt.has_pre, false) AS has_pre,
                COALESCE(gt.has_post, false) AS has_post,
                COALESCE(gt.has_mid, false) AS has_mid
            FROM "S01WORKSHOP" w
            LEFT JOIN "S03METRIC_WORKSHOP" mw ON mw.nidworkshop = w.nidworkshop
            LEFT JOIN "S03METRIC" m ON m.nidmetric = mw.nidmetric AND m.bisactive = true
            LEFT JOIN "S03QUESTIONNAIRE_GROUP" qg ON qg.nidquestionnairegroup = m.nidquestionnairegroup AND qg.bisactive = true
            LEFT JOIN group_types gt ON gt.nidquestionnairegroup = qg.nidquestionnairegroup
            WHERE w.nidprogram = :program_id
              AND w.bisactive = true
              AND w.cstatus IN ('SCHEDULED', 'ONGOING', 'ENDED')
            ORDER BY w.tdate, qg.cname
        """)
        result = await self._session.execute(sql, {"program_id": program_id})
        rows = result.fetchall()

        workshops_map: dict = {}
        for row in rows:
            wid = str(row[0])
            if wid not in workshops_map:
                workshops_map[wid] = WorkshopQuestionnaire(
                    n_id_workshop=wid,
                    c_description=row[1],
                    c_status=row[2],
                    t_date=str(row[3]) if row[3] else None,
                    questionnaire_groups=[],
                )

            if row[9]:
                types = []
                if row[12]:
                    types.append("pre")
                if row[13]:
                    types.append("post")
                if row[14]:
                    types.append("mid")
                group = QuestionnaireGroup(
                    n_id_questionnaire_group=str(row[9]),
                    c_name=row[10],
                    c_description=row[11],
                    n_id_metric=str(row[5]),
                    c_metric_name=row[6],
                    c_metric_description=row[7],
                    c_metric_data_type=row[8],
                    n_id_metric_workshop=str(row[4]),
                    available_types=types,
                )
                workshops_map[wid].questionnaire_groups.append(group)

        return list(workshops_map.values())

    async def find_questions_by_group_and_type(
        self, group_id: str, c_type: str
    ) -> List[Question]:
        if c_type == "pre":
            sql = text("""
                SELECT
                    q.nidquestionnaire, q.cquestion, q.nidquestionnairetype,
                    qt.cname AS type_name, q.jalternatives::text,
                    q.bispre, q.bispost
                FROM "S03QUESTIONNAIRE" q
                JOIN "S03QUESTIONNAIRE_TYPE" qt ON qt.nidquestionnairetype = q.nidquestionnairetype
                WHERE q.nidquestionnairegroup = :group_id
                  AND q.bisactive = true
                  AND q.bispre = true AND q.bispost = false
                ORDER BY q.nidquestionnaire
            """)
        elif c_type == "post":
            sql = text("""
                SELECT
                    q.nidquestionnaire, q.cquestion, q.nidquestionnairetype,
                    qt.cname AS type_name, q.jalternatives::text,
                    q.bispre, q.bispost
                FROM "S03QUESTIONNAIRE" q
                JOIN "S03QUESTIONNAIRE_TYPE" qt ON qt.nidquestionnairetype = q.nidquestionnairetype
                WHERE q.nidquestionnairegroup = :group_id
                  AND q.bisactive = true
                  AND q.bispre = false AND q.bispost = true
                ORDER BY q.nidquestionnaire
            """)
        else:
            sql = text("""
                SELECT
                    q.nidquestionnaire, q.cquestion, q.nidquestionnairetype,
                    qt.cname AS type_name, q.jalternatives::text,
                    q.bispre, q.bispost
                FROM "S03QUESTIONNAIRE" q
                JOIN "S03QUESTIONNAIRE_TYPE" qt ON qt.nidquestionnairetype = q.nidquestionnairetype
                WHERE q.nidquestionnairegroup = :group_id
                  AND q.bisactive = true
                  AND q.bispre = false AND q.bispost = false
                ORDER BY q.nidquestionnaire
            """)
        result = await self._session.execute(sql, {"group_id": group_id})
        result = await self._session.execute(sql, {"group_id": group_id})
        return [
            Question(
                n_id_questionnaire=str(row[0]),
                c_question=row[1],
                n_id_questionnaire_type=row[2],
                c_type_name=row[3],
                j_alternatives=row[4] or "[]",
                b_is_pre=row[5],
                b_is_post=row[6],
            )
            for row in result.fetchall()
        ]

    async def save_answer(self, data: AnswerLog) -> None:
        sql = text("""
            INSERT INTO "S03METRIC_LOG" (nidmetricworkshop, nidparticipant, cvalue)
            VALUES (:metric_workshop, :participant, :value)
        """)
        await self._session.execute(sql, {
            "metric_workshop": data.n_id_metric_workshop,
            "participant": data.n_id_participant,
            "value": data.c_value,
        })
        await self._session.commit()

    async def save_answers_batch(self, items: List[AnswerLog]) -> None:
        if not items:
            return
        import json
        values = [
            {
                "nidmetricworkshop": item.n_id_metric_workshop,
                "nidparticipant": item.n_id_participant,
                "cvalue": item.c_value,
            }
            for item in items
        ]
        for item in items:
            await self._session.execute(
                text("""
                    INSERT INTO "S03METRIC_LOG" (nidmetricworkshop, nidparticipant, cvalue)
                    VALUES (:metric_workshop, :participant, :value)
                """),
                {
                    "metric_workshop": item.n_id_metric_workshop,
                    "participant": item.n_id_participant,
                    "value": item.c_value,
                },
            )
        await self._session.commit()

    async def create_questionnaire_group(
        self, c_name: str, c_description: Optional[str] = None
    ) -> str:
        import uuid
        orm = S03QuestionnaireGroupORM(
            nIdQuestionnaireGroup=str(uuid.uuid4()),
            cName=c_name,
            cDescription=c_description,
            bIsActive=True,
        )
        self._session.add(orm)
        await self._session.flush()
        await self._session.commit()
        return str(orm.nIdQuestionnaireGroup)

    async def find_all_questionnaire_groups(
        self, program_id: Optional[str] = None, workshop_id: Optional[str] = None
    ) -> List[QuestionnaireGroup]:
        if program_id:
            stmt = (
                select(
                    S03QuestionnaireGroupORM.nIdQuestionnaireGroup,
                    S03QuestionnaireGroupORM.cName,
                    S03QuestionnaireGroupORM.cDescription,
                    S03MetricORM.nIdMetric,
                    S03MetricORM.cName.label("metric_name"),
                    S03MetricWorkshopORM.nIdMetricWorkshop,
                    func.bool_or(S03QuestionnaireORM.bIsPre).label("has_pre"),
                    func.bool_or(S03QuestionnaireORM.bIsPost).label("has_post"),
                    func.bool_or(and_(~S03QuestionnaireORM.bIsPre, ~S03QuestionnaireORM.bIsPost)).label("has_mid"),
                )
                .select_from(S01WorkshopORM)
                .join(S03MetricWorkshopORM, S03MetricWorkshopORM.nIdWorkshop == S01WorkshopORM.nIdWorkshop)
                .join(S03MetricORM, and_(S03MetricORM.nIdMetric == S03MetricWorkshopORM.nIdMetric, S03MetricORM.bIsActive == True))
                .join(S03QuestionnaireGroupORM, and_(S03QuestionnaireGroupORM.nIdQuestionnaireGroup == S03MetricORM.nIdQuestionnaireGroup, S03QuestionnaireGroupORM.bIsActive == True))
                .outerjoin(S03QuestionnaireORM, and_(S03QuestionnaireORM.nIdQuestionnaireGroup == S03QuestionnaireGroupORM.nIdQuestionnaireGroup, S03QuestionnaireORM.bIsActive == True))
                .where(S01WorkshopORM.nIdProgram == program_id, S01WorkshopORM.bIsActive == True)
                .where(S01WorkshopORM.cStatus.in_(["SCHEDULED", "ONGOING", "ENDED"]))
                .group_by(
                    S03QuestionnaireGroupORM.nIdQuestionnaireGroup,
                    S03QuestionnaireGroupORM.cName,
                    S03QuestionnaireGroupORM.cDescription,
                    S03MetricORM.nIdMetric,
                    S03MetricORM.cName,
                    S03MetricWorkshopORM.nIdMetricWorkshop,
                )
                .order_by(S03QuestionnaireGroupORM.cName)
            )
            if workshop_id:
                stmt = stmt.where(S01WorkshopORM.nIdWorkshop == workshop_id)
            result = await self._session.execute(stmt)
        else:
            stmt = (
                select(
                    S03QuestionnaireGroupORM.nIdQuestionnaireGroup,
                    S03QuestionnaireGroupORM.cName,
                    S03QuestionnaireGroupORM.cDescription,
                    null().label("nidmetric"),
                    null().label("metric_name"),
                    null().label("nidmetricworkshop"),
                    func.bool_or(S03QuestionnaireORM.bIsPre).label("has_pre"),
                    func.bool_or(S03QuestionnaireORM.bIsPost).label("has_post"),
                    func.bool_or(and_(~S03QuestionnaireORM.bIsPre, ~S03QuestionnaireORM.bIsPost)).label("has_mid"),
                )
                .select_from(S03QuestionnaireGroupORM)
                .outerjoin(S03QuestionnaireORM, and_(S03QuestionnaireORM.nIdQuestionnaireGroup == S03QuestionnaireGroupORM.nIdQuestionnaireGroup, S03QuestionnaireORM.bIsActive == True))
                .where(S03QuestionnaireGroupORM.bIsActive == True)
                .group_by(
                    S03QuestionnaireGroupORM.nIdQuestionnaireGroup,
                    S03QuestionnaireGroupORM.cName,
                    S03QuestionnaireGroupORM.cDescription,
                )
                .order_by(S03QuestionnaireGroupORM.cName)
            )
            result = await self._session.execute(stmt)
        return [
            QuestionnaireGroup(
                n_id_questionnaire_group=str(row[0]),
                c_name=row[1],
                c_description=row[2],
                n_id_metric=str(row[3]) if row[3] else None,
                c_metric_name=row[4],
                n_id_metric_workshop=str(row[5]) if row[5] else None,
                available_types=[
                    t for t, flag in [("pre", row[6]), ("post", row[7]), ("mid", row[8])] if flag
                ],
            )
            for row in result.fetchall()
        ]

    async def create_question(self, data: NewQuestion) -> str:
        import uuid
        config = get_type_config(data.n_id_questionnaire_type)
        alternatives = data.j_alternatives if config and config.has_options else "[]"
        orm = S03QuestionnaireORM(
            nIdQuestionnaire=str(uuid.uuid4()),
            nIdQuestionnaireGroup=data.n_id_questionnaire_group,
            cQuestion=data.c_question,
            nIdQuestionnaireType=data.n_id_questionnaire_type,
            jAlternatives=alternatives,
            bIsPre=data.b_is_pre,
            bIsPost=data.b_is_post,
            bIsActive=True,
        )
        self._session.add(orm)
        await self._session.flush()
        await self._session.commit()
        return str(orm.nIdQuestionnaire)

    async def create_metric(self, data: NewMetric) -> str:
        import uuid
        metric_id = str(uuid.uuid4())
        orm = S03MetricORM(
            nIdMetric=metric_id,
            cName=data.c_name,
            cDescription=data.c_description,
            cDataType=data.c_data_type,
            nIdQuestionnaireGroup=data.n_id_questionnaire_group,
            bIsActive=data.b_is_active,
        )
        self._session.add(orm)

        if data.n_id_workshop:
            mw_orm = S03MetricWorkshopORM(
                nIdMetricWorkshop=str(uuid.uuid4()),
                nIdMetric=metric_id,
                nIdWorkshop=data.n_id_workshop,
            )
            self._session.add(mw_orm)

        await self._session.flush()
        await self._session.commit()
        return metric_id

    async def assign_metric_to_workshop(self, metric_id: str, workshop_id: str) -> str:
        import uuid
        existing = await self._session.execute(
            select(S03MetricWorkshopORM).where(
                S03MetricWorkshopORM.nIdMetric == metric_id,
                S03MetricWorkshopORM.nIdWorkshop == workshop_id,
            )
        )
        if existing.scalar_one_or_none():
            return "ALREADY_EXISTS"
        mw_id = str(uuid.uuid4())
        orm = S03MetricWorkshopORM(
            nIdMetricWorkshop=mw_id,
            nIdMetric=metric_id,
            nIdWorkshop=workshop_id,
        )
        self._session.add(orm)
        await self._session.flush()
        await self._session.commit()
        return mw_id

    async def find_workshop_metric_ids(self, workshop_id: str) -> List[str]:
        stmt = select(S03MetricWorkshopORM.nIdMetric).where(
            S03MetricWorkshopORM.nIdWorkshop == workshop_id
        )
        result = await self._session.execute(stmt)
        return [str(row[0]) for row in result.fetchall()]

    async def find_workshop_challenges(self, workshop_id: str) -> List[dict]:
        sql = text("""
            SELECT c.nidchallenge, c.cname, c.cdescription
            FROM "S01CHALLENGE" c
            JOIN "S01WORKSHOP_CHALLENGE" wc ON wc.nidchallenge = c.nidchallenge
            WHERE wc.nidworkshop = :workshop_id
            ORDER BY c.cname
        """)
        result = await self._session.execute(sql, {"workshop_id": workshop_id})
        return [
            {
                "n_id_challenge": str(row[0]),
                "c_name": row[1],
                "c_description": row[2],
            }
            for row in result.fetchall()
        ]

    async def create_challenge(self, c_name: str, c_description: Optional[str] = None) -> str:
        import uuid
        challenge_id = str(uuid.uuid4())
        orm = S01ChallengeORM(
            nIdChallenge=challenge_id,
            cName=c_name,
            cDescription=c_description,
        )
        self._session.add(orm)
        await self._session.flush()
        await self._session.commit()
        return challenge_id

    async def assign_challenge_to_workshop(self, challenge_id: str, workshop_id: str) -> str:
        import uuid
        existing = await self._session.execute(
            select(S01WorkshopChallengeORM).where(
                S01WorkshopChallengeORM.nIdChallenge == challenge_id,
                S01WorkshopChallengeORM.nIdWorkshop == workshop_id,
            )
        )
        if existing.scalar_one_or_none():
            return "ALREADY_EXISTS"
        orm = S01WorkshopChallengeORM(
            nIdWorkshop=workshop_id,
            nIdChallenge=challenge_id,
        )
        self._session.add(orm)
        await self._session.flush()
        await self._session.commit()
        return challenge_id

    async def find_all_challenges(self) -> List[dict]:
        sql = text("""
            SELECT nidchallenge, cname, cdescription
            FROM "S01CHALLENGE"
            ORDER BY cname
        """)
        result = await self._session.execute(sql)
        return [
            {
                "n_id_challenge": str(row[0]),
                "c_name": row[1],
                "c_description": row[2],
            }
            for row in result.fetchall()
        ]

    async def find_workshop_challenge_ids(self, workshop_id: str) -> List[str]:
        stmt = select(S01WorkshopChallengeORM.nIdChallenge).where(
            S01WorkshopChallengeORM.nIdWorkshop == workshop_id
        )
        result = await self._session.execute(stmt)
        return [str(row[0]) for row in result.fetchall()]

    async def find_workshop_metrics(self, workshop_id: str) -> List[WorkshopMetric]:
        sql = text("""
            SELECT
                mw.nidmetricworkshop,
                m.nidmetric,
                m.cname,
                m.cdescription,
                m.cdatatype
            FROM "S03METRIC_WORKSHOP" mw
            JOIN "S03METRIC" m ON m.nidmetric = mw.nidmetric AND m.bisactive = true
            WHERE mw.nidworkshop = :workshop_id
              AND m.cdatatype ILIKE 'integer'
            ORDER BY m.cname
        """)
        result = await self._session.execute(sql, {"workshop_id": workshop_id})
        return [
            WorkshopMetric(
                n_id_metric_workshop=str(row[0]),
                n_id_metric=str(row[1]),
                c_name=row[2],
                c_description=row[3],
                c_data_type=row[4],
            )
            for row in result.fetchall()
        ]

    async def find_all_metrics(self) -> List[Metric]:
        stmt = select(S03MetricORM).where(S03MetricORM.bIsActive == True)
        result = await self._session.execute(stmt)
        rows = result.scalars().all()
        return [
            Metric(
                n_id_metric=str(r.nIdMetric),
                c_name=r.cName,
                c_description=r.cDescription,
                c_data_type=r.cDataType,
                n_id_questionnaire_group=str(r.nIdQuestionnaireGroup) if r.nIdQuestionnaireGroup else None,
                b_is_active=r.bIsActive,
            )
            for r in rows
        ]

    async def find_participant_metrics(
        self, participant_id: str, workshop_id: str
    ) -> List[ParticipantMetricEntry]:
        sql = text("""
            SELECT
                mw.nidmetricworkshop,
                ml.cvalue,
                m.cname AS metric_name,
                m.cdatatype AS metric_data_type,
                ml.tdate::text
            FROM "S03METRIC_LOG" ml
            JOIN "S03METRIC_WORKSHOP" mw ON mw.nidmetricworkshop = ml.nidmetricworkshop
            JOIN "S03METRIC" m ON m.nidmetric = mw.nidmetric AND m.bisactive = true
            WHERE mw.nidworkshop = :workshop_id
              AND ml.nidparticipant = :participant_id
            ORDER BY m.cname, ml.tdate
        """)
        result = await self._session.execute(sql, {
            "workshop_id": workshop_id,
            "participant_id": participant_id,
        })
        return [
            ParticipantMetricEntry(
                n_id_metric_workshop=str(row[0]),
                c_value=row[1] or "",
                metric_name=row[2] or "",
                metric_data_type=row[3],
                t_date=row[4],
            )
            for row in result.fetchall()
        ]
