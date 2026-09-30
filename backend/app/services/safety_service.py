import re
from typing import Tuple, Optional

CRISIS_PATTERNS = [
    r"\b(bunuh\s*diri|suicide|suicidal)\b",
    r"\b(akhiri\s*hidup|mau\s*mati|ingin\s*mati|pengen\s*mati)\b",
    r"\b(sayat\s*tangan|melukai\s*diri|potong\s*urat|self[\s-]*harm)\b",
    r"\b(loncat\s*dari|gantung\s*diri|minum\s*racun|overdosis)\b",
    r"\b(tidak\s*ada\s*gunanya\s*hidup|lebih\s*baik\s*mati|capek\s*hidup)\b",
    r"\b(kill\s*myself|end\s*my\s*life|want\s*to\s*die)\b",
]

COMPILED_CRISIS_REGEX = re.compile("|".join(CRISIS_PATTERNS), re.IGNORECASE)

CRISIS_RESPONSE_PAYLOAD = {
    "is_crisis": True,
    "delta": (
        "Aku mendengar rasa sakit dan beban berat yang kamu rasakan saat ini. "
        "Namun keselamatanmu adalah yang paling penting. "
        "Aku adalah pendamping AI dan tidak dapat memberikan bantuan darurat langsung. "
        "Tolong hubungi bantuan profesional atau orang terdekat sekarang juga."
    ),
    "suggested_chips": ["Hubungi Hotline 119", "Napas Dalam Dulu", "Kontak Darurat"],
    "trigger_exercise": "breathing",
    "hotlines": [
        {"name": "Layanan Sejiwa", "number": "119", "ext": "8"},
        {"name": "Into The Light Indonesia", "website": "https://www.intothelightid.org"},
        {"name": "Halo Kemenkes", "number": "1500567"}
    ]
}

def check_crisis(text: str) -> Tuple[bool, Optional[dict]]:
    """Evaluasi teks input apakah masuk kategori risiko krisis (<10ms)."""
    if not text:
        return False, None
    if COMPILED_CRISIS_REGEX.search(text):
        return True, CRISIS_RESPONSE_PAYLOAD
    return False, None
