import React from 'react';
import styles from './DetailColumn.module.css';

interface Props {
  title?: string;
  className?: string;
  children?: React.ReactNode;
}

const DetailColumn: React.FC<Props> = ({ title, className = "", children }) => {
  return (
    <div className={`${styles.column} ${className}`}>
      {title && <h4 className={styles.columnTitle}>{title}</h4>}
      {children}
    </div>
  );
};

export default DetailColumn;
