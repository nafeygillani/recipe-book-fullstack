from __future__ import annotations

import json
from abc import ABC, abstractmethod
from copy import deepcopy
from datetime import datetime, timezone
from pathlib import Path
from threading import Lock
from typing import Any
from uuid import uuid4

from bson import ObjectId
from pymongo import MongoClient
from pymongo.collection import Collection
from pymongo.errors import PyMongoError

from .config import settings


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def normalize_recipe(record: dict[str, Any]) -> dict[str, Any]:
    doc = deepcopy(record)
    if "_id" in doc:
        doc["id"] = str(doc.pop("_id"))
    return doc


class RecipeRepository(ABC):
    mode: str

    @abstractmethod
    def health_check(self) -> None:
        raise NotImplementedError

    @abstractmethod
    def list_recipes(self) -> list[dict[str, Any]]:
        raise NotImplementedError

    @abstractmethod
    def get_recipe(self, recipe_id: str) -> dict[str, Any] | None:
        raise NotImplementedError

    @abstractmethod
    def create_recipe(self, recipe_data: dict[str, Any]) -> dict[str, Any]:
        raise NotImplementedError

    @abstractmethod
    def update_recipe(self, recipe_id: str, recipe_data: dict[str, Any]) -> dict[str, Any] | None:
        raise NotImplementedError

    @abstractmethod
    def delete_recipe(self, recipe_id: str) -> bool:
        raise NotImplementedError

    @abstractmethod
    def count(self) -> int:
        raise NotImplementedError


class MongoRecipeRepository(RecipeRepository):
    mode = "mongodb"

    def __init__(self, client: MongoClient) -> None:
        self.client = client
        self.collection: Collection = client[settings.mongo_db][settings.mongo_collection]

    def health_check(self) -> None:
        self.client.admin.command("ping")

    def list_recipes(self) -> list[dict[str, Any]]:
        recipes = [
            normalize_recipe(doc)
            for doc in self.collection.find().sort([("source", 1), ("title", 1)])
        ]
        return recipes

    def get_recipe(self, recipe_id: str) -> dict[str, Any] | None:
        if not ObjectId.is_valid(recipe_id):
            return None
        recipe = self.collection.find_one({"_id": ObjectId(recipe_id)})
        return normalize_recipe(recipe) if recipe else None

    def create_recipe(self, recipe_data: dict[str, Any]) -> dict[str, Any]:
        payload = deepcopy(recipe_data)
        result = self.collection.insert_one(payload)
        payload["_id"] = result.inserted_id
        return normalize_recipe(payload)

    def update_recipe(self, recipe_id: str, recipe_data: dict[str, Any]) -> dict[str, Any] | None:
        if not ObjectId.is_valid(recipe_id):
            return None
        object_id = ObjectId(recipe_id)
        result = self.collection.update_one({"_id": object_id}, {"$set": deepcopy(recipe_data)})
        if result.matched_count == 0:
            return None
        updated = self.collection.find_one({"_id": object_id})
        return normalize_recipe(updated) if updated else None

    def delete_recipe(self, recipe_id: str) -> bool:
        if not ObjectId.is_valid(recipe_id):
            return False
        result = self.collection.delete_one({"_id": ObjectId(recipe_id)})
        return result.deleted_count == 1

    def count(self) -> int:
        return self.collection.count_documents({})


class LocalJsonRecipeRepository(RecipeRepository):
    mode = "local-json-fallback"

    def __init__(self, file_path: Path) -> None:
        self.file_path = file_path
        self.file_path.parent.mkdir(parents=True, exist_ok=True)
        self.lock = Lock()
        if not self.file_path.exists():
            self.file_path.write_text("[]", encoding="utf-8")

    def health_check(self) -> None:
        if not self.file_path.exists():
            raise FileNotFoundError(self.file_path)

    def _read(self) -> list[dict[str, Any]]:
        with self.lock:
            return json.loads(self.file_path.read_text(encoding="utf-8"))

    def _write(self, data: list[dict[str, Any]]) -> None:
        with self.lock:
            self.file_path.write_text(json.dumps(data, indent=2), encoding="utf-8")

    def list_recipes(self) -> list[dict[str, Any]]:
        recipes = self._read()
        return sorted(recipes, key=lambda item: (item["source"], item["title"].lower()))

    def get_recipe(self, recipe_id: str) -> dict[str, Any] | None:
        return next((recipe for recipe in self._read() if recipe["id"] == recipe_id), None)

    def create_recipe(self, recipe_data: dict[str, Any]) -> dict[str, Any]:
        recipes = self._read()
        payload = deepcopy(recipe_data)
        payload["id"] = uuid4().hex
        recipes.append(payload)
        self._write(recipes)
        return payload

    def update_recipe(self, recipe_id: str, recipe_data: dict[str, Any]) -> dict[str, Any] | None:
        recipes = self._read()
        updated_recipe = None
        for index, recipe in enumerate(recipes):
            if recipe["id"] == recipe_id:
                updated_recipe = {"id": recipe_id, **deepcopy(recipe_data)}
                recipes[index] = updated_recipe
                break
        if updated_recipe is None:
            return None
        self._write(recipes)
        return updated_recipe

    def delete_recipe(self, recipe_id: str) -> bool:
        recipes = self._read()
        filtered = [recipe for recipe in recipes if recipe["id"] != recipe_id]
        if len(filtered) == len(recipes):
            return False
        self._write(filtered)
        return True

    def count(self) -> int:
        return len(self._read())


def build_repository() -> RecipeRepository:
    try:
        mongo_client = MongoClient(settings.mongo_uri, serverSelectionTimeoutMS=1500)
        repo = MongoRecipeRepository(mongo_client)
        repo.health_check()
        return repo
    except PyMongoError:
        return LocalJsonRecipeRepository(settings.data_file)
