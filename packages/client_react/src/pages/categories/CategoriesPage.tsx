import React, { useState, useEffect } from 'react';
import CategoryDetailView from '@/components/categories/CategoryDetailView';
import CategoryDialog from '@/components/categories/CategoryDialog';
import type { CategoryDto } from '@/types/category';
import categoriesService from '@/services/categoriesService';

const CategoriesPage: React.FC = () => {
  const [categories, setCategories] = useState<CategoryDto[]>([]);
  const [selectedCategoryId, setSelectedCategoryId] = useState<number | null>(null);
  const [lastEditedCategoryId, setLastEditedCategoryId] = useState<number | null>(null);
  const [isAddDialogOpen, setIsAddDialogOpen] = useState(false);
  const [isDetailViewOpen, setIsDetailViewOpen] = useState(false);

  const fetchCategories = async () => {
    try {
      const data = await categoriesService.getAllCategories();
      setCategories(data);
    } catch (err) {
      console.error('Failed to fetch categories', err);
    }
  };

  useEffect(() => {
    fetchCategories();
  }, []);

  const handleAddCategory = () => {
    setIsAddDialogOpen(true);
  };

  const handleDetailsCategory = (id: number) => {
    setSelectedCategoryId(id);
    setIsDetailViewOpen(true);
  };

  const handleDetailViewClose = (savedId?: number | null) => {
    setIsDetailViewOpen(false);
    setSelectedCategoryId(null);
    fetchCategories();
    if (savedId) {
      setLastEditedCategoryId(savedId);
    }
  };

  const handleCategoryDialogClose = (savedId?: number | null) => {
    setIsAddDialogOpen(false);
    fetchCategories();
    if (savedId) {
      setLastEditedCategoryId(savedId);
    }
  };

  return (
    <div className="page-container">
      <h2 className="page-title">Categories</h2>
      <button onClick={handleAddCategory} className="action-button primary">Add New Category</button>
      <table className="data-table">
        <thead>
          <tr>
            <th>ID</th>
            <th>Name</th>
            <th>Code</th>
            <th>Description</th>
            <th>Is Obsolete</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {categories.map((category) => (
            <tr 
              key={category.id} 
              className={category.id === lastEditedCategoryId ? "highlighted-row" : ""}
            >
              <td>{category.id}</td>
              <td>{category.name}</td>
              <td>{category.code}</td>
              <td>{category.description}</td>
              <td>{category.isObsolete ? "Yes" : "No"}</td>
              <td>
                <button 
                  onClick={() => handleDetailsCategory(category.id)} 
                  className="action-button edit-button small-button"
                >
                  Details
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>

      {isDetailViewOpen && selectedCategoryId !== null && (
        <CategoryDetailView 
          categoryId={selectedCategoryId}
          onClose={handleDetailViewClose} 
          breadcrumbs={["Categories"]} 
        />
      )}

      {isAddDialogOpen && (
        <CategoryDialog 
          open={true} 
          onClose={handleCategoryDialogClose} 
        />
      )}
    </div>
  );
};

export default CategoriesPage;
