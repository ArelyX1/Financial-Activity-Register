from abc import ABC, abstractmethod
from typing import List, Optional
from questionnaire.domain.entities.questionnaire import (
    WorkshopQuestionnaire, QuestionnaireGroup, Question, AnswerLog, NewQuestion, NewMetric, Metric,
    ParticipantMetricEntry, WorkshopMetric,
)


class QuestionnaireInputPort(ABC):

    @abstractmethod
    async def get_workshops_with_questionnaires(
        self, program_id: str
    ) -> List[WorkshopQuestionnaire]: ...

    @abstractmethod
    async def get_questions_by_group_and_type(
        self, group_id: str, c_type: str
    ) -> List[Question]: ...

    @abstractmethod
    async def save_answer(self, data: AnswerLog) -> None: ...

    @abstractmethod
    async def save_answers_batch(self, items: List[AnswerLog]) -> None: ...

    @abstractmethod
    async def create_questionnaire_group(
        self, c_name: str, c_description: Optional[str] = None
    ) -> str: ...

    @abstractmethod
    async def get_all_questionnaire_groups(
        self, program_id: Optional[str] = None, workshop_id: Optional[str] = None
    ) -> List[QuestionnaireGroup]: ...

    @abstractmethod
    async def create_question(self, data: NewQuestion) -> str: ...

    @abstractmethod
    async def create_metric(self, data: NewMetric) -> str: ...

    @abstractmethod
    async def get_all_metrics(self) -> List[Metric]: ...

    @abstractmethod
    async def get_workshop_metrics(self, workshop_id: str) -> List[WorkshopMetric]: ...

    @abstractmethod
    async def get_participant_metrics(
        self, participant_id: str, workshop_id: str
    ) -> List[ParticipantMetricEntry]: ...
