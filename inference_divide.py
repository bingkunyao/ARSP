from transformers import AutoTokenizer, AutoModelForCausalLM
import torch

model_name = "zwhc/code_divider"


tokenizer = AutoTokenizer.from_pretrained(model_name, trust_remote_code=True)
model = AutoModelForCausalLM.from_pretrained(model_name, trust_remote_code=True, torch_dtype=torch.bfloat16).cuda()
module_spec = ""
module_code = ""

prompt = f'''
    Assume you are a Verilog code expert. Below is a piece of Verilog code that is too long, so please divide it into several parts. You only need to output each part separately. 
    Requirements: When all these parts are combined in sequence, they must be EXACTLY identical to the original code. 
    DO NOT omit or skip any lines - every single line from the original code must be included in one of the parts even if the code may have similar implementation logic to other code.    
    Design description:
    ```Markdown
    {module_spec}
    ```
    Code implementation:
    ```Verilog
    {module_code}
    ```
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