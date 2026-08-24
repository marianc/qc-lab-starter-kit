import axios from 'axios';
import type { ElectronicSignatureVerificationDto } from '@/types/electronicSignature';

const API_URL = '/api/signatures';

const signaturesService = {
  verifyEntitySignature: async (entityName: string, entityId: number): Promise<ElectronicSignatureVerificationDto> => {
    const response = await axios.get<ElectronicSignatureVerificationDto>(`${API_URL}/${entityName}/${entityId}`);
    return response.data;
  }
};

export default signaturesService;
