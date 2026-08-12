import strawberry
import json
from typing import List
from questionnaire.domain.services.questionnaire_service import QuestionnaireService
from questionnaire.adapters.driven.postgres_questionnaire_repository import PostgresQuestionnaireRepository
from questionnaire.domain.entities.questionnaire import AnswerLog, NewQuestion, NewMetric
from questionnaire.domain.rules.questionnaire_rules import get_type_config, QUESTIONNAIRE_TYPE_RULES
from db.config import AsyncSessionLocal


@strawberry.type
class QuestionAlternativeType:
    valor: int
    etiqueta: str


@strawberry.type
class QuestionnaireTypeInfo:
    n_id_questionnaire_type: int
    c_name: str


@strawberry.type
class QuestionType:
    n_id_questionnaire: str
    c_question: str
    n_id_questionnaire_type: int
    c_type_name: str
    j_alternatives: str
    alternatives: List[QuestionAlternativeType] | None = None
    b_is_pre: bool
    b_is_post: bool


@strawberry.type
class QuestionnaireGroupType:
    n_id_questionnaire_group: str
    c_name: str
    c_description: str | None = None
    n_id_metric: str
    c_metric_name: str
    c_metric_description: str | None = None
    c_metric_data_type: str | None = None
    n_id_metric_workshop: str
    available_types: List[str] | None = None


@strawberry.type
class WorkshopQuestionnaireType:
    n_id_workshop: str
    c_description: str | None = None
    c_status: str | None = None
    t_date: str | None = None
    questionnaire_groups: List[QuestionnaireGroupType] | None = None


@strawberry.type
class WorkshopChallengeType:
    n_id_challenge: str
    c_name: str | None = None
    c_description: str | None = None


@strawberry.type
class MetricType:
    n_id_metric: str
    c_name: str
    c_description: str | None = None
    c_data_type: str | None = None
    n_id_questionnaire_group: str | None = None
    b_is_active: bool = True


@strawberry.input
class SaveAnswerInput:
    n_id_metric_workshop: str
    n_id_participant: str
    c_value: str


@strawberry.input
class SaveAnswersBatchInput:
    items: List[SaveAnswerInput]


@strawberry.input
class AssignMetricToWorkshopInput:
    n_id_metric: str
    n_id_workshop: str


@strawberry.input
class CreateChallengeInput:
    c_name: str
    c_description: str | None = None


@strawberry.input
class AssignChallengeToWorkshopInput:
    n_id_challenge: str
    n_id_workshop: str


@strawberry.input
class CreateMetricInput:
    c_name: str
    c_description: str | None = None
    c_data_type: str | None = None
    n_id_questionnaire_group: str | None = None
    n_id_workshop: str | None = None
    b_is_active: bool = True


@strawberry.type
class ParticipantMetricEntryType:
    n_id_metric_workshop: str
    c_value: str
    metric_name: str
    metric_data_type: str | None = None
    n_id_questionnaire: str | None = None
    c_question: str | None = None
    j_alternatives: str | None = None
    questionnaire_type_name: str | None = None
    t_date: str | None = None


@strawberry.type
class WorkshopMetricType:
    n_id_metric_workshop: str
    n_id_metric: str
    c_name: str
    c_description: str | None = None
    c_data_type: str | None = None


