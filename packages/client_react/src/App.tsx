import { Outlet } from 'react-router-dom';
import { useEffect } from 'react';
import { useAuthStore } from './store/authStore';
import authService from './services/authService';

const App = () => {
  const { setUser, setInitialized } = useAuthStore();

  useEffect(() => {
    const initAuth = async () => {
      try {
        const user = await authService.me();
        setUser(user);
      } catch (error) {
        console.error('Auth initialization failed', error);
        setUser(null);
      } finally {
        setInitialized(true);
      }
    };

    initAuth();
  }, [setUser, setInitialized]);

  return (
    <div id="app-root">
      <Outlet />
    </div>
  );
};

export default App;
