import React from 'react';
import styles from './DetailView.module.css';
import { DetailViewLevelContext, useDetailViewLevel } from './DetailViewLevelContext';

interface Props {
  children?: React.ReactNode;
  className?: string;
}

const DetailView: React.FC<Props> = ({ children, className = "" }) => {
  const parentLevel = useDetailViewLevel();
  const currentLevel = parentLevel + 1;
  const zIndex = 50 + (currentLevel * 10);

  return (
    <DetailViewLevelContext.Provider value={currentLevel}>
      <div 
        className={`${styles.overlay} ${className}`} 
        style={{ zIndex }}
        data-overlay-level={currentLevel}
      >
        {children}
      </div>
    </DetailViewLevelContext.Provider>
  );
};

export default DetailView;
