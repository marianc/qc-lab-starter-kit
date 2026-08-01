import apiClient from './apiClient';
import type { ReceptionTypeDto } from '../types/receptionType';

const receptionTypesService = {
  async getAllReceptionTypes(): Promise<ReceptionTypeDto[]> {
    const response = await apiClient.get<ReceptionTypeDto[]>('api/reception_types');
    return response.data;
  }
};

export default receptionTypesService;