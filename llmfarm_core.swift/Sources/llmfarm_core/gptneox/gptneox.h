#ifndef GPTNEOX_NEW_H
#define GPTNEOX_NEW_H

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>



#ifdef __cplusplus
extern "C" {
#endif


typedef int gpt_token;

struct gpt_context;
struct gpt_neox_context;


void gpt_neox_free(struct gpt_context * ctx);

const char * print_system_info(void);

//GPTNEOX_API struct gpt_context_params gpt_context_default_params();

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

struct gpt_neox_context * gpt_neox_init_from_file(const char * path_model, struct gpt_context_params params);

void gpt_shift_kv_cache(struct gpt_neox_context * ctx, int n);

int init_logits(struct gpt_neox_context * ctx,int   n_threads);

int gpt_neox_eval(
        struct gpt_neox_context * ctx,
           const gpt_token * tokens,
                         int   n_tokens,
                         int   n_past,
                         int   n_threads);

int gpt_neox_tokenize(
        struct gpt_neox_context * ctx,
                  const char * text,
                 gpt_token * tokens,
                         int   n_max_tokens,
                        bool   add_bos);

int gpt_neox_n_vocab(struct gpt_neox_context * ctx) ;
int gpt_neox_n_ctx(struct gpt_neox_context * ctx);
int gpt_neox_n_embd(struct gpt_neox_context * ctx);
float * gpt_neox_get_logits(struct gpt_neox_context * ctx);
float * gpt_neox_get_embeddings(struct gpt_neox_context * ctx);
gpt_token gpt_neox_token_bos();
gpt_token gpt_neox_token_eos();
gpt_token gpt_neox_str_to_token(struct gpt_neox_context * ctx, const char * str);
const char * gpt_neox_token_to_str(struct gpt_neox_context * ctx, gpt_token token);


int32_t gpt_sample(struct gpt_neox_context * ctx, int top_k, float top_p, float temp);
int32_t gpt_sample_repeat(struct gpt_neox_context * ctx,
                                           const int32_t * last_n_tokens_data,
                                           size_t last_n_tokens_data_size,
                                           int top_k, float top_p, float temp,
                                           int repeat_last_n,
                                           float repeat_penalty);

#ifdef __cplusplus
}
#endif


#endif // GPTNEOX_NEW_H
