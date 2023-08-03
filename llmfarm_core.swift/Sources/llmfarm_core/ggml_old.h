#pragma once

//
// GGML_OLD Tensor Library
//
// This documentation is still a work in progress.
// If you wish some specific topics to be covered, feel free to drop a comment:
//
//   https://github.com/ggerganov/whisper.cpp/issues/40
//
// ## Overview
//
// This library implements:
//
//  - a set of tensor operations
//  - automatic differentiation
//  - basic optimization algorithms
//
// The aim of this library is to provide a minimalistic approach for various machine learning tasks. This includes,
// but is not limited to, the following:
//
//  - linear regression
//  - support vector machines
//  - neural networks
//
// The library allows the user to define a certain function using the available tensor operations. This function
// definition is represented internally via a computation graph. Each tensor operation in the function definition
// corresponds to a node in the graph. Having the computation graph defined, the user can choose to compute the
// function's value and/or its gradient with respect to the input variables. Optionally, the function can be optimized
// using one of the available optimization algorithms.
//
// For example, here we define the function: f(x) = a*x^2 + b
//
//   {
//       struct ggml_old_init_params params = {
//           .mem_size   = 16*1024*1024,
//           .mem_buffer = NULL,
//       };
//
//       // memory allocation happens here
//       struct ggml_old_context * ctx = ggml_old_init(params);
//
//       struct ggml_old_tensor * x = ggml_old_new_tensor_1d(ctx, GGML_OLD_TYPE_F32, 1);
//
//       ggml_old_set_param(ctx, x); // x is an input variable
//
//       struct ggml_old_tensor * a  = ggml_old_new_tensor_1d(ctx, GGML_OLD_TYPE_F32, 1);
//       struct ggml_old_tensor * b  = ggml_old_new_tensor_1d(ctx, GGML_OLD_TYPE_F32, 1);
//       struct ggml_old_tensor * x2 = ggml_old_mul(ctx, x, x);
//       struct ggml_old_tensor * f  = ggml_old_add(ctx, ggml_old_mul(ctx, a, x2), b);
//
//       ...
//   }
//
// Notice that the function definition above does not involve any actual computation. The computation is performed only
// when the user explicitly requests it. For example, to compute the function's value at x = 2.0:
//
//   {
//       ...
//
//       struct ggml_old_cgraph gf = ggml_old_build_forward(f);
//
//       // set the input variable and parameter values
//       ggml_old_set_f32(x, 2.0f);
//       ggml_old_set_f32(a, 3.0f);
//       ggml_old_set_f32(b, 4.0f);
//
//       ggml_old_graph_compute(ctx0, &gf);
//
//       printf("f = %f\n", ggml_old_get_f32_1d(f, 0));
//
//       ...
//   }
//
// The actual computation is performed in the ggml_old_graph_compute() function.
//
// The ggml_old_new_tensor_...() functions create new tensors. They are allocated in the memory buffer provided to the
// ggml_old_init() function. You have to be careful not to exceed the memory buffer size. Therefore, you have to know
// in advance how much memory you need for your computation. Alternatively, you can allocate a large enough memory
// and after defining the computation graph, call the ggml_old_used_mem() function to find out how much memory was
// actually needed.
//
// The ggml_old_set_param() function marks a tensor as an input variable. This is used by the automatic
// differentiation and optimization algorithms.
//
// The described approach allows to define the function graph once and then compute its forward or backward graphs
// multiple times. All computations will use the same memory buffer allocated in the ggml_old_init() function. This way
// the user can avoid the memory allocation overhead at runtime.
//
// The library supports multi-dimensional tensors - up to 4 dimensions. The FP16 and FP32 data types are first class
// citizens, but in theory the library can be extended to support FP8 and integer data types.
//
// Each tensor operation produces a new tensor. Initially the library was envisioned to support only the use of unary
// and binary operations. Most of the available operations fall into one of these two categories. With time, it became
// clear that the library needs to support more complex operations. The way to support these operations is not clear
// yet, but a few examples are demonstrated in the following operations:
//
//   - ggml_old_permute()
//   - ggml_old_conv_1d_1s()
//   - ggml_old_conv_1d_2s()
//
// For each tensor operator, the library implements a forward and backward computation function. The forward function
// computes the output tensor value given the input tensor values. The backward function computes the adjoint of the
// input tensors given the adjoint of the output tensor. For a detailed explanation of what this means, take a
// calculus class, or watch the following video:
//
//   What is Automatic Differentiation?
//   https://www.youtube.com/watch?v=wG_nF1awSSY
//
//
// ## Tensor data (struct ggml_old_tensor)
//
// The tensors are stored in memory via the ggml_old_tensor struct. The structure provides information about the size of
// the tensor, the data type, and the memory buffer where the tensor data is stored. Additionally, it contains
// pointers to the "source" tensors - i.e. the tensors that were used to compute the current tensor. For example:
//
//   {
//       struct ggml_old_tensor * c = ggml_old_add(ctx, a, b);
//
//       assert(c->src[0] == a);
//       assert(c->src[1] == b);
//   }
//
// The multi-dimensional tensors are stored in row-major order. The ggml_old_tensor struct contains fields for the
// number of elements in each dimension ("ne") as well as the number of bytes ("nb", a.k.a. stride). This allows
// to store tensors that are not contiguous in memory, which is useful for operations such as transposition and
// permutation. All tensor operations have to take the stride into account and not assume that the tensor is
// contiguous in memory.
//
// The data of the tensor is accessed via the "data" pointer. For example:
//
//   {
//       struct ggml_old_tensor * a = ggml_old_new_tensor_2d(ctx, GGML_OLD_TYPE_F32, 2, 3);
//
//       // a[1, 2] = 1.0f;
//       *(float *) ((char *) a->data + 2*a->nb[1] + 1*a->nb[0]) = 1.0f;
//
//       // a[2, 0] = 2.0f;
//       *(float *) ((char *) a->data + 0*a->nb[1] + 2*a->nb[0]) = 2.0f;
//
//       ...
//   }
//
// Alternatively, there are helper functions, such as ggml_old_get_f32_1d() and ggml_old_set_f32_1d() that can be used.
//
// ## The matrix multiplication operator (ggml_old_mul_mat)
//
// TODO
//
//
// ## Multi-threading
//
// TODO
//
//
// ## Overview of ggml.c
//
// TODO
//
//
// ## SIMD optimizations
//
// TODO
//
//
// ## Debugging ggml
//
// TODO
//
//

