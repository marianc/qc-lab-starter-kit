import type { UserSessionDto } from '@/types/auth';
import { create } from 'zustand';

interface AuthState {
  user: UserSessionDto | null;
  isAuthenticated: boolean;
  isInitialized: boolean;
  setUser: (user: UserSessionDto | null) => void;
  setInitialized: (initialized: boolean) => void;
  logout: () => void;
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  isAuthenticated: false,
  isInitialized: false,
  setUser: (user) => set({ user, isAuthenticated: !!user }),
  setInitialized: (isInitialized) => set({ isInitialized }),
  logout: () => set({ user: null, isAuthenticated: false }),
}));
