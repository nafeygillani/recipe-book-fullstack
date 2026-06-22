from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field


class RecipeBase(BaseModel):
    title: str = Field(min_length=2, max_length=120)
    cuisine: str = Field(min_length=2, max_length=60)
    description: str = Field(min_length=10, max_length=500)
    prep_minutes: int = Field(ge=0, le=600)
    cook_minutes: int = Field(ge=0, le=600)
    servings: int = Field(ge=1, le=20)
    difficulty: Literal["Easy", "Medium", "Hard"]
    ingredients: list[str] = Field(min_length=1)
    steps: list[str] = Field(min_length=1)
    notes: str = Field(default="", max_length=500)
    created_by: str = Field(default="User", max_length=50)


class RecipeCreate(RecipeBase):
    pass


class RecipeUpdate(RecipeBase):
    pass


class RecipeResponse(RecipeBase):
    id: str
    source: Literal["default", "user", "ai"]
    created_at: str
    updated_at: str


class AiSearchRequest(BaseModel):
    query: str = Field(min_length=2, max_length=120)


class AiRecipeResponse(BaseModel):
    recipe: RecipeResponse
    provider: str
    live_model_used: bool


class ApiStatus(BaseModel):
    status: str
    database_mode: str
    openai_enabled: bool
