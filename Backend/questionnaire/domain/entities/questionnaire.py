from dataclasses import dataclass
from typing import Optional


@dataclass
class QuestionnaireGroup:
    n_id_questionnaire_group: str
    c_name: str
    c_description: Optional[str] = None
    n_id_metric: Optional[str] = None
    c_metric_name: Optional[str] = None
    c_metric_description: Optional[str] = None
    c_metric_data_type: Optional[str] = None
    n_id_metric_workshop: Optional[str] = None
    available_types: list[str] | None = None


@dataclass
class Question:
    n_id_questionnaire: str
    c_question: str
    n_id_questionnaire_type: int
    c_type_name: str = ""
    j_alternatives: str = "[]"
    b_is_pre: bool = False
    b_is_post: bool = False


@dataclass
class WorkshopQuestionnaire:
    n_id_workshop: str
    c_description: Optional[str] = None
    c_status: Optional[str] = None
    t_date: Optional[str] = None
    questionnaire_groups: list[QuestionnaireGroup] | None = None


@dataclass
class AnswerLog:
    n_id_metric_workshop: str
    n_id_participant: str
    c_value: str


@dataclass
class NewQuestion:
    n_id_questionnaire_group: str
    c_question: str
    n_id_questionnaire_type: int
    j_alternatives: str = "[]"
    b_is_pre: bool = False
    b_is_post: bool = False


@dataclass
class NewMetric:
    c_name: str
    c_description: str | None = None
    c_data_type: str | None = None
    n_id_questionnaire_group: str | None = None
    n_id_workshop: str | None = None
    b_is_active: bool = True


@dataclass
class Metric:
    n_id_metric: str
    c_name: str
    c_description: str | None = None
    c_data_type: str | None = None
    n_id_questionnaire_group: str | None = None
    b_is_active: bool = True


@dataclass
class WorkshopMetric:
    n_id_metric_workshop: str
    n_id_metric: str
    c_name: str
    c_description: str | None = None
    c_data_type: str | None = None


@dataclass
class ParticipantMetricEntry:
    n_id_metric_workshop: str
    c_value: str
    metric_name: str
    metric_data_type: str | None = None
    n_id_questionnaire: str | None = None
    c_question: str | None = None
    j_alternatives: str | None = None
    questionnaire_type_name: str | None = None
    t_date: str | None = None
