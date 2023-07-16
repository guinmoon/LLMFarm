
#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

#include "../ggml.h"



#ifdef __cplusplus
extern "C" {
#endif


const char * print_system_info(void);

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
    uint32_t seed;    // RNG seed, 0 for random

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

typedef int gpt_token;

gpt_token gpt_base_token_bos();
gpt_token gpt_base_token_eos();




int gpt_base_n_vocab(struct gpt_base_context * ctx);

int gpt_base_n_ctx(struct gpt_base_context * ctx);

int gpt_base_n_embd(struct gpt_base_context * ctx);

float * gpt_base_get_logits(struct gpt_base_context * ctx);

float * gpt_base_get_embeddings(struct gpt_base_context * ctx);

gpt_token gpt_base_str_to_token(struct gpt_base_context * ctx, const char * str);

const char * gpt_base_token_to_str(struct gpt_base_context * ctx, gpt_token token);


int gpt_base_tokenize(
        struct gpt_base_context * ctx,
                  const char * text,
                 gpt_token * tokens,
                         int   n_max_tokens,
                        bool   add_bos);

void gpt_base_shift_kv_cache(struct gpt_base_context * ctx, int n);


int32_t gpt_base_sample(struct gpt_base_context * ctx, int top_k, float top_p, float temp);
int32_t gpt_base_sample_repeat(struct gpt_base_context * ctx,
                                           const int32_t * last_n_tokens_data,
                                           size_t last_n_tokens_data_size,
                                           int top_k, float top_p, float temp,
                                           int repeat_last_n,
                                           float repeat_penalty);

#ifdef __cplusplus
}
#endif
