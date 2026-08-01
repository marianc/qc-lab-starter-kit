import React from 'react';
import styles from './DetailViewHeader.module.css';

interface Props {
  title?: string;
  onBack: () => void;
  breadcrumbs?: string[];
  children?: React.ReactNode;
}

const DetailViewHeader: React.FC<Props> = ({ title, onBack, breadcrumbs, children }) => {
  return (
    <div className={styles.header}>
      <div className={styles.headerLeft}>
        <button className={styles.backButton} onClick={onBack}>
          Back
        </button>
        {breadcrumbs && breadcrumbs.length > 0 && (
          <div className={styles.breadcrumbs}>
            {breadcrumbs.join(" > ")}
          </div>
        )}
      </div>
      <div className={styles.headerCenter}>
        {title && <h2 className={styles.title}>{title}</h2>}
      </div>
      <div className={styles.headerRight}>
        {children}
      </div>
    </div>
  );
};

export default DetailViewHeader;
