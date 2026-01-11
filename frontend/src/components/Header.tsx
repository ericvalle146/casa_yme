import { Search, Menu, X } from "lucide-react";
import { useState } from "react";
import { Link } from "react-router-dom";
import logo from "../assets/logo-principal.png";
import { Button } from "./ui/button";
import AuthDialog from "./AuthDialog";
import UserProfileMenu from "./UserProfileMenu";
import { useAuth } from "@/context/AuthContext";

const Header = () => {
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [isAuthOpen, setIsAuthOpen] = useState(false);
  const { user, logout } = useAuth();

  const toggleMenu = () => setIsMenuOpen((prev) => !prev);

  const navItems = [
    { href: "/", label: "Início" },
    { href: "/#destaques", label: "Imóveis" },
    { href: "/#contato", label: "Contato" },
  ];

  return (
    <header className="fixed top-0 left-0 right-0 z-50 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/80 border-b border-border shadow-sm">
      <div className="container mx-auto px-4">
        <div className="flex items-center justify-between h-20">
          <Link to="/" className="flex items-center gap-2">
            <img src={logo} alt="Casa YME" className="h-8 w-8 object-contain" />
            <span className="text-2xl font-bold tracking-tight text-primary">Casa YME</span>
          </Link>
          
          <nav className="hidden md:flex items-center gap-6">
            {navItems.map((item) => (
              <a
                key={item.href}
                href={item.href}
                className="text-sm font-medium text-muted-foreground hover:text-primary transition-colors"
              >
                {item.label}
              </a>
            ))}
          </nav>

          <div className="flex items-center gap-3">
            {user ? (
              <div className="hidden md:flex items-center gap-3">
                <UserProfileMenu />
              </div>
            ) : (
              <Button
                variant="outline"
                className="hidden md:inline-flex"
                onClick={() => setIsAuthOpen(true)}
              >
                Entrar
              </Button>
            )}
            <Button
              className="hidden md:inline-flex bg-primary hover:bg-primary/90 text-white"
              onClick={() => {
                const contatoSection = document.getElementById('contato');
                if (contatoSection) {
                  contatoSection.scrollIntoView({ behavior: 'smooth' });
                }
              }}
            >
              Agendar Consultoria
            </Button>
            <Button variant="ghost" size="icon" className="md:hidden" onClick={toggleMenu} aria-label="Abrir menu">
              {isMenuOpen ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
            </Button>
          </div>
        </div>
      </div>
      {isMenuOpen && (
        <div className="md:hidden border-t border-border bg-background/98 backdrop-blur">
          <nav className="container mx-auto px-4 py-6">
            <ul className="space-y-4 text-sm font-medium text-muted-foreground">
              {navItems.map((item) => (
                <li key={item.href}>
                  <a
                    href={item.href}
                    className="block hover:text-primary transition-colors"
                    onClick={() => setIsMenuOpen(false)}
                  >
                    {item.label}
                  </a>
                </li>
              ))}
              <li>
                <Button
                  className="w-full bg-primary hover:bg-primary/90 text-white"
                  onClick={() => {
                    setIsMenuOpen(false);
                    const contatoSection = document.getElementById('contato');
                    if (contatoSection) {
                      contatoSection.scrollIntoView({ behavior: 'smooth' });
                    }
                  }}
                >
                  Agendar Consultoria
                </Button>
              </li>
              {user && (
                <li>
                  <Button asChild variant="outline" className="w-full">
                    <Link to="/admin">Adicionar imoveis</Link>
                  </Button>
                </li>
              )}
              <li>
                {user ? (
                  <Button
                    variant="outline"
                    className="w-full"
                    onClick={() => {
                      setIsMenuOpen(false);
                      logout();
                    }}
                  >
                    Sair
                  </Button>
                ) : (
                  <Button
                    variant="outline"
                    className="w-full"
                    onClick={() => {
                      setIsMenuOpen(false);
                      setIsAuthOpen(true);
                    }}
                  >
                    Entrar
                  </Button>
                )}
              </li>
            </ul>
          </nav>
        </div>
      )}
      <AuthDialog open={isAuthOpen} onOpenChange={setIsAuthOpen} />
    </header>
  );
};

export default Header;
