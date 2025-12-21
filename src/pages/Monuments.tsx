import { Navbar } from "@/components/Navbar";
import { Footer } from "@/components/Footer";
import { MonumentGallery } from "@/components/MonumentGallery";
import { BackToHome } from "@/components/BackToHome";

const Monuments = () => {
  return (
    <div className="min-h-screen">
      <Navbar />
      <main className="pt-16">
        <div className="container mx-auto px-4 py-4">
          <BackToHome />
        </div>
        <MonumentGallery />
      </main>
      <Footer />
    </div>
  );
};

export default Monuments;