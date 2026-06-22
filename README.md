# Recipe Book Full Stack App

This project is a simple full stack recipe book made with:

- `Flutter` for the frontend
- `Python FastAPI` for the backend
- `MongoDB` for the database when available

The backend also includes an AI recipe search endpoint:

- If you add an `OPENROUTER_API_KEY`, it can use OpenRouter.
- The default configured live model is `deepseek/deepseek-v4-flash`.
- If you add an `OPENAI_API_KEY`, it can also use the OpenAI path if you switch providers.
- If you do not add a key, it still works in demo mode using a built-in fallback recipe search.

## Features

- View default seeded recipes
- Add your own recipe
- Edit any recipe
- Delete any recipe
- Search for a recipe with the in-app AI search
- Save an AI recipe into the recipe book

## Project Structure

- [backend](/C:/Users/Abdullah/Desktop/nafey/backend)
- [frontend](/C:/Users/Abdullah/Desktop/nafey/frontend)
- [run_demo.bat](/C:/Users/Abdullah/Desktop/nafey/run_demo.bat)

## Prerequisites

Install these before running:

1. `Python 3.11+`
2. `Flutter SDK`
3. `Google Chrome` for `flutter run -d chrome`
4. `MongoDB Community Server` if you want real MongoDB mode

Notes:

- The app will still run if MongoDB is not installed. In that case the backend automatically falls back to a local JSON file for demo purposes.
- On this machine, `Flutter` and a full `Python` install were not available, so the code was prepared carefully but could not be executed here.

## Backend Setup

1. Open the [backend](/C:/Users/Abdullah/Desktop/nafey/backend) folder.
2. Copy `.env.example` to `.env`.
3. If you want live AI search with OpenRouter, add your OpenRouter key in `.env`:

```env
AI_PROVIDER=openrouter
OPENROUTER_API_KEY=your_openrouter_key_here
OPENROUTER_MODEL=deepseek/deepseek-v4-flash
```

You can also switch to OpenAI later with:

```env
AI_PROVIDER=openai
OPENAI_API_KEY=your_openai_key_here
```

4. Start the backend:

```bat
backend\start_backend.bat
```

The backend runs at:

- `http://127.0.0.1:8000`
- Swagger docs: `http://127.0.0.1:8000/docs`

## Frontend Setup

1. Open the [frontend](/C:/Users/Abdullah/Desktop/nafey/frontend) folder.
2. Run:

```bat
frontend\start_frontend.bat
```

This launches the Flutter app in Chrome and points it to:

- `http://127.0.0.1:8000/api`

## One-Click Demo

You can also try:

```bat
run_demo.bat
```

This opens the backend and frontend in separate terminal windows.

## Demo Flow For Teacher

You can show these actions:

1. Open the app and show the default recipes.
2. Add a new recipe manually.
3. Edit that recipe.
4. Delete a recipe.
5. Search a recipe from the AI search box.
6. Save the AI result into the recipe book.

## Important Files

- Backend entry: [backend/app/main.py](/C:/Users/Abdullah/Desktop/nafey/backend/app/main.py)
- AI search logic: [backend/app/services.py](/C:/Users/Abdullah/Desktop/nafey/backend/app/services.py)
- Flutter UI: [frontend/lib/main.dart](/C:/Users/Abdullah/Desktop/nafey/frontend/lib/main.dart)

## Zip

The packaged project zip is:

- [recipe-book-fullstack.zip](/C:/Users/Abdullah/Desktop/nafey/recipe-book-fullstack.zip)
