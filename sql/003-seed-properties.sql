-- Ajuste o e-mail abaixo para o usuario administrador que criara os imoveis.
-- Se nao existir, nenhum insert sera executado.

WITH admin AS (
  SELECT id FROM users WHERE email = 'teste.casa_yme@gmail.com' LIMIT 1
), new_property AS (
  INSERT INTO properties (
    title,
    type,
    transaction,
    price,
    bedrooms,
    bathrooms,
    area,
    neighborhood,
    city,
    state,
    description,
    amenities,
    created_by
  )
  SELECT
    'Complexo Residencial Recanto dos Passaros',
    'Casa',
    'VENDA',
    3300000,
    4,
    5,
    815,
    'Recanto dos Passaros',
    'Caratinga',
    'MG',
    'Casa de condominio com 815 m2 de area construida em terreno de 10000 m2, com ambientes integrados, casas auxiliares e lazer completo.',
    ARRAY[
      'Piscina',
      'Espaco Gourmet',
      'Quintal',
      'Ambientes integrados',
      'Banheira',
      'Ar-condicionado',
      'Condominio fechado',
      'Condominio sustentavel',
      'Area de lazer',
      '20 vagas'
    ],
    admin.id
  FROM admin
  RETURNING id
)
INSERT INTO property_media (property_id, url, alt, position, is_cover)
SELECT id, 'https://resizedimgs.vivareal.com/img/vr-listing/ca3ed9d51369d963c1a550efd586eefb/casa-de-condominio-com-4-quartos-a-venda-815m-no-residencial-porto-seguro-caratinga.webp?action=fit-in&dimension=870x707', 'Area de lazer com piscina e deck', 0, true FROM new_property
UNION ALL
SELECT id, 'https://resizedimgs.vivareal.com/img/vr-listing/4deb718a87b8572994911dc8b2b1d27f/casa-de-condominio-com-4-quartos-a-venda-815m-no-residencial-porto-seguro-caratinga.webp?action=fit-in&dimension=870x707', 'Entrada principal com arquitetura contemporanea', 1, false FROM new_property
UNION ALL
SELECT id, 'https://resizedimgs.vivareal.com/img/vr-listing/453e456b0d075becceb8cb422cf1d355/casa-de-condominio-com-4-quartos-a-venda-815m-no-residencial-porto-seguro-caratinga.webp?action=fit-in&dimension=870x707', 'Copa integrada a sala', 2, false FROM new_property
UNION ALL
SELECT id, 'https://resizedimgs.vivareal.com/img/vr-listing/634c4c068d16ec16ff92bfa3a7a43ec9/casa-de-condominio-com-4-quartos-a-venda-815m-no-residencial-porto-seguro-caratinga.webp?action=fit-in&dimension=870x707', 'Area verde com pomar', 3, false FROM new_property
UNION ALL
SELECT id, 'https://resizedimgs.vivareal.com/img/vr-listing/c37e8d6e0ce432593dc9705769726bd0/casa-de-condominio-com-4-quartos-a-venda-815m-no-residencial-porto-seguro-caratinga.webp?action=fit-in&dimension=870x707', 'Espaco gourmet com churrasqueira', 4, false FROM new_property
UNION ALL
SELECT id, 'https://resizedimgs.vivareal.com/img/vr-listing/e5fc9e96ba60c2cd8f9a5259f932e990/casa-de-condominio-com-4-quartos-a-venda-815m-no-residencial-porto-seguro-caratinga.webp?action=fit-in&dimension=870x707', 'Banheiro com acabamento em marmore', 5, false FROM new_property;

