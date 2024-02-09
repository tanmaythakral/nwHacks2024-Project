import string
import threading
from flask import Flask, request, jsonify
import json
import random
import io
from generate import generate
from PIL import Image
import firebase_admin
import numpy as np
import firebase_admin
from flask_cors import CORS
from firebase_admin import credentials, firestore, storage
from generate import stitch_image

app = Flask(__name__)
CORS(app)



# Load existing data from the JSON files
users_filename = 'backend/data/users.json'
groups_filename = 'backend/data/groups.json'
payload_filename = 'backend/data/payload.json'


cred = credentials.Certificate('backend/app/pixdraw-20623-0b84bbec58a4.json')
firebase_admin.initialize_app(cred, {
        'storageBucket': 'pixdraw-20623.appspot.com'
    })
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

# @app.route('/api/users', methods=['GET'])
# def get_users():
#     return jsonify({'users': users, 'len_users': len(users)})


# @app.route('/api/users/<username>', methods=['GET'])
# def get_user(username):
#     user = users.get(username)
#     if user:
#         return jsonify(user)
#     return jsonify({'error': 'User not found'}), 404


# @app.route('/api/users/create', methods=['POST'])
# def create_user():
#     data = request.json  # Get JSON payload from the request
#     username = data.get('username')
#     phone = data.get('phone')

#     # Check if the username already exists
#     if username in users:
#         return jsonify({'message': 'Username already exists'}), 400

#     # Create the user
#     users[username] = {
#         'username': username,
#         'phone': phone,
#         'groups': [],
        
#     })
#     return jsonify({'username': username, 'message': 'User registered successfully'})


# @app.route('/api/users/login', methods=['POST'])
# def login_user():
#     data = request.json  # Get JSON payload from the request
#     username = data.get('username')
#     phone = data.get('phone')

#     # Check if the username already exists
#     if username in users:
#         return jsonify({'message': 'Login successful', 'user': users[username]})
#     else:
#         return jsonify({'message': 'User not found'}), 404


# Group Endpoints

@app.route('/api/groups', methods=['GET'])
def get_groups():
    return jsonify({'groups': groups, 'len_groups': len(groups)})


@app.route('/api/groups/create', methods=['POST'])
def create_group():
    data = request.get_json()
    group_name = data.get('group_name')
    username = data.get('username')
    userid = data.get('userid')
    db = firestore.client()

    # # Check if the user is already in a group and remove them from the old group
    # if username in users:
    #     current_group = users[username].get('groups', [])
    #     if current_group:
    #         old_group_code = current_group[0]
    #         groups[old_group_code]['members'].remove(username)

    # Generate a unique group code
    group_code = generate_unique_group_code()

    # Create the group
    groups[group_code] = {
        'group_code': group_code,
        'group_name': group_name,
        'members': [username],  # Add the creator as a member of the group
        'drawing_link': ''  # Placeholder for drawing link
    }

    # Update Firebase Firestore with group data
    group_ref = db.collection('groups').document(group_code)
    group_ref.set({
        'group_name': group_name,
        'group_code': group_code,
        'members': [username],  # Add the creator as a member of the group
        'drawing_link': ''  # Placeholder for drawing link
    })

    # Update user's groups in Firestore
    user_ref = db.collection('users').document(username)
    user_ref.set({
        'groups': [group_code]  # Update the user's groups list
    }, merge=True)  # Merge to update user data without removing other fields

    return jsonify({'group_code': group_code, 'message': 'Group created successfully'}), 200

@app.route('/api/groups/join', methods=['POST'])
def join_group():
    data = request.get_json()
    group_code = data.get('group_code')
    username = data.get('username')
    db = firestore.client()


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

                    # Update Firebase Firestore with removed member from old group
                    old_group_ref = db.collection('groups').document(old_group_code)
                    old_group_ref.update({
                        'members': firestore.ArrayRemove([username])
                    })

                    # Update user's old group data in Firestore
                    old_user_ref = db.collection('users').document(username)
                    old_user_ref.update({
                        'groups': firestore.ArrayRemove([old_group_code])
                    })

            # Update the new group's members
            groups[group_code]['members'].append(username)

            # Update Firebase Firestore with added member to new group
            group_ref = db.collection('groups').document(group_code)
            group_ref.update({
                'members': firestore.ArrayUnion([username])
            })

            # Update user's groups in Firestore
            user_ref = db.collection('users').document(username)
            user_ref.update({
                'groups': firestore.ArrayUnion([group_code])
            })

            return jsonify({'group_code': group_code, 'message': 'Joined group successfully'}), 200
        else:
            return jsonify({'message': 'User is already a member of the group'}), 400
    else:
        return jsonify({'message': 'Group not found'}), 404
    


