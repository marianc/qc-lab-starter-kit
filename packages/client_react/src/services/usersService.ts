import apiClient from './apiClient';
import type { UserDto } from '../types/user';
import type { 
  CreateUserDto, 
  UpdateUserDto, 
  ResetPasswordDto 
} from '../types/users';
import type { IdDto, ToggleObsoleteDto } from '../types/models';

const usersService = {
  async getAllUsers(): Promise<UserDto[]> {
    const response = await apiClient.get<UserDto[]>('api/users');
    return response.data;
  },

  async getUser(id: number): Promise<UserDto> {
    const response = await apiClient.get<UserDto>(`api/users/${id}`);
    return response.data;
  },

  async createUser(newUser: CreateUserDto): Promise<IdDto> {
    const response = await apiClient.post<IdDto>('api/users', newUser);
    return response.data;
  },

  async updateUser(id: number, userData: UpdateUserDto): Promise<void> {
    await apiClient.put(`api/users/${id}`, userData);
  },

  async toggleObsolete(id: number, dto: ToggleObsoleteDto): Promise<void> {
    await apiClient.put(`api/users/${id}/toggle_obsolete`, dto);
  },

  async resetPassword(id: number, dto: ResetPasswordDto): Promise<void> {
    await apiClient.put(`api/users/${id}/reset_password`, dto);
  },

  async validateUniqueness(property: string, value: string, id: number): Promise<boolean> {
    const response = await apiClient.get<{ is_unique: boolean }>(`api/validate/unique?entity=User&property=${property}&value=${value}&id=${id}`);
    return response.data.is_unique;
  },
};

export default usersService;
