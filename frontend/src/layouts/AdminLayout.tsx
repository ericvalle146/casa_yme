import { Outlet, Navigate } from 'react-router-dom';
import { useAuth } from '@/context/AuthContext';
import Header from '@/components/Header';
import Footer from '@/components/Footer';
import AdminSidebar from '@/components/admin/AdminSidebar';

const AdminLayout = () => {
  const { user, isLoading } = useAuth();

  // Aguardar carregamento da sessão
  if (isLoading) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto mb-4"></div>
          <p className="text-muted-foreground">Carregando...</p>
        </div>
      </div>
    );
  }

  // Verificar se usuário está autenticado e é CORRETOR ou ADMIN
  if (!user) {
    return <Navigate to="/" replace />;
  }

  if (user.userType !== 'CORRETOR' && user.userType !== 'ADMIN') {
    return (
      <div className="min-h-screen bg-background">
        <Header />
        <main className="pt-32 pb-24">
          <div className="container mx-auto px-4 max-w-4xl">
            <div className="bg-destructive/10 border border-destructive/20 rounded-xl p-8 text-center">
              <h1 className="text-2xl font-bold text-destructive mb-2">Acesso Negado</h1>
              <p className="text-muted-foreground mb-6">
                Apenas corretores e administradores podem acessar o painel administrativo.
              </p>
              <a
                href="/"
                className="inline-block bg-primary text-primary-foreground px-6 py-2 rounded-md hover:bg-primary/90 transition-colors"
              >
                Voltar ao Início
              </a>
            </div>
          </div>
        </main>
        <Footer />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background">
      <Header />
      <div className="pt-20">
        <div className="flex min-h-[calc(100vh-5rem)]">
          {/* Sidebar */}
          <AdminSidebar />

          {/* Main Content Area */}
          <main className="flex-1 p-6 lg:p-8 overflow-x-hidden">
            <div className="max-w-7xl mx-auto">
              <Outlet />
            </div>
          </main>
        </div>
      </div>
      <Footer />
    </div>
  );
};

export default AdminLayout;
