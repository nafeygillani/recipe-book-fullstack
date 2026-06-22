from __future__ import annotations

import json
from copy import deepcopy
from pathlib import Path
from typing import Any

from .database import RecipeRepository, utc_now_iso


def load_seed_recipes(seed_file: Path) -> list[dict[str, Any]]:
    raw_recipes = json.loads(seed_file.read_text(encoding="utf-8"))
    now = utc_now_iso()
    recipes: list[dict[str, Any]] = []
    for recipe in raw_recipes:
        payload = deepcopy(recipe)
        payload["source"] = "default"
        payload["created_at"] = now
        payload["updated_at"] = now
        recipes.append(payload)
    return recipes


def seed_if_empty(repository: RecipeRepository, seed_file: Path) -> None:
    if repository.count() > 0:
        return
    for recipe in load_seed_recipes(seed_file):
        repository.create_recipe(recipe)
