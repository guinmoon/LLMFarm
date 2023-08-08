#include "../spm-headers/gptneox.h"
#include "../gpt_helpers.h"
#include "../spm-headers/gpt_spm.h"

#include "../ggml.h"

#include "../common.h"
#include "../common-ggml.h"

#include <cassert>
#include <cmath>
#include <cstdio>
#include <cstring>
#include <cinttypes>
#include <fstream>
#include <map>
#include <string>
#include <vector>


//#define GPTNEOX_USE_SCRATCH
//#define GPTNEOX_MAX_SCRATCH_BUFFERS 16

// default hparams (StableLM 3B)
//struct gpt_neox_hparams {
//    int32_t n_vocab = 50257;
//    int32_t n_ctx   = 4096;
//    int32_t n_embd  = 4096;
//    int32_t n_head  = 32;
//    int32_t n_layer = 16;
//    int32_t n_rot   = 32; // rotary_pct * (n_embd / n_head)
//    int32_t par_res = 1; // 1 = true, 0 = false
//    int32_t ftype   = 1;
//};





struct gpt_neox_layer {
    // pre normalization
    struct ggml_tensor * ln_1_g;
    struct ggml_tensor * ln_1_b;

    // attention
    struct ggml_tensor * c_attn_attn_w;
    struct ggml_tensor * c_attn_attn_b;

    struct ggml_tensor * c_attn_proj_w;
    struct ggml_tensor * c_attn_proj_b;

    // post normalization
    struct ggml_tensor * ln_2_g;
    struct ggml_tensor * ln_2_b;

    // ff
    struct ggml_tensor * c_mlp_fc_w;
    struct ggml_tensor * c_mlp_fc_b;

    struct ggml_tensor * c_mlp_proj_w;
    struct ggml_tensor * c_mlp_proj_b;
};

struct gpt_neox_hparams:gpt_base_hparams {
    int32_t n_vocab = 50257;
    int32_t n_ctx   = 4096;
    int32_t n_embd  = 1024;
    int32_t n_head  = 32;
    int32_t n_layer = 16;
    int32_t n_rot   = 32; // rotary_pct * (n_embd / n_head)
    int32_t par_res = 1; // 1 = true, 0 = false
    int32_t ftype   = 1;
};

struct gpt_neox_model:gpt_base_model {
    gpt_neox_hparams hparams;
    struct ggml_tensor * lmh_g; // language model head
    //struct ggml_tensor * lmh_b; // language model bias
    std::vector<gpt_neox_layer> layers;
};


struct gpt_neox_context:gpt_base_context {
    gpt_neox_model model;
};

void gpt_neox_free(struct gpt_neox_context * ctx) {
    delete ctx;
}

//void gpt_base_free(struct gpt_base_context * ctx) {
//    delete ctx;
//}





