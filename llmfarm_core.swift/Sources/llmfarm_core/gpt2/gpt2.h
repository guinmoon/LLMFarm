#ifndef GPT2_H
#define GPT2_H

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>



#ifdef __cplusplus
extern "C" {
#endif



typedef int gpt2_token;

struct gpt2_context;


void gpt2_free(struct gpt2_context * ctx);


//GPTNEOX_API struct gpt_context_params gpt_context_default_params();

typedef void (*gpt2_progress_callback)(float progress, void *ctx);

struct gpt2_context_params {
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
    gpt2_progress_callback progress_callback;
    // context pointer passed to the progress callback
    void * progress_callback_user_data;
};

struct gpt2_context_params gpt2_context_default_params();

struct gpt2_context * gpt2_init_from_file(const char * path_model, struct gpt2_context_params params);

void gpt2_shift_kv_cache(struct gpt2_context * ctx, int n);

int gpt2_init_logits(struct gpt2_context * ctx,int   n_threads);

int gpt2_eval(
        struct gpt2_context * ctx,
           const gpt2_token * tokens,
                         int   n_tokens,
                         int   n_past,
                         int   n_threads);

int gpt2_tokenize(
        struct gpt2_context * ctx,
                  const char * text,
                 gpt2_token * tokens,
                         int   n_max_tokens,
                        bool   add_bos);

int gpt2_n_vocab(struct gpt2_context * ctx) ;
int gpt2_n_ctx(struct gpt2_context * ctx);
int gpt2_n_embd(struct gpt2_context * ctx);
float * gpt2_get_logits(struct gpt2_context * ctx);
float * gpt2_get_embeddings(struct gpt2_context * ctx);
gpt2_token gpt2_token_bos();
gpt2_token gpt2_token_eos();
gpt2_token gpt2_str_to_token(struct gpt2_context * ctx, const char * str);
const char * gpt2_token_to_str(struct gpt2_context * ctx, gpt2_token token);


int32_t gpt2_sample(struct gpt2_context * ctx, int top_k, float top_p, float temp);
int32_t gpt2_sample_repeat(struct gpt2_context * ctx,
                                           const int32_t * last_n_tokens_data,
                                           size_t last_n_tokens_data_size,
                                           int top_k, float top_p, float temp,
                                           int repeat_last_n,
                                           float repeat_penalty);

#ifdef __cplusplus
}
#endif



#endif // GPT2
