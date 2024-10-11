# LLMFarm


<p align="center">
  <a href="https://apps.apple.com/ru/app/llm-farm/id6461209867?l=en-GB&platform=iphone"><img width="178px" alt="Icon" src="dist/LLMFarm0.1.2_256.png"></a>
  <a href="https://testflight.apple.com/join/6SpPLIVM"><img width="178px" alt="Icon" src="dist/testflight.png"></a>
</p>
<p align="center">
  <a href="https://apps.apple.com/ru/app/llm-farm/id6461209867?l=en-GB&platform=iphone"><strong>Install Stable</strong></a>&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;
  &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; <a href="https://testflight.apple.com/join/6SpPLIVM"><strong>Install Latest</strong></a>
</p>

<br>

<p align="center">
  <a href="https://t.me/llmfarm_chat"><img alt="Icon" height="32"  src="dist/telegram_logo_128.png"></a>&nbsp;&nbsp;&nbsp;&nbsp;
  <a href="https://www.youtube.com/@LLMFarm-lib"><img alt="Icon" height="32"  src="dist/youtube_logo_128.png"></a>&nbsp;&nbsp;&nbsp;&nbsp;
  <a href="https://boosty.to/llmfarm"><img alt="Icon" height="32"  src="dist/boosty_icon.png"></a>&nbsp;&nbsp;&nbsp;&nbsp;
  <a href="https://llmfarm.tech"><img alt="Icon" height="32"  src="dist/www_logo_128.png"></a>&nbsp;&nbsp;&nbsp;&nbsp;
  <a href="https://github.com/guinmoon/LLMFarm/wiki"><img alt="Wiki" height="32"  src="dist/wiki_logo_128.png"></a>
</p>

<p align="center">
  <img alt="Icon" height="440px"  src="dist/screen1.png">&nbsp;&nbsp;
  <img alt="Icon" width="540px"  src="dist/screen2.png">
</p>

---


