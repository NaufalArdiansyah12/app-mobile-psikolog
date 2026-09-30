from pathlib import Path
import os
from dotenv import load_dotenv

env_path = Path(__file__).resolve().parent.parent.parent / ".env"
load_dotenv(dotenv_path=env_path)

PORT = int(os.getenv("PORT", 8000))
HOST = os.getenv("HOST", "0.0.0.0")
ENVIRONMENT = os.getenv("ENVIRONMENT", "development")

# 9router Gateway Config
AI_GATEWAY_URL = os.getenv("AI_GATEWAY_URL", "http://localhost:20128/v1")
AI_GATEWAY_KEY = os.getenv("AI_GATEWAY_KEY", "")
AI_MODEL = os.getenv("AI_MODEL", "ag/gemini-3.8-flash-high")

# Supabase Credentials
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
