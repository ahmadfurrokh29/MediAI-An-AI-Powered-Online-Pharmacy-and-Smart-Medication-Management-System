"""
Pydantic request / response models for the Coupon Engine.
FastAPI is stateless — it never stores data; only validates and computes.
"""
from __future__ import annotations

from datetime import datetime
from enum import Enum
from typing import Any, Dict, List, Optional

from pydantic import BaseModel, Field, field_validator


# ─────────────────────────── Enums ────────────────────────────────────────────

class DiscountType(str, Enum):
    PERCENTAGE = "PERCENTAGE"
    FLAT = "FLAT"


class CouponStatus(str, Enum):
    PENDING = "PENDING"
    ACCEPTED = "ACCEPTED"
    DECLINED = "DECLINED"
    REDEEMED = "REDEEMED"
    EXPIRED = "EXPIRED"


# ─────────────────────── Shared Coupon Snapshot ───────────────────────────────

class CouponSnapshot(BaseModel):
    """
    Mirrors the Firestore Coupons document fields that FastAPI needs to
    perform validation.  Passed in by the Flutter client so FastAPI
    stays stateless.
    """
    id: str
    code: str
    discount_value: float = Field(alias="DiscountValue")
    type: DiscountType = Field(alias="Type")
    is_active: bool = Field(alias="IsActive")
    start_date: Optional[datetime] = Field(None, alias="StartDate")
    end_date: Optional[datetime] = Field(None, alias="EndDate")
    usage_limit: int = Field(alias="UsageLimit")
    usage_count: int = Field(0, alias="UsageCount")
    per_user_limit: int = Field(1, alias="PerUserLimit")
    min_order_amount: float = Field(0.0, alias="MinOrderAmount")
    stackable: bool = Field(False, alias="Stackable")

    model_config = {"populate_by_name": True}


# ─────────────────────── Request Models ───────────────────────────────────────

class ValidateCouponRequest(BaseModel):
    coupon_code: str
    user_id: str
    order_subtotal: float
    user_redemption_count: int = 0          # how many times this user already redeemed
    coupon: CouponSnapshot                  # snapshot from Firestore passed by client


class ApplyCouponRequest(BaseModel):
    coupon_code: str
    user_id: str
    order_subtotal: float
    shipping_fee: float
    tax_fee: float
    coupon: CouponSnapshot
    user_redemption_count: int = 0


class AcceptCouponRequest(BaseModel):
    user_id: str
    coupon_id: str
    user_coupon_id: str                     # Firestore doc ID in UserCoupons


class DeclineCouponRequest(BaseModel):
    user_id: str
    coupon_id: str
    user_coupon_id: str


class RedeemCouponRequest(BaseModel):
    user_id: str
    coupon_id: str
    order_id: str
    coupon: CouponSnapshot
    order_subtotal: float
    user_redemption_count: int = 0


# ─────────────────────── Response Models ──────────────────────────────────────

class ValidationResult(BaseModel):
    valid: bool
    error_code: Optional[str] = None
    message: str
    discount_amount: float = 0.0


class ApplyResult(BaseModel):
    valid: bool
    message: str
    error_code: Optional[str] = None
    coupon_code: str = ""
    discount_amount: float = 0.0
    subtotal: float = 0.0
    shipping_fee: float = 0.0
    tax_fee: float = 0.0
    final_total: float = 0.0


class EligibilityResult(BaseModel):
    user_id: str
    eligible_coupon_ids: List[str] = []
    message: str = ""


class AnalyticsSummary(BaseModel):
    total_coupons: int = 0
    active_coupons: int = 0
    total_redemptions: int = 0
    total_discount_given: float = 0.0
    acceptance_rate: float = 0.0
    decline_rate: float = 0.0
    top_coupons: List[Dict[str, Any]] = []
