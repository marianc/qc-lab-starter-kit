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
import type { TestDto } from '@/types/test';
import type { FormDto } from '@/types/form';
import type { SelectableItem } from '@/types/models';
import categoriesService from '@/services/categoriesService';
import testsService from '@/services/testsService';
import formsService from '@/services/formsService';
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
  const [allTests, setAllTests] = useState<TestDto[]>([]);
  const [allForms, setAllForms] = useState<FormDto[]>([]);
  const [showEditDialog, setShowEditDialog] = useState(false);
  const [showTestDialog, setShowTestDialog] = useState(false);
  const [showApplicableFormsDialog, setShowApplicableFormsDialog] = useState(false);
  const [showConfirmationDialog, setShowConfirmationDialog] = useState(false);
  const [showDeactivateCommentDialog, setShowDeactivateCommentDialog] = useState(false);

  const [pendingFormTestIds, setPendingFormTestIds] = useState<number[]>([]);
  const [missingTestNames, setMissingTestNames] = useState<string[]>([]);

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
      setAllTests(tests);
    } catch (err) {
      console.error('Failed to fetch tests', err);
    }
  };

  const fetchFormsData = async () => {
    try {
      const forms = await formsService.getAllForms();
      setAllForms(forms);
    } catch (err) {
      console.error('Failed to fetch forms', err);
    }
  };

  useEffect(() => {
    fetchData();
    fetchAllTests();
    fetchFormsData();
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

  const handleApplicableFormsSave = async (selectedFormIds: number[]) => {
    if (selectedFormIds.length === 0) {
      setShowApplicableFormsDialog(false);
      return;
    }

    try {
      const formTestIdSet = new Set<number>();
      for (const formId of selectedFormIds) {
        const params = await formsService.getFormParams(formId);
        params.forEach(p => {
          const testObj = allTests.find(t => t.id === p.testId);
          if (testObj && !testObj.isParam) {
            formTestIdSet.add(p.testId);
          }
        });
      }

      const currentTestIds = new Set(associatedTests.map(t => t.id));
      const missingIds = Array.from(formTestIdSet).filter(id => !currentTestIds.has(id));

      if (missingIds.length > 0) {
        const sortedMissingTests = missingIds
          .map(id => allTests.find(t => t.id === id))
          .filter((t): t is TestDto => t !== undefined)
          .sort((a, b) => a.nrOrd - b.nrOrd);

        const names = sortedMissingTests.map(t => t.name);
        setMissingTestNames(names);
        setPendingFormTestIds(Array.from(formTestIdSet));
        setShowApplicableFormsDialog(false);
        setShowConfirmationDialog(true);
      } else {
        const combinedIds = Array.from(new Set([...currentTestIds, ...formTestIdSet]));
        await categoriesService.updateCategoryTests(categoryId, { testIds: combinedIds });
        setShowApplicableFormsDialog(false);
        fetchData();
      }
    } catch (err) {
      console.error('Failed to process applicable forms', err);
    }
  };

  const handleConfirmAddMissingTests = async () => {
    try {
      const currentTestIds = associatedTests.map(t => t.id);
      const combinedIds = Array.from(new Set([...currentTestIds, ...pendingFormTestIds]));
      await categoriesService.updateCategoryTests(categoryId, { testIds: combinedIds });
      setShowConfirmationDialog(false);
      setPendingFormTestIds([]);
      setMissingTestNames([]);
      fetchData();
    } catch (err) {
      console.error('Failed to update category tests with applicable forms', err);
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

  const selectableTests: SelectableItem[] = allTests
    .filter(t => !t.isParam)
    .map(t => ({ id: t.id, name: t.name }));

  const validForms: SelectableItem[] = allForms
    .filter(f => f.isValidated && !f.isCancelled)
    .map(f => ({ id: f.id, name: f.name }));

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
            <button onClick={() => setShowApplicableFormsDialog(true)} className="action-button secondary">Applicable Forms</button>
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
          items={selectableTests}
          selectedIds={associatedTests.map(t => t.id)}
          onSave={handleTestSelectionSave}
          onClose={() => setShowTestDialog(false)}
          idPrefix="test"
        />
      )}

      {showApplicableFormsDialog && (
        <SelectDialog 
          open={true}
          title="Select Applicable Forms"
          items={validForms}
          selectedIds={[]}
          onSave={handleApplicableFormsSave}
          onClose={() => setShowApplicableFormsDialog(false)}
          idPrefix="form"
        />
      )}

      {showConfirmationDialog && missingTestNames.length > 0 ? (
        <ConfirmationDialog 
          open={true}
          title="Add Missing Tests"
          message={
            <div>
              <p>The following tests present in the selected forms are not currently associated with this category and will be added:</p>
              <br />
              <ul style={{ listStyleType: 'disc', paddingLeft: '20px', margin: 0 }}>
                {missingTestNames.map((testName, idx) => (
                  <li key={idx}>{testName}</li>
                ))}
              </ul>
              <br />
              <p>Do you want to proceed?</p>
            </div>
          }
          onConfirm={handleConfirmAddMissingTests}
          onCancel={() => {
            setShowConfirmationDialog(false);
            setPendingFormTestIds([]);
            setMissingTestNames([]);
          }}
        />
      ) : showConfirmationDialog ? (
        <ConfirmationDialog 
          open={true}
          title="Confirm Category Activation"
          message={`Are you sure you want to activate category ${category.name}?`}
          onConfirm={handleConfirmActivation}
          onCancel={() => setShowConfirmationDialog(false)}
        />
      ) : null}

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
