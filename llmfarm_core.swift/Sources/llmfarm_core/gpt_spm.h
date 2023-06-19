
#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>





#ifdef __cplusplus
extern "C" {
#endif

typedef struct gpt_neox_token_data {
    int id;  // token id
    float logit; // log-odds of the token
    float p;     // probability of the token
} gpt_neox_token_data;

typedef struct gpt_neox_token_data_array {
    gpt_neox_token_data * data;
    size_t size;
    bool sorted;
} gpt_neox_token_data_array;





#ifdef __cplusplus
}
#endif
