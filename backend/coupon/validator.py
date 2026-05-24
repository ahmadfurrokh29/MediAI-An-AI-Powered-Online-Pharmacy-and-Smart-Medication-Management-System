"""
Coupon Validation & Discount Calculation Engine.

FastAPI is the source of truth for all pricing.
NEVER trust frontend calculations.
"""
from __future__ import annotations

from datetime import datetime, timezone
from typing import Tuple

from .models import (
    ApplyCouponRequest,
    ApplyResult,
    CouponSnapshot,
    DiscountType,
    RedeemCouponRequest,
    ValidateCouponRequest,
    ValidationResult,
)

# ── Error Codes ────────────────────────────────────────────────────────────────
ERR_INACTIVE = "COUPON_INACTIVE"
ERR_EXPIRED = "COUPON_EXPIRED"
ERR_NOT_STARTED = "COUPON_NOT_STARTED"
ERR_USAGE_LIMIT = "USAGE_LIMIT_REACHED"
ERR_PER_USER_LIMIT = "PER_USER_LIMIT_REACHED"
ERR_MIN_ORDER = "MIN_ORDER_NOT_MET"
ERR_ALREADY_REDEEMED = "ALREADY_REDEEMED"


def _now_utc() -> datetime:
    return datetime.now(timezone.utc)


# ── Core Validator ─────────────────────────────────────────────────────────────

def _validate_coupon_rules(
    coupon: CouponSnapshot,
    order_subtotal: float,
    user_redemption_count: int,
) -> Tuple[bool, str, str]:
    """
    Returns (is_valid, error_code, message).
    All checks are stateless — caller provides the data.
    """
    now = _now_utc()

    # 1. Active check
    if not coupon.is_active:
        return False, ERR_INACTIVE, "This coupon is no longer active."

    # 2. Start date check
    if coupon.start_date and coupon.start_date.tzinfo is None:
        start = coupon.start_date.replace(tzinfo=timezone.utc)
    else:
        start = coupon.start_date
    if start and now < start:
        return False, ERR_NOT_STARTED, "This coupon is not yet valid."

    # 3. Expiry check
    if coupon.end_date and coupon.end_date.tzinfo is None:
        end = coupon.end_date.replace(tzinfo=timezone.utc)
    else:
        end = coupon.end_date
    if end and now > end:
        return False, ERR_EXPIRED, "This coupon has expired."

    # 4. Global usage limit
    if coupon.usage_limit > 0 and coupon.usage_count >= coupon.usage_limit:
        return False, ERR_USAGE_LIMIT, "This coupon has reached its usage limit."

    # 5. Per-user limit
    if coupon.per_user_limit > 0 and user_redemption_count >= coupon.per_user_limit:
        return False, ERR_PER_USER_LIMIT, "You have already used this coupon the maximum number of times."

    # 6. Minimum order amount
    if coupon.min_order_amount > 0 and order_subtotal < coupon.min_order_amount:
        return (
            False,
            ERR_MIN_ORDER,
            f"Minimum order amount of Rs {coupon.min_order_amount:.0f} required.",
        )

    return True, "", "Coupon is valid."


def _calculate_discount(coupon: CouponSnapshot, order_subtotal: float) -> float:
    """Compute the discount amount. Always returns a non-negative value."""
    if coupon.type == DiscountType.PERCENTAGE:
        discount = order_subtotal * (coupon.discount_value / 100.0)
    else:
        discount = float(coupon.discount_value)

    # Discount cannot exceed order subtotal
    return min(discount, order_subtotal)


# ── Public API ─────────────────────────────────────────────────────────────────

def validate_coupon(req: ValidateCouponRequest) -> ValidationResult:
    is_valid, error_code, message = _validate_coupon_rules(
        req.coupon,
        req.order_subtotal,
        req.user_redemption_count,
    )
    if not is_valid:
        return ValidationResult(valid=False, error_code=error_code, message=message)

    discount = _calculate_discount(req.coupon, req.order_subtotal)
    return ValidationResult(valid=True, message=message, discount_amount=discount)


def apply_coupon(req: ApplyCouponRequest) -> ApplyResult:
    is_valid, error_code, message = _validate_coupon_rules(
        req.coupon,
        req.order_subtotal,
        req.user_redemption_count,
    )
    if not is_valid:
        return ApplyResult(
            valid=False,
            message=message,
            error_code=error_code,
            coupon_code=req.coupon_code,
            subtotal=req.order_subtotal,
            shipping_fee=req.shipping_fee,
            tax_fee=req.tax_fee,
            final_total=req.order_subtotal + req.shipping_fee + req.tax_fee,
        )

    discount = _calculate_discount(req.coupon, req.order_subtotal)
    discounted_subtotal = req.order_subtotal - discount
    final_total = discounted_subtotal + req.shipping_fee + req.tax_fee

    return ApplyResult(
        valid=True,
        message=f"Coupon applied! You save Rs {discount:.0f}.",
        coupon_code=req.coupon_code,
        discount_amount=discount,
        subtotal=req.order_subtotal,
        shipping_fee=req.shipping_fee,
        tax_fee=req.tax_fee,
        final_total=max(final_total, 0.0),
    )


def validate_redemption(req: RedeemCouponRequest) -> ValidationResult:
    """
    Final server-side gate before an order is placed.
    Validates the coupon one last time to prevent race conditions / replay attacks.
    """
    is_valid, error_code, message = _validate_coupon_rules(
        req.coupon,
        req.order_subtotal,
        req.user_redemption_count,
    )
    if not is_valid:
        return ValidationResult(valid=False, error_code=error_code, message=message)

    discount = _calculate_discount(req.coupon, req.order_subtotal)
    return ValidationResult(valid=True, message="Redemption approved.", discount_amount=discount)
