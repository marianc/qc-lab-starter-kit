import React from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useAuthStore } from '../../store/authStore';
import styles from './Header.module.css';
import authService from '@/services/authService';

const Header: React.FC = () => {
  const { user, logout } = useAuthStore();
  const navigate = useNavigate();

  const handleLogout = async (e: React.MouseEvent) => {
    e.preventDefault();
    try {
      await authService.logout();
      logout();
      navigate('/login');
    } catch (error) {
      console.error('Logout failed', error);
    }
  };

  return (
    <header className={styles.header}>
      <h1>Quality Control</h1>
      <div className={styles['user-info']}>
        {user ? (
          <>
            <span>Welcome, {user.name}</span>
            <a href="#" onClick={handleLogout}>Logout</a>
            <Link to="/change-password">Change Password</Link>
          </>
        ) : (
          <Link to="/login">Login</Link>
        )}
      </div>
    </header>
  );
};

export default Header;