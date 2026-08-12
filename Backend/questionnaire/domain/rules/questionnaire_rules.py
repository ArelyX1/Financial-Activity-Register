from dataclasses import dataclass, field
from typing import List


@dataclass
class AlternativeField:
    valor: int
    etiqueta: str


@dataclass
class QuestionnaireTypeConfig:
    nidquestionnairetype: int
    cname: str
    has_options: bool
    multi_select: bool
    default_alternatives: List[AlternativeField] = field(default_factory=list)


QUESTIONNAIRE_TYPE_RULES: dict[int, QuestionnaireTypeConfig] = {
    1: QuestionnaireTypeConfig(
        nidquestionnairetype=1,
        cname="Likert",
        has_options=True,
        multi_select=False,
        default_alternatives=[
            AlternativeField(valor=1, etiqueta="Totalmente en desacuerdo"),
            AlternativeField(valor=2, etiqueta="En desacuerdo"),
            AlternativeField(valor=3, etiqueta="Neutral"),
            AlternativeField(valor=4, etiqueta="De acuerdo"),
            AlternativeField(valor=5, etiqueta="Totalmente de acuerdo"),
        ],
    ),
    2: QuestionnaireTypeConfig(
        nidquestionnairetype=2,
        cname="Respuesta Abierta",
        has_options=False,
        multi_select=False,
        default_alternatives=[],
    ),
    3: QuestionnaireTypeConfig(
        nidquestionnairetype=3,
        cname="Opción Múltiple",
        has_options=True,
        multi_select=True,
        default_alternatives=[
            AlternativeField(valor=1, etiqueta="Opción 1"),
            AlternativeField(valor=2, etiqueta="Opción 2"),
            AlternativeField(valor=3, etiqueta="Opción 3"),
        ],
    ),
    4: QuestionnaireTypeConfig(
        nidquestionnairetype=4,
        cname="Opción Simple",
        has_options=True,
        multi_select=False,
        default_alternatives=[
            AlternativeField(valor=0, etiqueta="Sí"),
            AlternativeField(valor=1, etiqueta="No"),
        ],
    ),
}


def get_type_config(type_id: int) -> QuestionnaireTypeConfig | None:
    return QUESTIONNAIRE_TYPE_RULES.get(type_id)
