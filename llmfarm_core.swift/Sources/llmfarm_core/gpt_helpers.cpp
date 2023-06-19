#include "gpt_helpers.h"
#include "ggml.h"

#include "common.h"
#include "common-ggml.h"

#include <cassert>
#include <cmath>
#include <cstdio>
#include <cstring>
#include <cinttypes>
#include <fstream>
#include <map>
#include <string>
#include <vector>

int test_fn()
{
    return 42;
}


static const std::map<e_model, size_t> & MEM_REQ_SCRATCH0()
{
    static std::map<e_model, size_t> k_sizes = {
        { MODEL_3B,    128ull * MB },
        { MODEL_7B,    512ull * MB_small },
        { MODEL_13B,   512ull * MB_small },
        { MODEL_30B,   512ull * MB_small },
        { MODEL_65B,  1024ull * MB_small },
    };
    return k_sizes;
}

static const std::map<e_model, size_t> & MEM_REQ_SCRATCH1()
{
    static std::map<e_model, size_t> k_sizes = {
        { MODEL_3B,    128ull * MB },
        { MODEL_7B,    512ull * MB_small },
        { MODEL_13B,   512ull * MB_small },
        { MODEL_30B,   512ull * MB_small },
        { MODEL_65B,  1024ull * MB_small },
    };
    return k_sizes;
}

// 2*n_embd*n_ctx*n_layer*sizeof(float16)
static const std::map<e_model, size_t> & MEM_REQ_KV_SELF()
{
    static std::map<e_model, size_t> k_sizes = {
        { MODEL_3B,    682ull * MB },
        { MODEL_7B,   1026ull * MB_small },
        { MODEL_13B,  1608ull * MB_small },
        { MODEL_30B,  3124ull * MB_small },
        { MODEL_65B,  5120ull * MB_small },
    };
    return k_sizes;
}

// this is mostly needed for temporary mul_mat buffers to dequantize the data
// not actually needed if BLAS is disabled
static const std::map<e_model, size_t> & MEM_REQ_EVAL()
{
    static std::map<e_model, size_t> k_sizes = {
        { MODEL_3B,   512ull * MB },
        { MODEL_7B,   768ull * MB_small },
        { MODEL_13B, 1024ull * MB_small },
        { MODEL_30B, 1280ull * MB_small },
        { MODEL_65B, 1536ull * MB_small },
    };
    return k_sizes;
}






