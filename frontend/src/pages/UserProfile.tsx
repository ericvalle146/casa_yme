import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/context/AuthContext';
import { useFavoritesList } from '@/hooks/useFavorites';
import Header from '@/components/Header';
import Footer from '@/components/Footer';
import PropertyCard from '@/components/PropertyCard';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';
import { User, Heart } from 'lucide-react';

const UserProfile = () => {
  const { user } = useAuth();
  const navigate = useNavigate();

  // Redirecionar se não estiver logado
  if (!user) {
    navigate('/');
    return null;
  }

  // Estados para formulário de perfil
  const [profileData, setProfileData] = useState({
    name: user.name,
    email: user.email,
  });

  // Buscar favoritos
  const { data: favorites = [], isLoading: loadingFavorites } = useFavoritesList();

  return (
    <div className="min-h-screen bg-background">
      <Header />
      <main className="pt-32 pb-24">
        <div className="container mx-auto px-4 max-w-6xl">
          <div className="mb-8">
            <h1 className="text-4xl font-bold text-foreground mb-2">Meu Perfil</h1>
            <p className="text-muted-foreground">
              Gerencie suas informações e favoritos
            </p>
          </div>

          <Tabs defaultValue="dados" className="w-full">
            <TabsList className="grid w-full grid-cols-2 mb-8">
              <TabsTrigger value="dados">
                <User className="h-4 w-4 mr-2" />
                Meus Dados
              </TabsTrigger>
              <TabsTrigger value="favoritos">
                <Heart className="h-4 w-4 mr-2" />
                Favoritos ({favorites.length})
              </TabsTrigger>
            </TabsList>

            {/* Tab: Meus Dados */}
            <TabsContent value="dados">
              <Card>
                <CardHeader>
                  <CardTitle>Informações Pessoais</CardTitle>
                  <CardDescription>
                    Atualize seus dados pessoais aqui
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="space-y-2">
                    <Label htmlFor="name">Nome</Label>
                    <Input
                      id="name"
                      value={profileData.name}
                      onChange={(e) =>
                        setProfileData({ ...profileData, name: e.target.value })
                      }
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="email">E-mail</Label>
                    <Input id="email" value={profileData.email} disabled />
                  </div>
                  <div className="space-y-2">
                    <Label>Tipo de Usuário</Label>
                    <Input value={user.userType} disabled />
                  </div>
                  <Button className="w-full">Salvar Alterações</Button>
                </CardContent>
              </Card>
            </TabsContent>

            {/* Tab: Favoritos */}
            <TabsContent value="favoritos">
              {loadingFavorites ? (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                  {[1, 2, 3].map((i) => (
                    <div key={i} className="h-96 bg-muted/30 animate-pulse rounded-xl" />
                  ))}
                </div>
              ) : favorites.length > 0 ? (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                  {favorites.map((property: any) => (
                    <PropertyCard key={property.id} {...property} />
                  ))}
                </div>
              ) : (
                <Card>
                  <CardContent className="flex flex-col items-center justify-center py-12">
                    <Heart className="h-16 w-16 text-muted-foreground mb-4" />
                    <h3 className="text-xl font-semibold mb-2">Nenhum favorito ainda</h3>
                    <p className="text-muted-foreground text-center mb-6">
                      Explore nosso portfólio e favorite os imóveis que você mais gostou
                    </p>
                    <Button onClick={() => navigate('/')}>Explorar Imóveis</Button>
                  </CardContent>
                </Card>
              )}
            </TabsContent>
          </Tabs>
        </div>
      </main>
      <Footer />
    </div>
  );
};

export default UserProfile;