// load the model's weights from a file
bool gpt_neox_model_load(const std::string & fname, gpt_neox_model & model, gpt_vocab & vocab, int max_n_ctx) {
    printf("%s: loading model from '%s' - please wait ...\n", __func__, fname.c_str());

    auto fin = std::ifstream(fname, std::ios::binary);
    if (!fin) {
        fprintf(stderr, "%s: failed to open '%s'\n", __func__, fname.c_str());
        return false;
    }

    // verify magic
    {
        uint32_t magic;
        fin.read((char *) &magic, sizeof(magic));
        if (magic != 0x67676d6c) {
            fprintf(stderr, "%s: invalid model file '%s' (bad magic)\n", __func__, fname.c_str());
            return false;
        }
    }
    
    

    // load hparams
    {
        auto & hparams = model.hparams;
        
        fin.read((char *) &hparams.n_vocab, sizeof(hparams.n_vocab));
        fin.read((char *) &hparams.n_ctx,   sizeof(hparams.n_ctx));
        fin.read((char *) &hparams.n_embd,  sizeof(hparams.n_embd));
        fin.read((char *) &hparams.n_head,  sizeof(hparams.n_head));
        fin.read((char *) &hparams.n_layer, sizeof(hparams.n_layer));
        fin.read((char *) &hparams.n_rot,   sizeof(hparams.n_rot));
        fin.read((char *) &hparams.par_res, sizeof(hparams.par_res));
        fin.read((char *) &hparams.ftype,   sizeof(hparams.ftype));
        if (hparams.n_ctx>max_n_ctx){
            hparams.n_ctx = max_n_ctx;
        }
//        if (hparams.n_embd>2048){
//            hparams.n_embd = 2048;
//        }
        const int32_t qntvr = hparams.ftype / GGML_QNT_VERSION_FACTOR;
        
            
        printf("%s: n_vocab = %d\n", __func__, hparams.n_vocab);
        printf("%s: n_ctx   = %d\n", __func__, hparams.n_ctx);
        printf("%s: n_embd  = %d\n", __func__, hparams.n_embd);
        printf("%s: n_head  = %d\n", __func__, hparams.n_head);
        printf("%s: n_layer = %d\n", __func__, hparams.n_layer);
        printf("%s: n_rot   = %d\n", __func__, hparams.n_rot);
        printf("%s: par_res = %d\n", __func__, hparams.par_res);
        printf("%s: ftype   = %d\n", __func__, hparams.ftype);
        printf("%s: qntvr   = %d\n", __func__, qntvr);

        hparams.ftype %= GGML_QNT_VERSION_FACTOR;
    }

    // load vocab
    {
        const int32_t n_vocab = model.hparams.n_vocab;

        std::string word;
        std::vector<char> buf(128);

        for (int i = 0; i < n_vocab; i++) {
            uint32_t len;
            fin.read((char *) &len, sizeof(len));

            buf.resize(len);
            fin.read((char *) buf.data(), len);
            word.assign(buf.data(), len);

            vocab.token_to_id[word] = i;
            vocab.id_to_token[i] = word;
        }
    }

    // for the big tensors, we have the option to store the data in 16-bit floats or quantized
    // in order to save memory and also to speed up the computation
    ggml_type wtype = ggml_ftype_to_ggml_type((ggml_ftype) (model.hparams.ftype));
    if (wtype == GGML_TYPE_COUNT) {
        fprintf(stderr, "%s: invalid model file '%s' (bad ftype value %d)\n",
                __func__, fname.c_str(), model.hparams.ftype);
        return false;
    }

    auto & ctx = model.ctx;

    size_t ctx_size = 0;

    {
        const auto & hparams = model.hparams;

        const size_t n_embd  = hparams.n_embd;
        const size_t n_layer = hparams.n_layer;
        const size_t n_ctx   = hparams.n_ctx;
        const size_t n_vocab = hparams.n_vocab;

        ctx_size += n_embd*ggml_type_sizef(GGML_TYPE_F32); // ln_f_g
        ctx_size += n_embd*ggml_type_sizef(GGML_TYPE_F32); // ln_f_b

        ctx_size += n_embd*n_vocab*ggml_type_sizef(wtype); // wte

        ctx_size += n_embd*n_vocab*ggml_type_sizef(wtype);           // lmh_g
        //ctx_size +=        n_vocab*ggml_type_sizef(GGML_TYPE_F32); // lmh_b

        ctx_size += n_layer*(n_embd*ggml_type_sizef(GGML_TYPE_F32)); // ln_1_g
        ctx_size += n_layer*(n_embd*ggml_type_sizef(GGML_TYPE_F32)); // ln_1_b

        ctx_size += n_layer*(3*n_embd*n_embd*ggml_type_sizef(wtype));         // c_attn_attn_w
        ctx_size += n_layer*(       3*n_embd*ggml_type_sizef(GGML_TYPE_F32)); // c_attn_attn_b

        ctx_size += n_layer*(n_embd*n_embd*ggml_type_sizef(wtype));         // c_attn_proj_w
        ctx_size += n_layer*(n_embd*n_embd*ggml_type_sizef(GGML_TYPE_F32)); // c_attn_proj_b

        ctx_size += n_layer*(n_embd*ggml_type_sizef(GGML_TYPE_F32)); // ln_2_g
        ctx_size += n_layer*(n_embd*ggml_type_sizef(GGML_TYPE_F32)); // ln_2_b

        ctx_size += n_layer*(4*n_embd*n_embd*ggml_type_sizef(wtype));         // c_mlp_fc_w
        ctx_size += n_layer*(       4*n_embd*ggml_type_sizef(GGML_TYPE_F32)); // c_mlp_fc_b

        ctx_size += n_layer*(4*n_embd*n_embd*ggml_type_sizef(wtype));         // c_mlp_proj_w
        ctx_size += n_layer*(         n_embd*ggml_type_sizef(GGML_TYPE_F32)); // c_mlp_proj_b

        ctx_size += n_ctx*n_layer*n_embd*ggml_type_sizef(GGML_TYPE_F32); // memory_k
        ctx_size += n_ctx*n_layer*n_embd*ggml_type_sizef(GGML_TYPE_F32); // memory_v

        size_t overhead =ggml_tensor_overhead();
        ctx_size += (6 + 16*n_layer)*1024; // object overhead

        printf("%s: ggml ctx size = %6.2f MB\n", __func__, ctx_size/(1024.0*1024.0));
    }

    // create the ggml context
    {
        struct ggml_init_params params = {
            .mem_size   = ctx_size,
            .mem_buffer = NULL,
            .no_alloc   = false,
        };

        model.ctx = ggml_init(params);
        if (!model.ctx) {
            fprintf(stderr, "%s: ggml_init() failed\n", __func__);
            return false;
        }
    }

    // prepare memory for the weights
    {
        const auto & hparams = model.hparams;

        const int n_embd  = hparams.n_embd;
        const int n_layer = hparams.n_layer;
        const int n_vocab = hparams.n_vocab;

        model.layers.resize(n_layer);

        model.wte    = ggml_new_tensor_2d(ctx, wtype,         n_embd, n_vocab);

        model.ln_f_g = ggml_new_tensor_1d(ctx, GGML_TYPE_F32, n_embd);
        model.ln_f_b = ggml_new_tensor_1d(ctx, GGML_TYPE_F32, n_embd);

        model.lmh_g  = ggml_new_tensor_2d(ctx, wtype,         n_embd, n_vocab);
        //model.lmh_b  = ggml_new_tensor_1d(ctx, GGML_TYPE_F32, n_vocab);

        // map by name
        model.tensors["gpt_neox.embed_in.weight"] = model.wte;

        model.tensors["gpt_neox.final_layer_norm.weight"] = model.ln_f_g;
        model.tensors["gpt_neox.final_layer_norm.bias"]   = model.ln_f_b;

        model.tensors["embed_out.weight"] = model.lmh_g;
        //model.tensors["lm_head.bias"]   = model.lmh_b;

        for (int i = 0; i < n_layer; ++i) {
            auto & layer = model.layers[i];

            layer.ln_1_g          = ggml_new_tensor_1d(ctx, GGML_TYPE_F32,   n_embd);
            layer.ln_1_b          = ggml_new_tensor_1d(ctx, GGML_TYPE_F32,   n_embd);

            layer.c_attn_attn_w   = ggml_new_tensor_2d(ctx, wtype,           n_embd, 3*n_embd);
            layer.c_attn_attn_b   = ggml_new_tensor_1d(ctx, GGML_TYPE_F32, 3*n_embd);

            layer.c_attn_proj_w   = ggml_new_tensor_2d(ctx, wtype,           n_embd,   n_embd);
            layer.c_attn_proj_b   = ggml_new_tensor_1d(ctx, GGML_TYPE_F32,   n_embd);

            layer.ln_2_g          = ggml_new_tensor_1d(ctx, GGML_TYPE_F32,   n_embd);
            layer.ln_2_b          = ggml_new_tensor_1d(ctx, GGML_TYPE_F32,   n_embd);

            layer.c_mlp_fc_w      = ggml_new_tensor_2d(ctx, wtype,           n_embd, 4*n_embd);
            layer.c_mlp_fc_b      = ggml_new_tensor_1d(ctx, GGML_TYPE_F32, 4*n_embd);

            layer.c_mlp_proj_w    = ggml_new_tensor_2d(ctx, wtype,         4*n_embd,   n_embd);
            layer.c_mlp_proj_b    = ggml_new_tensor_1d(ctx, GGML_TYPE_F32,   n_embd);

            // map by name
            model.tensors["gpt_neox.layers." + std::to_string(i) + ".input_layernorm.weight"] = layer.ln_1_g;
            model.tensors["gpt_neox.layers." + std::to_string(i) + ".input_layernorm.bias"]   = layer.ln_1_b;

            model.tensors["gpt_neox.layers." + std::to_string(i) + ".attention.query_key_value.weight"] = layer.c_attn_attn_w;
            model.tensors["gpt_neox.layers." + std::to_string(i) + ".attention.query_key_value.bias"]   = layer.c_attn_attn_b;

            model.tensors["gpt_neox.layers." + std::to_string(i) + ".attention.dense.weight"] = layer.c_attn_proj_w;
            model.tensors["gpt_neox.layers." + std::to_string(i) + ".attention.dense.bias"]   = layer.c_attn_proj_b;

            model.tensors["gpt_neox.layers." + std::to_string(i) + ".post_attention_layernorm.weight"] = layer.ln_2_g;
            model.tensors["gpt_neox.layers." + std::to_string(i) + ".post_attention_layernorm.bias"]   = layer.ln_2_b;

            model.tensors["gpt_neox.layers." + std::to_string(i) + ".mlp.dense_h_to_4h.weight"] = layer.c_mlp_fc_w;
            model.tensors["gpt_neox.layers." + std::to_string(i) + ".mlp.dense_h_to_4h.bias"]   = layer.c_mlp_fc_b;

            model.tensors["gpt_neox.layers." + std::to_string(i) + ".mlp.dense_4h_to_h.weight"] = layer.c_mlp_proj_w;
            model.tensors["gpt_neox.layers." + std::to_string(i) + ".mlp.dense_4h_to_h.bias"]   = layer.c_mlp_proj_b;
        }
    }

    // key + value memory
    {
        const auto & hparams = model.hparams;

        const int n_embd  = hparams.n_embd;
        const int n_layer = hparams.n_layer;
        const int n_ctx   = hparams.n_ctx;

        const int64_t n_mem      = n_layer*n_ctx;
        const int64_t n_elements = n_embd*n_mem;

        model.memory_k = ggml_new_tensor_1d(ctx, GGML_TYPE_F16, n_elements);
        model.memory_v = ggml_new_tensor_1d(ctx, GGML_TYPE_F16, n_elements);

        const size_t memory_size = ggml_nbytes(model.memory_k) + ggml_nbytes(model.memory_v);

        printf("%s: memory_size = %8.2f MB, n_mem = %" PRId64 "\n", __func__, memory_size/1024.0/1024.0, n_mem);
    }

    // load weights
    {
        int n_tensors = 0;
        size_t total_size = 0;

        printf("%s: ", __func__);

        while (true) {
            int32_t n_dims;
            int32_t length;
            int32_t ttype;

            fin.read(reinterpret_cast<char *>(&n_dims), sizeof(n_dims));
            fin.read(reinterpret_cast<char *>(&length), sizeof(length));
            fin.read(reinterpret_cast<char *>(&ttype),  sizeof(ttype));

            if (fin.eof()) {
                break;
            }

            int32_t nelements = 1;
            int32_t ne[2] = { 1, 1 };
            for (int i = 0; i < n_dims; ++i) {
                fin.read(reinterpret_cast<char *>(&ne[i]), sizeof(ne[i]));
                nelements *= ne[i];
            }

            std::string name(length, 0);
            fin.read(&name[0], length);

            if (model.tensors.find(name.data()) == model.tensors.end()) {
                fprintf(stderr, "%s: unknown tensor '%s' in model file\n", __func__, name.data());
                return false;
            }

            auto tensor = model.tensors[name.data()];
            if (ggml_nelements(tensor) != nelements) {
                fprintf(stderr, "%s: tensor '%s' has wrong size in model file\n", __func__, name.data());
                return false;
            }

            if (tensor->ne[0] != ne[0] || tensor->ne[1] != ne[1]) {
                fprintf(stderr, "%s: tensor '%s' has wrong shape in model file: got [%5d, %5d], expected [%5d, %5d]\n",
                        __func__, name.data(), (int) tensor->ne[0], (int) tensor->ne[1], ne[0], ne[1]);
                return false;
            }

            // for debugging
            if (0) {
                printf("%24s - [%5d, %5d], type = %6s, %6.2f MB, %9zu bytes\n", name.data(), ne[0], ne[1], ggml_type_name(ggml_type(ttype)), ggml_nbytes(tensor)/1024.0/1024.0, ggml_nbytes(tensor));
            }

            const size_t bpe = ggml_type_size(ggml_type(ttype));

            if ((nelements*bpe)/ggml_blck_size(tensor->type) != ggml_nbytes(tensor)) {
                fprintf(stderr, "%s: tensor '%s' has wrong size in model file: got %zu, expected %zu\n",
                        __func__, name.data(), ggml_nbytes(tensor), nelements*bpe);
                return false;
            }

            fin.read(reinterpret_cast<char *>(tensor->data), ggml_nbytes(tensor));

            total_size += ggml_nbytes(tensor);
            if (++n_tensors % 8 == 0) {
                printf(".");
                fflush(stdout);
            }
        }

        printf(" done\n");

        printf("%s: model size = %8.2f MB / num tensors = %d\n", __func__, total_size/1024.0/1024.0, n_tensors);
    }

    fin.close();

    return true;
}


