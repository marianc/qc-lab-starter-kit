import React, { useEffect } from 'react';
import { Outlet, useNavigate, useLocation } from 'react-router-dom';
import Header from './Header';
import Sidebar from './Sidebar';
import { useAuthStore } from '@/store/authStore';
import styles from './MainLayout.module.css';

const MainLayout: React.FC = () => {
  const { user, isAuthenticated, isInitialized } = useAuthStore();
  const navigate = useNavigate();
  const location = useLocation();

  useEffect(() => {
    if (isInitialized && !isAuthenticated) {
      navigate('/login');
    }
    
    if (isInitialized && isAuthenticated && user?.mustChangePassword) {
      if (location.pathname !== '/change-password') {
        navigate('/change-password');
      }
    }
  }, [isAuthenticated, isInitialized, user, navigate, location.pathname]);

  if (!isInitialized) {
    return <div>Loading...</div>;
  }

  return (
    <div className={styles.page}>
      <Header />
      <Sidebar />
      <main className={styles.main}>
        <Outlet />
      </main>
    </div>
  );
};

export default MainLayout;