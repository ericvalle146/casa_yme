import type { ReactNode } from "react";
import { Badge } from "./ui/badge";

interface HeroProps {
  renderSearchForm: () => ReactNode;
}

const Hero = ({ renderSearchForm }: HeroProps) => {
  return (
    <section id="inicio" className="relative min-h-[95vh] flex items-center justify-center pt-20">
      <div className="absolute inset-0 overflow-hidden">
        <video
          className="absolute inset-0 h-full w-full object-cover"
          autoPlay
          muted
          loop
          playsInline
          aria-hidden="true"
        >
          <source src="/video_fundo.mp4" type="video/mp4" />
        </video>
        <div className="absolute inset-0 bg-gradient-to-r from-hero-overlay/55 via-hero-overlay/40 to-hero-overlay/25" />
      </div>

      <div className="relative z-10 w-full">
        <div className="container mx-auto px-4 py-12 lg:py-24 flex flex-col lg:flex-row items-center gap-12">
          <div className="w-full lg:w-1/2 text-white text-left space-y-8">
            <Badge className="bg-white/15 backdrop-blur text-white px-4 py-2 text-xs uppercase tracking-[0.2em]">
              Consultoria imobiliária premium
            </Badge>
            <div>
              <h1 className="text-4xl md:text-5xl xl:text-6xl font-semibold leading-tight tracking-tight">
                Conectamos pessoas a imóveis singulares com excelência e discrição.
              </h1>
              <p className="mt-6 text-lg md:text-xl text-white/90 leading-relaxed max-w-xl">
                Há mais de 15 anos assessorando famílias, investidores e empresas na aquisição e locação de
                patrimônios imobiliários exclusivos, com curadoria criteriosa e atendimento personalizado.
              </p>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-6 text-white/80 text-sm">
              <div className="border-t border-white/30 pt-4 space-y-1">
                <strong className="block text-3xl text-white font-semibold mb-1">1.200+</strong>
                <span>Imóveis assessorados</span>
              </div>
              <div className="border-t border-white/30 pt-4 space-y-1">
                <strong className="block text-3xl text-white font-semibold mb-1">98%</strong>
                <span>Satisfação dos clientes</span>
              </div>
              <div className="border-t border-white/30 pt-4 space-y-1">
                <strong className="block text-3xl text-white font-semibold mb-1">15 anos</strong>
                <span>De atuação premium</span>
              </div>
            </div>
          </div>

          <div className="w-full lg:w-1/2">{renderSearchForm()}</div>
        </div>
      </div>
    </section>
  );
};

export default Hero;
