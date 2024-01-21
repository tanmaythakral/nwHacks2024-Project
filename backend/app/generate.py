from ultralytics import RTDETR, YOLO
import torch
import urllib.request
import numpy as np
import nltk
from PIL import Image
from rake_nltk import Rake
from transformers import BlipProcessor, BlipForConditionalGeneration
import openai

def openai_api_call(num_objects):
    openai.api_key = ""

    num_objects = num_objects

    prompt = 'Create a 2D, pixel art image in portrait mode of a [specific scene, e.g., beach, garden, ' \
             'cityscape, desert, hills, bedroom] . The ' \
             'image should include {} large and distinct objects from the COCO Dataset. The background ' \
             'should be minimal, [relevant background elements, e.g., ' \
             'sand and ocean, grass and sky, buildings and sky], with no complex elements. ' \
             'The image should have {} large, several and distinct objects from the COCO Dataset. Make it extremely slight realistic. Make it complex in nature'.format(num_objects, num_objects)

    response = openai.images.generate(
        model="dall-e-3",
        prompt=prompt,
        size="1024x1792",
        quality="standard",
        n=1,
    )

    # response.data[0].url

    return response.data[0].url

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
    urllib.request.urlretrieve(source, "image.jpg")
    yolo_path = 'yolov8n.pt'
    rtdetr_path = 'rtdetr-x.pt'
    save_path = 'rtdetr-x-names.pt'

    model3 = load_models(yolo_path, rtdetr_path, save_path)
    print(model3.names)
    results = model3("image.jpg", save=True)

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
    r = Rake()

    raw_image = extracted_image
    if conditional == True:
        # Conditional image captioning
        inputs = processor(raw_image, text, return_tensors="pt")
        out = model.generate(**inputs)
        print(processor.decode(out[0], skip_special_tokens=True))
        r.extract_keywords_from_text(processor.decode(out[0], skip_special_tokens=True))
        print(r.get_ranked_phrases()[0])
        return processor.decode(out[0], skip_special_tokens=True)
    else:
        # Unconditional image captioning
        inputs = processor(raw_image, return_tensors="pt")
        out = model.generate(**inputs)
        print(processor.decode(out[0], skip_special_tokens=True))
        r.extract_keywords_from_text(processor.decode(out[0], skip_special_tokens=True))
        print(r.get_ranked_phrases()[0], r.get_ranked_phrases()[1])
        return processor.decode(out[0], skip_special_tokens=True)



def remove_bboxes_from_image(image_path, bboxes):
    img = Image.open(image_path)
    img_removed = Image.new("RGB", img.size, (255, 255, 255))
    img_removed.paste(img, (0, 0))

    for bbox in bboxes:
        x_min, y_min, x_max, y_max = map(int, bbox)
        img_copy = img.copy()
        crop_img = img_copy.crop((x_min, y_min, x_max, y_max))
        np_img = np.array(crop_img)
        avg_color = tuple(np_img.mean(axis=(0, 1)).astype(int))
        region_to_remove = (x_min, y_min, x_max, y_max)
        img_removed.paste(avg_color, region_to_remove)

    img_removed.show(title='Image with Bounding Boxes Removed and Filled with White')
    img_removed.save('image_with_bboxes_removed_white.jpg')
    
    return img_removed


def extract_images_from_bboxes(image_path, bboxes):
    # Open the original image
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

    # Paste the resized user_image onto the original_cropped_image
    original_cropped_image.paste(user_image, (x_min, y_min))

    original_cropped_image.show(title='Image with User Image Stitched')
    return original_cropped_image


def keep_top_k_biggest_boxes(boxes, cls_names, k=3, percentage=55):
    boxes = np.array(boxes)
    cls_names = np.array(cls_names)
    areas = (boxes[:, 2] - boxes[:, 0]) * (boxes[:, 3] - boxes[:, 1])
    sorted_indices = np.argsort(areas)
    
    # Calculate the number of boxes in the top percentage
    top_percentage = int(len(boxes) * (percentage / 100.0))
    
    # If the top percentage is greater than k, select k boxes randomly
    if top_percentage > k:
        top_indices = np.random.choice(sorted_indices[-top_percentage:], k, replace=False)
    else:
        top_indices = sorted_indices[-k:]
    
    return boxes[top_indices], cls_names[top_indices]


def generate(k):
    source = openai_api_call(num_objects = k + 5)
    filtered_boxes, filtered_cls_names = get_boxes_and_class(source = source)
    print(filtered_boxes)
    top_k_boxes, top_k_names = keep_top_k_biggest_boxes(filtered_boxes, filtered_cls_names, k=k)
    extracted_images = extract_images_from_bboxes(image_path = "image.jpg", bboxes = top_k_boxes)
    print(extracted_images)
    for images in extracted_images:
        Image.fromarray(images).show()
    removed_image = remove_bboxes_from_image(image_path = "image.jpg", bboxes=top_k_boxes)

    texts = []
    for images in extracted_images:
        text = process_image_captioning(images, None, False)
        texts.append(text)

    return texts, top_k_boxes, removed_image


def get_images_from_user():
    pass

def main():
    # openai_api_call(5)
    # nltk.download('stopwords')
    # nltk.download('punkt')
    generate()
    image_from_user, users_box = get_images_from_user()
    # user_images, user_bbox = get_images_from_user()
    stitch_image(image_from_user, users_box, removed_image)

if __name__ == "__main__":
    main()

    
