#include "ggml.h"
#include "gptneox.h"

#include <cstdio>
#include <map>
#include <string>

// usage:
//  ./update-gptneox models/llama/ggml-model-input.bin models/llama/ggml-model-output.bin
// The intent of this executable is to open old model formats and save them in the most recent format.
// Updating a model in ggml/ggmf format to ggjt will results in much faster load times as mmap can be used to map the model to the address space directly.
// This will maintain ftype (f16, f32, q4_[n], etc)
// Also, if modified locally (along with gptneox.cpp), you can use this to add or remove hparams, score, etc from a model. For instance, I used this to open a model in ggjt (no score) and saved it again as ggjt (with score).
//
int main(int argc, char ** argv) {
    ggml_time_init();

    if (argc < 3) {
        fprintf(stderr, "usage: %s model-input.bin model-output.bin\n", argv[0]);
        return 1;
    }

    // needed to initialize f16 tables
    {
        struct ggml_init_params params = { 0, NULL, false };
        struct ggml_context * ctx = ggml_init(params);
        ggml_free(ctx);
    }

    const std::string fname_inp = argv[1];
    const std::string fname_out = argv[2];

    gptneox_model_update(fname_inp.c_str(), fname_out.c_str());

    return 0;
}
