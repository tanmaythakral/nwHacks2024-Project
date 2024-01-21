import string
import threading
from flask import Flask, request, jsonify
import json
import random
import io
<<<<<<< HEAD
from PIL import Image
import firebase_admin
from firebase_admin import credentials, initialize_app, storage
=======
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
from skimage import restoration
import cv2
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

payload_filename = 'backend/data/payload.json'


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
>>>>>>> b46880a (Most)

app = Flask(__name__)

# Load existing data from the JSON files
users_filename = 'backend/data/users.json'
groups_filename = 'backend/data/groups.json'
payload_filename = 'backend/data/payload.json'

# Load existing users data from the JSON file
try:
    with open(users_filename, 'r') as file:
        users_data = json.load(file)
        users = users_data.get('users', {})
except FileNotFoundError:
    users = {}

# Load existing groups data from the JSON file
try:
    with open(groups_filename, 'r') as file:
        groups_data = json.load(file)
        groups = groups_data.get('groups', {})
except FileNotFoundError:
    groups = {}


# User Endpoints

@app.route('/api/users', methods=['GET'])
def get_users():
    return jsonify({'users': users, 'len_users': len(users)})


@app.route('/api/users/<username>', methods=['GET'])
def get_user(username):
    user = users.get(username)
    if user:
        return jsonify(user)
    return jsonify({'error': 'User not found'}), 404


@app.route('/api/users/create', methods=['POST'])
def create_user():
    data = request.json  # Get JSON payload from the request
    username = data.get('username')
    phone = data.get('phone')

    # Check if the username already exists
    if username in users:
        return jsonify({'message': 'Username already exists'}), 400

    # Create the user
    users[username] = {
        'username': username,
        'phone': phone,
<<<<<<< HEAD
        'groups': []
        # remaining fields blank at creation
    }
    save_users_to_json()
=======
        'groups': [],
        
    })
>>>>>>> b46880a (Most)
    return jsonify({'username': username, 'message': 'User registered successfully'})


@app.route('/api/users/login', methods=['POST'])
def login_user():
    data = request.json  # Get JSON payload from the request
    username = data.get('username')
    phone = data.get('phone')

    # Check if the username already exists
    if username in users:
        return jsonify({'message': 'Login successful', 'user': users[username]})
    else:
        return jsonify({'message': 'User not found'}), 404


# Group Endpoints

@app.route('/api/groups', methods=['GET'])
def get_groups():
    return jsonify({'groups': groups, 'len_groups': len(groups)})


@app.route('/api/groups/create', methods=['POST'])
def create_group():
    # We require group_name, and username of the creator
    data = request.get_json()
    group_name = data.get('group_name')
    username = data.get('username')

    # Check if the user is already in a group
    if username in users:
        current_group = users[username].get('groups', [])

        # Check if the user is already a member of a group
        if len(current_group) > 0:
            # Remove the user from the current group
            old_group_code = current_group[0]
            groups[old_group_code]['members'].remove(username)

<<<<<<< HEAD
            # Save updated data to JSON files
            save_groups_to_json()
=======
        new_group = {
            'group_code': group_code,
            'group_name': group_name,
            'members': [uid],
            'drawing_link': ''
        }
>>>>>>> b46880a (Most)

    # Generate a unique group code
    group_code = generate_unique_group_code()

    # Create the group
    groups[group_code] = {
        'group_code': group_code,
        'group_name': group_name,
        'members': [username],
        'drawing_link': ''  # !!! Create generate_drawing_link function
    }

    # Update user's groups without removing other fields
    user_data = users.get(username, {})
    user_data['groups'] = [group_code]
    users[username] = user_data

    # Save updated data to JSON files
    save_users_to_json()
    save_groups_to_json()

    return jsonify({'group_code': group_code, 'message': 'Group created successfully'})


@app.route('/api/groups/join', methods=['POST'])
def join_group():
    # We require group_code and username
    data = request.get_json()
    group_code = data.get('group_code')
    username = data.get('username')

    # Check if the group exists
    if group_code in groups:
        # Check if the user is not already a member of the group
        if username not in groups[group_code]['members']:
            # Check if the user is already in a group
            if username in users:
                current_group = users[username].get('groups', [])
                # Check if the user is already a member of another group
                if len(current_group) > 0:
                    # Remove the user from the current group
                    old_group_code = current_group[0]
                    groups[old_group_code]['members'].remove(username)

                    # Save updated data to JSON files
                    save_groups_to_json()

            # Update the new group's members
            groups[group_code]['members'].append(username)

            # Update user's groups without removing other fields
            user_data = users.get(username, {})
            user_data['groups'] = [group_code]
            users[username] = user_data

            # Save updated data to JSON files
            save_users_to_json()
            save_groups_to_json()

            return jsonify({'group_code': group_code, 'message': 'Joined group successfully'})
        else:
            return jsonify({'message': 'User is already a member of the group'}), 400
    else:
        return jsonify({'message': 'Group not found'}), 404


