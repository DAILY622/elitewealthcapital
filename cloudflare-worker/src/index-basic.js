/**
 * ELITE WEALTH CAPITAL - CLOUDFLARE WORKER
 * 
 * Services:
 * - KV: Crypto price caching
 * - D1: User portfolios at the edge
 * - Workers AI: Fraud detection, KYC OCR, Sentiment analysis
 */

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    
    // CORS headers for Django origin
    const corsHeaders = {
      'Access-Control-Allow-Origin': 'https://portal.elitewealthcapita.uk',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    };

    // Handle preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    try {
      // Route handlers
      if (url.pathname === '/api/health') {
        return jsonResponse({ status: 'ok', services: ['KV', 'D1', 'AI'] }, corsHeaders);
      }

      if (url.pathname === '/api/prices') {
        return await getCryptoPrices(env, corsHeaders);
      }

      if (url.pathname.startsWith('/api/portfolio/')) {
        const userId = url.pathname.split('/')[3];
        return await getPortfolio(env, userId, corsHeaders);
      }

      if (url.pathname === '/api/fraud-check' && request.method === 'POST') {
        return await checkFraud(request, env, corsHeaders);
      }

      if (url.pathname === '/api/kyc-extract' && request.method === 'POST') {
        return await extractKYC(request, env, corsHeaders);
      }

      if (url.pathname === '/api/sentiment' && request.method === 'POST') {
        return await analyzeSentiment(request, env, corsHeaders);
      }

      // 404 for unknown routes
      return jsonResponse({ error: 'Not Found' }, corsHeaders, 404);

    } catch (error) {
      console.error('Worker error:', error);
      return jsonResponse({ error: error.message }, corsHeaders, 500);
    }
  }
};

/**
 * Get crypto prices with KV caching
 */
async function getCryptoPrices(env, corsHeaders) {
  const CACHE_KEY = 'crypto_prices';
  const CACHE_TTL = 60; // 60 seconds

  try {
    // Try KV cache first
    const cached = await env.ELITE_CACHE.get(CACHE_KEY, { type: 'json' });
    if (cached) {
      return jsonResponse({
        ...cached,
        source: 'cache',
        cached_at: cached.timestamp
      }, corsHeaders);
    }

    // Fetch fresh data from CoinGecko
    const response = await fetch(
      'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum,binancecoin,cardano,ripple&vs_currencies=usd&include_24hr_change=true'
    );
    
    const data = await response.json();
    
    // Transform to our format
    const prices = {
      BTC: {
        price: data.bitcoin?.usd || 0,
        change_24h: data.bitcoin?.usd_24h_change || 0
      },
      ETH: {
        price: data.ethereum?.usd || 0,
        change_24h: data.ethereum?.usd_24h_change || 0
      },
      BNB: {
        price: data.binancecoin?.usd || 0,
        change_24h: data.binancecoin?.usd_24h_change || 0
      },
      ADA: {
        price: data.cardano?.usd || 0,
        change_24h: data.cardano?.usd_24h_change || 0
      },
      XRP: {
        price: data.ripple?.usd || 0,
        change_24h: data.ripple?.usd_24h_change || 0
      },
      timestamp: new Date().toISOString()
    };

    // Store in KV with TTL
    await env.ELITE_CACHE.put(CACHE_KEY, JSON.stringify(prices), {
      expirationTtl: CACHE_TTL
    });

    return jsonResponse({
      ...prices,
      source: 'api'
    }, corsHeaders);

  } catch (error) {
    console.error('Price fetch error:', error);
    return jsonResponse({ error: 'Failed to fetch prices' }, corsHeaders, 500);
  }
}

/**
 * Get user portfolio from D1
 */
async function getPortfolio(env, userId, corsHeaders) {
  try {
    // Get portfolio summary
    const portfolio = await env.DB.prepare(
      'SELECT * FROM portfolios WHERE user_id = ?'
    ).bind(userId).first();

    // Get investment history
    const history = await env.DB.prepare(
      'SELECT * FROM investment_history WHERE user_id = ? ORDER BY created_at DESC LIMIT 20'
    ).bind(userId).all();

    // Get watchlist
    const watchlist = await env.DB.prepare(
      'SELECT * FROM watchlists WHERE user_id = ?'
    ).bind(userId).all();

    return jsonResponse({
      portfolio: portfolio || { user_id: userId, total_invested: 0, total_profit: 0 },
      history: history.results || [],
      watchlist: watchlist.results || []
    }, corsHeaders);

  } catch (error) {
    console.error('D1 query error:', error);
    return jsonResponse({ error: 'Database query failed' }, corsHeaders, 500);
  }
}

/**
 * Fraud detection using Workers AI
 */
