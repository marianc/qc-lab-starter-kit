import React from 'react';
import styles from './DialogFooter.module.css';

interface Props {
  children?: React.ReactNode;
  className?: string;
}

const DialogFooter: React.FC<Props> = ({ children, className = "" }) => {
  return (
    <div className={`${styles.footer} ${className}`}>
      {children}
    </div>
  );
};

export default DialogFooter;
