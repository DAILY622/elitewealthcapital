"""
Django management command to sync user portfolios to Cloudflare D1

Usage: python manage.py sync_d1
"""

from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from investments.models import Investment
from django.db.models import Sum
import subprocess
import os

User = get_user_model()

class Command(BaseCommand):
    help = 'Sync user portfolios from PostgreSQL to Cloudflare D1'

    def handle(self, *args, **options):
        self.stdout.write("="*60)
        self.stdout.write("🔄 SYNCING USERS TO CLOUDFLARE D1")
        self.stdout.write("="*60 + "\n")
        
        users = User.objects.all().order_by('id')
        total = users.count()
        
        self.stdout.write(f"Found {total} users\n")
        
        sql_statements = []
        sql_statements.append("DELETE FROM portfolios;")
        sql_statements.append("DELETE FROM investment_history;")
        
        for idx, user in enumerate(users, 1):
            self.stdout.write(f"[{idx}/{total}] {user.email}...", ending='')
            
            # Calculate stats
            total_invested = Investment.objects.filter(
                user=user,
                status__in=['active', 'completed']
            ).aggregate(Sum('amount'))['amount__sum'] or 0
            
            total_profit = Investment.objects.filter(
                user=user,
                status='completed'
            ).aggregate(Sum('profit'))['profit__sum'] or 0
            
            active = Investment.objects.filter(user=user, status='active').count()
            completed = Investment.objects.filter(user=user, status='completed').count()
            
            # Insert portfolio
            sql = f"""INSERT INTO portfolios (user_id, total_invested, total_profit, active_investments, completed_investments)
VALUES ({user.id}, {float(total_invested)}, {float(total_profit)}, {active}, {completed})
ON CONFLICT(user_id) DO UPDATE SET total_invested={float(total_invested)}, total_profit={float(total_profit)}, active_investments={active}, completed_investments={completed};"""
            sql_statements.append(sql)
            
            # Insert history
            for inv in Investment.objects.filter(user=user, status='completed').order_by('-created_at')[:10]:
                plan_name = inv.plan.name.replace("'", "''") if inv.plan else 'Unknown'
                start_date = inv.created_at.strftime('%Y-%m-%d')
                end_date = inv.maturity_date.strftime('%Y-%m-%d') if inv.maturity_date else ''
                
                hist_sql = f"""INSERT INTO investment_history (user_id, plan_name, amount, profit, roi_percentage, start_date, end_date, status)
VALUES ({user.id}, '{plan_name}', {float(inv.amount)}, {float(inv.profit or 0)}, {float(inv.plan.roi_percentage if inv.plan else 0)}, '{start_date}', '{end_date}', 'completed');"""
                sql_statements.append(hist_sql)
            
            self.stdout.write(" ✅")
        
        # Save SQL
        output_file = 'sync_users_to_d1.sql'
        with open(output_file, 'w') as f:
            f.write('\n\n'.join(sql_statements))
        
        self.stdout.write(f"\n✅ Generated {len(sql_statements)} SQL statements")
        self.stdout.write(f"✅ Saved to: {output_file}\n")
        self.stdout.write("\n🚀 Run this to upload to D1:")
        self.stdout.write("  cd cloudflare-worker")
        self.stdout.write(f"  wrangler d1 execute elite-portfolios --remote --file=../{output_file}\n")
