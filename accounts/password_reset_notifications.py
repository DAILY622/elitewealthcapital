"""
Signal handlers for password reset notifications
"""
from django.contrib.auth.signals import user_logged_in
from django.dispatch import receiver
from django.core.mail import EmailMultiAlternatives
from django.template.loader import render_to_string
from django.conf import settings
import logging

logger = logging.getLogger(__name__)


def send_password_reset_confirmation(user, request=None):
    """
    Send password reset confirmation email to user and admin
    Called after successful password reset
    Uses HTML + plain text for maximum email client compatibility
    """
    try:
        domain = settings.ALLOWED_HOSTS[0] if settings.ALLOWED_HOSTS else 'elitewealthcapita.uk'
        
        # ===== SEND TO USER =====
        user_subject = '✅ Your Password Has Been Reset - Elite Wealth Capital'
        
        # Plain text version
        user_text_content = render_to_string('emails/password_reset_success_user.txt', {
            'user': user,
            'domain': domain,
        })
        
        # HTML version
        user_html_content = render_to_string('emails/password_reset_success_user.html', {
            'user': user,
            'domain': domain,
        })
        
        user_email = EmailMultiAlternatives(
            subject=user_subject,
            body=user_text_content,  # Plain text fallback
            from_email=settings.DEFAULT_FROM_EMAIL,
            to=[user.email]
        )
        user_email.attach_alternative(user_html_content, "text/html")
        user_email.send()
        
        logger.info(f'✅ Password reset confirmation sent to user: {user.email}')
        
        # ===== SEND TO ADMIN =====
        admin_subject = f'🔐 Security Alert: Password Reset - {user.email}'
        
        # Plain text version
        admin_text_content = render_to_string('emails/password_reset_success_admin.txt', {
            'user': user,
            'domain': domain,
        })
        
        # HTML version
        admin_html_content = render_to_string('emails/password_reset_success_admin.html', {
            'user': user,
            'domain': domain,
        })
        
        admin_email = EmailMultiAlternatives(
            subject=admin_subject,
            body=admin_text_content,  # Plain text fallback
            from_email=settings.DEFAULT_FROM_EMAIL,
            to=[settings.ADMIN_EMAIL]
        )
        admin_email.attach_alternative(admin_html_content, "text/html")
        admin_email.send()
        
        logger.info(f'✅ Password reset notification sent to admin for user: {user.email}')
        
        return True
        
    except Exception as e:
        logger.error(f'❌ Error sending password reset confirmation: {str(e)}', exc_info=True)
        return False
