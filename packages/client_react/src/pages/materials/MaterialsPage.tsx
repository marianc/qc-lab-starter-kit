import React, { useState, useEffect } from 'react';
import MaterialDialog from '@/components/materials/MaterialDialog';
import MaterialDetailView from '@/components/materials/MaterialDetailView';
import type { MaterialDto } from '@/types/material';
import type { TestDto } from '@/types/test';
import materialsService from '@/services/materialsService';
import testsService from '@/services/testsService';

const MaterialsPage: React.FC = () => {
  const [materials, setMaterials] = useState<MaterialDto[]>([]);
  const [allTests, setAllTests] = useState<TestDto[]>([]);
  const [selectedMaterialId, setSelectedMaterialId] = useState<number | null>(null);
  const [isDetailsOpen, setIsDetailsOpen] = useState(false);
  const [isAddDialogOpen, setIsAddDialogOpen] = useState(false);
  const [lastEditedMaterialId, setLastEditedMaterialId] = useState<number | null>(null);

  const fetchMaterials = async () => {
    try {
      const data = await materialsService.getAllMaterials();
      // Sort by Name as in Blazor
      const sorted = [...data].sort((a, b) => a.name.localeCompare(b.name));
      setMaterials(sorted);
    } catch (err) {
      console.error('Failed to fetch materials', err);
    }
  };

  const fetchTests = async () => {
    try {
      const data = await testsService.getAllTests();
      setAllTests(data);
    } catch (err) {
      console.error('Failed to fetch tests', err);
    }
  };

  useEffect(() => {
    fetchMaterials();
    fetchTests();
  }, []);

  const viewMaterialDetails = (id: number) => {
    setSelectedMaterialId(id);
    setLastEditedMaterialId(id);
    setIsDetailsOpen(true);
  };

  const handleDetailsClose = (savedId?: number | null) => {
    setIsDetailsOpen(false);
    setSelectedMaterialId(null);
    if (savedId) {
      setLastEditedMaterialId(savedId);
      fetchMaterials();
    }
  };

  const handleAddDialogClose = (savedId?: number | null) => {
    setIsAddDialogOpen(false);
    if (savedId) {
      setLastEditedMaterialId(savedId);
      fetchMaterials();
    }
  };

  const handleMaterialUpdated = (updatedMaterial: MaterialDto) => {
    setMaterials(prev => prev.map(m => m.id === updatedMaterial.id ? updatedMaterial : m));
  };

  return (
    <div className="page-container">
      <h1 className="page-title">Materials Management</h1>
      <button onClick={() => setIsAddDialogOpen(true)} className="action-button primary">Add New Material</button>
      <table className="data-table">
        <thead>
          <tr>
            <th>ID</th>
            <th>Name</th>
            <th>Description</th>
            <th>Norm</th>
            <th>Is Product</th>
            <th>Is Raw Material</th>
            <th>Is Obsolete</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {materials.map((material) => (
            <tr key={material.id} className={material.id === lastEditedMaterialId ? "highlighted-row" : ""}>
              <td>{material.id}</td>
              <td>{material.name}</td>
              <td>{material.description}</td>
              <td>{material.normName}</td>
              <td>{material.isProduct ? "Yes" : "No"}</td>
              <td>{material.isRawMaterial ? "Yes" : "No"}</td>
              <td>{material.isObsolete ? "Yes" : "No"}</td>
              <td>
                <button onClick={() => viewMaterialDetails(material.id)} className="action-button edit-button small-button">Details</button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>

      {isDetailsOpen && selectedMaterialId !== null && (
        <MaterialDetailView 
          materialId={selectedMaterialId}
          onClose={handleDetailsClose}
          onMaterialUpdated={handleMaterialUpdated}
          breadcrumbs={["Materials"]}
          allTests={allTests}
        />
      )}

      {isAddDialogOpen && (
        <MaterialDialog 
          open={true}
          onClose={handleAddDialogClose}
        />
      )}
    </div>
  );
};

export default MaterialsPage;
