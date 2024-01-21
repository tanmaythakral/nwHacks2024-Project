from ultralytics import RTDETR, YOLO
import torch
import numpy as np
import requests
from PIL import Image
from transformers import BlipProcessor, BlipForConditionalGeneration

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
    rtdetr_path = 'rtdetr-l.pt'
    save_path = 'rtdetr-l-names.pt'

    model3 = load_models(yolo_path, rtdetr_path, save_path)
    print(model3.names)
    results = model3(source, save=True)

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

def process_image_captioning(extracted_image, text="a photography of", conditional = True):
    processor, model = load_blip_model()

    raw_image = extracted_image
    if conditional == True:
        # Conditional image captioning
        inputs = processor(raw_image, text, return_tensors="pt")
        out = model.generate(**inputs)
        print(processor.decode(out[0], skip_special_tokens=True))
        return processor.decode(out[0], skip_special_tokens=True)
    else:
        # Unconditional image captioning
        inputs = processor(raw_image, return_tensors="pt")
        out = model.generate(**inputs)
        print(processor.decode(out[0], skip_special_tokens=True))
        return processor.decode(out[0], skip_special_tokens=True)
    

def remove_bboxes_from_image(image_path, bboxes):
    img = Image.open(image_path)
    img_removed = Image.new("RGB", img.size, (255, 255, 255))
    img_removed.paste(img, (0, 0))

    for bbox in bboxes:
        x_min, y_min, x_max, y_max = map(int, bbox)
        region_to_remove = (x_min, y_min, x_max, y_max)
        img_removed.paste((255, 255, 255), region_to_remove)

    img_removed.show(title='Image with Bounding Boxes Removed and Filled with White')
    img_removed.save('image_with_bboxes_removed_white.jpg')
    
    return img_removed


def extract_images_from_bboxes(image_path, bboxes):
    # Open the original image
    original_img = Image.open(image_path)
    cropped_images = []
    for bbox in bboxes:
        x_min, y_min, x_max, y_max = map(int, bbox)
        cropped_img = original_img.crop((x_min, y_min, x_max, y_max))
        cropped_array = np.array(cropped_img)
        cropped_images.append(cropped_array)

    return cropped_images, original_img


def stitch_image(user_image, user_bbox, original_cropped_image):
    x_min, y_min, x_max, y_max = map(int, user_bbox)
    width, height = x_max - x_min, y_max - y_min  # Calculate width and height of the box
    user_image = Image.fromarray(user_image)
    # Resize user_image to match the size of the bounding box
    user_image = user_image.resize((width, height))

    # Paste the resized user_image onto the original_cropped_image
    original_cropped_image.paste(user_image, (x_min, y_min))

    original_cropped_image.show(title='Image with User Image Stitched')
    return original_cropped_image


def keep_top_k_biggest_boxes(boxes, cls_names, k=3):
    boxes = np.array(boxes)
    cls_names = np.array(cls_names)
    areas = (boxes[:, 2] - boxes[:, 0]) * (boxes[:, 3] - boxes[:, 1])
    sorted_indices = np.argsort(areas)
    top_k_indices = sorted_indices[-k:]
    return boxes[top_k_indices], cls_names[top_k_indices]

def get_images_from_user():
    pass

def main():
    source = "pixelart2.png"
    filtered_boxes, filtered_cls_names = get_boxes_and_class(source = source)
    print(filtered_boxes)
    top_k_boxes, top_k_names = keep_top_k_biggest_boxes(filtered_boxes, filtered_cls_names, k=3)
    extracted_images, original_cropped_image = extract_images_from_bboxes(image_path= source, bboxes=top_k_boxes)
    print(extracted_images)
    for images in extracted_images:
        Image.fromarray(images).show()
    print(original_cropped_image)
    removed_image = remove_bboxes_from_image(image_path= source, bboxes=top_k_boxes)
    for images in extracted_images:
        process_image_captioning(images, None, False)

    # user_images, user_bbox = get_images_from_user()
    stitch_image(extracted_images[0], filtered_boxes[0], original_cropped_image)

if __name__ == "__main__":
    main()

    
