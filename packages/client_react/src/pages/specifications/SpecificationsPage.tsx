import React, { useState, useEffect } from 'react';
import SpecificationDetailView from '@/components/specifications/SpecificationDetailView';
import SpecificationDialog from '@/components/specifications/SpecificationDialog';
import styles from './SpecificationsPage.module.css';
import type { SpecDto } from '@/types/specification';
import type { MaterialDto } from '@/types/material';
import type { TestDto } from '@/types/test';
import type { UserSessionDto } from '@/types/auth';
import authService from '@/services/authService';
import materialsService from '@/services/materialsService';
import specificationsService from '@/services/specificationsService';
import testsService from '@/services/testsService';
import { formatDate } from '@/lib/utils';

const SpecificationsPage: React.FC = () => {
  const [specs, setSpecs] = useState<SpecDto[]>([]);
  const [materials, setMaterials] = useState<MaterialDto[]>([]);
  const [allTests, setAllTests] = useState<TestDto[]>([]);
  const [currentUser, setCurrentUser] = useState<UserSessionDto | null>(null);
  const [isQCPersonnel, setIsQCPersonnel] = useState(false);
  
  const [selectedMaterialId, setSelectedMaterialId] = useState(0);
  const [selectedStatus, setSelectedStatus] = useState("");

  const [selectedSpecificationId, setSelectedSpecificationId] = useState<number | null>(null);
  const [isDetailOpen, setIsDetailOpen] = useState(false);
  const [showAddDialog, setShowAddDialog] = useState(false);
  const [lastEditedSpecificationId, setLastEditedSpecificationId] = useState<number | null>(null);

  useEffect(() => {
    const init = async () => {
      const user = await authService.me();
      setCurrentUser(user);
      if (user) {
        setIsQCPersonnel(user.roles.includes('QcPers'));
        const [materialsData, specsData, testsData] = await Promise.all([
          materialsService.getAllMaterials(),
          specificationsService.getAllSpecs(user.id, user.roles.includes('QcPers')),
          testsService.getAllTests()
        ]);
        setMaterials(materialsData);
        setSpecs(specsData);
        setAllTests(testsData);
      }
    };
    init();
  }, []);

  const fetchSpecs = async () => {
    if (currentUser) {
      const specsData = await specificationsService.getAllSpecs(currentUser.id, isQCPersonnel);
      setSpecs(specsData);
    }
  };

  const filteredSpecs = specs.filter(spec => {
    const materialMatch = selectedMaterialId === 0 || spec.materialId === selectedMaterialId;
    const statusMatch = !selectedStatus || spec.status === selectedStatus;
    return materialMatch && statusMatch;
  });

  const handleViewDetails = (id: number) => {
    setSelectedSpecificationId(id);
    setIsDetailOpen(true);
  };

  const handleDetailClose = async (savedId?: number | null) => {
    setIsDetailOpen(false);
    setSelectedSpecificationId(null);
    await fetchSpecs();
    if (savedId !== undefined) {
      setLastEditedSpecificationId(savedId);
    }
  };

  const handleAddSave = async (specData: SpecDto) => {
    if (currentUser) {
      const res = await specificationsService.createSpec({ 
        materialId: specData.materialId, 
        userId: currentUser.id,
        commentsSubmitted: null
      });
      setShowAddDialog(false);
      await fetchSpecs();
      setLastEditedSpecificationId(res.id);
    }
  };

  return (
    <div className="page-container">
      <h2 className="page-title">Specifications</h2>
      {isQCPersonnel && (
        <button onClick={() => setShowAddDialog(true)} className="action-button primary">Add New Specification</button>
      )}
      <div className={styles.filters}>
        <div className={styles.filterGroup}>
          <label htmlFor="material-filter">Material:</label>
          <select 
            id="material-filter" 
            className="form-control"
            value={selectedMaterialId} 
            onChange={e => setSelectedMaterialId(Number(e.target.value))}
          >
            <option value="0">All</option>
            {materials.map(material => (
              <option key={material.id} value={material.id}>{material.name}</option>
            ))}
          </select>
        </div>
        {isQCPersonnel && (
          <div className={styles.filterGroup}>
            <label htmlFor="status-filter">Status:</label>
            <select 
              id="status-filter" 
              className="form-control"
              value={selectedStatus} 
              onChange={e => setSelectedStatus(e.target.value)}
            >
              <option value="">All</option>
              <option value="Draft">Draft</option>
              <option value="Submitted">Submitted</option>
              <option value="Cancelled">Cancelled</option>
            </select>
          </div>
        )}
        <button onClick={fetchSpecs} className="action-button primary filter-apply-button">Apply Filters</button>
      </div>
      <table className="data-table">
        <thead>
          <tr>
            <th>ID</th>
            <th>Material Name</th>
            <th>Norm Name</th>
            <th>Release Date</th>
            <th>Replaced Specification ID</th>
            <th>Cancel Date</th>
            <th>Status</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {filteredSpecs.map(spec => {
            const statusColor = 
              spec.status === 'Draft' ? 'red' :
              spec.status === 'Cancelled' ? 'orange' :
              spec.status === 'Submitted' ? 'green' : 'inherit';

            return (
              <tr key={spec.id} className={spec.id === lastEditedSpecificationId ? "highlighted-row" : ""}>
                <td>{spec.id}</td>
                <td>{spec.materialName}</td>
                <td>{spec.normName}</td>
                <td>{spec.isSubmitted ? formatDate(spec.dateSubmitted) : ""}</td>
                <td>{spec.specReplacedId ?? "-"}</td>
                <td>{formatDate(spec.dateCancelled)}</td>
                <td><span style={{ color: statusColor, fontWeight: 'bold' }}>{spec.status}</span></td>
                <td>
                  <button 
                    onClick={() => handleViewDetails(spec.id)} 
                    className={`action-button small-button ${spec.isSubmitted ? "secondary" : "edit-button"}`}
                  >
                    Details
                  </button>
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>

      {isDetailOpen && selectedSpecificationId !== null && (
        <SpecificationDetailView 
          specificationId={selectedSpecificationId}
          onClose={handleDetailClose}
          currentUser={currentUser}
          allTests={allTests}
          breadcrumbs={["Specifications"]} 
        />
      )}

      {showAddDialog && (
        <SpecificationDialog 
          open={true}
          onSave={handleAddSave}
          onClose={() => setShowAddDialog(false)} 
        />
      )}
    </div>
  );
};

export default SpecificationsPage;
