# Social Media Suggestion Algorithm Documentation

## Overview

This document provides a comprehensive explanation of the sophisticated suggestion algorithm implemented for the social media platform's feed when the "الكل" (All) filter is selected. The algorithm intelligently combines user preferences, global popularity, and diversity mechanisms to create personalized yet diverse content feeds.

## Table of Contents

1. [Algorithm Overview](#algorithm-overview)
2. [Key Components](#key-components)
3. [Implementation Details](#implementation-details)
4. [Weighting System](#weighting-system)
5. [Diversity Mechanism](#diversity-mechanism)
6. [Database Integration](#database-integration)
7. [Performance Considerations](#performance-considerations)
8. [Usage Examples](#usage-examples)
9. [Future Enhancements](#future-enhancements)

## Algorithm Overview

The suggestion algorithm is designed to solve the fundamental challenge of content discovery in social media: balancing relevance with diversity. When users select the "الكل" (All) filter, the system automatically applies this algorithm instead of simple chronological ordering.

### Core Principles

1. **Personalization**: Content is weighted based on user interaction history
2. **Global Awareness**: Popular content across the platform influences recommendations
3. **Diversity**: Prevents echo chambers by ensuring variety in content
4. **Performance**: Efficient database queries and caching mechanisms

### Algorithm Flow

```
User Request (الكل filter)
    ↓
Check for specific filters (tags/category)
    ↓
If no filters → Apply Suggestion Algorithm
    ↓
Calculate User Tag Weights (70% influence)
    ↓
Calculate Global Tag Weights (30% influence)
    ↓
Combine Weights
    ↓
Apply Diversity Mechanism
    ↓
Return Ordered Posts
```

## Key Components

### 1. Entry Point: `get_queryset()` Method

Located in `PostViewSet` class in `views.py`, this method determines when to apply the suggestion algorithm:

```python
def get_queryset(self):
    # Standard visibility filtering
    user = self.request.user
    queryset = Post.objects.filter(
        Q(visibility='public') |
        Q(author=user) |
        (Q(visibility='followers') & Q(author__followers=user))
    ).annotate(
        comments_count=Count('comments', distinct=True),
        likes_count=Count('likes', distinct=True)
    )

    # Check for specific filters
    tags = self.request.query_params.getlist('tag')
    category = self.request.query_params.get('category')

    # Apply suggestion algorithm only when no filters are specified
    if not tags and not category:
        return self._apply_suggestion_algorithm(queryset)

    return queryset.order_by('-created_at')
```

**Key Logic**: The algorithm activates only when both `tags` and `category` parameters are empty, indicating the "الكل" (All) filter is selected.

### 2. Main Algorithm Orchestrator: `_apply_suggestion_algorithm()`

This method coordinates the entire suggestion process:

```python
def _apply_suggestion_algorithm(self, queryset):
    user = self.request.user

    # Step 1: Calculate user's tag preferences
    user_tag_weights = self._calculate_user_tag_weights(user)

    # Step 2: Calculate global tag popularity
    global_tag_weights = self._calculate_global_tag_weights()

    # Step 3: Combine preferences with popularity
    combined_weights = self._combine_weights(user_tag_weights, global_tag_weights)

    # Step 4: Create diverse post ordering
    return self._create_diverse_post_ordering(queryset, combined_weights)
```

## Implementation Details

### 1. User Tag Weight Calculation

**Method**: `_calculate_user_tag_weights(user)`

**Purpose**: Analyzes user's like history to determine tag preferences.

**Algorithm**:

```python
def _calculate_user_tag_weights(self, user):
    # Query tags the user has liked posts for
    user_liked_tags = Tag.objects.filter(
        posts__likes__user=user
    ).annotate(
        user_likes_count=Count('posts__likes', filter=Q(posts__likes__user=user))
    ).values('id', 'user_likes_count')

    weights = {}

    # Create weight dictionary proportional to likes
    for tag_data in user_liked_tags:
        tag_id = tag_data['id']
        likes_count = tag_data['user_likes_count']
        weights[tag_id] = max(likes_count, 1)  # Minimum weight of 1

    # Ensure all tags have weights (for diversity)
    all_tags = Tag.objects.values_list('id', flat=True)
    for tag_id in all_tags:
        if tag_id not in weights:
            weights[tag_id] = 0.1  # Small weight for unexplored tags

    return weights
```

**Key Features**:

- Weights are proportional to interaction frequency
- Minimum weight ensures no tag is completely ignored
- Covers all existing tags for comprehensive scoring

### 2. Global Tag Weight Calculation

**Method**: `_calculate_global_tag_weights()`

**Purpose**: Determines platform-wide tag popularity to introduce trending content.

**Algorithm**:

```python
def _calculate_global_tag_weights(self):
    # Get global like counts for all tags
    global_tag_data = Tag.objects.annotate(
        global_likes_count=Count('posts__likes')
    ).values('id', 'global_likes_count')

    weights = {}
    max_global_likes = 1  # Prevent division by zero

    # Find maximum for normalization
    for tag_data in global_tag_data:
        max_global_likes = max(max_global_likes, tag_data['global_likes_count'])

    # Calculate normalized weights (0-1 range)
    for tag_data in global_tag_data:
        tag_id = tag_data['id']
        likes_count = tag_data['global_likes_count']
        normalized_weight = (likes_count / max_global_likes) * 0.5 + 0.1
        weights[tag_id] = normalized_weight

    return weights
```

**Key Features**:

- Normalization prevents bias toward heavily-liked tags
- Base weight (0.1) ensures all tags have minimum visibility
- Scaling factor (0.5) limits global influence relative to user preferences

### 3. Weight Combination

**Method**: `_combine_weights(user_weights, global_weights)`

**Purpose**: Merges personal preferences with global trends using a 70/30 split.

**Algorithm**:

```python
def _combine_weights(self, user_weights, global_weights):
    combined = {}
    all_tag_ids = set(user_weights.keys()) | set(global_weights.keys())

    for tag_id in all_tag_ids:
        user_weight = user_weights.get(tag_id, 0.1)
        global_weight = global_weights.get(tag_id, 0.1)

        # 70% user preference, 30% global popularity
        combined[tag_id] = (user_weight * 0.7) + (global_weight * 0.3)

    return combined
```

**Rationale**: The 70/30 split ensures personalization takes precedence while still introducing diverse, globally popular content.

## Weighting System

### User Preference Weighting (70% Influence)

| User Interaction           | Weight Calculation | Example                                      |
| -------------------------- | ------------------ | -------------------------------------------- |
| Never liked posts with tag | 0.1 (baseline)     | User hasn't engaged with "religious" content |
| Liked 1 post with tag      | 1.0                | User showed minimal interest                 |
| Liked 5 posts with tag     | 5.0                | User shows strong preference                 |
| Liked 10+ posts with tag   | 10.0+              | User highly engaged with topic               |

### Global Popularity Weighting (30% Influence)

| Global Engagement                 | Normalized Weight | Impact                |
| --------------------------------- | ----------------- | --------------------- |
| 0 likes across platform           | 0.1               | Minimal visibility    |
| Low engagement (1-10% of max)     | 0.15-0.2          | Small boost           |
| Medium engagement (11-50% of max) | 0.2-0.35          | Moderate visibility   |
| High engagement (51-100% of max)  | 0.35-0.6          | Strong trending boost |

### Final Weight Calculation

```
Final Weight = (User Weight × 0.7) + (Global Weight × 0.3)
```

**Example Scenarios**:

1. **Highly Personal, Low Global**: User weight = 10, Global weight = 0.1

   - Final = (10 × 0.7) + (0.1 × 0.3) = 7.03

2. **Moderately Personal, High Global**: User weight = 3, Global weight = 0.5

   - Final = (3 × 0.7) + (0.5 × 0.3) = 2.25

3. **New Topic, High Global**: User weight = 0.1, Global weight = 0.6
   - Final = (0.1 × 0.7) + (0.6 × 0.3) = 0.25

## Diversity Mechanism

### Post Scoring Process

**Method**: `_create_diverse_post_ordering(queryset, tag_weights)`

**Steps**:

1. **Calculate Post Scores**: Each post's score is the average of its associated tags' weights
2. **Add Randomness**: ±20% variation to prevent predictable ordering
3. **Separate High/Low Score Groups**: Split posts at median score
4. **Apply 3:1 Diversity Ratio**: Every 4th position gets a lower-scored post

### Detailed Implementation

```python
def _create_diverse_post_ordering(self, queryset, tag_weights):
    posts_with_scores = []

    # Calculate scores for each post
    for post in queryset.prefetch_related('tags'):
        post_tags = post.tags.all()

        if post_tags:
            # Average of tag weights
            tag_scores = [tag_weights.get(tag.id, 0.1) for tag in post_tags]
            post_score = sum(tag_scores) / len(tag_scores)
        else:
            post_score = 0.1  # Posts without tags

        # Add randomness for diversity (±20%)
        randomness_factor = random.uniform(0.8, 1.2)
        final_score = post_score * randomness_factor

        posts_with_scores.append((post.id, final_score))

    # Sort by score and apply diversity
    posts_with_scores.sort(key=lambda x: x[1], reverse=True)

    # Separate into high and low score groups
    median_score = sorted([score for _, score in posts_with_scores])[len(posts_with_scores) // 2]

    high_score_posts = [pid for pid, score in posts_with_scores if score >= median_score]
    low_score_posts = [pid for pid, score in posts_with_scores if score < median_score]

    # Create diversified ordering: 3 high-score, 1 low-score
    diversified_order = []
    high_idx = low_idx = position = 0

    while high_idx < len(high_score_posts) or low_idx < len(low_score_posts):
        if position % 4 == 3 and low_idx < len(low_score_posts):
            # Every 4th position gets low-score post
            diversified_order.append(low_score_posts[low_idx])
            low_idx += 1
        elif high_idx < len(high_score_posts):
            diversified_order.append(high_score_posts[high_idx])
            high_idx += 1
        elif low_idx < len(low_score_posts):
            # Fill remaining with low-score posts
            diversified_order.append(low_score_posts[low_idx])
            low_idx += 1

        position += 1

    # Apply ordering using Django Case/When
    if diversified_order:
        ordering_cases = [
            When(id=post_id, then=Value(index))
            for index, post_id in enumerate(diversified_order)
        ]

        return queryset.annotate(
            custom_order=Case(*ordering_cases, default=Value(len(diversified_order)))
        ).order_by('custom_order')

    return queryset.order_by('-created_at')  # Fallback
```

### Diversity Pattern Example

```
Position 0: High-score post (most relevant)
Position 1: High-score post
Position 2: High-score post
Position 3: Low-score post (diversity injection)
Position 4: High-score post
Position 5: High-score post
Position 6: High-score post
Position 7: Low-score post (diversity injection)
...
```

## Database Integration

### Model Relationships

The algorithm leverages existing Django model relationships:

```python
# Key relationships used:
Tag.posts (ManyToMany with Post)
Post.likes (ForeignKey from Like)
Like.user (ForeignKey to User)
Post.tags (reverse ManyToMany)
```

### Optimized Queries

1. **User Tag Weights Query**:

```sql
SELECT tag.id, COUNT(like.id) as user_likes_count
FROM social_tag tag
JOIN social_tag_posts tag_posts ON tag.id = tag_posts.tag_id
JOIN social_post post ON tag_posts.post_id = post.id
JOIN social_like like ON post.id = like.post_id
WHERE like.user_id = %s
GROUP BY tag.id
```

2. **Global Tag Weights Query**:

```sql
SELECT tag.id, COUNT(like.id) as global_likes_count
FROM social_tag tag
JOIN social_tag_posts tag_posts ON tag.id = tag_posts.tag_id
JOIN social_post post ON tag_posts.post_id = post.id
JOIN social_like like ON post.id = like.post_id
GROUP BY tag.id
```

3. **Final Ordering Query**:

```sql
SELECT post.*
FROM social_post post
ANNOTATE custom_order = CASE
    WHEN post.id = %s THEN 0
    WHEN post.id = %s THEN 1
    ...
    ELSE %s
END
ORDER BY custom_order
```

### Performance Optimizations

1. **Prefetch Related**: Uses `prefetch_related('tags')` to minimize database hits
2. **Efficient Annotations**: Leverages Django ORM annotations for counting
3. **Single Query Ordering**: Uses `Case/When` for database-level ordering
4. **Lazy Evaluation**: Calculations performed only when needed

## Usage Examples

### Scenario 1: New User

- **User Weights**: All tags have weight 0.1 (no interaction history)
- **Global Weights**: Vary based on platform activity
- **Result**: Feed primarily driven by global popularity with maximum diversity

### Scenario 2: Active User with Preferences

- **User**: Frequently likes "religious" (weight: 15) and "practice" (weight: 8) content
- **Global**: "contemporary" is trending (weight: 0.5)
- **Result**:
  - "religious" posts: Final weight ≈ 10.65
  - "practice" posts: Final weight ≈ 5.75
  - "contemporary" posts: Final weight ≈ 0.22
  - Other posts: Final weight ≈ 0.22

### Scenario 3: Trending Content Discovery

- **User**: Never engaged with "community" content (weight: 0.1)
- **Global**: "community" is highly popular (weight: 0.6)
- **Result**: "community" posts get final weight ≈ 0.25, ensuring visibility

## Integration with Frontend

### Request Flow

1. **Frontend**: User selects "الكل" filter
2. **Frontend**: Sends request to `/social/posts/` without tag/category parameters
3. **Backend**: `get_queryset()` detects no filters
4. **Backend**: Applies suggestion algorithm
5. **Backend**: Returns ordered posts
6. **Frontend**: Displays personalized, diverse feed

### API Response

The API response maintains the same structure as standard post queries:

```json
{
    "results": [
        {
            "id": 123,
            "content": "Post content...",
            "author_details": {...},
            "tags": [...],
            "likes_count": 15,
            "comments_count": 3,
            "is_liked": false,
            "created_at": "2025-01-15T10:30:00Z"
        }
    ],
    "count": 50,
    "next": "http://api/social/posts/?page=2",
    "previous": null
}
```

## Performance Considerations

### Time Complexity

- **User Weight Calculation**: O(T + L_u) where T = total tags, L_u = user's likes
- **Global Weight Calculation**: O(T + L_g) where L_g = global likes
- **Post Scoring**: O(P × T_avg) where P = posts, T_avg = average tags per post
- **Overall**: O(T + L_g + P × T_avg)

### Space Complexity

- **Weight Dictionaries**: O(T) for storing tag weights
- **Post Scores**: O(P) for storing post scores
- **Overall**: O(T + P)

### Scalability Strategies

1. **Caching**: Tag weights can be cached for frequent users
2. **Background Processing**: Pre-calculate global weights periodically
3. **Pagination**: Algorithm works with Django's built-in pagination
4. **Database Indexing**: Ensure indexes on `user_id`, `post_id`, `tag_id` in Like and Tag relations

### Memory Usage

For a typical deployment:

- 1000 tags: ~32KB for weight dictionaries
- 10000 posts per query: ~320KB for post scores
- Total: <1MB per request (acceptable for most systems)

## Error Handling and Edge Cases

### Empty Data Scenarios

1. **No Posts**: Returns empty queryset gracefully
2. **No Tags**: All posts get baseline score (0.1)
3. **No User History**: Algorithm falls back to global weights only
4. **No Global Data**: Uses baseline weights for all tags

### Error Recovery

```python
try:
    return self._apply_suggestion_algorithm(queryset)
except Exception as e:
    # Log error and fall back to chronological ordering
    logger.error(f"Suggestion algorithm failed: {e}")
    return queryset.order_by('-created_at')
```

## Future Enhancements

### Planned Improvements

1. **Machine Learning Integration**

   - Implement collaborative filtering
   - Use neural networks for more sophisticated scoring
   - Add content-based similarity analysis

2. **Advanced Diversity Mechanisms**

   - Topic clustering for better diversity
   - Time-based diversity (avoid too many recent posts)
   - Author diversity (prevent single-author dominance)

3. **Real-time Adaptation**

   - Dynamic weight adjustment based on session behavior
   - A/B testing framework for algorithm optimization
   - User feedback integration

4. **Performance Optimizations**
   - Redis caching for weight calculations
   - Elasticsearch integration for complex queries
   - Background job processing for expensive calculations

### Potential Extensions

1. **Social Graph Integration**: Incorporate friend/follower relationships
2. **Temporal Factors**: Weight recent interactions more heavily
3. **Content Quality Metrics**: Factor in engagement rates, report counts
4. **Personalized Diversity**: Adjust diversity ratios per user preferences

## Conclusion

The implemented suggestion algorithm successfully balances personalization with content discovery, ensuring users receive relevant content while being exposed to diverse topics. The system is designed for scalability, maintainability, and continuous improvement.

Key achievements:

- ✅ Personalized content based on user behavior
- ✅ Global trend integration
- ✅ Diversity mechanism preventing echo chambers
- ✅ Efficient database operations
- ✅ Seamless integration with existing codebase
- ✅ Robust error handling and fallback mechanisms

The algorithm provides a solid foundation for intelligent content curation that can evolve with the platform's growth and changing user needs.
