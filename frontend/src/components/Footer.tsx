import { Phone, Mail, MapPin, Facebook, Instagram, Linkedin, ArrowUpRight } from "lucide-react";
import logo from "../assets/logo-principal.png";
import { Input } from "./ui/input";
import { Button } from "./ui/button";

const Footer = () => {
  return (
    <footer className="bg-gradient-to-b from-hero-overlay via-hero-overlay to-black text-white">
      <div className="container mx-auto px-4 py-16">
        <div className="grid grid-cols-1 lg:grid-cols-5 gap-10 mb-16">
          <div className="lg:col-span-2 space-y-6">
            <div className="flex items-center gap-3">
              <img src={logo} alt="Casa YME" className="h-9 w-9 object-contain" />
              <div>
                <span className="text-3xl font-semibold tracking-tight">Casa YME</span>
                <p className="text-white/60 text-xs uppercase tracking-[0.2em]">Consultoria imobiliária</p>
              </div>
            </div>
            <p className="text-white/80 leading-relaxed max-w-md">
              Conectamos pessoas, empresas e investimentos a patrimônios imobiliários exclusivos, com
              confidencialidade, expertise técnica e atendimento personalizado.
            </p>
            <div className="flex gap-4">
              <a href="#" className="hover:text-accent transition-colors">
                <Facebook className="h-5 w-5" />
              </a>
              <a href="#" className="hover:text-accent transition-colors">
                <Instagram className="h-5 w-5" />
              </a>
              <a href="#" className="hover:text-accent transition-colors">
                <Linkedin className="h-5 w-5" />
              </a>
            </div>
          </div>

          <div>
            <h3 className="text-lg font-semibold mb-4 uppercase tracking-[0.2em] text-white">Mapa</h3>
            <ul className="space-y-3 text-white/70">
              <li>
                <a href="#inicio" className="hover:text-accent transition-colors inline-flex items-center gap-2">
                  Início <ArrowUpRight className="h-4 w-4" />
                </a>
              </li>
              <li>
                <a href="#destaques" className="hover:text-accent transition-colors inline-flex items-center gap-2">
                  Imóveis em destaque <ArrowUpRight className="h-4 w-4" />
                </a>
              </li>
              <li>
                <a href="#servicos" className="hover:text-accent transition-colors inline-flex items-center gap-2">
                  Serviços <ArrowUpRight className="h-4 w-4" />
                </a>
              </li>
              <li>
                <a href="#depoimentos" className="hover:text-accent transition-colors inline-flex items-center gap-2">
                  Depoimentos <ArrowUpRight className="h-4 w-4" />
                </a>
              </li>
              <li>
                <a href="#contato" className="hover:text-accent transition-colors inline-flex items-center gap-2">
                  Contato <ArrowUpRight className="h-4 w-4" />
                </a>
              </li>
            </ul>
          </div>

          <div>
            <h3 className="text-lg font-semibold mb-4 uppercase tracking-[0.2em] text-white">Serviços</h3>
            <ul className="space-y-3 text-white/70">
              <li>
                <a href="#servicos" className="hover:text-accent transition-colors">
                  Assessoria de compra e venda
                </a>
              </li>
              <li>
                <a href="#servicos" className="hover:text-accent transition-colors">
                  Gestão de portfólio
                </a>
              </li>
              <li>
                <a href="#servicos" className="hover:text-accent transition-colors">
                  Consultoria corporativa
                </a>
              </li>
              <li>
                <a href="#servicos" className="hover:text-accent transition-colors">
                  Experiência concierge
                </a>
              </li>
            </ul>
          </div>

          <div>
            <h3 className="text-lg font-semibold mb-4 uppercase tracking-[0.2em] text-white">Contato</h3>
            <ul className="space-y-3 text-white/80">
              <li className="flex items-start gap-2">
                <MapPin className="h-5 w-5 mt-0.5 flex-shrink-0" />
                <span>
                  Rua Exemplo, 123 - Centro
                  <br />
                  São Paulo - SP
                </span>
              </li>
              <li className="flex items-center gap-2">
                <Phone className="h-5 w-5 flex-shrink-0" />
                <span>(11) 3333-4444</span>
              </li>
              <li className="flex items-center gap-2">
                <Mail className="h-5 w-5 flex-shrink-0" />
                <span>contato@casayme.com.br</span>
              </li>
            </ul>
          </div>
        </div>

        <div className="border-t border-white/15 pt-10 mt-10 flex flex-col lg:flex-row lg:items-center lg:justify-between gap-6">
          <div className="w-full lg:w-1/2">
            <p className="text-xs uppercase tracking-[0.2em] text-white/60 mb-3">
              Receba briefings exclusivos
            </p>
            <div className="flex flex-col sm:flex-row gap-3">
              <Input
                placeholder="Digite seu e-mail corporativo"
                className="bg-white/10 border-white/20 text-white placeholder:text-white/60"
              />
              <Button className="bg-accent hover:bg-accent/90 text-white px-6 uppercase tracking-[0.3em]">
                Inscrever
              </Button>
            </div>
          </div>
          <div className="text-white/60 text-sm">
            <p>&copy; {new Date().getFullYear()} Casa YME. Todos os direitos reservados.</p>
            <p className="mt-2">CRECI: 12345-J • Política de Privacidade • Termos de Uso</p>
          </div>
        </div>
      </div>
    </footer>
  );
};

export default Footer;
