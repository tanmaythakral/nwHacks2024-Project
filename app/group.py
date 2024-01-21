from flask import Flask, request, jsonify
import json 

app = Flask(__name__)


# Read user data from the JSON file
with open('data/users.json', 'r') as file:
    users_data = json.load(file)

# Initialize the users dictionary with the data from the JSON file
users = {user['user_id']: user for user in users_data['users']}

# In-memory data store (replace with a database in a real application)
groups = {}
drawings = {}

# User Endpoints

@app.route('/api/users', methods=['GET'])
def get_users():
    return jsonify({'users': users})

@app.route('/api/users/<user_id>', methods=['GET'])
def get_user(user_id):
    user = users.get(user_id)
    if user:
        return jsonify(user)
    return jsonify({'error': 'User not found'}), 404

@app.route('/api/users/create', methods=['POST'])
def create_user():
    data = request.json  # Get JSON payload from the request
    username = data.get('username')
    phone = data.get('phone')

    # increment user 
    user_id = len(users) + 1
    users[user_id] = {
        'user_id': user_id, 
        'username': username, 
        'phone': phone,
        # remaining fields blank at creation
    }
    save_users_to_json()
    return jsonify({'user_id': user_id, 'message': 'User registered successfully'})

def save_users_to_json():
    with open('users.json', 'w') as file:
        json.dump({'users': list(users.values())}, file, indent=2)

# Group Endpoints
@app.route('/api/groups/create', methods=['POST'])
def create_group():
    data = request.get_json() # group name, 
    # Validate data and create a new group
    # ...

    return jsonify({'message': 'Group created successfully'})

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

@app.route('/api/groups/<group_id>/join', methods=['POST'])
def join_group(group_id):
    data = request.get_json()
    # Validate data and add the user to the group
    # ...

    return jsonify({'message': 'User joined group successfully'})

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

if __name__ == '__main__':
    app.run(debug=True)
