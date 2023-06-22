#include "../spm-headers/gpt_spm.h"
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
