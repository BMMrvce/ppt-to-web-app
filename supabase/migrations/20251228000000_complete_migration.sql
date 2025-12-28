-- ============================================================================
-- Complete Migration Script for AR Folk Heritage Platform
-- Created: 2025-12-28
-- Description: Comprehensive database schema with admin panel functionality
-- ============================================================================

-- ============================================================================
-- 1. ENUMS
-- ============================================================================

-- Create role enum for user permissions
CREATE TYPE public.app_role AS ENUM ('admin', 'moderator', 'user');

-- Create contribution status enum for moderation workflow
CREATE TYPE public.contribution_status AS ENUM ('pending', 'approved', 'rejected');

-- ============================================================================
-- 2. CORE TABLES
-- ============================================================================

-- User profiles table
CREATE TABLE public.profiles (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT,
  avatar_url TEXT,
  bio TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- User roles table for access control
CREATE TABLE public.user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  role app_role NOT NULL,
  assigned_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE (user_id, role)
);

-- Monuments table
CREATE TABLE public.monuments (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  location TEXT NOT NULL,
  image_url TEXT NOT NULL,
  stories_count INTEGER NOT NULL DEFAULT 0,
  rating DECIMAL(3,2) NOT NULL DEFAULT 0.0 CHECK (rating >= 0 AND rating <= 5),
  era TEXT NOT NULL,
  description TEXT,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  category TEXT,
  significance TEXT,
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  is_published BOOLEAN NOT NULL DEFAULT true
);

