from ultralytics import RTDETR, YOLO
import torch
import urllib.request
import numpy as np
from PIL import Image
# from rake_nltk import Rake
from transformers import BlipProcessor, BlipForConditionalGeneration
import openai
import logging
import os
# from skimage import restoration
import cv2
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def load_models(yolo_path, rtdetr_path, save_path):
    model1 = YOLO(yolo_path)
    model2 = RTDETR(rtdetr_path)
    model2.model.names = model1.model.names
    torch.save(model2, save_path)
    return torch.load(save_path)

def filter_inside_boxes(boxes, cls_names, original_names):
    filtered_boxes = []
    filtered_cls_names = []
    for i, box_i in enumerate(boxes):
        is_inside = False
        for j, box_j in enumerate(boxes):
            if i != j and is_inside_box(box_i, box_j):
                is_inside = True
                break
        if not is_inside:
            filtered_boxes.append(box_i)
            filtered_cls_names.append(original_names[cls_names[i]])
    return filtered_boxes, filtered_cls_names

def is_inside_box(box_i, box_j):
    x_min_i, y_min_i, x_max_i, y_max_i = box_i
    x_min_j, y_min_j, x_max_j, y_max_j = box_j
    return x_min_i >= x_min_j and y_min_i >= y_min_j and x_max_i <= x_max_j and y_max_i <= y_max_j

def get_boxes_and_class(source):
    yolo_path = 'yolov8n.pt'
    rtdetr_path = 'rtdetr-x.pt'
    save_path = 'rtdetr-x-names.pt'

    model3 = load_models(yolo_path, rtdetr_path, save_path)
    print(model3.names)
    results = model3(source, save=True, iou=0.5, conf=0.4)

    original_names = model3.names
    box = None
    cls_names = None

    for r in results:
        box = r.boxes.xyxy
        cls_names = r.boxes.cls.cpu().numpy()

    filtered_boxes, filtered_cls_names = filter_inside_boxes(box, cls_names, original_names)

    return filtered_boxes, filtered_cls_names

def load_blip_model():
    processor = BlipProcessor.from_pretrained("Salesforce/blip-image-captioning-base")
    model = BlipForConditionalGeneration.from_pretrained("Salesforce/blip-image-captioning-base")
    return processor, model

from PIL import Image
import numpy as np

def process_image_captioning(extracted_image, text="a photography of", conditional=False):
    processor, model = load_blip_model()
    # r = Rake()

    if isinstance(extracted_image, np.ndarray):
        # If extracted_image is a NumPy array
        raw_image = Image.fromarray(extracted_image.astype('uint8')).convert("RGB")
    else:
        raise ValueError("Unsupported type for extracted_image. Supported type: np.ndarray.")

    if conditional:
        inputs = processor(raw_image, text, return_tensors="pt")
        out = model.generate(**inputs)
        generated_text = processor.decode(out[0], skip_special_tokens=True)
    else:
        inputs = processor(raw_image, return_tensors="pt")
        out = model.generate(**inputs)
        generated_text = processor.decode(out[0], skip_special_tokens=True)

    remove_phrases = ["pixel", "pixel pixel", "pixel art of a", "pixel pixel art of a"]
    
    if remove_phrases:
        for phrase in remove_phrases:
            generated_text = generated_text.replace(phrase, '')

    print(generated_text)
    return generated_text



def most_frequent_color(arr):
    # Reshape the array to a 2D array (pixels x channels)
    pixels = arr.reshape(-1, arr.shape[-1])
    
    # Find the mode for each channel
    modes = [np.argmax(np.bincount(pixels[:, i])) for i in range(pixels.shape[1])]
    
    return tuple(modes)

def remove_bboxes_with_mode_color(image_path, bboxes):
    img = Image.open(image_path)
    img_removed = Image.new("RGB", img.size, (255, 255, 255))
    img_removed.paste(img, (0, 0))

    for bbox in bboxes:
        x_min, y_min, x_max, y_max = map(int, bbox)
        img_copy = img.copy()
        crop_img = img_copy.crop((x_min, y_min, x_max, y_max))
        np_img = np.array(crop_img)
        
        # Get the most frequent color in the region
        mode_color = most_frequent_color(np_img)
        
        region_to_remove = (x_min, y_min, x_max, y_max)
        img_removed.paste(mode_color, region_to_remove)

    # img_removed.show(title='Image with Bounding Boxes Removed and Filled with Mode Color')
    img_removed.save('image_with_bboxes_removed_mode_color.jpg')

    return img_removed