// feed-forward network
ggml_tensor * gpt_neox_ff(
        const gpt_neox_layer &layer,
        ggml_context * ctx0,
        ggml_tensor * inp) {
    ggml_tensor * cur = ggml_norm(ctx0, inp);

    cur = ggml_add(ctx0,
        ggml_mul(ctx0,
            ggml_repeat(ctx0, layer.ln_2_g, cur),
            cur),
        ggml_repeat(ctx0, layer.ln_2_b, cur));

    cur = ggml_mul_mat(ctx0,
            layer.c_mlp_fc_w,
            cur);

    cur = ggml_add(ctx0,
            ggml_repeat(ctx0, layer.c_mlp_fc_b, cur),
            cur);

    // GELU activation
    cur = ggml_gelu(ctx0, cur);

    // projection
    // cur = proj_w*cur + proj_b
    cur = ggml_mul_mat(ctx0,
            layer.c_mlp_proj_w,
            cur);

    cur = ggml_add(ctx0,
            ggml_repeat(ctx0, layer.c_mlp_proj_b, cur),
            cur);
    return cur;
}

// evaluate the transformer
//
//   - model:     the model
//   - n_threads: number of threads to use
//   - n_past:    the context size so far
//   - embd_inp:  the embeddings of the tokens in the context
//   - embd_w:    the predicted logits for the next token
//
bool gpt_neox_eval(
        const gpt_neox_model & model,
        const int n_threads,
        const int n_past,
        const std::vector<gpt_vocab::id> & embd_inp,
              std::vector<float>         & embd_w,
              size_t                     & mem_per_token) {
    const int N = embd_inp.size();

    const auto & hparams = model.hparams;

    const int n_embd  = hparams.n_embd;
    const int n_layer = hparams.n_layer;
    const int n_ctx   = hparams.n_ctx;
    const int n_head  = hparams.n_head;
    const int n_vocab = hparams.n_vocab;
    const int n_rot   = hparams.n_rot;

    static size_t buf_size = 256u*1024*1024;
//    static size_t buf_size = 256u*1024*ggml_tensor_overhead();
    static void * buf = malloc(buf_size);

    // use 2 scratch buffers
    // TODO: very hacky solution - reimplement in a more elegant way
    static size_t scr0_size = 256u*1024*1024;
    static void * scr0 = malloc(scr0_size);

    static size_t scr1_size = 256u*1024*1024;
    static void * scr1 = malloc(scr1_size);

    if (mem_per_token > 0 && mem_per_token*N > buf_size) {
        const size_t buf_size_new = 1.1*(mem_per_token*N); // add 10% to account for ggml object overhead
        //printf("\n%s: reallocating buffer from %zu to %zu bytes\n", __func__, buf_size, buf_size_new);

        // reallocate
        buf_size = buf_size_new;
        buf = realloc(buf, buf_size);
        if (buf == nullptr) {
            fprintf(stderr, "%s: failed to allocate %zu bytes\n", __func__, buf_size);
            return false;
        }
    }

    struct ggml_init_params params = {
        /*.mem_size   =*/ buf_size,
        /*.mem_buffer =*/ buf,
        /*.no_alloc   =*/ false,
    };

    struct ggml_context * ctx0 = ggml_init(params);
    struct ggml_cgraph gf = {};

    struct ggml_tensor * embd = ggml_new_tensor_1d(ctx0, GGML_TYPE_I32, N);
    memcpy(embd->data, embd_inp.data(), N*ggml_element_size(embd));

    // wte
    struct ggml_tensor * inpL = ggml_get_rows(ctx0, model.wte, embd);

    for (int il = 0; il < n_layer; ++il) {
        struct ggml_tensor * cur;

        ggml_set_scratch(ctx0, { 0, scr0_size, scr0, });

        // self-attention
        {
            {
                cur = ggml_norm(ctx0, inpL);

                cur = ggml_add(ctx0,
                        ggml_mul(ctx0,
                            ggml_repeat(ctx0, model.layers[il].ln_1_g, cur),
                            cur),
                        ggml_repeat(ctx0, model.layers[il].ln_1_b, cur));
            }

            // compute QKV
            {
                cur = ggml_mul_mat(ctx0,
                        model.layers[il].c_attn_attn_w,
                        cur);

                cur = ggml_add(ctx0,
                        ggml_repeat(ctx0, model.layers[il].c_attn_attn_b, cur),
                        cur);
            }

            struct ggml_tensor * Qcur = ggml_cont(ctx0, ggml_view_3d(ctx0, cur, n_embd/n_head, n_head, N, cur->nb[1]/n_head, cur->nb[1], 0*sizeof(float)*n_embd/n_head));
            struct ggml_tensor * Kcur = ggml_cont(ctx0, ggml_view_3d(ctx0, cur, n_embd/n_head, n_head, N, cur->nb[1]/n_head, cur->nb[1], 1*sizeof(float)*n_embd/n_head));
            struct ggml_tensor * Vcur = ggml_cont(ctx0, ggml_view_3d(ctx0, cur, n_embd/n_head, n_head, N, cur->nb[1]/n_head, cur->nb[1], 2*sizeof(float)*n_embd/n_head));

            // using mode = 2 for GPT-NeoX mode
            Qcur = ggml_rope_inplace(ctx0, Qcur, n_past, n_rot, 2, 0);
            Kcur = ggml_rope_inplace(ctx0, Kcur, n_past, n_rot, 2, 0);

            // store key and value to memory
            {
                Vcur = ggml_transpose(ctx0, ggml_reshape_2d(ctx0, Vcur, n_embd, N));

                struct ggml_tensor * k = ggml_view_1d(ctx0, model.memory_k, N*n_embd, (ggml_element_size(model.memory_k)*n_embd)*(il*n_ctx + n_past));
                struct ggml_tensor * v = ggml_view_2d(ctx0, model.memory_v, N, n_embd,
                        (   n_ctx)*ggml_element_size(model.memory_v),
                        (il*n_ctx)*ggml_element_size(model.memory_v)*n_embd + n_past*ggml_element_size(model.memory_v));

                ggml_build_forward_expand(&gf, ggml_cpy(ctx0, Kcur, k));
                ggml_build_forward_expand(&gf, ggml_cpy(ctx0, Vcur, v));
            }

            // Q = Qcur.contiguous().view(n_embd/n_head, n_head, N).permute(0, 2, 1, 3)
            struct ggml_tensor * Q =
                ggml_permute(ctx0,
                        Qcur,
                        0, 2, 1, 3);

            // K = Kmem.view(n_embd/n_head, n_head, n_past + N).permute(0, 2, 1, 3)
            struct ggml_tensor * K =
                ggml_permute(ctx0,
                        ggml_reshape_3d(ctx0,
                            ggml_view_1d(ctx0, model.memory_k, (n_past + N)*n_embd, il*n_ctx*ggml_element_size(model.memory_k)*n_embd),
                            n_embd/n_head, n_head, n_past + N),
                        0, 2, 1, 3);

            // K * Q
            struct ggml_tensor * KQ = ggml_mul_mat(ctx0, K, Q);

            // KQ_scaled = KQ / sqrt(n_embd/n_head)
            struct ggml_tensor * KQ_scaled =
                ggml_scale_inplace(ctx0,
                        KQ,
                        ggml_new_f32(ctx0, 1.0f/sqrt(float(n_embd)/n_head))
                        );

            // KQ_masked = mask_past(KQ_scaled)
            struct ggml_tensor * KQ_masked = ggml_diag_mask_inf_inplace(ctx0, KQ_scaled, n_past);

            // KQ = soft_max(KQ_masked)
            struct ggml_tensor * KQ_soft_max = ggml_soft_max_inplace(ctx0, KQ_masked);

            // V_trans = Vmem.view(n_embd/n_head, n_head, n_past + N).permute(1, 2, 0, 3).contiguous()
            struct ggml_tensor * V =
                ggml_view_3d(ctx0, model.memory_v,
                        n_past + N, n_embd/n_head, n_head,
                        n_ctx*ggml_element_size(model.memory_v),
                        n_ctx*ggml_element_size(model.memory_v)*n_embd/n_head,
                        il*n_ctx*ggml_element_size(model.memory_v)*n_embd);

            // KQV = transpose(V) * KQ_soft_max
            struct ggml_tensor * KQV = ggml_mul_mat(ctx0, V, KQ_soft_max);

            // KQV_merged = KQV.permute(0, 2, 1, 3)
            struct ggml_tensor * KQV_merged = ggml_permute(ctx0, KQV, 0, 2, 1, 3);

            // cur = KQV_merged.contiguous().view(n_embd, N)
            cur = ggml_cpy(ctx0,
                    KQV_merged,
                    ggml_new_tensor_2d(ctx0, GGML_TYPE_F32, n_embd, N));

            // projection
            {
                cur = ggml_mul_mat(ctx0,
                        model.layers[il].c_attn_proj_w,
                        cur);

                cur = ggml_add(ctx0, ggml_repeat(ctx0, model.layers[il].c_attn_proj_b, cur), cur);
            }
        }

        ggml_set_scratch(ctx0, { 0, scr1_size, scr1, });

        if (hparams.par_res == 0) {
            struct ggml_tensor * inpFF = ggml_add(ctx0, cur, inpL);

            cur = gpt_neox_ff(model.layers[il], ctx0, inpFF);

            // input for next layer
            inpL = ggml_add(ctx0, cur, inpFF);
        } else {
            struct ggml_tensor * inpFF = cur;

            // this is independent of the self-attention result, so it could be done in parallel to the self-attention
            // note here we pass inpL instead of cur
            cur = gpt_neox_ff(model.layers[il], ctx0, inpL);

            // layer input + FF
            cur  = ggml_add(ctx0, cur, inpFF);

            // input for next layer
            inpL = ggml_add(ctx0, cur, inpL);
        }
    }

    ggml_set_scratch(ctx0, { 0, scr0_size, scr0, });

    // norm
    {
        inpL = ggml_norm(ctx0, inpL);

        // inpL = ln_f_g*inpL + ln_f_b
        inpL = ggml_add(ctx0,
                ggml_mul(ctx0,
                    ggml_repeat(ctx0, model.ln_f_g, inpL),
                    inpL),
                ggml_repeat(ctx0, model.ln_f_b, inpL));
    }

    ggml_set_scratch(ctx0, { 0, 0, nullptr, });

    // lm_head
    {
        inpL = ggml_mul_mat(ctx0, model.lmh_g, inpL);

        //inpL = ggml_add(ctx0,
        //        ggml_repeat(ctx0, model.lmh_b, inpL),
        //        inpL);
    }

    // logits -> probs
    //inpL = ggml_soft_max_inplace(ctx0, inpL);

    // run the computation
    ggml_build_forward_expand(&gf, inpL);
    ggml_graph_compute_with_ctx(ctx0, &gf, n_threads);

    //if (n_past%100 == 0) {
    //    ggml_graph_print   (&gf);
    //    ggml_graph_dump_dot(&gf, NULL, "gpt-2.dot");
    //}

    //embd_w.resize(n_vocab*N);
    //memcpy(embd_w.data(), ggml_get_data(inpL), sizeof(float)*n_vocab*N);

    // return result for just the last token
    embd_w.resize(n_vocab);
    memcpy(embd_w.data(), (float *) ggml_get_data(inpL) + (n_vocab*(N-1)), sizeof(float)*n_vocab);

    if (mem_per_token == 0) {
        mem_per_token = ggml_used_mem(ctx0)/N;
    }
    //printf("used_mem = %zu\n", ggml_used_mem(ctx0));

    ggml_free(ctx0);

    return true;
}





