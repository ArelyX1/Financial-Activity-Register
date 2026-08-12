"""graphql - Unified package combining local schema with graphql-core."""
import sys as _sys
import os as _os

_self = _sys.modules.pop("graphql")
_app_dir = _os.path.dirname(_os.path.dirname(_os.path.abspath(__file__)))
_original_path = _sys.path[:]
_sys.path = [p for p in _sys.path if _os.path.abspath(p) != _os.path.abspath(_app_dir)]

import importlib as _il
_core = _il.import_module("graphql")

_sys.path = _original_path

from pkgutil import extend_path
_self.__path__ = extend_path(_self.__path__, "graphql")

for _attr in dir(_core):
    if not _attr.startswith("_"):
        setattr(_self, _attr, getattr(_core, _attr))

_sys.modules["graphql"] = _self
