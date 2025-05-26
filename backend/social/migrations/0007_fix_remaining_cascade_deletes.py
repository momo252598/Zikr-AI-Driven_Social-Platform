# Generated manually to fix remaining cascade delete constraints
from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('social', '0006_fix_cascade_deletes'),
    ]

    operations = [
        # Fix the many-to-many table social_tag_posts CASCADE constraints
        migrations.RunSQL(
            # Drop existing foreign key constraints for the tag-post many-to-many table
            sql=[
                "ALTER TABLE social_tag_posts DROP CONSTRAINT IF EXISTS social_tag_posts_post_id_9ee240ce_fk_social_post_id;",
                "ALTER TABLE social_tag_posts DROP CONSTRAINT IF EXISTS social_tag_posts_tag_id_0875c4ca_fk_social_tag_id;",
            ],
            reverse_sql=[
                # Reverse operations (add constraints back without CASCADE)
                "ALTER TABLE social_tag_posts ADD CONSTRAINT social_tag_posts_post_id_9ee240ce_fk_social_post_id FOREIGN KEY (post_id) REFERENCES social_post (id);",
                "ALTER TABLE social_tag_posts ADD CONSTRAINT social_tag_posts_tag_id_0875c4ca_fk_social_tag_id FOREIGN KEY (tag_id) REFERENCES social_tag (id);",
            ]
        ),
        migrations.RunSQL(
            # Add foreign key constraints with CASCADE DELETE for the many-to-many table
            sql=[
                "ALTER TABLE social_tag_posts ADD CONSTRAINT social_tag_posts_post_id_9ee240ce_fk_social_post_id FOREIGN KEY (post_id) REFERENCES social_post (id) ON DELETE CASCADE;",
                "ALTER TABLE social_tag_posts ADD CONSTRAINT social_tag_posts_tag_id_0875c4ca_fk_social_tag_id FOREIGN KEY (tag_id) REFERENCES social_tag (id) ON DELETE CASCADE;",
            ],
            reverse_sql=[
                # Reverse operations
                "ALTER TABLE social_tag_posts DROP CONSTRAINT IF EXISTS social_tag_posts_post_id_9ee240ce_fk_social_post_id;",
                "ALTER TABLE social_tag_posts DROP CONSTRAINT IF EXISTS social_tag_posts_tag_id_0875c4ca_fk_social_tag_id;",
            ]
        ),
        # Fix any remaining user foreign key constraints that might need CASCADE
        migrations.RunSQL(
            # Drop and recreate user foreign key constraints with CASCADE
            sql=[
                "ALTER TABLE social_like DROP CONSTRAINT IF EXISTS social_like_user_id_d83dbbf8_fk_accounts_user_id;",
                "ALTER TABLE social_comment DROP CONSTRAINT IF EXISTS social_comment_author_id_b8fc6825_fk_accounts_user_id;",
                "ALTER TABLE social_post DROP CONSTRAINT IF EXISTS social_post_author_id_e4bf7f89_fk_accounts_user_id;",
                "ALTER TABLE social_savedpost DROP CONSTRAINT IF EXISTS social_savedpost_user_id_8c3bbb02_fk_accounts_user_id;",
            ],
            reverse_sql=[
                # Reverse operations 
                "ALTER TABLE social_like ADD CONSTRAINT social_like_user_id_d83dbbf8_fk_accounts_user_id FOREIGN KEY (user_id) REFERENCES accounts_user (id);",
                "ALTER TABLE social_comment ADD CONSTRAINT social_comment_author_id_b8fc6825_fk_accounts_user_id FOREIGN KEY (author_id) REFERENCES accounts_user (id);",
                "ALTER TABLE social_post ADD CONSTRAINT social_post_author_id_e4bf7f89_fk_accounts_user_id FOREIGN KEY (author_id) REFERENCES accounts_user (id);",
                "ALTER TABLE social_savedpost ADD CONSTRAINT social_savedpost_user_id_8c3bbb02_fk_accounts_user_id FOREIGN KEY (user_id) REFERENCES accounts_user (id);",
            ]
        ),
        migrations.RunSQL(
            # Add user foreign key constraints with CASCADE DELETE
            sql=[
                "ALTER TABLE social_like ADD CONSTRAINT social_like_user_id_d83dbbf8_fk_accounts_user_id FOREIGN KEY (user_id) REFERENCES accounts_user (id) ON DELETE CASCADE;",
                "ALTER TABLE social_comment ADD CONSTRAINT social_comment_author_id_b8fc6825_fk_accounts_user_id FOREIGN KEY (author_id) REFERENCES accounts_user (id) ON DELETE CASCADE;",
                "ALTER TABLE social_post ADD CONSTRAINT social_post_author_id_e4bf7f89_fk_accounts_user_id FOREIGN KEY (author_id) REFERENCES accounts_user (id) ON DELETE CASCADE;",
                "ALTER TABLE social_savedpost ADD CONSTRAINT social_savedpost_user_id_8c3bbb02_fk_accounts_user_id FOREIGN KEY (user_id) REFERENCES accounts_user (id) ON DELETE CASCADE;",
            ],
            reverse_sql=[
                # Reverse operations
                "ALTER TABLE social_like DROP CONSTRAINT IF EXISTS social_like_user_id_d83dbbf8_fk_accounts_user_id;",
                "ALTER TABLE social_comment DROP CONSTRAINT IF EXISTS social_comment_author_id_b8fc6825_fk_accounts_user_id;",
                "ALTER TABLE social_post DROP CONSTRAINT IF EXISTS social_post_author_id_e4bf7f89_fk_accounts_user_id;",
                "ALTER TABLE social_savedpost DROP CONSTRAINT IF EXISTS social_savedpost_user_id_8c3bbb02_fk_accounts_user_id;",
            ]
        ),
    ]
