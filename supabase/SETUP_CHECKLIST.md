# 🚀 Supabase Migration Setup Checklist

## Prerequisites
- [ ] New Supabase project created
- [ ] Project URL and API keys available
- [ ] Supabase CLI installed (optional but recommended)
- [ ] Database backup of old project (if migrating)

---

## Phase 1: Database Setup

### Step 1: Apply Migration Script ⏱️ 5 minutes
- [ ] Open Supabase Dashboard → SQL Editor
- [ ] Copy entire content from `20251228000000_complete_migration.sql`
- [ ] Paste into SQL Editor
- [ ] Click "Run"
- [ ] Verify: No errors in output
- [ ] Confirm: All tables created (22 tables)

**Verification Query:**
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;
```

Expected tables:
```
- admin_activity_log
- favorite_monuments
- moderation_log
- monument_ratings
- monument_views
- monuments
- profiles
- quiz_completions
- quiz_questions
- quiz_templates
- reported_content
- stories
- story_views
- user_roles
```

### Step 2: Verify Functions ⏱️ 2 minutes
- [ ] Check functions created

**Verification Query:**
```sql
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public'
ORDER BY routine_name;
```

Expected functions:
```
- handle_new_user
- has_role
- is_admin_or_moderator
- update_monument_rating
- update_monument_stories_count
- update_updated_at_column
```

### Step 3: Verify Storage Buckets ⏱️ 2 minutes
- [ ] Go to Storage section in Supabase Dashboard
- [ ] Verify buckets exist:
  - [ ] `avatars` (5MB limit, public)
  - [ ] `story-images` (10MB limit, public)
  - [ ] `monument-images` (10MB limit, public)

If buckets don't exist, create manually:
```sql
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types) 
VALUES 
  ('avatars', 'avatars', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('story-images', 'story-images', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('monument-images', 'monument-images', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp']);
```

### Step 4: Verify RLS Policies ⏱️ 2 minutes
- [ ] Check RLS enabled on tables

**Verification Query:**
```sql
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;
```

All tables should have `rowsecurity = true`

---

## Phase 2: Admin User Setup

### Step 5: Create Admin User ⏱️ 3 minutes

#### Option A: Through App
1. [ ] Go to your app's signup page
2. [ ] Register with your admin email
3. [ ] Verify email (check Supabase Auth settings)
4. [ ] Note your user ID

#### Option B: Through Supabase Dashboard
1. [ ] Go to Authentication → Users
2. [ ] Click "Add User"
3. [ ] Enter email and password
4. [ ] Copy the generated UUID

### Step 6: Assign Admin Role ⏱️ 1 minute
- [ ] Go to SQL Editor
- [ ] Run this query (replace with your UUID):

```sql
-- Replace 'your-user-uuid-here' with your actual user ID
INSERT INTO public.user_roles (user_id, role, assigned_by) 
VALUES 
  ('your-user-uuid-here', 'admin', 'your-user-uuid-here')
ON CONFLICT (user_id, role) DO NOTHING;
```

**Verification:**
```sql
-- Check your roles
SELECT 
  u.email,
  ur.role,
  ur.created_at
FROM user_roles ur
JOIN auth.users u ON ur.user_id = u.id
WHERE u.email = 'your-admin-email@example.com';
```

Should show: `admin` role

---

## Phase 3: Application Configuration

### Step 7: Update Environment Variables ⏱️ 2 minutes
- [ ] Create/update `.env` file:

```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key-here
```

- [ ] Get values from: Project Settings → API
- [ ] **Never commit** `.env` to version control
- [ ] Add `.env` to `.gitignore`

### Step 8: Update Supabase Client ⏱️ 1 minute
- [ ] File: `src/integrations/supabase/client.ts`
- [ ] Verify it uses environment variables:

```typescript
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

export const supabase = createClient(supabaseUrl, supabaseAnonKey)
```

### Step 9: Install Dependencies ⏱️ 2 minutes
- [ ] Run: `npm install` or `bun install`
- [ ] Verify Supabase package installed:

```bash
npm list @supabase/supabase-js
```

### Step 10: Test Database Connection ⏱️ 2 minutes
- [ ] Start dev server: `npm run dev`
- [ ] Open browser console
- [ ] Run test query:

```javascript
const { data, error } = await supabase.from('monuments').select('count');
console.log('Connection test:', data, error);
```

---

## Phase 4: Initial Data Setup

### Step 11: Add Sample Monument (Optional) ⏱️ 3 minutes
- [ ] Log in as admin user
- [ ] Go to `/admin` page
- [ ] Add a test monument:

```
Title: Taj Mahal
Location: Agra, India
Era: 17th Century
Image URL: https://upload.wikimedia.org/wikipedia/commons/thumb/b/bd/Taj_Mahal%2C_Agra%2C_India_edit3.jpg/800px-Taj_Mahal%2C_Agra%2C_India_edit3.jpg
Description: An ivory-white marble mausoleum on the right bank of the river Yamuna in Agra, India.
```

### Step 12: Add Sample Quiz (Optional) ⏱️ 5 minutes
```sql
-- Create quiz template
INSERT INTO quiz_templates (monument_id, title, difficulty, created_by)
SELECT 
  id as monument_id,
  'Test Your Knowledge: ' || title as title,
  'medium' as difficulty,
  (SELECT user_id FROM user_roles WHERE role = 'admin' LIMIT 1) as created_by
FROM monuments
LIMIT 1
RETURNING id;

-- Add sample questions (replace template_id with UUID from above)
INSERT INTO quiz_questions (
  quiz_template_id,
  question,
  options,
  correct_answer,
  explanation,
  order_index
) VALUES
  (
    'template-uuid-here',
    'In which century was the Taj Mahal built?',
    '["15th century", "17th century", "19th century", "20th century"]'::jsonb,
    1,
    'The Taj Mahal was built in the 17th century (1632-1653) by Mughal Emperor Shah Jahan.',
    1
  ),
  (
    'template-uuid-here',
    'What material was primarily used to build the Taj Mahal?',
    '["White marble", "Red sandstone", "Granite", "Limestone"]'::jsonb,
    0,
    'The Taj Mahal is primarily built with white marble from Rajasthan.',
    2
  );
```

---

## Phase 5: Testing & Verification

### Step 13: Test User Registration ⏱️ 3 minutes
- [ ] Sign up a new test user
- [ ] Check profile created:

```sql
SELECT * FROM profiles WHERE user_id = (
  SELECT id FROM auth.users WHERE email = 'test@example.com'
);
```

- [ ] Verify default 'user' role assigned

### Step 14: Test Story Submission ⏱️ 5 minutes
- [ ] Log in as regular user (not admin)
- [ ] Go to a monument page
- [ ] Click "Contribute Story"
- [ ] Submit a test story
- [ ] Verify story status is 'pending':

```sql
SELECT title, status, created_at 
FROM stories 
ORDER BY created_at DESC 
LIMIT 1;
```

### Step 15: Test Story Moderation ⏱️ 3 minutes
- [ ] Log in as admin
- [ ] Go to `/admin` → Stories tab
- [ ] See pending story
- [ ] Approve or reject the story
- [ ] Verify status changed in database

### Step 16: Test Monument Rating ⏱️ 2 minutes
- [ ] As any user, rate a monument (1-5 stars)
- [ ] Check rating recorded:

```sql
SELECT * FROM monument_ratings 
WHERE monument_id = 'monument-uuid-here';
```

- [ ] Verify monument average rating updated

### Step 17: Test Quiz Functionality ⏱️ 5 minutes
- [ ] Go to monument page
- [ ] Click "Take Quiz"
- [ ] Complete the quiz
- [ ] Check completion recorded:

```sql
SELECT * FROM quiz_completions 
WHERE user_id = auth.uid()
ORDER BY completed_at DESC;
```

### Step 18: Test Analytics ⏱️ 2 minutes
- [ ] Go to `/admin` → Analytics tab
- [ ] Verify stats display:
  - Total monuments count
  - Total stories count
  - Pending stories count
  - Total users count
  - Views in last 30 days

**Manual verification:**
```sql
SELECT * FROM admin_dashboard_stats;
```

---

## Phase 6: Security Verification

### Step 19: Test RLS Policies ⏱️ 5 minutes

#### Test 1: Non-admin cannot add monuments
```javascript
// As regular user, should fail
const { data, error } = await supabase
  .from('monuments')
  .insert({ title: 'Test', location: 'Test', era: 'Test', image_url: 'test' });
console.log('Should be error:', error); // Expected: policy violation
```

#### Test 2: User can only see their own favorites
```sql
-- As user A, create favorite
INSERT INTO favorite_monuments (user_id, monument_id)
VALUES (auth.uid(), 'monument-uuid');

-- Try to view another user's favorites (should return empty)
SELECT * FROM favorite_monuments 
WHERE user_id != auth.uid();
-- Expected: 0 rows
```

#### Test 3: Admin can see all stories
```javascript
// As admin
const { data } = await supabase
  .from('stories')
  .select('*, profiles(display_name)')
  .eq('status', 'pending');
console.log('Pending stories:', data); // Should show all
```

### Step 20: Test Storage Access ⏱️ 3 minutes
- [ ] Upload avatar image
- [ ] Verify it appears in profile
- [ ] Try to delete another user's avatar (should fail)
- [ ] Upload story image
- [ ] Verify public access to image URL

---

## Phase 7: Production Readiness

### Step 21: Security Checklist ⏱️ 5 minutes
- [ ] Verify RLS enabled on all tables
- [ ] Check no service_role key in frontend code
- [ ] Verify email confirmation enabled (if needed)
- [ ] Review storage bucket policies
- [ ] Check CORS settings
- [ ] Enable database backups
- [ ] Set up monitoring/alerts

### Step 22: Performance Optimization ⏱️ 3 minutes
- [ ] Verify indexes created:

```sql
SELECT indexname, tablename 
FROM pg_indexes 
WHERE schemaname = 'public'
ORDER BY tablename;
```

- [ ] Enable connection pooling (if needed)
- [ ] Review query performance with EXPLAIN ANALYZE

### Step 23: Backup Strategy ⏱️ 2 minutes
- [ ] Enable Point-in-Time Recovery (PITR) in Project Settings
- [ ] Schedule regular backups
- [ ] Test backup restoration process

**Manual backup:**
```bash
# Using Supabase CLI
supabase db dump -f backup_$(date +%Y%m%d).sql
```

---

## Phase 8: Documentation & Handoff

### Step 24: Document Custom Configuration ⏱️ 5 minutes
- [ ] Document any environment-specific settings
- [ ] List admin user credentials (securely)
- [ ] Note any custom modifications to migration
- [ ] Create runbook for common admin tasks

### Step 25: Train Admin Users ⏱️ 15 minutes
- [ ] Show how to access admin panel
- [ ] Demonstrate monument creation
- [ ] Explain story moderation workflow
- [ ] Show how to manage quizzes
- [ ] Review analytics dashboard

---

## Troubleshooting Guide

### Issue: Migration fails with "relation already exists"
**Solution:** 
```sql
-- Drop existing table (CAUTION: deletes data)
DROP TABLE IF EXISTS table_name CASCADE;
-- Then re-run migration
```

### Issue: "permission denied for table"
**Solution:**
```sql
-- Check if RLS is enabled
SELECT tablename, rowsecurity FROM pg_tables WHERE tablename = 'monuments';

-- Check policies
SELECT * FROM pg_policies WHERE tablename = 'monuments';

-- Verify user has correct role
SELECT * FROM user_roles WHERE user_id = auth.uid();
```

### Issue: Storage bucket not found
**Solution:**
```sql
-- Check buckets
SELECT * FROM storage.buckets;

-- Recreate if needed
INSERT INTO storage.buckets (id, name, public) 
VALUES ('avatars', 'avatars', true);
```

### Issue: Functions not working
**Solution:**
```sql
-- Recreate function
CREATE OR REPLACE FUNCTION public.has_role(_user_id uuid, _role app_role)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = _user_id AND role = _role
  )
$$;
```

---

## Post-Migration Checklist

### Immediate (Day 1)
- [ ] All tests passing
- [ ] Admin can access `/admin`
- [ ] Users can sign up and create profiles
- [ ] Story submission working
- [ ] Storage upload working

### Short-term (Week 1)
- [ ] Monitor error logs
- [ ] Review user feedback
- [ ] Check database performance
- [ ] Verify backup process
- [ ] Test with production load

### Long-term (Month 1)
- [ ] Review analytics data
- [ ] Optimize slow queries
- [ ] Add missing indexes if needed
- [ ] Scale resources if needed
- [ ] Plan feature enhancements

---

## Success Criteria

✅ **Migration Complete When:**
1. All tables created with proper schema
2. RLS policies enforced correctly
3. Admin user can access admin panel
4. Regular users can submit content
5. Moderation workflow functional
6. Analytics tracking working
7. Storage uploads successful
8. No permission errors in logs
9. Performance meets requirements
10. Backup strategy in place

---

## Support Resources

- **Supabase Docs**: https://supabase.com/docs
- **SQL Reference**: https://www.postgresql.org/docs/
- **RLS Guide**: https://supabase.com/docs/guides/auth/row-level-security
- **Storage Guide**: https://supabase.com/docs/guides/storage

---

**Total Estimated Time**: 1.5 - 2 hours
**Difficulty**: Intermediate
**Last Updated**: December 28, 2025

---

## Quick Start (TL;DR)

```bash
# 1. Apply migration in SQL Editor
# 2. Create admin user and assign role:
INSERT INTO user_roles (user_id, role, assigned_by) 
VALUES ('your-uuid', 'admin', 'your-uuid');

# 3. Update .env file
VITE_SUPABASE_URL=your-url
VITE_SUPABASE_ANON_KEY=your-key

# 4. Test
npm install && npm run dev
```

Navigate to `/admin` and start managing your platform! 🎉
