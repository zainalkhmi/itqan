"""
Integration test for Itqan ML Server.
Tests health endpoint and recitation scoring pipeline.
"""
from fastapi.testclient import TestClient
from server import app

client = TestClient(app)

def test_health():
    res = client.get("/health")
    assert res.status_code == 200
    data = res.json()
    assert data["status"] == "online"
    print("✅ Health check passed:", data)

def test_scoring_text():
    payload = {
        "expected_words": ["بِسْمِ", "ٱللَّهِ", "ٱلرَّحْمَـٰنِ", "ٱلرَّحِيمِ"],
        "ayah_text": "بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ",
        "surah": 1,
        "ayah": 1,
        "duration_ms": 4500
    }
    res = client.post("/score", json=payload)
    assert res.status_code == 200
    data = res.json()
    assert "overall" in data
    assert "wordScores" in data
    assert len(data["wordScores"]) == 4
    print("✅ Recitation score endpoint passed. Overall score:", data["overall"])
    print("   Word scores:", [(w["word"], w["score"]) for w in data["wordScores"]])

if __name__ == "__main__":
    test_health()
    test_scoring_text()
    print("🎉 All Server API integration tests passed!")