struct gpt_neox_context * gpt_neox_init_from_file(const char * path_model, struct gpt_context_params   params) {
    ggml_time_init();

    gpt_neox_context * ctx = new gpt_neox_context;

    if (params.seed <= 0) {
        params.seed = time(NULL);
    }

    

    ctx->rng = std::mt19937(params.seed);
    ctx->logits_all = params.logits_all;

    ggml_type memory_type = params.f16_kv ? GGML_TYPE_F16 : GGML_TYPE_F32;
    
    if (!gpt_neox_model_load(path_model, ctx->model, ctx->vocab,params.n_ctx)) {
        fprintf(stderr, "%s: failed to load model\n", __func__);
        gpt_neox_free(ctx);
        return nullptr;
    }

    // reserve memory for context buffers
    if (!params.vocab_only) {
//        if (!kv_cache_init(ctx->model.hparams, ctx->model.kv_self, memory_type, ctx->model.hparams.n_ctx)) {
//            fprintf(stderr, "%s: kv_cache_init() failed for self-attention cache\n", __func__);
//            gpt_neox_free(ctx);            
//            return nullptr;
//        }
//
//        {
//            const size_t memory_size = ggml_nbytes(ctx->model.kv_self.k) + ggml_nbytes(ctx->model.kv_self.v);
//            fprintf(stderr, "%s: kv self size  = %7.2f MiB\n", __func__, memory_size / 1024.0 / 1024.0);
//        }

        const auto & hparams = ctx->model.hparams;

        // resized during inference
        if (params.logits_all) {
            ctx->logits.reserve(hparams.n_ctx*hparams.n_vocab);
        } else {
            ctx->logits.reserve(hparams.n_vocab);
        }

        if (params.embedding){
            ctx->embedding.resize(hparams.n_embd);
        }

//        ctx->buf_compute.resize(MEM_REQ_EVAL().at(ctx->model.type));
//
//        ctx->buf_scratch[0].resize(MEM_REQ_SCRATCH0().at(ctx->model.type));
//        ctx->buf_scratch[1].resize(MEM_REQ_SCRATCH1().at(ctx->model.type));
    }

