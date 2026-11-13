"""
Unit tests for Itqan Quran Aligner and Scoring Engine.
"""
from quran_aligner import (
    normalize_arabic,
    similarity_ratio,
    detect_makhraj_issue,
    detect_tajweed_features,
    evaluate_recitation,
)

def test_normalization():
    raw = "بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ ١"
    clean = normalize_arabic(raw)
    assert "بسم الله الرحمن الرحيم" == clean, f"Got: {clean}"
    print("✅ test_normalization passed")

def test_makhraj_detection():
    # User said Seen instead of Saad in Sirat (صراط vs سراط)
    issue = detect_makhraj_issue("صراط", "سراط")
    assert issue is not None, "Expected makhraj issue detected"
    assert "Ṣād" in issue or "Seen" in issue
    print("✅ test_makhraj_detection passed")

def test_tajweed_features():
    rules_rahman = detect_tajweed_features("ٱلرَّحْمَـٰنِ")
    assert "madd" in rules_rahman
    print("✅ test_tajweed_features passed")

def test_evaluation():
    expected = ["بِسْمِ", "ٱللَّهِ", "ٱلرَّحْمَـٰنِ", "ٱلرَّحِيمِ"]
    # User pronounced perfectly
    transcription = "بسم الله الرحمن الرحيم"
    res = evaluate_recitation(expected, transcription, duration_sec=4.2)
    assert res["overall"] >= 90.0
    assert res["wordAccuracy"] >= 95.0
    assert len(res["wordScores"]) == 4
    print("✅ test_evaluation perfect recitation passed:", res["overall"])

    # User missed a word and mispronounced another
    imperfect_transcription = "بسم الله الرحيم"
    res_imperfect = evaluate_recitation(expected, imperfect_transcription, duration_sec=3.0)
    assert res_imperfect["overall"] < 90.0
    assert len(res_imperfect["mistakes"]) > 0
    print("✅ test_evaluation imperfect recitation passed:", res_imperfect["overall"])

if __name__ == "__main__":
    test_normalization()
    test_makhraj_detection()
    test_tajweed_features()
    test_evaluation()
    print("🎉 All Aligner unit tests passed!")

