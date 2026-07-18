"""
CLOUDFLARE WORKER INTEGRATION FOR DJANGO

This module provides functions to interact with the Cloudflare Worker
that provides KV caching, D1 database, and Workers AI features.

Setup:
1. Add to settings.py:
   CLOUDFLARE_WORKER_URL = env('CLOUDFLARE_WORKER_URL', default='')

2. Add to render.yaml:
   - key: CLOUDFLARE_WORKER_URL
     value: https://elite-wealth-worker.YOUR_SUBDOMAIN.workers.dev

3. Use in views:
   from integrations.cloudflare import CloudflareService
   
   prices = CloudflareService.get_crypto_prices()
   fraud_check = CloudflareService.check_fraud(user, deposit)
"""

import requests
import logging
from django.conf import settings
from django.core.cache import cache
from decimal import Decimal

logger = logging.getLogger(__name__)

# Worker URL from settings
WORKER_URL = getattr(settings, 'CLOUDFLARE_WORKER_URL', '')

class CloudflareService:
    """Service class for Cloudflare Worker integration"""
    
    @staticmethod
    def is_enabled():
        """Check if Cloudflare Worker is configured"""
        return bool(WORKER_URL)
    
    @staticmethod
    def get_crypto_prices():
        """
        Get crypto prices from KV cache (60s TTL)
        
        Returns:
            dict: {
                'BTC': {'price': 100000, 'change_24h': 5.2},
                'ETH': {'price': 5000, 'change_24h': 3.1},
                ...
            }
        
        Falls back to CoinGecko API if Worker fails
        """
        if not WORKER_URL:
            logger.warning('CLOUDFLARE_WORKER_URL not set, using fallback')
            return CloudflareService._fallback_coingecko()
        
        try:
            response = requests.get(
                f'{WORKER_URL}/api/prices',
                timeout=5
            )
            response.raise_for_status()
            data = response.json()
            
            logger.info(f"Crypto prices fetched from {data.get('source', 'unknown')}")
            return data
            
        except requests.RequestException as e:
            logger.error(f'Cloudflare Worker price fetch failed: {e}')
            return CloudflareService._fallback_coingecko()
    
    @staticmethod
    def _fallback_coingecko():
        """Fallback to direct CoinGecko API call"""
        try:
            # Check Django cache first (5 min TTL)
            cached = cache.get('crypto_prices_fallback')
            if cached:
                return cached
            
            response = requests.get(
                'https://api.coingecko.com/api/v3/simple/price',
                params={
                    'ids': 'bitcoin,ethereum,binancecoin,cardano,ripple',
                    'vs_currencies': 'usd',
                    'include_24hr_change': 'true'
                },
                timeout=10
            )
            response.raise_for_status()
            data = response.json()
            
            # Transform to our format
            prices = {
                'BTC': {
                    'price': data.get('bitcoin', {}).get('usd', 0),
                    'change_24h': data.get('bitcoin', {}).get('usd_24h_change', 0)
                },
                'ETH': {
                    'price': data.get('ethereum', {}).get('usd', 0),
                    'change_24h': data.get('ethereum', {}).get('usd_24h_change', 0)
                },
                'BNB': {
                    'price': data.get('binancecoin', {}).get('usd', 0),
                    'change_24h': data.get('binancecoin', {}).get('usd_24h_change', 0)
                },
                'ADA': {
                    'price': data.get('cardano', {}).get('usd', 0),
                    'change_24h': data.get('cardano', {}).get('usd_24h_change', 0)
                },
                'XRP': {
                    'price': data.get('ripple', {}).get('usd', 0),
                    'change_24h': data.get('ripple', {}).get('usd_24h_change', 0)
                },
                'source': 'fallback'
            }
            
            # Cache for 5 minutes
            cache.set('crypto_prices_fallback', prices, 300)
            return prices
            
        except Exception as e:
            logger.error(f'CoinGecko fallback failed: {e}')
            return {}
    
    @staticmethod
    def check_fraud(user, deposit):
        """
        Check if deposit is potentially fraudulent using Workers AI
        
        Args:
            user: Django User instance
            deposit: Deposit model instance
        
        Returns:
            dict: {
                'risk_score': 0-100,
                'flagged': True/False,
                'reason': 'explanation',
                'ai_analysis': 'AI reasoning'
            }
        """
        if not WORKER_URL:
            logger.warning('CLOUDFLARE_WORKER_URL not set, skipping fraud check')
            return {
                'risk_score': 0,
                'flagged': False,
                'reason': 'Worker not configured'
            }
        
        try:
            from django.utils import timezone
            from investments.models import Deposit
            from django.db.models import Avg
            
            # Calculate user deposit stats
            account_age_days = (timezone.now() - user.date_joined).days
            deposit_count = Deposit.objects.filter(
                user=user,
                status='confirmed'
            ).count()
            avg_deposit = Deposit.objects.filter(
                user=user,
                status='confirmed'
            ).aggregate(Avg('amount'))['amount__avg'] or 0
            
            # Prepare payload
            payload = {
                'user_id': user.id,
                'amount': float(deposit.amount),
                'country': getattr(deposit, 'country', 'Unknown'),
                'account_age_days': account_age_days,
                'deposit_count': deposit_count,
                'avg_deposit': float(avg_deposit)
            }
            
            # Call Worker
            response = requests.post(
                f'{WORKER_URL}/api/fraud-check',
                json=payload,
                timeout=10
            )
            response.raise_for_status()
            result = response.json()
            
            logger.info(f"Fraud check for deposit {deposit.id}: risk_score={result.get('risk_score')}")
            return result
            
        except Exception as e:
            logger.error(f'Cloudflare fraud check failed: {e}')
            return {
                'risk_score': 0,
                'flagged': False,
                'reason': f'Check failed: {str(e)}'
            }
    
    @staticmethod
    def extract_kyc_data(image_base64):
        """
        Extract data from KYC document (passport/ID) using Workers AI OCR
        
        Args:
            image_base64: Base64-encoded image (with or without data URI prefix)
        
        Returns:
            dict: {
                'full_name': 'John Smith',
                'date_of_birth': '1990-05-15',
                'document_number': 'AB1234567',
                'expiry_date': '2030-12-31',
                'nationality': 'US'
            }
        """
        if not WORKER_URL:
            logger.warning('CLOUDFLARE_WORKER_URL not set, skipping KYC extraction')
            return {'error': 'Worker not configured'}
        
        try:
            # Ensure base64 has data URI prefix
            if not image_base64.startswith('data:'):
                image_base64 = f'data:image/jpeg;base64,{image_base64}'
            
            payload = {'image': image_base64}
            
            response = requests.post(
                f'{WORKER_URL}/api/kyc-extract',
                json=payload,
                timeout=15
            )
            response.raise_for_status()
            result = response.json()
            
            logger.info(f"KYC extraction: {result.get('full_name', 'Unknown')}")
            return result
            
        except Exception as e:
            logger.error(f'Cloudflare KYC extraction failed: {e}')
            return {'error': str(e)}
    
    @staticmethod
    def analyze_sentiment(text):
        """
        Analyze crypto news sentiment using Workers AI
        
        Args:
            text: News headline or article text
        
        Returns:
            dict: {
                'sentiment': 'POSITIVE' | 'NEGATIVE' | 'NEUTRAL',
                'score': 0.0-1.0,
                'recommendation': 'BULLISH' | 'BEARISH' | 'NEUTRAL'
            }
        """
        if not WORKER_URL:
            return {
                'sentiment': 'NEUTRAL',
                'score': 0.5,
                'recommendation': 'NEUTRAL'
            }
        
        try:
            payload = {'text': text[:500]}  # Limit to 500 chars
            
            response = requests.post(
                f'{WORKER_URL}/api/sentiment',
                json=payload,
                timeout=5
            )
            response.raise_for_status()
            result = response.json()
            
            logger.info(f"Sentiment analysis: {result.get('sentiment')} ({result.get('score')})")
            return result
            
        except Exception as e:
            logger.error(f'Cloudflare sentiment analysis failed: {e}')
            return {
                'sentiment': 'NEUTRAL',
                'score': 0.5,
                'recommendation': 'NEUTRAL'
            }
    
    @staticmethod
    def get_portfolio(user_id):
        """
        Get user portfolio from D1 edge database
        
        Args:
            user_id: User ID
        
        Returns:
            dict: {
                'portfolio': {...},
                'history': [...],
                'watchlist': [...]
            }
        """
        if not WORKER_URL:
            return {
                'portfolio': None,
                'history': [],
                'watchlist': []
            }
        
        try:
            response = requests.get(
                f'{WORKER_URL}/api/portfolio/{user_id}',
                timeout=5
            )
            response.raise_for_status()
            return response.json()
            
        except Exception as e:
            logger.error(f'Cloudflare portfolio fetch failed: {e}')
            return {
                'portfolio': None,
                'history': [],
                'watchlist': []
            }


