from typing import List, Optional
from questionnaire.ports.driving.questionnaire_input_port import QuestionnaireInputPort
from questionnaire.ports.driven.questionnaire_repository_port import QuestionnaireRepositoryPort
from questionnaire.domain.entities.questionnaire import (
    WorkshopQuestionnaire, QuestionnaireGroup, Question, AnswerLog, NewQuestion, NewMetric, Metric,
    ParticipantMetricEntry, WorkshopMetric,
)


class QuestionnaireService(QuestionnaireInputPort):
    def __init__(self, repo: QuestionnaireRepositoryPort):
        self._repo = repo

    async def get_workshops_with_questionnaires(
        self, program_id: str
    ) -> List[WorkshopQuestionnaire]:
        return await self._repo.find_workshops_with_questionnaires(program_id)

    async def get_questions_by_group_and_type(
        self, group_id: str, c_type: str
    ) -> List[Question]:
        return await self._repo.find_questions_by_group_and_type(group_id, c_type)

    async def save_answer(self, data: AnswerLog) -> None:
        await self._repo.save_answer(data)

    async def save_answers_batch(self, items: List[AnswerLog]) -> None:
        await self._repo.save_answers_batch(items)

    async def create_questionnaire_group(
        self, c_name: str, c_description: Optional[str] = None
    ) -> str:
        return await self._repo.create_questionnaire_group(c_name, c_description)

    async def get_all_questionnaire_groups(
        self, program_id: Optional[str] = None, workshop_id: Optional[str] = None
    ) -> List[QuestionnaireGroup]:
        return await self._repo.find_all_questionnaire_groups(program_id, workshop_id)

    async def create_question(self, data: NewQuestion) -> str:
        return await self._repo.create_question(data)

    async def create_metric(self, data: NewMetric) -> str:
        return await self._repo.create_metric(data)

    async def get_all_metrics(self) -> List[Metric]:
        return await self._repo.find_all_metrics()

    async def get_workshop_metrics(self, workshop_id: str) -> List[WorkshopMetric]:
        return await self._repo.find_workshop_metrics(workshop_id)

    async def assign_metric_to_workshop(self, metric_id: str, workshop_id: str) -> str:
        return await self._repo.assign_metric_to_workshop(metric_id, workshop_id)

    async def get_workshop_metric_ids(self, workshop_id: str) -> List[str]:
        return await self._repo.find_workshop_metric_ids(workshop_id)

    async def create_challenge(self, c_name: str, c_description: Optional[str] = None) -> str:
        return await self._repo.create_challenge(c_name, c_description)

    async def assign_challenge_to_workshop(self, challenge_id: str, workshop_id: str) -> str:
        return await self._repo.assign_challenge_to_workshop(challenge_id, workshop_id)

    async def get_all_challenges(self) -> List[dict]:
        return await self._repo.find_all_challenges()

    async def get_workshop_challenge_ids(self, workshop_id: str) -> List[str]:
        return await self._repo.find_workshop_challenge_ids(workshop_id)

    async def get_workshop_challenges(self, workshop_id: str) -> List[dict]:
        return await self._repo.find_workshop_challenges(workshop_id)

    async def get_participant_metrics(
        self, participant_id: str, workshop_id: str
    ) -> List[ParticipantMetricEntry]:
        return await self._repo.find_participant_metrics(participant_id, workshop_id)
