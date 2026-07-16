"""
Database Migration Script: Merge Supabase + Neon databases
Consolidates all users from both databases into Neon
"""

import psycopg2
from psycopg2.extras import RealDictCursor
import json
from datetime import datetime

# Database URLs
SUPABASE_URL = "postgresql://postgres.fykzoburtipislgjrcjm:gTpjdkGJBLBjdFGT@aws-1-ap-northeast-1.pooler.supabase.com:5432/postgres"
NEON_URL = "postgresql://neondb_owner:npg_Pc4mXQWbVvH5@ep-holy-sea-a4989cmp-pooler.us-east-1.aws.neon.tech/my-elite-db?sslmode=require"

def connect_db(url, name):
    """Connect to database"""
    try:
        conn = psycopg2.connect(url)
        print(f"✅ Connected to {name}")
        return conn
    except Exception as e:
        print(f"❌ Failed to connect to {name}: {e}")
        return None

def count_users(conn, db_name):
    """Count users in database"""
    try:
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM accounts_customuser;")
        count = cursor.fetchone()[0]
        print(f"   {db_name}: {count} users")
        cursor.close()
        return count
    except Exception as e:
        print(f"   Error counting users in {db_name}: {e}")
        return 0

def get_all_users(conn, db_name):
    """Get all users from database"""
    try:
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        cursor.execute("""
            SELECT 
                id, email, password, last_login, is_superuser, is_staff, is_active,
                full_name, phone, country, profile_image,
                balance, invested_amount, total_profit, total_withdrawn, referral_bonus,
                referral_code, referred_by_id, account_type, kyc_status,
                two_fa_enabled, two_fa_secret, email_verified,
                email_verification_token, email_verification_sent_at,
                password_reset_token, password_reset_sent_at,
                failed_login_attempts, locked_until,
                has_virtual_card, card_status, card_type, card_number, card_expiry, card_cvv,
                card_pin, card_limit, card_balance, card_issued_at, card_activated_at,
                date_joined, last_activity
            FROM accounts_customuser
            ORDER BY date_joined;
        """)
        users = cursor.fetchall()
        cursor.close()
        print(f"   ✅ Retrieved {len(users)} users from {db_name}")
        return users
    except Exception as e:
        print(f"   ❌ Error retrieving users from {db_name}: {e}")
        return []

def main():
    print("\n" + "="*60)
    print("   🔄 DATABASE MERGER - Supabase + Neon")
    print("="*60 + "\n")
    
    # Connect to both databases
    print("📡 Connecting to databases...")
    supabase_conn = connect_db(SUPABASE_URL, "Supabase")
    neon_conn = connect_db(NEON_URL, "Neon")
    
    if not supabase_conn or not neon_conn:
        print("\n❌ Cannot proceed without both database connections")
        return
    
    # Count users in both databases
    print("\n📊 Counting users...")
    supabase_count = count_users(supabase_conn, "Supabase")
    neon_count = count_users(neon_conn, "Neon")
    
    total = supabase_count + neon_count
    print(f"\n   Total users to merge: {total}")
    
    # Get all users from both databases
    print("\n📥 Retrieving all users...")
    supabase_users = get_all_users(supabase_conn, "Supabase")
    neon_users = get_all_users(neon_conn, "Neon")
    
    # Save to JSON for inspection
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    print("\n💾 Saving user data to JSON files...")
    with open(f"supabase_users_{timestamp}.json", 'w') as f:
        json.dump(supabase_users, f, indent=2, default=str)
        print(f"   ✅ Saved: supabase_users_{timestamp}.json")
    
    with open(f"neon_users_{timestamp}.json", 'w') as f:
        json.dump(neon_users, f, indent=2, default=str)
        print(f"   ✅ Saved: neon_users_{timestamp}.json")
    
    # Show summary
    print("\n" + "="*60)
    print("   📊 MIGRATION SUMMARY")
    print("="*60)
    print(f"\n✅ Supabase Database: {len(supabase_users)} users exported")
    print(f"✅ Neon Database: {len(neon_users)} users exported")
    print(f"📈 Total Members: {len(supabase_users) + len(neon_users)} users")
    
    # Show top 5 users from each database
    if supabase_users:
        print("\n🔵 Top 5 Supabase Users:")
        for i, user in enumerate(supabase_users[:5], 1):
            print(f"   {i}. {user['full_name']} ({user['email']})")
    
    if neon_users:
        print("\n🟢 Top 5 Neon Users:")
        for i, user in enumerate(neon_users[:5], 1):
            print(f"   {i}. {user['full_name']} ({user['email']})")
    
    print("\n" + "="*60)
    print("   ✅ EXPORT COMPLETE!")
    print("="*60 + "\n")
    
    # Close connections
    supabase_conn.close()
    neon_conn.close()
    
    print("📁 Files created:")
    print(f"   • supabase_users_{timestamp}.json")
    print(f"   • neon_users_{timestamp}.json")
    print("\n🎯 Next: Review the JSON files and prepare merge strategy\n")

if __name__ == "__main__":
    main()
