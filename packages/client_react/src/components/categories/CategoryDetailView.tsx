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
  CommentDialog,
  SelectDialog
} from '../common';
import CategoryDialog from './CategoryDialog';
import styles from './CategoryDetailView.module.css';
import type { CategoryDto, CategoryTestDto } from '@/types/category';
import type { SelectableItem } from '@/types/models';
import categoriesService from '@/services/categoriesService';
import testsService from '@/services/testsService';
import { formatDate } from '@/lib/utils';

interface CategoryDetailViewProps {
  categoryId: number;
  onClose: (savedId?: number | null) => void;
  breadcrumbs?: string[];
}

const CategoryDetailView: React.FC<CategoryDetailViewProps> = ({ 
  categoryId, 
  onClose, 
  breadcrumbs = [] 
}) => {
  const [category, setCategory] = useState<CategoryDto | null>(null);
  const [associatedTests, setAssociatedTests] = useState<CategoryTestDto[]>([]);
  const [allTests, setAllTests] = useState<SelectableItem[]>([]);
  const [showEditDialog, setShowEditDialog] = useState(false);
  const [showTestDialog, setShowTestDialog] = useState(false);
  const [showConfirmationDialog, setShowConfirmationDialog] = useState(false);
  const [showDeactivateCommentDialog, setShowDeactivateCommentDialog] = useState(false);

  const fetchData = async () => {
    try {
      const data = await categoriesService.getCategory(categoryId);
      setCategory(data);
      const tests = await categoriesService.getCategoryTests(categoryId);
      setAssociatedTests(tests);
    } catch (err) {
      console.error('Failed to fetch category data', err);
    }
  };

  const fetchAllTests = async () => {
    try {
      const tests = await testsService.getAllTests();
      setAllTests(tests
        .filter(t => !t.isParam)
        .map(t => ({ id: t.id, name: t.name }))
      );
    } catch (err) {
      console.error('Failed to fetch tests', err);
    }
  };

  useEffect(() => {
    fetchData();
    fetchAllTests();
  }, [categoryId]);

  const handleEditSave = async (savedId?: number | null) => {
    setShowEditDialog(false);
    if (savedId) {
      fetchData();
    }
  };

  const handleTestSelectionSave = async (selectedTestIds: number[]) => {
    try {
      await categoriesService.updateCategoryTests(categoryId, { testIds: selectedTestIds });
      setShowTestDialog(false);
      const tests = await categoriesService.getCategoryTests(categoryId);
      setAssociatedTests(tests);
    } catch (err) {
      console.error('Failed to save test selection', err);
    }
  };

  const handleToggleStatusClick = () => {
    if (!category) return;
    if (category.isObsolete) {
      setShowConfirmationDialog(true);
    } else {
      setShowDeactivateCommentDialog(true);
    }
  };

  const handleConfirmActivation = async () => {
    if (!category) return;
    try {
      await categoriesService.toggleObsolete(categoryId, { isObsolete: false });
      setShowConfirmationDialog(false);
      fetchData();
    } catch (err) {
      console.error('Failed to activate category', err);
    }
  };

  const handleDeactivateSubmit = async (comment: string) => {
    if (!category) return;
    try {
      await categoriesService.toggleObsolete(categoryId, { isObsolete: true, comments: comment });
      setShowDeactivateCommentDialog(false);
      fetchData();
    } catch (err) {
      console.error('Failed to deactivate category', err);
    }
  };

  if (!category) return null;

  return (
    <DetailView>
      <DetailViewHeader 
        title={`Category ${category.id}`} 
        onBack={() => onClose(categoryId)} 
        breadcrumbs={breadcrumbs} 
      />
      <DetailViewContent>
        <div className="page-container">
          <DetailContainer>
            <DetailColumn>
              <DetailItem label="Name" value={category.name} />
              <DetailItem label="Code" value={category.code} />
              <DetailItem label="Description" value={category.description || "-"} />
            </DetailColumn>
            <DetailColumn>
              <DetailItem label="Date Created" value={formatDate(category.dateCreated)} />
              <DetailItem label="Is Obsolete" value={category.isObsolete ? "Yes" : "No"} />
              <DetailItem label="Date Obsolete" value={formatDate(category.dateObsolete)} />
              {category.isObsolete && category.commentsObsolete && (
                <DetailItem label="Obsolete Comment" value={category.commentsObsolete} />
              )}
            </DetailColumn>
          </DetailContainer>

          <div className={styles.actionButtons}>
            <button onClick={() => setShowEditDialog(true)} className="action-button edit-button">Edit</button>
            <button 
              onClick={handleToggleStatusClick} 
              className={`action-button ${category.isObsolete ? 'secondary' : 'delete-button'}`}
            >
              {category.isObsolete ? 'Activate' : 'Deactivate'}
            </button>
          </div>

          <h3 className="section-title">Associated Tests</h3>
          {associatedTests.length > 0 ? (
            <ul className="item-list">
              {associatedTests.map(test => (
                <li key={test.id}>{test.name}</li>
              ))}
            </ul>
          ) : (
            <p>No associated tests</p>
          )}
          
          <div className={styles.manageTestsContainer}>
            <button onClick={() => setShowTestDialog(true)} className="action-button secondary">Manage Tests</button>
          </div>
        </div>
      </DetailViewContent>

      {showEditDialog && (
        <CategoryDialog 
          open={true} 
          categoryId={categoryId} 
          onClose={handleEditSave} 
        />
      )}

      {showTestDialog && (
        <SelectDialog 
          open={true}
          title="Select Tests"
          items={allTests}
          selectedIds={associatedTests.map(t => t.id)}
          onSave={handleTestSelectionSave}
          onClose={() => setShowTestDialog(false)}
          idPrefix="test"
        />
      )}

      {showConfirmationDialog && (
        <ConfirmationDialog 
          open={true}
          title="Confirm Category Activation"
          message={`Are you sure you want to activate category ${category.name}?`}
          onConfirm={handleConfirmActivation}
          onCancel={() => setShowConfirmationDialog(false)}
        />
      )}

      {showDeactivateCommentDialog && (
        <CommentDialog 
          open={true}
          onSubmit={handleDeactivateSubmit}
          onClose={() => setShowDeactivateCommentDialog(false)}
        />
      )}
    </DetailView>
  );
};

export default CategoryDetailView;
