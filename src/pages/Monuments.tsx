import { Navbar } from "@/components/Navbar";
import { Footer } from "@/components/Footer";
import { MonumentGallery } from "@/components/MonumentGallery";

const Monuments = () => {
  return (
    <div className="min-h-screen">
      <Navbar />
      <main className="pt-16">
        <MonumentGallery />
      </main>
      <Footer />
    </div>
  );
};

export default Monuments;