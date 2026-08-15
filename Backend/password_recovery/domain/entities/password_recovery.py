from dataclasses import dataclass


@dataclass
class RecoveryCode:
    identification_number: str
    code: str
    expires_in_seconds: int


@dataclass
class PasswordChangeResult:
    success: bool
