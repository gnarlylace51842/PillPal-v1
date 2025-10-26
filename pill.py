from flask import Flask, render_template, redirect, session, request, jsonify
from bson.objectid import ObjectId
import time
from pymongo.mongo_client import MongoClient
from werkzeug.security import generate_password_hash, check_password_hash

app = Flask(__name__)

uri = "mongodb+srv://dylanashraf56014:CawPx5TtpKSEQoxG@cluster0.iigar.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0"
client = MongoClient(uri)

db = client.pillApp
users_collection = db.users
medications_collection = db.medications

@app.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    
    if not data or not data.get('email') or not data.get('password') or not data.get('username'):
        return jsonify({'error': 'Email, password, and username are required'}), 400
    
    email = data['email']
    password = data['password']
    username = data['username']
    
    existing_user = users_collection.find_one({'email': email})
    if existing_user:
        return jsonify({'error': 'Email already exists'}), 409
    
    hashed_password = generate_password_hash(password)
    
    new_user = {
        'email': email,
        'password': hashed_password,
        'username': username,
        'created_at': time.time()
    }
    
    try:
        result = users_collection.insert_one(new_user)
        
        return jsonify({
            'message': 'User registered successfully',
            'user_id': str(result.inserted_id),
            'username': username,
            'email': email
        }), 201
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()

    if not data or not data.get('email') or not data.get('password'):
        return jsonify({'error': 'Email and password are required'}), 400
    
    email = data['email']
    password = data['password']
    
    try:
        user = users_collection.find_one({'email': email})
        
        if user and check_password_hash(user['password'], password):
            return jsonify({
                'message': 'Login successful',
                'user_id': str(user['_id']),
                'email': user['email'],
                'username': user['username']
            }), 200
        else:
            return jsonify({'error': 'Invalid email or password'}), 401
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/add_medication', methods=['POST'])
def add_medication():
    """Add medication for a specific user"""
    data = request.get_json()
    
    if not data or not data.get('user_id'):
        return jsonify({'error': 'User ID is required'}), 400
    
    user_id = data.get('user_id')
    
    pills_remaining = data.get('pills_remaining', '0')
    if pills_remaining == '' or pills_remaining is None:
        pills_remaining = 0
    else:
        try:
            pills_remaining = int(pills_remaining)
        except (ValueError, TypeError):
            pills_remaining = 0
    
    medication_data = {
        'user_id': user_id,
        'name': data.get('name'),
        'strength': data.get('strength'),
        'form': data.get('form'),
        'instructions': data.get('instructions'),
        'prescriber': data.get('prescriber'),
        'schedule_type': data.get('schedule_type'),
        'schedule_details': data.get('schedule_details'),
        'start_date': data.get('start_date'),
        'end_date': data.get('end_date'),
        'skip_dates': data.get('skip_dates'),
        'pills_remaining': pills_remaining,
        'created_at': time.time()
    }
    
    try:
        result = medications_collection.insert_one(medication_data)
        
        return jsonify({
            'message': 'Medication added successfully',
            'medication_id': str(result.inserted_id)
        }), 201
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/get_medications/<user_id>', methods=['GET'])
def get_medications(user_id):
    """Get all medications for a specific user"""
    try:
        medications = list(medications_collection.find({'user_id': user_id}))
        
        for med in medications:
            med['_id'] = str(med['_id'])
        
        return jsonify({
            'medications': medications
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/delete_medication/<medication_id>', methods=['DELETE'])
def delete_medication(medication_id):
    """Delete a specific medication"""
    try:
        result = medications_collection.delete_one({'_id': ObjectId(medication_id)})
        
        if result.deleted_count > 0:
            return jsonify({'message': 'Medication deleted successfully'}), 200
        else:
            return jsonify({'error': 'Medication not found'}), 404
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/get_medication_history/<user_id>', methods=['GET'])
def get_medication_history(user_id):
    """Get medication history for a specific user"""
    try:
        history_collection = db.medication_history
        history = list(history_collection.find({'user_id': user_id}))
        
        for record in history:
            record['_id'] = str(record['_id'])
        
        return jsonify({'history': history}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/delete_history_record/<record_id>', methods=['DELETE'])
def delete_history_record(record_id):
    """Delete a specific history record"""
    try:
        history_collection = db.medication_history
        result = history_collection.delete_one({'_id': ObjectId(record_id)})
        
        if result.deleted_count > 0:
            return jsonify({'message': 'History record deleted successfully'}), 200
        else:
            return jsonify({'error': 'Record not found'}), 404
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/get_emergency_info/<user_id>', methods=['GET'])
def get_emergency_info(user_id):
    """Get emergency info for a specific user"""
    try:
        emergency_collection = db.emergency_info
        info = emergency_collection.find_one({'user_id': user_id})
        
        if info:
            info['_id'] = str(info['_id'])
            return jsonify({'emergency_info': info}), 200
        else:
            return jsonify({'emergency_info': None}), 200
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/save_emergency_info', methods=['POST'])
def save_emergency_info():
    """Save or update emergency info for a user"""
    data = request.get_json()
    
    if not data or not data.get('user_id'):
        return jsonify({'error': 'User ID is required'}), 400
    
    user_id = data.get('user_id')
    
    emergency_data = {
        'user_id': user_id,
        'doctor_name': data.get('doctor_name'),
        'contact_info': data.get('contact_info'),
        'location': data.get('location'),
        'updated_at': time.time()
    }
    
    try:
        emergency_collection = db.emergency_info
        existing = emergency_collection.find_one({'user_id': user_id})
        
        if existing:
            emergency_collection.update_one(
                {'user_id': user_id},
                {'$set': emergency_data}
            )
            return jsonify({'message': 'Emergency info updated successfully'}), 200
        else:
            emergency_collection.insert_one(emergency_data)
            return jsonify({'message': 'Emergency info saved successfully'}), 201
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/get_medication/<medication_id>', methods=['GET'])
def get_medication(medication_id):
    """Get a single medication by ID"""
    try:
        medication = medications_collection.find_one({'_id': ObjectId(medication_id)})
        
        if medication:
            medication['_id'] = str(medication['_id'])
            return jsonify({'medication': medication}), 200
        else:
            return jsonify({'error': 'Medication not found'}), 404
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/log_medication', methods=['POST'])
def log_medication():
    """Log that a medication was taken and decrement pill count"""
    data = request.get_json()
    
    if not data or not data.get('medication_id'):
        return jsonify({'error': 'Medication ID is required'}), 400
    
    medication_id = data['medication_id']
    user_id = data.get('user_id')
    
    try:
        medication = medications_collection.find_one({'_id': ObjectId(medication_id)})
        
        if not medication:
            return jsonify({'error': 'Medication not found'}), 404
        
        current_pills = int(medication.get('pills_remaining', 0))
        if current_pills > 0:
            medications_collection.update_one(
                {'_id': ObjectId(medication_id)},
                {'$set': {'pills_remaining': current_pills - 1}}
            )
        
        history_collection = db.medication_history
        history_record = {
            'user_id': user_id,
            'medication_id': medication_id,
            'medication_name': medication['name'],
            'pills_taken': 1,
            'date': time.strftime('%Y-%m-%d %H:%M:%S'),
            'timestamp': time.time()
        }
        history_collection.insert_one(history_record)
        
        return jsonify({
            'message': 'Medication logged successfully',
            'pills_remaining': current_pills - 1
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/mark_medication_taken', methods=['POST'])
def mark_medication_taken():
    """Mark a medication as taken for today and decrement pills"""
    data = request.get_json()
    
    if not data or not data.get('medication_id') or not data.get('user_id'):
        return jsonify({'error': 'Medication ID and User ID are required'}), 400
    
    medication_id = data['medication_id']
    user_id = data['user_id']
    doses_per_day = data.get('doses_per_day', 1)
    
    try:
        medication = medications_collection.find_one({'_id': ObjectId(medication_id)})
        
        if not medication:
            return jsonify({'error': 'Medication not found'}), 404
        
        current_pills = int(medication.get('pills_remaining', 0))
        new_count = max(0, current_pills - doses_per_day)
        
        medications_collection.update_one(
            {'_id': ObjectId(medication_id)},
            {'$set': {'pills_remaining': new_count}}
        )
        
        history_collection = db.medication_history
        history_record = {
            'user_id': user_id,
            'medication_id': medication_id,
            'medication_name': medication['name'],
            'pills_taken': doses_per_day,
            'date': time.strftime('%Y-%m-%d %H:%M:%S'),
            'timestamp': time.time()
        }
        history_collection.insert_one(history_record)
        
        return jsonify({
            'message': 'Medication marked as taken',
            'pills_remaining': new_count
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == "__main__":
    app.run(debug=True)