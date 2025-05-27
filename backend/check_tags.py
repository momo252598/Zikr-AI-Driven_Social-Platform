#!/usr/bin/env python
import os
import sys
import django

# Add the project directory to Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from social.models import Tag

def check_tags():
    tags = Tag.objects.all()
    print(f'Total tags: {tags.count()}')
    print('By category:')
    
    for cat_code, cat_name in Tag.CATEGORY_CHOICES:
        count = tags.filter(category=cat_code).count()
        print(f'  {cat_code} ({cat_name}): {count} tags')
        
        # Show first few tags in each category
        category_tags = tags.filter(category=cat_code)[:5]
        for tag in category_tags:
            print(f'    - {tag.name} (id: {tag.id})')
        if tags.filter(category=cat_code).count() > 5:
            print(f'    ... and {tags.filter(category=cat_code).count() - 5} more')
        print()

if __name__ == '__main__':
    check_tags()
