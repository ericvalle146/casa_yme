# Welcome to your Lovable project

## Project info

**URL**: https://lovable.dev/projects/55615f8e-374a-4050-a0ae-d3a3c6ba0eb2

## How can I edit this code?

There are several ways of editing your application.

**Use Lovable**

Simply visit the [Lovable Project](https://lovable.dev/projects/55615f8e-374a-4050-a0ae-d3a3c6ba0eb2) and start prompting.

Changes made via Lovable will be committed automatically to this repo.

**Use your preferred IDE**

If you want to work locally using your own IDE, you can clone this repo and push changes. Pushed changes will also be reflected in Lovable.

The only requirement is having Node.js & npm installed - [install with nvm](https://github.com/nvm-sh/nvm#installing-and-updating)

Follow these steps:

```sh
# Step 1: Clone the repository using the project's Git URL.
git clone <YOUR_GIT_URL>

# Step 2: Navigate to the project directory.
cd <YOUR_PROJECT_NAME>

# Step 3: Install the necessary dependencies.
npm i

# Step 4: Start the development server with auto-reloading and an instant preview.
npm run dev
```

**Edit a file directly in GitHub**

- Navigate to the desired file(s).
- Click the "Edit" button (pencil icon) at the top right of the file view.
- Make your changes and commit the changes.

**Use GitHub Codespaces**

- Navigate to the main page of your repository.
- Click on the "Code" button (green button) near the top right.
- Select the "Codespaces" tab.
- Click on "New codespace" to launch a new Codespace environment.
- Edit files directly within the Codespace and commit and push your changes once you're done.

## What technologies are used for this project?

This project is built with:

- Vite
- TypeScript
- React
- shadcn-ui
- Tailwind CSS

## Backend (API de Leads)

O diretório `server/` contém uma API Express que recebe os dados do formulário “Converse com um especialista” e os encaminha para um webhook do N8N.

### Variáveis de ambiente

1. Copie `server/env.example` para `server/.env`.
2. Ajuste os valores conforme seu ambiente:

```
cp server/env.example server/.env
```

- `PORT`: porta em que a API será exposta (padrão 4000).
- `CORS_ORIGINS`: origens permitidas para requisições (separe com vírgula).
- `N8N_WEBHOOK_URL`: URL do webhook no N8N que receberá os dados.

### Executando localmente

```
cd server
npm install
npm run dev
```

A API ficará disponível em `http://localhost:4000`. O front faz requisições para `POST /api/contact`.

## Front-end (Vite/React)

### Variáveis de ambiente

1. Copie `frontend.env.example` para `.env.local` (ou `.env`) na raiz do projeto:

```
cp frontend.env.example .env.local
```

2. Ajuste conforme necessário:

- `VITE_API_BASE_URL`: URL pública do backend. Em produção deve apontar para o domínio do servidor Express.
- `VITE_PROXY_TARGET`: URL usada pelo proxy do Vite no desenvolvimento (normalmente `http://localhost:4000`).

> Observação: quando `VITE_API_BASE_URL` estiver vazio, o front utilizará rotas relativas (`/api/contact`). No desenvolvimento, o proxy cuida do redirecionamento; em produção, defina a variável para evitar depender de subpath específico.

### Verificação das imagens

Execute `npm run check:media` para validar se todas as URLs de imagens configuradas nas propriedades respondem com sucesso (requisições `HEAD`).

## Deploy com Docker

### Deploy Completo (Frontend + Backend)

O projeto inclui arquivos Docker para deploy completo na VPS.

#### Domínios Configurados
- **Frontend**: `imob.locusup.shop`
- **Backend**: `apiapi.jyze.space`

#### Passos Rápidos

1. **Configure o backend**:
   ```bash
   cd server
   cp env.example .env
   nano .env  # Configure N8N_WEBHOOK_URL
   ```

2. **Execute o deploy**:
   ```bash
   chmod +x deploy.sh
   ./deploy.sh
   ```

3. **Configure Nginx e SSL** (veja `INSTALL.md`):
   ```bash
   # Copiar configuração do Nginx
   sudo cp nginx-proxy.conf /etc/nginx/sites-available/imovelpro
   sudo ln -s /etc/nginx/sites-available/imovelpro /etc/nginx/sites-enabled/
   
   # Obter certificados SSL
   sudo certbot --nginx -d imob.locusup.shop
   sudo certbot --nginx -d apiapi.jyze.space
   ```

#### Documentação Completa

- **Deploy rápido**: Veja `DEPLOY.md`
- **Instalação detalhada**: Veja `INSTALL.md`

#### Comandos Úteis

```bash
# Ver status
docker compose ps

# Ver logs
docker compose logs -f

# Reiniciar
docker compose restart

# Parar
docker compose down

# Reconstruir
docker compose up -d --build
```

## Can I connect a custom domain to my Lovable project?

Yes, you can!

To connect a domain, navigate to Project > Settings > Domains and click Connect Domain.

Read more here: [Setting up a custom domain](https://docs.lovable.dev/features/custom-domain#custom-domain)

## Catálogo de propriedades

As quatro primeiras residências refletem anúncios reais enviados pelo cliente; as demais são referências conceituais que permanecem para fins de layout até que novos materiais sejam fornecidos.

### 1. Complexo Residencial Recanto dos Pássaros — Caratinga/MG
- **Valores:** Venda R$ 3.300.000 • Condomínio R$ 400/mês • IPTU R$ 3.500
- **Dimensões:** 815 m² construídos em terreno de 10.000 m² • 4 quartos • 5 banheiros • 20 vagas • 2 suítes
- **Destaques:** Piscina, espaço gourmet, quintal com pomar, mirante, condomínio inteligente/sustentável
- **Vídeo tour:** [YouTube](https://youtu.be/cVmnONLekQA)
- **Imagens:**
  - [Vista aérea da residência](https://resizedimgs.vivareal.com/img/vr-listing/26da475ce459f7e741c1c648dc7c1bac/casa-de-condominio-com-4-quartos-a-venda-815m-no-residencial-porto-seguro-caratinga.webp?action=fit-in&dimension=870x707)
  - [Área de lazer com piscina](https://resizedimgs.vivareal.com/img/vr-listing/ca3ed9d51369d963c1a550efd586eefb/casa-de-condominio-com-4-quartos-a-venda-815m-no-residencial-porto-seguro-caratinga.webp?action=fit-in&dimension=870x707)
  - [Área verde e pomar](https://resizedimgs.vivareal.com/img/vr-listing/634c4c068d16ec16ff92bfa3a7a43ec9/casa-de-condominio-com-4-quartos-a-venda-815m-no-residencial-porto-seguro-caratinga.webp?action=fit-in&dimension=870x707)
  - [Entrada principal](https://resizedimgs.vivareal.com/img/vr-listing/4deb718a87b8572994911dc8b2b1d27f/casa-de-condominio-com-4-quartos-a-venda-815m-no-residencial-porto-seguro-caratinga.webp?action=fit-in&dimension=870x707)
  - [Espaço gourmet](https://resizedimgs.vivareal.com/img/vr-listing/c37e8d6e0ce432593dc9705769726bd0/casa-de-condominio-com-4-quartos-a-venda-815m-no-residencial-porto-seguro-caratinga.webp?action=fit-in&dimension=870x707)
  - [Copa integrada](https://resizedimgs.vivareal.com/img/vr-listing/453e456b0d075becceb8cb422cf1d355/casa-de-condominio-com-4-quartos-a-venda-815m-no-residencial-porto-seguro-caratinga.webp?action=fit-in&dimension=870x707)
  - [Banheiro principal](https://resizedimgs.vivareal.com/img/vr-listing/e5fc9e96ba60c2cd8f9a5259f932e990/casa-de-condominio-com-4-quartos-a-venda-815m-no-residencial-porto-seguro-caratinga.webp?action=fit-in&dimension=870x707)

### 2. Loteamento Lagoa Silvania — Caratinga/MG
- **Valores:** Venda R$ 620.000 • Condomínio R$ 1/mês • IPTU R$ 1
- **Dimensões:** 1.001 m² de terreno
- **Destaques:** Projeto autoral de Nicolas Kilaris, localização privilegiada, lazer completo (piscinas, quadras, espaço kids, academia, sauna)
- **Imagens:**
  - [Panorama do loteamento](https://resizedimgs.vivareal.com/img/vr-listing/5b43a24e6accebd01c636e0a24115f6b/loteterreno-a-venda-1001m-no-centro-caratinga.webp?action=fit-in&dimension=870x707)
  - [Acesso principal](https://resizedimgs.vivareal.com/img/vr-listing/4e4fc4fb3182b1fbbfb1b2867b2be66f/loteterreno-a-venda-1001m-no-centro-caratinga.webp?action=fit-in&dimension=870x707)
  - [Piscina e área de lazer](https://resizedimgs.vivareal.com/img/vr-listing/31a518ffcebe340cf4c59b03215b2702/loteterreno-a-venda-1001m-no-centro-caratinga.webp?action=fit-in&dimension=870x707)
  - [Churrasqueira coberta](https://resizedimgs.vivareal.com/img/vr-listing/0c1833cf1d39f593f7bec705520f7d10/loteterreno-a-venda-1001m-no-centro-caratinga.webp?action=fit-in&dimension=870x707)
  - [Perspectiva alternativa do acesso](https://resizedimgs.vivareal.com/img/vr-listing/f33c9028ff4a71473927909d05c8cd92/loteterreno-a-venda-1001m-no-centro-caratinga.webp?action=fit-in&dimension=870x707)

### 3. Chácara Duplex Porto Seguro — Caratinga/MG
- **Valores:** Venda R$ 2.000.000 • Condomínio R$ 1/mês • IPTU R$ 1
- **Dimensões:** 380 m² • 4 quartos • 5 banheiros • 2 vagas • 4 suítes
- **Destaques:** Pomar formado, área gourmet integrada, suítes com sacadas, closet e varanda para o pomar
- **Imagens:**
  - [Fachada principal da casa](https://resizedimgs.vivareal.com/img/vr-listing/deb233d0d84c24b460566a253ec32f0e/casa-com-4-quartos-a-venda-380m-no-residencial-porto-seguro-caratinga.webp?action=fit-in&dimension=870x707)
  - [Vista posterior com pomar](https://resizedimgs.vivareal.com/img/vr-listing/5fe05513a143e0c294ce52a1633f5388/casa-com-4-quartos-a-venda-380m-no-residencial-porto-seguro-caratinga.webp?action=fit-in&dimension=870x707)
  - [Sala integrada à cozinha gourmet](https://resizedimgs.vivareal.com/img/vr-listing/07bf74b41593a0f111628b599eb0bc18/casa-com-4-quartos-a-venda-380m-no-residencial-porto-seguro-caratinga.webp?action=fit-in&dimension=870x707)

### 4. Casa Lagoa Silvana Premium — Caratinga/MG
- **Valores:** Venda R$ 2.800.000 • Condomínio R$ 550/mês
- **Dimensões:** 266 m² • 3 quartos • 3 banheiros • 3 vagas • 3 suítes
- **Destaques:** Arquitetura contemporânea em condomínio Lagoa Silvana, piscina com deck, ambientes integrados e acabamentos de alto padrão
- **Imagens:**
  - [Fachada com linhas modernas](https://resizedimgs.vivareal.com/img/vr-listing/b17f5d3e18f5ea20d66636f8c9ba4b55/casa-de-condominio-com-3-quartos-a-venda-266m-no-ilha-do-rio-doce-caratinga.webp?action=fit-in&dimension=870x707)
  - [Sala integrada com pé-direito duplo](https://resizedimgs.vivareal.com/img/vr-listing/73744365f49abb028ac0d961d6641df4/casa-de-condominio-com-3-quartos-a-venda-266m-no-ilha-do-rio-doce-caratinga.webp?action=fit-in&dimension=870x707)
  - [Copa/cozinha planejada](https://resizedimgs.vivareal.com/img/vr-listing/a0c09d655b386737d8353ccb7c6f06e9/casa-de-condominio-com-3-quartos-a-venda-266m-no-ilha-do-rio-doce-caratinga.webp?action=fit-in&dimension=870x707)
  - [Piscina com deck em madeira](https://resizedimgs.vivareal.com/img/vr-listing/c43d5cf2e03d82e116b5da9ae179d8f3/casa-de-condominio-com-3-quartos-a-venda-266m-no-ilha-do-rio-doce-caratinga.webp?action=fit-in&dimension=870x707)
  - [Perspectiva lateral com brises](https://resizedimgs.vivareal.com/img/vr-listing/cb962c1449d6d6f36bbed61184c21953/casa-de-condominio-com-3-quartos-a-venda-266m-no-ilha-do-rio-doce-caratinga.webp?action=fit-in&dimension=870x707)

---

### Propriedades de referência (conceito visual)

5. **Casa Atlântico Mirage — Rio de Janeiro/RJ**  
   [Piscina infinita](https://images.unsplash.com/photo-1505691723518-36a5ac3be353?auto=format&fit=crop&w=1600&q=80) • [Sala panorâmica](https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1600&q=80) • [Suíte master](https://images.unsplash.com/photo-1449844908441-8829872d2607?auto=format&fit=crop&w=1600&q=80)

6. **Villa Brisa Mediterrânea — Armação dos Búzios/RJ**  
   [Espaço gourmet com vista](https://images.unsplash.com/photo-1522156373667-4c7234bbd804?auto=format&fit=crop&w=1600&q=80) • [Sala envidraçada](https://images.unsplash.com/photo-1560448075-bb485b067938?auto=format&fit=crop&w=1600&q=80) • [Suíte luminosa](https://images.unsplash.com/photo-1499916078039-922301b0eb9b?auto=format&fit=crop&w=1600&q=80)

7. **Chácara Vale Verde Signature — Itatiaia/RJ**  
   [Lago ornamental](https://images.unsplash.com/photo-1464890100898-a385f744067f?auto=format&fit=crop&w=1600&q=80) • [Lareira em pedra](https://images.unsplash.com/photo-1444418776041-9c7e33cc5a9c?auto=format&fit=crop&w=1600&q=80) • [Piscina interna aquecida](https://images.unsplash.com/photo-1505692762512-94346d5ed866?auto=format&fit=crop&w=1600&q=80)

8. **Casa Vista das Dunas — Cruz/CE**  
   [Varanda com redes](https://images.unsplash.com/photo-1493663284031-b7e3aefcae8e?auto=format&fit=crop&w=1600&q=80) • [Piscina ao entardecer](https://images.unsplash.com/photo-1521783988132-5fabced22c67?auto=format&fit=crop&w=1600&q=80) • [Área gourmet externa](https://images.unsplash.com/photo-1505691723518-36a5ac3be353?auto=format&fit=crop&w=1600&q=80)

> **Importante:** Substitua as referências conceituais pelas fotos oficiais quando os materiais forem disponibilizados. O formulário de contato já envia o nome do imóvel selecionado no campo de mensagem por padrão.