    return ctx;
}

//int gpt_neox_eval_first(struct gpt_neox_context * ctx,
//                        const gpt_neox_token * tokens,
//                                      int   n_tokens,
//                                      int   n_past,
//                        int   n_threads){
//
//}


//void gpt_shift_kv_cache(struct gpt_neox_context * ctx, int n) {
//    auto & model = ctx->model;
//    auto & kv_self = model.kv_self;
//    auto & hparams = model.hparams;
//    auto n_layer = hparams.n_layer;
//    auto n_embd = hparams.n_embd;
//    auto n_ctx = hparams.n_ctx;
//    for(int il = 0; il < n_layer; il++) {
//        // K: Embeddings are in regular order so moving them is easy as copying the memory
//        {
//            int elem_byte_size = ggml_element_size(kv_self.k);
//            uint8_t * dst_ptr = ((uint8_t *)kv_self.k->data) + (elem_byte_size * n_embd * (il * n_ctx));
//            uint8_t * src_ptr = ((uint8_t *)kv_self.k->data) + (elem_byte_size * n_embd * (il * n_ctx + n));
//            memcpy(dst_ptr, src_ptr, elem_byte_size * n_embd * (n_ctx - n));
//        }
//        
//        // V: Embeddings are transposed so each embedding element must be copied separately
//        {
//            int elem_byte_size = ggml_element_size(kv_self.v);
//            for(int i = 0; i < n_embd; i++) {
//                uint8_t * dst_ptr = ((uint8_t *)kv_self.v->data) + (elem_byte_size * (il * n_ctx * i));
//                uint8_t * src_ptr = ((uint8_t *)kv_self.v->data) + (elem_byte_size * (il * n_ctx * i + n));
//                memcpy(dst_ptr, src_ptr, elem_byte_size * (n_ctx - n));
//            }
//        }
//    }
//}


