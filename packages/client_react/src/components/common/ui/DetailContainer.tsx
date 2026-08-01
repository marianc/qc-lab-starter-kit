import React from 'react';
import styles from './DetailContainer.module.css';

interface Props {
  children?: React.ReactNode;
  className?: string;
}

const DetailContainer: React.FC<Props> = ({ children, className = "" }) => {
  return (
    <div className={`${styles.container} ${className}`}>
      {children}
    </div>
  );
};

export default DetailContainer;