def extract_images_from_bboxes(image_path, bboxes):
    original_img = Image.open(image_path)
    cropped_images = []
    for bbox in bboxes:
        x_min, y_min, x_max, y_max = map(int, bbox)
        copy_img = original_img.copy()
        cropped_img = copy_img.crop((x_min, y_min, x_max, y_max))
        cropped_array = np.array(cropped_img)
        cropped_images.append(cropped_array)

    return cropped_images

def stitch_image(user_image, user_bbox, original_cropped_image):
    x_min, y_min, x_max, y_max = map(int, user_bbox)
    user_image = Image.fromarray(user_image)
    original_cropped_image.paste(user_image, (x_min, y_min))

    # original_cropped_image.show(title='Image with User Image Stitched')
    return original_cropped_image

def keep_top_k_biggest_boxes(boxes, cls_names, k=3, percentage=55):
    boxes = np.array(boxes)
    cls_names = np.array(cls_names)
    areas = (boxes[:, 2] - boxes[:, 0]) * (boxes[:, 3] - boxes[:, 1])
    sorted_indices = np.argsort(areas)
    
    top_percentage = int(len(boxes) * (percentage / 100.0))
    
    if top_percentage > k:
        top_indices = np.random.choice(sorted_indices[-top_percentage:], k, replace=False)
    else:
        top_indices = sorted_indices[-k:]
    
    return boxes[top_indices], cls_names[top_indices]

def generate(k, image_folder="good_images"):
    source = "backend/app/good_images/pixelart2.png"
    filtered_boxes, filtered_cls_names = get_boxes_and_class(source=source)
    # add_blur(source, filtered_boxes[0])
    logger.info(f"Filtered Boxes: {filtered_boxes}")

    if len(filtered_boxes) > k:
        logger.info(f"Sufficient boxes ({len(filtered_boxes)}) in {source}. Proceeding with the initial source.")
    else:
        logger.warning(f"Not enough boxes ({len(filtered_boxes)}) in {source} to generate {k} images. Checking other images in the folder.")
        
        for filename in os.listdir(image_folder):
            if filename.lower().endswith((".png", ".jpg", ".jpeg")):
                source = os.path.join(image_folder, filename)
                filtered_boxes, filtered_cls_names = get_boxes_and_class(source=source)
                logger.info(f"Filtered Boxes: {filtered_boxes}")

                if len(filtered_boxes) > k:
                    logger.info(f"Sufficient boxes ({len(filtered_boxes)}) in {filename}. Proceeding with this image.")
                    break

    # Continue with the rest of the processing
    top_k_boxes, top_k_names = keep_top_k_biggest_boxes(filtered_boxes, filtered_cls_names, k=k)
    extracted_images = extract_images_from_bboxes(image_path=source, bboxes=top_k_boxes)
    logger.info(f"Extracted Images: {extracted_images}")

    # for images in extracted_images:
    #     # Image.fromarray(images).show()

    # removed_image = remove_bboxes_with_mode_color(image_path=source, bboxes=top_k_boxes)
        
    blurred_image = add_blur(source, top_k_boxes)

    texts = []
    for images in extracted_images:
        print(type(images))
        text = process_image_captioning(images)
        texts.append(text)

    return texts, top_k_boxes, blurred_image

def add_blur(source, bboxes, margin=5, blur_iterations=5):
    image = Image.open(source)
    for bbox in bboxes:
        x_min, y_min, x_max, y_max = map(int, bbox)
        
        x_min -= margin
        y_min -= margin
        x_max += margin
        y_max += margin
        
        x_min = max(x_min, 0)
        y_min = max(y_min, 0)
        x_max = min(x_max, image.width)
        y_max = min(y_max, image.height)
        crop_img = image.crop((x_min, y_min, x_max, y_max))
        np_img = np.array(crop_img)
        
        for _ in range(blur_iterations):
            np_img = cv2.GaussianBlur(np_img, (35, 35), 50)
        
        blurred_img = Image.fromarray(np_img)
        image.paste(blurred_img, (x_min, y_min, x_max, y_max))
    # image.show(title='Image with Bounding Boxes Blurred')
    
    return image