# Admin Panel Features - Quick Reference

## 🎯 Overview
This document provides a quick reference for all admin panel features available in the AR Folk Heritage Platform.

## 🔐 Access Control

### User Roles
- **Admin**: Full access to all features
- **Moderator**: Can approve/reject stories, view analytics
- **User**: Regular user (no admin access)

### Permission Matrix
| Feature | Admin | Moderator | User |
|---------|-------|-----------|------|
| Add/Edit/Delete Monuments | ✅ | ❌ | ❌ |
| Approve/Reject Stories | ✅ | ✅ | ❌ |
| Manage Quiz Templates | ✅ | ❌ | ❌ |
| Assign User Roles | ✅ | ❌ | ❌ |
| View Analytics | ✅ | ✅ | ❌ |
| Review Reports | ✅ | ✅ | ❌ |
| Submit Stories | ✅ | ✅ | ✅ |
| Rate Monuments | ✅ | ✅ | ✅ |

## 📊 Admin Dashboard Tables

### 1. Monuments Management

#### Table: `monuments`
**Fields:**
- `title` (required) - Monument name
- `location` (required) - City, State/Country
- `era` (required) - Historical period
- `image_url` (required) - Main image URL
- `description` - Detailed description
- `latitude` - GPS latitude
- `longitude` - GPS longitude
- `category` - Type (temple, fort, palace, etc.)
- `significance` - Historical importance
- `is_published` - Visibility status

**Admin Actions:**
```sql
-- Create monument
INSERT INTO monuments (title, location, era, image_url, description)
VALUES ('Taj Mahal', 'Agra, India', '17th Century', 'url', 'description');

-- Update monument
UPDATE monuments 
SET description = 'Updated description', updated_at = now()
WHERE id = 'monument-uuid';

-- Delete monument (will cascade delete related data)
DELETE FROM monuments WHERE id = 'monument-uuid';

-- Unpublish monument (hide from public)
UPDATE monuments SET is_published = false WHERE id = 'monument-uuid';
```

### 2. Story Moderation

#### Table: `stories`
**Contribution Status:**
- `pending` - Awaiting review
- `approved` - Published
- `rejected` - Not accepted

**Fields:**
- `monument_id` - Associated monument
- `user_id` - Story author
- `title` - Story title
- `content` - Story text
- `author_name` - Public author name
- `image_url` - Optional image
- `status` - Moderation status
- `rejection_reason` - If rejected
- `moderated_by` - Admin/moderator UUID
- `moderated_at` - Timestamp

**Admin Actions:**
```sql
-- View pending stories
SELECT s.*, m.title as monument_title, p.display_name as author
FROM stories s
JOIN monuments m ON s.monument_id = m.id
JOIN profiles p ON s.user_id = p.user_id
WHERE s.status = 'pending'
ORDER BY s.created_at ASC;

-- Approve story
UPDATE stories 
SET status = 'approved',
    moderated_by = auth.uid(),
    moderated_at = now()
WHERE id = 'story-uuid';

-- Reject story with reason
UPDATE stories 
SET status = 'rejected',
    rejection_reason = 'Content does not meet guidelines',
    moderated_by = auth.uid(),
    moderated_at = now()
WHERE id = 'story-uuid';

-- Delete story
DELETE FROM stories WHERE id = 'story-uuid';
```

### 3. Quiz Management

#### Table: `quiz_templates`
**Fields:**
- `monument_id` - Associated monument
- `title` - Quiz title
- `description` - Quiz description
- `difficulty` - 'easy', 'medium', 'hard'
- `is_active` - Published status
- `created_by` - Creator UUID

#### Table: `quiz_questions`
**Fields:**
- `quiz_template_id` - Parent quiz
- `question` - Question text
- `options` - JSON array of options
- `correct_answer` - Index (0-3)
- `explanation` - Answer explanation
- `order_index` - Display order

**Admin Actions:**
```sql
-- Create quiz template
INSERT INTO quiz_templates (monument_id, title, difficulty, created_by)
VALUES ('monument-uuid', 'Test Your Knowledge', 'medium', auth.uid());

-- Add question to quiz
INSERT INTO quiz_questions (
  quiz_template_id, 
  question, 
  options, 
  correct_answer, 
  explanation,
  order_index
) VALUES (
  'template-uuid',
  'When was this monument built?',
  '["12th century", "15th century", "18th century", "20th century"]'::jsonb,
  1,
  'The monument was constructed in the 15th century during...',
  1
);

-- Update question
UPDATE quiz_questions
SET question = 'Updated question',
    options = '["New option 1", "New option 2", "New option 3", "New option 4"]'::jsonb
WHERE id = 'question-uuid';

-- Activate/deactivate quiz
UPDATE quiz_templates SET is_active = true WHERE id = 'template-uuid';

-- Delete quiz (will cascade delete questions)
DELETE FROM quiz_templates WHERE id = 'template-uuid';
```

