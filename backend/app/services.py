from __future__ import annotations

import json
from copy import deepcopy
from typing import Any
from uuid import uuid4

import requests

from .config import settings
from .database import utc_now_iso


FALLBACK_AI_RECIPES: dict[str, dict[str, Any]] = {
    "biryani": {
        "title": "Chicken Biryani",
        "cuisine": "South Asian",
        "description": "A layered rice dish with spiced chicken, herbs, and fried onions.",
        "prep_minutes": 30,
        "cook_minutes": 50,
        "servings": 4,
        "difficulty": "Medium",
        "ingredients": [
            "500 g chicken",
            "2 cups basmati rice",
            "2 onions, sliced",
            "1 cup yogurt",
            "2 tomatoes, chopped",
            "2 tsp biryani masala",
            "1 tsp ginger garlic paste",
            "Fresh mint and coriander",
        ],
        "steps": [
            "Wash and soak the rice for 20 minutes, then parboil until 70 percent cooked.",
            "Brown the onions and reserve half for layering and garnish.",
            "Cook chicken with yogurt, tomatoes, ginger garlic paste, masala, and salt until tender.",
            "Layer rice, chicken, herbs, and fried onions in a pot.",
            "Cover tightly and steam on low heat for 20 minutes before serving.",
        ],
        "notes": "Serve with raita or salad.",
    },
    "ramen": {
        "title": "Shoyu Ramen",
        "cuisine": "Japanese",
        "description": "Soy-based noodle soup with a savory broth and classic toppings.",
        "prep_minutes": 20,
        "cook_minutes": 35,
        "servings": 2,
        "difficulty": "Medium",
        "ingredients": [
            "2 ramen noodle portions",
            "4 cups chicken stock",
            "2 tbsp soy sauce",
            "1 tsp sesame oil",
            "2 soft-boiled eggs",
            "Mushrooms and spring onions",
            "Cooked chicken or tofu",
        ],
        "steps": [
            "Simmer stock with soy sauce and sesame oil for 15 minutes.",
            "Cook noodles separately until just tender.",
            "Place noodles in bowls and pour over hot broth.",
            "Top with eggs, mushrooms, spring onions, and protein.",
        ],
        "notes": "Add chili oil for extra heat.",
    },
    "tacos": {
        "title": "Beef Tacos",
        "cuisine": "Mexican",
        "description": "Quick skillet tacos with seasoned beef and fresh toppings.",
        "prep_minutes": 15,
        "cook_minutes": 15,
        "servings": 4,
        "difficulty": "Easy",
        "ingredients": [
            "500 g minced beef",
            "8 taco shells or tortillas",
            "1 onion, chopped",
            "2 tsp taco seasoning",
            "Lettuce, tomato, cheese",
            "Sour cream or salsa",
        ],
        "steps": [
            "Cook onion and beef in a skillet until browned.",
            "Add taco seasoning and a splash of water, then simmer briefly.",
            "Warm taco shells or tortillas.",
            "Fill with beef and toppings, then serve immediately.",
        ],
        "notes": "Works well with chicken or beans too.",
    },
    "pancakes": {
        "title": "Classic Pancakes",
        "cuisine": "American",
        "description": "Soft breakfast pancakes that come together with pantry basics.",
        "prep_minutes": 10,
        "cook_minutes": 12,
        "servings": 3,
        "difficulty": "Easy",
        "ingredients": [
            "1 cup flour",
            "2 tbsp sugar",
            "1 tsp baking powder",
            "1 egg",
            "3/4 cup milk",
            "2 tbsp melted butter",
        ],
        "steps": [
            "Whisk together the dry ingredients in a bowl.",
            "Mix in egg, milk, and melted butter until just combined.",
            "Pour batter onto a greased hot pan and cook until bubbles form.",
            "Flip and cook the second side until golden.",
        ],
        "notes": "Serve with syrup, fruit, or honey.",
    },
    "hummus": {
        "title": "Creamy Hummus",
        "cuisine": "Middle Eastern",
        "description": "A smooth chickpea dip blended with tahini, garlic, and lemon.",
        "prep_minutes": 10,
        "cook_minutes": 0,
        "servings": 4,
        "difficulty": "Easy",
        "ingredients": [
            "2 cups boiled chickpeas",
            "1/4 cup tahini",
            "2 tbsp lemon juice",
            "1 garlic clove",
            "2 tbsp olive oil",
            "Salt to taste",
        ],
        "steps": [
            "Blend chickpeas, tahini, lemon juice, garlic, and salt until smooth.",
            "Add a little cold water while blending to loosen the texture.",
            "Spread into a bowl and finish with olive oil on top.",
        ],
        "notes": "Paprika and parsley make a nice garnish.",
    },
}


