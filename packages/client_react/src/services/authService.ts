import apiClient from './apiClient';
import type { ChangePasswordDto, LoginRequest, UserSessionDto } from '../types/auth';

const authService = {
  async login(request: LoginRequest): Promise<UserSessionDto> {
    const response = await apiClient.post<UserSessionDto>('api/auth/login', request);
    return response.data;
  },

  async logout(): Promise<void> {
    await apiClient.post('api/auth/logout');
  },

  async me(): Promise<UserSessionDto | null> {
    try {
      const response = await apiClient.get<UserSessionDto>('api/auth/me');
      if (response.status === 204 || !response.data) return null;
      return response.data;
    } catch (error) {
      return null;
    }
  },

  async changePassword(dto: ChangePasswordDto): Promise<void> {
    await apiClient.post('api/auth/change-password', dto);
  },
};

export default authService;