int gpt_neox_init_logits(struct gpt_neox_context * ctx,int   n_threads){
    size_t mem_per_token = 0;
    if (!gpt_neox_eval(ctx->model, n_threads, 0, { 0, 1, 2, 3 }, ctx->logits, mem_per_token)) {
        fprintf(stderr, "%s: failed to eval\n", __func__);
        return 1;
    }
    return  0;
}

int gpt_neox_eval(
        struct gpt_neox_context * ctx,
           const gpt_token * tokens,
                         int   n_tokens,
                         int   n_past,
                  int   n_threads) {
    
//    std::vector<float> logits;
    std::vector<gpt_vocab::id> embd;
    for (int i=0;i<n_tokens;i++){
        embd.push_back(tokens[i]);
    }
    size_t mem_per_token = 0;
//    gpt_neox_eval(ctx->model, n_threads, 0, { 0, 1, 2, 3 }, ctx->logits, mem_per_token);
    //    if (!gptneox_eval_internal(*ctx, tokens, n_tokens, n_past, n_threads)) {
    if (!gpt_neox_eval(ctx->model, n_threads, n_past, embd, ctx->logits, mem_per_token)) {
        fprintf(stderr, "%s: failed to eval\n", __func__);
        return 1;
    }
    // get a more accurate load time, upon first eval
    if (!ctx->has_evaluated_once) {
        ctx->t_load_us = ggml_time_us() - ctx->t_start_us;
        ctx->has_evaluated_once = true;
    }
    return 0;
}

