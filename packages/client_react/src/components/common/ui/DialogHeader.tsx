import React from 'react';
import styles from './DialogHeader.module.css';
import { useDialogContext } from './DialogContext';

interface Props {
  children?: React.ReactNode;
  className?: string;
}

const DialogHeader: React.FC<Props> = ({ children, className = "" }) => {
  const { handleMouseDown } = useDialogContext();

  return (
    <div 
      className={`${styles.header} ${className}`}
      onMouseDown={handleMouseDown}
      onTouchStart={handleMouseDown}
    >
      {children}
    </div>
  );
};

export default DialogHeader;