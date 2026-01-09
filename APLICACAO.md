# Aplicacao

Este projeto e um site/app de imobiliaria para apresentar um portfolio de imoveis.

Principais fluxos:
- Listagem de imoveis em destaque
- Filtros de busca por transacao, cidade, bairro, tipo, dormitorios e faixa de valor
- Pagina de detalhes do imovel com galeria, comodidades e preco
- Formulario de contato para gerar leads
- Autenticacao com login e senha (login, refresh e logout)
- Painel administrativo para cadastrar, editar e remover imoveis

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
