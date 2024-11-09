from transformers import AutoImageProcessor, TableTransformerForObjectDetection
from PIL import Image
import torch
import os

image_processor = AutoImageProcessor.from_pretrained("microsoft/table-transformer-detection")
model = TableTransformerForObjectDetection.from_pretrained("microsoft/table-transformer-detection")

for year in range(2003, 2024):
    folder_path = f'data/intermediate/antenne_reports_to_images/antenne_amsterdam_{year}'
    file_names = [f for f in os.listdir(folder_path) if f.endswith('.png')]
    for file_name in file_names:
        file_path = os.path.join(folder_path, file_name)
        image = Image.open(file_path).convert("RGB")
        # prepare image for the model
        inputs = image_processor(images=image, return_tensors="pt")
        # forward pass
        outputs = model(**inputs)
        # the last hidden states are the final query embeddings of the Transformer decoder
        # these are of shape (batch_size, num_queries, hidden_size)
        # last_hidden_states = outputs.last_hidden_state
        # list(last_hidden_states.shape)
        # convert outputs (bounding boxes and class logits) to Pascal VOC format (xmin, ymin, xmax, ymax)
        target_sizes = torch.tensor([image.size[::-1]])
        results = image_processor.post_process_object_detection(outputs, threshold=0.9, target_sizes=target_sizes)[0]
        tensors_name = file_name.replace('.png', '')
        torch.save(results['boxes'], f'data/intermediate/antenne_reports_table_tensors/antenne_amsterdam_{year}/{tensors_name}.pt')