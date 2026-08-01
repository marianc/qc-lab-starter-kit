import React from 'react';
import styles from './DetailViewContent.module.css';

interface Props {
  children?: React.ReactNode;
  className?: string;
}

const DetailViewContent: React.FC<Props> = ({ children, className = "" }) => {
  return (
    <div className={`${styles.content} ${className}`}>
      {children}
    </div>
  );
};

export default DetailViewContent;