//int gpt_neox_tokenize(
//        struct gpt_base_context * ctx,
//                  const char * text,
//                 gpt_token * tokens,
//                         int   n_max_tokens,
//                        bool   add_bos) {
////    auto res = gptneox_tokenize(ctx->vocab, text, add_bos);
//    auto res = gpt_tokenize(ctx->vocab, text);
//    
//    if (n_max_tokens < (int) res.size()) {
//        fprintf(stderr, "%s: too many tokens\n", __func__);
//        return -((int) res.size());
//    }
//
//    for (size_t i = 0; i < res.size(); i++) {
//        tokens[i] = res[i];
//    }
//
//    return res.size();
//}

//const char * print_system_info(void) {
//    static std::string s;
//
//    s  = "";
//    s += "AVX = "         + std::to_string(ggml_cpu_has_avx())         + " | ";
//    s += "AVX2 = "        + std::to_string(ggml_cpu_has_avx2())        + " | ";
//    s += "AVX512 = "      + std::to_string(ggml_cpu_has_avx512())      + " | ";
//    s += "AVX512_VBMI = " + std::to_string(ggml_cpu_has_avx512_vbmi()) + " | ";
//    s += "AVX512_VNNI = " + std::to_string(ggml_cpu_has_avx512_vnni()) + " | ";
//    s += "FMA = "         + std::to_string(ggml_cpu_has_fma())         + " | ";
//    s += "NEON = "        + std::to_string(ggml_cpu_has_neon())        + " | ";
//    s += "ARM_FMA = "     + std::to_string(ggml_cpu_has_arm_fma())     + " | ";
//    s += "F16C = "        + std::to_string(ggml_cpu_has_f16c())        + " | ";
//    s += "FP16_VA = "     + std::to_string(ggml_cpu_has_fp16_va())     + " | ";
//    s += "WASM_SIMD = "   + std::to_string(ggml_cpu_has_wasm_simd())   + " | ";
//    s += "BLAS = "        + std::to_string(ggml_cpu_has_blas())        + " | ";
//    s += "SSE3 = "        + std::to_string(ggml_cpu_has_sse3())        + " | ";
//    s += "VSX = "         + std::to_string(ggml_cpu_has_vsx())         + " | ";
//
//    return s.c_str();
//}

//int gpt_neox_n_vocab(struct gpt_base_context * ctx) {
//    return ctx->vocab.id_to_token.size();
//}
//
//int gpt_neox_n_ctx(struct gpt_base_context * ctx) {
//    return ctx->model.hparams.n_ctx;
//}
//
//int gpt_neox_n_embd(struct gpt_base_context * ctx) {
//    return ctx->model.hparams.n_embd;
//}
//
//float * gpt_neox_get_logits(struct gpt_base_context * ctx) {
//    return ctx->logits.data();
//}
//
//float * gpt_neox_get_embeddings(struct gpt_base_context * ctx) {
//    return ctx->embedding.data();
//}
//
//gpt_token gpt_neox_str_to_token(struct gpt_base_context * ctx, const char * str) {
//    return ctx->vocab.token_to_id[str];
//}
//
//const char * gpt_neox_token_to_str(struct gpt_base_context * ctx, gpt_token token) {
//    if (token >= ctx->vocab.id_to_token.size()) {
//        return nullptr;
//    }
//    return ctx->vocab.id_to_token[token].c_str();
//}




