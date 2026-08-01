import React, { useEffect, useState, useCallback } from 'react';
import NormDialog from '@/components/norms/NormDialog';
import NormDetailView from '@/components/norms/NormDetailView';
import type { NormDto } from '@/types/norm';
import normsService from '@/services/normsService';

const NormsPage: React.FC = () => {
  const [norms, setNorms] = useState<NormDto[]>([]);
  const [selectedNormId, setSelectedNormId] = useState<number | null>(null);
  const [isDetailOpen, setIsDetailOpen] = useState(false);
  const [showAddDialog, setShowAddDialog] = useState(false);
  const [lastEditedNormId, setLastEditedNormId] = useState<number | null>(null);

  const fetchNorms = useCallback(async () => {
    try {
      const data = await normsService.getAllNorms();
      setNorms(data);
    } catch (err) {
      console.error('Error fetching norms:', err);
    }
  }, []);

  useEffect(() => {
    fetchNorms();
  }, [fetchNorms]);

  const handleAddSave = async (norm: NormDto) => {
    try {
      const res = await normsService.createNorm({
        name: norm.name,
        description: norm.description
      });
      setShowAddDialog(false);
      await fetchNorms();
      if (res && res.id) {
        setLastEditedNormId(res.id);
      }
    } catch (err) {
      console.error('Error creating norm:', err);
      throw err;
    }
  };

  const handleDetailClose = async (savedId?: number) => {
    setIsDetailOpen(false);
    setSelectedNormId(null);
    await fetchNorms();
    if (savedId !== undefined) {
      setLastEditedNormId(savedId);
    }
  };

  const openDetail = (id: number) => {
    setSelectedNormId(id);
    setIsDetailOpen(true);
  };

  return (
    <div className="page-container">
      <h2 className="page-title">Norms</h2>
      <div className="addButtons">
        <button onClick={() => setShowAddDialog(true)} className="action-button primary">Add New Norm</button>
      </div>
      <table className="data-table">
        <thead>
          <tr>
            <th>ID</th>
            <th>Name</th>
            <th>Description</th>
            <th>Is Obsolete</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {norms.map((norm) => (
            <tr key={norm.id} className={norm.id === lastEditedNormId ? 'highlighted-row' : ''}>
              <td>{norm.id}</td>
              <td>{norm.name}</td>
              <td>{norm.description}</td>
              <td>{norm.isObsolete ? "Yes" : "No"}</td>
              <td>
                <button onClick={() => openDetail(norm.id)} className="action-button edit-button small-button">Details</button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>

      {isDetailOpen && selectedNormId !== null && (
        <NormDetailView 
          normId={selectedNormId} 
          onClose={handleDetailClose} 
          breadcrumbs={["Norms"]} 
        />
      )}

      {showAddDialog && (
        <NormDialog 
          open={true}
          onClose={() => setShowAddDialog(false)}
          onSave={handleAddSave} 
        />
      )}
    </div>
  );
};

export default NormsPage;