@app.route('/api/groups/draw', methods=['POST'])
def fetch_drawing():
    data = request.get_json()
    group_code = data.get('group_code')
    username = data.get('username')

    with open(payload_filename, 'r') as file:
        payload_data = json.load(file)

    for key, group_data in payload_data.get('payload', {}).items():
        if key == group_code:
            user_data = group_data.get('images', {}).get(username, None)

            if user_data:
                return jsonify({
                    'coordinates': user_data.get('coordinates', []),
                    'image_text': user_data.get('image_text', ""),
                    'original_image': group_data.get('original_image', "")
                })

    return jsonify({'message': 'Group or user not found'}), 404


def create_payload():
    generated = {}
    global_payload = []


@app.route('/api/unleash', methods=['GET'])
def unleash():
    generated = {}
    global_payload = {}  # Change the content type as needed
<<<<<<< HEAD
    for group_code, group in groups.items():
        n = len(group.get("members", []))

        cred = credentials.Certificate("backend/app/pixdraw-20623-0b84bbec58a4.json")
        firebase_admin.initialize_app(cred, {"storageBucket": "pixdraw-20623.appspot.com"})

        if n not in generated:
            texts, boxes, blurred_image = generate(n)
            # blurred_image.save('blur_image.png')
            group.drawing_link = 'blur_image_' + group.group_code + '.png'
=======

    groups_ref = db.collection('groups')
    groups_docs = groups_ref.stream()
    groups = {doc.id: doc.to_dict() for doc in groups_docs}
    for group_code, group in groups.items():
        n = len(group.get("members", []))

        if n not in generated:
            texts, boxes, blurred_image = generate(n)
            # blurred_image.save('blur_image.png')
            group['drawing_link'] = 'blur_image_' + group_code + '.png'
>>>>>>> b46880a (Most)

            blur_image_bytes = io.BytesIO()
            blurred_image.save(blur_image_bytes, format='PNG')

            bucket = storage.bucket()
<<<<<<< HEAD
            blur_blob = bucket.blob(group.drawing_link)
=======
            blur_blob = bucket.blob(group['drawing_link'])
>>>>>>> b46880a (Most)
            blur_blob.upload_from_string(blur_image_bytes.getvalue(), content_type='image/png')



            payload = {
                "images": {},
                "original_image": 'blur_image.png'
            }

            # Iterate through group members and assign images to their usernames
            for username, (text, box) in zip(group["members"], zip(texts, boxes)):
                # Convert NumPy arrays to lists
                box_list = box.tolist()
                text_list = text.tolist() if isinstance(text, np.ndarray) else text

                payload["images"][username] = {"coordinates": box_list, "image_text": text_list}

            generated[n] = payload
            group_payload = {group_code: payload}
        else:
            group_payload = {group_code: generated[n]}

        global_payload.update(group_payload)

    send_notification()
    save_payload_to_json(global_payload)
    print(global_payload)
    return jsonify({'payload': global_payload})


# helpers
def send_notification():
    # Implement logic to send a notification to all users
    # ...
    pass


def generate_unique_group_code():
    while True:
        # Generate a random 6-character code
        group_code = ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))

        # Check if the code is unique
        if group_code not in groups:
            return group_code


# Function to save users data to JSON file
def save_users_to_json():
    with open(users_filename, 'w') as file:
        json.dump({'users': users}, file, indent=2)

<<<<<<< HEAD
=======
# # Function to execute a function after a delay
# def execute_after_delay(delay, func):
#     threading.Timer(delay, func).start()
        
# Function to save users data to JSON file
def save_payload_to_json(global_payload):
    with open(payload_filename, 'w') as file:
        json.dump({'payload:': global_payload}, file, indent=2)
>>>>>>> b46880a (Most)

# Function to save groups data to JSON file
def save_groups_to_json():
    with open(groups_filename, 'w') as file:
        json.dump({'groups': groups}, file, indent=2)

    # Function to save users data to JSON file


def save_payload_to_json(global_payload):
    with open(payload_filename, 'w') as file:
        json.dump({'payload:': global_payload}, file, indent=2)


# Function to execute a function after a delay
def execute_after_delay(delay, func):
    threading.Timer(delay, func).start()


# Execute the delayed function after a 30-second countdown


if __name__ == '__main__':
    app.run(debug=True)
    execute_after_delay(30, send_notification)  # send notification after 30 seconds that Bereal
