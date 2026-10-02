import os
import sys
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__))))

from app.core.database import get_supabase
from app.core.config import SUPABASE_URL, SUPABASE_KEY

def migrate_and_seed():
    sp = get_supabase()
    if not sp:
        print("Supabase client not initialized")
        return

    print("Checking Supabase connection...")
    
    # Check psychologists table
    psy_res = sp.table("psychologists").select("*").execute()
    print(f"Psychologists count: {len(psy_res.data)}")
    psychologists = psy_res.data
    first_psy = psychologists[0] if psychologists else None
    print(f"Sample psychologist: {first_psy}")

    # Let's check users table columns by trying to select role
    try:
        users_res = sp.table("users").select("id, nickname, role").limit(1).execute()
        print("users.role column already exists!")
    except Exception as e:
        print(f"Note on users.role column: {e}")

    # Create doctor user in auth admin
    doctor_email = "dokter@mindpal.id"
    doctor_password = "password123"
    doctor_name = "dr. Nadia S., Sp.KJ"

    try:
        # Check if doctor already exists in auth
        auth_users = sp.auth.admin.list_users()
        existing = [u for u in auth_users if u.email == doctor_email]
        
        doctor_user_id = None
        if existing:
            doctor_user_id = existing[0].id
            print(f"Doctor user already exists in Supabase Auth: {doctor_user_id}")
            # Update password if needed
            sp.auth.admin.update_user_by_id(doctor_user_id, {
                "password": doctor_password,
                "user_metadata": {"nickname": doctor_name, "role": "doctor"}
            })
        else:
            created = sp.auth.admin.create_user({
                "email": doctor_email,
                "password": doctor_password,
                "email_confirm": True,
                "user_metadata": {"nickname": doctor_name, "role": "doctor"}
            })
            doctor_user_id = created.user.id
            print(f"Created doctor user in Supabase Auth: {doctor_user_id}")

        # Upsert into public.users
        try:
            sp.table("users").upsert({
                "id": doctor_user_id,
                "device_uuid": doctor_user_id,
                "nickname": doctor_name,
                "role": "doctor"
            }).execute()
            print("Successfully upserted doctor to public.users with role='doctor'")
        except Exception as e:
            # If role column doesn't exist yet, insert without role column
            print(f"Upsert with role failed ({e}), trying without role column...")
            sp.table("users").upsert({
                "id": doctor_user_id,
                "device_uuid": doctor_user_id,
                "nickname": doctor_name
            }).execute()

        # Link psychologist profile if possible
        if first_psy:
            try:
                sp.table("psychologists").update({
                    "user_id": doctor_user_id
                }).eq("id", first_psy["id"]).execute()
                print(f"Linked psychologist {first_psy['name']} to user_id {doctor_user_id}")
            except Exception as e:
                print(f"Link psychologist column update note: {e}")

        print("\n--- DOCTOR CREDENTIALS CREATED ---")
        print(f"Email: {doctor_email}")
        print(f"Password: {doctor_password}")
        print(f"Role: doctor")
        print(f"Name: {doctor_name}")

    except Exception as e:
        print(f"Error creating doctor: {e}")

if __name__ == "__main__":
    migrate_and_seed()
