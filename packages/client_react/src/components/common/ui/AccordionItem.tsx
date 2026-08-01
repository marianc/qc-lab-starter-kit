import React, { useState, useEffect, useId } from 'react';
import styles from './AccordionItem.module.css';
import { useAccordion } from './AccordionContext';

interface Props {
  title: string;
  defaultCollapsed?: boolean;
  children?: React.ReactNode;
}

const AccordionItem: React.FC<Props> = ({ title, defaultCollapsed = false, children }) => {
  const [collapsed, setCollapsed] = useState(defaultCollapsed);
  const accordion = useAccordion();
  const id = useId();

  useEffect(() => {
    if (accordion) {
      accordion.registerItem(id, setCollapsed);
      return () => accordion.unregisterItem(id);
    }
  }, [accordion, id]);

  const toggle = () => setCollapsed(!collapsed);

  return (
    <div className={`${styles.accordionItem} ${collapsed ? styles.collapsed : styles.expanded}`}>
      <div className={styles.accordionItemHeader} onClick={toggle}>
        <span className={styles.accordionToggleIcon}>{collapsed ? "▶" : "▼"}</span>
        <span className={styles.accordionItemTitle}>{title}</span>
      </div>
      {!collapsed && (
        <div className={styles.accordionItemContent}>
          {children}
        </div>
      )}
    </div>
  );
};

export default AccordionItem;
