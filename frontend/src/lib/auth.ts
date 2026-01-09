type StoredUser = {
  id: string;
  name: string;
  email: string;
};

type AuthSession = {
  accessToken: string;
  refreshToken: string;
  user: StoredUser;
};

const ACCESS_TOKEN_KEY = "casayme.auth.accessToken";
const REFRESH_TOKEN_KEY = "casayme.auth.refreshToken";
const USER_KEY = "casayme.auth.user";

const canUseStorage = () => typeof window !== "undefined" && Boolean(window.localStorage);

export const authStorage = {
  setSession: ({ accessToken, refreshToken, user }: AuthSession) => {
    if (!canUseStorage()) return;
    window.localStorage.setItem(ACCESS_TOKEN_KEY, accessToken);
    window.localStorage.setItem(REFRESH_TOKEN_KEY, refreshToken);
    window.localStorage.setItem(USER_KEY, JSON.stringify(user));
  },

  clearSession: () => {
    if (!canUseStorage()) return;
    window.localStorage.removeItem(ACCESS_TOKEN_KEY);
    window.localStorage.removeItem(REFRESH_TOKEN_KEY);
    window.localStorage.removeItem(USER_KEY);
  },

  getAccessToken: () => {
    if (!canUseStorage()) return null;
    return window.localStorage.getItem(ACCESS_TOKEN_KEY);
  },

  getRefreshToken: () => {
    if (!canUseStorage()) return null;
    return window.localStorage.getItem(REFRESH_TOKEN_KEY);
  },

  getUser: (): StoredUser | null => {
    if (!canUseStorage()) return null;
    const raw = window.localStorage.getItem(USER_KEY);
    if (!raw) return null;
    try {
      return JSON.parse(raw) as StoredUser;
    } catch (error) {
      return null;
    }
  },
};
