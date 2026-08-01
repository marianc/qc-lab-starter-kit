import React, { useState, useEffect } from 'react';
import UserDialog from '@/components/users/UserDialog';
import UserDetailView from '@/components/users/UserDetailView';
import type { UserDto } from '@/types/user';
import usersService from '@/services/usersService';
import type { CreateUserDto, UpdateUserDto } from '@/types/users';
import { formatDate } from '@/lib/utils';

const UsersPage: React.FC = () => {
  const [users, setUsers] = useState<UserDto[]>([]);
  const [showDialog, setShowDialog] = useState(false);
  const [selectedUser, setSelectedUser] = useState<UserDto | null>(null);
  const [selectedUserId, setSelectedUserId] = useState<number | null>(null);
  const [lastVisitedUserId, setLastVisitedUserId] = useState<number | null>(null);

  useEffect(() => {
    fetchUsers();
  }, []);

  const fetchUsers = async () => {
    try {
      const data = await usersService.getAllUsers();
      setUsers(data);
    } catch (err) {
      console.error('Failed to fetch users', err);
    }
  };

  const addUser = () => {
    setSelectedUser(null);
    setShowDialog(true);
  };

  const handleSave = async (userData: UserDto) => {
    try {
      let savedId = userData.id;
      if (userData.id > 0) {
        const updateDto: UpdateUserDto = {
          tag: userData.tag,
          code: userData.code,
          email: userData.email,
          firstName: userData.firstName,
          lastName: userData.lastName,
          isAdmin: userData.isAdmin,
          isLabPers: userData.isLabPers,
          isQcPers: userData.isQcPers,
          mustChangePassword: userData.mustChangePassword
        };
        await usersService.updateUser(userData.id, updateDto);
      } else {
        const createDto: CreateUserDto = {
          tag: userData.tag,
          code: userData.code,
          email: userData.email,
          firstName: userData.firstName,
          lastName: userData.lastName,
          isAdmin: userData.isAdmin,
          isLabPers: userData.isLabPers,
          isQcPers: userData.isQcPers,
          password: userData.password || ""
        };
        const result = await usersService.createUser(createDto);
        savedId = result.id;
      }
      setLastVisitedUserId(savedId);
      setShowDialog(false);
      fetchUsers();
    } catch (err) {
      console.error('Failed to save user', err);
    }
  };

  const viewUserDetails = (id: number) => {
    setSelectedUserId(id);
    setLastVisitedUserId(id);
  };

  const handleUserUpdated = (updatedUser: UserDto) => {
    setUsers(prev => prev.map(u => u.id === updatedUser.id ? updatedUser : u));
  };

  const handleDetailBack = (id?: number | null) => {
    if (id) {
      setLastVisitedUserId(id);
    }
    setSelectedUserId(null);
  };

  return (
    <div className="page-container">
      <div>
        <h2 className="page-title">Users</h2>
        <button onClick={addUser} className="action-button primary">Add New User</button>
        <table className="data-table">
          <thead>
            <tr>
              <th>ID</th>
              <th>Name</th>
              <th>Code</th>
              <th>Admin</th>
              <th>Lab Personnel</th>
              <th>QC Personnel</th>
              <th>Must Change Password</th>
              <th>Password Changed</th>
              <th>Date Created</th>
              <th>Is Obsolete</th>
              <th>Date Obsolete</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {users.map((user) => (
              <tr key={user.id} className={user.id === lastVisitedUserId ? "highlighted-row" : ""}>
                <td>{user.id}</td>
                <td>{user.tag}</td>
                <td>{user.code}</td>
                <td>{user.isAdmin ? "Yes" : "No"}</td>
                <td>{user.isLabPers ? "Yes" : "No"}</td>
                <td>{user.isQcPers ? "Yes" : "No"}</td>
                <td>{user.mustChangePassword ? "Yes" : "No"}</td>
                <td>{formatDate(user.datePasswordChanged)}</td>
                <td>{formatDate(user.dateCreated)}</td>
                <td>{user.isObsolete ? "Yes" : "No"}</td>
                <td>{formatDate(user.dateObsolete)}</td>
                <td>
                  <button onClick={() => viewUserDetails(user.id)} className="action-button secondary small-button">Details</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {selectedUserId && (
        <UserDetailView 
          userId={selectedUserId} 
          onBack={handleDetailBack} 
          onUserUpdated={handleUserUpdated} 
          breadcrumbs={["Users"]} 
        />
      )}

      {showDialog && (
        <UserDialog 
          open={true} 
          userData={selectedUser} 
          onSave={handleSave} 
          onClose={() => setShowDialog(false)} 
        />
      )}
    </div>
  );
};

export default UsersPage;
