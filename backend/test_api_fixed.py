#!/usr/bin/env python
import requests
import json

# Test the tags API endpoint
base_url = "http://localhost:8000"  # Adjust if your server runs on a different port

def test_tags_api():
    print("Testing Tags API...")
    
    # Test all tags
    try:
        response = requests.get(f"{base_url}/api/social/tags/", timeout=10)
        print(f"All tags - Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print(f"Total tags returned: {len(data)}")
            if isinstance(data, list) and data:
                print("Sample tags:")
                for tag in data[:5]:  # Show first 5 tags
                    print(f"  - {tag.get('name', 'N/A')} (id: {tag.get('id', 'N/A')}, category: {tag.get('category', 'N/A')})")
            else:
                print(f"Unexpected data format: {data}")
        elif response.status_code == 401:
            print("Authentication required - API needs JWT token")
            return
        else:
            print(f"Error response: {response.text}")
    except requests.exceptions.Timeout:
        print("Request timed out - server might not be responding")
        return
    except Exception as e:
        print(f"Error fetching all tags: {e}")
        return
    
    print("\n" + "="*50 + "\n")
    
    # Test each category
    categories = [
        'religious',
        'practice', 
        'lifestyle',
        'contemporary',
        'community',
        'other'
    ]
    
    for category in categories:
        try:
            response = requests.get(f"{base_url}/api/social/tags/?category={category}")
            print(f"Category '{category}' - Status: {response.status_code}")
            if response.status_code == 200:
                data = response.json()
                print(f"  Tags returned: {len(data)}")
                if isinstance(data, list) and data:
                    for tag in data[:3]:  # Show first 3 tags
                        print(f"    - {tag.get('name', 'N/A')} (id: {tag.get('id', 'N/A')})")
                    if len(data) > 3:
                        print(f"    ... and {len(data) - 3} more")
                else:
                    print(f"  No tags or unexpected data format: {data}")
            else:
                print(f"  Error response: {response.text}")
        except Exception as e:
            print(f"  Error fetching category '{category}': {e}")
        print()

if __name__ == '__main__':
    test_tags_api()
