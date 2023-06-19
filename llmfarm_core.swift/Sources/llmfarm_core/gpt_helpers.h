#pragma once

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>
#include "ggml.h"

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