//
//int32_t gpt_sample(struct gpt_neox_context * ctx, int top_k, float top_p, float temp) {
//    const int64_t t_start_sample_us = ggml_time_us();
//    gpt_vocab::id smpl = gpt_sample_top_k_top_p(ctx->vocab, ctx->logits.data() + (ctx->logits.size() - ctx->vocab.id_to_token.size()), top_k, top_p, temp, ctx->rng);
//    if (ctx) {
//        ctx->t_sample_us += ggml_time_us() - t_start_sample_us;
//    }
//    return  smpl;
//}
//
//
//int32_t gpt_sample_repeat(struct gpt_neox_context * ctx,
//                               const int32_t * last_n_tokens_data,
//                               size_t last_n_tokens_data_size,
//                               int top_k, float top_p, float temp,
//                               int repeat_last_n,
//                               float repeat_penalty) {
//    const int64_t t_start_sample_us = ggml_time_us();
//    gpt_vocab::id smpl = gpt_sample_top_k_top_p_repeat(ctx->vocab, ctx->logits.data() + (ctx->logits.size() - ctx->vocab.id_to_token.size()),
//                                                       last_n_tokens_data,last_n_tokens_data_size,
//                                                       top_k, top_p, temp,
//                                                       repeat_last_n,repeat_penalty,
//                                                       ctx->rng);
//    if (ctx) {
//        ctx->t_sample_us += ggml_time_us() - t_start_sample_us;
//    }
//    return  smpl;
//}

//
//int test_run() {
//    ggml_time_init();
//
//    const int64_t t_main_start_us = ggml_time_us();
//
//    gpt_params params;
//    params.model = "models/stablelm-base-alpha-3b/ggml-model-f16.bin";
//
////    if (gpt_params_parse(argc, argv, params) == false) {
////        return 1;
////    }
//
//    if (params.seed < 0) {
//        params.seed = time(NULL);
//    }
//
//    printf("%s: seed = %d\n", __func__, params.seed);
//
//    std::mt19937 rng(params.seed);
////    if (params.prompt.empty()) {
////        params.prompt = gpt_random_prompt(rng);
////    }
//
//    int64_t t_load_us = 0;
//
//    gpt_vocab vocab;
//    gpt_neox_model model;
//
//    // load the model
//    {
//        const int64_t t_start_us = ggml_time_us();
//
//        if (!gpt_neox_model_load(params.model, model, vocab,1024)) {
//            fprintf(stderr, "%s: failed to load model from '%s'\n", __func__, params.model.c_str());
//            return 1;
//        }
//
//        t_load_us = ggml_time_us() - t_start_us;
//
//        test_gpt_tokenizer(vocab, params.token_test);
//    }
//
//    int n_past = 0;
//
//    int64_t t_sample_us  = 0;
//    int64_t t_predict_us = 0;
//
//    std::vector<float> logits;
//
//    // tokenize the prompt
//    std::vector<gpt_vocab::id> embd_inp = ::gpt_tokenize(vocab, params.prompt);
//
//    params.n_predict = std::min(params.n_predict, model.hparams.n_ctx - (int) embd_inp.size());
//
//    printf("%s: number of tokens in prompt = %zu\n", __func__, embd_inp.size());
//    for (int i = 0; i < embd_inp.size(); i++) {
//        printf("%s: token[%d] = %6d, %s\n", __func__, i, embd_inp[i], vocab.id_to_token.at(embd_inp[i]).c_str());
//    }
//    printf("\n");
//
//    std::vector<gpt_vocab::id> embd;
//
//    // determine the required inference memory per token:
//    size_t mem_per_token = 0;
//    gpt_neox_eval(model, params.n_threads, 0, { 0, 1, 2, 3 }, logits, mem_per_token);
//
//    for (int i = embd.size(); i < embd_inp.size() + params.n_predict; i++) {
//        // predict
//        if (embd.size() > 0) {
//            const int64_t t_start_us = ggml_time_us();
//
//            if (!gpt_neox_eval(model, params.n_threads, n_past, embd, logits, mem_per_token)) {
//                printf("Failed to predict\n");
//                return 1;
//            }
//
//            t_predict_us += ggml_time_us() - t_start_us;
//        }
//
//        n_past += embd.size();
//        embd.clear();
//
//        if (i >= embd_inp.size()) {
//            // sample next token
//            const int   top_k = params.top_k;
//            const float top_p = params.top_p;
//            const float temp  = params.temp;
//
//            const int n_vocab = model.hparams.n_vocab;
//
//            gpt_vocab::id id = 0;
//
//            {
//                const int64_t t_start_sample_us = ggml_time_us();
//
//                id = gpt_sample_top_k_top_p(vocab, logits.data() + (logits.size() - n_vocab), top_k, top_p, temp, rng);
//
//                t_sample_us += ggml_time_us() - t_start_sample_us;
//            }
//
//            // add it to the context
//            embd.push_back(id);
//        } else {
//            // if here, it means we are still processing the input prompt
//            for (int k = i; k < embd_inp.size(); k++) {
//                embd.push_back(embd_inp[k]);
//                if (embd.size() > params.n_batch) {
//                    break;
//                }
//            }
//            i += embd.size() - 1;
//        }
//
//        // display text
//        for (auto id : embd) {
//            printf("%s", vocab.id_to_token[id].c_str());
//        }
//        fflush(stdout);
//
//        // end of text token
//        if (embd.back() == 0) {
//            break;
//        }
//    }
//
//    // report timing
//    {
//        const int64_t t_main_end_us = ggml_time_us();
//
//        printf("\n\n");
//        printf("%s: mem per token = %8zu bytes\n", __func__, mem_per_token);
//        printf("%s:     load time = %8.2f ms\n", __func__, t_load_us/1000.0f);
//        printf("%s:   sample time = %8.2f ms\n", __func__, t_sample_us/1000.0f);
//        printf("%s:  predict time = %8.2f ms / %.2f ms per token\n", __func__, t_predict_us/1000.0f, t_predict_us/1000.0f/n_past);
//        printf("%s:    total time = %8.2f ms\n", __func__, (t_main_end_us - t_main_start_us)/1000.0f);
//    }
//
//    ggml_free(model.ctx);
//
//    return 0;
//}