#ifdef GGML_OLD_SHARED
#    if defined(_WIN32) && !defined(__MINGW32__)
#        ifdef GGML_OLD_BUILD
#            define GGML_OLD_API __declspec(dllexport)
#        else
#            define GGML_OLD_API __declspec(dllimport)
#        endif
#    else
#        define GGML_OLD_API __attribute__ ((visibility ("default")))
#    endif
#else
#    define GGML_OLD_API
#endif

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#define GGML_OLD_FILE_MAGIC   0x67676d6c // "ggml"
#define GGML_OLD_FILE_VERSION 1

#define GGML_OLD_QNT_VERSION        2    // bump this on quantization format changes
#define GGML_OLD_QNT_VERSION_FACTOR 1000 // do not change this

#define GGML_OLD_MAX_DIMS          4
#define GGML_OLD_MAX_NODES         4096
#define GGML_OLD_MAX_PARAMS        256
#define GGML_OLD_MAX_CONTEXTS      64
#define GGML_OLD_MAX_OPT           4
#define GGML_OLD_MAX_NAME          32
#define GGML_OLD_DEFAULT_N_THREADS 4

#define GGML_OLD_ASSERT(x) \
    do { \
        if (!(x)) { \
            fprintf(stderr, "GGML_OLD_ASSERT: %s:%d: %s\n", __FILE__, __LINE__, #x); \
            abort(); \
        } \
    } while (0)

#ifdef  __cplusplus
extern "C" {
#endif

#ifdef __ARM_NEON
    // we use the built-in 16-bit float type
    typedef __fp16 ggml_old_fp16_t;
#else
    typedef uint16_t ggml_old_fp16_t;
#endif

    // convert FP16 <-> FP32
    GGML_OLD_API float       ggml_old_fp16_to_fp32(ggml_old_fp16_t x);
    GGML_OLD_API ggml_old_fp16_t ggml_old_fp32_to_fp16(float x);

    GGML_OLD_API void ggml_old_fp16_to_fp32_row(const ggml_old_fp16_t * x, float * y, size_t n);
    GGML_OLD_API void ggml_old_fp32_to_fp16_row(const float * x, ggml_old_fp16_t * y, size_t n);

    struct ggml_old_object;
    struct ggml_old_context;

    enum ggml_old_type {
        GGML_OLD_TYPE_F32  = 0,
        GGML_OLD_TYPE_F16  = 1,
        GGML_OLD_TYPE_Q4_0 = 2,
        GGML_OLD_TYPE_Q4_1 = 3,
        // GGML_OLD_TYPE_Q4_2 = 4, support has been removed
        // GGML_OLD_TYPE_Q4_3 (5) support has been removed
        GGML_OLD_TYPE_Q5_0 = 6,
        GGML_OLD_TYPE_Q5_1 = 7,
        GGML_OLD_TYPE_Q8_0 = 8,
        GGML_OLD_TYPE_Q8_1 = 9,
        // k-quantizations
        GGML_OLD_TYPE_Q2_K = 10,
        GGML_OLD_TYPE_Q3_K = 11,
        GGML_OLD_TYPE_Q4_K = 12,
        GGML_OLD_TYPE_Q5_K = 13,
        GGML_OLD_TYPE_Q6_K = 14,
        GGML_OLD_TYPE_Q8_K = 15,
        GGML_OLD_TYPE_I8,
        GGML_OLD_TYPE_I16,
        GGML_OLD_TYPE_I32,
        GGML_OLD_TYPE_COUNT,
    };

    enum ggml_old_backend {
        GGML_OLD_BACKEND_CPU = 0,
        GGML_OLD_BACKEND_GPU = 10,
        GGML_OLD_BACKEND_GPU_SPLIT = 20,
    };

    // model file types
    enum ggml_old_ftype {
        GGML_OLD_FTYPE_UNKNOWN     = -1,
        GGML_OLD_FTYPE_ALL_F32     = 0,
        GGML_OLD_FTYPE_MOSTLY_F16  = 1,  // except 1d tensors
        GGML_OLD_FTYPE_MOSTLY_Q4_0 = 2,  // except 1d tensors
        GGML_OLD_FTYPE_MOSTLY_Q4_1 = 3,  // except 1d tensors
        GGML_OLD_FTYPE_MOSTLY_Q4_1_SOME_F16 = 4, // tok_embeddings.weight and output.weight are F16
        GGML_OLD_FTYPE_MOSTLY_Q8_0 = 7,  // except 1d tensors
        GGML_OLD_FTYPE_MOSTLY_Q5_0 = 8,  // except 1d tensors
        GGML_OLD_FTYPE_MOSTLY_Q5_1 = 9,  // except 1d tensors
        GGML_OLD_FTYPE_MOSTLY_Q2_K = 10, // except 1d tensors
        GGML_OLD_FTYPE_MOSTLY_Q3_K = 11, // except 1d tensors
        GGML_OLD_FTYPE_MOSTLY_Q4_K = 12, // except 1d tensors
        GGML_OLD_FTYPE_MOSTLY_Q5_K = 13, // except 1d tensors
        GGML_OLD_FTYPE_MOSTLY_Q6_K = 14, // except 1d tensors
    };

    // available tensor operations:
    enum ggml_old_op {
        GGML_OLD_OP_NONE = 0,

        GGML_OLD_OP_DUP,
        GGML_OLD_OP_ADD,
        GGML_OLD_OP_ADD1,
        GGML_OLD_OP_ACC,
        GGML_OLD_OP_SUB,
        GGML_OLD_OP_MUL,
        GGML_OLD_OP_DIV,
        GGML_OLD_OP_SQR,
        GGML_OLD_OP_SQRT,
        GGML_OLD_OP_LOG,
        GGML_OLD_OP_SUM,
        GGML_OLD_OP_SUM_ROWS,
        GGML_OLD_OP_MEAN,
        GGML_OLD_OP_REPEAT,
        GGML_OLD_OP_REPEAT_BACK,
        GGML_OLD_OP_ABS,
        GGML_OLD_OP_SGN,
        GGML_OLD_OP_NEG,
        GGML_OLD_OP_STEP,
        GGML_OLD_OP_RELU,
        GGML_OLD_OP_GELU,
        GGML_OLD_OP_GELU_QUICK,
        GGML_OLD_OP_SILU,
        GGML_OLD_OP_SILU_BACK,
        GGML_OLD_OP_NORM, // normalize
        GGML_OLD_OP_RMS_NORM,
        GGML_OLD_OP_RMS_NORM_BACK,

        GGML_OLD_OP_MUL_MAT,
        GGML_OLD_OP_OUT_PROD,

        GGML_OLD_OP_SCALE,
        GGML_OLD_OP_SET,
        GGML_OLD_OP_CPY,
        GGML_OLD_OP_CONT,
        GGML_OLD_OP_RESHAPE,
        GGML_OLD_OP_VIEW,
        GGML_OLD_OP_PERMUTE,
        GGML_OLD_OP_TRANSPOSE,
        GGML_OLD_OP_GET_ROWS,
        GGML_OLD_OP_GET_ROWS_BACK,
        GGML_OLD_OP_DIAG,
        GGML_OLD_OP_DIAG_MASK_INF,
        GGML_OLD_OP_DIAG_MASK_ZERO,
        GGML_OLD_OP_SOFT_MAX,
        GGML_OLD_OP_SOFT_MAX_BACK,
        GGML_OLD_OP_ROPE,
        GGML_OLD_OP_ROPE_BACK,
        GGML_OLD_OP_ALIBI,
        GGML_OLD_OP_CLAMP,
        GGML_OLD_OP_CONV_1D_S1_PH,
        GGML_OLD_OP_CONV_1D_S2_PH,
        GGML_OLD_OP_CONV_2D_SK_P0,

        GGML_OLD_OP_FLASH_ATTN,
        GGML_OLD_OP_FLASH_FF,
        GGML_OLD_OP_FLASH_ATTN_BACK,
        GGML_OLD_OP_WIN_PART,
        GGML_OLD_OP_WIN_UNPART,

        GGML_OLD_OP_MAP_UNARY,
        GGML_OLD_OP_MAP_BINARY,

        GGML_OLD_OP_MAP_CUSTOM1,
        GGML_OLD_OP_MAP_CUSTOM2,
        GGML_OLD_OP_MAP_CUSTOM3,

        GGML_OLD_OP_CROSS_ENTROPY_LOSS,
        GGML_OLD_OP_CROSS_ENTROPY_LOSS_BACK,

        GGML_OLD_OP_COUNT,
    };


    // ggml object
    struct ggml_old_object {
        size_t offs;
        size_t size;

        struct ggml_old_object * next;

        char padding[8];
    };

    static const size_t GGML_OLD_OBJECT_SIZE = sizeof(struct ggml_old_object);

    // n-dimensional tensor
    struct ggml_old_tensor {
        enum ggml_old_type    type;
        enum ggml_old_backend backend;

        int     n_dims;
        int64_t ne[GGML_OLD_MAX_DIMS]; // number of elements
        size_t  nb[GGML_OLD_MAX_DIMS]; // stride in bytes:
                                   // nb[0] = sizeof(type)
                                   // nb[1] = nb[0]   * ne[0] + padding
                                   // nb[i] = nb[i-1] * ne[i-1]

        // compute data
        enum ggml_old_op op;

        bool is_param;

        struct ggml_old_tensor * grad;
        struct ggml_old_tensor * src0;
        struct ggml_old_tensor * src1;
        struct ggml_old_tensor * opt[GGML_OLD_MAX_OPT];

        // thread scheduling
        int n_tasks;

        // performance
        int     perf_runs;
        int64_t perf_cycles;
        int64_t perf_time_us;

        void * data;

        char name[GGML_OLD_MAX_NAME];

        void * extra; // extra things e.g. for ggml-cuda.cu

        char padding[4];
    };

    static const size_t GGML_OLD_TENSOR_SIZE = sizeof(struct ggml_old_tensor);

    // computation graph
    struct ggml_old_cgraph {
        int n_nodes;
        int n_leafs;
        int n_threads;

        size_t work_size;
        struct ggml_old_tensor * work;

        struct ggml_old_tensor * nodes[GGML_OLD_MAX_NODES];
        struct ggml_old_tensor * grads[GGML_OLD_MAX_NODES];
        struct ggml_old_tensor * leafs[GGML_OLD_MAX_NODES];

        // performance
        int     perf_runs;
        int64_t perf_cycles;
        int64_t perf_time_us;
    };

    // scratch buffer
    struct ggml_old_scratch {
        size_t offs;
        size_t size;
        void * data;
    };

    struct ggml_old_init_params {
        // memory pool
        size_t mem_size;   // bytes
        void * mem_buffer; // if NULL, memory will be allocated internally
        bool   no_alloc;   // don't allocate memory for the tensor data
    };


    // compute types
    enum ggml_old_task_type {
        GGML_OLD_TASK_INIT = 0,
        GGML_OLD_TASK_COMPUTE,
        GGML_OLD_TASK_FINALIZE,
    };

    struct ggml_old_compute_params {
        enum ggml_old_task_type type;

        // ith = thread index, nth = number of threads
        int ith, nth;

        // work buffer for all threads
        size_t wsize;
        void * wdata;
    };

    // misc

    GGML_OLD_API void    ggml_old_time_init(void); // call this once at the beginning of the program
    GGML_OLD_API int64_t ggml_old_time_ms(void);
    GGML_OLD_API int64_t ggml_old_time_us(void);
    GGML_OLD_API int64_t ggml_old_cycles(void);
    GGML_OLD_API int64_t ggml_old_cycles_per_ms(void);

    GGML_OLD_API void    ggml_old_print_object (const struct ggml_old_object * obj);
    GGML_OLD_API void    ggml_old_print_objects(const struct ggml_old_context * ctx);

    GGML_OLD_API int64_t ggml_old_nelements   (const struct ggml_old_tensor * tensor);
    GGML_OLD_API int64_t ggml_old_nrows       (const struct ggml_old_tensor * tensor);
    GGML_OLD_API size_t  ggml_old_nbytes      (const struct ggml_old_tensor * tensor);
    GGML_OLD_API size_t  ggml_old_nbytes_split(const struct ggml_old_tensor * tensor, int nrows_split);

    GGML_OLD_API int     ggml_old_blck_size (enum ggml_old_type type);
    GGML_OLD_API size_t  ggml_old_type_size (enum ggml_old_type type); // size in bytes for all elements in a block
    GGML_OLD_API float   ggml_old_type_sizef(enum ggml_old_type type); // ggml_old_type_size()/ggml_old_blck_size() as float

    GGML_OLD_API const char * ggml_old_type_name(enum ggml_old_type type);
    GGML_OLD_API const char * ggml_old_op_name  (enum ggml_old_op   op);

    GGML_OLD_API size_t  ggml_old_element_size(const struct ggml_old_tensor * tensor);

    GGML_OLD_API bool    ggml_old_is_quantized(enum ggml_old_type type);

    // TODO: temporary until model loading of ggml examples is refactored
    GGML_OLD_API enum ggml_old_type ggml_old_ftype_to_ggml_old_type(enum ggml_old_ftype ftype);

    GGML_OLD_API bool ggml_old_is_transposed(const struct ggml_old_tensor * tensor);
    GGML_OLD_API bool ggml_old_is_contiguous(const struct ggml_old_tensor * tensor);
    GGML_OLD_API bool ggml_old_is_permuted  (const struct ggml_old_tensor * tensor);

    // use this to compute the memory overhead of a tensor
    GGML_OLD_API size_t ggml_old_tensor_overhead(void);

    // main

    GGML_OLD_API struct ggml_old_context * ggml_old_init(struct ggml_old_init_params params);
    GGML_OLD_API void                  ggml_old_free(struct ggml_old_context * ctx);

    GGML_OLD_API size_t  ggml_old_used_mem(const struct ggml_old_context * ctx);

    GGML_OLD_API size_t  ggml_old_set_scratch (struct ggml_old_context * ctx, struct ggml_old_scratch scratch);
    GGML_OLD_API void    ggml_old_set_no_alloc(struct ggml_old_context * ctx, bool no_alloc);

    GGML_OLD_API void *  ggml_old_get_mem_buffer     (const struct ggml_old_context * ctx);
    GGML_OLD_API size_t  ggml_old_get_mem_size       (const struct ggml_old_context * ctx);
    GGML_OLD_API size_t  ggml_old_get_max_tensor_size(const struct ggml_old_context * ctx);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_new_tensor(
            struct ggml_old_context * ctx,
            enum   ggml_old_type type,
            int    n_dims,
            const int64_t *ne);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_new_tensor_1d(
            struct ggml_old_context * ctx,
            enum   ggml_old_type type,
            int64_t ne0);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_new_tensor_2d(
            struct ggml_old_context * ctx,
            enum   ggml_old_type type,
            int64_t ne0,
            int64_t ne1);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_new_tensor_3d(
            struct ggml_old_context * ctx,
            enum   ggml_old_type type,
            int64_t ne0,
            int64_t ne1,
            int64_t ne2);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_new_tensor_4d(
            struct ggml_old_context * ctx,
            enum   ggml_old_type type,
            int64_t ne0,
            int64_t ne1,
            int64_t ne2,
            int64_t ne3);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_new_i32(struct ggml_old_context * ctx, int32_t value);
    GGML_OLD_API struct ggml_old_tensor * ggml_old_new_f32(struct ggml_old_context * ctx, float value);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_dup_tensor (struct ggml_old_context * ctx, const struct ggml_old_tensor * src);
    GGML_OLD_API struct ggml_old_tensor * ggml_old_view_tensor(struct ggml_old_context * ctx, const struct ggml_old_tensor * src);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_get_tensor(struct ggml_old_context * ctx, const char * name);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_set_zero(struct ggml_old_tensor * tensor);
    GGML_OLD_API struct ggml_old_tensor * ggml_old_set_i32 (struct ggml_old_tensor * tensor, int32_t value);
    GGML_OLD_API struct ggml_old_tensor * ggml_old_set_f32 (struct ggml_old_tensor * tensor, float value);

    GGML_OLD_API int32_t ggml_old_get_i32_1d(const struct ggml_old_tensor * tensor, int i);
    GGML_OLD_API void    ggml_old_set_i32_1d(const struct ggml_old_tensor * tensor, int i, int32_t value);

    GGML_OLD_API float   ggml_old_get_f32_1d(const struct ggml_old_tensor * tensor, int i);
    GGML_OLD_API void    ggml_old_set_f32_1d(const struct ggml_old_tensor * tensor, int i, float value);

    GGML_OLD_API void *  ggml_old_get_data    (const struct ggml_old_tensor * tensor);
    GGML_OLD_API float * ggml_old_get_data_f32(const struct ggml_old_tensor * tensor);

    GGML_OLD_API const char *         ggml_old_get_name(const struct ggml_old_tensor * tensor);
    GGML_OLD_API struct ggml_old_tensor * ggml_old_set_name(struct ggml_old_tensor * tensor, const char * name);
    GGML_OLD_API struct ggml_old_tensor * ggml_old_format_name(struct ggml_old_tensor * tensor, const char * fmt, ...);

    //
    // operations on tensors with backpropagation
    //

    GGML_OLD_API struct ggml_old_tensor * ggml_old_dup(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_add(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            struct ggml_old_tensor  * b);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_add_inplace(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            struct ggml_old_tensor  * b);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_add1(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            struct ggml_old_tensor  * b);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_add1_inplace(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            struct ggml_old_tensor  * b);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_acc(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            struct ggml_old_tensor  * b,
            size_t                nb1,
            size_t                nb2,
            size_t                nb3,
            size_t                offset);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_acc_inplace(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            struct ggml_old_tensor  * b,
            size_t                nb1,
            size_t                nb2,
            size_t                nb3,
            size_t                offset);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_sub(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            struct ggml_old_tensor  * b);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_sub_inplace(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            struct ggml_old_tensor  * b);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_mul(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            struct ggml_old_tensor  * b);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_mul_inplace(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            struct ggml_old_tensor  * b);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_div(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            struct ggml_old_tensor  * b);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_div_inplace(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            struct ggml_old_tensor  * b);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_sqr(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_sqr_inplace(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_sqrt(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_sqrt_inplace(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_log(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_log_inplace(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a);

    // return scalar
    GGML_OLD_API struct ggml_old_tensor * ggml_old_sum(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a);

    // sums along rows, with input shape [a,b,c,d] return shape [1,b,c,d]
    GGML_OLD_API struct ggml_old_tensor * ggml_old_sum_rows(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a);

    // mean along rows
    GGML_OLD_API struct ggml_old_tensor * ggml_old_mean(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a);

    // if a is the same shape as b, and a is not parameter, return a
    // otherwise, return a new tensor: repeat(a) to fit in b
    GGML_OLD_API struct ggml_old_tensor * ggml_old_repeat(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            struct ggml_old_tensor  * b);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_repeat_back(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            struct ggml_old_tensor  * b);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_abs(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_abs_inplace(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_sgn(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_sgn_inplace(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_neg(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_neg_inplace(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_step(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_step_inplace(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_relu(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_relu_inplace(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a);

    // TODO: double-check this computation is correct
    GGML_OLD_API struct ggml_old_tensor * ggml_old_gelu(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_gelu_inplace(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_gelu_quick(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_gelu_quick_inplace(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_silu(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_silu_inplace(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a);

    // a - x
    // b - dy
    GGML_OLD_API struct ggml_old_tensor * ggml_old_silu_back(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            struct ggml_old_tensor  * b);

    // normalize along rows
    // TODO: eps is hardcoded to 1e-5 for now
    GGML_OLD_API struct ggml_old_tensor * ggml_old_norm(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_norm_inplace(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_rms_norm(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_rms_norm_inplace(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a);

    // a - x
    // b - dy
    GGML_OLD_API struct ggml_old_tensor * ggml_old_rms_norm_back(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            struct ggml_old_tensor  * b);

    // A: n columns, m rows
    // B: n columns, p rows  (i.e. we transpose it internally)
    // result is m columns, p rows
    GGML_OLD_API struct ggml_old_tensor * ggml_old_mul_mat(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            struct ggml_old_tensor  * b);

    // A: m columns, n rows,
    // B: p columns, n rows,
    // result is m columns, p rows
    GGML_OLD_API struct ggml_old_tensor * ggml_old_out_prod(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            struct ggml_old_tensor  * b);

    //
    // operations on tensors without backpropagation
    //

    GGML_OLD_API struct ggml_old_tensor * ggml_old_scale(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            struct ggml_old_tensor  * b);

    // in-place, returns view(a)
    GGML_OLD_API struct ggml_old_tensor * ggml_old_scale_inplace(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            struct ggml_old_tensor  * b);

    // b -> view(a,offset,nb1,nb2,3), return modified a
    GGML_OLD_API struct ggml_old_tensor * ggml_old_set(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            struct ggml_old_tensor  * b,
            size_t                nb1,
            size_t                nb2,
            size_t                nb3,
            size_t                offset);

    // b -> view(a,offset,nb1,nb2,3), return view(a)
    GGML_OLD_API struct ggml_old_tensor * ggml_old_set_inplace(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            struct ggml_old_tensor  * b,
            size_t                nb1,
            size_t                nb2,
            size_t                nb3,
            size_t                offset);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_set_1d(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            struct ggml_old_tensor  * b,
            size_t                offset);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_set_1d_inplace(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            struct ggml_old_tensor  * b,
            size_t                offset);

    // b -> view(a,offset,nb1,nb2,3), return modified a
    GGML_OLD_API struct ggml_old_tensor * ggml_old_set_2d(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            struct ggml_old_tensor  * b,
            size_t                nb1,
            size_t                offset);

    // b -> view(a,offset,nb1,nb2,3), return view(a)
    GGML_OLD_API struct ggml_old_tensor * ggml_old_set_2d_inplace(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            struct ggml_old_tensor  * b,
            size_t                nb1,
            size_t                offset);


    // a -> b, return view(b)
    GGML_OLD_API struct ggml_old_tensor * ggml_old_cpy(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            struct ggml_old_tensor  * b);

    // make contiguous
    GGML_OLD_API struct ggml_old_tensor * ggml_old_cont(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a);

    // return view(a), b specifies the new shape
    // TODO: when we start computing gradient, make a copy instead of view
    GGML_OLD_API struct ggml_old_tensor * ggml_old_reshape(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            struct ggml_old_tensor  * b);

    // return view(a)
    // TODO: when we start computing gradient, make a copy instead of view
    GGML_OLD_API struct ggml_old_tensor * ggml_old_reshape_1d(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            int64_t               ne0);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_reshape_2d(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            int64_t               ne0,
            int64_t               ne1);

    // return view(a)
    // TODO: when we start computing gradient, make a copy instead of view
    GGML_OLD_API struct ggml_old_tensor * ggml_old_reshape_3d(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            int64_t               ne0,
            int64_t               ne1,
            int64_t               ne2);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_reshape_4d(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            int64_t               ne0,
            int64_t               ne1,
            int64_t               ne2,
            int64_t               ne3);

    // offset in bytes
    GGML_OLD_API struct ggml_old_tensor * ggml_old_view_1d(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            int64_t               ne0,
            size_t                offset);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_view_2d(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            int64_t               ne0,
            int64_t               ne1,
            size_t                nb1, // row stride in bytes
            size_t                offset);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_view_3d(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            int64_t               ne0,
            int64_t               ne1,
            int64_t               ne2,
            size_t                nb1, // row   stride in bytes
            size_t                nb2, // slice stride in bytes
            size_t                offset);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_view_4d(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            int64_t               ne0,
            int64_t               ne1,
            int64_t               ne2,
            int64_t               ne3,
            size_t                nb1, // row   stride in bytes
            size_t                nb2, // slice stride in bytes
            size_t                nb3,
            size_t                offset);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_permute(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            int                   axis0,
            int                   axis1,
            int                   axis2,
            int                   axis3);

    // alias for ggml_old_permute(ctx, a, 1, 0, 2, 3)
    GGML_OLD_API struct ggml_old_tensor * ggml_old_transpose(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_get_rows(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            struct ggml_old_tensor  * b);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_get_rows_back(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            struct ggml_old_tensor  * b,
            struct ggml_old_tensor  * c);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_diag(
        struct ggml_old_context     * ctx,
        struct ggml_old_tensor      * a);

    // set elements above the diagonal to -INF
    GGML_OLD_API struct ggml_old_tensor * ggml_old_diag_mask_inf(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            int                   n_past);

    // in-place, returns view(a)
    GGML_OLD_API struct ggml_old_tensor * ggml_old_diag_mask_inf_inplace(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            int                   n_past);

    // set elements above the diagonal to 0
    GGML_OLD_API struct ggml_old_tensor * ggml_old_diag_mask_zero(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            int                   n_past);

    // in-place, returns view(a)
    GGML_OLD_API struct ggml_old_tensor * ggml_old_diag_mask_zero_inplace(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            int                   n_past);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_soft_max(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a);

    // in-place, returns view(a)
    GGML_OLD_API struct ggml_old_tensor * ggml_old_soft_max_inplace(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_soft_max_back(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            struct ggml_old_tensor  * b);

    // in-place, returns view(a)
    GGML_OLD_API struct ggml_old_tensor * ggml_old_soft_max_back_inplace(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            struct ggml_old_tensor  * b);

    // rotary position embedding
    // if mode & 1 == 1, skip n_past elements
    // if mode & 2 == 1, GPT-NeoX style
    // TODO: avoid creating a new tensor every time
    GGML_OLD_API struct ggml_old_tensor * ggml_old_rope(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            int                   n_past,
            int                   n_dims,
            int                   mode);

    // in-place, returns view(a)
    GGML_OLD_API struct ggml_old_tensor * ggml_old_rope_inplace(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            int                   n_past,
            int                   n_dims,
            int                   mode);

    // rotary position embedding backward, i.e compute dx from dy
    // a - dy
    GGML_OLD_API struct ggml_old_tensor * ggml_old_rope_back(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            int                   n_past,
            int                   n_dims,
            int                   mode);

    // alibi position embedding
    // in-place, returns view(a)
    struct ggml_old_tensor * ggml_old_alibi(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            int                   n_past,
            int                   n_head,
            float                 bias_max);

    // clamp
    // in-place, returns view(a)
    struct ggml_old_tensor * ggml_old_clamp(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            float                 min,
            float                 max);

    // TODO: implement general-purpose convolutions
    // GGML_OLD_API struct ggml_old_tensor * ggml_old_conv_1d(
    //        struct ggml_old_context * ctx,
    //        struct ggml_old_tensor  * a,
    //        struct ggml_old_tensor  * b,
    //        int                   s0
    //        int                   p0,
    //        int                   d0);
    //
    // GGML_OLD_API struct ggml_old_tensor * ggml_old_conv_2d(
    //        struct ggml_old_context * ctx,
    //        struct ggml_old_tensor  * a,
    //        struct ggml_old_tensor  * b,
    //        int                   s0,
    //        int                   s1,
    //        int                   p0,
    //        int                   p1,
    //        int                   d0,
    //        int                   d1);

    // padding = half
    // TODO: we don't support extra parameters for now
    //       that's why we are hard-coding the stride, padding, and dilation
    //       not great ..
    // example:
    // a:      3   80  768    1
    // b:   3000   80    1    1
    // res: 3000  768    1    1
    // used in whisper
    GGML_OLD_API struct ggml_old_tensor * ggml_old_conv_1d_s1_ph(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            struct ggml_old_tensor  * b);

    // used in whisper
    GGML_OLD_API struct ggml_old_tensor * ggml_old_conv_1d_s2_ph(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            struct ggml_old_tensor  * b);

    // kernel size is a->ne[0] x a->ne[1]
    // stride is equal to kernel size
    // padding is zero
    // example:
    // a:     16   16    3  768
    // b:   1024 1024    3    1
    // res:   64   64  768    1
    // used in sam
    GGML_OLD_API struct ggml_old_tensor * ggml_old_conv_2d_sk_p0(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            struct ggml_old_tensor  * b);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_flash_attn(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * q,
            struct ggml_old_tensor  * k,
            struct ggml_old_tensor  * v,
            bool                  masked);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_flash_attn_back(
           struct ggml_old_context * ctx,
           struct ggml_old_tensor  * q,
           struct ggml_old_tensor  * k,
           struct ggml_old_tensor  * v,
           struct ggml_old_tensor  * d,
           bool                  masked);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_flash_ff(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            struct ggml_old_tensor  * b0,
            struct ggml_old_tensor  * b1,
            struct ggml_old_tensor  * c0,
            struct ggml_old_tensor  * c1);

    // partition into non-overlapping windows with padding if needed
    // example:
    // a:   768   64   64    1
    // w:    14
    // res: 768   14   14    25
    // used in sam
    GGML_OLD_API struct ggml_old_tensor * ggml_old_win_part(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            int                   w);

    // reverse of ggml_old_win_part
    // used in sam
    GGML_OLD_API struct ggml_old_tensor * ggml_old_win_unpart(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor  * a,
            int                   w0,
            int                   h0,
            int                   w);

    // custom operators

    typedef void (*ggml_old_unary_op_f32_t) (const int, float *, const float *);
    typedef void (*ggml_old_binary_op_f32_t)(const int, float *, const float *, const float *);

    typedef void (*ggml_old_custom1_op_f32_t)(struct ggml_old_tensor *, const struct ggml_old_tensor *);
    typedef void (*ggml_old_custom2_op_f32_t)(struct ggml_old_tensor *, const struct ggml_old_tensor *, const struct ggml_old_tensor *);
    typedef void (*ggml_old_custom3_op_f32_t)(struct ggml_old_tensor *, const struct ggml_old_tensor *, const struct ggml_old_tensor *, const struct ggml_old_tensor *);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_map_unary_f32(
            struct ggml_old_context        * ctx,
            struct ggml_old_tensor         * a,
                   ggml_old_unary_op_f32_t   fun);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_map_unary_inplace_f32(
            struct ggml_old_context        * ctx,
            struct ggml_old_tensor         * a,
                   ggml_old_unary_op_f32_t   fun);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_map_binary_f32(
            struct ggml_old_context         * ctx,
            struct ggml_old_tensor          * a,
            struct ggml_old_tensor          * b,
                   ggml_old_binary_op_f32_t   fun);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_map_binary_inplace_f32(
            struct ggml_old_context         * ctx,
            struct ggml_old_tensor          * a,
            struct ggml_old_tensor          * b,
                   ggml_old_binary_op_f32_t   fun);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_map_custom1_f32(
            struct ggml_old_context          * ctx,
            struct ggml_old_tensor           * a,
                   ggml_old_custom1_op_f32_t   fun);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_map_custom1_inplace_f32(
            struct ggml_old_context          * ctx,
            struct ggml_old_tensor           * a,
                   ggml_old_custom1_op_f32_t   fun);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_map_custom2_f32(
            struct ggml_old_context          * ctx,
            struct ggml_old_tensor           * a,
            struct ggml_old_tensor           * b,
                   ggml_old_custom2_op_f32_t   fun);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_map_custom2_inplace_f32(
            struct ggml_old_context          * ctx,
            struct ggml_old_tensor           * a,
            struct ggml_old_tensor           * b,
                   ggml_old_custom2_op_f32_t   fun);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_map_custom3_f32(
            struct ggml_old_context          * ctx,
            struct ggml_old_tensor           * a,
            struct ggml_old_tensor           * b,
            struct ggml_old_tensor           * c,
                   ggml_old_custom3_op_f32_t   fun);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_map_custom3_inplace_f32(
            struct ggml_old_context          * ctx,
            struct ggml_old_tensor           * a,
            struct ggml_old_tensor           * b,
            struct ggml_old_tensor           * c,
                   ggml_old_custom3_op_f32_t   fun);

    // loss function

    GGML_OLD_API struct ggml_old_tensor * ggml_old_cross_entropy_loss(
            struct ggml_old_context         * ctx,
            struct ggml_old_tensor          * a,
            struct ggml_old_tensor          * b);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_cross_entropy_loss_back(
            struct ggml_old_context         * ctx,
            struct ggml_old_tensor          * a,
            struct ggml_old_tensor          * b,
            struct ggml_old_tensor          * c);

    //
    // automatic differentiation
    //

    GGML_OLD_API void ggml_old_set_param(
            struct ggml_old_context * ctx,
            struct ggml_old_tensor * tensor);

    GGML_OLD_API void ggml_old_build_forward_expand(struct ggml_old_cgraph * cgraph, struct ggml_old_tensor * tensor);

    GGML_OLD_API struct ggml_old_cgraph ggml_old_build_forward (struct ggml_old_tensor * tensor);
    GGML_OLD_API struct ggml_old_cgraph ggml_old_build_backward(struct ggml_old_context * ctx, struct ggml_old_cgraph * gf, bool keep);

    GGML_OLD_API void ggml_old_graph_compute(struct ggml_old_context * ctx, struct ggml_old_cgraph * cgraph);
    GGML_OLD_API void ggml_old_graph_reset  (struct ggml_old_cgraph * cgraph);

    GGML_OLD_API struct ggml_old_tensor * ggml_old_graph_get_tensor(struct ggml_old_cgraph * cgraph, const char * name);

    GGML_OLD_API void               ggml_old_graph_export(const struct ggml_old_cgraph * cgraph, const char * fname);
    GGML_OLD_API struct ggml_old_cgraph ggml_old_graph_import(const char * fname, struct ggml_old_context ** ctx_data, struct ggml_old_context ** ctx_eval);

    // print info and performance information for the graph
    GGML_OLD_API void ggml_old_graph_print(const struct ggml_old_cgraph * cgraph);

    // dump the graph into a file using the dot format
    GGML_OLD_API void ggml_old_graph_dump_dot(const struct ggml_old_cgraph * gb, const struct ggml_old_cgraph * gf, const char * filename);

    //
    // optimization
    //

    // optimization methods
    enum ggml_old_opt_type {
        GGML_OLD_OPT_ADAM,
        GGML_OLD_OPT_LBFGS,
    };

    // linesearch methods
    enum ggml_old_linesearch {
        GGML_OLD_LINESEARCH_DEFAULT = 1,

        GGML_OLD_LINESEARCH_BACKTRACKING_ARMIJO       = 0,
        GGML_OLD_LINESEARCH_BACKTRACKING_WOLFE        = 1,
        GGML_OLD_LINESEARCH_BACKTRACKING_STRONG_WOLFE = 2,
    };

    // optimization return values
    enum ggml_old_opt_result {
        GGML_OLD_OPT_OK = 0,
        GGML_OLD_OPT_DID_NOT_CONVERGE,
        GGML_OLD_OPT_NO_CONTEXT,
        GGML_OLD_OPT_INVALID_WOLFE,
        GGML_OLD_OPT_FAIL,

        GGML_OLD_LINESEARCH_FAIL = -128,
        GGML_OLD_LINESEARCH_MINIMUM_STEP,
        GGML_OLD_LINESEARCH_MAXIMUM_STEP,
        GGML_OLD_LINESEARCH_MAXIMUM_ITERATIONS,
        GGML_OLD_LINESEARCH_INVALID_PARAMETERS,
    };

    // optimization parameters
    //
    //   see ggml.c (ggml_old_opt_default_params) for default values
    //
    struct ggml_old_opt_params {
        enum ggml_old_opt_type type;

        int n_threads;

        // delta-based convergence test
        //
        //   if past == 0 - disabled
        //   if past > 0:
        //     stop if |f(x) - f(x_past)| < delta * max(1, |f(x)|)
        //
        int past;
        float delta;

        // maximum number of iterations without improvement
        //
        //   if 0 - disabled
        //   if > 0:
        //     assume convergence if no cost improvement in this number of iterations
        //
        int max_no_improvement;

        bool print_forward_graph;
        bool print_backward_graph;

        // ADAM parameters
        struct {
            int n_iter;

            float sched; // schedule multiplier (fixed, decay or warmup)
            float decay; // weight decay for AdamW, use 0.0f to disable
            float alpha; // learning rate
            float beta1;
            float beta2;
            float eps;   // epsilon for numerical stability
            float eps_f; // epsilon for convergence test
            float eps_g; // epsilon for convergence test
        } adam;

        // LBFGS parameters
        struct {
            int m; // number of corrections to approximate the inv. Hessian
            int n_iter;
            int max_linesearch;

            float eps;      // convergence tolerance
            float ftol;     // line search tolerance
            float wolfe;
            float min_step;
            float max_step;

            enum ggml_old_linesearch linesearch;
        } lbfgs;
    };

    struct ggml_old_opt_context {
        struct ggml_old_context * ctx;
        struct ggml_old_opt_params params;

        int iter;
        int64_t nx; // number of parameter elements

        bool just_initialized;

        struct {
            struct ggml_old_tensor * x;  // view of the parameters
            struct ggml_old_tensor * g1; // gradient
            struct ggml_old_tensor * g2; // gradient squared
            struct ggml_old_tensor * m;  // first moment
            struct ggml_old_tensor * v;  // second moment
            struct ggml_old_tensor * mh; // first moment hat
            struct ggml_old_tensor * vh; // second moment hat
            struct ggml_old_tensor * pf; // past function values
            float fx_best;
            float fx_prev;
            int n_no_improvement;
        } adam;

        struct {
            struct ggml_old_tensor * x;    // current parameters
            struct ggml_old_tensor * xp;   // previous parameters
            struct ggml_old_tensor * g;    // current gradient
            struct ggml_old_tensor * gp;   // previous gradient
            struct ggml_old_tensor * d;    // search direction
            struct ggml_old_tensor * pf;   // past function values
            struct ggml_old_tensor * lmal; // the L-BFGS memory alpha
            struct ggml_old_tensor * lmys; // the L-BFGS memory ys
            struct ggml_old_tensor * lms;  // the L-BFGS memory s
            struct ggml_old_tensor * lmy;  // the L-BFGS memory y
            float fx_best;
            float step;
            int j;
            int k;
            int end;
            int n_no_improvement;
        } lbfgs;
    };

    GGML_OLD_API struct ggml_old_opt_params ggml_old_opt_default_params(enum ggml_old_opt_type type);

    // optimize the function defined by the tensor f
    GGML_OLD_API enum ggml_old_opt_result ggml_old_opt(
            struct ggml_old_context * ctx,
            struct ggml_old_opt_params params,
            struct ggml_old_tensor * f);

    // initialize optimizer context
    GGML_OLD_API void ggml_old_opt_init(
            struct ggml_old_context * ctx,
            struct ggml_old_opt_context * opt,
            struct ggml_old_opt_params params,
            int64_t nx);

    // continue optimizing the function defined by the tensor f
    GGML_OLD_API enum ggml_old_opt_result ggml_old_opt_resume(
            struct ggml_old_context * ctx,
            struct ggml_old_opt_context * opt,
            struct ggml_old_tensor * f);

    // continue optimizing the function defined by the tensor f
    GGML_OLD_API enum ggml_old_opt_result ggml_old_opt_resume_g(
            struct ggml_old_context * ctx,
            struct ggml_old_opt_context * opt,
            struct ggml_old_tensor * f,
            struct ggml_old_cgraph * gf,
            struct ggml_old_cgraph * gb);

    //
    // quantization
    //

    GGML_OLD_API size_t ggml_old_quantize_q4_0(const float * src, void * dst, int n, int k, int64_t * hist);
    GGML_OLD_API size_t ggml_old_quantize_q4_1(const float * src, void * dst, int n, int k, int64_t * hist);
    GGML_OLD_API size_t ggml_old_quantize_q5_0(const float * src, void * dst, int n, int k, int64_t * hist);
    GGML_OLD_API size_t ggml_old_quantize_q5_1(const float * src, void * dst, int n, int k, int64_t * hist);
    GGML_OLD_API size_t ggml_old_quantize_q8_0(const float * src, void * dst, int n, int k, int64_t * hist);

    GGML_OLD_API size_t ggml_old_quantize_chunk(enum ggml_old_type type, const float * src, void * dst, int start, int n, int64_t * hist);

    //
    // system info
    //

    GGML_OLD_API int ggml_old_cpu_has_avx        (void);
    GGML_OLD_API int ggml_old_cpu_has_avx2       (void);
    GGML_OLD_API int ggml_old_cpu_has_avx512     (void);
    GGML_OLD_API int ggml_old_cpu_has_avx512_vbmi(void);
    GGML_OLD_API int ggml_old_cpu_has_avx512_vnni(void);
    GGML_OLD_API int ggml_old_cpu_has_fma        (void);
    GGML_OLD_API int ggml_old_cpu_has_neon       (void);
    GGML_OLD_API int ggml_old_cpu_has_arm_fma    (void);
    GGML_OLD_API int ggml_old_cpu_has_f16c       (void);
    GGML_OLD_API int ggml_old_cpu_has_fp16_va    (void);
    GGML_OLD_API int ggml_old_cpu_has_wasm_simd  (void);
    GGML_OLD_API int ggml_old_cpu_has_blas       (void);
    GGML_OLD_API int ggml_old_cpu_has_cublas     (void);
    GGML_OLD_API int ggml_old_cpu_has_clblast    (void);
    GGML_OLD_API int ggml_old_cpu_has_gpublas    (void);
    GGML_OLD_API int ggml_old_cpu_has_sse3       (void);
    GGML_OLD_API int ggml_old_cpu_has_vsx        (void);

    //
    // Internal types and functions exposed for tests and benchmarks
    //

#ifdef  __cplusplus
    // restrict not standard in C++
#define GGML_OLD_RESTRICT
#else
#define GGML_OLD_RESTRICT restrict
#endif
    typedef void (*dequantize_row_q_t)(const void * GGML_OLD_RESTRICT x, float * GGML_OLD_RESTRICT y, int k);
    typedef void (*quantize_row_q_t)  (const float * GGML_OLD_RESTRICT x, void * GGML_OLD_RESTRICT y, int k);
    typedef void (*vec_dot_q_t)       (const int n, float * GGML_OLD_RESTRICT s, const void * GGML_OLD_RESTRICT x, const void * GGML_OLD_RESTRICT y);

    typedef struct {
        dequantize_row_q_t dequantize_row_q;
        quantize_row_q_t   quantize_row_q;
        quantize_row_q_t   quantize_row_q_reference;
        quantize_row_q_t   quantize_row_q_dot;
        vec_dot_q_t        vec_dot_q;
        enum ggml_old_type     vec_dot_type;
    } quantize_fns_t;

    quantize_fns_t ggml_old_internal_get_quantize_fn(size_t i);

#ifdef  __cplusplus
}
#endif
