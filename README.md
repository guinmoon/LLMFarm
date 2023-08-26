# LLMFarm

<p align="center">
  <img width="178px" alt="Icon" src="dist/LLMFarm0.1.2_256.png">
  <a href="https://testflight.apple.com/join/6SpPLIVM"><img width="178px" alt="Icon" src="dist/testflight.png"></a>
</p>

<p align="center">
<a href="https://testflight.apple.com/join/6SpPLIVM"><strong>Install with TestFlight</strong></a>
</p>


<p align="center">
  <img alt="Icon" height="400px"  src="dist/screen1.png">
  <img alt="Icon" width="535px"  src="dist/screen2.png">
</p>

LLMFarm is an iOS and MacOS app to work with large language models (LLM). It allows you to load different LLMs with certain parameters.<br>
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

## Getting Started

Models must be quantized by [ggml](https://github.com/ggerganov/ggml) after [#154](https://github.com/ggerganov/ggml/pull/154).
LLMFarm work in sandbox mode and put added models to the "models" directory. 

### Inference options
When creating a chat, a JSON file is generated in which you can specify additional inference options. The chat files are located in the "chats" directory. You can see all inference options [here](/inference_options.md).

### Models
You can download some of the supported [models here](/models.md).


## Development
llmfarm_core has been moved to a [separate repository](https://github.com/guinmoon/llmfarm_core.swift). To build llmfarm, you need to clone this repository recursively:
```bash
git clone --recurse-submodules https://github.com/guinmoon/LLMFarm
```


## P.S.
The number of open models is continuously growing. One of the advantages of using such models is the possibility of preserving their original content without censorship. However, the disadvantage may be the irrelevance of the information contained in them. You can also get answers to questions from various industries, for example, there are models that specialize in medical terms or programming.
In addition, with the help of these models, you can create stories, songs, music and play quests etc...


