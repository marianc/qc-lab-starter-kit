import React from 'react';
import styles from './DetailItem.module.css';

interface Props {
  label?: string;
  value?: any;
  className?: string;
  children?: React.ReactNode;
}

const DetailItem: React.FC<Props> = ({ label, value, className = "", children }) => {
  const formatValue = (val: any) => {
    if (val === null || val === undefined) return null;

    if (typeof val === 'string') {
      return val.split('\n').map((line, index) => (
        <React.Fragment key={index}>
          {line}
          {index < val.split('\n').length - 1 && <br />}
        </React.Fragment>
      ));
    }

    return val;
  };

  return (
    <div className={`${styles.item} ${className}`}>
      <span className={styles.label}>{label}</span>
      <span className={styles.value}>
        {children || formatValue(value)}
      </span>
    </div>
  );
};

export default DetailItem;
