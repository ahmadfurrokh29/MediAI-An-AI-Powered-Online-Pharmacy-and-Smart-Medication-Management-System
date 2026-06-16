"""
Conversation state management for multi-turn symptom assessment.

The base chatbot is stateless (one request -> one reply). The symptom triage
engine, however, needs to remember what it has already asked and what the user
has answered across several messages. This module provides that memory.

Design:
  * State is keyed by a client-supplied `session_id` (the Flutter app generates
    one per conversation and echoes it on every request).
  * Storage is in-memory (sessions are short-lived) and thread-safe.
  * Sessions auto-expire after SESSION_TTL_SECONDS of inactivity so abandoned
    assessments don't leak memory.

Nothing here is symptom-specific — it's a generic per-session scratchpad that
the triage engine drives. That keeps it reusable for any future multi-turn flow.
"""
from __future__ import annotations

import logging
import threading
import time
from dataclasses import dataclass, field
from enum import Enum
from typing import Dict, Optional

logger = logging.getLogger(__name__)

# Sessions idle for longer than this are discarded.
SESSION_TTL_SECONDS = 30 * 60  # 30 minutes


class TriageState(str, Enum):
    """The symptom-assessment state machine.

    Flow:
        ASSESSMENT_STARTED
          → GATHERING_INFORMATION   (asking the workflow questions)
          → ASSESSMENT_COMPLETE     (summary produced)
          → WAITING_FOR_MEDICATION_CONSENT  (asked "want medicine info?")
          → MEDICATION_RECOMMENDATION_STAGE (user said yes)
          → SESSION_CLOSED
    """
    ASSESSMENT_STARTED             = "assessment_started"
    GATHERING_INFORMATION          = "gathering_information"
    ASSESSMENT_COMPLETE            = "assessment_complete"
    WAITING_FOR_MEDICATION_CONSENT = "waiting_for_medication_consent"
    MEDICATION_RECOMMENDATION_STAGE = "medication_recommendation_stage"
    SESSION_CLOSED                 = "session_closed"


@dataclass
class TriageSession:
    """
    Per-session triage scratchpad.

    symptom     : the symptom that started the assessment (e.g. "headache")
    workflow    : the workflow key resolved for that symptom
    state       : current TriageState
    step_index  : which workflow question we're on (0-based)
    awaiting    : the key of the answer we're currently expecting
    collected   : map of question-key -> user's answer
    """
    session_id: str
    symptom:    str = ""
    workflow:   str = ""
    state:      TriageState = TriageState.ASSESSMENT_STARTED
    step_index: int = 0
    awaiting:   Optional[str] = None
    collected:  Dict[str, str] = field(default_factory=dict)
    created_at: float = field(default_factory=time.time)
    updated_at: float = field(default_factory=time.time)

    def touch(self) -> None:
        self.updated_at = time.time()

    def is_active(self) -> bool:
        """True while an assessment is in progress (anything but fully closed)."""
        return self.state != TriageState.SESSION_CLOSED


class ConversationStore:
    """Thread-safe, in-memory, TTL-expiring session store (singleton)."""

    _instance: Optional["ConversationStore"] = None
    _instance_lock = threading.Lock()

    def __init__(self) -> None:
        self._sessions: Dict[str, TriageSession] = {}
        self._lock = threading.Lock()

    # ── Singleton accessor ────────────────────────────────────────────────────
    @classmethod
    def instance(cls) -> "ConversationStore":
        if cls._instance is None:
            with cls._instance_lock:
                if cls._instance is None:
                    cls._instance = cls()
        return cls._instance

    # ── Internal: drop expired sessions (caller must hold the lock) ───────────
    def _prune_locked(self) -> None:
        now = time.time()
        expired = [
            sid for sid, s in self._sessions.items()
            if now - s.updated_at > SESSION_TTL_SECONDS
        ]
        for sid in expired:
            logger.info("[ConvState] session expired session=%s", sid)
            self._sessions.pop(sid, None)

    # ── Public API ────────────────────────────────────────────────────────────
    def get(self, session_id: str) -> Optional[TriageSession]:
        if not session_id:
            return None
        with self._lock:
            self._prune_locked()
            return self._sessions.get(session_id)

    def start(self, session_id: str, symptom: str, workflow: str) -> TriageSession:
        """Create (or reset) a triage session for this session_id."""
        with self._lock:
            self._prune_locked()
            session = TriageSession(
                session_id=session_id,
                symptom=symptom,
                workflow=workflow,
                state=TriageState.ASSESSMENT_STARTED,
            )
            self._sessions[session_id] = session
            logger.info(
                "[ConvState] triage started session=%s symptom=%s workflow=%s",
                session_id, symptom, workflow,
            )
            return session

    def save(self, session: TriageSession) -> None:
        session.touch()
        with self._lock:
            self._sessions[session.session_id] = session

    def clear(self, session_id: str) -> None:
        with self._lock:
            if self._sessions.pop(session_id, None) is not None:
                logger.info("[ConvState] session cleared session=%s", session_id)

    def has_active_triage(self, session_id: str) -> bool:
        session = self.get(session_id)
        return bool(session and session.is_active())
