# Inference options
When creating a chat, a JSON file is generated in which you can specify additional model parameters. The chat files are located in the "chats" directory.

| parametr          | default           | description                                         |
|-------------------|-------------------|-----------------------------------------------------|
| title             | [Model file name] | Chat title                                          |
| icon              | ava0              | ava[0-7]                                            |
| model             |                   | model file path                                     |
| model_inference   | auto              | model_inference: llama \| gptneox \| replit \| gpt2 |
| prompt_format     | auto              | Example for stablelm:                               |
|                   |                   | `"<USER> {{prompt}} <ASSISTANT>"`                   |
| numberOfThreads   | 0 (max)           | number of threads                                   |
| context           | 1024              | context size                                        |
| n_batch           | 512               | batch size for prompt processing                    |
| temp              | 0.8               | temperature                                         |
| top_k             | 40                | top-k sampling                                      |
| top_p             | 0.95              | top-p sampling                                      |
| tfs_z             | 1.0               | tail free sampling, parameter z                     |
| typical_p         | 1.0               | locally typical sampling, parameter p               |
| repeat_penalty    | 1.1               | penalize repeat sequence of tokens                  |
| repeat_last_n     | 64                | last n tokens to consider for penalize              |
| frequence_penalty | 0.0               | repeat alpha frequency penalty                      |
| presence_penalty  | 0.0               | repeat alpha presence penalt                        |
| mirostat          | 0                 | use Mirostat sampling                               |
| mirostat_tau      | 5.0               | Mirostat target entropy, parameter tau              |
| mirostat_eta      | 0.1               | Mirostat learning rate, parameter eta               |