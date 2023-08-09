#ifndef replit_H
#define replit_H

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>



#ifdef __cplusplus
extern "C" {
#endif


typedef int replit_token;

struct gpt_base_context;
struct replit_context;

void replit_free(struct replit_context * ctx);




struct gpt_context_params;

int replit_tokenize(
        struct replit_context * ctx,
                  const char * text,
                    replit_token * tokens,
                         int   n_max_tokens,
                    bool   add_bos);

struct replit_context * replit_init_from_file(const char * path_model, struct gpt_context_params params);



int replit_init_logits(struct replit_context * ctx,int   n_threads);

int replit_eval(
        struct replit_context * ctx,
           const replit_token * tokens,
                         int   n_tokens,
                         int   n_past,
                         int   n_threads);

const char * replit_token_to_str(struct replit_context * ctx, replit_token token);

int32_t replit_n_logits(struct replit_context * ctx);

int32_t replit_sample(struct replit_context * ctx, int top_k, float top_p, float temp);
int32_t replit_sample_repeat(struct replit_context * ctx,
                               const int32_t * last_n_tokens_data,
                               size_t last_n_tokens_data_size,
                               int top_k, float top_p, float temp,
                               int repeat_last_n,
                             float repeat_penalty);

#ifdef __cplusplus
}
#endif



#endif // replit
