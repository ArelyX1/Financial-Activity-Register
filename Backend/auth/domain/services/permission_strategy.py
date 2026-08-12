import re
from abc import ABC, abstractmethod
from typing import List


class PermissionStrategy(ABC):
    @abstractmethod
    def has_permission(self, user_permissions: List[str], required_permission: str) -> bool: ...


class ExactMatchStrategy(PermissionStrategy):
    def has_permission(self, user_permissions: List[str], required_permission: str) -> bool:
        return required_permission in user_permissions


class WildcardStrategy(PermissionStrategy):
    def has_permission(self, user_permissions: List[str], required_permission: str) -> bool:
        if required_permission in user_permissions:
            return True
        escaped = re.escape(required_permission).replace('\\*', '.*')
        pattern = f"^{escaped}$"
        for perm in user_permissions:
            if re.match(pattern, perm):
                return True
        return False


class PermissionChecker:
    def __init__(self, strategy: PermissionStrategy | None = None):
        self._strategy = strategy or WildcardStrategy()

    def set_strategy(self, strategy: PermissionStrategy) -> None:
        self._strategy = strategy

    def check(self, user_permissions: List[str], required_permission: str) -> bool:
        if not required_permission:
            return True
        return self._strategy.has_permission(user_permissions, required_permission)
