# Stripe Test Report - RC1

Status: `BLOCKED_EXTERNAL_CONFIG`

No Stripe live mode was used.

## Code-Level Evidence

| Item | Status | Notes |
| --- | --- | --- |
| Billing backend route exists | PASS | `backend/app/routes/billing.py` contains checkout, portal, subscription and usage endpoints. |
| Checkout requires authenticated user | PASS | `create_checkout_session` depends on `require_current_user`. |
| Secret key is backend-only | PASS | Backend reads `STRIPE_SECRET_KEY` from environment. |
| Flutter opens checkout through backend URL | PASS | `mobile/campusai_mobile/lib/services/billing_service.dart`. |
| Customer portal route exists | PASS | `/billing/create-customer-portal-session`. |
| Subscription route exists | PASS | `/billing/subscription/me`. |
| Usage route exists | PASS | `/billing/usage/me`. |

## External Configuration Required

Set these only in backend/runtime secret storage:

- `STRIPE_SECRET_KEY`
- `STRIPE_WEBHOOK_SECRET`
- Plan price IDs: `STRIPE_STUDENT_PRICE_ID`, `STRIPE_TEACHER_PRICE_ID`, `STRIPE_ACCESSIBILITY_PRICE_ID`, `STRIPE_ULTRA_PRICE_ID`
- `APP_SUCCESS_URL`
- `APP_CANCEL_URL`
- `STRIPE_CUSTOMER_PORTAL_RETURN_URL`

## Manual Test Checklist

| Flow | Expected | Status |
| --- | --- | --- |
| Checkout session | Redirects to Stripe test checkout | BLOCKED_EXTERNAL_CONFIG |
| Cancel redirect | Returns to app with cancel state | BLOCKED_EXTERNAL_CONFIG |
| Success redirect | Returns to app with plan query | BLOCKED_EXTERNAL_CONFIG |
| Webhook | Updates subscription record | BLOCKED_EXTERNAL_CONFIG |
| `/billing/subscription/me` | Returns current plan | BLOCKED_EXTERNAL_CONFIG |
| `/billing/usage/me` | Returns scoped usage | BLOCKED_EXTERNAL_CONFIG |
| Customer portal | Opens Stripe portal | BLOCKED_EXTERNAL_CONFIG |

