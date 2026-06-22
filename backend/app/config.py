from __future__ import annotations

import os
from dataclasses import dataclass, field
from pathlib import Path

from dotenv import load_dotenv


BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BASE_DIR / ".env")


def _csv_to_list(value: str) -> list[str]:
    if not value.strip():
        return []
    return [item.strip() for item in value.split(",") if item.strip()]


@dataclass(slots=True)
class Settings:
    mongo_uri: str = os.getenv("MONGO_URI", "mongodb://localhost:27017")
    mongo_db: str = os.getenv("MONGO_DB", "recipe_book")
    mongo_collection: str = os.getenv("MONGO_COLLECTION", "recipes")
    ai_provider: str = os.getenv("AI_PROVIDER", "openrouter").lower()
    openrouter_api_key: str = os.getenv("OPENROUTER_API_KEY", "")
    openrouter_model: str = os.getenv("OPENROUTER_MODEL", "deepseek/deepseek-v4-flash")
    openrouter_base_url: str = os.getenv("OPENROUTER_BASE_URL", "https://openrouter.ai/api/v1")
    openrouter_provider: str = os.getenv("OPENROUTER_PROVIDER", "deepseek")
    openrouter_allow_fallbacks: bool = os.getenv("OPENROUTER_ALLOW_FALLBACKS", "false").lower() == "true"
    openai_api_key: str = os.getenv("OPENAI_API_KEY", "")
    openai_model: str = os.getenv("OPENAI_MODEL", "gpt-5.2-mini")
    openai_base_url: str = os.getenv("OPENAI_BASE_URL", "https://api.openai.com/v1")
    backend_host: str = os.getenv("BACKEND_HOST", "127.0.0.1")
    backend_port: int = int(os.getenv("BACKEND_PORT", "8000"))
    allowed_origins: list[str] = field(
        default_factory=lambda: _csv_to_list(os.getenv("ALLOWED_ORIGINS", "*"))
    )
    data_file: Path = BASE_DIR / "app" / "data" / "runtime_recipes.json"
    seed_file: Path = BASE_DIR / "app" / "data" / "default_recipes.json"


settings = Settings()
