import { Link } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Home } from "lucide-react";

interface BackToHomeProps {
  className?: string;
}

export const BackToHome = ({ className = "" }: BackToHomeProps) => {
  return (
    <Link to="/" className={className}>
      <Button variant="outline" size="sm" className="gap-2">
        <Home className="w-4 h-4" />
        Back to Home
      </Button>
    </Link>
  );
};
