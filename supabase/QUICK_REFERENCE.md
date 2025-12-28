# 📋 Admin Quick Reference Card

## 🔐 Essential SQL Commands

### Check Current User's Role
```sql
SELECT role FROM user_roles WHERE user_id = auth.uid();
```

### Make Someone Admin
```sql
INSERT INTO user_roles (user_id, role, assigned_by) 
VALUES ('user-uuid-here', 'admin', auth.uid());
```

### View Pending Stories
```sql
SELECT s.*, m.title as monument, p.display_name as author
FROM stories s
JOIN monuments m ON s.monument_id = m.id  
JOIN profiles p ON s.user_id = p.user_id
WHERE s.status = 'pending'
ORDER BY s.created_at ASC;
```

### Approve Story
```sql
UPDATE stories 
SET status = 'approved', moderated_by = auth.uid(), moderated_at = now()
WHERE id = 'story-uuid';
```

### Reject Story
```sql
UPDATE stories 
SET status = 'rejected', 
    rejection_reason = 'Does not meet guidelines',
    moderated_by = auth.uid(), 
    moderated_at = now()
WHERE id = 'story-uuid';
```

### View Dashboard Stats
```sql
SELECT * FROM admin_dashboard_stats;
```

### Top 10 Monuments
```sql
SELECT * FROM popular_monuments LIMIT 10;
```

---

## 🎯 Common Admin Tasks

### Add Monument
```sql
INSERT INTO monuments (title, location, era, image_url, description, is_published)
VALUES (
  'Monument Name',
  'City, Country', 
  '15th Century',
  'https://example.com/image.jpg',
  'Description...',
  true
);
```

### Create Quiz
```sql
-- 1. Create template
INSERT INTO quiz_templates (monument_id, title, difficulty)
VALUES ('monument-uuid', 'Quiz Title', 'medium')
RETURNING id;

-- 2. Add questions (repeat for each)
INSERT INTO quiz_questions (
  quiz_template_id, 
  question, 
  options, 
  correct_answer, 
  explanation
) VALUES (
  'template-uuid',
  'Question text?',
  '["Option 1", "Option 2", "Option 3", "Option 4"]'::jsonb,
  0,
  'Explanation...'
);
```

### Delete Spam Content
```sql
-- Delete all content from spam user
DELETE FROM stories WHERE user_id = 'spam-user-uuid';
DELETE FROM monument_ratings WHERE user_id = 'spam-user-uuid';
```

### Ban User (Revoke Permissions)
```sql
-- Remove all roles except 'user'
DELETE FROM user_roles 
WHERE user_id = 'user-uuid' AND role != 'user';
```

---

## 📊 Analytics Queries

### Active Users (Last 30 Days)
```sql
SELECT COUNT(DISTINCT user_id) as active_users
FROM (
  SELECT user_id, created_at FROM stories
  UNION ALL
  SELECT user_id, created_at FROM monument_ratings
  UNION ALL
  SELECT user_id, completed_at as created_at FROM quiz_completions
) interactions
WHERE created_at > now() - interval '30 days';
```

### Top Contributors
```sql
SELECT 
  p.display_name,
  COUNT(s.id) as story_count,
  AVG(LENGTH(s.content)) as avg_story_length
FROM stories s
JOIN profiles p ON s.user_id = p.user_id
WHERE s.status = 'approved'
GROUP BY p.display_name
ORDER BY story_count DESC
LIMIT 10;
```

### Content Growth (Daily)
```sql
SELECT 
  DATE(created_at) as date,
  COUNT(*) as new_stories
FROM stories
WHERE created_at > now() - interval '7 days'
GROUP BY DATE(created_at)
ORDER BY date DESC;
```

---

## 🛡️ Moderation Commands

### Review Reported Content
```sql
SELECT 
  rc.*,
  p.display_name as reporter
FROM reported_content rc
JOIN profiles p ON rc.reported_by = p.user_id
WHERE rc.status = 'pending'
ORDER BY rc.created_at DESC;
```

### Mark Report as Reviewed
```sql
UPDATE reported_content
SET status = 'reviewed',
    reviewed_by = auth.uid(),
    reviewed_at = now()
WHERE id = 'report-uuid';
```

### View Moderation History
```sql
SELECT 
  ml.*,
  p.display_name as moderator
FROM moderation_log ml
JOIN profiles p ON ml.moderator_id = p.user_id
ORDER BY ml.created_at DESC
LIMIT 20;
```

---

## 🔧 Troubleshooting

