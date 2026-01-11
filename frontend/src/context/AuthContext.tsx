import { createContext, useContext, useEffect, useMemo, useState } from "react";
import { API_BASE_URL } from "@/lib/api";
import { authStorage } from "@/lib/auth";

export type AuthUser = {
  id: string;
  name: string;
  email: string;
  userType: 'VISITANTE' | 'CORRETOR' | 'ADMIN';
};

type AuthContextValue = {
  user: AuthUser | null;
  accessToken: string | null;
  isLoading: boolean;
  login: (session: { accessToken: string; refreshToken: string; user: AuthUser }) => void;
  logout: () => Promise<void>;
  refreshSession: () => Promise<boolean>;
};

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

const fetchJson = async (input: RequestInfo, init?: RequestInit) => {
  const response = await fetch(input, init);
  const data = await response.json().catch(() => ({}));
  return { response, data };
};

export const AuthProvider = ({ children }: { children: React.ReactNode }) => {
  const [user, setUser] = useState<AuthUser | null>(() => authStorage.getUser());
  const [accessToken, setAccessToken] = useState<string | null>(() => authStorage.getAccessToken());
  const [isLoading, setIsLoading] = useState(false);

  const clearSession = () => {
    authStorage.clearSession();
    setUser(null);
    setAccessToken(null);
  };

  const refreshSession = async () => {
    const refreshToken = authStorage.getRefreshToken();
    if (!refreshToken) {
      clearSession();
      return false;
    }

    const { response, data } = await fetchJson(`${API_BASE_URL}/api/auth/refresh`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ refreshToken }),
    });

    if (!response.ok || !data?.accessToken || !data?.refreshToken || !data?.user) {
      clearSession();
      return false;
    }

    authStorage.setSession({
      accessToken: data.accessToken,
      refreshToken: data.refreshToken,
      user: data.user,
    });

    setUser(data.user);
    setAccessToken(data.accessToken);
    return true;
  };

  const validateSession = async (token: string) => {
    const { response, data } = await fetchJson(`${API_BASE_URL}/api/auth/me`, {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    });

    if (response.ok && data?.id) {
      setUser(data);
      return true;
    }

    return false;
  };

  useEffect(() => {
    const token = authStorage.getAccessToken();
    if (!token) {
      return;
    }

    let active = true;

    const run = async () => {
      setIsLoading(true);
      const ok = await validateSession(token);
      if (!ok) {
        await refreshSession();
      }
      if (active) {
        setIsLoading(false);
      }
    };

    run();

    return () => {
      active = false;
    };
  }, []);

  const login = (session: { accessToken: string; refreshToken: string; user: AuthUser }) => {
    authStorage.setSession(session);
    setUser(session.user);
    setAccessToken(session.accessToken);
  };

  const logout = async () => {
    const refreshToken = authStorage.getRefreshToken();
    try {
      if (refreshToken) {
        await fetch(`${API_BASE_URL}/api/auth/logout`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({ refreshToken }),
        });
      }
    } catch (error) {
      // ignore logout errors
    } finally {
      clearSession();
    }
  };

  const value = useMemo(
    () => ({
      user,
      accessToken,
      isLoading,
      login,
      logout,
      refreshSession,
    }),
    [user, accessToken, isLoading],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error("useAuth deve ser usado dentro de AuthProvider.");
  }
  return context;
};
