export type TransactionType = "VENDA" | "ALUGUEL";

export interface Property {
  id: number;
  image: string;
  title: string;
  type: string;
  transaction: TransactionType;
  price: number;
  bedrooms: number;
  bathrooms: number;
  area: number;
  neighborhood: string;
  city: string;
  state: string;
  description: string;
  amenities: string[];
  gallery: { url: string; alt: string }[];
}

export const properties: Property[] = [
  {
    id: 1,
    image:
      "https://resizedimgs.vivareal.com/img/vr-listing/26da475ce459f7e741c1c648dc7c1bac/casa-de-condominio-com-4-quartos-a-venda-815m-no-residencial-porto-seguro-caratinga.webp?action=fit-in&dimension=870x707",
    title: "Complexo Residencial Recanto dos Pássaros",
    type: "Casa",
    transaction: "VENDA",
    price: 3300000,
    bedrooms: 4,
    bathrooms: 5,
    area: 815,
    neighborhood: "Recanto dos Pássaros",
    city: "Caratinga",
    state: "MG",
    description:
      "Casa de condomínio com 815 m² de área construída inserida em terreno de 10.000 m², composta por sete ambientes integrados, duas casas auxiliares, área gourmet completa, mirante e lazer completo próximo ao Clube dos Médicos em Porto Seguro.",
    amenities: [
      "Piscina",
      "Espaço Gourmet",
      "Quintal",
      "Ambientes integrados",
      "Banheira",
      "Ar-condicionado",
      "Condomínio fechado",
      "Condomínio sustentável",
      "Área de lazer",
      "20 vagas",
    ],
    gallery: [
      {
        url: "https://resizedimgs.vivareal.com/img/vr-listing/ca3ed9d51369d963c1a550efd586eefb/casa-de-condominio-com-4-quartos-a-venda-815m-no-residencial-porto-seguro-caratinga.webp?action=fit-in&dimension=870x707",
        alt: "Área de lazer com piscina e deck",
      },
      {
        url: "https://resizedimgs.vivareal.com/img/vr-listing/4deb718a87b8572994911dc8b2b1d27f/casa-de-condominio-com-4-quartos-a-venda-815m-no-residencial-porto-seguro-caratinga.webp?action=fit-in&dimension=870x707",
        alt: "Entrada principal com arquitetura contemporânea",
      },
      {
        url: "https://resizedimgs.vivareal.com/img/vr-listing/453e456b0d075becceb8cb422cf1d355/casa-de-condominio-com-4-quartos-a-venda-815m-no-residencial-porto-seguro-caratinga.webp?action=fit-in&dimension=870x707",
        alt: "Copa integrada à sala",
      },
      {
        url: "https://resizedimgs.vivareal.com/img/vr-listing/634c4c068d16ec16ff92bfa3a7a43ec9/casa-de-condominio-com-4-quartos-a-venda-815m-no-residencial-porto-seguro-caratinga.webp?action=fit-in&dimension=870x707",
        alt: "Área verde com pomar",
      },
      {
        url: "https://resizedimgs.vivareal.com/img/vr-listing/c37e8d6e0ce432593dc9705769726bd0/casa-de-condominio-com-4-quartos-a-venda-815m-no-residencial-porto-seguro-caratinga.webp?action=fit-in&dimension=870x707",
        alt: "Espaço gourmet com churrasqueira",
      },
      {
        url: "https://resizedimgs.vivareal.com/img/vr-listing/e5fc9e96ba60c2cd8f9a5259f932e990/casa-de-condominio-com-4-quartos-a-venda-815m-no-residencial-porto-seguro-caratinga.webp?action=fit-in&dimension=870x707",
        alt: "Banheiro com acabamento em mármore",
      },
    ],
  },
  {
    id: 2,
    image:
      "https://resizedimgs.vivareal.com/img/vr-listing/5b43a24e6accebd01c636e0a24115f6b/loteterreno-a-venda-1001m-no-centro-caratinga.webp?action=fit-in&dimension=870x707",
    title: "Loteamento Lagoa Silvania",
    type: "Terreno",
    transaction: "VENDA",
    price: 620000,
    bedrooms: 0,
    bathrooms: 0,
    area: 1001,
    neighborhood: "Centro",
    city: "Caratinga",
    state: "MG",
    description:
      "Lote de 1.001 m² no condomínio Lagoa Silvania com projeto autoral de Nicolas Kilaris, infraestrutura completa e comodidades de alto padrão como piscinas, quadra esportiva, sauna, academia, salão de festas e monitoramento 24 horas.",
    amenities: [
      "Piscinas",
      "Churrasqueira",
      "Quadra esportiva",
      "Sauna",
      "Espaço kids",
      "Academia",
      "Salão de festas",
      "CFTV 24h",
      "Condomínio fechado",
    ],
    gallery: [
      {
        url: "https://resizedimgs.vivareal.com/img/vr-listing/9037f02d01a6e3df3d2513fc07efba0e/loteterreno-a-venda-1001m-no-centro-caratinga.webp?action=fit-in&dimension=870x707",
        alt: "Vista posterior do loteamento",
      },
      {
        url: "https://resizedimgs.vivareal.com/img/vr-listing/4e4fc4fb3182b1fbbfb1b2867b2be66f/loteterreno-a-venda-1001m-no-centro-caratinga.webp?action=fit-in&dimension=870x707",
        alt: "Fachada principal com acesso",
      },
      {
        url: "https://resizedimgs.vivareal.com/img/vr-listing/31a518ffcebe340cf4c59b03215b2702/loteterreno-a-venda-1001m-no-centro-caratinga.webp?action=fit-in&dimension=870x707",
        alt: "Piscina do condomínio Lagoa Silvania",
      },
      {
        url: "https://resizedimgs.vivareal.com/img/vr-listing/0c1833cf1d39f593f7bec705520f7d10/loteterreno-a-venda-1001m-no-centro-caratinga.webp?action=fit-in&dimension=870x707",
        alt: "Área de lazer com pergolado",
      },
      {
        url: "https://resizedimgs.vivareal.com/img/vr-listing/f33c9028ff4a71473927909d05c8cd92/loteterreno-a-venda-1001m-no-centro-caratinga.webp?action=fit-in&dimension=870x707",
        alt: "Acesso principal com guarita",
      },
    ],
  },
  {
    id: 3,
    image:
      "https://resizedimgs.vivareal.com/img/vr-listing/deb233d0d84c24b460566a253ec32f0e/casa-com-4-quartos-a-venda-380m-no-residencial-porto-seguro-caratinga.webp?action=fit-in&dimension=870x707",
    title: "Chácara Duplex Porto Seguro",
    type: "Casa",
    transaction: "VENDA",
    price: 2000000,
    bedrooms: 4,
    bathrooms: 5,
    area: 380,
    neighborhood: "Residencial Porto Seguro",
    city: "Caratinga",
    state: "MG",
    description:
      "Chácara urbana com casa duplex, pomar formado e projetos elétrico/hidráulico executados. Primeiro pavimento com suíte, cozinha gourmet, varanda para o pomar e garagem; segundo pavimento com três suítes e sacadas, sendo uma delas com closet.",
    amenities: [
      "Área gourmet",
      "Pomar",
      "Varanda",
      "Lavabo",
      "Lavanderia",
      "Closet",
      "Portão eletrônico",
    ],
    gallery: [
      {
        url: "https://resizedimgs.vivareal.com/img/vr-listing/5fe05513a143e0c294ce52a1633f5388/casa-com-4-quartos-a-venda-380m-no-residencial-porto-seguro-caratinga.webp?action=fit-in&dimension=870x707",
        alt: "Vista posterior com pomar e gramado",
      },
      {
        url: "https://resizedimgs.vivareal.com/img/vr-listing/07bf74b41593a0f111628b599eb0bc18/casa-com-4-quartos-a-venda-380m-no-residencial-porto-seguro-caratinga.webp?action=fit-in&dimension=870x707",
        alt: "Sala integrada à área gourmet",
      },
      {
        url: "https://resizedimgs.vivareal.com/img/vr-listing/deb233d0d84c24b460566a253ec32f0e/casa-com-4-quartos-a-venda-380m-no-residencial-porto-seguro-caratinga.webp?action=fit-in&dimension=870x707",
        alt: "Fachada principal com dois pavimentos",
      },
    ],
  },
  {
    id: 4,
    image:
      "https://resizedimgs.vivareal.com/img/vr-listing/b17f5d3e18f5ea20d66636f8c9ba4b55/casa-de-condominio-com-3-quartos-a-venda-266m-no-ilha-do-rio-doce-caratinga.webp?action=fit-in&dimension=870x707",
    title: "Casa Lagoa Silvana Premium",
    type: "Casa",
    transaction: "VENDA",
    price: 2800000,
    bedrooms: 3,
    bathrooms: 3,
    area: 266,
    neighborhood: "Lagoa Silvana",
    city: "Caratinga",
    state: "MG",
    description:
      "Casa duplex de 266 m² no condomínio Parque Lagoa Silvana com design contemporâneo, acabamentos de alto padrão e áreas integradas para receber com conforto em condomínio fechado com lazer completo.",
    amenities: [
      "Piscina",
      "Espaço gourmet",
      "Sala integrada",
      "Varandas",
      "3 suítes",
      "Garagem para 3 carros",
      "Condomínio fechado",
    ],
    gallery: [
      {
        url: "https://resizedimgs.vivareal.com/img/vr-listing/73744365f49abb028ac0d961d6641df4/casa-de-condominio-com-3-quartos-a-venda-266m-no-ilha-do-rio-doce-caratinga.webp?action=fit-in&dimension=870x707",
        alt: "Living principal com pé-direito duplo",
      },
      {
        url: "https://resizedimgs.vivareal.com/img/vr-listing/a0c09d655b386737d8353ccb7c6f06e9/casa-de-condominio-com-3-quartos-a-venda-266m-no-ilha-do-rio-doce-caratinga.webp?action=fit-in&dimension=870x707",
        alt: "Copa integrada à cozinha",
      },
      {
        url: "https://resizedimgs.vivareal.com/img/vr-listing/c43d5cf2e03d82e116b5da9ae179d8f3/casa-de-condominio-com-3-quartos-a-venda-266m-no-ilha-do-rio-doce-caratinga.webp?action=fit-in&dimension=870x707",
        alt: "Piscina com deck em madeira",
      },
      {
        url: "https://resizedimgs.vivareal.com/img/vr-listing/cb962c1449d6d6f36bbed61184c21953/casa-de-condominio-com-3-quartos-a-venda-266m-no-ilha-do-rio-doce-caratinga.webp?action=fit-in&dimension=870x707",
        alt: "Fachada lateral com brises",
      },
    ],
  },
  {
    id: 5,
    image: "https://images.unsplash.com/photo-1505691938895-1758d7feb511?auto=format&fit=crop&w=1600&q=80",
    title: "Casa Atlântico Mirage",
    type: "Casa",
    transaction: "VENDA",
    price: 11800000,
    bedrooms: 5,
    bathrooms: 6,
    area: 720,
    neighborhood: "Joatinga",
    city: "Rio de Janeiro",
    state: "RJ",
    description:
      "Residência esculpida em encosta com fachada envidraçada e vista permanente para o mar. Ambientes integrados, piscina de borda infinita, spa panorâmico e acabamento em pedra natural e madeira nobre.",
    amenities: [
      "Piscina",
      "Spa",
      "Varanda",
      "Cinema",
      "Heliponto",
    ],
    gallery: [
      {
        url: "https://images.unsplash.com/photo-1505691723518-36a5ac3be353?auto=format&fit=crop&w=1600&q=80",
        alt: "Piscina com borda infinita voltada ao oceano",
      },
      {
        url: "https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1600&q=80",
        alt: "Sala de estar com vista panorâmica para o mar",
      },
      {
        url: "https://images.unsplash.com/photo-1449844908441-8829872d2607?auto=format&fit=crop&w=1600&q=80",
        alt: "Suíte master minimalista com vista para o horizonte",
      },
    ],
  },
  {
    id: 6,
    image: "https://images.unsplash.com/photo-1502005097973-6a7082348e28?auto=format&fit=crop&w=1600&q=80",
    title: "Villa Brisa Mediterrânea",
    type: "Casa",
    transaction: "ALUGUEL",
    price: 26000,
    bedrooms: 4,
    bathrooms: 5,
    area: 540,
    neighborhood: "Ferradura",
    city: "Armação dos Búzios",
    state: "RJ",
    description:
      "Villa litorânea em estilo mediterrâneo com piscina aquecida, gazebo gourmet e ambientes abertos para o jardim. Ideal para temporadas premium com serviço de concierge completo.",
    amenities: [
      "Piscina aquecida",
      "Gazebo",
      "Concierge",
      "Pier",
      "Academia",
    ],
    gallery: [
      {
        url: "https://images.unsplash.com/photo-1502005097973-6a7082348e28?auto=format&fit=crop&w=1600&q=80",
        alt: "Vista externa da villa com arquitetura mediterrânea",
      },
      {
        url: "https://images.unsplash.com/photo-1560448075-bb485b067938?auto=format&fit=crop&w=1600&q=80",
        alt: "Sala envidraçada integrada ao deck externo",
      },
      {
        url: "https://images.unsplash.com/photo-1499916078039-922301b0eb9b?auto=format&fit=crop&w=1600&q=80",
        alt: "Suíte com decoração clara e acolhedora",
      },
      {
        url: "https://images.unsplash.com/photo-1522156373667-4c7234bbd804?auto=format&fit=crop&w=1600&q=80",
        alt: "Espaço gourmet sob pergolado voltado ao mar",
      },
    ],
  },
  {
    id: 7,
    image: "https://images.unsplash.com/photo-1515260268569-9271009adfdb?auto=format&fit=crop&w=1600&q=80",
    title: "Chácara Vale Verde Signature",
    type: "Casa",
    transaction: "VENDA",
    price: 5600000,
    bedrooms: 4,
    bathrooms: 5,
    area: 500,
    neighborhood: "Vale Verde",
    city: "Itatiaia",
    state: "RJ",
    description:
      "Chácara contemporânea integrada à natureza com sala envidraçada, lareira em pedra, lago ornamental e casa de hóspedes independente. Perfeita para quem busca privacidade e bem-estar na serra.",
    amenities: [
      "Lago",
      "Adega",
      "Lareira",
      "Casa de hóspedes",
      "Heliponto",
    ],
    gallery: [
      {
        url: "https://images.unsplash.com/photo-1515260268569-9271009adfdb?auto=format&fit=crop&w=1600&q=80",
        alt: "Fachada da chácara com arquitetura contemporânea",
      },
      {
        url: "https://images.unsplash.com/photo-1464890100898-a385f744067f?auto=format&fit=crop&w=1600&q=80",
        alt: "Lago ornamental ao entardecer",
      },
      {
        url: "https://images.unsplash.com/photo-1444418776041-9c7e33cc5a9c?auto=format&fit=crop&w=1600&q=80",
        alt: "Sala com lareira em pedra natural",
      },
      {
        url: "https://images.unsplash.com/photo-1487956382158-bb926046304a?auto=format&fit=crop&w=1600&q=80",
        alt: "Piscina interna aquecida com vista para a mata",
      },
    ],
  },
  {
    id: 8,
    image: "https://images.unsplash.com/photo-1505691723518-36a5ac3be353?auto=format&fit=crop&w=1600&q=80",
    title: "Casa Vista das Dunas",
    type: "Casa",
    transaction: "ALUGUEL",
    price: 21000,
    bedrooms: 4,
    bathrooms: 5,
    area: 450,
    neighborhood: "Praia do Preá",
    city: "Cruz",
    state: "CE",
    description:
      "Casa de praia minimalista com piscina em prainha, varanda com redes e espaços abertos integrados à paisagem das dunas. Ideal para temporadas de kitesurf e descanso.",
    amenities: [
      "Piscina com prainha",
      "Terraço",
      "Forno a lenha",
      "Depósito de kitesurf",
      "Serviço de praia",
    ],
    gallery: [
      {
        url: "https://images.unsplash.com/photo-1493663284031-b7e3aefcae8e?auto=format&fit=crop&w=1600&q=80",
        alt: "Varanda com redes voltada às dunas",
      },
      {
        url: "https://images.unsplash.com/photo-1479839672679-a46483c0e7c8?auto=format&fit=crop&w=1600&q=80",
        alt: "Piscina iluminada ao pôr do sol",
      },
      {
        url: "https://images.unsplash.com/photo-1505691723518-36a5ac3be353?auto=format&fit=crop&w=1600&q=80",
        alt: "Área gourmet externa com forno a lenha",
      },
    ],
  },
];

export const formatCurrency = (value: number) =>
  new Intl.NumberFormat("pt-BR", {
    style: "currency",
    currency: "BRL",
    minimumFractionDigits: 0,
  }).format(value);