### Check User's Permissions
```sql
SELECT 
  u.email,
  array_agg(ur.role) as roles
FROM auth.users u
LEFT JOIN user_roles ur ON u.id = ur.user_id
WHERE u.email = 'user@example.com'
GROUP BY u.email;
```

### Verify RLS Policies
```sql
SELECT 
  tablename,
  policyname,
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'monuments'
ORDER BY policyname;
```

### Check Storage Buckets
```sql
SELECT id, name, public, file_size_limit 
FROM storage.buckets;
```

### Find Orphaned Records
```sql
-- Stories without monuments
SELECT * FROM stories 
WHERE monument_id NOT IN (SELECT id FROM monuments);

-- Ratings without users
SELECT * FROM monument_ratings
WHERE user_id NOT IN (SELECT id FROM auth.users);
```

---

## ⚡ Performance Checks

### Slow Queries
```sql
-- Enable query timing
EXPLAIN ANALYZE
SELECT * FROM monuments WHERE era = '15th Century';
```

### Table Sizes
```sql
SELECT 
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

### Index Usage
```sql
SELECT 
  schemaname,
  tablename,
  indexname,
  idx_scan as times_used
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan ASC;
```

---

## 🚨 Emergency Commands

### Disable RLS (EMERGENCY ONLY)
```sql
-- DO NOT USE IN PRODUCTION
ALTER TABLE monuments DISABLE ROW LEVEL SECURITY;
-- Re-enable immediately after fixing issue
ALTER TABLE monuments ENABLE ROW LEVEL SECURITY;
```

### Bulk Approve Stories
```sql
-- From trusted user
UPDATE stories
SET status = 'approved',
    moderated_by = auth.uid(),
    moderated_at = now()
WHERE user_id = 'trusted-user-uuid' 
  AND status = 'pending';
```

### Reset User Password (Supabase Dashboard)
```
1. Go to Authentication → Users
2. Find user by email
3. Click "..." → Send recovery email
```

---

## 📱 Frontend Integration

### Check if User is Admin
```typescript
import { supabase } from './supabase/client';

async function isUserAdmin() {
  const { data } = await supabase
    .from('user_roles')
    .select('role')
    .eq('user_id', (await supabase.auth.getUser()).data.user?.id)
    .eq('role', 'admin')
    .single();
  
  return !!data;
}
```

### Submit Story
```typescript
const { data, error } = await supabase
  .from('stories')
  .insert({
    monument_id: monumentId,
    user_id: user.id,
    title: 'Story Title',
    content: 'Story content...',
    status: 'pending' // Will be set by default
  });
```

### Approve Story (Admin)
```typescript
const { error } = await supabase
  .from('stories')
  .update({
    status: 'approved',
    moderated_by: user.id,
    moderated_at: new Date().toISOString()
  })
  .eq('id', storyId);
```

---

## 🔑 Environment Variables

```env
# Required
VITE_SUPABASE_URL=https://xxxxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Optional - For local development
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**⚠️ NEVER commit service_role_key to version control!**

---

## 📞 Support Links

- **Supabase Docs**: https://supabase.com/docs
- **SQL Editor**: https://app.supabase.com/project/_/sql
- **Table Editor**: https://app.supabase.com/project/_/editor
- **Storage**: https://app.supabase.com/project/_/storage
- **Auth**: https://app.supabase.com/project/_/auth/users

---

## 🎯 Role Permissions Summary

| Action | User | Moderator | Admin |
|--------|------|-----------|-------|
| Submit story | ✅ | ✅ | ✅ |
| Approve story | ❌ | ✅ | ✅ |
| Add monument | ❌ | ❌ | ✅ |
| Delete content | Own only | Stories | All |
| Assign roles | ❌ | ❌ | ✅ |
| View analytics | Own only | All | All |
| Manage quizzes | ❌ | ❌ | ✅ |

---

## 📋 Pre-Flight Checklist

Before going live:
- [ ] Admin user created
- [ ] Sample monuments added
- [ ] Storage buckets configured
- [ ] RLS policies tested
- [ ] Backup strategy in place
- [ ] Environment variables set
- [ ] Error monitoring enabled
- [ ] Rate limiting configured

---

## 🆘 Emergency Contacts

| Issue | Action |
|-------|--------|
| Database down | Check Supabase status page |
| Permission denied | Verify user role in user_roles |
| Storage upload fails | Check bucket policies |
| RLS blocking admin | Verify has_role() function |
| Migration failed | Restore from backup |

---

**Print this card and keep handy for quick reference!**

*Last Updated: December 28, 2025*
