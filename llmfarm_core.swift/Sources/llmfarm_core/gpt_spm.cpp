#include "../spm-headers/gpt_spm.h"
#include "gpt_helpers.h"
#include "ggml.h"
#include <cassert>
#include <cmath>
#include <cstdio>
#include <cstring>
#include <cinttypes>
#include <fstream>
#include <map>
#include <string>
#include <vector>
#include <random>



gpt_token gpt_base_token_bos(){
   return 0;
}

gpt_token gpt_base_token_eos() {
    return 0;
}

const char * print_system_info(void) {
    static std::string s;

    s  = "";
    s += "AVX = "         + std::to_string(ggml_cpu_has_avx())         + " | ";
    s += "AVX2 = "        + std::to_string(ggml_cpu_has_avx2())        + " | ";
    s += "AVX512 = "      + std::to_string(ggml_cpu_has_avx512())      + " | ";
    s += "AVX512_VBMI = " + std::to_string(ggml_cpu_has_avx512_vbmi()) + " | ";
    s += "AVX512_VNNI = " + std::to_string(ggml_cpu_has_avx512_vnni()) + " | ";
    s += "FMA = "         + std::to_string(ggml_cpu_has_fma())         + " | ";
    s += "NEON = "        + std::to_string(ggml_cpu_has_neon())        + " | ";
    s += "ARM_FMA = "     + std::to_string(ggml_cpu_has_arm_fma())     + " | ";
    s += "F16C = "        + std::to_string(ggml_cpu_has_f16c())        + " | ";
    s += "FP16_VA = "     + std::to_string(ggml_cpu_has_fp16_va())     + " | ";
    s += "WASM_SIMD = "   + std::to_string(ggml_cpu_has_wasm_simd())   + " | ";
    s += "BLAS = "        + std::to_string(ggml_cpu_has_blas())        + " | ";
    s += "SSE3 = "        + std::to_string(ggml_cpu_has_sse3())        + " | ";
    s += "VSX = "         + std::to_string(ggml_cpu_has_vsx())         + " | ";

    return s.c_str();
}

struct gpt_context_params gpt_context_default_params() {
    struct gpt_context_params result = {
        /*.n_ctx                       =*/ 512,
        /*.n_parts                     =*/ -1,
        /*.seed                        =*/ 0,
        /*.f16_kv                      =*/ false,
        /*.logits_all                  =*/ false,
        /*.vocab_only                  =*/ false,
        /*.use_mmap                    =*/ true,
        /*.use_mlock                   =*/ false,
        /*.embedding                   =*/ false,
        /*.progress_callback           =*/ nullptr,
        /*.progress_callback_user_data =*/ nullptr,
    };
    return result;
};


int gpt_base_n_vocab(struct gpt_base_context * ctx) {
    return ctx->vocab.id_to_token.size();
}

int gpt_base_n_ctx(struct gpt_base_context * ctx) {
    return ctx->model.hparams.n_ctx;
}

int gpt_base_n_embd(struct gpt_base_context * ctx) {
    return ctx->model.hparams.n_embd;
}

float * gpt_base_get_logits(struct gpt_base_context * ctx) {
    return ctx->logits.data();
}

float * gpt_base_get_embeddings(struct gpt_base_context * ctx) {
    return ctx->embedding.data();
}

gpt_token gpt_base_str_to_token(struct gpt_base_context * ctx, const char * str) {
    return ctx->vocab.token_to_id[str];
}

const char * gpt_base_token_to_str(struct gpt_base_context * ctx, gpt_token token) {
    if (token >= ctx->vocab.id_to_token.size()) {
        return nullptr;
    }
    return ctx->vocab.id_to_token[token].c_str();
}


int gpt_base_tokenize(
        struct gpt_base_context * ctx,
                  const char * text,
                 gpt_token * tokens,
                         int   n_max_tokens,
                        bool   add_bos) {
//    auto res = gptneox_tokenize(ctx->vocab, text, add_bos);
    auto res = gpt_tokenize(ctx->vocab, text);
    
    if (n_max_tokens < (int) res.size()) {
        fprintf(stderr, "%s: too many tokens\n", __func__);
        return -((int) res.size());
    }

    for (size_t i = 0; i < res.size(); i++) {
        tokens[i] = res[i];
    }

    return res.size();
}

void gpt_base_shift_kv_cache(struct gpt_base_context * ctx, int n) {
    auto & model = ctx->model;
    auto & kv_self = model.kv_self;
    auto & hparams = model.hparams;
    auto n_layer = hparams.n_layer;
    auto n_embd = hparams.n_embd;
    auto n_ctx = hparams.n_ctx;
    for(int il = 0; il < n_layer; il++) {
        // K: Embeddings are in regular order so moving them is easy as copying the memory
        {
            int elem_byte_size = ggml_element_size(kv_self.k);
            uint8_t * dst_ptr = ((uint8_t *)kv_self.k->data) + (elem_byte_size * n_embd * (il * n_ctx));
            uint8_t * src_ptr = ((uint8_t *)kv_self.k->data) + (elem_byte_size * n_embd * (il * n_ctx + n));
            memcpy(dst_ptr, src_ptr, elem_byte_size * n_embd * (n_ctx - n));
        }
        
        // V: Embeddings are transposed so each embedding element must be copied separately
        {
            int elem_byte_size = ggml_element_size(kv_self.v);
            for(int i = 0; i < n_embd; i++) {
                uint8_t * dst_ptr = ((uint8_t *)kv_self.v->data) + (elem_byte_size * (il * n_ctx * i));
                uint8_t * src_ptr = ((uint8_t *)kv_self.v->data) + (elem_byte_size * (il * n_ctx * i + n));
                memcpy(dst_ptr, src_ptr, elem_byte_size * (n_ctx - n));
            }
        }
    }
}



int32_t gpt_base_sample(struct gpt_base_context * ctx, int top_k, float top_p, float temp) {
    const int64_t t_start_sample_us = ggml_time_us();
    gpt_vocab::id smpl = gpt_sample_top_k_top_p(ctx->vocab, ctx->logits.data() + (ctx->logits.size() - ctx->vocab.id_to_token.size()), top_k, top_p, temp, ctx->rng);
    if (ctx) {
        ctx->t_sample_us += ggml_time_us() - t_start_sample_us;
    }
    return  smpl;
}


int32_t gpt_base_sample_repeat(struct gpt_base_context * ctx,
                               const int32_t * last_n_tokens_data,
                               size_t last_n_tokens_data_size,
                               int top_k, float top_p, float temp,
                               int repeat_last_n,
                               float repeat_penalty) {
    const int64_t t_start_sample_us = ggml_time_us();
    gpt_vocab::id smpl = gpt_sample_top_k_top_p_repeat(ctx->vocab, ctx->logits.data() + (ctx->logits.size() - ctx->vocab.id_to_token.size()),
                                                       last_n_tokens_data,last_n_tokens_data_size,
                                                       top_k, top_p, temp,
                                                       repeat_last_n,repeat_penalty,
                                                       ctx->rng);
    if (ctx) {
        ctx->t_sample_us += ggml_time_us() - t_start_sample_us;
    }
    return  smpl;
}
