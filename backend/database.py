import os
from pathlib import Path

from dotenv import dotenv_values, load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker
from sqlalchemy.pool import NullPool

BASE_DIR = Path(__file__).resolve().parent
ENV_PATH = BASE_DIR / ".env"

load_dotenv(dotenv_path=str(ENV_PATH), override=True, encoding="utf-8-sig")
if ENV_PATH.exists():
    for key, value in dotenv_values(ENV_PATH, encoding="utf-8-sig").items():
        normalized_key = key.lstrip("\ufeff")
        if value is not None and normalized_key not in os.environ:
            os.environ[normalized_key] = value

DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    raise RuntimeError("DATABASE_URL no está configurada en el entorno o en .env")

DIRECT_URL = os.getenv("DIRECT_URL") or DATABASE_URL

IS_SQLITE = DATABASE_URL.startswith("sqlite")
USES_PGBOUNCER = "pooler.supabase.com" in DATABASE_URL or ":6543/" in DATABASE_URL

engine = create_engine(
    DATABASE_URL,
    connect_args={
        "check_same_thread": False,
    }
    if IS_SQLITE
    else (
        {"prepare_threshold": None}
        if USES_PGBOUNCER
        else {}
    ),
    pool_pre_ping=not IS_SQLITE,
    poolclass=NullPool if USES_PGBOUNCER else None,
)

SessionLocal = sessionmaker(bind=engine)

Base = declarative_base()

