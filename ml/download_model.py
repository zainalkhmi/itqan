"""
Downloads tarteel-ai/whisper-base-ar-quran files directly with streaming progress.
"""
import os
import sys
import requests
from pathlib import Path

MODEL_DIR = Path(__file__).parent / "models" / "whisper-base-ar-quran"
MODEL_DIR.mkdir(parents=True, exist_ok=True)

BASE_URL = "https://huggingface.co/tarteel-ai/whisper-base-ar-quran/resolve/main"
FILES = [
    "config.json",
    "preprocessor_config.json",
    "special_tokens_map.json",
    "tokenizer_config.json",
    "vocab.json",
    "merges.txt",
    "normalizer.json",
    "added_tokens.json",
    "pytorch_model.bin",
]

def download_file(filename: str):
    target = MODEL_DIR / filename
    if target.exists() and target.stat().st_size > 0:
        print(f"✅ Already exists: {filename} ({target.stat().st_size / 1e6:.1f} MB)")
        return
    
    url = f"{BASE_URL}/{filename}"
    print(f"⬇️ Downloading {filename} from {url}...")
    with requests.get(url, stream=True, timeout=60) as r:
        r.raise_for_status()
        total = int(r.headers.get("content-length", 0))
        downloaded = 0
        with open(target, "wb") as f:
            for chunk in r.iter_content(chunk_size=1024 * 1024):
                if chunk:
                    f.write(chunk)
                    downloaded += len(chunk)
                    if total > 0:
                        pct = (downloaded / total) * 100
                        mb = downloaded / (1024 * 1024)
                        tot_mb = total / (1024 * 1024)
                        sys.stdout.write(f"\r  Progress: {pct:.1f}% ({mb:.1f}/{tot_mb:.1f} MB)")
                        sys.stdout.flush()
    print(f"\n✅ Finished: {filename}")

def main():
    print(f"Target directory: {MODEL_DIR}")
    for f in FILES:
        download_file(f)
    print("\n🎉 All model files downloaded successfully!")

if __name__ == "__main__":
    main()

