# Connecting LoRA adapters
Put the adapter files in the `lora_adapters` directory.

**You `cannot use mmap` when connecting an adapter, so `memory` consumption will be `high`. In order to use mmap with lora do export.**
To add one LoRA adapter, you can use the LLMFarm chat settings interface.
To add several LoRA adapters, manually write them in the configuration file like this:
```JSON
{
...
    "prompt_format" : "{{prompt}}",
    "model" : "openllama-3b-v2-q8_0.gguf",
    "lora_adapters" : [
        {
            "adapter" : "lora-open-llama-3b-v2-q8_0-shakespeare-LATEST.bin",
            "scale" : 0.9
        },
        {
            "adapter" : "lora-open-llama-3b-v2-q8_0-second-LATEST.bin",
            "scale" : 1.0
        }
    ],
...
}
```

# Fine Tune
Now you can perform FineTune directly in LLMFarm. To do this, go to settings -> FineTune
*FineTune consumes quite a lot of RAM, so on iOS it is possible to train only 3B models with minimum settings n_ctx, n_batch*.
You can read [more about FineTune here.](https://github.com/ggerganov/llama.cpp/tree/master/examples/finetune).

# Export LoRA as a model
Now you can perform FineTune directly in LLMFarm. To do this, go to settings -> Merge Lora
You can read about how to apply an adapter to a model and export the resulting model [here.](https://github.com/ggerganov/llama.cpp/tree/master/examples/export-lora).
*For proper functionality on iOS devices, it is recommended to merge with Q4_K models and below.*