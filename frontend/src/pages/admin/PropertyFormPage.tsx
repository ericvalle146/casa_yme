import { useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { API_BASE_URL } from '@/lib/api';
import { authStorage } from '@/lib/auth';
import { useAuth } from '@/context/AuthContext';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Separator } from '@/components/ui/separator';
import { Badge } from '@/components/ui/badge';
import { toast } from 'sonner';
import { Save, ArrowLeft, Home, MapPin, DollarSign, FileText, Image as ImageIcon, X } from 'lucide-react';

type MediaItem = {
  id?: string;
  url?: string;
  file?: File;
  alt: string;
  isCover: boolean;
  preview?: string;
};

const emptyForm = {
  title: '',
  type: '',
  transaction: 'VENDA',
  price: '',
  isActive: true,
  bedrooms: '',
  bathrooms: '',
  suites: '',
  area: '',
  vagas: '',
  zipCode: '',
  street: '',
  number: '',
  complement: '',
  neighborhood: '',
  city: '',
  state: '',
  iptu: '',
  condominio: '',
  description: '',
  amenities: '',
};

const PropertyFormPage = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const { accessToken, refreshSession } = useAuth();

  const isEditing = Boolean(id);

  const [form, setForm] = useState(emptyForm);
  const [mediaItems, setMediaItems] = useState<MediaItem[]>([]);
  const [urlInput, setUrlInput] = useState({ url: '', alt: '' });
  const [fileInput, setFileInput] = useState<{ file: File | null; alt: string }>({ file: null, alt: '' });

  // Buscar detalhes do imóvel (se editando)
  const { data: propertyData, isLoading: isLoadingProperty } = useQuery({
    queryKey: ['property', id],
    queryFn: async () => {
      const response = await fetch(`${API_BASE_URL}/api/properties/${id}`);
      if (!response.ok) throw new Error('Falha ao carregar imóvel');
      return response.json();
    },
    enabled: isEditing,
  });

  // Preencher formulário ao carregar dados
  useEffect(() => {
    if (propertyData) {
      setForm({
        title: propertyData.title || '',
        type: propertyData.type || '',
        transaction: propertyData.transaction || 'VENDA',
        price: String(propertyData.price ?? ''),
        isActive: propertyData.is_active !== false,
        bedrooms: String(propertyData.bedrooms ?? ''),
        bathrooms: String(propertyData.bathrooms ?? ''),
        suites: String(propertyData.suites ?? ''),
        area: String(propertyData.area ?? ''),
        vagas: String(propertyData.vagas ?? ''),
        zipCode: propertyData.zip_code || '',
        street: propertyData.street || '',
        number: propertyData.number || '',
        complement: propertyData.complement || '',
        neighborhood: propertyData.neighborhood || '',
        city: propertyData.city || '',
        state: propertyData.state || '',
        iptu: String(propertyData.iptu ?? ''),
        condominio: String(propertyData.condominio ?? ''),
        description: propertyData.description || '',
        amenities: Array.isArray(propertyData.amenities) ? propertyData.amenities.join(', ') : '',
      });

      const media = Array.isArray(propertyData.gallery)
        ? propertyData.gallery.map((item: any) => ({
            id: item.id,
            url: item.url,
            alt: item.alt || '',
            isCover: Boolean(item.isCover),
          }))
        : [];

      setMediaItems(media);
    }
  }, [propertyData]);

  const normalizeCover = (items: MediaItem[]) => {
    if (!items.length) return items;
    const hasCover = items.some((item) => item.isCover);
    if (!hasCover) {
      items[0].isCover = true;
    }
    return items;
  };

  const handleAddUrlMedia = () => {
    if (!urlInput.url.trim()) {
      toast.error('Informe um link válido.');
      return;
    }

    const next = normalizeCover([
      ...mediaItems,
      {
        url: urlInput.url.trim(),
        alt: urlInput.alt.trim(),
        isCover: !mediaItems.some((item) => item.isCover),
      },
    ]);

    setMediaItems([...next]);
    setUrlInput({ url: '', alt: '' });
    toast.success('Imagem adicionada');
  };

  const handleAddFileMedia = () => {
    if (!fileInput.file) {
      toast.error('Selecione um arquivo de imagem.');
      return;
    }

    const preview = URL.createObjectURL(fileInput.file);
    const next = normalizeCover([
      ...mediaItems,
      {
        file: fileInput.file,
        alt: fileInput.alt.trim(),
        isCover: !mediaItems.some((item) => item.isCover),
        preview,
      },
    ]);

    setMediaItems([...next]);
    setFileInput({ file: null, alt: '' });
    toast.success('Imagem adicionada');
  };

  const handleSetCover = (index: number) => {
    const next = mediaItems.map((item, idx) => ({
      ...item,
      isCover: idx === index,
    }));
    setMediaItems(next);
  };

  const handleRemoveMedia = (index: number) => {
    const next = mediaItems.filter((_, idx) => idx !== index);
    setMediaItems(normalizeCover([...next]));
  };

  const buildFormData = () => {
    const formData = new FormData();

    formData.append('title', form.title.trim());
    formData.append('type', form.type.trim());
    formData.append('transaction', form.transaction);
    formData.append('price', form.price);
    formData.append('is_active', String(form.isActive));
    formData.append('bedrooms', form.bedrooms);
    formData.append('bathrooms', form.bathrooms);
    formData.append('suites', form.suites || '0');
    formData.append('area', form.area);
    formData.append('vagas', form.vagas || '0');
    formData.append('zip_code', form.zipCode.trim());
    formData.append('street', form.street.trim());
    formData.append('number', form.number.trim());
    formData.append('complement', form.complement.trim());
    formData.append('neighborhood', form.neighborhood.trim());
    formData.append('city', form.city.trim());
    formData.append('state', form.state.trim());
    formData.append('iptu', form.iptu || '0');
    formData.append('condominio', form.condominio || '0');
    formData.append('description', form.description.trim());

    const amenities = form.amenities
      .split(',')
      .map((item) => item.trim())
      .filter(Boolean);
    formData.append('amenities', JSON.stringify(amenities));

    const mediaUrls = mediaItems
      .filter((item) => item.url)
      .map((item) => ({
        url: item.url,
        alt: item.alt,
        isCover: item.isCover,
      }));

    const mediaFiles = mediaItems.filter((item) => item.file) as Array<MediaItem & { file: File }>;
    const mediaFilesMeta = mediaFiles.map((item) => ({
      alt: item.alt,
      isCover: item.isCover,
    }));

    if (mediaUrls.length) {
      formData.append('mediaUrls', JSON.stringify(mediaUrls));
    }

    if (mediaFilesMeta.length) {
      formData.append('mediaFilesMeta', JSON.stringify(mediaFilesMeta));
    }

    mediaFiles.forEach((item) => {
      formData.append('mediaFiles', item.file);
    });

    if (isEditing) {
      formData.append('replaceMedia', 'true');
    }

    return formData;
  };

  const saveMutation = useMutation({
    mutationFn: async (formData: FormData) => {
      let token = accessToken || authStorage.getAccessToken();

      const doFetch = (authToken?: string) =>
        fetch(isEditing ? `${API_BASE_URL}/api/properties/${id}` : `${API_BASE_URL}/api/properties`, {
          method: isEditing ? 'PUT' : 'POST',
          headers: {
            ...(authToken ? { Authorization: `Bearer ${authToken}` } : {}),
          },
          body: formData,
        });

      let response = await doFetch(token || undefined);

      if (response.status === 401) {
        const refreshed = await refreshSession();
        if (refreshed) {
          token = authStorage.getAccessToken();
          response = await doFetch(token || undefined);
        }
      }

      if (!response.ok) {
        const data = await response.json().catch(() => ({}));
        throw new Error(data?.error || 'Falha ao salvar imóvel');
      }

      return response.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-properties'] });
      queryClient.invalidateQueries({ queryKey: ['admin-properties-list'] });
      toast.success(isEditing ? 'Imóvel atualizado com sucesso!' : 'Imóvel criado com sucesso!');
      navigate('/admin/properties');
    },
    onError: (error: Error) => {
      toast.error(error.message || 'Erro ao salvar imóvel');
    },
  });

  const handleSubmit = (event: React.FormEvent) => {
    event.preventDefault();

    if (mediaItems.length === 0) {
      toast.error('Adicione pelo menos uma imagem ao imóvel');
      return;
    }

    const formData = buildFormData();
    saveMutation.mutate(formData);
  };

  if (isEditing && isLoadingProperty) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto mb-4"></div>
          <p className="text-muted-foreground">Carregando imóvel...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <Button variant="ghost" onClick={() => navigate('/admin/properties')} className="mb-4">
          <ArrowLeft className="h-4 w-4 mr-2" />
          Voltar
        </Button>
        <h1 className="text-3xl font-bold text-foreground">
          {isEditing ? 'Editar Imóvel' : 'Adicionar Novo Imóvel'}
        </h1>
        <p className="text-muted-foreground mt-1">
          Preencha todos os campos obrigatórios para {isEditing ? 'atualizar' : 'cadastrar'} o imóvel
        </p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Seção 1: Informações Básicas */}
        <Card>
          <CardHeader>
            <div className="flex items-center gap-2">
              <Home className="h-5 w-5" />
              <CardTitle>Informações Básicas</CardTitle>
            </div>
            <CardDescription>Dados principais do imóvel</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2 md:col-span-2">
                <Label htmlFor="title">
                  Título do Anúncio <span className="text-destructive">*</span>
                </Label>
                <Input
                  id="title"
                  placeholder="Ex: Apartamento 3 quartos com vista para o mar"
                  value={form.title}
                  onChange={(e) => setForm({ ...form, title: e.target.value })}
                  required
                  minLength={10}
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="type">
                  Tipo de Imóvel <span className="text-destructive">*</span>
                </Label>
                <Select value={form.type} onValueChange={(value) => setForm({ ...form, type: value })} required>
                  <SelectTrigger id="type">
                    <SelectValue placeholder="Selecione o tipo" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="Apartamento">Apartamento</SelectItem>
                    <SelectItem value="Casa">Casa</SelectItem>
                    <SelectItem value="Sobrado">Sobrado</SelectItem>
                    <SelectItem value="Cobertura">Cobertura</SelectItem>
                    <SelectItem value="Terreno">Terreno</SelectItem>
                    <SelectItem value="Comercial">Comercial</SelectItem>
                    <SelectItem value="Chácara">Chácara</SelectItem>
                    <SelectItem value="Sítio">Sítio</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label htmlFor="transaction">
                  Tipo de Transação <span className="text-destructive">*</span>
                </Label>
                <Select value={form.transaction} onValueChange={(value) => setForm({ ...form, transaction: value })} required>
                  <SelectTrigger id="transaction">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="VENDA">Venda</SelectItem>
                    <SelectItem value="ALUGUEL">Aluguel</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label htmlFor="price">
                  Preço (R$) <span className="text-destructive">*</span>
                </Label>
                <Input
                  id="price"
                  type="number"
                  placeholder="0.00"
                  value={form.price}
                  onChange={(e) => setForm({ ...form, price: e.target.value })}
                  required
                  min="0"
                  step="0.01"
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="isActive" className="flex items-center gap-2">
                  Status do Anúncio
                </Label>
                <div className="flex items-center gap-3 h-10 px-3 rounded-md border border-input bg-background">
                  <Switch
                    id="isActive"
                    checked={form.isActive}
                    onCheckedChange={(checked) => setForm({ ...form, isActive: checked })}
                  />
                  <span className="text-sm">
                    {form.isActive ? (
                      <Badge className="bg-green-600">Ativo (Visível no Site)</Badge>
                    ) : (
                      <Badge variant="secondary">Inativo (Oculto)</Badge>
                    )}
                  </span>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Seção 2: Características */}
        <Card>
          <CardHeader>
            <div className="flex items-center gap-2">
              <Home className="h-5 w-5" />
              <CardTitle>Características do Imóvel</CardTitle>
            </div>
            <CardDescription>Detalhes sobre quartos, área e vagas</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="space-y-2">
                <Label htmlFor="bedrooms">
                  Dormitórios <span className="text-destructive">*</span>
                </Label>
                <Input
                  id="bedrooms"
                  type="number"
                  placeholder="0"
                  value={form.bedrooms}
                  onChange={(e) => setForm({ ...form, bedrooms: e.target.value })}
                  required
                  min="0"
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="bathrooms">
                  Banheiros <span className="text-destructive">*</span>
                </Label>
                <Input
                  id="bathrooms"
                  type="number"
                  placeholder="0"
                  value={form.bathrooms}
                  onChange={(e) => setForm({ ...form, bathrooms: e.target.value })}
                  required
                  min="0"
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="suites">Suítes</Label>
                <Input
                  id="suites"
                  type="number"
                  placeholder="0"
                  value={form.suites}
                  onChange={(e) => setForm({ ...form, suites: e.target.value })}
                  min="0"
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="area">
                  Área Total (m²) <span className="text-destructive">*</span>
                </Label>
                <Input
                  id="area"
                  type="number"
                  placeholder="0"
                  value={form.area}
                  onChange={(e) => setForm({ ...form, area: e.target.value })}
                  required
                  min="0"
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="vagas">Vagas de Garagem</Label>
                <Input
                  id="vagas"
                  type="number"
                  placeholder="0"
                  value={form.vagas}
                  onChange={(e) => setForm({ ...form, vagas: e.target.value })}
                  min="0"
                />
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Seção 3: Localização */}
        <Card>
          <CardHeader>
            <div className="flex items-center gap-2">
              <MapPin className="h-5 w-5" />
              <CardTitle>Localização</CardTitle>
            </div>
            <CardDescription>Endereço completo do imóvel (Latitude e Longitude serão geradas automaticamente)</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {/* Linha 1: CEP + Rua + Número */}
              <div className="grid grid-cols-1 md:grid-cols-12 gap-4">
                <div className="space-y-2 md:col-span-3">
                  <Label htmlFor="zipCode">CEP</Label>
                  <Input
                    id="zipCode"
                    placeholder="00000-000"
                    value={form.zipCode}
                    onChange={(e) => setForm({ ...form, zipCode: e.target.value })}
                    maxLength={9}
                  />
                </div>

                <div className="space-y-2 md:col-span-6">
                  <Label htmlFor="street">
                    Rua/Logradouro <span className="text-destructive">*</span>
                  </Label>
                  <Input
                    id="street"
                    placeholder="Ex: Rua das Flores"
                    value={form.street}
                    onChange={(e) => setForm({ ...form, street: e.target.value })}
                    required
                  />
                </div>

                <div className="space-y-2 md:col-span-3">
                  <Label htmlFor="number">
                    Número <span className="text-destructive">*</span>
                  </Label>
                  <Input
                    id="number"
                    placeholder="123"
                    value={form.number}
                    onChange={(e) => setForm({ ...form, number: e.target.value })}
                    required
                  />
                </div>
              </div>

              {/* Linha 2: Complemento + Bairro */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="complement">Complemento</Label>
                  <Input
                    id="complement"
                    placeholder="Ex: Apto 201, Bloco B"
                    value={form.complement}
                    onChange={(e) => setForm({ ...form, complement: e.target.value })}
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="neighborhood">
                    Bairro <span className="text-destructive">*</span>
                  </Label>
                  <Input
                    id="neighborhood"
                    placeholder="Ex: Centro"
                    value={form.neighborhood}
                    onChange={(e) => setForm({ ...form, neighborhood: e.target.value })}
                    required
                  />
                </div>
              </div>

              {/* Linha 3: Cidade + Estado */}
              <div className="grid grid-cols-1 md:grid-cols-12 gap-4">
                <div className="space-y-2 md:col-span-9">
                  <Label htmlFor="city">
                    Cidade <span className="text-destructive">*</span>
                  </Label>
                  <Input
                    id="city"
                    placeholder="Ex: São Paulo"
                    value={form.city}
                    onChange={(e) => setForm({ ...form, city: e.target.value })}
                    required
                  />
                </div>

                <div className="space-y-2 md:col-span-3">
                  <Label htmlFor="state">
                    Estado <span className="text-destructive">*</span>
                  </Label>
                  <Input
                    id="state"
                    placeholder="Ex: SP"
                    value={form.state}
                    onChange={(e) => setForm({ ...form, state: e.target.value })}
                    required
                    maxLength={2}
                  />
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Seção 4: Custos Adicionais */}
        <Card>
          <CardHeader>
            <div className="flex items-center gap-2">
              <DollarSign className="h-5 w-5" />
              <CardTitle>Custos Adicionais</CardTitle>
            </div>
            <CardDescription>IPTU e condomínio (opcional)</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="iptu">IPTU Anual (R$)</Label>
                <Input
                  id="iptu"
                  type="number"
                  placeholder="0.00"
                  value={form.iptu}
                  onChange={(e) => setForm({ ...form, iptu: e.target.value })}
                  min="0"
                  step="0.01"
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="condominio">Condomínio Mensal (R$)</Label>
                <Input
                  id="condominio"
                  type="number"
                  placeholder="0.00"
                  value={form.condominio}
                  onChange={(e) => setForm({ ...form, condominio: e.target.value })}
                  min="0"
                  step="0.01"
                />
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Seção 5: Descrição e Comodidades */}
        <Card>
          <CardHeader>
            <div className="flex items-center gap-2">
              <FileText className="h-5 w-5" />
              <CardTitle>Descrição e Comodidades</CardTitle>
            </div>
            <CardDescription>Detalhes sobre o imóvel e suas comodidades</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="description">
                Descrição <span className="text-destructive">*</span>
              </Label>
              <Textarea
                id="description"
                placeholder="Descreva o imóvel, seus diferenciais, localização, proximidades..."
                value={form.description}
                onChange={(e) => setForm({ ...form, description: e.target.value })}
                required
                minLength={50}
                rows={6}
              />
              <p className="text-xs text-muted-foreground">
                Mínimo 50 caracteres • {form.description.length} caracteres
              </p>
            </div>

            <div className="space-y-2">
              <Label htmlFor="amenities">Comodidades (separadas por vírgula)</Label>
              <Input
                id="amenities"
                placeholder="Ex: Piscina, Churrasqueira, Academia, Playground"
                value={form.amenities}
                onChange={(e) => setForm({ ...form, amenities: e.target.value })}
              />
              <p className="text-xs text-muted-foreground">
                Exemplos: Piscina, Churrasqueira, Sacada, Elevador, Portaria 24h
              </p>
            </div>
          </CardContent>
        </Card>

        {/* Seção 6: Galeria de Imagens */}
        <Card>
          <CardHeader>
            <div className="flex items-center gap-2">
              <ImageIcon className="h-5 w-5" />
              <CardTitle>Galeria de Imagens</CardTitle>
            </div>
            <CardDescription>
              Adicione imagens do imóvel (mínimo 1 imagem obrigatória)
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-6">
            {/* Adicionar por URL */}
            <div className="space-y-3">
              <h4 className="text-sm font-semibold">Adicionar imagem por link</h4>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
                <Input
                  placeholder="URL da imagem"
                  value={urlInput.url}
                  onChange={(e) => setUrlInput({ ...urlInput, url: e.target.value })}
                  className="md:col-span-2"
                />
                <Input
                  placeholder="Descrição (alt)"
                  value={urlInput.alt}
                  onChange={(e) => setUrlInput({ ...urlInput, alt: e.target.value })}
                />
              </div>
              <Button type="button" variant="secondary" onClick={handleAddUrlMedia}>
                Adicionar Link
              </Button>
            </div>

            <Separator />

            {/* Adicionar por Upload */}
            <div className="space-y-3">
              <h4 className="text-sm font-semibold">Adicionar imagem por upload</h4>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                <Input
                  type="file"
                  accept="image/*"
                  onChange={(e) =>
                    setFileInput({
                      file: e.target.files ? e.target.files[0] : null,
                      alt: fileInput.alt,
                    })
                  }
                />
                <Input
                  placeholder="Descrição (alt)"
                  value={fileInput.alt}
                  onChange={(e) => setFileInput({ ...fileInput, alt: e.target.value })}
                />
              </div>
              <Button type="button" variant="secondary" onClick={handleAddFileMedia}>
                Adicionar Upload
              </Button>
            </div>

            <Separator />

            {/* Lista de Imagens */}
            {mediaItems.length > 0 ? (
              <div className="space-y-3">
                <h4 className="text-sm font-semibold">Imagens Adicionadas ({mediaItems.length})</h4>
                <div className="space-y-3">
                  {mediaItems.map((item, index) => (
                    <div
                      key={`${item.url || item.preview || index}`}
                      className="flex items-center gap-4 p-4 border border-border rounded-lg"
                    >
                      <div className="h-16 w-24 bg-muted rounded-md overflow-hidden flex-shrink-0">
                        {(item.url || item.preview) ? (
                          <img
                            src={item.url || item.preview}
                            alt={item.alt}
                            className="h-full w-full object-cover"
                          />
                        ) : (
                          <div className="h-full w-full flex items-center justify-center">
                            <ImageIcon className="h-6 w-6 text-muted-foreground" />
                          </div>
                        )}
                      </div>

                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium truncate">
                          {item.url || item.file?.name || 'Imagem'}
                        </p>
                        {item.alt && (
                          <p className="text-xs text-muted-foreground truncate">{item.alt}</p>
                        )}
                      </div>

                      <div className="flex items-center gap-2">
                        <Button
                          type="button"
                          variant={item.isCover ? 'default' : 'outline'}
                          size="sm"
                          onClick={() => handleSetCover(index)}
                        >
                          {item.isCover ? 'Capa' : 'Definir Capa'}
                        </Button>
                        <Button
                          type="button"
                          variant="ghost"
                          size="sm"
                          onClick={() => handleRemoveMedia(index)}
                          className="text-destructive hover:text-destructive"
                        >
                          <X className="h-4 w-4" />
                        </Button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            ) : (
              <div className="text-center py-8 border-2 border-dashed border-border rounded-lg">
                <ImageIcon className="h-12 w-12 text-muted-foreground mx-auto mb-2" />
                <p className="text-sm text-muted-foreground">
                  Nenhuma imagem adicionada ainda
                </p>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Botões de Ação */}
        <div className="flex items-center gap-3">
          <Button type="submit" disabled={saveMutation.isPending}>
            {saveMutation.isPending ? (
              <>Salvando...</>
            ) : (
              <>
                <Save className="h-4 w-4 mr-2" />
                {isEditing ? 'Atualizar Imóvel' : 'Cadastrar Imóvel'}
              </>
            )}
          </Button>
          <Button type="button" variant="outline" onClick={() => navigate('/admin/properties')}>
            Cancelar
          </Button>
        </div>
      </form>
    </div>
  );
};

export default PropertyFormPage;
