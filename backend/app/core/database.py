from typing import Optional
from app.core.config import SUPABASE_URL, SUPABASE_KEY

supabase_client = None

if SUPABASE_URL and SUPABASE_KEY and not SUPABASE_URL.startswith("https://your-project"):
    try:
        from supabase import create_client, Client
        supabase_client: Optional[Client] = create_client(SUPABASE_URL, SUPABASE_KEY)
        print(f"Connected to Supabase: {SUPABASE_URL}")
    except Exception as e:
        print(f"Warning: Failed to init Supabase client: {e}")

def get_supabase():
    return supabase_client
