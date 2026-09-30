from app.core.database import get_supabase

def test_supabase_connection():
    sp = get_supabase()
    if not sp:
        print("FAIL: Supabase client is None")
        return False

    try:
        res = sp.table("psychologists").select("*").execute()
        print(f"SUCCESS: Supabase connected! Psychologists table count: {len(res.data)}")
        return True
    except Exception as e:
        print(f"ERROR: Failed to query Supabase: {e}")
        return False

if __name__ == "__main__":
    test_supabase_connection()
