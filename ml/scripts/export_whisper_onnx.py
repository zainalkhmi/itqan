"""
Exports Whisper Quran Encoder to ONNX and quantizes to INT8 for mobile embedded inference.
"""
import sys
import time
from pathlib import Path
import torch
import numpy as np

MODELS_DIR = Path(__file__).parent.parent / "models"
LOCAL_MODEL = MODELS_DIR / "whisper-base-ar-quran"
ONNX_FLOAT_PATH = MODELS_DIR / "whisper-base-encoder.onnx"
ONNX_INT8_PATH = MODELS_DIR / "whisper-base-encoder.int8.onnx"

def export_encoder_onnx():
    print("⏳ Loading PyTorch Whisper model...")
    from transformers import AutoModelForSpeechSeq2Seq
    model = AutoModelForSpeechSeq2Seq.from_pretrained(str(LOCAL_MODEL))
    encoder = model.get_encoder()
    encoder.eval()

    dummy_input = torch.randn(1, 80, 3000, dtype=torch.float32)
    print("🚀 Exporting encoder to ONNX (opset 14)...")
    
    # Export without dynamo to ensure standard ONNX graph
    torch.onnx.export(
        encoder,
        dummy_input,
        str(ONNX_FLOAT_PATH),
        input_names=["input_features"],
        output_names=["last_hidden_state"],
        dynamic_axes={
            "input_features": {0: "batch_size"},
            "last_hidden_state": {0: "batch_size"},
        },
        opset_version=14,
        do_constant_folding=True,
    )
    orig_mb = ONNX_FLOAT_PATH.stat().st_size / (1024 * 1024)
    print(f"✅ Exported Float32 ONNX: {orig_mb:.1f} MB -> {ONNX_FLOAT_PATH}")

    # Quantize to INT8
    print("⚙️ Quantizing to INT8 for mobile embedded deployment...")
    from onnxruntime.quantization import quantize_dynamic, QuantType
    quantize_dynamic(
        model_input=str(ONNX_FLOAT_PATH),
        model_output=str(ONNX_INT8_PATH),
        weight_type=QuantType.QInt8,
    )
    quant_mb = ONNX_INT8_PATH.stat().st_size / (1024 * 1024)
    reduction = (1 - (quant_mb / orig_mb)) * 100
    print(f"✅ Quantized INT8 ONNX: {quant_mb:.1f} MB ({reduction:.1f}% reduction) -> {ONNX_INT8_PATH}")

    # Test with ONNX Runtime
    print("🧪 Verifying INT8 ONNX inference session...")
    import onnxruntime as ort
    session = ort.InferenceSession(str(ONNX_INT8_PATH), providers=["CPUExecutionProvider"])
    test_input = np.random.randn(1, 80, 3000).astype(np.float32)
    t0 = time.time()
    outputs = session.run(["last_hidden_state"], {"input_features": test_input})
    t1 = time.time()
    print(f"✅ Verification Success! Output shape: {outputs[0].shape}, Latency: {(t1-t0)*1000:.1f} ms")

if __name__ == "__main__":
    export_encoder_onnx()