-- Stories table
CREATE TABLE public.stories (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  monument_id UUID NOT NULL REFERENCES public.monuments(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  author_name TEXT,
  image_url TEXT,
  language TEXT DEFAULT 'en',
  status contribution_status NOT NULL DEFAULT 'pending',
  rejection_reason TEXT,
  moderated_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  moderated_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Favorite monuments table
CREATE TABLE public.favorite_monuments (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  monument_id UUID NOT NULL REFERENCES public.monuments(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(user_id, monument_id)
);

-- Monument ratings table
CREATE TABLE public.monument_ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  monument_id UUID REFERENCES public.monuments(id) ON DELETE CASCADE NOT NULL,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  review TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE (monument_id, user_id)
);

-- ============================================================================
-- 3. ANALYTICS & TRACKING TABLES
-- ============================================================================

-- Story views tracking
CREATE TABLE public.story_views (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  story_id UUID REFERENCES public.stories(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  viewed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  language TEXT DEFAULT 'en',
  session_id TEXT
);

-- Monument views tracking
CREATE TABLE public.monument_views (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  monument_id UUID REFERENCES public.monuments(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  viewed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  session_id TEXT
);

-- Quiz completions tracking
CREATE TABLE public.quiz_completions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  monument_id UUID REFERENCES public.monuments(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  score INTEGER NOT NULL,
  total_questions INTEGER NOT NULL,
  difficulty TEXT DEFAULT 'medium',
  time_taken_seconds INTEGER,
  completed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- ============================================================================
-- 4. QUIZ MANAGEMENT TABLES (for Admin Panel)
-- ============================================================================

-- Quiz templates table
CREATE TABLE public.quiz_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  monument_id UUID REFERENCES public.monuments(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  difficulty TEXT DEFAULT 'medium',
  is_active BOOLEAN DEFAULT true,
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Quiz questions table
CREATE TABLE public.quiz_questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quiz_template_id UUID REFERENCES public.quiz_templates(id) ON DELETE CASCADE NOT NULL,
  question TEXT NOT NULL,
  options JSONB NOT NULL, -- Array of options
  correct_answer INTEGER NOT NULL, -- Index of correct option
  explanation TEXT,
  order_index INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- ============================================================================
-- 5. MODERATION & ADMIN TABLES
-- ============================================================================

-- Contribution moderation log
CREATE TABLE public.moderation_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type TEXT NOT NULL, -- 'story', 'monument', 'rating', etc.
  entity_id UUID NOT NULL,
  action TEXT NOT NULL, -- 'approved', 'rejected', 'deleted', etc.
  moderator_id UUID REFERENCES auth.users(id) ON DELETE SET NULL NOT NULL,
  reason TEXT,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Admin activity log
CREATE TABLE public.admin_activity_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id UUID REFERENCES auth.users(id) ON DELETE SET NULL NOT NULL,
  action TEXT NOT NULL,
  entity_type TEXT,
  entity_id UUID,
  details JSONB,
  ip_address TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Reported content table
CREATE TABLE public.reported_content (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type TEXT NOT NULL,
  entity_id UUID NOT NULL,
  reported_by UUID REFERENCES auth.users(id) ON DELETE SET NULL NOT NULL,
  reason TEXT NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'pending', -- 'pending', 'reviewed', 'resolved'
  reviewed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  reviewed_at TIMESTAMP WITH TIME ZONE,
  resolution TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- ============================================================================
-- 6. INDEXES FOR PERFORMANCE
-- ============================================================================

-- Profile indexes
CREATE INDEX idx_profiles_user_id ON public.profiles(user_id);

-- User roles indexes
CREATE INDEX idx_user_roles_user_id ON public.user_roles(user_id);
CREATE INDEX idx_user_roles_role ON public.user_roles(role);

-- Monument indexes
CREATE INDEX idx_monuments_created_at ON public.monuments(created_at DESC);
CREATE INDEX idx_monuments_rating ON public.monuments(rating DESC);
CREATE INDEX idx_monuments_era ON public.monuments(era);
CREATE INDEX idx_monuments_location ON public.monuments(location);
CREATE INDEX idx_monuments_is_published ON public.monuments(is_published);

-- Story indexes
CREATE INDEX idx_stories_monument_id ON public.stories(monument_id);
CREATE INDEX idx_stories_user_id ON public.stories(user_id);
CREATE INDEX idx_stories_status ON public.stories(status);
CREATE INDEX idx_stories_created_at ON public.stories(created_at DESC);

-- Analytics indexes
CREATE INDEX idx_story_views_story_id ON public.story_views(story_id);
CREATE INDEX idx_story_views_viewed_at ON public.story_views(viewed_at);
CREATE INDEX idx_monument_views_monument_id ON public.monument_views(monument_id);
CREATE INDEX idx_monument_views_viewed_at ON public.monument_views(viewed_at);
CREATE INDEX idx_quiz_completions_user_id ON public.quiz_completions(user_id);
CREATE INDEX idx_quiz_completions_monument_id ON public.quiz_completions(monument_id);
CREATE INDEX idx_quiz_completions_completed_at ON public.quiz_completions(completed_at);

-- Quiz indexes
CREATE INDEX idx_quiz_templates_monument_id ON public.quiz_templates(monument_id);
CREATE INDEX idx_quiz_questions_template_id ON public.quiz_questions(quiz_template_id);

-- Moderation indexes
CREATE INDEX idx_moderation_log_entity ON public.moderation_log(entity_type, entity_id);
CREATE INDEX idx_moderation_log_moderator ON public.moderation_log(moderator_id);
CREATE INDEX idx_admin_activity_log_admin ON public.admin_activity_log(admin_id);
CREATE INDEX idx_reported_content_status ON public.reported_content(status);
CREATE INDEX idx_reported_content_entity ON public.reported_content(entity_type, entity_id);

-- ============================================================================
-- 7. FUNCTIONS
-- ============================================================================

-- Function to update timestamps
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

-- Function to check user roles
CREATE OR REPLACE FUNCTION public.has_role(_user_id UUID, _role app_role)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.user_roles
    WHERE user_id = _user_id
      AND role = _role
  )
$$;

-- Function to check if user is admin or moderator
CREATE OR REPLACE FUNCTION public.is_admin_or_moderator(_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.user_roles
    WHERE user_id = _user_id
      AND role IN ('admin', 'moderator')
  )
$$;

-- Function to update monument average rating
CREATE OR REPLACE FUNCTION public.update_monument_rating()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.monuments
  SET rating = (
    SELECT COALESCE(ROUND(AVG(rating)::numeric, 2), 0)
    FROM public.monument_ratings
    WHERE monument_id = COALESCE(NEW.monument_id, OLD.monument_id)
  )
  WHERE id = COALESCE(NEW.monument_id, OLD.monument_id);
  RETURN COALESCE(NEW, OLD);
END;
$$;

-- Function to update monument stories count
CREATE OR REPLACE FUNCTION public.update_monument_stories_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.monuments
  SET stories_count = (
    SELECT COUNT(*)
    FROM public.stories
    WHERE monument_id = COALESCE(NEW.monument_id, OLD.monument_id)
      AND status = 'approved'
  )
  WHERE id = COALESCE(NEW.monument_id, OLD.monument_id);
  RETURN COALESCE(NEW, OLD);
END;
$$;

-- Function to handle new user profile creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (user_id, display_name)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.email));
  
  -- Assign default 'user' role
  INSERT INTO public.user_roles (user_id, role)
  VALUES (NEW.id, 'user');
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ============================================================================
-- 8. TRIGGERS
-- ============================================================================

-- Timestamp update triggers
CREATE TRIGGER update_profiles_updated_at
BEFORE UPDATE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_monuments_updated_at
BEFORE UPDATE ON public.monuments
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_stories_updated_at
BEFORE UPDATE ON public.stories
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_user_roles_updated_at
BEFORE UPDATE ON public.user_roles
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_quiz_templates_updated_at
BEFORE UPDATE ON public.quiz_templates
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_quiz_questions_updated_at
BEFORE UPDATE ON public.quiz_questions
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- Rating calculation trigger
CREATE TRIGGER on_rating_change
AFTER INSERT OR UPDATE OR DELETE ON public.monument_ratings
FOR EACH ROW
EXECUTE FUNCTION public.update_monument_rating();

-- Stories count update trigger
CREATE TRIGGER on_story_status_change
AFTER INSERT OR UPDATE OR DELETE ON public.stories
FOR EACH ROW
EXECUTE FUNCTION public.update_monument_stories_count();

-- New user profile creation trigger
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- 9. ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.monuments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorite_monuments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.monument_ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.story_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.monument_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.moderation_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_activity_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reported_content ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 10. RLS POLICIES - PROFILES
-- ============================================================================

CREATE POLICY "Users can view their own profile"
ON public.profiles FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own profile"
ON public.profiles FOR UPDATE
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own profile"
ON public.profiles FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can view all profiles"
ON public.profiles FOR SELECT
TO authenticated
USING (public.has_role(auth.uid(), 'admin'));

-- ============================================================================
-- 11. RLS POLICIES - USER ROLES
-- ============================================================================

CREATE POLICY "Users can view their own roles"
ON public.user_roles FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all roles"
ON public.user_roles FOR SELECT
TO authenticated
USING (public.has_role(auth.uid(), 'admin'));

CREATE POLICY "Admins can manage roles"
ON public.user_roles FOR ALL
TO authenticated
USING (public.has_role(auth.uid(), 'admin'));

-- ============================================================================
-- 12. RLS POLICIES - MONUMENTS
-- ============================================================================

CREATE POLICY "Everyone can view published monuments"
ON public.monuments FOR SELECT
USING (is_published = true OR public.is_admin_or_moderator(auth.uid()));

CREATE POLICY "Admins can insert monuments"
ON public.monuments FOR INSERT
TO authenticated
WITH CHECK (public.has_role(auth.uid(), 'admin'));

CREATE POLICY "Admins can update monuments"
ON public.monuments FOR UPDATE
TO authenticated
USING (public.has_role(auth.uid(), 'admin'));

CREATE POLICY "Admins can delete monuments"
ON public.monuments FOR DELETE
TO authenticated
USING (public.has_role(auth.uid(), 'admin'));

-- ============================================================================
-- 13. RLS POLICIES - STORIES
-- ============================================================================

CREATE POLICY "Everyone can view approved stories"
ON public.stories FOR SELECT
USING (
  status = 'approved' OR 
  auth.uid() = user_id OR 
  public.is_admin_or_moderator(auth.uid())
);

CREATE POLICY "Authenticated users can create stories"
ON public.stories FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own pending stories"
ON public.stories FOR UPDATE
TO authenticated
USING (auth.uid() = user_id AND status = 'pending');

CREATE POLICY "Users can delete their own pending stories"
ON public.stories FOR DELETE
TO authenticated
USING (auth.uid() = user_id AND status = 'pending');

CREATE POLICY "Moderators can update any story"
ON public.stories FOR UPDATE
TO authenticated
USING (public.is_admin_or_moderator(auth.uid()));

CREATE POLICY "Admins can delete any story"
ON public.stories FOR DELETE
TO authenticated
USING (public.has_role(auth.uid(), 'admin'));

-- ============================================================================
-- 14. RLS POLICIES - FAVORITES
-- ============================================================================

CREATE POLICY "Users can view their own favorites"
ON public.favorite_monuments FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Users can add their own favorites"
ON public.favorite_monuments FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can remove their own favorites"
ON public.favorite_monuments FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- ============================================================================
-- 15. RLS POLICIES - RATINGS
-- ============================================================================

CREATE POLICY "Everyone can view ratings"
ON public.monument_ratings FOR SELECT
USING (true);

CREATE POLICY "Users can rate monuments"
ON public.monument_ratings FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own rating"
ON public.monument_ratings FOR UPDATE
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own rating"
ON public.monument_ratings FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- ============================================================================
-- 16. RLS POLICIES - ANALYTICS
-- ============================================================================

CREATE POLICY "Anyone can record story views"
ON public.story_views FOR INSERT
WITH CHECK (true);

CREATE POLICY "Admins can view all story views"
ON public.story_views FOR SELECT
TO authenticated
USING (public.has_role(auth.uid(), 'admin'));

CREATE POLICY "Anyone can record monument views"
ON public.monument_views FOR INSERT
WITH CHECK (true);

CREATE POLICY "Admins can view all monument views"
ON public.monument_views FOR SELECT
TO authenticated
USING (public.has_role(auth.uid(), 'admin'));

CREATE POLICY "Users can insert their own quiz completions"
ON public.quiz_completions FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own quiz completions"
ON public.quiz_completions FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all quiz completions"
ON public.quiz_completions FOR SELECT
TO authenticated
USING (public.has_role(auth.uid(), 'admin'));

-- ============================================================================
-- 17. RLS POLICIES - QUIZ MANAGEMENT
-- ============================================================================

CREATE POLICY "Everyone can view active quiz templates"
ON public.quiz_templates FOR SELECT
USING (is_active = true OR public.is_admin_or_moderator(auth.uid()));

CREATE POLICY "Admins can manage quiz templates"
ON public.quiz_templates FOR ALL
TO authenticated
USING (public.has_role(auth.uid(), 'admin'));

CREATE POLICY "Everyone can view quiz questions for active templates"
ON public.quiz_questions FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.quiz_templates
    WHERE id = quiz_questions.quiz_template_id
    AND is_active = true
  ) OR public.is_admin_or_moderator(auth.uid())
);

CREATE POLICY "Admins can manage quiz questions"
ON public.quiz_questions FOR ALL
TO authenticated
USING (public.has_role(auth.uid(), 'admin'));

-- ============================================================================
-- 18. RLS POLICIES - MODERATION
-- ============================================================================

CREATE POLICY "Moderators can view moderation log"
ON public.moderation_log FOR SELECT
TO authenticated
USING (public.is_admin_or_moderator(auth.uid()));

CREATE POLICY "Moderators can insert moderation log"
ON public.moderation_log FOR INSERT
TO authenticated
WITH CHECK (public.is_admin_or_moderator(auth.uid()));

CREATE POLICY "Admins can view admin activity log"
ON public.admin_activity_log FOR SELECT
TO authenticated
USING (public.has_role(auth.uid(), 'admin'));

CREATE POLICY "Admins can insert admin activity log"
ON public.admin_activity_log FOR INSERT
TO authenticated
WITH CHECK (public.has_role(auth.uid(), 'admin'));

CREATE POLICY "Users can report content"
ON public.reported_content FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = reported_by);

CREATE POLICY "Users can view their own reports"
ON public.reported_content FOR SELECT
TO authenticated
USING (auth.uid() = reported_by OR public.is_admin_or_moderator(auth.uid()));

CREATE POLICY "Moderators can update reported content"
ON public.reported_content FOR UPDATE
TO authenticated
USING (public.is_admin_or_moderator(auth.uid()));

-- ============================================================================
-- 19. STORAGE BUCKETS
-- ============================================================================

-- Create storage buckets
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types) 
VALUES 
  ('avatars', 'avatars', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('story-images', 'story-images', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('monument-images', 'monument-images', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp'])
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 20. STORAGE POLICIES
-- ============================================================================

-- Avatar images policies
CREATE POLICY "Avatar images are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload their own avatar"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'avatars' AND 
  auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can update their own avatar"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'avatars' AND 
  auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can delete their own avatar"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'avatars' AND 
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Story images policies
CREATE POLICY "Story images are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'story-images');

CREATE POLICY "Users can upload story images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'story-images' AND 
  auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can delete their own story images"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'story-images' AND 
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Monument images policies
CREATE POLICY "Monument images are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'monument-images');

CREATE POLICY "Admins can upload monument images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'monument-images' AND 
  public.has_role(auth.uid(), 'admin')
);

CREATE POLICY "Admins can update monument images"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'monument-images' AND 
  public.has_role(auth.uid(), 'admin')
);

CREATE POLICY "Admins can delete monument images"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'monument-images' AND 
  public.has_role(auth.uid(), 'admin')
);

