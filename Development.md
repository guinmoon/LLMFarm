# LLMFarm_core
LLMFarm_core swift library to work with large language models (LLM). It allows you to load different LLMs with certain parameters.<br>
Based on [ggml](https://github.com/ggerganov/ggml) and [llama.cpp](https://github.com/ggerganov/llama.cpp) by [Georgi Gerganov](https://github.com/ggerganov).

Also used sources from:
* [rwkv.cpp](https://github.com/saharNooby/rwkv.cpp) by [saharNooby](https://github.com/saharNooby).
* [Mia](https://github.com/byroneverson/Mia) by [byroneverson](https://github.com/byroneverson).

## Features

- [x] MacOS (13+)
- [x] iOS (16+)
- [x] Various inferences
- [x] Metal for llama inference (MacOS and iOS)
- [x] Model setting templates
- [x] Sampling from llama.cpp for other inference
- [ ] classifier-free guidance sampling from llama.cpp 
- [ ] Other tokenizers support
- [ ] Restore context state (now only chat history) 
- [ ] Metal for other inference

## Inferences

- [x] [LLaMA](https://arxiv.org/abs/2302.13971)
- [x] [GPTNeoX](https://huggingface.co/docs/transformers/model_doc/gpt_neox)
- [x] [Replit](https://huggingface.co/replit/replit-code-v1-3b)
- [x] [GPT2](https://huggingface.co/docs/transformers/model_doc/gpt2) + [Cerebras](https://arxiv.org/abs/2304.03208)
- [x] [Starcoder(Santacoder)](https://huggingface.co/bigcode/santacoder)
- [x] [RWKV](https://huggingface.co/docs/transformers/model_doc/rwkv) (20B tokenizer)
- [ ] [Falcon](https://github.com/cmp-nct/ggllm.cpp)


# Installation
```
git clone https://github.com/guinmoon/LLMFarm
```

## Installation

### Swift Package Manager

Add `llmfarm_core` to your project using Xcode (File > Add Packages...) or by adding it to your project's `Package.swift` file:

```swift
dependencies: [
  "llmfarm_core"
]
```

## Usage

### Swift library

To generate output from a prompt, first instantiate a `LlamaRunner` instance with the URL to your LLaMA model file:

```swift

```

Generating output is as simple as calling `run()` with your prompt on the `LlamaRunner` instance. Since tokens are generated asynchronously this returns an `AsyncThrowingStream` which you can enumerate over to process tokens as they are returned:

```swift

```

Note that tokens don't necessarily correspond to a single word, and also include any whitespace and newlines.

#### Configuration

`LlamaRunner.run()` takes an optional `LlamaRunner.Config` instance which lets you control the number of threads inference is run on (default: `8`), the maximum number of tokens returned (default: `512`) and an optional reverse/negative prompt:

```swift

```