#!/usr/bin/env python3
"""
Simple test script to check profile posts filtering
"""
import requests
import json
import os
import django

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from accounts.models import User
from social.models import Post

BASE_URL = 'http://127.0.0.1:8000'

def login_user(username, password):
    """Login and get authentication token"""
    login_url = f"{BASE_URL}/api/accounts/login/"
    login_data = {
        'username': username,
        'password': password
    }
    
    try:
        response = requests.post(login_url, json=login_data)
        if response.status_code == 200:
            data = response.json()
            return data.get('access')
        else:
            print(f"Login failed: {response.status_code}")
            print(f"Response: {response.text}")
            return None
    except Exception as e:
        print(f"Login error: {e}")
        return None

def test_profile_posts():
    print("Testing Profile Posts API...")
    print("="*50)
    
    # Get a test user from database
    users = User.objects.all()
    if not users:
        print("No users found. Please create a user first.")
        return
    
    test_user = users.first()
    user_id = test_user.id
    print(f"Testing with user: {test_user.username} (ID: {user_id})")
    
    # Check posts in database first
    print(f"\n1. Posts in database for user {user_id}:")
    user_posts_db = Post.objects.filter(author_id=user_id).order_by('-created_at')
    print(f"   Total posts: {user_posts_db.count()}")
    
    for post in user_posts_db:
        print(f"   - Post {post.id}: '{post.content[:30]}...' (Created: {post.created_at})")
    
    # Try to login (this might fail, but let's test the API anyway)
    print(f"\n2. Testing API login...")
    token = login_user(test_user.username, 'admin')  # Try common password
    
    if not token:
        print("Login failed. Trying without authentication...")
        # Test without auth to see if PostViewSet allows it
        headers = {}
    else:
        print("Login successful!")
        headers = {'Authorization': f'Bearer {token}'}
    
    # Test posts API with author filter
    print(f"\n3. Testing posts API with author filter...")
    try:
        response = requests.get(f'{BASE_URL}/api/social/posts/?author={user_id}', headers=headers)
        print(f"   Status: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            posts = data.get('results', [])
            print(f"   API returned {len(posts)} posts")
            
            for post in posts:
                created_at = post.get('created_at', 'Unknown')
                print(f"   - Post {post.get('id')}: '{post.get('content', '')[:30]}...' (Created: {created_at})")
                
            # Compare with database
            if len(posts) != user_posts_db.count():
                print(f"\n   ⚠️  MISMATCH: Database has {user_posts_db.count()} posts, API returned {len(posts)}")
            else:
                print(f"\n   ✅ SUCCESS: API and database counts match!")
                
        else:
            print(f"   Error: {response.text}")
            
    except Exception as e:
        print(f"   Error testing API: {e}")
    
    # Test general posts API (without author filter)
    print(f"\n4. Testing general posts API (no filters)...")
    try:
        response = requests.get(f'{BASE_URL}/api/social/posts/', headers=headers)
        print(f"   Status: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            posts = data.get('results', [])
            print(f"   API returned {len(posts)} posts total")
            
            # Count posts by our test user
            user_posts_in_general = [p for p in posts if p.get('author', {}).get('id') == user_id]
            print(f"   Posts by user {user_id} in general feed: {len(user_posts_in_general)}")
            
        else:
            print(f"   Error: {response.text}")
            
    except Exception as e:
        print(f"   Error testing general API: {e}")

if __name__ == '__main__':
    test_profile_posts()
