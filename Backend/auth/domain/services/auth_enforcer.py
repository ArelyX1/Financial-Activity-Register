import os
from pathlib import Path
from typing import List
import casbin


class PermissionEnforcer:
    def __init__(self, model_path: str | None = None, policy_path: str | None = None):
        base = Path(__file__).parent.parent.parent / "casbin"
        model = model_path or str(base / "model.conf")
        policy = policy_path or str(base / "policy.csv")
        self._enforcer = casbin.Enforcer(model, policy)

    def get_required_permission(self, api_operation: str) -> str | None:
        rules = self._enforcer.get_filtered_policy(1, api_operation)
        if rules:
            return rules[0][0]
        return None

    def can_access(self, user_permissions: List[str], api_operation: str) -> bool:
        from auth.domain.services.permission_strategy import PermissionChecker

        required = self.get_required_permission(api_operation)
        if required is None:
            return False
        checker = PermissionChecker()
        perm_names = [p["code"] if isinstance(p, dict) else p for p in user_permissions]
        return checker.check(perm_names, required)
