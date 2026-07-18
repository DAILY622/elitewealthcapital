"""
Custom Django email backend for improved password reset emails
Handles HTML + plain text alternatives with proper email client support
"""
from django.contrib.auth.tokens import default_token_generator
from django.contrib.sites.shortcuts import get_current_site
from django.core.mail import EmailMultiAlternatives
from django.template import loader
from django.utils.encoding import force_bytes
from django.utils.http import urlsafe_base64_encode
from django.conf import settings
import logging

logger = logging.getLogger(__name__)


class EnhancedPasswordResetBackend:
    """
    Enhanced password reset email backend that sends both HTML and plain text
    Improves compatibility with email clients and spam filters
    """

    def send_password_reset_email(self,
                                   email,
                                   subject_template_name,
                                   email_template_name,
                                   context,
                                   from_email,
                                   to_email,
                                   html_email_template_name=None,
                                   extra_email_context=None):
        """
        Send a django.contrib.auth password reset email.
        """
        if extra_email_context is None:
            extra_email_context = {}
        context.update(extra_email_context)

        # Load and render plain text template
        subject = loader.render_to_string(subject_template_name, context)
        # Email subject *must not* contain newlines
        subject = ''.join(subject.splitlines())
        
        body = loader.render_to_string(email_template_name, context)

        # Try to load HTML template (with .html extension)
        email_html = None
        if html_email_template_name is not None:
            try:
                email_html = loader.render_to_string(html_email_template_name, context)
            except Exception as e:
                logger.warning(f"Could not load HTML email template: {str(e)}")

        # Send email with both alternatives
        msg = EmailMultiAlternatives(
            subject=subject,
            body=body,  # Plain text fallback
            from_email=from_email,
            to=[to_email]
        )

        # Attach HTML version if available
        if email_html:
            msg.attach_alternative(email_html, "text/html")

        # Set headers for better deliverability
        msg['X-Priority'] = '3'
        msg['X-MSMail-Priority'] = 'Normal'
        msg['X-Mailer'] = 'Elite Wealth Capital'

        try:
            msg.send(fail_silently=False)
            logger.info(f"✅ Password reset email sent to {to_email}")
            return True
        except Exception as e:
            logger.error(f"❌ Failed to send password reset email to {to_email}: {str(e)}")
            return False


def send_password_reset_email_backend(user, request, site=None):
    """
    Wrapper function to send password reset email with enhanced backend
    
    Args:
        user: User object
        request: HttpRequest object
        site: Site object (optional)
    """
    from django.contrib.sites.shortcuts import get_current_site
    from django.contrib.auth.tokens import default_token_generator
    from django.utils.encoding import force_bytes
    from django.utils.http import urlsafe_base64_encode

    if site is None:
        site = get_current_site(request)

    context = {
        'email': user.email,
        'uid': urlsafe_base64_encode(force_bytes(user.pk)),
        'user': user,
        'token': default_token_generator.make_token(user),
        'site_name': site.name,
        'site_domain': site.domain,
        'protocol': 'https' if request.is_secure() else 'http',
        'domain': settings.ALLOWED_HOSTS[0] if settings.ALLOWED_HOSTS else 'elitewealthcapita.uk',
    }

    # Initialize backend
    backend = EnhancedPasswordResetBackend()

    # Send email with improved backend
    return backend.send_password_reset_email(
        email=user.email,
        subject_template_name='registration/password_reset_subject.txt',
        email_template_name='registration/password_reset_email.txt',  # Plain text
        html_email_template_name='registration/password_reset_email.html',  # HTML
        context=context,
        from_email=settings.DEFAULT_FROM_EMAIL,
        to_email=user.email,
    )
