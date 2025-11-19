from transformers import AutoTokenizer, AutoModelForCausalLM
import torch

model_name = "zwhc/chunk_debugger"


tokenizer = AutoTokenizer.from_pretrained(model_name, trust_remote_code=True)
model = AutoModelForCausalLM.from_pretrained(model_name, trust_remote_code=True, torch_dtype=torch.bfloat16).cuda()
chunk_code = ""
module_spec = ""
module_code = ""

prompt = f'''
    Assume you are an experienced IC designer. Next I will provide you with a design description of a hardware module, a Verilog implementation code of this module, and a targeted portion of this code. This targeted portion may contain bugs that prevent the whole code from correctly implementing the described functionality. If there are bugs, please modify and output corrected portion; if there are no bugs, output the targeted portion unchanged. 
    Note: (1) You need to make modifications based on the design description and the whole code snippet;
    (2) Other parts of the code may also contain bugs, but you only need to focus on bugs in this targeted portion.
    Design description:
    ```Markdown
    {module_spec}
    ```
    Code implementation:
    ```Verilog
    {module_code}
    ```
    Targeted portion:
    ```Verilog
    {chunk_code}
    ```
    The corrected targeted portion is:
'''

messages = [{"role": "user", "content": prompt}]
inputs = tokenizer.apply_chat_template(messages, add_generation_prompt=True, return_tensors="pt").to(model.device)
outputs = model.generate(
    inputs,
    max_new_tokens=16384,
    do_sample=True,
    top_p=0.95,
    temperature=0.4,
    num_return_sequences=1,
    eos_token_id=tokenizer.eos_token_id,
)
print(tokenizer.decode(outputs[0][len(inputs[0]) :], skip_special_tokens=True))