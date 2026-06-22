from __future__ import annotations

from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Response
from fastapi.middleware.cors import CORSMiddleware

from .config import settings
from .database import RecipeRepository, build_repository, utc_now_iso
from .models import AiRecipeResponse, AiSearchRequest, ApiStatus, RecipeCreate, RecipeResponse, RecipeUpdate
from .seed import seed_if_empty
from .services import search_recipe_with_fallback


repository: RecipeRepository = build_repository()


@asynccontextmanager
async def lifespan(_: FastAPI):
    seed_if_empty(repository, settings.seed_file)
    yield


app = FastAPI(
    title="Recipe Book API",
    version="1.0.0",
    description="Simple CRUD recipe backend with optional AI recipe search.",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins or ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/api/health", response_model=ApiStatus)
def health_check() -> ApiStatus:
    ai_enabled = bool(
        (settings.ai_provider == "openrouter" and settings.openrouter_api_key)
        or (settings.ai_provider == "openai" and settings.openai_api_key)
    )
    return ApiStatus(
        status="ok",
        database_mode=repository.mode,
        openai_enabled=ai_enabled,
    )


@app.get("/api/recipes", response_model=list[RecipeResponse])
def list_recipes() -> list[RecipeResponse]:
    return [RecipeResponse.model_validate(recipe) for recipe in repository.list_recipes()]


@app.get("/api/recipes/{recipe_id}", response_model=RecipeResponse)
def get_recipe(recipe_id: str) -> RecipeResponse:
    recipe = repository.get_recipe(recipe_id)
    if not recipe:
        raise HTTPException(status_code=404, detail="Recipe not found.")
    return RecipeResponse.model_validate(recipe)


@app.post("/api/recipes", response_model=RecipeResponse, status_code=201)
def create_recipe(recipe: RecipeCreate) -> RecipeResponse:
    now = utc_now_iso()
    payload = {
        **recipe.model_dump(),
        "source": "user",
        "created_at": now,
        "updated_at": now,
    }
    created = repository.create_recipe(payload)
    return RecipeResponse.model_validate(created)


@app.put("/api/recipes/{recipe_id}", response_model=RecipeResponse)
def update_recipe(recipe_id: str, recipe: RecipeUpdate) -> RecipeResponse:
    existing = repository.get_recipe(recipe_id)
    if not existing:
        raise HTTPException(status_code=404, detail="Recipe not found.")
    payload = {
        **recipe.model_dump(),
        "source": existing["source"],
        "created_at": existing["created_at"],
        "updated_at": utc_now_iso(),
    }
    updated = repository.update_recipe(recipe_id, payload)
    if not updated:
        raise HTTPException(status_code=404, detail="Recipe not found.")
    return RecipeResponse.model_validate(updated)


@app.delete("/api/recipes/{recipe_id}", status_code=204)
def delete_recipe(recipe_id: str) -> Response:
    deleted = repository.delete_recipe(recipe_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Recipe not found.")
    return Response(status_code=204)


@app.post("/api/ai/search", response_model=AiRecipeResponse)
def ai_search_recipe(request: AiSearchRequest) -> AiRecipeResponse:
    recipe, provider, live_model_used = search_recipe_with_fallback(request.query)
    return AiRecipeResponse(
        recipe=RecipeResponse.model_validate(recipe),
        provider=provider,
        live_model_used=live_model_used,
    )
