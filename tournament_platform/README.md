# Tournament Platform — Django API Backend (Phase 1-3 scaffold)

## What's here
- Custom `User` model (email login) — `accounts`
- `TournamentRole` / `AssistantCapability` — the single role/permission system
- Core models: `organizations`, `tournaments` (Tournament/Category/Court),
  `entries` (Entry, with the partial-unique "one active entry per category" constraint),
  `draws` (Draw/DrawSlot), `matches` (Match, with the `version` optimistic-concurrency field)
- JWT auth endpoints: signup, login, refresh, logout (blacklist), session
- `core/permissions.py` — shared DRF permission classes for the rest of the build

## Run it
```bash
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver
```

Currently configured with sqlite for quick local iteration — switch to the
commented-out Postgres block in `config/settings.py` before doing real
concurrency testing (sqlite doesn't give real row-level locks for
`select_for_update()`, which the draw-generation and scoring logic depend on).

## Verified working
- `POST /api/auth/signup` → creates User + PlayerProfile, returns tokens
- `POST /api/auth/login` → JWT pair
- `GET /api/auth/session` (Bearer token) → user + active roles/capabilities,
  401 without a token
- `POST /api/auth/refresh`, `POST /api/auth/logout` (blacklists refresh token)

## Not yet built (next phases per the build plan)
- Organizations/Tournaments/Categories/Courts CRUD endpoints + serializers
- Entries endpoints (search, pagination, eligibility rules)
- Draw generation service (`select_for_update` + atomic transaction)
- Match scheduling endpoint (conflict detection)
- Channels consumer + live-scoring service
- Celery task + ResultDocument for PDF generation

celery -A config worker --loglevel=info --pool=solo