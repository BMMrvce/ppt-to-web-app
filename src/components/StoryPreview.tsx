import { useEffect, useState } from "react";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Volume2, BookOpen, Eye, Loader2 } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { useToast } from "@/hooks/use-toast";

type StoryRecord = {
  id: string;
  title: string;
  content: string;
  author_name: string | null;
  monument_id: string | null;
  monuments?: {
    title: string;
    location: string;
    era: string;
  } | null;
};

export const StoryPreview = () => {
  const navigate = useNavigate();
  const { toast } = useToast();
  const [audioLoading, setAudioLoading] = useState(false);
  const [story, setStory] = useState<StoryRecord | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchStory = async () => {
      setLoading(true);
      const { data, error } = await supabase
        .from('stories')
        .select('id, title, content, author_name, monument_id, monuments(title, location, era)')
        .eq('status', 'approved')
        .order('created_at', { ascending: false })
        .limit(1)
        .maybeSingle();

      if (error) {
        toast({
          title: 'Error loading stories',
          description: error.message,
          variant: 'destructive',
        });
      } else {
        setStory(data);
      }
      setLoading(false);
    };

    fetchStory();
  }, [toast]);

  const handleAudio = async (language: string) => {
    setAudioLoading(true);
    try {
      const text = story?.content || '';
      const { data, error } = await supabase.functions.invoke('text-to-speech', {
        body: { text, language }
      });

      if (error) throw error;

      if (data?.text) {
        toast({
          title: "Narration Generated",
          description: `${language === 'en' ? 'English' : 'Kannada'} narration: "${data.text.substring(0, 100)}..."`,
        });
      }
    } catch (error: any) {
      toast({
        title: "Error",
        description: error.message || "Failed to generate audio",
        variant: "destructive",
      });
    } finally {
      setAudioLoading(false);
    }
  };

  return (
    <section className="py-24 bg-muted/30">
      <div className="container mx-auto px-4">
        <div className="max-w-5xl mx-auto">
          <div className="text-center mb-12">
            <h2 className="text-4xl md:text-5xl font-bold text-foreground mb-4">
              AI-Powered Story Experience
            </h2>
            <p className="text-xl text-muted-foreground">
              Choose your preferred length and language for each folk story
            </p>
          </div>

          <Card className="p-8 border-0 shadow-monument bg-gradient-card">
            {loading && (
              <div className="flex items-center justify-center py-12 text-muted-foreground">
                <Loader2 className="h-5 w-5 animate-spin mr-2" /> Loading story...
              </div>
            )}

            {!loading && !story && (
              <div className="text-center py-12 text-muted-foreground">
                No stories available yet.
              </div>
            )}

            {!loading && story && (
              <>
                <div className="mb-6">
                  <div className="flex items-center justify-between mb-4">
                    <h3 className="text-2xl font-bold text-foreground">
                      {story.title}
                    </h3>
                    {story.monuments?.title ? (
                      <Badge className="bg-heritage-indigo text-heritage-cream">
                        {story.monuments.title}
                      </Badge>
                    ) : null}
                  </div>
                  <div className="flex flex-wrap gap-2 mb-6">
                    {story.monuments?.era ? (
                      <Badge variant="outline" className="border-heritage-gold text-heritage-terracotta">
                        {story.monuments.era}
                      </Badge>
                    ) : null}
                    {story.monuments?.location ? (
                      <Badge variant="outline" className="border-heritage-gold text-heritage-terracotta">
                        {story.monuments.location}
                      </Badge>
                    ) : null}
                    {story.author_name ? (
                      <Badge variant="outline" className="border-heritage-gold text-heritage-terracotta">
                        By {story.author_name}
                      </Badge>
                    ) : null}
                  </div>
                </div>

                <Tabs defaultValue="short" className="w-full">
                  <TabsList className="grid w-full grid-cols-3 mb-6">
                    <TabsTrigger value="short">Short (2 min)</TabsTrigger>
                    <TabsTrigger value="medium">Medium (5 min)</TabsTrigger>
                    <TabsTrigger value="detailed">Detailed (10 min)</TabsTrigger>
                  </TabsList>

                  <TabsContent value="short" className="space-y-4">
                    <div className="prose prose-lg max-w-none text-foreground whitespace-pre-line">
                      <p className="leading-relaxed">{story.content}</p>
                    </div>
                  </TabsContent>

                  <TabsContent value="medium" className="space-y-4">
                    <div className="prose prose-lg max-w-none text-foreground whitespace-pre-line">
                      <p className="leading-relaxed">{story.content}</p>
                    </div>
                  </TabsContent>

                  <TabsContent value="detailed" className="space-y-4">
                    <div className="prose prose-lg max-w-none text-foreground whitespace-pre-line">
                      <p className="leading-relaxed">{story.content}</p>
                    </div>
                  </TabsContent>
                </Tabs>

                <div className="flex flex-wrap gap-4 mt-8 pt-8 border-t border-border">
                  <Button 
                    onClick={() => handleAudio('en')}
                    disabled={audioLoading || loading || !story}
                    className="bg-heritage-terracotta hover:bg-heritage-terracotta/90 text-heritage-cream"
                  >
                    {audioLoading ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <Volume2 className="mr-2 h-4 w-4" />}
                    Listen in English
                  </Button>
                  <Button 
                    variant="outline" 
                    onClick={() => handleAudio('kn')}
                    disabled={audioLoading || loading || !story}
                    className="border-heritage-indigo text-heritage-indigo hover:bg-heritage-indigo/10"
                  >
                    {audioLoading ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <Volume2 className="mr-2 h-4 w-4" />}
                    ಕನ್ನಡದಲ್ಲಿ ಕೇಳಿ
                  </Button>
                  <Button 
                    variant="outline" 
                    onClick={() => navigate('/ar?monument=hampi')}
                    className="border-heritage-gold text-heritage-earth hover:bg-heritage-gold/10"
                  >
                    <Eye className="mr-2 h-4 w-4" />
                    View in AR
                  </Button>
                  <Button 
                    variant="outline" 
                    onClick={() => {
                      const el = document.getElementById('monuments');
                      el?.scrollIntoView({ behavior: 'smooth' });
                    }}
                    className="border-heritage-terracotta text-heritage-terracotta hover:bg-heritage-terracotta/10"
                  >
                    <BookOpen className="mr-2 h-4 w-4" />
                    Read More Stories
                  </Button>
                </div>
              </>
            )}
          </Card>
        </div>
      </div>
    </section>
  );
};
