#!/usr/bin/env python3
"""
Test script to check if profile posts are working correctly for author filtering
"""
import requests
import json
import os
import django
from django.conf import settings

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from accounts.models import User
from social.models import Post

BASE_URL = 'http://127.0.0.1:8000'

def get_auth_token():
    """Get authentication token for testing"""
    # Try to get an existing user for testing
    users = User.objects.all()
    if not users:
        print("No users found in database. Please create a user first.")
        return None
    
    test_user = users.first()
    print(f"Testing with user: {test_user.username} (ID: {test_user.id})")
    
    # For testing, we'll need to login or use an existing token
    # You might need to adjust this based on your authentication setup
    login_data = {
        'username': test_user.username,
        'password': 'testpassword123'  # You'll need to set this or use actual password
    }
      try:
        response = requests.post(f'{BASE_URL}/api/accounts/login/', json=login_data)
        if response.status_code == 200:
            return response.json().get('access'), test_user.id
        else:
            print(f"Login failed: {response.status_code} - {response.text}")
            return None, test_user.id
    except Exception as e:
        print(f"Login error: {e}")
        return None, test_user.id

def test_posts_api(token, user_id):
    """Test the posts API with different filters"""
    headers = {}
    if token:
        headers['Authorization'] = f'Bearer {token}'
    
    print("\n" + "="*50)
    print("TESTING POSTS API")
    print("="*50)
    
    # Test 1: Get all posts
    print("\n1. Testing all posts (no filters):")
    try:
        response = requests.get(f'{BASE_URL}/api/social/posts/', headers=headers)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            total_posts = data.get('count', len(data.get('results', [])))
            print(f"Total posts in system: {total_posts}")
            
            posts = data.get('results', [])
            print(f"Posts returned in this page: {len(posts)}")
            
            if posts:
                print("Sample posts:")
                for i, post in enumerate(posts[:3]):
                    author_info = post.get('author', {})
                    author_name = author_info.get('username', 'Unknown') if isinstance(author_info, dict) else str(author_info)
                    print(f"  - Post {post.get('id')}: '{post.get('content', '')[:50]}...' by {author_name}")
        else:
            print(f"Error: {response.text}")
    except Exception as e:
        print(f"Error testing all posts: {e}")
    
    # Test 2: Get posts by specific author
    print(f"\n2. Testing posts filtered by author (user ID: {user_id}):")
    try:
        response = requests.get(f'{BASE_URL}/api/social/posts/?author={user_id}', headers=headers)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            user_posts = data.get('results', [])
            print(f"Posts by user {user_id}: {len(user_posts)}")
            
            if user_posts:
                print("User's posts:")
                for post in user_posts:
                    created_at = post.get('created_at', 'Unknown')
                    print(f"  - Post {post.get('id')}: '{post.get('content', '')[:50]}...' (Created: {created_at})")
            else:
                print("No posts found for this user")
        else:
            print(f"Error: {response.text}")
    except Exception as e:
        print(f"Error testing author filter: {e}")
    
    # Test 3: Check posts directly from database
    print(f"\n3. Checking posts directly from database for user {user_id}:")
    try:
        user_posts_db = Post.objects.filter(author_id=user_id).order_by('-created_at')
        print(f"Posts in database for user {user_id}: {user_posts_db.count()}")
        
        if user_posts_db:
            print("Database posts:")
            for post in user_posts_db:
                print(f"  - Post {post.id}: '{post.content[:50]}...' (Created: {post.created_at})")
    except Exception as e:
        print(f"Error checking database: {e}")

def create_test_post(token, user_id):
    """Create a test post to verify new posts appear"""
    if not token:
        print("Cannot create test post without authentication token")
        return None
    
    headers = {'Authorization': f'Bearer {token}'}
    post_data = {
        'content': f'Test post created for profile testing at {django.utils.timezone.now()}',
        'visibility': 'public'
    }
    
    try:
        response = requests.post(f'{BASE_URL}/api/social/posts/', json=post_data, headers=headers)
        if response.status_code == 201:
            new_post = response.json()
            print(f"\nCreated new test post: ID {new_post.get('id')}")
            return new_post.get('id')
        else:
            print(f"Failed to create test post: {response.status_code} - {response.text}")
            return None
    except Exception as e:
        print(f"Error creating test post: {e}")
        return None

def main():
    print("Testing Profile Posts API...")
    
    # Get authentication token and user ID
    token, user_id = get_auth_token()
    
    if not user_id:
        print("Cannot proceed without user ID")
        return
    
    # Test current state
    test_posts_api(token, user_id)
    
    # Create a new test post
    new_post_id = create_test_post(token, user_id)
    
    if new_post_id:
        print(f"\n{'='*50}")
        print("TESTING AFTER CREATING NEW POST")
        print("="*50)
        
        # Test again to see if new post appears
        test_posts_api(token, user_id)

if __name__ == '__main__':
    main()
