# LLMFarm

<p align="center">
  <img width="178px" alt="Icon" src="dist/LLMFarm0.1.2_256.png">
</p>

<p align="center">
  <img alt="Icon" height="400px"  src="dist/screen1.png">
  <img alt="Icon" width="570px"  src="dist/screen2.png">
</p>

Application for iOS and MacOS designed to work with large language models (LLM). It allows you to load different LLMs with certain parameters.
Based on [ggml](https://github.com/ggerganov/ggml) and [llama.cpp](https://github.com/ggerganov/llama.cpp) by [Georgi Gerganov](https://github.com/ggerganov).
Also, when creating the application, the source codes from the repository [byroneverson](https://github.com/byroneverson/Mia) were used.

List of supported models:

| model                                                                              | inference | size     | quantized link                                                     | iOS (iphone 12 pro max) | MacOS  |
|------------------------------------------------------------------------------------|-----------|----------|--------------------------------------------------------------------|-------------------------|--------|
| [OpenLLaMa](https://github.com/openlm-research/open_llama)                         | LLaMA     | 3B       | [hug](https://huggingface.co/guinmoon/LLMFarm_Models/tree/main)    | ok                      | ok     |
| [ORCA](https://huggingface.co/psmathur/orca_mini_3b)                               | LLaMA     | 3B       | [hug](https://huggingface.co/guinmoon/LLMFarm_Models/tree/main)    | ok                      | ok     |
| [ORCA](https://huggingface.co/TheBloke/orca_mini_7B-GGML/)                         | LLaMA     | 7B(q3_K) | [hug](https://huggingface.co/TheBloke/orca_mini_7B-GGML/tree/main) | ok                      | ok     |
| [StableLM Tuned Alpha](https://huggingface.co/stabilityai/stablelm-tuned-alpha-3b) | GPT-NeoX  | 3B       | [hug](https://huggingface.co/guinmoon/LLMFarm_Models/tree/main)    | ok                      | ok     |
| [Dolly v2](https://github.com/databrickslabs/dolly)                                | GPT-NeoX  | 3B       | [hug](https://huggingface.co/guinmoon/LLMFarm_Models/tree/main)    | ok                      | ok     |
| [RedPajama](https://huggingface.co/togethercomputer/RedPajama-INCITE-Base-3B-v1)   | GPT-NeoX  | 3B       | [hug](https://huggingface.co/guinmoon/LLMFarm_Models/tree/main)    | ok                      | ok     |
| [Pythia](https://huggingface.co/EleutherAI)                                        | GPT-NeoX  | 2.8B     | [hug](https://huggingface.co/guinmoon/LLMFarm_Models/tree/main)    | ok                      | ok     |
| [Llama](https://arxiv.org/abs/2302.13971)                                          | LLaMA     | 7B(q3_K) |                                                                    | ok                      | ok     |
| [WizardLM](https://arxiv.org/abs/2304.12244)                                       | LLaMA     | 7B(q3_K) |                                                                    | ok                      | ok     |
| [Cerebras](https://huggingface.co/cerebras/Cerebras-GPT-2.7B)                      | GPT-2     | 2.7B     |                                                                    | ok                      | ok     |
| [AI Dungeon](https://huggingface.co/Henk717/ai-dungeon2-classic-ggml)              | GPT-2     | ?        | [hug](https://huggingface.co/guinmoon/LLMFarm_Models/tree/main)    | ok                      | ok     |
| [Replit](https://huggingface.co/replit/replit-code-v1-3b)                          | Replit    | 3B       | [hug](https://huggingface.co/guinmoon/LLMFarm_Models/tree/main)    | ok                      | ok     |
| [RWKV-4 "Raven"](https://huggingface.co/BlinkDL/rwkv-4-raven)                      | RWKV      | 3B       |                                                                    | in dev                  | in dev |

Models must be quantized by [ggml](https://github.com/ggerganov/ggml) after [#154](https://github.com/ggerganov/ggml/pull/154).

The application operates in sandbox mode and put added models to the "models" directory. 

When creating a chat, a JSON file is generated in which you can specify additional model parameters. The chat files are located in the "chats" directory.

Parameter list:

| parametr          | default           | description                                                                 |
|-------------------|-------------------|-----------------------------------------------------------------------------|
| title             | [Model file name] | Chat title                                                                  |
| icon              | ava0              | ava[0-7]                                                                    |
| model             |                   | model file path                                                             |
| model_inference   | auto              | model_inference: llama \| gptneox                                           |
| prompt_format     | auto              | Example for stablelm:                                                       |
|                   |                   | `"<USER> {{prompt}} <ASSISTANT>"`                                           |
| numberOfThreads   | 0 (max)           | number of threads (for MacOS i recomend set your processor thread count -2) |
| context           | 2048              | context size                                                                |
| n_batch           | 512               | batch size for prompt processing                                            |
| temp              | 0.8               | temperature                                                                 |
| top_k             | 40                | top-k sampling                                                              |
| top_p             | 0.95              | top-p sampling                                                              |
| tfs_z             | 1.0               | tail free sampling, parameter z                                             |
| typical_p         | 1.0               | locally typical sampling, parameter p                                       |
| repeat_penalty    | 1.1               | penalize repeat sequence of tokens                                          |
| repeat_last_n     | 64                | last n tokens to consider for penalize                                      |
| frequence_penalty | 0.0               | repeat alpha frequency penalty                                              |
| presence_penalty  | 0.0               | repeat alpha presence penalt                                                |
| mirostat          | 0                 | use Mirostat sampling                                                       |
| mirostat_tau      | 5.0               | Mirostat target entropy, parameter tau                                      |
| mirostat_eta      | 0.1               | Mirostat learning rate, parameter eta                                       |


The number of open models is constantly growing. One of the advantages of using such models is the possibility of preserving their original content without censorship. However, the disadvantage may be the irrelevance of the information contained in them. You can also get answers to questions from various industries, for example, there are models that specialize in medical terms or programming.
In addition, with the help of these models, you can create stories, songs, music and play quests (more on that later).