#pragma once

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>
#include "ggml.h"
#include "common.h"

#include <cassert>
#include <random>
#include <cmath>
#include <cstdio>
#include <cstring>
#include <cinttypes>
#include <fstream>
#include <map>
#include <string>
#include <vector>

#ifdef __cplusplus
extern "C" {
#endif

int test_fn();

static const size_t MB = 1024*1024;
static const size_t MB_small = 1024*1024;

enum e_model {
    MODEL_UNKNOWN,
    MODEL_3B,
    MODEL_7B,
    MODEL_13B,
    MODEL_30B,
    MODEL_65B,
};


struct gpt_base_hparams {
    int32_t n_vocab = 0;
    int32_t n_ctx   = 0;
    int32_t n_embd  = 0;
    int32_t n_head  = 0;
    int32_t n_layer = 0;
    int32_t n_rot   = 0; // rotary_pct * (n_embd / n_head)
    int32_t par_res = 0; // 1 = true, 0 = false
    int32_t ftype   = 0;
};

struct gpt_buffer {
    uint8_t * addr = NULL;
    size_t size = 0;

    void resize(size_t size) {
        delete[] addr;
        addr = new uint8_t[size];
        this->size = size;
    }

    ~gpt_buffer() {
        delete[] addr;
    }
};



struct gpt_kv_cache {
    struct ggml_tensor * k;
    struct ggml_tensor * v;

    struct ggml_context * ctx = NULL;

    gpt_buffer buf;

    int n; // number of tokens currently in the cache

    ~gpt_kv_cache() {
        if (ctx) {
            ggml_free(ctx);
        }
    }
};


static bool kv_cache_init(
        const struct gpt_base_hparams & hparams,
             struct gpt_kv_cache & cache,
                           ggml_type   wtype,
                                 int   n_ctx) {
    const int n_embd  = hparams.n_embd;
    const int n_layer = hparams.n_layer;

    const int64_t n_mem      = (int64_t)n_layer*n_ctx;
    const int64_t n_elements = n_embd*n_mem;

    cache.buf.resize(2u*n_elements*ggml_type_size(wtype) + 2u*MB);

    struct ggml_init_params params;
    params.mem_size   = cache.buf.size;
    params.mem_buffer = cache.buf.addr;
    params.no_alloc   = false;

    cache.ctx = ggml_init(params);

    if (!cache.ctx) {
        fprintf(stderr, "%s: failed to allocate memory for kv cache\n", __func__);
        return false;
    }

    cache.k = ggml_new_tensor_1d(cache.ctx, wtype, n_elements);
    cache.v = ggml_new_tensor_1d(cache.ctx, wtype, n_elements);

    return true;
}



struct gpt_base_model {
    e_model type = MODEL_UNKNOWN;
    
    gpt_base_hparams hparams;
    
    struct gpt_kv_cache kv_self;

    // normalization
    struct ggml_tensor * ln_f_g;
    struct ggml_tensor * ln_f_b;

    struct ggml_tensor * wte;     // position embedding
    struct ggml_tensor * wpe;     //    token embedding
    struct ggml_tensor * lm_head; // language model head

    

    // key + value memory
    struct ggml_tensor * memory_k;
    struct ggml_tensor * memory_v;

    //
    struct ggml_context * ctx;
    std::map<std::string, struct ggml_tensor *> tensors;
//    virtual ~gpt_base_model() {
//        if (ctx) {
//            ggml_free(ctx);
//        }
//    }
};



struct gpt_base_context {
    std::mt19937 rng;

    int64_t t_load_us = 0;
    int64_t t_start_us = 0;
    bool has_evaluated_once = false;

    int64_t t_sample_us = 0;
    int64_t t_eval_us   = 0;
    int64_t t_p_eval_us = 0;

    int32_t n_sample = 0; // number of tokens sampled
    int32_t n_eval   = 0; // number of eval calls
    int32_t n_p_eval = 0; // number of tokens in eval calls for the prompt (with batch size > 1)

    gpt_base_model model;
    gpt_vocab vocab;
    
    size_t mem_per_token = 0;

    // decode output (2-dimensional array: [n_tokens][n_vocab])
    std::vector<float> logits;
    bool logits_all = false;

    // input embedding (1-dimensional array: [n_embd])
    std::vector<float> embedding;

    
};



static const char *gpt_model_type_name(e_model type) {
    switch (type) {
        case MODEL_3B: return "3B";
        case MODEL_7B: return "7B";
        case MODEL_13B: return "13B";
        case MODEL_30B: return "30B";
        case MODEL_65B: return "65B";
        default: return "UNKNOWN";
    }
};



#ifdef __cplusplus
}
#endif
