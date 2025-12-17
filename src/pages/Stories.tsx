import { Navbar } from "@/components/Navbar";
import { Footer } from "@/components/Footer";
import { StoryPreview } from "@/components/StoryPreview";

const Stories = () => {
  return (
    <div className="min-h-screen">
      <Navbar />
      <main className="pt-16">
        <StoryPreview />
      </main>
      <Footer />
    </div>
  );
};

export default Stories;