import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '../../store/authStore';
import styles from './ChangePasswordPage.module.css';
import authService from '@/services/authService';

const ChangePasswordPage: React.FC = () => {
  const [oldPassword, setOldPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);
  const { setUser } = useAuthStore();
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setSuccess(false);

    if (newPassword !== confirmPassword) {
      setError('New password and confirmation do not match.');
      return;
    }

    try {
      await authService.changePassword({ oldPassword, newPassword, confirmPassword });
      setSuccess(true);
      
      const user = await authService.me();
      setUser(user);

      setTimeout(() => {
        navigate('/');
      }, 2000);
    } catch (err: any) {
      setError('Failed to change password. Check old password.');
    }
  };

  return (
    <div className={styles.authLayout}>
      <div className={styles.changePasswordBox}>
        <h3>Change Password</h3>
        <form onSubmit={handleSubmit}>
          <div className={styles.mb3}>
            <label>Old Password:</label>
            <input
              type="password"
              className={styles.formControl}
              value={oldPassword}
              onChange={(e) => setOldPassword(e.target.value)}
              required
            />
          </div>
          <div className={styles.mb3}>
            <label>New Password:</label>
            <input
              type="password"
              className={styles.formControl}
              value={newPassword}
              onChange={(e) => setNewPassword(e.target.value)}
              required
            />
          </div>
          <div className={styles.mb3}>
            <label>Confirm Password:</label>
            <input
              type="password"
              className={styles.formControl}
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              required
            />
          </div>
          <button type="submit" className={styles.btnPrimary}>Change Password</button>
        </form>
        {success && <div className="alert alert-success" style={{ marginTop: '1rem' }}>Password changed successfully.</div>}
        {error && <div className="alert alert-danger" style={{ marginTop: '1rem' }}>{error}</div>}
      </div>
    </div>
  );
};

export default ChangePasswordPage;