WITH admin AS (
  SELECT id FROM users WHERE email = 'teste.casa_yme@gmail.com' LIMIT 1
), new_property AS (
  INSERT INTO properties (
    title,
    type,
    transaction,
    price,
    bedrooms,
    bathrooms,
    area,
    neighborhood,
    city,
    state,
    description,
    amenities,
    created_by
  )
  SELECT
    'Loteamento Lagoa Silvania',
    'Terreno',
    'VENDA',
    620000,
    0,
    0,
    1001,
    'Centro',
    'Caratinga',
    'MG',
    'Lote de 1001 m2 no condominio Lagoa Silvania com infraestrutura completa e lazer premium.',
    ARRAY[
      'Piscinas',
      'Churrasqueira',
      'Quadra esportiva',
      'Sauna',
      'Espaco kids',
      'Academia',
      'Salao de festas',
      'CFTV 24h',
      'Condominio fechado'
    ],
    admin.id
  FROM admin
  RETURNING id
)
INSERT INTO property_media (property_id, url, alt, position, is_cover)
SELECT id, 'https://resizedimgs.vivareal.com/img/vr-listing/9037f02d01a6e3df3d2513fc07efba0e/loteterreno-a-venda-1001m-no-centro-caratinga.webp?action=fit-in&dimension=870x707', 'Vista posterior do loteamento', 0, true FROM new_property
UNION ALL
SELECT id, 'https://resizedimgs.vivareal.com/img/vr-listing/4e4fc4fb3182b1fbbfb1b2867b2be66f/loteterreno-a-venda-1001m-no-centro-caratinga.webp?action=fit-in&dimension=870x707', 'Fachada principal com acesso', 1, false FROM new_property
UNION ALL
SELECT id, 'https://resizedimgs.vivareal.com/img/vr-listing/31a518ffcebe340cf4c59b03215b2702/loteterreno-a-venda-1001m-no-centro-caratinga.webp?action=fit-in&dimension=870x707', 'Piscina do condominio Lagoa Silvania', 2, false FROM new_property
UNION ALL
SELECT id, 'https://resizedimgs.vivareal.com/img/vr-listing/0c1833cf1d39f593f7bec705520f7d10/loteterreno-a-venda-1001m-no-centro-caratinga.webp?action=fit-in&dimension=870x707', 'Area de lazer com pergolado', 3, false FROM new_property
UNION ALL
SELECT id, 'https://resizedimgs.vivareal.com/img/vr-listing/f33c9028ff4a71473927909d05c8cd92/loteterreno-a-venda-1001m-no-centro-caratinga.webp?action=fit-in&dimension=870x707', 'Acesso principal com guarita', 4, false FROM new_property;

WITH admin AS (
  SELECT id FROM users WHERE email = 'teste.casa_yme@gmail.com' LIMIT 1
), new_property AS (
  INSERT INTO properties (
    title,
    type,
    transaction,
    price,
    bedrooms,
    bathrooms,
    area,
    neighborhood,
    city,
    state,
    description,
    amenities,
    created_by
  )
  SELECT
    'Chacara Duplex Porto Seguro',
    'Casa',
    'VENDA',
    2000000,
    4,
    5,
    380,
    'Residencial Porto Seguro',
    'Caratinga',
    'MG',
    'Chacara urbana com casa duplex, pomar formado e ambientes integrados. Suites com sacadas e closet.',
    ARRAY[
      'Area gourmet',
      'Pomar',
      'Varanda',
      'Lavabo',
      'Lavanderia',
      'Closet',
      'Portao eletronico'
    ],
    admin.id
  FROM admin
  RETURNING id
)
INSERT INTO property_media (property_id, url, alt, position, is_cover)
SELECT id, 'https://resizedimgs.vivareal.com/img/vr-listing/5fe05513a143e0c294ce52a1633f5388/casa-com-4-quartos-a-venda-380m-no-residencial-porto-seguro-caratinga.webp?action=fit-in&dimension=870x707', 'Vista posterior com pomar e gramado', 0, true FROM new_property
UNION ALL
SELECT id, 'https://resizedimgs.vivareal.com/img/vr-listing/07bf74b41593a0f111628b599eb0bc18/casa-com-4-quartos-a-venda-380m-no-residencial-porto-seguro-caratinga.webp?action=fit-in&dimension=870x707', 'Sala integrada a area gourmet', 1, false FROM new_property
UNION ALL
SELECT id, 'https://resizedimgs.vivareal.com/img/vr-listing/deb233d0d84c24b460566a253ec32f0e/casa-com-4-quartos-a-venda-380m-no-residencial-porto-seguro-caratinga.webp?action=fit-in&dimension=870x707', 'Fachada principal com dois pavimentos', 2, false FROM new_property;

