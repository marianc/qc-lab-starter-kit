import React, { useState, useCallback, useRef } from 'react';
import styles from './Accordion.module.css';
import { AccordionContext } from './AccordionContext';

interface Props {
  title: string;
  children?: React.ReactNode;
}

const Accordion: React.FC<Props> = ({ title, children }) => {
  const itemsRef = useRef<Record<string, (collapsed: boolean) => void>>({});

  const registerItem = useCallback((id: string, setCollapsed: (collapsed: boolean) => void) => {
    itemsRef.current[id] = setCollapsed;
  }, []);

  const unregisterItem = useCallback((id: string) => {
    delete itemsRef.current[id];
  }, []);

  const expandAll = () => {
    Object.values(itemsRef.current).forEach(setCollapsed => setCollapsed(false));
  };

  const collapseAll = () => {
    Object.values(itemsRef.current).forEach(setCollapsed => setCollapsed(true));
  };

  return (
    <div className={styles.accordionContainer}>
      <div className={styles.accordionHeaderBar}>
        <h3>{title}</h3>
        <div className={styles.accordionControls}>
          <button className="action-button secondary small-button" onClick={expandAll}>Expand All</button>
          <button className="action-button secondary small-button" onClick={collapseAll}>Collapse All</button>
        </div>
      </div>
      <div className={styles.accordionBody}>
        <AccordionContext.Provider value={{ registerItem, unregisterItem }}>
          {children}
        </AccordionContext.Provider>
      </div>
    </div>
  );
};

export default Accordion;
