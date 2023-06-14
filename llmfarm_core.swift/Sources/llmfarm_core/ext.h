//
//  Header.h
//  
//
//  Created by guinmoon on 04.06.2023.
//
import "llama.h"

// Shifts the KV cache effectively removing the first n tokens
LLAMA_API void llama_shift_kv_cache(struct llama_context * ctx, int n);

void llama_shift_kv_cache(struct llama_context * ctx, int n) {
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
