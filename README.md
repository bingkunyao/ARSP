These are open-sourced materials of the paper "ARSP: Automated Repair of Verilog Design via Semantic Partition". 

## Directory Structure

ErrorSet/: The test dataset of ARSP.

requirements.txt: Specify the required dependencies.

inference_divide.py: The code for the inference of the Partitioning LLM.

inference_debug.py: The code for the inference of the Repair LLM.

examples_of_bug_locality/: Examples of bugs and semantically tight chunks in our analysis in Section 2 of the paper.

## Model Usage

Firstly, you need to install all dependencies using 
```python
pip install -r requirements.txt
```

Then, run inference_divide.py or inference_debug.py to partition a module into semantically tight chunks or repair a chunk. 

## Link

Models can be downloaded from https://huggingface.co/zwhc/code_divider and https://huggingface.co/zwhc/chunk_debugger.

The training data can be found at https://huggingface.co/datasets/zwhc/ARSP_training_dataset/tree/main.