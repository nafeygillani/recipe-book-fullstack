# Recipe Book Fullstack

A full-stack recipe book application built with a Flutter web frontend and a FastAPI backend. The app lets users browse seeded recipes, create and manage their own recipes, search for AI-generated recipes, and optionally show live activity through Discord Rich Presence.

![Flutter](https://img.shields.io/badge/Frontend-Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![FastAPI](https://img.shields.io/badge/Backend-FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)
![MongoDB](https://img.shields.io/badge/Database-MongoDB-47A248?style=for-the-badge&logo=mongodb&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.11+-3776AB?style=for-the-badge&logo=python&logoColor=white)

## Overview

Recipe Book Fullstack is a student-friendly full-stack project that demonstrates a complete CRUD workflow with a polished Flutter interface and a Python API. The backend uses MongoDB when available and automatically falls back to a local JSON store for easy demos. AI recipe search can run with OpenRouter or OpenAI keys, while still working in fallback demo mode without API credentials.

## Features

- Browse default seeded recipes
- Add, edit, view, and delete recipes
- Search for AI-generated recipe ideas
- Save AI search results into the recipe book
- MongoDB persistence with local JSON fallback
- FastAPI Swagger documentation
- Optional Discord Rich Presence integration
- One-click Windows demo launcher

## Tech Stack

| Layer | Technology |
| --- | --- |
| Frontend | Flutter, Dart, Material 3, `http` |
| Backend | Python, FastAPI, Uvicorn, Pydantic |
| Database | MongoDB with local JSON fallback |
| AI Providers | OpenRouter or OpenAI |
| Optional Integration | Discord Rich Presence via `pypresence` |

## Project Structure

```text
recipe-book-fullstack/
|-- backend/
|   |-- app/
|   |   |-- data/
|   |   |   |-- default_recipes.json
|   |   |   `-- runtime_recipes.json
|   |   |-- config.py
|   |   |-- database.py
|   |   |-- main.py
|   |   |-- models.py
|   |   |-- presence.py
|   |   |-- seed.py
|   |   `-- services.py
|   |-- requirements.txt
|   `-- start_backend.bat
|-- frontend/
|   |-- lib/
|   |   `-- main.dart
|   |-- web/
|   |-- pubspec.yaml
|   `-- start_frontend.bat
|-- discord-assets/
|-- run_demo.bat
`-- README.md
```

## Prerequisites

Install the following before running the project:

- Python 3.11 or newer
- Flutter SDK with Chrome support enabled
- Google Chrome
- MongoDB Community Server, optional

MongoDB is not required for demos. If MongoDB is unavailable, the backend automatically stores recipes in `backend/app/data/runtime_recipes.json`.

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/nafeygillani/recipe-book-fullstack.git
cd recipe-book-fullstack
```

### 2. Start the backend

On Windows:

```bat
backend\start_backend.bat
```

The script creates a virtual environment, installs dependencies, and starts the FastAPI server at:

- API: `http://127.0.0.1:8000`
- Swagger Docs: `http://127.0.0.1:8000/docs`

### 3. Start the frontend

In a second terminal:

```bat
frontend\start_frontend.bat
```

The Flutter app runs in Chrome and connects to:

```text
http://127.0.0.1:8000/api
```

### 4. Run the full demo

You can also launch both backend and frontend with:

```bat
run_demo.bat
```

## Environment Variables

Create `backend/.env` if you want to customize the backend. All variables are optional because the project includes sensible defaults.

```env
# Server
BACKEND_HOST=127.0.0.1
BACKEND_PORT=8000
ALLOWED_ORIGINS=*

# MongoDB
MONGO_URI=mongodb://localhost:27017
MONGO_DB=recipe_book
MONGO_COLLECTION=recipes

# AI provider: openrouter or openai
AI_PROVIDER=openrouter

# OpenRouter
OPENROUTER_API_KEY=your_openrouter_key_here
OPENROUTER_MODEL=deepseek/deepseek-v4-flash
OPENROUTER_BASE_URL=https://openrouter.ai/api/v1
OPENROUTER_PROVIDER=deepseek
OPENROUTER_ALLOW_FALLBACKS=false

# OpenAI
OPENAI_API_KEY=your_openai_key_here
OPENAI_MODEL=gpt-5.2-mini
OPENAI_BASE_URL=https://api.openai.com/v1

# Discord Rich Presence
DISCORD_CLIENT_ID=your_discord_application_client_id
DISCORD_LARGE_IMAGE=
DISCORD_LARGE_TEXT=Recipe Book
DISCORD_PRESENCE_TIMEOUT_SECONDS=45
```

If no AI key is provided, AI search still works through the built-in fallback recipe generator.

## API Endpoints

| Method | Endpoint | Description |
| --- | --- | --- |
| `GET` | `/api/health` | Check API, database, AI, and Discord status |
| `GET` | `/api/recipes` | List all recipes |
| `GET` | `/api/recipes/{recipe_id}` | Get one recipe |
| `POST` | `/api/recipes` | Create a recipe |
| `PUT` | `/api/recipes/{recipe_id}` | Update a recipe |
| `DELETE` | `/api/recipes/{recipe_id}` | Delete a recipe |
| `POST` | `/api/ai/search` | Generate or fetch an AI recipe result |
| `POST` | `/api/presence` | Update Discord activity |
| `DELETE` | `/api/presence` | Clear Discord activity |

## Discord Rich Presence

The app can show recipe activity in Discord while it is running.

1. Create an application in the Discord Developer Portal.
2. Copy the application Client ID.
3. Add it to `backend/.env`:

```env
DISCORD_CLIENT_ID=your_discord_application_client_id
DISCORD_LARGE_TEXT=Recipe Book
```

4. Keep the Discord desktop app open.
5. Enable activity sharing in Discord privacy settings.
6. Restart the backend and open the Flutter app.

The Flutter frontend sends heartbeat requests to `POST /api/presence`, and the backend clears the activity when the app stops sending updates.

## Demo Flow

Use this flow when presenting the project:

1. Open the app and show the seeded recipes.
2. Add a new recipe manually.
3. Edit the recipe details.
4. Delete a recipe.
5. Search for a recipe using AI search.
6. Save the AI-generated recipe to the recipe book.
7. Open Swagger Docs to show the backend API.

## Key Files

- Backend entry point: [`backend/app/main.py`](backend/app/main.py)
- Backend settings: [`backend/app/config.py`](backend/app/config.py)
- Database layer: [`backend/app/database.py`](backend/app/database.py)
- AI recipe logic: [`backend/app/services.py`](backend/app/services.py)
- Flutter UI: [`frontend/lib/main.dart`](frontend/lib/main.dart)
- Frontend dependencies: [`frontend/pubspec.yaml`](frontend/pubspec.yaml)
- Backend dependencies: [`backend/requirements.txt`](backend/requirements.txt)

## License

This project is available for learning and demonstration purposes. Add a license file if you plan to publish or distribute it formally.
