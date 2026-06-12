---
name: mlops-model-operations
description: "MLOps umbrella: model discovery, local/served inference, evaluation, experiment tracking, model surgery, and specialized model tooling."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [mlops, huggingface, llama-cpp, vllm, evaluation, wandb, audiocraft, sam]
---

# MLOps Model Operations

Use this class-level skill for machine-learning operations around models: Hugging Face Hub, local GGUF inference, vLLM serving, benchmark evaluation, W&B tracking, model surgery/abliteration, audio generation, and vision segmentation models.

## Model discovery and artifacts

Use Hugging Face Hub workflows to search, download, upload, and inspect models/datasets. Confirm license, model format, quantization, file sizes, and required dependencies before downloading large artifacts.

## Local inference with llama.cpp / GGUF

Use for CPU/GPU/Apple Silicon local inference, GGUF quant selection, `llama-cli`, and `llama-server`.

Key choices:

- Match quantization to RAM/VRAM.
- Prefer existing GGUF repos when available.
- Verify model context length, chat template, and tokenizer compatibility.

## Production serving with vLLM

Use vLLM for high-throughput OpenAI-compatible serving, batching, tensor parallelism, and quantized GPU deployments.

Typical checks:

```bash
python -c 'import vllm; print(vllm.__version__)'
nvidia-smi || true
```

Tune max model length, GPU memory utilization, tensor parallel size, and quantization based on hardware.

## Evaluation and benchmarking

Use lm-evaluation-harness for standardized LLM benchmarks such as MMLU, GSM8K, TruthfulQA, HellaSwag, and HumanEval-style tasks. Record model revision, prompts/templates, batch size, seeds, and exact command lines.

## Experiment tracking with Weights & Biases

Use W&B for run metrics, dashboards, sweeps, artifacts, model registry, and team collaboration. Verify auth and project/entity names before launching long sweeps.

## Model surgery / refusal direction work

Use abliteration/model-surgery workflows only for open-weight models and with explicit user intent. Preserve reproducibility: config, selected layers, directions, eval prompts, and before/after benchmark results.

## Specialized model tooling

- AudioCraft/MusicGen/AudioGen: text-to-music, sound effects, melody-conditioned generation.
- Segment Anything Model: zero-shot image segmentation with points, boxes, masks, ONNX export, and annotation tooling.

## Operational safety

- Large downloads and GPU jobs should be bounded or backgrounded with completion notification.
- Always verify generated model artifacts with checksums or basic load tests.
- Report hardware assumptions and exact command output.
