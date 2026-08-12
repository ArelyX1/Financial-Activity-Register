from dataclasses import dataclass


@dataclass
class Boundarie:
    uid: int | None = None
    geo1: str | None = None
    geo1_name: str | None = None
    geo2: str | None = None
    geo2_name: str | None = None
    geo3: str | None = None
    geo3_name: str | None = None
    geo4: str | None = None
    geo4_name: str | None = None