@strawberry.type
class Query:
    @strawberry.field
    async def workshop_questionnaires(self, program_id: str) -> List[WorkshopQuestionnaireType]:
        async with AsyncSessionLocal() as session:
            repo = PostgresQuestionnaireRepository(session)
            service = QuestionnaireService(repo)
            items = await service.get_workshops_with_questionnaires(program_id)
            return [
                WorkshopQuestionnaireType(
                    n_id_workshop=w.n_id_workshop,
                    c_description=w.c_description,
                    c_status=w.c_status,
                    t_date=w.t_date,
                    questionnaire_groups=[
                        QuestionnaireGroupType(
                            n_id_questionnaire_group=g.n_id_questionnaire_group,
                            c_name=g.c_name,
                            c_description=g.c_description,
                            n_id_metric=g.n_id_metric,
                            c_metric_name=g.c_metric_name,
                            c_metric_description=g.c_metric_description,
                            c_metric_data_type=g.c_metric_data_type,
                            n_id_metric_workshop=g.n_id_metric_workshop,
                            available_types=g.available_types,
                        )
                        for g in (w.questionnaire_groups or [])
                    ] if w.questionnaire_groups else None,
                )
                for w in items
            ]

    @strawberry.field
    async def questionnaire_types(self) -> List[QuestionnaireTypeInfo]:
        return [
            QuestionnaireTypeInfo(n_id_questionnaire_type=t.nidquestionnairetype, c_name=t.cname)
            for t in QUESTIONNAIRE_TYPE_RULES.values()
        ]

    @strawberry.field
    async def all_questionnaire_groups(
        self, program_id: str | None = None, workshop_id: str | None = None
    ) -> List[QuestionnaireGroupType]:
        async with AsyncSessionLocal() as session:
            repo = PostgresQuestionnaireRepository(session)
            service = QuestionnaireService(repo)
            items = await service.get_all_questionnaire_groups(program_id, workshop_id)
            return [
                QuestionnaireGroupType(
                    n_id_questionnaire_group=g.n_id_questionnaire_group,
                    c_name=g.c_name,
                    c_description=g.c_description,
                    n_id_metric=g.n_id_metric or "",
                    c_metric_name=g.c_metric_name or "",
                    c_metric_description=g.c_metric_description,
                    c_metric_data_type=g.c_metric_data_type,
                    n_id_metric_workshop=g.n_id_metric_workshop or "",
                    available_types=g.available_types,
                )
                for g in items
            ]

    @strawberry.field
    async def questionnaire_questions(
        self, questionnaire_group_id: str, c_type: str
    ) -> List[QuestionType]:
        async with AsyncSessionLocal() as session:
            repo = PostgresQuestionnaireRepository(session)
            service = QuestionnaireService(repo)
            items = await service.get_questions_by_group_and_type(questionnaire_group_id, c_type)
            result: List[QuestionType] = []
            for q in items:
                alts = None
                if q.j_alternatives and q.j_alternatives != "[]":
                    try:
                        raw = json.loads(q.j_alternatives)
                        alts = [
                            QuestionAlternativeType(valor=a.get("valor", 0), etiqueta=a.get("etiqueta", ""))
                            for a in raw
                        ]
                    except (json.JSONDecodeError, TypeError):
                        alts = None

                result.append(QuestionType(
                    n_id_questionnaire=q.n_id_questionnaire,
                    c_question=q.c_question,
                    n_id_questionnaire_type=q.n_id_questionnaire_type,
                    c_type_name=q.c_type_name,
                    j_alternatives=q.j_alternatives,
                    alternatives=alts,
                    b_is_pre=q.b_is_pre,
                    b_is_post=q.b_is_post,
                ))
            return result

    @strawberry.field
    async def workshop_challenges(self, workshop_id: str) -> List[WorkshopChallengeType]:
        async with AsyncSessionLocal() as session:
            repo = PostgresQuestionnaireRepository(session)
            service = QuestionnaireService(repo)
            items = await service.get_workshop_challenges(workshop_id)
            return [
                WorkshopChallengeType(
                    n_id_challenge=item["n_id_challenge"],
                    c_name=item["c_name"],
                    c_description=item["c_description"],
                )
                for item in items
            ]

    @strawberry.field
    async def workshop_metric_ids(self, workshop_id: str) -> List[str]:
        async with AsyncSessionLocal() as session:
            repo = PostgresQuestionnaireRepository(session)
            service = QuestionnaireService(repo)
            return await service.get_workshop_metric_ids(workshop_id)

    @strawberry.field
    async def all_challenges(self) -> List[WorkshopChallengeType]:
        async with AsyncSessionLocal() as session:
            repo = PostgresQuestionnaireRepository(session)
            service = QuestionnaireService(repo)
            items = await service.get_all_challenges()
            return [
                WorkshopChallengeType(
                    n_id_challenge=item["n_id_challenge"],
                    c_name=item["c_name"],
                    c_description=item["c_description"],
                )
                for item in items
            ]

    @strawberry.field
    async def workshop_challenge_ids(self, workshop_id: str) -> List[str]:
        async with AsyncSessionLocal() as session:
            repo = PostgresQuestionnaireRepository(session)
            service = QuestionnaireService(repo)
            return await service.get_workshop_challenge_ids(workshop_id)

    @strawberry.field
    async def participant_metrics(
        self, participant_id: str, workshop_id: str
    ) -> List[ParticipantMetricEntryType]:
        async with AsyncSessionLocal() as session:
            repo = PostgresQuestionnaireRepository(session)
            service = QuestionnaireService(repo)
            items = await service.get_participant_metrics(participant_id, workshop_id)
            return [
                ParticipantMetricEntryType(
                    n_id_metric_workshop=e.n_id_metric_workshop,
                    c_value=e.c_value,
                    metric_name=e.metric_name,
                    metric_data_type=e.metric_data_type,
                    n_id_questionnaire=e.n_id_questionnaire,
                    c_question=e.c_question,
                    j_alternatives=e.j_alternatives,
                    questionnaire_type_name=e.questionnaire_type_name,
                    t_date=e.t_date,
                )
                for e in items
            ]

    @strawberry.field
    async def metrics(self) -> List[MetricType]:
        async with AsyncSessionLocal() as session:
            repo = PostgresQuestionnaireRepository(session)
            service = QuestionnaireService(repo)
            items = await service.get_all_metrics()
            return [
                MetricType(
                    n_id_metric=m.n_id_metric,
                    c_name=m.c_name,
                    c_description=m.c_description,
                    c_data_type=m.c_data_type,
                    n_id_questionnaire_group=m.n_id_questionnaire_group,
                    b_is_active=m.b_is_active,
                )
                for m in items
            ]

    @strawberry.field
    async def workshop_metrics(self, workshop_id: str) -> List[WorkshopMetricType]:
        async with AsyncSessionLocal() as session:
            repo = PostgresQuestionnaireRepository(session)
            service = QuestionnaireService(repo)
            items = await service.get_workshop_metrics(workshop_id)
            return [
                WorkshopMetricType(
                    n_id_metric_workshop=item.n_id_metric_workshop,
                    n_id_metric=item.n_id_metric,
                    c_name=item.c_name,
                    c_description=item.c_description,
                    c_data_type=item.c_data_type,
                )
                for item in items
            ]


