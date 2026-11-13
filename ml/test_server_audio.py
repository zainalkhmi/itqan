"""
Integration test for Itqan ML Server with real audio.
"""
import base64
import requests
from fastapi.testclient import TestClient
from server import app, load_asr_model

# Ensure model is loaded for test
load_asr_model()
client = TestClient(app)

def test_full_pipeline():
    # Fetch real recitation audio
    audio_bytes = requests.get('https://verses.quran.com/Alafasy/mp3/001001.mp3').content
    audio_b64 = base64.b64encode(audio_bytes).decode('ascii')
    
    payload = {
        "audio_base64": audio_b64,
        "expected_words": ["بِسْمِ", "ٱللَّهِ", "ٱلرَّحْمَـٰنِ", "ٱلرَّحِيمِ"],
        "ayah_text": "بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ",
        "surah": 1,
        "ayah": 1,
        "duration_ms": 4200
    }
    res = client.post("/score", json=payload)
    assert res.status_code == 200, f"Error {res.status_code}: {res.text}"
    data = res.json()
    
    print("✅ Full Pipeline Response:")
    print("   AI Transcription:", data.get("transcription"))
    print("   Overall Score:", data.get("overall"))
    print("   Word Accuracy:", data.get("wordAccuracy"))
    print("   Letter Accuracy:", data.get("letterAccuracy"))
    print("   Tajweed Score:", data.get("tajweed"))
    print("   Fluency Score:", data.get("fluency"))
    print("   AI Model:", data.get("ai_model"))
    print("   Word breakdown:", [(w["word"], w["score"], w["error"]) for w in data["wordScores"]])
    
    assert data["overall"] >= 80.0
    assert "بسم" in data.get("transcription", "") or "بِسْمِ" in data.get("transcription", "")
    print("🎉 Real audio recitation test verified 100% successfully!")

if __name__ == "__main__":
    test_full_pipeline()