LLMFarm is an iOS and MacOS app to work with large language models (LLM). It allows you to load different LLMs with certain parameters.With LLMFarm, you can test the performance of different LLMs on iOS and macOS and find the most suitable model for your project.<br>
Based on [ggml](https://github.com/ggerganov/ggml) and [llama.cpp](https://github.com/ggerganov/llama.cpp) by [Georgi Gerganov](https://github.com/ggerganov).

# Features

- [x] MacOS (13+)
- [x] iOS (16+)
- [x] Various inferences
- [x] Various sampling methods
- [x] Metal ([dont work](https://github.com/ggerganov/llama.cpp/issues/2407#issuecomment-1699544808) on intel Mac)
- [x] Model setting templates
- [x] [Restore context state](./docs/save_load_state.md)
- [x] [Apple Shortcuts](./docs/shortcuts.md)

# Inferences

- [x] <img src="dist/metal-96x96_2x.png" width="16px" heigth="16px"> [LLaMA](https://arxiv.org/abs/2302.13971) 
- [x] <img src="dist/metal-96x96_2x.png" width="16px" heigth="16px"> [Gemma](https://ai.google.dev/gemma) 
- [x] <img src="dist/metal-96x96_2x.png" width="16px" heigth="16px"> [Phi](https://huggingface.co/models?search=microsoft/phi) 
- [x] <img src="dist/metal-96x96_2x.png" width="16px" heigth="16px"> [GPT2](https://huggingface.co/docs/transformers/model_doc/gpt2) + [Cerebras](https://arxiv.org/abs/2304.03208) 
- [x] <img src="dist/metal-96x96_2x.png" width="16px" heigth="16px"> [Starcoder(Santacoder)](https://huggingface.co/bigcode/santacoder) 
- [x] <img src="dist/metal-96x96_2x.png" width="16px" heigth="16px"> [Falcon](https://github.com/cmp-nct/ggllm.cpp) 
- [x] <img src="dist/metal-96x96_2x.png" width="16px" heigth="16px"> [MPT](https://huggingface.co/guinmoon/mpt-7b-storywriter-GGUF) 
- [x] <img src="dist/metal-96x96_2x.png" width="16px" heigth="16px"> [Bloom](https://huggingface.co/guinmoon/bloomz-1b7-gguf) 
- [x] <img src="dist/metal-96x96_2x.png" width="16px" heigth="16px"> [StableLM-3b-4e1t](https://huggingface.co/stabilityai/stablelm-3b-4e1t) 
- [x] <img src="dist/metal-96x96_2x.png" width="16px" heigth="16px"> [Qwen](https://huggingface.co/Qwen/Qwen-7B) 
- [x] <img src="dist/metal-96x96_2x.png" width="16px" heigth="16px"> [Yi models](https://huggingface.co/models?search=01-ai/Yi) 
- [x] <img src="dist/metal-96x96_2x.png" width="16px" heigth="16px"> [Deepseek models](https://huggingface.co/models?search=deepseek-ai/deepseek) 
- [x] <img src="dist/metal-96x96_2x.png" width="16px" heigth="16px"> [Mixtral MoE](https://huggingface.co/models?search=mistral-ai/Mixtral) 
- [x] <img src="dist/metal-96x96_2x.png" width="16px" heigth="16px"> [PLaMo-13B](https://github.com/ggerganov/llama.cpp/pull/3557) 
- [x] <img src="dist/metal-96x96_2x.png" width="16px" heigth="16px"> [Mamba](https://github.com/state-spaces/mamba)
- [x] <img src="dist/metal-96x96_2x.png" width="16px" heigth="16px"> [RWKV](https://huggingface.co/docs/transformers/model_doc/rwkv) 
- [x] <img src="dist/metal-96x96_2x.png" width="16px" heigth="16px"> [GPTNeoX](https://huggingface.co/docs/transformers/model_doc/gpt_neox)

See full list [here](https://github.com/ggerganov/llama.cpp).

## Multimodal
- [x] [LLaVA 1.5 models](https://huggingface.co/collections/liuhaotian/llava-15-653aac15d994e992e2677a7e), [LLaVA 1.6 models](https://huggingface.co/collections/liuhaotian/llava-16-65b9e40155f60fd046a5ccf2)
- [x] [BakLLaVA](https://huggingface.co/models?search=SkunkworksAI/Bakllava)
- [x] [Obsidian](https://huggingface.co/NousResearch/Obsidian-3B-V0.5)
- [x] [ShareGPT4V](https://huggingface.co/models?search=Lin-Chen/ShareGPT4V)
- [x] [MobileVLM 1.7B/3B models](https://huggingface.co/models?search=mobileVLM)
- [x] [Yi-VL](https://huggingface.co/models?search=Yi-VL)
- [x] [Moondream](https://huggingface.co/vikhyatk/moondream2)
  
Note: For *Falcon, Alpaca, GPT4All, Chinese LLaMA / Alpaca and Chinese LLaMA-2 / Alpaca-2, Vigogne (French), Vicuna, Koala, OpenBuddy (Multilingual), Pygmalion/Metharme, WizardLM, Baichuan 1 & 2 + derivations, Aquila 1 & 2, Mistral AI v0.1, Refact, Persimmon 8B, MPT, Bloom* select `llama inferece` in model settings.

# Sampling methods
- [x] Temperature (temp, tok-k, top-p)
- [x] [Tail Free Sampling (TFS)](https://www.trentonbricken.com/Tail-Free-Sampling/)
- [x] [Locally Typical Sampling](https://arxiv.org/abs/2202.00666)
- [x] [Mirostat](https://arxiv.org/abs/2007.14966)
- [x] Greedy
- [x] Grammar
- [ ] Classifier-Free Guidance

# Getting Started

You can find answers to some questions in the [FAQ section](https://github.com/guinmoon/LLMFarm/wiki/FAQ).

## Inference options
When creating a chat, a JSON file is generated in which you can specify additional inference options. The chat files are located in the "chats" directory. You can see all inference options [here](./docs/inference_options.md).

## Models
You can download some of the supported [models here](https://llmfarm.site/).


# Development
`llmfarm_core` has been moved to a [separate repository](https://github.com/guinmoon/llmfarm_core.swift). To build llmfarm, you need to clone this repository recursively:
```bash
git clone --recurse-submodules https://github.com/guinmoon/LLMFarm
```

# Also used sources from:
* [rwkv.cpp](https://github.com/saharNooby/rwkv.cpp) by [saharNooby](https://github.com/saharNooby)
* [Mia](https://github.com/byroneverson/Mia) by [byroneverson](https://github.com/byroneverson)
* [LlamaChat](https://github.com/alexrozanski/LlamaChat) by [alexrozanski](https://github.com/alexrozanski)
* [swift-markdown-ui](https://github.com/gonzalezreal/swift-markdown-ui) by [gonzalezreal](https://github.com/gonzalezreal)

# [❤️ Support project](./donate.md)
