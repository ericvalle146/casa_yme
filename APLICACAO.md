# Aplicacao

Este projeto e um site/app de imobiliaria para apresentar um portfolio de imoveis.

Principais fluxos:
- Listagem de imoveis em destaque
- Filtros de busca por transacao, cidade, bairro, tipo, dormitorios e faixa de valor
- Pagina de detalhes do imovel com galeria, comodidades, preco e mapa interativo
- Sistema de favoritos para usuarios autenticados
- Busca avancada com autocomplete de localizacoes
- Mapas interativos com geolocalizacao automatica via OpenStreetMap
- Formulario de contato para gerar leads
- Autenticacao com login e senha (login, refresh e logout)
- Sistema de tipos de usuario (VISITANTE, CORRETOR, ADMIN) com controle de acesso baseado em roles
- Painel administrativo moderno com sidebar navegavel para gerenciar imoveis
  - Dashboard com estatisticas e metricas
  - Lista de imoveis com filtros e acoes (editar, excluir, visualizar)
  - Formulario completo de cadastro/edicao com campos organizados em secoes
  - Geocoding automatico de enderecos para coordenadas GPS

Arquitetura geral:
- Frontend em React/Vite dentro de frontend/
- Backend em Node/Express dentro de backend/ para receber leads, autenticar usuarios e gerenciar imoveis
- Banco de dados Postgres para usuarios, sessoes e imoveis

Deploy
- Deploy via ./deploy.sh usando Docker + Traefik
- Frontend em https://casayme.com.br
- Backend em https://backend.casayme.com.br

Dados:
- Os imoveis sao carregados via API do backend e persistidos no Postgres
- As credenciais e sessoes sao persistidas no Postgres
