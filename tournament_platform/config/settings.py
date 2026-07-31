import os
from datetime import timedelta
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = os.environ.get("DJANGO_SECRET_KEY", "dev-secret-key-change-in-production")
DEBUG = os.environ.get("DJANGO_DEBUG", "True").lower() in ("true", "1", "yes")
ALLOWED_HOSTS = os.environ.get("DJANGO_ALLOWED_HOSTS", "*").split(",")

INSTALLED_APPS = [
    "corsheaders",
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "rest_framework",
    "rest_framework_simplejwt",
    "rest_framework_simplejwt.token_blacklist",
    "django_filters",
    "accounts",
    "organizations",
    "tournaments",
    "entries",
    "draws",
    "matches",
    "results",
    "players",
    "core",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "corsheaders.middleware.CorsMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"

# Automatically add trailing slash to URLs
APPEND_SLASH = True

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.debug",
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "config.wsgi.application"
ASGI_APPLICATION = "config.asgi.application"

AUTH_USER_MODEL = "accounts.User"

# Database configuration - supports both SQLite (dev) and PostgreSQL (production)
# Set DATABASE_URL environment variable for PostgreSQL:
#   postgresql://user:password@localhost:5432/tournament_platform
# Or set individual environment variables:
#   DB_ENGINE=django.db.backends.postgresql
#   DB_NAME=tournament_platform
#   DB_USER=postgres
#   DB_PASSWORD=yourpassword
#   DB_HOST=localhost
#   DB_PORT=5432

db_url = os.environ.get("DATABASE_URL", "")

if db_url.startswith("postgres"):
    # Use DATABASE_URL format (e.g., postgresql://user:pass@localhost:5432/dbname)
    import dj_database_url
    DATABASES = {"default": dj_database_url.parse(db_url)}
else:
    # Fallback to individual settings
    db_engine = os.environ.get("DB_ENGINE", "")
    if db_engine == "django.db.backends.postgresql":
        DATABASES = {
            "default": {
                "ENGINE": "django.db.backends.postgresql",
                "NAME": os.environ.get("DB_NAME", "tournament_platform"),
                "USER": os.environ.get("DB_USER", "postgres"),
                "PASSWORD": os.environ.get("DB_PASSWORD", ""),
                "HOST": os.environ.get("DB_HOST", "localhost"),
                "PORT": os.environ.get("DB_PORT", "5432"),
            }
        }
    else:
        # Default to SQLite for local development
        DATABASES = {
            "default": {
                "ENGINE": "django.db.backends.sqlite3",
                "NAME": BASE_DIR / "db.sqlite3",
            }
        }

AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator"},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]

LANGUAGE_CODE = "en-us"
TIME_ZONE = "UTC"
USE_I18N = True
USE_TZ = True

STATIC_URL = "static/"
MEDIA_URL = "media/"
MEDIA_ROOT = BASE_DIR / "media"
DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": [
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ],
    "DEFAULT_PERMISSION_CLASSES": ["rest_framework.permissions.IsAuthenticated"],
    "DEFAULT_PAGINATION_CLASS": "rest_framework.pagination.PageNumberPagination",
    "PAGE_SIZE": 20,
    "DEFAULT_FILTER_BACKENDS": ["django_filters.rest_framework.DjangoFilterBackend"],
}

SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(minutes=30),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=7),
    "ROTATE_REFRESH_TOKENS": True,
    "BLACKLIST_AFTER_ROTATION": True,
}

CORS_ALLOW_ALL_ORIGINS = True  # dev only — never in production

# --- Channels / Celery / Redis: wire these in once you get to the live-
# scoring and PDF phases (see build plan §7 and §9). Left commented so this
# scaffold runs standalone without Redis being up.
CHANNEL_LAYERS = {
    "default": {"BACKEND": "channels_redis.core.RedisChannelLayer",
                 "CONFIG": {"hosts": [("localhost", 6379)]}}
}
CELERY_BROKER_URL = "redis://localhost:6379/1"
CELERY_RESULT_BACKEND = "redis://localhost:6379/2"
