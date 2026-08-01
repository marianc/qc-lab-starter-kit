import React from 'react';
import styles from './DragHandle.module.css';

interface Props {
  onMouseDown?: (e: React.MouseEvent) => void;
  onMouseUp?: (e: React.MouseEvent) => void;
}

const DragHandle: React.FC<Props> = ({ onMouseDown, onMouseUp }) => {
  return (
    <span className={styles.dragHandle} onMouseDown={onMouseDown} onMouseUp={onMouseUp}>
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <circle cx="9" cy="5" r="1"></circle>
        <circle cx="9" cy="12" r="1"></circle>
        <circle cx="9" cy="19" r="1"></circle>
        <circle cx="15" cy="5" r="1"></circle>
        <circle cx="15" cy="12" r="1"></circle>
        <circle cx="15" cy="19" r="1"></circle>
      </svg>
    </span>
  );
};

export default DragHandle;
