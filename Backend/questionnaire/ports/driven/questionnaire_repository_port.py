from abc import ABC, abstractmethod
from typing import List, Optional
from questionnaire.domain.entities.questionnaire import (
    WorkshopQuestionnaire, QuestionnaireGroup, Question, AnswerLog, NewQuestion, NewMetric, Metric,
    ParticipantMetricEntry, WorkshopMetric,
)


class QuestionnaireRepositoryPort(ABC):

    @abstractmethod
    async def find_workshops_with_questionnaires(
        self, program_id: str
    ) -> List[WorkshopQuestionnaire]: ...

    @abstractmethod
    async def find_questions_by_group_and_type(
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
    async def find_all_questionnaire_groups(
        self, program_id: Optional[str] = None, workshop_id: Optional[str] = None
    ) -> List[QuestionnaireGroup]: ...

    @abstractmethod
    async def create_question(self, data: NewQuestion) -> str: ...

    @abstractmethod
    async def create_metric(self, data: NewMetric) -> str: ...

    @abstractmethod
    async def find_all_metrics(self) -> List[Metric]: ...

    @abstractmethod
    async def assign_metric_to_workshop(self, metric_id: str, workshop_id: str) -> str: ...

    @abstractmethod
    async def find_workshop_metric_ids(self, workshop_id: str) -> List[str]: ...

    @abstractmethod
    async def create_challenge(self, c_name: str, c_description: Optional[str] = None) -> str: ...

    @abstractmethod
    async def assign_challenge_to_workshop(self, challenge_id: str, workshop_id: str) -> str: ...

    @abstractmethod
    async def find_all_challenges(self) -> List[dict]: ...

    @abstractmethod
    async def find_workshop_challenge_ids(self, workshop_id: str) -> List[str]: ...

    @abstractmethod
    async def find_workshop_challenges(self, workshop_id: str) -> List[dict]: ...

    @abstractmethod
    async def find_workshop_metrics(self, workshop_id: str) -> List[WorkshopMetric]: ...

    @abstractmethod
    async def find_participant_metrics(
        self, participant_id: str, workshop_id: str
    ) -> List[ParticipantMetricEntry]: ...
