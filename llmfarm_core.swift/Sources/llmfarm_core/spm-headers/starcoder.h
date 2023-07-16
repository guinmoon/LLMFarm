#ifndef starcoder_H
#define starcoder_H

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>



#ifdef __cplusplus
extern "C" {
#endif



typedef int starcoder_token;

struct gpt_base_context;
struct starcoder_context;


void starcoder_free(struct starcoder_context * ctx);


struct gpt_context_params;

struct starcoder_context * starcoder_init_from_file(const char * path_model, struct gpt_context_params params);


int starcoder_init_logits(struct starcoder_context * ctx,int   n_threads);

int starcoder_eval(
        struct starcoder_context * ctx,
           const starcoder_token * tokens,
                         int   n_tokens,
                         int   n_past,
                         int   n_threads);
#ifdef __cplusplus
}
#endif



#endif // starcoder