WITH admin AS (
  SELECT id FROM users WHERE email = 'teste.casa_yme@gmail.com' LIMIT 1
), new_property AS (
  INSERT INTO properties (
    title,
    type,
    transaction,
    price,
    bedrooms,
    bathrooms,
    area,
    neighborhood,
    city,
    state,
    description,
    amenities,
    created_by
  )
  SELECT
    'Casa Lagoa Silvana Premium',
    'Casa',
    'VENDA',
    2800000,
    3,
    3,
    266,
    'Lagoa Silvana',
    'Caratinga',
    'MG',
    'Casa duplex de 266 m2 no condominio Parque Lagoa Silvana com design contemporaneo e lazer completo.',
    ARRAY[
      'Piscina',
      'Espaco gourmet',
      'Sala integrada',
      'Varandas',
      '3 suites',
      'Garagem para 3 carros',
      'Condominio fechado'
    ],
    admin.id
  FROM admin
  RETURNING id
)
INSERT INTO property_media (property_id, url, alt, position, is_cover)
SELECT id, 'https://resizedimgs.vivareal.com/img/vr-listing/73744365f49abb028ac0d961d6641df4/casa-de-condominio-com-3-quartos-a-venda-266m-no-ilha-do-rio-doce-caratinga.webp?action=fit-in&dimension=870x707', 'Living principal com pe direito duplo', 0, true FROM new_property
UNION ALL
SELECT id, 'https://resizedimgs.vivareal.com/img/vr-listing/a0c09d655b386737d8353ccb7c6f06e9/casa-de-condominio-com-3-quartos-a-venda-266m-no-ilha-do-rio-doce-caratinga.webp?action=fit-in&dimension=870x707', 'Copa integrada a cozinha', 1, false FROM new_property
UNION ALL
SELECT id, 'https://resizedimgs.vivareal.com/img/vr-listing/c43d5cf2e03d82e116b5da9ae179d8f3/casa-de-condominio-com-3-quartos-a-venda-266m-no-ilha-do-rio-doce-caratinga.webp?action=fit-in&dimension=870x707', 'Piscina com deck em madeira', 2, false FROM new_property
UNION ALL
SELECT id, 'https://resizedimgs.vivareal.com/img/vr-listing/cb962c1449d6d6f36bbed61184c21953/casa-de-condominio-com-3-quartos-a-venda-266m-no-ilha-do-rio-doce-caratinga.webp?action=fit-in&dimension=870x707', 'Fachada lateral com brises', 3, false FROM new_property;

WITH admin AS (
  SELECT id FROM users WHERE email = 'teste.casa_yme@gmail.com' LIMIT 1
), new_property AS (
  INSERT INTO properties (
    title,
    type,
    transaction,
    price,
    bedrooms,
    bathrooms,
    area,
    neighborhood,
    city,
    state,
    description,
    amenities,
    created_by
  )
  SELECT
    'Casa Atlantico Mirage',
    'Casa',
    'VENDA',
    11800000,
    5,
    6,
    720,
    'Joatinga',
    'Rio de Janeiro',
    'RJ',
    'Residencia em encosta com fachada envidracada, vista para o mar e piscina de borda infinita.',
    ARRAY[
      'Piscina',
      'Spa',
      'Varanda',
      'Cinema',
      'Heliponto'
    ],
    admin.id
  FROM admin
  RETURNING id
)
INSERT INTO property_media (property_id, url, alt, position, is_cover)
SELECT id, 'https://images.unsplash.com/photo-1505691938895-1758d7feb511?auto=format&fit=crop&w=1600&q=80', 'Fachada com vista para o mar', 0, true FROM new_property
UNION ALL
SELECT id, 'https://images.unsplash.com/photo-1505691723518-36a5ac3be353?auto=format&fit=crop&w=1600&q=80', 'Piscina com borda infinita', 1, false FROM new_property
UNION ALL
SELECT id, 'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1600&q=80', 'Sala de estar com vista panoramica', 2, false FROM new_property
UNION ALL
SELECT id, 'https://images.unsplash.com/photo-1449844908441-8829872d2607?auto=format&fit=crop&w=1600&q=80', 'Suite master minimalista', 3, false FROM new_property;

