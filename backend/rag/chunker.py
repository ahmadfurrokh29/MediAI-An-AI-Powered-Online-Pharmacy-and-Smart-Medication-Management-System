"""
Text chunking utilities.

Splits long pharmaceutical text into overlapping chunks at sentence
boundaries where possible, so each chunk is self-contained and fits
comfortably within LLM context windows.
"""
from __future__ import annotations

import re
from typing import List

from .config import CHUNK_SIZE, CHUNK_OVERLAP


def _split_sentences(text: str) -> List[str]:
    """
    Naïve but effective sentence splitter that works without NLTK.
    Handles abbreviations like 'Dr.' and 'mg.' reasonably well.
    """
    # Split on '. ', '! ', '? ' followed by an uppercase letter or end-of-string
    parts = re.split(r'(?<=[.!?])\s+(?=[A-Z\d])', text.strip())
    return [p.strip() for p in parts if p.strip()]


def chunk_text(text: str) -> List[str]:
    """
    Splits [text] into chunks of roughly CHUNK_SIZE characters, with
    CHUNK_OVERLAP characters of context carried into the next chunk.

    Strategy:
      1. Split into sentences.
      2. Accumulate sentences until the chunk would exceed CHUNK_SIZE.
      3. When a chunk is full, emit it, then carry the last few sentences
         (up to CHUNK_OVERLAP chars) forward as the overlap seed.
    """
    if not text or len(text.strip()) < 30:
        return []

    sentences = _split_sentences(text)
    chunks: List[str] = []
    current: List[str] = []
    current_len = 0

    for sent in sentences:
        sent_len = len(sent)
        if current_len + sent_len > CHUNK_SIZE and current:
            # Emit current chunk
            chunks.append(" ".join(current))

            # Build overlap: keep sentences from the tail until we have CHUNK_OVERLAP chars
            overlap: List[str] = []
            overlap_len = 0
            for s in reversed(current):
                if overlap_len + len(s) <= CHUNK_OVERLAP:
                    overlap.insert(0, s)
                    overlap_len += len(s)
                else:
                    break
            current = overlap
            current_len = overlap_len

        current.append(sent)
        current_len += sent_len

    # Emit remaining sentences
    if current:
        chunks.append(" ".join(current))

    return chunks
