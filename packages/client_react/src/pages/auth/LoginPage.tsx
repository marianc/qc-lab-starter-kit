import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/store/authStore';
import styles from './LoginPage.module.css';
import authService from '@/services/authService';

const LoginPage: React.FC = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const { setUser } = useAuthStore();
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    try {
      const user = await authService.login({ email, password });
      setUser(user);
      if (user.mustChangePassword) {
        navigate('/change-password');
      } else {
        navigate('/');
      }
    } catch (err: any) {
      setError('Invalid login attempt.');
    }
  };

  return (
    <div className={styles.authLayout}>
      <div className={styles.loginBox}>
        <h3>Login</h3>
        <form onSubmit={handleSubmit}>
          <div className={styles.mb3}>
            <label>Email:</label>
            <input
              type="email"
              className={styles.formControl}
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
          </div>
          <div className={styles.mb3}>
            <label>Password:</label>
            <input
              type="password"
              className={styles.formControl}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
            />
          </div>
          <button type="submit" className={styles.btnPrimary}>Login</button>
        </form>
        {error && <div className="alert alert-danger" style={{ marginTop: '1rem' }}>{error}</div>}
      </div>
    </div>
  );
};

export default LoginPage;