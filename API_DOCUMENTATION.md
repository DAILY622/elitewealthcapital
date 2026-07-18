# Elite Wealth Capital API Documentation

## Overview

The Elite Wealth Capital API provides comprehensive endpoints for managing investments, KYC verification, virtual cards, deposits, withdrawals, and loans. All API endpoints are protected and require authentication.

## Base URL

- **Production**: `https://elitewealthcapita.uk/api/`
- **Development**: `http://localhost:8000/api/`

## Authentication

All API requests must include an Authorization header with a valid authentication token:

```
Authorization: Bearer <token>
```

## API Documentation

### Interactive Documentation

The API provides interactive documentation accessible at:

- **Swagger UI**: `/api/docs/` - Interactive API explorer with "Try it out" capability
- **ReDoc**: `/api/redoc/` - Alternative API documentation viewer
- **OpenAPI Schema**: `/api/schema/` - Raw OpenAPI 3.0 schema in JSON format

## API Endpoints

### Investments

#### Get Investment Plans
- **Endpoint**: `GET /investments/api/plans/`
- **Description**: Retrieve all active investment plans
- **Query Parameters**:
  - `category`: Filter by category (crypto, real_estate, oil_gas, agriculture, solar, stocks)
  - `page`: Pagination page number
- **Response**: List of investment plans with details

#### Create Investment
- **Endpoint**: `POST /investments/invest/`
- **Description**: Create a new investment
- **Request Body**:
  ```json
  {
    "plan_id": 1,
    "amount": 1000.00
  }
  ```
- **Response**: Investment confirmation with details

#### Get My Investments
- **Endpoint**: `GET /investments/my-investments/`
- **Description**: Retrieve user's investment portfolio
- **Response**: List of user investments with status

#### Investment Dashboard
- **Endpoint**: `GET /investments/performance-dashboard/`
- **Description**: Get comprehensive portfolio analytics
- **Query Parameters**:
  - `timeframe`: 30, 90, or 365 days (default: 365)
- **Response**: Portfolio metrics, charts data, and performance analytics

### Virtual Cards

#### Get Card Details
- **Endpoint**: `GET /investments/cards/`
- **Description**: Retrieve user's virtual card information
- **Response**: Card details including masked number and balance

#### Freeze Card
- **Endpoint**: `POST /investments/cards/freeze/`
- **Description**: Freeze the virtual card
- **Response**: Confirmation message

#### Unfreeze Card
- **Endpoint**: `POST /investments/cards/unfreeze/`
- **Description**: Unfreeze the virtual card
- **Response**: Confirmation message

#### Top-up Card
- **Endpoint**: `POST /investments/cards/topup/`
- **Description**: Transfer funds to virtual card
- **Request Body**:
  ```json
  {
    "amount": 500.00
  }
  ```
- **Response**: Transaction confirmation

#### Replace Card
- **Endpoint**: `POST /investments/cards/replace/`
- **Description**: Request a new card with new number
- **Response**: New card details

#### Card Transactions
- **Endpoint**: `GET /investments/cards/transactions/`
- **Description**: Get transaction history
- **Query Parameters**:
  - `page`: Pagination page number
- **Response**: List of card transactions

### Deposits

#### Create Deposit
- **Endpoint**: `POST /investments/deposit/`
- **Description**: Initiate a deposit
- **Request Body**:
  ```json
  {
    "amount": 1000.00,
    "payment_method": "crypto",
    "crypto_type": "BTC"
  }
  ```
- **Response**: Deposit confirmation with details

#### Get Deposit Status
- **Endpoint**: `GET /investments/deposit-status/<id>/`
- **Description**: Check deposit status
- **Response**: Current deposit status and details

### KYC Verification

#### Upload KYC Documents
- **Endpoint**: `POST /kyc/upload/`
- **Description**: Submit KYC documents for verification
- **Request Body**: Form data with:
  - `document_type`: Type of document (passport, drivers_license, national_id, etc.)
  - `front_image`: Front side image (multipart/form-data)
  - `back_image`: Back side image (multipart/form-data)
  - `selfie_image`: Selfie image (multipart/form-data)
- **Response**: Submission confirmation

#### AI KYC Verification
- **Endpoint**: `POST /kyc/ai-verify/`
- **Description**: Submit document for AI verification
- **Request Body**: Form data with:
  - `document_type`: Document type
  - `document_image`: Document image (multipart/form-data)
- **Response**: Verification results with confidence score

#### Get KYC Status
- **Endpoint**: `GET /kyc/status/`
- **Description**: Get current KYC verification status
- **Response**: KYC document details and status

