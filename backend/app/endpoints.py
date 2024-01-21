import string
from flask import Flask, request, jsonify
import json
import random
from generate import generate

app = Flask(__name__)

# Load existing data from the JSON files
users_filename = 'backend/data/users.json'
groups_filename = 'backend/data/groups.json'

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
        'groups': []
        # remaining fields blank at creation
    }
    save_users_to_json()
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

    # Generate a unique group code
    group_code = generate_unique_group_code()

    # Create the group
    groups[group_code] = {
        'group_code': group_code,
        'group_name': group_name,
        'members': [username],
        'drawing_link': ''  # !!! Create generate_drawing_link function
    }

    # Update user's groups
    user_groups = users.get(username, {}).get('groups', [])
    user_groups.append(group_code)
    users[username]['groups'] = user_groups

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
            # Update group's members
            groups[group_code]['members'].append(username)

            # Update user's groups
            user_groups = users.get(username, {}).get('groups', [])
            user_groups.append(group_code)
            users[username]['groups'] = user_groups

            # Save updated data to JSON files
            save_users_to_json()
            save_groups_to_json()

            return jsonify({'group_code': group_code, 'message': 'Joined group successfully'})
        else:
            return jsonify({'message': 'User is already a member of the group'}), 400
    else:
        return jsonify({'message': 'Group not found'}), 404

@app.route('/api/groups/<group_id>/details', methods=['GET'])
def group_details(group_id):
    # Implement logic to retrieve group details
    # ...

    return jsonify({'group': 'group_details'})

@app.route('/api/groups/<group_id>/update', methods=['PUT'])
def update_group(group_id):
    data = request.get_json()
    # Validate data and update the group
    # ...

    return jsonify({'message': 'Group updated successfully'})

@app.route('/api/groups/<group_id>/delete', methods=['DELETE'])
def delete_group(group_id):
    # Implement logic to delete the group
    # ...

    return jsonify({'message': 'Group deleted successfully'})


@app.route('/api/groups/<group_id>/leave', methods=['DELETE'])
def leave_group(group_id):
    # Implement logic to remove the user from the group
    # ...

    return jsonify({'message': 'User left group successfully'})

# Drawing Endpoints
@app.route('/api/groups/<group_id>/draw', methods=['POST'])
def draw_in_group(group_id):
    data = request.get_json()
    # Validate data and add the drawing to the group
    # ...

    return jsonify({'message': 'Drawing added successfully'})

@app.route('/api/groups/<group_id>/drawings', methods=['GET'])
def get_group_drawings(group_id):
    # Implement logic to retrieve drawings for the group
    # ...

    return jsonify({'drawings': 'list_of_drawings'})

def unleash():
    generated = {}
    global_payload = []

    for group_code, group in groups.items():
        n = len(group.get("members", []))

        if n not in generated:
            texts, boxes, removed_image = generate(n)
            payload = {
                "images": {},
                "original_image": removed_image
            }

            for i, (text, box) in enumerate(zip(texts, boxes)):
                image_key = f"image{i + 1}"
                payload["images"][image_key] = {"coordinates": box, "image_text": text}

            generated[n] = payload
            group_payload = {group_code: payload}
        else:
            group_payload = {group_code: generated[n]}

        global_payload.append(group_payload)

    # Convert the global_payload list to JSON
    json_payload = json.dumps(global_payload, indent=2)
    print(json_payload)
    return

"""
BEREAL POPS -->
generate() returns a list of payload objects:
  "4H8J25": { // GROUP CODE
    "username_1": {
      "coordinates": 
      "image_text":
    },
    "username_2": {
      "coordinates": 
      "image_text":
    }
    ...
  } 

generated = {} 
global_payload = []
for every group in groups:
    n = len(group.members)
    if n not in generated:
        payload = generate(n)
        generated[n] = payload 
        group_payload = group_code + payload // make this as JSON
    else:
        group_payload = group_code + generated[n] // make this as JSON
    global_payload += group_payloud 



global_payload [
  group_code: { // if group size is 4, append in generated[4]
    "images": {
        "image1": {
            "coordinates": 
            "image_text":
        },
        "image2": {
            "coordinates": 
            "image_text":
        } // once frontend user sends this back, attach their username to their image 
        ...
    }
    "original_image": something.png
  } 
  group_code_2: { // if group size is 4, append in generated[4]
    "images": {
        "image1": {
            "coordinates": 
            "image_text":
        },
        "image2": {
            "coordinates": 
            "image_text":
        } // once frontend user sends this back, attach their username to their image 
        ...
    }
    "original_image": something.png
  } 
]


  e.g. we have this group:
  "groups": {
    "WAB6LR": {
      "group_code": "WAB6LR",
      "group_name": "AWESOME",
      "members": [
        "test_user_1"
        "test_user_2"
      ],
      "drawing_link": ""
    }
  }




"""




# helpers
    
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

# Function to save groups data to JSON file
def save_groups_to_json():
    with open(groups_filename, 'w') as file:
        json.dump({'groups': groups}, file, indent=2) 

if __name__ == '__main__':
    app.run(debug=True)

