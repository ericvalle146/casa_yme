import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { API_BASE_URL } from '@/lib/api';
import { authStorage } from '@/lib/auth';
import { useAuth } from '@/context/AuthContext';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { toast } from 'sonner';
import { Plus, Eye, Edit, Trash2, Home, Search } from 'lucide-react';

const PropertyList = () => {
  const { accessToken, refreshSession } = useAuth();
  const navigate = useNavigate();
  const queryClient = useQueryClient();

  const [searchTerm, setSearchTerm] = useState('');
  const [filterType, setFilterType] = useState('all');
  const [filterTransaction, setFilterTransaction] = useState('all');
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [propertyToDelete, setPropertyToDelete] = useState<string | null>(null);

  // Buscar imóveis
  const { data: properties = [], isLoading, refetch } = useQuery({
    queryKey: ['admin-properties-list'],
    queryFn: async () => {
      const response = await fetch(`${API_BASE_URL}/api/properties`);
      if (!response.ok) throw new Error('Falha ao carregar imóveis');
      return response.json();
    },
  });

  // Mutation para deletar
  const deleteMutation = useMutation({
    mutationFn: async (propertyId: string) => {
      let token = accessToken || authStorage.getAccessToken();

      const doFetch = (authToken?: string) =>
        fetch(`${API_BASE_URL}/api/properties/${propertyId}`, {
          method: 'DELETE',
          headers: {
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

      if (!response.ok) {
        const data = await response.json().catch(() => ({}));
        throw new Error(data?.error || 'Falha ao remover imóvel');
      }

      return response.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-properties-list'] });
      queryClient.invalidateQueries({ queryKey: ['admin-properties'] });
      toast.success('Imóvel removido com sucesso!');
      setDeleteDialogOpen(false);
      setPropertyToDelete(null);
    },
    onError: (error: Error) => {
      toast.error(error.message || 'Erro ao remover imóvel');
    },
  });

  // Filtrar propriedades
  const filteredProperties = properties.filter((property: any) => {
    const matchesSearch =
      searchTerm === '' ||
      property.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
      property.city.toLowerCase().includes(searchTerm.toLowerCase()) ||
      property.neighborhood.toLowerCase().includes(searchTerm.toLowerCase());

    const matchesType = filterType === 'all' || property.type === filterType;
    const matchesTransaction = filterTransaction === 'all' || property.transaction === filterTransaction;

    return matchesSearch && matchesType && matchesTransaction;
  });

  const handleDeleteClick = (propertyId: string) => {
    setPropertyToDelete(propertyId);
    setDeleteDialogOpen(true);
  };

  const handleDeleteConfirm = () => {
    if (propertyToDelete) {
      deleteMutation.mutate(propertyToDelete);
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold text-foreground">Meus Imóveis</h1>
          <p className="text-muted-foreground mt-1">
            Gerencie todos os seus imóveis cadastrados
          </p>
        </div>
        <Button asChild>
          <Link to="/admin/properties/new">
            <Plus className="h-4 w-4 mr-2" />
            Adicionar Novo
          </Link>
        </Button>
      </div>

      {/* Filters */}
      <Card>
        <CardHeader>
          <CardTitle className="text-lg">Filtros</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {/* Search */}
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="Buscar por título, cidade..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-9"
              />
            </div>

            {/* Filter by Type */}
            <Select value={filterType} onValueChange={setFilterType}>
              <SelectTrigger>
                <SelectValue placeholder="Tipo de imóvel" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">Todos os tipos</SelectItem>
                <SelectItem value="Apartamento">Apartamento</SelectItem>
                <SelectItem value="Casa">Casa</SelectItem>
                <SelectItem value="Terreno">Terreno</SelectItem>
                <SelectItem value="Comercial">Comercial</SelectItem>
              </SelectContent>
            </Select>

            {/* Filter by Transaction */}
            <Select value={filterTransaction} onValueChange={setFilterTransaction}>
              <SelectTrigger>
                <SelectValue placeholder="Transação" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">Todas as transações</SelectItem>
                <SelectItem value="VENDA">Venda</SelectItem>
                <SelectItem value="ALUGUEL">Aluguel</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardContent>
      </Card>

      {/* Properties Table */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>
              {filteredProperties.length} {filteredProperties.length === 1 ? 'Imóvel' : 'Imóveis'}
            </CardTitle>
            <Button variant="outline" size="sm" onClick={() => refetch()}>
              Atualizar
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="space-y-4">
              {[1, 2, 3, 4, 5].map((i) => (
                <div key={i} className="h-20 bg-muted/30 animate-pulse rounded-lg" />
              ))}
            </div>
          ) : filteredProperties.length === 0 ? (
            <div className="text-center py-12">
              <Home className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
              <h3 className="text-lg font-semibold mb-2">
                {searchTerm || filterType !== 'all' || filterTransaction !== 'all'
                  ? 'Nenhum imóvel encontrado'
                  : 'Nenhum imóvel cadastrado'}
              </h3>
              <p className="text-muted-foreground mb-6">
                {searchTerm || filterType !== 'all' || filterTransaction !== 'all'
                  ? 'Tente ajustar os filtros de busca'
                  : 'Comece adicionando seu primeiro imóvel'}
              </p>
              {!(searchTerm || filterType !== 'all' || filterTransaction !== 'all') && (
                <Button asChild>
                  <Link to="/admin/properties/new">
                    <Plus className="h-4 w-4 mr-2" />
                    Adicionar Imóvel
                  </Link>
                </Button>
              )}
            </div>
          ) : (
            <div className="overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Imóvel</TableHead>
                    <TableHead>Localização</TableHead>
                    <TableHead>Tipo</TableHead>
                    <TableHead>Transação</TableHead>
                    <TableHead>Preço</TableHead>
                    <TableHead>Visualizações</TableHead>
                    <TableHead className="text-right">Ações</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredProperties.map((property: any) => (
                    <TableRow key={property.id}>
                      <TableCell>
                        <div className="flex items-center gap-3">
                          <div className="h-12 w-16 bg-muted rounded-md overflow-hidden flex-shrink-0">
                            {property.image ? (
                              <img
                                src={property.image}
                                alt={property.title}
                                className="h-full w-full object-cover"
                              />
                            ) : (
                              <div className="h-full w-full flex items-center justify-center">
                                <Home className="h-5 w-5 text-muted-foreground" />
                              </div>
                            )}
                          </div>
                          <div className="min-w-0">
                            <p className="font-medium text-foreground truncate">
                              {property.title}
                            </p>
                            <p className="text-xs text-muted-foreground">
                              {property.bedrooms} qts • {property.bathrooms} banheiros • {property.area}m²
                            </p>
                          </div>
                        </div>
                      </TableCell>
                      <TableCell>
                        <div>
                          <p className="font-medium">{property.city}</p>
                          <p className="text-xs text-muted-foreground">
                            {property.neighborhood} - {property.state}
                          </p>
                        </div>
                      </TableCell>
                      <TableCell>
                        <Badge variant="outline">{property.type}</Badge>
                      </TableCell>
                      <TableCell>
                        <Badge variant={property.transaction === 'VENDA' ? 'default' : 'secondary'}>
                          {property.transaction}
                        </Badge>
                      </TableCell>
                      <TableCell className="font-semibold text-primary">
                        {new Intl.NumberFormat('pt-BR', {
                          style: 'currency',
                          currency: 'BRL',
                          minimumFractionDigits: 0,
                        }).format(property.price)}
                      </TableCell>
                      <TableCell>
                        <div className="flex items-center gap-1 text-muted-foreground">
                          <Eye className="h-4 w-4" />
                          <span className="text-sm">{property.views_count || 0}</span>
                        </div>
                      </TableCell>
                      <TableCell className="text-right">
                        <div className="flex items-center justify-end gap-2">
                          <Button
                            variant="ghost"
                            size="sm"
                            asChild
                            title="Ver no site"
                          >
                            <Link to={`/propriedade/${property.id}`} target="_blank">
                              <Eye className="h-4 w-4" />
                            </Link>
                          </Button>
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => navigate(`/admin/properties/${property.id}/edit`)}
                            title="Editar"
                          >
                            <Edit className="h-4 w-4" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => handleDeleteClick(property.id)}
                            title="Excluir"
                            className="text-destructive hover:text-destructive hover:bg-destructive/10"
                          >
                            <Trash2 className="h-4 w-4" />
                          </Button>
                        </div>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Delete Confirmation Dialog */}
      <AlertDialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Confirmar Exclusão</AlertDialogTitle>
            <AlertDialogDescription>
              Tem certeza que deseja excluir este imóvel? Esta ação não pode ser desfeita.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancelar</AlertDialogCancel>
            <AlertDialogAction
              onClick={handleDeleteConfirm}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
              disabled={deleteMutation.isPending}
            >
              {deleteMutation.isPending ? 'Excluindo...' : 'Excluir'}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
};

export default PropertyList;