WITH admin AS (
  SELECT id FROM users WHERE email = 'teste.casa_yme@gmail.com' LIMIT 1
), new_property AS (
  INSERT INTO properties (
    title,
    type,
    transaction,
    price,
    bedrooms,
    bathrooms,
    area,
    neighborhood,
    city,
    state,
    description,
    amenities,
    created_by
  )
  SELECT
    'Villa Brisa Mediterranea',
    'Casa',
    'ALUGUEL',
    26000,
    4,
    5,
    540,
    'Ferradura',
    'Armacao dos Buzios',
    'RJ',
    'Villa litoranea com piscina aquecida, gazebo gourmet e ambientes abertos para o jardim.',
    ARRAY[
      'Piscina aquecida',
      'Gazebo',
      'Concierge',
      'Pier',
      'Academia'
    ],
    admin.id
  FROM admin
  RETURNING id
)
INSERT INTO property_media (property_id, url, alt, position, is_cover)
SELECT id, 'https://images.unsplash.com/photo-1502005097973-6a7082348e28?auto=format&fit=crop&w=1600&q=80', 'Vista externa da villa mediterranea', 0, true FROM new_property
UNION ALL
SELECT id, 'https://images.unsplash.com/photo-1560448075-bb485b067938?auto=format&fit=crop&w=1600&q=80', 'Sala envidracada integrada ao deck', 1, false FROM new_property
UNION ALL
SELECT id, 'https://images.unsplash.com/photo-1499916078039-922301b0eb9b?auto=format&fit=crop&w=1600&q=80', 'Suite com decoracao clara', 2, false FROM new_property
UNION ALL
SELECT id, 'https://images.unsplash.com/photo-1522156373667-4c7234bbd804?auto=format&fit=crop&w=1600&q=80', 'Espaco gourmet sob pergolado', 3, false FROM new_property;

WITH admin AS (
  SELECT id FROM users WHERE email = 'teste.casa_yme@gmail.com' LIMIT 1
), new_property AS (
  INSERT INTO properties (
    title,
    type,
    transaction,
    price,
    bedrooms,
    bathrooms,
    area,
    neighborhood,
    city,
    state,
    description,
    amenities,
    created_by
  )
  SELECT
    'Chacara Vale Verde Signature',
    'Casa',
    'VENDA',
    5600000,
    4,
    5,
    500,
    'Vale Verde',
    'Itatiaia',
    'RJ',
    'Chacara contemporanea integrada a natureza com sala envidracada, lareira em pedra e casa de hospedes.',
    ARRAY[
      'Lago',
      'Adega',
      'Lareira',
      'Casa de hospedes',
      'Heliponto'
    ],
    admin.id
  FROM admin
  RETURNING id
)
INSERT INTO property_media (property_id, url, alt, position, is_cover)
SELECT id, 'https://images.unsplash.com/photo-1515260268569-9271009adfdb?auto=format&fit=crop&w=1600&q=80', 'Fachada da chacara contemporanea', 0, true FROM new_property
UNION ALL
SELECT id, 'https://images.unsplash.com/photo-1464890100898-a385f744067f?auto=format&fit=crop&w=1600&q=80', 'Lago ornamental ao entardecer', 1, false FROM new_property
UNION ALL
SELECT id, 'https://images.unsplash.com/photo-1444418776041-9c7e33cc5a9c?auto=format&fit=crop&w=1600&q=80', 'Sala com lareira em pedra', 2, false FROM new_property
UNION ALL
SELECT id, 'https://images.unsplash.com/photo-1487956382158-bb926046304a?auto=format&fit=crop&w=1600&q=80', 'Piscina interna aquecida', 3, false FROM new_property;

WITH admin AS (
  SELECT id FROM users WHERE email = 'teste.casa_yme@gmail.com' LIMIT 1
), new_property AS (
  INSERT INTO properties (
    title,
    type,
    transaction,
    price,
    bedrooms,
    bathrooms,
    area,
    neighborhood,
    city,
    state,
    description,
    amenities,
    created_by
  )
  SELECT
    'Casa Vista das Dunas',
    'Casa',
    'ALUGUEL',
    21000,
    4,
    5,
    450,
    'Praia do Prea',
    'Cruz',
    'CE',
    'Casa de praia minimalista com piscina em prainha, varanda com redes e espacos integrados as dunas.',
    ARRAY[
      'Piscina com prainha',
      'Terraco',
      'Forno a lenha',
      'Deposito de kitesurf',
      'Servico de praia'
    ],
    admin.id
  FROM admin
  RETURNING id
)
INSERT INTO property_media (property_id, url, alt, position, is_cover)
SELECT id, 'https://images.unsplash.com/photo-1493663284031-b7e3aefcae8e?auto=format&fit=crop&w=1600&q=80', 'Varanda com redes voltada as dunas', 0, true FROM new_property
UNION ALL
SELECT id, 'https://images.unsplash.com/photo-1479839672679-a46483c0e7c8?auto=format&fit=crop&w=1600&q=80', 'Piscina iluminada ao por do sol', 1, false FROM new_property
UNION ALL
SELECT id, 'https://images.unsplash.com/photo-1505691723518-36a5ac3be353?auto=format&fit=crop&w=1600&q=80', 'Area gourmet externa com forno a lenha', 2, false FROM new_property;
