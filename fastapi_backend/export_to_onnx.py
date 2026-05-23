from optimum.onnxruntime import ORTModelForSequenceClassification
from transformers import AutoTokenizer

MODEL_NAME = "finmigodeveloper/distilbert-transaction-classifier"

tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME)

model = ORTModelForSequenceClassification.from_pretrained(
    MODEL_NAME,
    export=True,
)

model.save_pretrained("./onnx_model")
tokenizer.save_pretrained("./onnx_model")
