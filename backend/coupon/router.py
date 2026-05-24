"""
FastAPI Coupon Router.

All endpoints are stateless — FastAPI validates rules and returns results.
Firebase state mutations are triggered by the Flutter client after receiving
a FastAPI decision (except for idempotency checks which read Firestore).
"""
from __future__ import annotations

import logging
from datetime import datetime, timezone
from typing import Any, Dict, List

from fastapi import APIRouter, HTTPException, status
from google.cloud.firestore_v1 import FieldFilter

from .firebase_client import get_firestore, send_fcm_multicast
from .models import (
    AcceptCouponRequest,
    AnalyticsSummary,
    ApplyCouponRequest,
    ApplyResult,
    DeclineCouponRequest,
    EligibilityResult,
    RedeemCouponRequest,
    ValidateCouponRequest,
    ValidationResult,
)
from .validator import apply_coupon, validate_coupon, validate_redemption

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/coupon", tags=["Coupon Engine"])
admin_router = APIRouter(prefix="/admin", tags=["Admin Analytics"])


# ── POST /coupon/validate ──────────────────────────────────────────────────────

@router.post("/validate", response_model=ValidationResult)
async def route_validate_coupon(req: ValidateCouponRequest) -> ValidationResult:
    """
    Validate a coupon code against business rules.
    Called by Flutter checkout before showing discount preview.
    """
    return validate_coupon(req)


# ── POST /coupon/apply ─────────────────────────────────────────────────────────

@router.post("/apply", response_model=ApplyResult)
async def route_apply_coupon(req: ApplyCouponRequest) -> ApplyResult:
    """
    Apply a coupon and return the final computed price breakdown.
    FastAPI is the source of truth — frontend must use this value.
    """
    return apply_coupon(req)


# ── POST /coupon/accept ────────────────────────────────────────────────────────

@router.post("/accept", response_model=Dict[str, Any])
async def route_accept_coupon(req: AcceptCouponRequest) -> Dict[str, Any]:
    """
    Mark a user_coupon as ACCEPTED in Firestore.
    Idempotent — safe to call multiple times.
    """
    db = get_firestore()
    now = datetime.now(timezone.utc)

    ref = db.collection("UserCoupons").document(req.user_coupon_id)
    doc = ref.get()

    if not doc.exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="UserCoupon document not found.",
        )

    data = doc.to_dict() or {}
    current_status = data.get("Status", "PENDING")

    # Idempotency: already accepted → return success without re-writing
    if current_status == "ACCEPTED":
        return {"success": True, "message": "Already accepted.", "status": "ACCEPTED"}

    if current_status in ("DECLINED", "REDEEMED", "EXPIRED"):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Cannot accept a coupon in status: {current_status}",
        )

    ref.update({"Status": "ACCEPTED", "AcceptedAt": now})
    return {"success": True, "message": "Coupon accepted.", "status": "ACCEPTED"}


# ── POST /coupon/decline ───────────────────────────────────────────────────────

@router.post("/decline", response_model=Dict[str, Any])
async def route_decline_coupon(req: DeclineCouponRequest) -> Dict[str, Any]:
    """
    Mark a user_coupon as DECLINED in Firestore.
    Coupon is removed only for this user (global coupon stays intact).
    Idempotent.
    """
    db = get_firestore()
    now = datetime.now(timezone.utc)

    ref = db.collection("UserCoupons").document(req.user_coupon_id)
    doc = ref.get()

    if not doc.exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="UserCoupon document not found.",
        )

    data = doc.to_dict() or {}
    current_status = data.get("Status", "PENDING")

    if current_status == "DECLINED":
        return {"success": True, "message": "Already declined.", "status": "DECLINED"}

    if current_status in ("REDEEMED",):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Cannot decline a coupon that has been redeemed.",
        )

    ref.update({"Status": "DECLINED", "DeclinedAt": now})
    return {"success": True, "message": "Coupon declined.", "status": "DECLINED"}


# ── POST /coupon/redeem ────────────────────────────────────────────────────────

@router.post("/redeem", response_model=ValidationResult)
async def route_redeem_coupon(req: RedeemCouponRequest) -> ValidationResult:
    """
    Final validation gate before order placement.
    Validates coupon rules one last time to prevent race conditions.
    On success, caller (Flutter) should:
      1. Write CouponRedemptions document
      2. Update UserCoupons status → REDEEMED
      3. Increment Coupons.UsageCount via batch write
    FastAPI never writes these — Flutter does, ensuring transactional safety.
    """
    # Check for duplicate redemption in Firestore
    db = get_firestore()
    existing = (
        db.collection("CouponRedemptions")
        .where(filter=FieldFilter("UserId", "==", req.user_id))
        .where(filter=FieldFilter("CouponId", "==", req.coupon_id))
        .where(filter=FieldFilter("OrderId", "==", req.order_id))
        .limit(1)
        .get()
    )
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Coupon already redeemed for this order.",
        )

    result = validate_redemption(req)
    if not result.valid:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=result.message,
        )
    return result


# ── GET /coupon/eligibility/{userId} ──────────────────────────────────────────

@router.get("/eligibility/{user_id}", response_model=EligibilityResult)
async def route_coupon_eligibility(user_id: str) -> EligibilityResult:
    """
    Return list of coupon IDs this user is eligible for.
    Reads UserCoupons collection filtered by userId + status=ACCEPTED.
    """
    db = get_firestore()
    docs = (
        db.collection("UserCoupons")
        .where(filter=FieldFilter("UserId", "==", user_id))
        .where(filter=FieldFilter("Status", "==", "ACCEPTED"))
        .stream()
    )
    eligible_ids: List[str] = [d.to_dict().get("CouponId", "") for d in docs if d.exists]
    eligible_ids = [eid for eid in eligible_ids if eid]

    return EligibilityResult(
        user_id=user_id,
        eligible_coupon_ids=eligible_ids,
        message=f"{len(eligible_ids)} coupon(s) available.",
    )


