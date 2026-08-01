import React, { useEffect, useRef, useState } from 'react';
import { createPortal } from 'react-dom';
import styles from './Dialog.module.css';
import { DialogContext } from './DialogContext';
import type { MouseEvent as ReactMouseEvent, TouchEvent as ReactTouchEvent } from 'react';

interface Props {
  open: boolean;
  onClose?: () => void;
  className?: string;
  children?: React.ReactNode;
}

const Dialog: React.FC<Props> = ({ open, onClose, className = "", children }) => {
  const [position, setPosition] = useState({ x: 0, y: 0 });
  const dialogRef = useRef<HTMLDivElement>(null);
  
  const isDragging = useRef(false);
  const dragStart = useRef({ x: 0, y: 0 });
  const initialPos = useRef({ x: 0, y: 0 });

  useEffect(() => {
    if (open) {
      setPosition({ x: 0, y: 0 });

      const handleEscape = (event: KeyboardEvent) => {
        if (event.key === 'Escape' && onClose) {
          onClose();
        }
      };

      document.addEventListener('keydown', handleEscape);
      return () => {
        document.removeEventListener('keydown', handleEscape);
      };
    }
  }, [open, onClose]);

  const handleMouseDown = (e: ReactMouseEvent | ReactTouchEvent) => {
    if ('button' in e && e.button !== 0) return;

    // Don't drag if clicking a button or input inside the header
    const target = e.target as HTMLElement;
    if (target.tagName === 'BUTTON' || target.tagName === 'INPUT' || target.closest('button')) {
        return;
    }

    isDragging.current = true;
    
    const clientX = 'touches' in e ? e.touches[0].clientX : e.clientX;
    const clientY = 'touches' in e ? e.touches[0].clientY : e.clientY;

    dragStart.current = { x: clientX, y: clientY };
    initialPos.current = { ...position };

    document.addEventListener('mousemove', handleMouseMove);
    document.addEventListener('mouseup', handleMouseUp);
    document.addEventListener('touchmove', handleTouchMove, { passive: false });
    document.addEventListener('touchend', handleMouseUp);
  };

  const handleMouseMove = (e: MouseEvent) => {
    if (!isDragging.current) return;
    
    const dx = e.clientX - dragStart.current.x;
    const dy = e.clientY - dragStart.current.y;

    setPosition({
      x: initialPos.current.x + dx,
      y: initialPos.current.y + dy,
    });
  };

  const handleTouchMove = (e: TouchEvent) => {
    if (!isDragging.current) return;
    e.preventDefault(); 
    
    const dx = e.touches[0].clientX - dragStart.current.x;
    const dy = e.touches[0].clientY - dragStart.current.y;

    setPosition({
      x: initialPos.current.x + dx,
      y: initialPos.current.y + dy,
    });
  };

  const handleMouseUp = () => {
    isDragging.current = false;
    document.removeEventListener('mousemove', handleMouseMove);
    document.removeEventListener('mouseup', handleMouseUp);
    document.removeEventListener('touchmove', handleTouchMove);
    document.removeEventListener('touchend', handleMouseUp);
  };

  if (!open) return null;

  return createPortal(
    <DialogContext.Provider value={{ handleMouseDown }}>
      <div className={styles.overlay}>
        <div 
          ref={dialogRef}
          className={`${styles.dialog} ${className}`} 
          style={{ 
            left: '50%', 
            top: '50%', 
            transform: `translate(calc(-50% + ${position.x}px), calc(-50% + ${position.y}px))` 
          }}
          onClick={(e) => e.stopPropagation()}
        >
          {children}
        </div>
      </div>
    </DialogContext.Provider>,
    document.body
  );
};

export default Dialog;