# Example usage in views.py:
"""
from integrations.cloudflare import CloudflareService

# In crypto ticker view
def crypto_ticker_api(request):
    prices = CloudflareService.get_crypto_prices()
    return JsonResponse(prices)

# In deposit view
def deposit_view(request):
    if request.method == 'POST':
        form = DepositForm(request.POST, request.FILES)
        if form.is_valid():
            deposit = form.save(commit=False)
            deposit.user = request.user
            deposit.save()
            
            # Run fraud check
            fraud_check = CloudflareService.check_fraud(request.user, deposit)
            if fraud_check.get('flagged'):
                deposit.status = 'review_required'
                deposit.fraud_score = fraud_check['risk_score']
                deposit.fraud_reason = fraud_check['reason']
                deposit.save()
                
                messages.warning(
                    request,
                    f'Your deposit is under review for security. Reason: {fraud_check["reason"]}'
                )
            else:
                messages.success(request, 'Deposit submitted successfully!')
            
            return redirect('investments:deposit_status', pk=deposit.id)

# In KYC view
def kyc_upload(request):
    if request.method == 'POST' and request.FILES.get('document'):
        import base64
        
        # Convert uploaded file to base64
        doc_file = request.FILES['document']
        file_data = doc_file.read()
        b64_data = base64.b64encode(file_data).decode('utf-8')
        
        # Extract data
        extracted = CloudflareService.extract_kyc_data(b64_data)
        
        if 'error' not in extracted:
            # Auto-fill form
            return render(request, 'kyc/form.html', {
                'extracted_data': extracted
            })
"""
