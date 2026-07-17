# Generated migration

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('accounts', '0003_alter_customuser_account_type'),
    ]

    operations = [
        migrations.AddField(
            model_name='customuser',
            name='notification_sound_enabled',
            field=models.BooleanField(default=True, help_text='Enable/disable notification sounds'),
        ),
    ]
