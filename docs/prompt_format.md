# Prompt format
You can use `{prompt}` or `{{prompt}}` to indicate a prompt.
The system prompt can be specified at the beginning of the template in the format `[system](<your system prompt>)`.

## BOS option:
Adds the Begin Of Session token to the beginning of the prompt.

## EOS option:
Adds the End Of Session token to the end of the prompt.

## Option Special:
If enabled, the tokenizer will accept special tokens in the template, such as `<|user|>`.

## Option reverse prompts:
Allows you to specify sequences at the occurrence of which the prediction will be stopped. The sequences are specified using commas.
Example: `<|end|>,user:`.

## Option skip tokens:
Allows you to specify tokens (in string format) that will not be displayed in the prediction results. Tokens are specified using commas.
Example: `<|end|>,<|assistant|>`.
