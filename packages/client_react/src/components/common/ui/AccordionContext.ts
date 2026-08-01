import { createContext, useContext } from 'react';

export interface AccordionContextType {
  registerItem: (id: string, setCollapsed: (collapsed: boolean) => void) => void;
  unregisterItem: (id: string) => void;
}

export const AccordionContext = createContext<AccordionContextType | null>(null);

export const useAccordion = () => useContext(AccordionContext);
