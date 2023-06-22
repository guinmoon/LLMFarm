
#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

#include "../ggml.h"



#ifdef __cplusplus
extern "C" {
#endif

typedef struct gpt_neox_token_data {
    int id;  // token id
    float logit; // log-odds of the token
    float p;     // probability of the token
} gpt_neox_token_data;

typedef struct gpt_neox_token_data_array {
    gpt_neox_token_data * data;
    size_t size;
    bool sorted;
} gpt_neox_token_data_array;

typedef void (*gpt_progress_callback)(float progress, void *ctx);

struct gpt_context_params {
    int n_ctx;   // text context
    int n_parts; // -1 for default
    int seed;    // RNG seed, 0 for random

    bool f16_kv;     // use fp16 for KV cache
    bool logits_all; // the gptneox_eval() call computes all logits, not just the last one
    bool vocab_only; // only load the vocabulary, no weights
    bool use_mmap;   // use mmap if possible
    bool use_mlock;  // force system to keep model in RAM
    bool embedding;  // embedding mode only

    // called with a progress value between 0 and 1, pass NULL to disable
    gpt_progress_callback progress_callback;
    // context pointer passed to the progress callback
    void * progress_callback_user_data;
};

struct gpt_context_params gpt_context_default_params();






#ifdef __cplusplus
}
#endif
