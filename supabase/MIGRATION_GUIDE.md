# AR Folk Heritage Platform - Migration Guide

## Overview
This migration script creates a complete database schema for the AR Folk Heritage Platform with comprehensive admin panel functionality. The schema includes user management, monument management, story moderation, quiz management, analytics tracking, and content moderation features.

## Migration File
- **File**: `20251228000000_complete_migration.sql`
- **Created**: December 28, 2025
- **Purpose**: Complete database setup for new Supabase project

## What's Included

### 1. Core Features
- **User Profiles**: Display name, avatar, bio
- **Role-Based Access Control**: Admin, Moderator, User roles
- **Monuments Management**: Full CRUD with metadata (location, era, description, coordinates)
- **Stories System**: User-contributed stories with moderation workflow
- **Ratings & Reviews**: 5-star rating system with optional reviews
- **Favorites**: Bookmark monuments
- **Quiz System**: Template-based quizzes with questions

### 2. Admin Panel Features

#### Monument Management
- ✅ Create, Read, Update, Delete monuments
- ✅ Add location coordinates (latitude/longitude)
- ✅ Categorize monuments
- ✅ Set significance level
- ✅ Publish/unpublish monuments
- ✅ Upload monument images

#### Story Moderation
- ✅ Approve/reject user contributions
- ✅ View pending stories
- ✅ Add rejection reasons
- ✅ Track moderation history
- ✅ Moderator assignment

#### Quiz Management
- ✅ Create quiz templates for monuments
- ✅ Add/edit/delete quiz questions
- ✅ Set difficulty levels
- ✅ Activate/deactivate quizzes
- ✅ View quiz completion statistics

#### User Management
- ✅ View all users
- ✅ Assign/remove roles (Admin, Moderator, User)
- ✅ Track user activity
- ✅ View user contributions

#### Analytics Dashboard
- ✅ Total monuments, stories, users
- ✅ Pending contributions count
- ✅ View statistics (30-day trends)
- ✅ Quiz completion rates
- ✅ Popular monuments ranking
- ✅ User engagement metrics

#### Content Moderation
- ✅ Report system for inappropriate content
- ✅ Moderation log tracking
- ✅ Admin activity log
- ✅ Review reported content

### 3. Security Features
- Row Level Security (RLS) on all tables
- Role-based permissions
- Secure functions with SECURITY DEFINER
- User can only edit their own content
- Admins have full access
- Moderators have story approval access

### 4. Analytics & Tracking
- Monument view tracking
- Story view tracking (with language support)
- Quiz completion tracking
- Session tracking
- Time-based analytics

## How to Apply Migration

### Step 1: Create New Supabase Project
1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Create a new project
3. Note your project URL and API keys

### Step 2: Apply Migration

#### Option A: Using Supabase CLI (Recommended)
```bash
# Install Supabase CLI if not installed
npm install -g supabase

# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref your-project-ref

# Push the migration
supabase db push
```

#### Option B: Using SQL Editor
1. Open your Supabase project dashboard
2. Go to SQL Editor
3. Copy the entire content of `20251228000000_complete_migration.sql`
4. Paste and run the SQL script

### Step 3: Create First Admin User

After running the migration:

1. **Sign up a user** through your app's authentication
2. **Get the user's UUID** from Supabase Dashboard:
   - Go to Authentication → Users
   - Copy the UUID of your user

3. **Assign admin role** using SQL Editor:
```sql
-- Replace 'your-user-uuid-here' with actual UUID
INSERT INTO public.user_roles (user_id, role, assigned_by) 
VALUES ('your-user-uuid-here', 'admin', 'your-user-uuid-here');
```

### Step 4: Configure Storage
Storage buckets are automatically created, but verify they exist:
- `avatars` - User profile pictures (5MB limit)
- `story-images` - Story attachments (10MB limit)
- `monument-images` - Monument photos (10MB limit)

### Step 5: Set Environment Variables
Update your `.env` file:
```env
VITE_SUPABASE_URL=your-project-url
VITE_SUPABASE_ANON_KEY=your-anon-key
```

## Database Schema Overview

### Main Tables
```
profiles                 - User profile data
user_roles              - Role assignments
monuments               - Monument data
stories                 - User-contributed stories
favorite_monuments      - User favorites
monument_ratings        - Ratings and reviews
quiz_templates          - Quiz definitions
quiz_questions          - Quiz question bank
moderation_log          - Moderation history
admin_activity_log      - Admin actions log
reported_content        - User reports
story_views             - View analytics
monument_views          - View analytics
quiz_completions        - Quiz results
```

### Enums
- `app_role`: 'admin', 'moderator', 'user'
- `contribution_status`: 'pending', 'approved', 'rejected'