async function checkFraud(request, env, corsHeaders) {
  try {
    const body = await request.json();
    const { user_id, amount, country, account_age_days, deposit_count, avg_deposit } = body;

    // Build fraud detection prompt
    const prompt = `Analyze this deposit for fraud risk:
- User ID: ${user_id}
- Deposit Amount: $${amount}
- Country: ${country}
- Account Age: ${account_age_days} days
- Previous Deposits: ${deposit_count}
- Average Deposit: $${avg_deposit}

Red flags to check:
1. New account (<7 days) with large deposit (>$5000)
2. First deposit significantly higher than average
3. High-risk country
4. Unusual patterns

Respond ONLY with a JSON object (no markdown):
{
  "risk_score": 0-100,
  "flagged": true/false,
  "reason": "brief explanation"
}`;

    // Call Workers AI
    const ai = await env.AI.run('@cf/meta/llama-3.1-8b-instruct', {
      messages: [{ role: 'user', content: prompt }],
      max_tokens: 150
    });

    // Parse AI response
    let result;
    try {
      const response_text = ai.response || ai.result?.response || '';
      // Extract JSON from response (remove markdown formatting)
      const jsonMatch = response_text.match(/\{[\s\S]*\}/);
      result = jsonMatch ? JSON.parse(jsonMatch[0]) : {
        risk_score: 0,
        flagged: false,
        reason: 'AI parsing failed'
      };
    } catch (parseError) {
      console.error('AI response parsing error:', parseError);
      result = {
        risk_score: 50,
        flagged: false,
        reason: 'Unable to parse AI response'
      };
    }

    // Apply rule-based scoring as fallback
    let risk_score = result.risk_score || 0;
    let flags = [];

    if (account_age_days < 7 && amount > 5000) {
      risk_score = Math.max(risk_score, 75);
      flags.push('New account with large deposit');
    }

    if (deposit_count === 0 && amount > 1000) {
      risk_score = Math.max(risk_score, 60);
      flags.push('First-time large deposit');
    }

    if (avg_deposit > 0 && amount > avg_deposit * 3) {
      risk_score = Math.max(risk_score, 70);
      flags.push('3x higher than average');
    }

    return jsonResponse({
      risk_score,
      flagged: risk_score > 65,
      reason: flags.length > 0 ? flags.join('; ') : result.reason,
      ai_analysis: result.reason
    }, corsHeaders);

  } catch (error) {
    console.error('Fraud check error:', error);
    return jsonResponse({ error: 'Fraud check failed' }, corsHeaders, 500);
  }
}

/**
 * KYC OCR using Workers AI Vision
 */
async function extractKYC(request, env, corsHeaders) {
  try {
    const body = await request.json();
    const { image } = body;

    if (!image) {
      return jsonResponse({ error: 'Image required' }, corsHeaders, 400);
    }

    // Extract base64 data
    const base64Data = image.includes('base64,') ? image.split('base64,')[1] : image;
    const imageBytes = Uint8Array.from(atob(base64Data), c => c.charCodeAt(0));

    // Call Workers AI Vision model
    const ai = await env.AI.run('@cf/meta/llama-3.2-11b-vision-instruct', {
      image: Array.from(imageBytes),
      prompt: `Extract the following information from this ID/passport document:
- Full Name
- Date of Birth (format: YYYY-MM-DD)
- Document Number
- Expiry Date (format: YYYY-MM-DD)
- Nationality

Respond ONLY with JSON (no markdown):
{
  "full_name": "...",
  "date_of_birth": "YYYY-MM-DD",
  "document_number": "...",
  "expiry_date": "YYYY-MM-DD",
  "nationality": "..."
}`,
      max_tokens: 200
    });

    // Parse AI response
    let extracted;
    try {
      const response_text = ai.response || ai.result?.response || '';
      const jsonMatch = response_text.match(/\{[\s\S]*\}/);
      extracted = jsonMatch ? JSON.parse(jsonMatch[0]) : {
        error: 'Failed to extract data'
      };
    } catch (parseError) {
      console.error('OCR parsing error:', parseError);
      extracted = {
        error: 'Failed to parse document',
        raw_response: ai.response || 'No response'
      };
    }

    return jsonResponse(extracted, corsHeaders);

  } catch (error) {
    console.error('KYC extraction error:', error);
    return jsonResponse({ error: 'OCR extraction failed' }, corsHeaders, 500);
  }
}

/**
 * Sentiment analysis using Workers AI
 */
async function analyzeSentiment(request, env, corsHeaders) {
  try {
    const body = await request.json();
    const { text } = body;

    if (!text) {
      return jsonResponse({ error: 'Text required' }, corsHeaders, 400);
    }

    // Call Workers AI sentiment model
    const ai = await env.AI.run('@cf/huggingface/distilbert-sst-2-int8', {
      text: text
    });

    // Determine recommendation based on sentiment
    let recommendation = 'NEUTRAL';
    let sentiment = 'NEUTRAL';
    let score = 0.5;

    if (ai.length > 0) {
      const result = ai[0];
      sentiment = result.label === 'POSITIVE' ? 'POSITIVE' : result.label === 'NEGATIVE' ? 'NEGATIVE' : 'NEUTRAL';
      score = result.score;

      if (sentiment === 'POSITIVE' && score > 0.8) {
        recommendation = 'BULLISH';
      } else if (sentiment === 'NEGATIVE' && score > 0.8) {
        recommendation = 'BEARISH';
      }
    }

    return jsonResponse({
      sentiment,
      score,
      recommendation,
      text: text.substring(0, 100) + (text.length > 100 ? '...' : '')
    }, corsHeaders);

  } catch (error) {
    console.error('Sentiment analysis error:', error);
    return jsonResponse({ error: 'Sentiment analysis failed' }, corsHeaders, 500);
  }
}

/**
 * Helper: JSON response with CORS
 */
function jsonResponse(data, corsHeaders, status = 200) {
  return new Response(JSON.stringify(data, null, 2), {
    status,
    headers: {
      'Content-Type': 'application/json',
      ...corsHeaders
    }
  });
}
