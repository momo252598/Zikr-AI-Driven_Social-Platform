# Generated manually to fix cascade delete constraints
from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('social', '0005_alter_tag_category'),
    ]

    operations = [
        # Drop and recreate foreign key constraints with proper CASCADE behavior
        migrations.RunSQL(
            # Drop existing foreign key constraints (PostgreSQL syntax)
            sql=[
                "ALTER TABLE social_like DROP CONSTRAINT IF EXISTS social_like_post_id_6d804a40_fk_social_post_id;",
                "ALTER TABLE social_like DROP CONSTRAINT IF EXISTS social_like_comment_id_8bc24a37_fk_social_comment_id;",
                "ALTER TABLE social_comment DROP CONSTRAINT IF EXISTS social_comment_post_id_e8a96d1f_fk_social_post_id;",
                "ALTER TABLE social_comment DROP CONSTRAINT IF EXISTS social_comment_parent_id_5e88bb0b_fk_social_comment_id;",
                "ALTER TABLE social_mediapost DROP CONSTRAINT IF EXISTS social_mediapost_post_id_68cdc30b_fk_social_post_id;",
                "ALTER TABLE social_savedpost DROP CONSTRAINT IF EXISTS social_savedpost_post_id_f1b4cadf_fk_social_post_id;",
            ],
            reverse_sql=[
                # Reverse operations (add constraints back without CASCADE)
                "ALTER TABLE social_like ADD CONSTRAINT social_like_post_id_6d804a40_fk_social_post_id FOREIGN KEY (post_id) REFERENCES social_post (id);",
                "ALTER TABLE social_like ADD CONSTRAINT social_like_comment_id_8bc24a37_fk_social_comment_id FOREIGN KEY (comment_id) REFERENCES social_comment (id);",
                "ALTER TABLE social_comment ADD CONSTRAINT social_comment_post_id_e8a96d1f_fk_social_post_id FOREIGN KEY (post_id) REFERENCES social_post (id);",
                "ALTER TABLE social_comment ADD CONSTRAINT social_comment_parent_id_5e88bb0b_fk_social_comment_id FOREIGN KEY (parent_id) REFERENCES social_comment (id);",
                "ALTER TABLE social_mediapost ADD CONSTRAINT social_mediapost_post_id_68cdc30b_fk_social_post_id FOREIGN KEY (post_id) REFERENCES social_post (id);",
                "ALTER TABLE social_savedpost ADD CONSTRAINT social_savedpost_post_id_f1b4cadf_fk_social_post_id FOREIGN KEY (post_id) REFERENCES social_post (id);",
            ]
        ),
        migrations.RunSQL(
            # Add foreign key constraints with CASCADE DELETE (PostgreSQL syntax)
            sql=[
                "ALTER TABLE social_like ADD CONSTRAINT social_like_post_id_6d804a40_fk_social_post_id FOREIGN KEY (post_id) REFERENCES social_post (id) ON DELETE CASCADE;",
                "ALTER TABLE social_like ADD CONSTRAINT social_like_comment_id_8bc24a37_fk_social_comment_id FOREIGN KEY (comment_id) REFERENCES social_comment (id) ON DELETE CASCADE;",
                "ALTER TABLE social_comment ADD CONSTRAINT social_comment_post_id_e8a96d1f_fk_social_post_id FOREIGN KEY (post_id) REFERENCES social_post (id) ON DELETE CASCADE;",
                "ALTER TABLE social_comment ADD CONSTRAINT social_comment_parent_id_5e88bb0b_fk_social_comment_id FOREIGN KEY (parent_id) REFERENCES social_comment (id) ON DELETE CASCADE;",
                "ALTER TABLE social_mediapost ADD CONSTRAINT social_mediapost_post_id_68cdc30b_fk_social_post_id FOREIGN KEY (post_id) REFERENCES social_post (id) ON DELETE CASCADE;",
                "ALTER TABLE social_savedpost ADD CONSTRAINT social_savedpost_post_id_f1b4cadf_fk_social_post_id FOREIGN KEY (post_id) REFERENCES social_post (id) ON DELETE CASCADE;",
            ],
            reverse_sql=[
                # Reverse operations (PostgreSQL syntax)
                "ALTER TABLE social_like DROP CONSTRAINT IF EXISTS social_like_post_id_6d804a40_fk_social_post_id;",
                "ALTER TABLE social_like DROP CONSTRAINT IF EXISTS social_like_comment_id_8bc24a37_fk_social_comment_id;",
                "ALTER TABLE social_comment DROP CONSTRAINT IF EXISTS social_comment_post_id_e8a96d1f_fk_social_post_id;",
                "ALTER TABLE social_comment DROP CONSTRAINT IF EXISTS social_comment_parent_id_5e88bb0b_fk_social_comment_id;",
                "ALTER TABLE social_mediapost DROP CONSTRAINT IF EXISTS social_mediapost_post_id_68cdc30b_fk_social_post_id;",
                "ALTER TABLE social_savedpost DROP CONSTRAINT IF EXISTS social_savedpost_post_id_f1b4cadf_fk_social_post_id;",
            ]
        ),
    ]
