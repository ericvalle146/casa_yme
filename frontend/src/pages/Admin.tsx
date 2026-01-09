import { useEffect, useMemo, useState } from "react";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { useToast } from "@/hooks/use-toast";
import { Property, TransactionType } from "@/data/properties";
import { API_BASE_URL } from "@/lib/api";
import { authStorage } from "@/lib/auth";
import { useAuth } from "@/context/AuthContext";

const emptyForm = {
  title: "",
  type: "",
  transaction: "VENDA" as TransactionType,
  price: "",
  bedrooms: "",
  bathrooms: "",
  area: "",
  neighborhood: "",
  city: "",
  state: "",
  description: "",
  amenities: "",
};

type MediaItem = {
  id?: string;
  url?: string;
  file?: File;
  alt: string;
  isCover: boolean;
  preview?: string;
};

const Admin = () => {
  const { user, accessToken, refreshSession } = useAuth();
  const { toast } = useToast();
  const [properties, setProperties] = useState<Property[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [form, setForm] = useState(emptyForm);
  const [mediaItems, setMediaItems] = useState<MediaItem[]>([]);
  const [urlInput, setUrlInput] = useState({ url: "", alt: "" });
  const [fileInput, setFileInput] = useState<{ file: File | null; alt: string }>({ file: null, alt: "" });

  const canSubmit = useMemo(() => Boolean(user), [user]);

  const normalizeCover = (items: MediaItem[]) => {
    if (!items.length) return items;
    const hasCover = items.some((item) => item.isCover);
    if (!hasCover) {
      items[0].isCover = true;
    }
    return items;
  };

  const fetchWithAuth = async (url: string, init?: RequestInit) => {
    let token = accessToken || authStorage.getAccessToken();

    const doFetch = (authToken?: string) =>
      fetch(url, {
        ...init,
        headers: {
          ...(init?.headers || {}),
          ...(authToken ? { Authorization: `Bearer ${authToken}` } : {}),
        },
      });

    let response = await doFetch(token || undefined);

    if (response.status === 401) {
      const refreshed = await refreshSession();
      if (refreshed) {
        token = authStorage.getAccessToken();
        response = await doFetch(token || undefined);
      }
    }

    return response;
  };

  const loadProperties = async () => {
    setIsLoading(true);
    try {
      const response = await fetch(`${API_BASE_URL}/api/properties`);
      const data = await response.json().catch(() => []);
      if (!response.ok) {
        throw new Error("Falha ao carregar imoveis.");
      }
      setProperties(Array.isArray(data) ? data : []);
    } catch (error) {
      toast({
        title: "Erro ao carregar imoveis",
        description: "Verifique a API e tente novamente.",
        variant: "destructive",
      });
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    loadProperties();
  }, []);

  const resetForm = () => {
    setForm(emptyForm);
    setMediaItems([]);
    setUrlInput({ url: "", alt: "" });
    setFileInput({ file: null, alt: "" });
    setEditingId(null);
  };

  const handleEdit = async (property: Property) => {
    try {
      const response = await fetch(`${API_BASE_URL}/api/properties/${property.id}`);
      const data = await response.json().catch(() => null);
      if (!response.ok || !data) {
        throw new Error("Falha ao carregar detalhes do imovel.");
      }

      setForm({
        title: data.title || "",
        type: data.type || "",
        transaction: data.transaction || "VENDA",
        price: String(data.price ?? ""),
        bedrooms: String(data.bedrooms ?? ""),
        bathrooms: String(data.bathrooms ?? ""),
        area: String(data.area ?? ""),
        neighborhood: data.neighborhood || "",
        city: data.city || "",
        state: data.state || "",
        description: data.description || "",
        amenities: Array.isArray(data.amenities) ? data.amenities.join(", ") : "",
      });

      const media = Array.isArray(data.gallery)
        ? data.gallery.map((item: MediaItem) => ({
            id: item.id,
            url: item.url,
            alt: item.alt || "",
            isCover: Boolean(item.isCover),
          }))
        : [];

      setMediaItems(normalizeCover(media));
      setEditingId(property.id);
    } catch (error) {
      toast({
        title: "Falha ao carregar imovel",
        description: "Nao foi possivel carregar os detalhes.",
        variant: "destructive",
      });
    }
  };

  const handleDelete = async (propertyId: string) => {
    if (!user) {
      toast({
        title: "Acesso restrito",
        description: "Faca login para remover imoveis.",
        variant: "destructive",
      });
      return;
    }

    try {
      const response = await fetchWithAuth(`${API_BASE_URL}/api/properties/${propertyId}`, {
        method: "DELETE",
      });

      if (!response.ok) {
        const data = await response.json().catch(() => ({}));
        throw new Error(data?.error || "Falha ao remover imovel.");
      }

      toast({ title: "Imovel removido com sucesso" });
      loadProperties();
      if (editingId === propertyId) {
        resetForm();
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : "Erro ao remover imovel.";
      toast({ title: "Erro", description: message, variant: "destructive" });
    }
  };

  const handleAddUrlMedia = () => {
    if (!urlInput.url.trim()) {
      toast({ title: "Informe um link valido.", variant: "destructive" });
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
    setUrlInput({ url: "", alt: "" });
  };

  const handleAddFileMedia = () => {
    if (!fileInput.file) {
      toast({ title: "Selecione um arquivo de imagem.", variant: "destructive" });
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
    setFileInput({ file: null, alt: "" });
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

    formData.append("title", form.title.trim());
    formData.append("type", form.type.trim());
    formData.append("transaction", form.transaction);
    formData.append("price", form.price);
    formData.append("bedrooms", form.bedrooms);
    formData.append("bathrooms", form.bathrooms);
    formData.append("area", form.area);
    formData.append("neighborhood", form.neighborhood.trim());
    formData.append("city", form.city.trim());
    formData.append("state", form.state.trim());
    formData.append("description", form.description.trim());

    const amenities = form.amenities
      .split(",")
      .map((item) => item.trim())
      .filter(Boolean);
    formData.append("amenities", JSON.stringify(amenities));

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
      formData.append("mediaUrls", JSON.stringify(mediaUrls));
    }

    if (mediaFilesMeta.length) {
      formData.append("mediaFilesMeta", JSON.stringify(mediaFilesMeta));
    }

    mediaFiles.forEach((item) => {
      formData.append("mediaFiles", item.file);
    });

    if (editingId) {
      formData.append("replaceMedia", "true");
    }

    return formData;
  };

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();

    if (!user) {
      toast({
        title: "Acesso restrito",
        description: "Faca login para salvar imoveis.",
        variant: "destructive",
      });
      return;
    }

    setIsSubmitting(true);

    try {
      const formData = buildFormData();
      const response = await fetchWithAuth(
        editingId ? `${API_BASE_URL}/api/properties/${editingId}` : `${API_BASE_URL}/api/properties`,
        {
          method: editingId ? "PUT" : "POST",
          body: formData,
        },
      );

      const data = await response.json().catch(() => ({}));

      if (!response.ok) {
        throw new Error(data?.error || "Falha ao salvar imovel.");
      }

      toast({ title: editingId ? "Imovel atualizado" : "Imovel criado" });
      resetForm();
      loadProperties();
    } catch (error) {
      const message = error instanceof Error ? error.message : "Erro ao salvar imovel.";
      toast({ title: "Erro", description: message, variant: "destructive" });
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="min-h-screen bg-background text-foreground">
      <Header />
      <main className="pt-28 pb-16">
        <div className="container mx-auto px-4 space-y-8">
          <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
            <div>
              <h1 className="text-3xl md:text-4xl font-semibold">Painel administrativo</h1>
              <p className="text-sm text-muted-foreground">
                Gerencie imoveis, imagens e informacoes exibidas no site.
              </p>
            </div>
            <Button variant="outline" onClick={loadProperties} disabled={isLoading}>
              Atualizar lista
            </Button>
          </div>

          {!user && (
            <Card className="border border-border/70">
              <CardContent className="py-6 text-sm text-muted-foreground">
                Faca login para acessar o cadastro de imoveis.
              </CardContent>
            </Card>
          )}

          <Card className="border border-border/70">
            <CardHeader>
              <CardTitle>{editingId ? "Editar imovel" : "Novo imovel"}</CardTitle>
            </CardHeader>
            <CardContent>
              <form onSubmit={handleSubmit} className="space-y-6">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <Input
                    placeholder="Titulo"
                    value={form.title}
                    onChange={(event) => setForm((prev) => ({ ...prev, title: event.target.value }))}
                    required
                  />
                  <Input
                    placeholder="Tipologia"
                    value={form.type}
                    onChange={(event) => setForm((prev) => ({ ...prev, type: event.target.value }))}
                    required
                  />
                  <select
                    className="h-12 rounded-md border border-input bg-background px-3 text-sm"
                    value={form.transaction}
                    onChange={(event) =>
                      setForm((prev) => ({ ...prev, transaction: event.target.value as TransactionType }))
                    }
                  >
                    <option value="VENDA">Venda</option>
                    <option value="ALUGUEL">Aluguel</option>
                  </select>
                  <Input
                    type="number"
                    placeholder="Preco"
                    value={form.price}
                    onChange={(event) => setForm((prev) => ({ ...prev, price: event.target.value }))}
                    required
                  />
                  <Input
                    type="number"
                    placeholder="Dormitorios"
                    value={form.bedrooms}
                    onChange={(event) => setForm((prev) => ({ ...prev, bedrooms: event.target.value }))}
                    required
                  />
                  <Input
                    type="number"
                    placeholder="Banheiros"
                    value={form.bathrooms}
                    onChange={(event) => setForm((prev) => ({ ...prev, bathrooms: event.target.value }))}
                    required
                  />
                  <Input
                    type="number"
                    placeholder="Area (m2)"
                    value={form.area}
                    onChange={(event) => setForm((prev) => ({ ...prev, area: event.target.value }))}
                    required
                  />
                  <Input
                    placeholder="Bairro"
                    value={form.neighborhood}
                    onChange={(event) => setForm((prev) => ({ ...prev, neighborhood: event.target.value }))}
                    required
                  />
                  <Input
                    placeholder="Cidade"
                    value={form.city}
                    onChange={(event) => setForm((prev) => ({ ...prev, city: event.target.value }))}
                    required
                  />
                  <Input
                    placeholder="Estado"
                    value={form.state}
                    onChange={(event) => setForm((prev) => ({ ...prev, state: event.target.value }))}
                    required
                  />
                </div>

                <Textarea
                  placeholder="Descricao do imovel"
                  value={form.description}
                  onChange={(event) => setForm((prev) => ({ ...prev, description: event.target.value }))}
                  rows={4}
                  required
                />

                <Input
                  placeholder="Comodidades (separe por virgula)"
                  value={form.amenities}
                  onChange={(event) => setForm((prev) => ({ ...prev, amenities: event.target.value }))}
                />

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="space-y-3">
                    <p className="text-sm font-semibold">Adicionar imagem por link</p>
                    <Input
                      placeholder="URL da imagem"
                      value={urlInput.url}
                      onChange={(event) => setUrlInput((prev) => ({ ...prev, url: event.target.value }))}
                    />
                    <Input
                      placeholder="Descricao da imagem"
                      value={urlInput.alt}
                      onChange={(event) => setUrlInput((prev) => ({ ...prev, alt: event.target.value }))}
                    />
                    <Button type="button" variant="secondary" onClick={handleAddUrlMedia}>
                      Adicionar link
                    </Button>
                  </div>

                  <div className="space-y-3">
                    <p className="text-sm font-semibold">Adicionar imagem por upload</p>
                    <Input
                      type="file"
                      accept="image/*"
                      onChange={(event) =>
                        setFileInput({
                          file: event.target.files ? event.target.files[0] : null,
                          alt: fileInput.alt,
                        })
                      }
                    />
                    <Input
                      placeholder="Descricao da imagem"
                      value={fileInput.alt}
                      onChange={(event) => setFileInput((prev) => ({ ...prev, alt: event.target.value }))}
                    />
                    <Button type="button" variant="secondary" onClick={handleAddFileMedia}>
                      Adicionar upload
                    </Button>
                  </div>
                </div>

                {mediaItems.length > 0 && (
                  <div className="space-y-3">
                    <p className="text-sm font-semibold">Galeria do imovel</p>
                    <div className="space-y-3">
                      {mediaItems.map((item, index) => (
                        <div
                          key={`${item.url || item.preview || index}`}
                          className="flex flex-col md:flex-row md:items-center gap-3 border border-border/70 rounded-lg p-3"
                        >
                          <div className="flex items-center gap-3">
                            <input
                              type="radio"
                              name="cover"
                              checked={item.isCover}
                              onChange={() => handleSetCover(index)}
                            />
                            <span className="text-sm">Capa</span>
                          </div>
                          <div className="flex-1">
                            <p className="text-sm text-muted-foreground break-all">
                              {item.url || item.file?.name || "Imagem enviada"}
                            </p>
                            {item.alt && (
                              <p className="text-xs text-muted-foreground">Alt: {item.alt}</p>
                            )}
                          </div>
                          <Button type="button" variant="ghost" onClick={() => handleRemoveMedia(index)}>
                            Remover
                          </Button>
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                <div className="flex flex-wrap gap-3">
                  <Button type="submit" disabled={!canSubmit || isSubmitting}>
                    {isSubmitting ? "Salvando..." : editingId ? "Atualizar imovel" : "Cadastrar imovel"}
                  </Button>
                  {editingId && (
                    <Button type="button" variant="outline" onClick={resetForm}>
                      Cancelar edicao
                    </Button>
                  )}
                </div>
              </form>
            </CardContent>
          </Card>

          <Card className="border border-border/70">
            <CardHeader>
              <CardTitle>Imoveis cadastrados</CardTitle>
            </CardHeader>
            <CardContent>
              {isLoading ? (
                <p className="text-sm text-muted-foreground">Carregando...</p>
              ) : (
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Titulo</TableHead>
                      <TableHead>Cidade</TableHead>
                      <TableHead>Transacao</TableHead>
                      <TableHead>Preco</TableHead>
                      <TableHead>Acoes</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {properties.map((property) => (
                      <TableRow key={property.id}>
                        <TableCell className="font-medium">{property.title}</TableCell>
                        <TableCell>
                          {property.city} - {property.state}
                        </TableCell>
                        <TableCell>{property.transaction}</TableCell>
                        <TableCell>{property.price}</TableCell>
                        <TableCell className="flex flex-wrap gap-2">
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={() => handleEdit(property)}
                            disabled={!user}
                          >
                            Editar
                          </Button>
                          <Button
                            size="sm"
                            variant="destructive"
                            onClick={() => handleDelete(property.id)}
                            disabled={!user}
                          >
                            Excluir
                          </Button>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              )}
            </CardContent>
          </Card>
        </div>
      </main>
      <Footer />
    </div>
  );
};

export default Admin;
