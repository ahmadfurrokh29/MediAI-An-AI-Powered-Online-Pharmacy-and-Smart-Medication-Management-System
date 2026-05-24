"""
Firebase Admin SDK singleton.
Initializes once and provides Firestore + FCM clients.
"""
from __future__ import annotations

import os
import firebase_admin
from firebase_admin import credentials, firestore, messaging
from google.cloud.firestore_v1 import Client as FirestoreClient

_app: firebase_admin.App | None = None


def _init_app() -> firebase_admin.App:
    """
    Initialize Firebase Admin.  Looks for a service-account JSON file
    whose path is stored in FIREBASE_SERVICE_ACCOUNT env var.
    Falls back to Application Default Credentials (ADC) so the app
    also works on GCP / Cloud Run without a key file.
    """
    global _app
    if _app is not None:
        return _app

    sa_path = os.getenv("FIREBASE_SERVICE_ACCOUNT")
    if sa_path and os.path.exists(sa_path):
        cred = credentials.Certificate(sa_path)
    else:
        cred = credentials.ApplicationDefault()

    _app = firebase_admin.initialize_app(cred)
    return _app


def get_firestore() -> FirestoreClient:
    _init_app()
    return firestore.client()


def send_fcm_notification(
    *,
    token: str,
    title: str,
    body: str,
    data: dict[str, str] | None = None,
) -> str:
    """Send a single-device FCM push notification. Returns message_id."""
    _init_app()
    message = messaging.Message(
        notification=messaging.Notification(title=title, body=body),
        data=data or {},
        token=token,
    )
    return messaging.send(message)


def send_fcm_multicast(
    *,
    tokens: list[str],
    title: str,
    body: str,
    data: dict[str, str] | None = None,
) -> messaging.BatchResponse:
    """Send push notifications to up to 500 devices at once."""
    _init_app()
    message = messaging.MulticastMessage(
        notification=messaging.Notification(title=title, body=body),
        data=data or {},
        tokens=tokens,
    )
    return messaging.send_each_for_multicast(message)
