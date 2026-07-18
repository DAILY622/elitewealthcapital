from django.shortcuts import render, get_object_or_404
from django.contrib.auth.decorators import login_required
from django.http import JsonResponse
from django.views.decorators.http import require_POST
from django.core.paginator import Paginator
from .models import Notification


@login_required
def notification_list(request):
    """List all notifications for the current user"""
    notifications = Notification.objects.filter(user=request.user).order_by('-created_at')
    
    # Filter by read status
    filter_status = request.GET.get('status', 'all')
    if filter_status == 'unread':
        notifications = notifications.filter(is_read=False)
    elif filter_status == 'read':
        notifications = notifications.filter(is_read=True)
    
    # Pagination
    paginator = Paginator(notifications, 20)
    page = request.GET.get('page', 1)
    notifications_page = paginator.get_page(page)
    
    # Count unread
    unread_count = Notification.objects.filter(user=request.user, is_read=False).count()
    
    context = {
        'notifications': notifications_page,
        'unread_count': unread_count,
        'filter_status': filter_status,
    }
    
    return render(request, 'notifications/list.html', context)


@login_required
@require_POST
def mark_as_read(request, notification_id):
    """Mark a single notification as read"""
    notification = get_object_or_404(Notification, id=notification_id, user=request.user)
    notification.mark_as_read()
    
    return JsonResponse({'success': True, 'notification_id': notification_id})


@login_required
@require_POST
def mark_all_as_read(request):
    """Mark all notifications as read"""
    Notification.mark_all_as_read(request.user)
    
    return JsonResponse({'success': True})


@login_required
@require_POST
def delete_notification(request, notification_id):
    """Delete a notification"""
    notification = get_object_or_404(Notification, id=notification_id, user=request.user)
    notification.delete()
    
    return JsonResponse({'success': True, 'notification_id': notification_id})


@login_required
def unread_count(request):
    """Get count of unread notifications (for AJAX)"""
    count = Notification.objects.filter(user=request.user, is_read=False).count()
    return JsonResponse({'count': count})


@login_required
def recent_notifications(request):
    """Get recent notifications (for dropdown)"""
    notifications = Notification.objects.filter(
        user=request.user
    ).order_by('-created_at')[:5]
    
    data = [{
        'id': n.id,
        'title': n.title,
        'message': n.message[:100],
        'type': n.notification_type,
        'is_read': n.is_read,
        'action_url': n.action_url,
        'created_at': n.created_at.isoformat(),
    } for n in notifications]
    
    unread_count = Notification.objects.filter(user=request.user, is_read=False).count()
    
    return JsonResponse({
        'notifications': data,
        'unread_count': unread_count
    })


@login_required
def test_sounds(request):
    """Test notification sounds page"""
    return render(request, 'notifications/test_sounds.html')


@login_required
def notification_preferences(request):
    """User notification preferences page"""
    from .models import NotificationPreference
    from django.contrib import messages
    
    prefs = NotificationPreference.get_or_create_for_user(request.user)
    
    if request.method == 'POST':
        # Update email preferences
        prefs.email_on_deposit = request.POST.get('email_on_deposit') == 'on'
        prefs.email_on_withdrawal = request.POST.get('email_on_withdrawal') == 'on'
        prefs.email_on_investment = request.POST.get('email_on_investment') == 'on'
        prefs.email_on_profit = request.POST.get('email_on_profit') == 'on'
        prefs.email_on_kyc = request.POST.get('email_on_kyc') == 'on'
        prefs.email_on_referral = request.POST.get('email_on_referral') == 'on'
        prefs.email_on_security = request.POST.get('email_on_security') == 'on'
        
        # Update push preferences
        prefs.push_enabled = request.POST.get('push_enabled') == 'on'
        prefs.push_on_deposit = request.POST.get('push_on_deposit') == 'on'
        prefs.push_on_withdrawal = request.POST.get('push_on_withdrawal') == 'on'
        prefs.push_on_investment = request.POST.get('push_on_investment') == 'on'
        prefs.push_on_profit = request.POST.get('push_on_profit') == 'on'
        prefs.push_on_kyc = request.POST.get('push_on_kyc') == 'on'
        prefs.push_on_referral = request.POST.get('push_on_referral') == 'on'
        
        # Update SMS preferences
        prefs.sms_enabled = request.POST.get('sms_enabled') == 'on'
        prefs.sms_on_deposit = request.POST.get('sms_on_deposit') == 'on'
        prefs.sms_on_withdrawal = request.POST.get('sms_on_withdrawal') == 'on'
        prefs.sms_on_security = request.POST.get('sms_on_security') == 'on'
        
        # Update sound and digest preferences
        prefs.sound_enabled = request.POST.get('sound_enabled') == 'on'
        prefs.daily_digest = request.POST.get('daily_digest') == 'on'
        prefs.weekly_digest = request.POST.get('weekly_digest') == 'on'
        prefs.marketing_emails = request.POST.get('marketing_emails') == 'on'
        
        prefs.save()
        messages.success(request, 'Notification preferences updated successfully!')
        
        return JsonResponse({'success': True, 'message': 'Preferences saved'})
    
    context = {
        'prefs': prefs,
    }
    
    return render(request, 'notifications/preferences.html', context)