def _generic_recipe(query: str) -> dict[str, Any]:
    name = query.strip().title()
    return {
        "title": name,
        "cuisine": "International",
        "description": f"A simple demo-style recipe outline for {name}.",
        "prep_minutes": 15,
        "cook_minutes": 25,
        "servings": 4,
        "difficulty": "Easy",
        "ingredients": [
            f"Main ingredient for {name}",
            "2 tbsp oil or butter",
            "1 onion, chopped",
            "2 cloves garlic",
            "Salt and pepper",
            "Herbs or spices of choice",
        ],
        "steps": [
            f"Prepare the ingredients for {name} and season them lightly.",
            "Heat oil in a pan and cook onion and garlic until fragrant.",
            "Add the main ingredients and cook until tender and well seasoned.",
            "Finish with herbs or a sauce, then serve warm.",
        ],
        "notes": "This fallback appears when no live AI key is configured.",
    }


def build_ai_recipe_payload(recipe: dict[str, Any]) -> dict[str, Any]:
    now = utc_now_iso()
    return {
        "id": f"ai-{uuid4().hex}",
        **deepcopy(recipe),
        "source": "ai",
        "created_by": "AI Search",
        "created_at": now,
        "updated_at": now,
    }


def search_recipe_with_fallback(query: str) -> tuple[dict[str, Any], str, bool]:
    normalized = query.strip().lower()
    live_recipe = None
    provider_name = settings.ai_provider

    if settings.ai_provider == "openrouter" and settings.openrouter_api_key:
        live_recipe = search_recipe_with_openrouter(normalized)
    elif settings.ai_provider == "openai" and settings.openai_api_key:
        live_recipe = search_recipe_with_openai(normalized)

    if live_recipe:
        return build_ai_recipe_payload(live_recipe), provider_name, True

    if settings.openai_api_key:
        live_recipe = search_recipe_with_openai(normalized)
        if live_recipe:
            return build_ai_recipe_payload(live_recipe), "openai", True

    for keyword, recipe in FALLBACK_AI_RECIPES.items():
        if keyword in normalized:
            return build_ai_recipe_payload(recipe), "local-fallback", False

    return build_ai_recipe_payload(_generic_recipe(query)), "local-fallback", False


def search_recipe_with_openai(query: str) -> dict[str, Any] | None:
    endpoint = f"{settings.openai_base_url.rstrip('/')}/responses"
    prompt = (
        "You are a recipe assistant. Return only valid JSON with the keys "
        "title, cuisine, description, prep_minutes, cook_minutes, servings, difficulty, "
        "ingredients, steps, notes. Difficulty must be Easy, Medium, or Hard. "
        f"Find a practical home-cook recipe for: {query}."
    )
    try:
        response = requests.post(
            endpoint,
            headers={
                "Authorization": f"Bearer {settings.openai_api_key}",
                "Content-Type": "application/json",
            },
            json={
                "model": settings.openai_model,
                "input": prompt,
            },
            timeout=20,
        )
        response.raise_for_status()
        data = response.json()
        text = _extract_response_text(data)
        if not text:
            return None
        parsed = json.loads(text)
        if not isinstance(parsed, dict):
            return None
        return {
            "title": str(parsed.get("title", query.title())),
            "cuisine": str(parsed.get("cuisine", "International")),
            "description": str(parsed.get("description", f"A recipe for {query.title()}.")),
            "prep_minutes": int(parsed.get("prep_minutes", 15)),
            "cook_minutes": int(parsed.get("cook_minutes", 25)),
            "servings": int(parsed.get("servings", 4)),
            "difficulty": parsed.get("difficulty", "Easy"),
            "ingredients": [str(item) for item in parsed.get("ingredients", [])] or ["See recipe notes"],
            "steps": [str(item) for item in parsed.get("steps", [])] or ["Prepare and cook the dish."],
            "notes": str(parsed.get("notes", "")),
        }
    except (requests.RequestException, ValueError, TypeError, json.JSONDecodeError):
        return None


