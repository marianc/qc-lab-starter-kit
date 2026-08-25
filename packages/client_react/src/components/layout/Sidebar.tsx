import React from 'react';
import { NavLink } from 'react-router-dom';
import { useAuthStore } from '@/store/authStore';
import styles from './Sidebar.module.css';

const Sidebar: React.FC = () => {
  const { user } = useAuthStore();
  const isAdmin = user?.roles.includes('Admin');
  const isQcPers = user?.roles.includes('QcPers');
  const isLabPers = user?.roles.includes('LabPers');

  return (
    <aside className={styles.sidebar}>
      <nav>
        <ul>
          {isAdmin && (
            <li>
              <NavLink 
                to="/users" 
                className={({ isActive }) => isActive ? styles.active : undefined}
              >
                Users
              </NavLink>
            </li>
          )}
          {isQcPers && (
            <>
              <li>
                <NavLink 
                  to="/materials" 
                  className={({ isActive }) => isActive ? styles.active : undefined}
                >
                  Materials
                </NavLink>
              </li>
              <li>
                <NavLink 
                  to="/units" 
                  className={({ isActive }) => isActive ? styles.active : undefined}
                >
                  Measurement Units
                </NavLink>
              </li>
              <li>
                <NavLink 
                  to="/norms" 
                  className={({ isActive }) => isActive ? styles.active : undefined}
                >
                  Norms
                </NavLink>
              </li>
              <li>
                <NavLink 
                  to="/tests" 
                  className={({ isActive }) => isActive ? styles.active : undefined}
                >
                  Tests & Parameters
                </NavLink>
              </li>
              <li>
                <NavLink 
                  to="/categories" 
                  className={({ isActive }) => isActive ? styles.active : undefined}
                >
                  Categories
                </NavLink>
              </li>
              <li>
                <NavLink 
                  to="/forms" 
                  className={({ isActive }) => isActive ? styles.active : undefined}
                >
                  Forms
                </NavLink>
              </li>
            </>
          )}
          <>
            <li>
              <NavLink 
                to="/receptions" 
                className={({ isActive }) => isActive ? styles.active : undefined}
              >
                Sample Receptions
              </NavLink>
            </li>
            <li>
              <NavLink 
                to="/reports" 
                className={({ isActive }) => isActive ? styles.active : undefined}
              >
                Testing Reports
              </NavLink>
            </li>
            <li>
              <NavLink 
                to="/certificates" 
                className={({ isActive }) => isActive ? styles.active : undefined}
              >
                Quality Certificates
              </NavLink>
            </li>
            <li>
              <NavLink 
                to="/specifications" 
                className={({ isActive }) => isActive ? styles.active : undefined}
              >
                Specifications
              </NavLink>
            </li>
            {isQcPers && (
              <li>
                <NavLink 
                  to="/equipment" 
                  className={({ isActive }) => isActive ? styles.active : undefined}
                >
                  Equipment
                </NavLink>
              </li>
            )}
            <li>
              <NavLink 
                to="/audit" 
                className={({ isActive }) => isActive ? styles.active : undefined}
              >
                Audit Logs
              </NavLink>
            </li>
          </>
          {/* Other menu items will be added here later */}
        </ul>
      </nav>
    </aside>
  );
};

export default Sidebar;
