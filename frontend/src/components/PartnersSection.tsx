const partners = [
  "Grupo Skyline",
  "Casa & Forma",
  "Refulgence Capital",
  "Urban Works",
  "Mosaico Incorporadora",
  "Prime Corporate",
];

const PartnersSection = () => (
  <section className="py-16 bg-background">
    <div className="container mx-auto px-4">
      <div className="text-center mb-10">
        <p className="uppercase text-xs tracking-[0.4em] text-primary font-semibold">
          Alianças estratégicas
        </p>
        <h3 className="mt-3 text-lg text-muted-foreground">
          Conectados às principais incorporadoras, escritórios e fundos de investimento do país.
        </h3>
      </div>
      <div className="flex flex-wrap items-center justify-center gap-6 md:gap-10 text-sm uppercase tracking-[0.4em] text-muted-foreground">
        {partners.map((partner) => (
          <span
            key={partner}
            className="px-6 py-3 border border-dashed border-border/80 rounded-full hover:text-primary hover:border-primary/60 transition-colors"
          >
            {partner}
          </span>
        ))}
      </div>
    </div>
  </section>
);

export default PartnersSection;