-- ============================================================================
-- 21. VIEWS FOR ADMIN DASHBOARD
-- ============================================================================

-- View for dashboard statistics
CREATE OR REPLACE VIEW public.admin_dashboard_stats AS
SELECT
  (SELECT COUNT(*) FROM public.monuments WHERE is_published = true) as total_monuments,
  (SELECT COUNT(*) FROM public.stories WHERE status = 'approved') as total_stories,
  (SELECT COUNT(*) FROM public.stories WHERE status = 'pending') as pending_stories,
  (SELECT COUNT(*) FROM auth.users) as total_users,
  (SELECT COUNT(*) FROM public.monument_views WHERE viewed_at > now() - interval '30 days') as views_last_30_days,
  (SELECT COUNT(*) FROM public.quiz_completions WHERE completed_at > now() - interval '30 days') as quizzes_last_30_days;

-- View for popular monuments
CREATE OR REPLACE VIEW public.popular_monuments AS
SELECT 
  m.id,
  m.title,
  m.location,
  m.rating,
  m.stories_count,
  COUNT(mv.id) as view_count,
  COUNT(DISTINCT qc.user_id) as quiz_takers
FROM public.monuments m
LEFT JOIN public.monument_views mv ON m.id = mv.monument_id
LEFT JOIN public.quiz_completions qc ON m.id = qc.monument_id
WHERE m.is_published = true
GROUP BY m.id, m.title, m.location, m.rating, m.stories_count
ORDER BY view_count DESC;

-- ============================================================================
-- 22. SAMPLE DATA (OPTIONAL - Remove if not needed)
-- ============================================================================

-- Note: In production, you should create the first admin user manually
-- This is just an example - replace with your actual admin user ID after signup
-- Example: 
-- INSERT INTO public.user_roles (user_id, role, assigned_by) 
-- VALUES ('your-admin-uuid-here', 'admin', 'your-admin-uuid-here');

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, service_role;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO postgres, service_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- Enable realtime for specific tables (optional)
ALTER PUBLICATION supabase_realtime ADD TABLE public.stories;
ALTER PUBLICATION supabase_realtime ADD TABLE public.monuments;
ALTER PUBLICATION supabase_realtime ADD TABLE public.reported_content;

-- Migration completed successfully
COMMENT ON SCHEMA public IS 'AR Folk Heritage Platform - Complete Schema with Admin Panel';
