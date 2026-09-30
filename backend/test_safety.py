import unittest
from app.services.safety_service import check_crisis

class TestSafetyGuardrail(unittest.TestCase):
    def test_crisis_detection_positive(self):
        cases = [
            "aku capek hidup, ingin bunuh diri",
            "rasanya pengen mati aja",
            "aku kepikiran mau self-harm lagi",
            "pengen sayat tangan rasanya",
            "i want to kill myself",
        ]
        for text in cases:
            is_crisis, data = check_crisis(text)
            self.assertTrue(is_crisis, f"Gagal deteksi krisis: {text}")
            self.assertIsNotNone(data)
            self.assertTrue(data["is_crisis"])
            self.assertTrue(len(data["hotlines"]) > 0)

    def test_crisis_detection_negative(self):
        cases = [
            "aku stres banget sama deadline tugas akhir",
            "hari ini lelah sekali kerja di kantor",
            "apakah wajar merasa cemas setiap malam?",
            "tolong bantu aku latihan pernapasan",
        ]
        for text in cases:
            is_crisis, data = check_crisis(text)
            self.assertFalse(is_crisis, f"Salah deteksi krisis: {text}")
            self.assertIsNone(data)

if __name__ == "__main__":
    unittest.main()
