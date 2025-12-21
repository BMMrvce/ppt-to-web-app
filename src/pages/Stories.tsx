import { Navbar } from "@/components/Navbar";
import { Footer } from "@/components/Footer";
import { StoryPreview } from "@/components/StoryPreview";
import { BackToHome } from "@/components/BackToHome";

const Stories = () => {
  return (
    <div className="min-h-screen">
      <Navbar />
      <main className="pt-16">
        <div className="container mx-auto px-4 py-4">
          <BackToHome />
        </div>
        <StoryPreview />
      </main>
      <Footer />
    </div>
  );
};

export default Stories;