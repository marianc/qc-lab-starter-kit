import type { CertificationStatusDto } from '@/types/certificationStatus';
import apiClient from './apiClient';

const certificationStatusService = {
  getCertificationStatus: async (): Promise<CertificationStatusDto[]> => {
    const response = await apiClient.get<CertificationStatusDto[]>('/api/certification_status');
    return response.data;
  }
};

export default certificationStatusService;
