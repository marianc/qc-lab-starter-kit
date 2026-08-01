import apiClient from './apiClient';
import type { ValueTypeDto } from '../types/valueType';

const valueTypesService = {
  async getAllValueTypes(): Promise<ValueTypeDto[]> {
    const response = await apiClient.get<ValueTypeDto[]>('api/value_types');
    return response.data;
  },
};

export default valueTypesService;
