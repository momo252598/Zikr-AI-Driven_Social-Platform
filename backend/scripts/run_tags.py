"""
Simple script to run the create_tags.py logic directly
"""

import os
import sys
import django

# Setup Django environment
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

# Import the create_tags function from create_tags.py
from social.models import Tag

# Define tags by category
TAGS = {
    'religious': [
        {'name': 'quran_studies', 'display_name_ar': 'دراسات قرآنية', 'description': 'Discussions about Quranic verses, tafsir (interpretations), and reflections'},
        {'name': 'hadith_collections', 'display_name_ar': 'مجموعات الحديث', 'description': 'Sharing and discussing authentic hadith'},
        {'name': 'fiqh', 'display_name_ar': 'فقه', 'description': 'Questions and discussions about Islamic law and rulings'},
        {'name': 'aqeedah', 'display_name_ar': 'عقيدة', 'description': 'Posts about core beliefs and theological discussions'},
        {'name': 'seerah', 'display_name_ar': 'سيرة', 'description': "Stories and lessons from the Prophet Muhammad's (PBUH) life"},
    ],
    'practice': [
        {'name': 'salah', 'display_name_ar': 'صلاة', 'description': 'Tips, reminders, and discussions about prayer'},
        {'name': 'ramadan', 'display_name_ar': 'رمضان', 'description': 'Content specific to Ramadan and fasting practices'},
        {'name': 'zakat_charity', 'display_name_ar': 'زكاة وصدقة', 'description': 'Discussions about giving, charity work, and community service'},
        {'name': 'dhikr_dua', 'display_name_ar': 'ذكر ودعاء', 'description': 'Sharing of supplications and remembrance of Allah'},
        {'name': 'islamic_ethics', 'display_name_ar': 'أخلاق إسلامية', 'description': 'Posts about developing good character according to Islamic teachings'},
    ],
    'lifestyle': [
        {'name': 'islamic_events', 'display_name_ar': 'مناسبات إسلامية', 'description': 'Content about Eid, Hajj, and other important dates'},
        {'name': 'muslim_family', 'display_name_ar': 'الأسرة المسلمة', 'description': 'Discussions about parenting, marriage, and family dynamics in Islam'},
        {'name': 'halal_living', 'display_name_ar': 'حياة حلال', 'description': 'Topics around halal food, modest fashion, and lifestyle choices'},
        {'name': 'health_wellness', 'display_name_ar': 'صحة وعافية', 'description': 'Physical and mental health discussions from an Islamic perspective'},
        {'name': 'new_muslims', 'display_name_ar': 'المسلمون الجدد', 'description': 'Resources and support for new converts to Islam'},
    ],
    'contemporary': [
        {'name': 'islam_technology', 'display_name_ar': 'الإسلام والتكنولوجيا', 'description': 'Discussions about Islamic apps, online resources, and tech ethics'},
        {'name': 'current_events', 'display_name_ar': 'أحداث جارية', 'description': 'Islamic perspectives on world events'},
        {'name': 'islamic_art', 'display_name_ar': 'الفن الإسلامي', 'description': 'Sharing of Islamic calligraphy, architecture, and cultural expressions'},
        {'name': 'interfaith', 'display_name_ar': 'حوار الأديان', 'description': 'Respectful discussions with other faith traditions'},
        {'name': 'islamic_finance', 'display_name_ar': 'التمويل الإسلامي', 'description': 'Discussions about halal investments, avoiding riba (interest), etc.'},
    ],
    'community': [
        {'name': 'question_answer', 'display_name_ar': 'سؤال وجواب', 'description': 'Where users can ask specific questions to the community'},
        {'name': 'announcements', 'display_name_ar': 'إعلانات', 'description': 'Local events, mosque activities, etc.'},
        {'name': 'education', 'display_name_ar': 'التعليم الإسلامي', 'description': 'Resources for learning more about Islam'},
        {'name': 'inspirational', 'display_name_ar': 'قصص ملهمة', 'description': 'Personal testimonies and inspirational content'},
        {'name': 'resources', 'display_name_ar': 'موارد وكتب', 'description': 'Sharing beneficial Islamic literature and resources'},
    ],
    'suggestions': [
        {'name': 'suggested', 'display_name_ar': 'المقترحات', 'description': 'Suggestions for new tags or topics to discuss based on user behavior'},
    ],
}

def create_tags():
    """Create tags from the predefined categories"""
    tags_created = 0
    tags_updated = 0
    
    for category, tags in TAGS.items():
        for tag in tags:
            obj, created = Tag.objects.update_or_create(
                name=tag['name'],
                defaults={
                    'display_name_ar': tag['display_name_ar'],
                    'category': category,
                    'description': tag['description']
                }
            )
            if created:
                tags_created += 1
            else:
                tags_updated += 1
    
    print(f"Created {tags_created} new tags")
    print(f"Updated {tags_updated} existing tags")
    
    total_tags = Tag.objects.count()
    print(f"Total tags in the database: {total_tags}")

if __name__ == "__main__":
    print("Creating tags...")
    create_tags()
    print("Done!")