@strawberry.type
class Mutation:
    @strawberry.mutation
    async def save_questionnaire_answer(self, input: SaveAnswerInput) -> str:
        async with AsyncSessionLocal() as session:
            repo = PostgresQuestionnaireRepository(session)
            service = QuestionnaireService(repo)
            entity = AnswerLog(
                n_id_metric_workshop=input.n_id_metric_workshop,
                n_id_participant=input.n_id_participant,
                c_value=input.c_value,
            )
            await service.save_answer(entity)
            return "OK"

    @strawberry.mutation
    async def save_questionnaire_answers_batch(self, input: SaveAnswersBatchInput) -> str:
        async with AsyncSessionLocal() as session:
            repo = PostgresQuestionnaireRepository(session)
            service = QuestionnaireService(repo)
            items = [
                AnswerLog(
                    n_id_metric_workshop=i.n_id_metric_workshop,
                    n_id_participant=i.n_id_participant,
                    c_value=i.c_value,
                )
                for i in input.items
            ]
            await service.save_answers_batch(items)
            return "OK"

    @strawberry.mutation
    async def create_questionnaire_group(
        self, c_name: str, c_description: str | None = None
    ) -> str:
        async with AsyncSessionLocal() as session:
            repo = PostgresQuestionnaireRepository(session)
            service = QuestionnaireService(repo)
            return await service.create_questionnaire_group(
                c_name=c_name,
                c_description=c_description,
            )

    @strawberry.mutation
    async def create_questionnaire_question(
        self,
        n_id_questionnaire_group: str,
        c_question: str,
        n_id_questionnaire_type: int,
        j_alternatives: str = "[]",
        b_is_pre: bool = False,
        b_is_post: bool = False,
    ) -> str:
        async with AsyncSessionLocal() as session:
            repo = PostgresQuestionnaireRepository(session)
            service = QuestionnaireService(repo)
            entity = NewQuestion(
                n_id_questionnaire_group=n_id_questionnaire_group,
                c_question=c_question,
                n_id_questionnaire_type=n_id_questionnaire_type,
                j_alternatives=j_alternatives,
                b_is_pre=b_is_pre,
                b_is_post=b_is_post,
            )
            return await service.create_question(entity)

    @strawberry.mutation
    async def create_metric(self, input: CreateMetricInput) -> str:
        async with AsyncSessionLocal() as session:
            repo = PostgresQuestionnaireRepository(session)
            service = QuestionnaireService(repo)
            entity = NewMetric(
                c_name=input.c_name,
                c_description=input.c_description,
                c_data_type=input.c_data_type,
                n_id_questionnaire_group=input.n_id_questionnaire_group,
                n_id_workshop=input.n_id_workshop,
                b_is_active=input.b_is_active,
            )
            return await service.create_metric(entity)

    @strawberry.mutation
    async def create_challenge(self, input: CreateChallengeInput) -> str:
        async with AsyncSessionLocal() as session:
            repo = PostgresQuestionnaireRepository(session)
            service = QuestionnaireService(repo)
            return await service.create_challenge(
                c_name=input.c_name,
                c_description=input.c_description,
            )

    @strawberry.mutation
    async def assign_challenge_to_workshop(self, input: AssignChallengeToWorkshopInput) -> str:
        async with AsyncSessionLocal() as session:
            repo = PostgresQuestionnaireRepository(session)
            service = QuestionnaireService(repo)
            return await service.assign_challenge_to_workshop(
                challenge_id=input.n_id_challenge,
                workshop_id=input.n_id_workshop,
            )

    @strawberry.mutation
    async def assign_metric_to_workshop(self, input: AssignMetricToWorkshopInput) -> str:
        async with AsyncSessionLocal() as session:
            repo = PostgresQuestionnaireRepository(session)
            service = QuestionnaireService(repo)
            return await service.assign_metric_to_workshop(
                metric_id=input.n_id_metric,
                workshop_id=input.n_id_workshop,
            )