# ── GET /admin/coupon/analytics ───────────────────────────────────────────────

@admin_router.get("/coupon/analytics", response_model=AnalyticsSummary)
async def route_coupon_analytics() -> AnalyticsSummary:
    """
    Aggregate analytics for the admin dashboard.
    Reads: Coupons, CouponRedemptions, UserCoupons collections.
    """
    db = get_firestore()

    # --- Coupons summary ---
    all_coupons = list(db.collection("Coupons").stream())
    total_coupons = len(all_coupons)
    active_coupons = sum(
        1 for d in all_coupons if (d.to_dict() or {}).get("IsActive", False)
    )

    # --- Redemptions ---
    redemptions = list(db.collection("CouponRedemptions").stream())
    total_redemptions = len(redemptions)
    total_discount_given = sum(
        float((d.to_dict() or {}).get("DiscountAmount", 0)) for d in redemptions
    )

    # --- Acceptance / Decline rates ---
    user_coupons = list(db.collection("UserCoupons").stream())
    total_uc = len(user_coupons)
    accepted = sum(
        1 for d in user_coupons if (d.to_dict() or {}).get("Status") == "ACCEPTED"
    )
    declined = sum(
        1 for d in user_coupons if (d.to_dict() or {}).get("Status") == "DECLINED"
    )
    acceptance_rate = (accepted / total_uc * 100) if total_uc > 0 else 0.0
    decline_rate = (declined / total_uc * 100) if total_uc > 0 else 0.0

    # --- Top coupons by redemption count ---
    top_map: Dict[str, int] = {}
    for d in redemptions:
        cid = (d.to_dict() or {}).get("CouponId", "")
        if cid:
            top_map[cid] = top_map.get(cid, 0) + 1
    top_coupons = [
        {"coupon_id": k, "redemption_count": v}
        for k, v in sorted(top_map.items(), key=lambda x: x[1], reverse=True)[:10]
    ]

    return AnalyticsSummary(
        total_coupons=total_coupons,
        active_coupons=active_coupons,
        total_redemptions=total_redemptions,
        total_discount_given=total_discount_given,
        acceptance_rate=round(acceptance_rate, 2),
        decline_rate=round(decline_rate, 2),
        top_coupons=top_coupons,
    )


# ── POST /coupon/campaign/send ─────────────────────────────────────────────────

campaign_router = APIRouter(prefix="/campaign", tags=["Campaign"])


@campaign_router.post("/send", response_model=Dict[str, Any])
async def route_send_campaign(payload: Dict[str, Any]) -> Dict[str, Any]:
    """
    Send coupon push notifications to targeted users via FCM.
    Payload:
      - coupon_id: str
      - coupon_code: str
      - title: str
      - body: str
      - user_tokens: list[str]   (FCM tokens)
      - user_ids: list[str]
    Writes UserCoupons documents for each user (PENDING state).
    """
    db = get_firestore()
    coupon_id: str = payload.get("coupon_id", "")
    coupon_code: str = payload.get("coupon_code", "")
    title: str = payload.get("title", "New Offer!")
    body: str = payload.get("body", f"You have a new coupon: {coupon_code}")
    user_tokens: List[str] = payload.get("user_tokens", [])
    user_ids: List[str] = payload.get("user_ids", [])
    campaign_id: str = payload.get("campaign_id", "")

    if not coupon_id or not user_ids:
        raise HTTPException(status_code=400, detail="coupon_id and user_ids are required.")

    now = datetime.now(timezone.utc)

    # Write UserCoupons docs in batch (idempotent — skip if already exists)
    batch = db.batch()
    written = 0
    for uid in user_ids:
        # Check if already sent
        existing = (
            db.collection("UserCoupons")
            .where(filter=FieldFilter("UserId", "==", uid))
            .where(filter=FieldFilter("CouponId", "==", coupon_id))
            .limit(1)
            .get()
        )
        if existing:
            continue  # idempotent skip
        ref = db.collection("UserCoupons").document()
        batch.set(ref, {
            "UserId": uid,
            "CouponId": coupon_id,
            "CampaignId": campaign_id,
            "Status": "PENDING",
            "ReceivedAt": now,
            "AcceptedAt": None,
            "DeclinedAt": None,
            "RedeemedAt": None,
        })
        written += 1

    if written > 0:
        batch.commit()

    # Send FCM notifications in chunks of 500
    sent_count = 0
    failed_count = 0
    if user_tokens:
        chunk_size = 500
        for i in range(0, len(user_tokens), chunk_size):
            chunk = user_tokens[i : i + chunk_size]
            try:
                resp = send_fcm_multicast(
                    tokens=chunk,
                    title=title,
                    body=body,
                    data={
                        "type": "COUPON_OFFER",
                        "coupon_id": coupon_id,
                        "coupon_code": coupon_code,
                        "campaign_id": campaign_id,
                        "deep_link": f"mediai://coupons/{coupon_id}",
                    },
                )
                sent_count += resp.success_count
                failed_count += resp.failure_count
            except Exception as e:
                logger.error(f"FCM multicast error: {e}")
                failed_count += len(chunk)

    return {
        "success": True,
        "user_coupons_written": written,
        "fcm_sent": sent_count,
        "fcm_failed": failed_count,
        "message": f"Campaign dispatched to {len(user_ids)} users.",
    }
