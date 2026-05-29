from dotenv import load_dotenv
from pathlib import Path
from supabase import create_client, Client

import os


BASE_DIR = Path(__file__).resolve().parent.parent.parent

load_dotenv(BASE_DIR / ".env")
load_dotenv(BASE_DIR / ".env.supabase")


SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY", "")


def get_supabase_client() -> Client:
    if not SUPABASE_URL or not SUPABASE_ANON_KEY:
        raise ValueError(
            "Faltan SUPABASE_URL o SUPABASE_ANON_KEY."
        )

    return create_client(
        SUPABASE_URL,
        SUPABASE_ANON_KEY,
    )