def search_recipe_with_openrouter(query: str) -> dict[str, Any] | None:
    endpoint = f"{settings.openrouter_base_url.rstrip('/')}/chat/completions"
    system_prompt = (
        "You are a recipe assistant. Return only valid JSON with these keys: "
        "title, cuisine, description, prep_minutes, cook_minutes, servings, difficulty, "
        "ingredients, steps, notes. Difficulty must be Easy, Medium, or Hard."
    )
    user_prompt = f"Find a practical home-cook recipe for: {query}."

    try:
        response = requests.post(
            endpoint,
            headers={
                "Authorization": f"Bearer {settings.openrouter_api_key}",
                "Content-Type": "application/json",
                "HTTP-Referer": "http://localhost",
                "X-OpenRouter-Title": "Recipe Book Demo",
            },
            json={
                "model": settings.openrouter_model,
                "messages": [
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt},
                ],
                "response_format": {"type": "json_object"},
                "provider": {
                    "order": [settings.openrouter_provider],
                    "allow_fallbacks": settings.openrouter_allow_fallbacks,
                },
            },
            timeout=30,
        )
        response.raise_for_status()
        data = response.json()
        text = _extract_openrouter_text(data)
        if not text:
            return None
        parsed = json.loads(text)
        if not isinstance(parsed, dict):
            return None
        return {
            "title": str(parsed.get("title", query.title())),
            "cuisine": str(parsed.get("cuisine", "International")),
            "description": str(parsed.get("description", f"A recipe for {query.title()}.")),
            "prep_minutes": int(parsed.get("prep_minutes", 15)),
            "cook_minutes": int(parsed.get("cook_minutes", 25)),
            "servings": int(parsed.get("servings", 4)),
            "difficulty": parsed.get("difficulty", "Easy"),
            "ingredients": [str(item) for item in parsed.get("ingredients", [])] or ["See recipe notes"],
            "steps": [str(item) for item in parsed.get("steps", [])] or ["Prepare and cook the dish."],
            "notes": str(parsed.get("notes", "")),
        }
    except (requests.RequestException, ValueError, TypeError, json.JSONDecodeError):
        return None


def _extract_response_text(data: dict[str, Any]) -> str:
    output_text = str(data.get("output_text", "")).strip()
    if output_text:
        return output_text

    output = data.get("output", [])
    if not isinstance(output, list):
        return ""

    text_parts: list[str] = []
    for item in output:
        if not isinstance(item, dict):
            continue
        for content in item.get("content", []):
            if not isinstance(content, dict):
                continue
            if content.get("type") == "output_text":
                text = str(content.get("text", "")).strip()
                if text:
                    text_parts.append(text)
    return "\n".join(text_parts).strip()


def _extract_openrouter_text(data: dict[str, Any]) -> str:
    choices = data.get("choices", [])
    if not isinstance(choices, list) or not choices:
        return ""

    first = choices[0]
    if not isinstance(first, dict):
        return ""

    message = first.get("message", {})
    if not isinstance(message, dict):
        return ""

    return str(message.get("content", "")).strip()
