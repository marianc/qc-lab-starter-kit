import React from 'react';
import styles from './DialogContent.module.css';

interface Props {
  children?: React.ReactNode;
  className?: string;
}

const DialogContent: React.FC<Props> = ({ children, className = "" }) => {
  return (
    <div className={`${styles.content} ${className}`}>
      {children}
    </div>
  );
};

export default DialogContent;
