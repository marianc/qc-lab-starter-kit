import { createContext, useContext } from 'react';

export const DetailViewLevelContext = createContext<number>(0);

export const useDetailViewLevel = () => useContext(DetailViewLevelContext);
