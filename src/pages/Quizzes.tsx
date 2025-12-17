import { Navbar } from "@/components/Navbar";
import { Footer } from "@/components/Footer";
import { GameSection } from "@/components/GameSection";

const Quizzes = () => {
  return (
    <div className="min-h-screen">
      <Navbar />
      <main className="pt-16">
        <GameSection />
      </main>
      <Footer />
    </div>
  );
};

export default Quizzes;