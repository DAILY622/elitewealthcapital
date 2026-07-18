from django.db import models
from django.conf import settings
from django.utils import timezone


class NotificationPreference(models.Model):
    """User notification preferences"""
    
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL, 
        on_delete=models.CASCADE, 
        related_name='notification_preferences'
    )
    
    # Email notifications
    email_on_deposit = models.BooleanField(default=True, help_text='Email when deposit is approved')
    email_on_withdrawal = models.BooleanField(default=True, help_text='Email when withdrawal is processed')
    email_on_investment = models.BooleanField(default=True, help_text='Email when investment is created')
    email_on_profit = models.BooleanField(default=True, help_text='Email on profit credited')
    email_on_kyc = models.BooleanField(default=True, help_text='Email on KYC status change')
    email_on_referral = models.BooleanField(default=True, help_text='Email when someone uses your referral')
    email_on_security = models.BooleanField(default=True, help_text='Email on security alerts')
    
    # Push notifications
    push_enabled = models.BooleanField(default=False, help_text='Enable browser push notifications')
    push_on_deposit = models.BooleanField(default=True)
    push_on_withdrawal = models.BooleanField(default=True)
    push_on_investment = models.BooleanField(default=True)
    push_on_profit = models.BooleanField(default=False)
    push_on_kyc = models.BooleanField(default=True)
    push_on_referral = models.BooleanField(default=True)
    
    # SMS notifications (if implemented)
    sms_enabled = models.BooleanField(default=False, help_text='Enable SMS notifications')
    sms_on_deposit = models.BooleanField(default=False)
    sms_on_withdrawal = models.BooleanField(default=True)
    sms_on_security = models.BooleanField(default=True)
    
    # Notification sounds
    sound_enabled = models.BooleanField(default=True, help_text='Play sound for notifications')
    
    # Digest emails
    daily_digest = models.BooleanField(default=False, help_text='Send daily summary email')
    weekly_digest = models.BooleanField(default=False, help_text='Send weekly summary email')
    
    # Marketing
    marketing_emails = models.BooleanField(default=True, help_text='Receive promotional emails')
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = 'Notification Preference'
        verbose_name_plural = 'Notification Preferences'
    
    def __str__(self):
        return f"Preferences for {self.user.email}"
    
    @classmethod
    def get_or_create_for_user(cls, user):
        """Get or create preferences for a user"""
        prefs, created = cls.objects.get_or_create(user=user)
        return prefs


class Notification(models.Model):
    """User notifications"""
    
    TYPE_CHOICES = [
        ('info', 'Information'),
        ('success', 'Success'),
        ('warning', 'Warning'),
        ('error', 'Error'),
        ('transaction', 'Transaction'),
        ('investment', 'Investment'),
        ('system', 'System'),
    ]
    
    CATEGORY_CHOICES = [
        ('general', 'General'),
        ('financial', 'Financial'),
        ('security', 'Security'),
        ('promotional', 'Promotional'),
    ]
    
    PRIORITY_CHOICES = [
        ('low', 'Low'),
        ('normal', 'Normal'),
        ('high', 'High'),
        ('urgent', 'Urgent'),
    ]
    
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='notifications')
    title = models.CharField(max_length=255)
    message = models.TextField()
    
    # Classification
    notification_type = models.CharField(max_length=20, choices=TYPE_CHOICES, default='info')
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES, default='general')
    priority = models.CharField(max_length=20, choices=PRIORITY_CHOICES, default='normal')
    
    # Status
    is_read = models.BooleanField(default=False)
    read_at = models.DateTimeField(null=True, blank=True)
    email_sent = models.BooleanField(default=False)
    
    # Action
    action_url = models.CharField(max_length=500, blank=True, help_text='Optional URL for CTA')
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        verbose_name = 'Notification'
        verbose_name_plural = 'Notifications'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', 'is_read']),
            models.Index(fields=['user', '-created_at']),
        ]
    
    def __str__(self):
        return f"{self.user.email} - {self.title}"
    
    def mark_as_read(self):
        """Mark notification as read"""
        if not self.is_read:
            self.is_read = True
            self.read_at = timezone.now()
            self.save(update_fields=['is_read', 'read_at'])
    
    @classmethod
    def mark_all_as_read(cls, user):
        """Mark all user notifications as read"""
        cls.objects.filter(user=user, is_read=False).update(
            is_read=True,
            read_at=timezone.now()
        )
    
    @classmethod
    def create_notification(cls, user, title, message, notification_type='info', category='general', priority='normal', action_url=''):
        """Helper method to create notifications"""
        return cls.objects.create(
            user=user,
            title=title,
            message=message,
            notification_type=notification_type,
            category=category,
            priority=priority,
            action_url=action_url
        )