@app.route('/api/groups/leave', methods=['POST'])
def leave_group():
    data = request.get_json()
    group_code = data.get('group_code')
    username = data.get('username')
    db = firestore.client()

    # Check if the group exists
    if group_code in groups:
        # Check if the user is a member of the group
        if username in groups[group_code]['members']:
            # Remove the user from the group
            groups[group_code]['members'].remove(username)

            # Update Firebase Firestore with removed member from the group
            group_ref = db.collection('groups').document(group_code)
            group_ref.update({
                'members': firestore.ArrayRemove([username])
            })

            # Update user's groups in Firestore
            user_ref = db.collection('users').document(username)
            user_ref.update({
                'groups': firestore.ArrayRemove([group_code])
            })

            # Check if the group is empty after removing the user
            if not groups[group_code]['members']:
                # Delete the group from Firestore
                group_ref.delete()
                # Remove the group from the 'groups' dictionary
                del groups[group_code]

            return jsonify({'message': 'Left group successfully'}), 200
        else:
            return jsonify({'error': 'User is not a member of the group'}), 400
    else:
        return jsonify({'error': 'Group not found'}), 404
    


@app.route('/api/groups/members/<group_code>', methods=['GET'])
def get_group_members(group_code):
    if group_code in groups:
        group = groups[group_code]
        member_names = group['members']
        return jsonify({'members': member_names}), 200
    else:
        return jsonify({'error': 'Group not found'}), 404




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


@app.route('/api/groups/complete', methods=['POST'])
def complete_drawing():
    data = request.get_json()
    user_id = data.get('user_id')
    group_code = data.get('group_code')


    # fetch image from storage
    bucket = storage.bucket()
    blob = bucket.blob('drawings/' + group_code +  "/" + user_id + '.png')
    image_bytes = blob.download_as_string()
    image = Image.open(io.BytesIO(image_bytes))
    
    # fetch blur image from storage
    blur_blob = bucket.blob('drawings/' + group_code +  "/" + user_id + '_blur.png')
    blur_image_bytes = blur_blob.download_as_string()
    blur_image = Image.open(io.BytesIO(blur_image_bytes))



    # fetch user bboxes and texts from firestore
    db = firestore.client()
    user_ref = db.collection('users').document(user_id)
    user_data = user_ref.get().to_dict()
    user_bboxes = user_data.get('bboxes', [])


    # stich the images together
    stitch_image(image, blur_image, user_bboxes)


    # send image back to user
    return jsonify({'message': 'User Completed Drawing'}), 200


def create_payload():
    generated = {}
    global_payload = []


@app.route('/api/unleash', methods=['GET'])
def unleash():
    generated = {}
    global_payload = {}  # Change the content type as needed
    db = firestore.client()

    groups_ref = db.collection('groups')
    groups_docs = groups_ref.stream()
    groups = {doc.id: doc.to_dict() for doc in groups_docs}
    for group_code, group in groups.items():
        n = len(group.get("members", []))

        if n not in generated:
            texts, boxes, blurred_image = generate(n)
            # blurred_image.save('blur_image.png')
            group['drawing_link'] = 'blur_image_' + group_code + '.png'

            blur_image_bytes = io.BytesIO()
            blurred_image.save(blur_image_bytes, format='PNG')

            bucket = storage.bucket()
            blur_blob = bucket.blob(group['drawing_link'])
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

    # send_notification()
    save_payload_to_json(global_payload)
    print(global_payload)
    return jsonify({'payload': global_payload})


# # helpers
# def send_notification():
#     # Implement logic to send a notification to all users
#     # ...
#     pass


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

# # Function to execute a function after a delay
# def execute_after_delay(delay, func):
#     threading.Timer(delay, func).start()
        
# Function to save users data to JSON file
def save_payload_to_json(global_payload):
    with open(payload_filename, 'w') as file:
        json.dump({'payload:': global_payload}, file, indent=2)

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
    # execute_after_delay(30, send_notification)  # send notification after 30 seconds that Bereal