### 4. User Management

#### Table: `user_roles`
**Admin Actions:**
```sql
-- View all users with roles
SELECT 
  u.id,
  u.email,
  u.created_at,
  array_agg(ur.role) as roles,
  p.display_name
FROM auth.users u
LEFT JOIN user_roles ur ON u.id = ur.user_id
LEFT JOIN profiles p ON u.id = p.user_id
GROUP BY u.id, u.email, u.created_at, p.display_name;

-- Assign admin role
INSERT INTO user_roles (user_id, role, assigned_by)
VALUES ('user-uuid', 'admin', auth.uid());

-- Assign moderator role
INSERT INTO user_roles (user_id, role, assigned_by)
VALUES ('user-uuid', 'moderator', auth.uid());

-- Remove role
DELETE FROM user_roles 
WHERE user_id = 'user-uuid' AND role = 'moderator';

-- View user's contributions
SELECT 
  (SELECT COUNT(*) FROM stories WHERE user_id = 'user-uuid') as stories_count,
  (SELECT COUNT(*) FROM monument_ratings WHERE user_id = 'user-uuid') as ratings_count,
  (SELECT COUNT(*) FROM quiz_completions WHERE user_id = 'user-uuid') as quizzes_completed;
```

### 5. Analytics Queries

```sql
-- Dashboard overview
SELECT * FROM admin_dashboard_stats;

-- Popular monuments
SELECT * FROM popular_monuments LIMIT 10;

-- Recent activity (last 7 days)
SELECT 
  DATE(created_at) as date,
  COUNT(*) as count
FROM stories
WHERE created_at > now() - interval '7 days'
GROUP BY DATE(created_at)
ORDER BY date DESC;

-- User engagement metrics
SELECT 
  COUNT(DISTINCT user_id) as active_users,
  COUNT(*) as total_interactions
FROM (
  SELECT user_id, created_at FROM stories
  UNION ALL
  SELECT user_id, created_at FROM monument_ratings
  UNION ALL
  SELECT user_id, completed_at as created_at FROM quiz_completions
) as interactions
WHERE created_at > now() - interval '30 days';

-- Top contributors
SELECT 
  p.display_name,
  u.email,
  COUNT(s.id) as story_count
FROM stories s
JOIN auth.users u ON s.user_id = u.id
JOIN profiles p ON u.id = p.user_id
WHERE s.status = 'approved'
GROUP BY p.display_name, u.email
ORDER BY story_count DESC
LIMIT 10;

-- Monument engagement
SELECT 
  m.title,
  m.rating,
  m.stories_count,
  COUNT(DISTINCT mv.id) as views,
  COUNT(DISTINCT qc.user_id) as quiz_takers
FROM monuments m
LEFT JOIN monument_views mv ON m.id = mv.monument_id
LEFT JOIN quiz_completions qc ON m.id = qc.monument_id
GROUP BY m.id, m.title, m.rating, m.stories_count
ORDER BY views DESC
LIMIT 20;
```

### 6. Content Moderation

#### Table: `reported_content`
**Fields:**
- `entity_type` - 'story', 'monument', 'rating'
- `entity_id` - ID of reported item
- `reported_by` - Reporter UUID
- `reason` - Report category
- `description` - Details
- `status` - 'pending', 'reviewed', 'resolved'
- `reviewed_by` - Moderator UUID
- `resolution` - Action taken

**Admin Actions:**
```sql
-- View pending reports
SELECT 
  rc.*,
  p.display_name as reporter_name
FROM reported_content rc
JOIN profiles p ON rc.reported_by = p.user_id
WHERE rc.status = 'pending'
ORDER BY rc.created_at DESC;

-- Review report
UPDATE reported_content
SET status = 'reviewed',
    reviewed_by = auth.uid(),
    reviewed_at = now()
WHERE id = 'report-uuid';

-- Resolve with action
UPDATE reported_content
SET status = 'resolved',
    resolution = 'Content removed and user warned',
    reviewed_by = auth.uid(),
    reviewed_at = now()
WHERE id = 'report-uuid';
```

