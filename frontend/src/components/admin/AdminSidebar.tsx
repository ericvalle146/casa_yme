import { NavLink } from 'react-router-dom';
import { LayoutDashboard, Home, Plus } from 'lucide-react';
import { cn } from '@/lib/utils';

const AdminSidebar = () => {
  const navItems = [
    {
      to: '/admin/dashboard',
      icon: LayoutDashboard,
      label: 'Dashboard',
      description: 'Visão geral',
    },
    {
      to: '/admin/properties',
      icon: Home,
      label: 'Meus Imóveis',
      description: 'Gerenciar imóveis',
    },
    {
      to: '/admin/properties/new',
      icon: Plus,
      label: 'Adicionar Novo',
      description: 'Criar imóvel',
    },
  ];

  return (
    <aside className="w-64 bg-card border-r border-border min-h-full hidden md:block">
      <div className="p-6">
        <h2 className="text-lg font-semibold text-foreground mb-1">Painel Admin</h2>
        <p className="text-xs text-muted-foreground">Gerenciamento de Imóveis</p>
      </div>

      <nav className="px-3 space-y-1">
        {navItems.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            className={({ isActive }) =>
              cn(
                'flex items-start gap-3 px-3 py-3 rounded-lg transition-colors group',
                isActive
                  ? 'bg-primary text-primary-foreground'
                  : 'hover:bg-accent text-muted-foreground hover:text-foreground'
              )
            }
          >
            {({ isActive }) => (
              <>
                <item.icon
                  className={cn(
                    'h-5 w-5 flex-shrink-0 mt-0.5',
                    isActive ? 'text-primary-foreground' : 'text-muted-foreground group-hover:text-foreground'
                  )}
                />
                <div className="flex flex-col">
                  <span className="font-medium text-sm">{item.label}</span>
                  <span
                    className={cn(
                      'text-xs',
                      isActive
                        ? 'text-primary-foreground/80'
                        : 'text-muted-foreground group-hover:text-muted-foreground'
                    )}
                  >
                    {item.description}
                  </span>
                </div>
              </>
            )}
          </NavLink>
        ))}
      </nav>
    </aside>
  );
};

export default AdminSidebar;
