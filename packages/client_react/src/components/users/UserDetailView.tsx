import React, { useState, useEffect } from 'react';
import { 
  DetailView, 
  DetailViewHeader, 
  DetailViewContent, 
  DetailContainer, 
  DetailColumn, 
  DetailItem
} from '../common/ui';
import { 
  ConfirmationDialog, 
  CommentDialog
} from '../common';
import UserDialog from './UserDialog';
import ResetPasswordDialog from './ResetPasswordDialog';
import styles from './UserDetailView.module.css';
import type { UserDto } from '@/types/user';
import usersService from '@/services/usersService';
import type { ResetPasswordDto, UpdateUserDto } from '@/types/users';
import { formatDate } from '@/lib/utils';

interface UserDetailViewProps {
  userId: number;
  onBack: (id?: number | null) => void;
  onUserUpdated?: (updatedUser: UserDto) => void;
  breadcrumbs?: string[];
}

const UserDetailView: React.FC<UserDetailViewProps> = ({ 
  userId, 
  onBack, 
  onUserUpdated, 
  breadcrumbs = [] 
}) => {
  const [user, setUser] = useState<UserDto | null>(null);
  
  const [showUserDialog, setShowUserDialog] = useState(false);
  const [showResetPasswordDialog, setShowResetPasswordDialog] = useState(false);
  const [showConfirmationDialog, setShowConfirmationDialog] = useState(false);
  const [showDeactivateCommentDialog, setShowDeactivateCommentDialog] = useState(false);

  useEffect(() => {
    fetchUserDetails();
  }, [userId]);

  const fetchUserDetails = async () => {
    try {
      const data = await usersService.getUser(userId);
      setUser(data);
      if (onUserUpdated) {
        onUserUpdated(data);
      }
    } catch (err) {
      console.error('Failed to fetch user details', err);
    }
  };

  const handleSaveUser = async (userData: UserDto) => {
    try {
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
      setShowUserDialog(false);
      fetchUserDetails();
    } catch (err) {
      console.error('Failed to save user', err);
    }
  };

  const handleResetPasswordSave = async (newPassword: string) => {
    try {
      const dto: ResetPasswordDto = { newPassword, confirmPassword: newPassword };
      await usersService.resetPassword(userId, dto);
      setShowResetPasswordDialog(false);
      fetchUserDetails();
    } catch (err) {
      console.error('Failed to reset password', err);
    }
  };

  const handleToggleStatusClick = () => {
    if (!user) return;
    if (user.isObsolete) {
      setShowConfirmationDialog(true);
    } else {
      setShowDeactivateCommentDialog(true);
    }
  };

  const handleConfirmActivation = async () => {
    if (user) {
      try {
        await usersService.toggleObsolete(user.id, { isObsolete: false });
        setShowConfirmationDialog(false);
        fetchUserDetails();
      } catch (err) {
        console.error('Failed to activate user', err);
      }
    }
  };

  const handleDeactivateSubmit = async (comment: string) => {
    if (user && comment.trim()) {
      try {
        await usersService.toggleObsolete(user.id, { isObsolete: true, comments: comment });
        setShowDeactivateCommentDialog(false);
        fetchUserDetails();
      } catch (err) {
        console.error('Failed to deactivate user', err);
      }
    }
  };

  return (
    <>
      <DetailView>
        <DetailViewHeader title={`User ${userId}`} onBack={() => onBack(userId)} breadcrumbs={breadcrumbs} />
        <DetailViewContent>
          <div className="page-container">
            {!user ? (
              <p>Loading user details...</p>
            ) : (
              <>
                <DetailContainer>
                  <DetailColumn>
                    <DetailItem label="Name" value={user.tag} />
                    <DetailItem label="Code" value={user.code} />
                    <DetailItem label="Email" value={user.email} />
                    <DetailItem label="First Name" value={user.firstName} />
                    <DetailItem label="Last Name" value={user.lastName} />
                    <DetailItem label="Admin" value={user.isAdmin ? "Yes" : "No"} />
                    <DetailItem label="Lab Personnel" value={user.isLabPers ? "Yes" : "No"} />
                    <DetailItem label="QC Personnel" value={user.isQcPers ? "Yes" : "No"} />
                  </DetailColumn>
                  <DetailColumn>
                    <DetailItem label="Must Change Password" value={user.mustChangePassword ? "Yes" : "No"} />
                    <DetailItem label="Password Changed" value={formatDate(user.datePasswordChanged)} />
                    <DetailItem label="Date Created" value={formatDate(user.dateCreated)} />
                    <DetailItem label="Is Obsolete" value={user.isObsolete ? "Yes" : "No"} />
                    <DetailItem label="Date Obsolete" value={formatDate(user.dateObsolete)} />
                    {user.isObsolete && user.commentsObsolete && (
                      <DetailItem label="Obsolete Comment" value={user.commentsObsolete} />
                    )}
                  </DetailColumn>
                </DetailContainer>

                <div className={styles.actionButtons}>
                  <button onClick={() => setShowUserDialog(true)} className="action-button edit-button">Edit</button>
                  <button onClick={() => setShowResetPasswordDialog(true)} className="action-button primary">Reset Password</button>
                  <button 
                    onClick={handleToggleStatusClick} 
                    className={`action-button ${user.isObsolete ? "secondary" : "delete-button"}`}
                  >
                    {user.isObsolete ? "Activate" : "Deactivate"}
                  </button>
                </div>
              </>
            )}
          </div>
        </DetailViewContent>
      </DetailView>

      {showUserDialog && user && (
        <UserDialog open={true} userData={user} onSave={handleSaveUser} onClose={() => setShowUserDialog(false)} />
      )}

      {showResetPasswordDialog && user && (
        <ResetPasswordDialog 
          open={true} 
          userId={user.id} 
          userName={user.tag} 
          onSubmit={handleResetPasswordSave} 
          onClose={() => setShowResetPasswordDialog(false)} 
        />
      )}

      {showConfirmationDialog && user && (
        <ConfirmationDialog 
          open={true} 
          title="Confirm User Activation" 
          message={`Are you sure you want to activate user ${user.tag}?`} 
          onConfirm={handleConfirmActivation} 
          onCancel={() => setShowConfirmationDialog(false)} 
        />
      )}

      {showDeactivateCommentDialog && user && (
        <CommentDialog 
          open={true}
          onSubmit={handleDeactivateSubmit}
          onClose={() => setShowDeactivateCommentDialog(false)} 
        />
      )}
    </>
  );
};

export default UserDetailView;