### Loans

#### Apply for Loan
- **Endpoint**: `POST /investments/loans/`
- **Description**: Submit loan application
- **Request Body**:
  ```json
  {
    "amount": 5000.00,
    "duration_days": 90,
    "purpose": "Business expansion"
  }
  ```
- **Response**: Loan application confirmation

#### Get My Loans
- **Endpoint**: `GET /investments/loans/`
- **Description**: Get all user loans
- **Response**: List of loans with status

#### Repay Loan
- **Endpoint**: `POST /investments/loans/<id>/repay/`
- **Description**: Make a loan payment
- **Request Body**:
  ```json
  {
    "amount": 500.00
  }
  ```
- **Response**: Payment confirmation

### Withdrawals

#### Create Withdrawal
- **Endpoint**: `POST /investments/withdraw/`
- **Description**: Request a withdrawal
- **Request Body**:
  ```json
  {
    "amount": 500.00,
    "withdrawal_method": "crypto",
    "crypto_type": "BTC",
    "wallet_address": "1A1z7agoat..."
  }
  ```
- **Response**: Withdrawal confirmation

## Error Responses

### Common Error Codes

| Status | Code | Message |
|--------|------|---------|
| 400 | `BAD_REQUEST` | Invalid request parameters |
| 401 | `UNAUTHORIZED` | Missing or invalid authentication |
| 403 | `FORBIDDEN` | Insufficient permissions |
| 404 | `NOT_FOUND` | Resource not found |
| 429 | `RATE_LIMITED` | Too many requests |
| 500 | `SERVER_ERROR` | Internal server error |

### Error Response Format

```json
{
  "error": "error_code",
  "message": "Human readable error message",
  "details": {
    "field": ["error for this field"]
  }
}
```

## Rate Limiting

API requests are rate limited to prevent abuse:

- **Standard Users**: 100 requests per hour
- **Premium Users**: 500 requests per hour
- **VIP Users**: 2000 requests per hour

Rate limit information is included in response headers:
- `X-RateLimit-Limit`: Total requests allowed
- `X-RateLimit-Remaining`: Requests remaining
- `X-RateLimit-Reset`: Unix timestamp when limit resets

## Pagination

List endpoints support pagination:

```
GET /investments/api/plans/?page=1&limit=20
```

Response includes:
```json
{
  "count": 100,
  "next": "https://api.example.com/investments/api/plans/?page=2",
  "previous": null,
  "results": [...]
}
```

## Testing API Endpoints

### Using cURL

```bash
# Get investment plans
curl -H "Authorization: Bearer YOUR_TOKEN" \
  https://elitewealthcapita.uk/api/investments/

# Create deposit
curl -X POST \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"amount": 1000, "payment_method": "crypto"}' \
  https://elitewealthcapita.uk/api/deposit/
```

### Using Python Requests

```python
import requests

headers = {"Authorization": "Bearer YOUR_TOKEN"}

# Get investments
response = requests.get(
    "https://elitewealthcapita.uk/api/investments/",
    headers=headers
)
print(response.json())

# Create deposit
response = requests.post(
    "https://elitewealthcapita.uk/api/deposit/",
    headers=headers,
    json={"amount": 1000, "payment_method": "crypto"}
)
print(response.json())
```

### Using JavaScript Fetch

```javascript
// Get investment plans
const response = await fetch(
  'https://elitewealthcapita.uk/api/investments/',
  {
    method: 'GET',
    headers: {
      'Authorization': 'Bearer YOUR_TOKEN',
      'Content-Type': 'application/json'
    }
  }
);
const data = await response.json();
console.log(data);
```

## Webhooks (Coming Soon)

Real-time updates via webhooks for:
- Investment status changes
- KYC verification results
- Deposit confirmations
- Loan approvals/rejections

## API Versioning

The current API version is **v1**. Future versions will be available at `/api/v2/`, etc.

## Support

For API support and questions:
- **Email**: `api@elitewealthcapita.uk`
- **Documentation**: `https://elitewealthcapita.uk/api/docs/`
- **Issues**: Report via admin dashboard

## Security

- All API traffic must use HTTPS
- Tokens expire after 24 hours
- Never share API tokens publicly
- Use environment variables for sensitive data
- Implement proper error handling in production

## Changelog

### v1.0.0 (Current)
- Initial API release
- Investment management endpoints
- Virtual card endpoints
- KYC verification endpoints
- Deposit/withdrawal endpoints
- Loan management endpoints
- Swagger/OpenAPI documentation
