import string
from flask import Flask, request, jsonify
import json
import random

# Generates group code for unique identifiers
def generate_unique_group_code(groups):
    while True:
        # Generate a random 6-character code
        group_code = ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))

        # Check if the code is unique
        if group_code not in groups:
            return group_code
        