#### Table: `moderation_log`
Automatically tracks all moderation actions:
```sql
-- View moderation history
SELECT 
  ml.*,
  p.display_name as moderator_name
FROM moderation_log ml
JOIN profiles p ON ml.moderator_id = p.user_id
ORDER BY ml.created_at DESC
LIMIT 50;

-- Insert moderation log (done automatically by triggers or manually)
INSERT INTO moderation_log (
  entity_type,
  entity_id,
  action,
  moderator_id,
  reason,
  notes
) VALUES (
  'story',
  'story-uuid',
  'approved',
  auth.uid(),
  'Meets content guidelines',
  'Well-written historical account'
);
```

## 🔧 Common Admin Tasks

### Task 1: Bulk Approve Stories
```sql
-- Approve all pending stories from a trusted user
UPDATE stories
SET status = 'approved',
    moderated_by = auth.uid(),
    moderated_at = now()
WHERE user_id = 'trusted-user-uuid' AND status = 'pending';
```

### Task 2: Feature Monument
```sql
-- Add featured flag (you may need to add this column)
ALTER TABLE monuments ADD COLUMN is_featured BOOLEAN DEFAULT false;

UPDATE monuments SET is_featured = true WHERE id = 'monument-uuid';
```

### Task 3: Batch Delete Spam
```sql
-- Delete all stories from a spam account
DELETE FROM stories WHERE user_id = 'spam-user-uuid';
```

### Task 4: Export Data
```sql
-- Export all approved stories for a monument
COPY (
  SELECT 
    s.title,
    s.content,
    s.author_name,
    s.created_at,
    m.title as monument_name
  FROM stories s
  JOIN monuments m ON s.monument_id = m.id
  WHERE m.id = 'monument-uuid' AND s.status = 'approved'
) TO '/tmp/monument_stories.csv' CSV HEADER;
```

## 📱 Admin Panel UI Components Needed

### 1. Monuments Tab
- [ ] Monument list table with search/filter
- [ ] Add monument form dialog
- [ ] Edit monument form
- [ ] Image uploader
- [ ] Delete confirmation dialog
- [ ] Publish/unpublish toggle

### 2. Stories Tab
- [ ] Pending stories queue
- [ ] Story preview card
- [ ] Approve/reject buttons
- [ ] Rejection reason textarea
- [ ] Bulk action selector
- [ ] Filter by status

### 3. Quizzes Tab
- [ ] Quiz template list
- [ ] Create template form
- [ ] Question editor
- [ ] Add/remove options
- [ ] Correct answer selector
- [ ] Preview quiz
- [ ] Activate/deactivate toggle

### 4. Users Tab
- [ ] User list with pagination
- [ ] Role badges
- [ ] Role assignment dropdown
- [ ] User profile modal
- [ ] Activity statistics
- [ ] Contribution history

### 5. Analytics Tab
- [ ] Stats cards (monuments, stories, users)
- [ ] Line charts (views over time)
- [ ] Bar charts (popular monuments)
- [ ] User engagement metrics
- [ ] Export data button

### 6. Reports Tab
- [ ] Reported content list
- [ ] Report details modal
- [ ] Review actions (approve/delete content)
- [ ] Resolution notes textarea
- [ ] Status filter

## 🚀 Performance Tips

### Indexing Strategy
All necessary indexes are created by the migration. Key indexes:
- Monument searches: title, location, era
- Story moderation: status, created_at
- Analytics: viewed_at dates
- User lookups: user_id references

### Query Optimization
```sql
-- Use EXPLAIN ANALYZE to check query performance
EXPLAIN ANALYZE
SELECT * FROM stories WHERE status = 'pending';

-- Add pagination for large datasets
SELECT * FROM monuments
ORDER BY created_at DESC
LIMIT 50 OFFSET 0;
```

## 📞 Support

### Common Errors
1. **Permission Denied**: Check user role in `user_roles` table
2. **Foreign Key Violation**: Ensure referenced records exist
3. **Check Constraint**: Verify data meets constraints (e.g., rating 1-5)

### Debugging
```sql
-- Check current user's roles
SELECT * FROM user_roles WHERE user_id = auth.uid();

-- Check RLS policies
SELECT * FROM pg_policies WHERE tablename = 'monuments';

-- View recent errors (if logging enabled)
SELECT * FROM admin_activity_log 
ORDER BY created_at DESC 
LIMIT 10;
```

---

**Last Updated**: December 28, 2025  
**Version**: 1.0.0
