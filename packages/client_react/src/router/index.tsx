import { createBrowserRouter, RouterProvider, Navigate } from 'react-router-dom';
import App from '@/App';
import HomePage from '@/pages/HomePage';
import LoginPage from '@/pages/auth/LoginPage';
import ChangePasswordPage from '@/pages/auth/ChangePasswordPage';
import UsersPage from '@/pages/users/UsersPage';
import MaterialsPage from '@/pages/materials/MaterialsPage';
import MeasurementUnitsPage from '@/pages/units/MeasurementUnitsPage';
import TestsPage from '@/pages/tests/TestsPage';
import CategoriesPage from '@/pages/categories/CategoriesPage';
import NormsPage from '@/pages/norms/NormsPage';
import FormGroupsPage from '@/pages/formGroups/FormGroupsPage';
import ReportsPage from '@/pages/reports/ReportsPage';
import SpecificationsPage from '@/pages/specifications/SpecificationsPage';
import EquipmentsPage from '@/pages/equipments/EquipmentsPage';
import ReagentsPage from '@/pages/reagents/ReagentsPage';
import CertificatesPage from '@/pages/certificates/CertificatesPage';
import ReceptionsPage from '@/pages/receptions/ReceptionsPage';
import AuditLogsPage from '@/pages/audit/AuditLogsPage';
import MainLayout from '@/components/layout/MainLayout';

const router = createBrowserRouter([
  {
    path: '/',
    element: <App />,
    children: [
      {
        element: <MainLayout />,
        children: [
          { path: '/', element: <HomePage /> },
          { path: '/users', element: <UsersPage /> },
          { path: '/materials', element: <MaterialsPage /> },
          { path: '/units', element: <MeasurementUnitsPage /> },
          { path: '/norms', element: <NormsPage /> },
          { path: '/tests', element: <TestsPage /> },
          { path: '/categories', element: <CategoriesPage /> },
          { path: '/forms', element: <FormGroupsPage /> },
          { path: '/receptions', element: <ReceptionsPage /> },
          { path: '/reports', element: <ReportsPage /> },
          { path: '/certificates', element: <CertificatesPage /> },
          { path: '/specifications', element: <SpecificationsPage /> },
          { path: '/equipment', element: <EquipmentsPage /> },
          { path: '/reagents', element: <ReagentsPage /> },
          { path: '/audit', element: <AuditLogsPage /> },
        ]
      },
      { path: '/login', element: <LoginPage /> },
      { path: '/change-password', element: <ChangePasswordPage /> },
      { path: '*', element: <Navigate to="/" replace /> }
    ]
  },
]);

const AppRouter = () => {
  return <RouterProvider router={router} />;
};

export default AppRouter;