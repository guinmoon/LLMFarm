# Connecting LoRA adapters

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
}
```

# Fine Tune
You can read about [FineTune here.](https://github.com/ggerganov/llama.cpp/tree/master/examples/finetune).

# Export LoRA as a model

You can read about how to apply an adapter to a model and export the resulting model [read here.](https://github.com/ggerganov/llama.cpp/tree/master/examples/export-lora).