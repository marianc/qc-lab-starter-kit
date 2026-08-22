import React from 'react';
import AuditLogsTable from '@/components/audit/AuditLogsTable';
import styles from './AuditLogsPage.module.css';

const AuditLogsPage: React.FC = () => {
  return (
    <div className={styles.pageContainer}>
      <div className={styles.headerSection}>
        <h1 className={styles.title}>System Audit Trail</h1>
        <p className={styles.subtitle}>
          Read-only audit trail inspection tool compliant with FDA 21 CFR Part 11 (§ 11.10(e)) and ISO/IEC 17025.
        </p>
      </div>
      <AuditLogsTable />
    </div>
  );
};

export default AuditLogsPage;
