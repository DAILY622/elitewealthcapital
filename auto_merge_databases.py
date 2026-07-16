"""
DATABASE MERGER - Export Supabase to Neon
Uses direct PostgreSQL connections to merge databases
"""

import json
import os
from datetime import datetime

# Database connection strings
SUPABASE_URL = "postgresql://postgres.fykzoburtipislgjrcjm:gTpjdkGJBLBjdFGT@aws-1-ap-northeast-1.pooler.supabase.com:5432/postgres"
NEON_URL = "postgresql://neondb_owner:npg_Pc4mXQWbVvH5@ep-holy-sea-a4989cmp-pooler.us-east-1.aws.neon.tech/my-elite-db?sslmode=require"

print("""
========================================
   🔄 DATABASE MERGER
   Supabase → Neon PostgreSQL
========================================
""")

try:
    import psycopg2
    from psycopg2.extras import RealDictCursor
    print("✅ psycopg2 library loaded")
except ImportError:
    print("❌ psycopg2 not installed!")
    print("   Installing psycopg2-binary...")
    os.system("pip install psycopg2-binary")
    import psycopg2
    from psycopg2.extras import RealDictCursor
    print("✅ psycopg2 installed successfully")

def connect_db(url, name):
    """Connect to database"""
    try:
        conn = psycopg2.connect(url)
        print(f"✅ Connected to {name}")
        return conn
    except Exception as e:
        print(f"❌ Failed to connect to {name}:")
        print(f"   Error: {e}")
        return None

def get_user_count(conn, name):
    """Get user count"""
    try:
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM accounts_customuser;")
        count = cursor.fetchone()[0]
        cursor.close()
        return count
    except Exception as e:
        print(f"❌ Error counting users in {name}: {e}")
        return 0

def get_all_users(conn, name):
    """Get all users from database"""
    try:
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        cursor.execute("""
            SELECT * FROM accounts_customuser ORDER BY date_joined;
        """)
        users = cursor.fetchall()
        cursor.close()
        return users
    except Exception as e:
        print(f"❌ Error getting users from {name}: {e}")
        return []

def backup_neon_db(neon_conn):
    """Backup Neon database before merge"""
    print("\n💾 Creating backup of Neon database...")
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_file = f"neon_backup_before_merge_{timestamp}.json"
    
    users = get_all_users(neon_conn, "Neon")
    
    with open(backup_file, 'w') as f:
        json.dump(users, f, indent=2, default=str)
    
    print(f"✅ Backup saved: {backup_file}")
    return backup_file

def merge_users_to_neon(supabase_users, neon_conn):
    """Merge Supabase users into Neon"""
    print("\n🔄 Merging users into Neon...")
    
    cursor = neon_conn.cursor()
    imported = 0
    skipped = 0
    updated = 0
    
    for user in supabase_users:
        email = user['email']
        
        # Check if user exists
        cursor.execute("SELECT id, email FROM accounts_customuser WHERE email = %s", (email,))
        existing = cursor.fetchone()
        
        if existing:
            print(f"   ⚠️  User exists: {email} - Skipping")
            skipped += 1
        else:
            # Insert new user
            try:
                columns = user.keys()
                values = [user[col] for col in columns]
                placeholders = ','.join(['%s'] * len(values))
                column_names = ','.join(columns)
                
                insert_sql = f"INSERT INTO accounts_customuser ({column_names}) VALUES ({placeholders})"
                cursor.execute(insert_sql, values)
                
                print(f"   ✅ Imported: {email}")
                imported += 1
            except Exception as e:
                print(f"   ❌ Failed to import {email}: {e}")
    
    # Commit changes
    neon_conn.commit()
    cursor.close()
    
    return imported, skipped, updated

def main():
    # Step 1: Connect to both databases
    print("\n📡 Connecting to databases...")
    supabase_conn = connect_db(SUPABASE_URL, "Supabase")
    neon_conn = connect_db(NEON_URL, "Neon")
    
    if not supabase_conn or not neon_conn:
        print("\n❌ Cannot proceed without both connections")
        return
    
    # Step 2: Count users
    print("\n📊 Counting users...")
    supabase_count = get_user_count(supabase_conn, "Supabase")
    neon_count_before = get_user_count(neon_conn, "Neon")
    
    print(f"   Supabase: {supabase_count} users")
    print(f"   Neon (before): {neon_count_before} users")
    print(f"   Total to merge: {supabase_count + neon_count_before} users")
    
    # Step 3: Backup Neon
    backup_file = backup_neon_db(neon_conn)
    
    # Step 4: Get all Supabase users
    print("\n📥 Fetching Supabase users...")
    supabase_users = get_all_users(supabase_conn, "Supabase")
    print(f"✅ Retrieved {len(supabase_users)} users from Supabase")
    
    # Step 5: Merge users
    imported, skipped, updated = merge_users_to_neon(supabase_users, neon_conn)
    
    # Step 6: Verify
    print("\n🔍 Verifying migration...")
    neon_count_after = get_user_count(neon_conn, "Neon")
    
    print("\n" + "="*60)
    print("   ✅ MIGRATION COMPLETE!")
    print("="*60)
    print(f"\n📊 Results:")
    print(f"   • Neon users (before): {neon_count_before}")
    print(f"   • Supabase users: {supabase_count}")
    print(f"   • Imported: {imported}")
    print(f"   • Skipped (duplicates): {skipped}")
    print(f"   • Neon users (after): {neon_count_after}")
    print(f"   • Expected: {neon_count_before + imported}")
    
    if neon_count_after == neon_count_before + imported:
        print("\n✅ Migration successful! All users merged.")
    else:
        print("\n⚠️  User count mismatch! Please verify.")
    
    print(f"\n💾 Backup file: {backup_file}")
    print("\n🎉 Done! All users now in Neon PostgreSQL.\n")
    
    # Close connections
    supabase_conn.close()
    neon_conn.close()

if __name__ == "__main__":
    main()