## Admin Panel Access

### Accessing Admin Panel
URL: `https://yourapp.com/admin`

### Required Permissions
- User must be authenticated
- User must have 'admin' role in `user_roles` table
- Protected by `useUserRole` hook

### Admin Panel Tabs
1. **Monuments**: Add/edit/delete monuments
2. **Stories**: Approve/reject user stories
3. **Quizzes**: Manage quiz templates and questions
4. **Users**: View and manage user roles
5. **Analytics**: View platform statistics
6. **Reports**: Review reported content

## API Functions

### Role Check Functions
```sql
-- Check if user has specific role
SELECT public.has_role('user-uuid', 'admin');

-- Check if user is admin or moderator
SELECT public.is_admin_or_moderator('user-uuid');
```

### Automatic Calculations
- Monument ratings are automatically averaged when users rate
- Story counts are automatically updated on approval/deletion
- User profiles are auto-created on signup

## Data Views

### Dashboard Statistics
```sql
SELECT * FROM public.admin_dashboard_stats;
```

Returns:
- Total monuments
- Total stories
- Pending stories
- Total users
- Views in last 30 days
- Quizzes completed in last 30 days

### Popular Monuments
```sql
SELECT * FROM public.popular_monuments;
```

Returns monuments ranked by view count and engagement.

## Testing the Migration

### 1. Test User Signup
```javascript
const { data, error } = await supabase.auth.signUp({
  email: 'test@example.com',
  password: 'password123'
})
```

### 2. Test Monument Creation (Admin Only)
```javascript
const { data, error } = await supabase
  .from('monuments')
  .insert({
    title: 'Test Monument',
    location: 'Test City',
    era: '15th Century',
    image_url: 'https://example.com/image.jpg',
    description: 'Test description'
  })
```

### 3. Test Story Submission
```javascript
const { data, error } = await supabase
  .from('stories')
  .insert({
    monument_id: 'monument-uuid',
    user_id: 'user-uuid',
    title: 'My Story',
    content: 'Story content...'
  })
// Status defaults to 'pending'
```

### 4. Test Story Approval (Admin/Moderator)
```javascript
const { data, error } = await supabase
  .from('stories')
  .update({ 
    status: 'approved',
    moderated_by: 'admin-uuid',
    moderated_at: new Date().toISOString()
  })
  .eq('id', 'story-uuid')
```

## Troubleshooting

### Issue: "Permission denied for table"
**Solution**: Ensure RLS policies are applied and user has correct role.

### Issue: "Function does not exist"
**Solution**: Run the migration again, functions may not have been created.

### Issue: "Storage bucket not found"
**Solution**: Check storage section in Supabase dashboard, buckets should be created automatically.

### Issue: "Cannot insert into monuments (admin only)"
**Solution**: 
```sql
-- Verify user has admin role
SELECT * FROM public.user_roles WHERE user_id = auth.uid();
```

## Additional Features to Implement

### Frontend Admin Components Needed
1. **Quiz Management UI**
   - Create quiz template form
   - Add questions interface
   - Question editor with options and correct answer

2. **User Management UI**
   - User list with role badges
   - Role assignment dropdown
   - User activity timeline

3. **Content Reports UI**
   - Reported content list
   - Review and resolve interface
   - Ban/warn actions

4. **Enhanced Analytics**
   - Charts for view trends
   - Geographic distribution
   - User engagement heatmap

## Support & Maintenance

### Backup Strategy
```bash
# Export database
supabase db dump -f backup.sql

# Export with data
supabase db dump --data-only -f data_backup.sql
```

### Migration Rollback
Keep a backup before applying migration. To rollback:
```sql
-- Drop all tables (CAUTION: This deletes all data)
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
```

## Security Best Practices

1. **Never expose service_role key** in frontend code
2. **Always use RLS policies** for data access
3. **Validate input** on both frontend and database level
4. **Audit admin actions** using admin_activity_log
5. **Regular backups** of database
6. **Monitor reported_content** table regularly
7. **Review moderation_log** for admin oversight

## Next Steps

1. ✅ Apply migration to new Supabase project
2. ✅ Create first admin user
3. ✅ Test basic functionality
4. ⬜ Add sample monument data
5. ⬜ Implement quiz management UI
6. ⬜ Add user management interface
7. ⬜ Implement content reporting UI
8. ⬜ Set up monitoring and alerts

## Contact & Support
For issues or questions about this migration:
- Check Supabase documentation: https://supabase.com/docs
- Review RLS policies if permission errors occur
- Test with different user roles to verify access control

---

**Migration Version**: 1.0.0  
**Last Updated**: December 28, 2025  
**Schema Version**: Complete with Admin Panel
