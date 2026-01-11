import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { API_BASE_URL } from '@/lib/api';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Home, Eye, Heart, TrendingUp, Plus } from 'lucide-react';

const AdminDashboard = () => {
  // Buscar lista de imóveis para calcular estatísticas
  const { data: properties = [], isLoading } = useQuery({
    queryKey: ['admin-properties'],
    queryFn: async () => {
      const response = await fetch(`${API_BASE_URL}/api/properties`);
      if (!response.ok) throw new Error('Falha ao carregar imóveis');
      return response.json();
    },
  });

  const stats = {
    total: properties.length,
    active: properties.filter((p: any) => p.is_active !== false).length,
    views: properties.reduce((sum: number, p: any) => sum + (p.views_count || 0), 0),
    avgPrice: properties.length > 0
      ? Math.round(properties.reduce((sum: number, p: any) => sum + (p.price || 0), 0) / properties.length)
      : 0,
  };

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold text-foreground">Dashboard</h1>
          <p className="text-muted-foreground mt-1">
            Visão geral dos seus imóveis e estatísticas
          </p>
        </div>
        <Button asChild>
          <Link to="/admin/properties/new">
            <Plus className="h-4 w-4 mr-2" />
            Adicionar Imóvel
          </Link>
        </Button>
      </div>

      {/* Stats Cards */}
      {isLoading ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {[1, 2, 3, 4].map((i) => (
            <div key={i} className="h-32 bg-muted/30 animate-pulse rounded-xl" />
          ))}
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {/* Total de Imóveis */}
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">
                Total de Imóveis
              </CardTitle>
              <Home className="h-5 w-5 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-3xl font-bold">{stats.total}</div>
              <p className="text-xs text-muted-foreground mt-1">
                {stats.active} ativos
              </p>
            </CardContent>
          </Card>

          {/* Visualizações Totais */}
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">
                Visualizações
              </CardTitle>
              <Eye className="h-5 w-5 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-3xl font-bold">{stats.views.toLocaleString('pt-BR')}</div>
              <p className="text-xs text-muted-foreground mt-1">
                Total de acessos
              </p>
            </CardContent>
          </Card>

          {/* Preço Médio */}
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">
                Preço Médio
              </CardTitle>
              <TrendingUp className="h-5 w-5 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-3xl font-bold">
                {new Intl.NumberFormat('pt-BR', {
                  style: 'currency',
                  currency: 'BRL',
                  minimumFractionDigits: 0,
                }).format(stats.avgPrice)}
              </div>
              <p className="text-xs text-muted-foreground mt-1">
                Dos imóveis cadastrados
              </p>
            </CardContent>
          </Card>

          {/* Taxa de Conversão (futuro) */}
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">
                Em Breve
              </CardTitle>
              <Heart className="h-5 w-5 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-3xl font-bold">--</div>
              <p className="text-xs text-muted-foreground mt-1">
                Estatísticas adicionais
              </p>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Recent Properties */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Imóveis Recentes</CardTitle>
            <Button variant="outline" size="sm" asChild>
              <Link to="/admin/properties">Ver Todos</Link>
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="space-y-4">
              {[1, 2, 3].map((i) => (
                <div key={i} className="h-20 bg-muted/30 animate-pulse rounded-lg" />
              ))}
            </div>
          ) : properties.length === 0 ? (
            <div className="text-center py-12">
              <Home className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
              <h3 className="text-lg font-semibold mb-2">Nenhum imóvel cadastrado</h3>
              <p className="text-muted-foreground mb-6">
                Comece adicionando seu primeiro imóvel ao sistema
              </p>
              <Button asChild>
                <Link to="/admin/properties/new">
                  <Plus className="h-4 w-4 mr-2" />
                  Adicionar Primeiro Imóvel
                </Link>
              </Button>
            </div>
          ) : (
            <div className="space-y-4">
              {properties.slice(0, 5).map((property: any) => (
                <div
                  key={property.id}
                  className="flex items-center gap-4 p-4 border border-border rounded-lg hover:bg-accent/50 transition-colors"
                >
                  <div className="h-16 w-24 bg-muted rounded-md overflow-hidden flex-shrink-0">
                    {property.image ? (
                      <img
                        src={property.image}
                        alt={property.title}
                        className="h-full w-full object-cover"
                      />
                    ) : (
                      <div className="h-full w-full flex items-center justify-center">
                        <Home className="h-6 w-6 text-muted-foreground" />
                      </div>
                    )}
                  </div>
                  <div className="flex-1 min-w-0">
                    <h4 className="font-semibold text-foreground truncate">{property.title}</h4>
                    <p className="text-sm text-muted-foreground">
                      {property.city} - {property.state} • {property.transaction}
                    </p>
                  </div>
                  <div className="text-right flex-shrink-0">
                    <p className="font-bold text-primary">
                      {new Intl.NumberFormat('pt-BR', {
                        style: 'currency',
                        currency: 'BRL',
                        minimumFractionDigits: 0,
                      }).format(property.price)}
                    </p>
                    <p className="text-xs text-muted-foreground">
                      {property.views_count || 0} visualizações
                    </p>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Quick Actions */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card className="hover:shadow-md transition-shadow cursor-pointer" asChild>
          <Link to="/admin/properties/new">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Plus className="h-5 w-5" />
                Adicionar Novo
              </CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-sm text-muted-foreground">
                Cadastre um novo imóvel com todas as informações
              </p>
            </CardContent>
          </Link>
        </Card>

        <Card className="hover:shadow-md transition-shadow cursor-pointer" asChild>
          <Link to="/admin/properties">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Home className="h-5 w-5" />
                Gerenciar Imóveis
              </CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-sm text-muted-foreground">
                Edite ou remova imóveis existentes
              </p>
            </CardContent>
          </Link>
        </Card>

        <Card className="hover:shadow-md transition-shadow cursor-pointer" asChild>
          <Link to="/">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Eye className="h-5 w-5" />
                Ver Site
              </CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-sm text-muted-foreground">
                Visualize o site público com seus imóveis
              </p>
            </CardContent>
          </Link>
        </Card>
      </div>
    </div>
  );
};

export default AdminDashboard;
