import React, { useState, useEffect } from 'react';
import { 
  DetailView, 
  DetailViewHeader, 
  DetailViewContent, 
  DetailContainer, 
  DetailColumn, 
  DetailItem 
} from '../common/ui';
import MeasurementUnitDialog from './MeasurementUnitDialog';
import type { UnitDto } from '@/types/unit';
import unitsService from '@/services/unitsService';

interface MeasurementUnitsDetailViewProps {
  unitId: number;
  onClose: (savedId?: number | null) => void;
  onUnitUpdated?: (updatedUnit: UnitDto) => void;
  breadcrumbs?: string[];
}

const MeasurementUnitsDetailView: React.FC<MeasurementUnitsDetailViewProps> = ({ 
  unitId, 
  onClose, 
  onUnitUpdated,
  breadcrumbs = []
}) => {
  const [unit, setUnit] = useState<UnitDto | null>(null);
  const [showEditDialog, setShowEditDialog] = useState(false);

  const fetchUnitData = async () => {
    try {
      const data = await unitsService.getUnit(unitId);
      setUnit(data);
      if (onUnitUpdated) {
        onUnitUpdated(data);
      }
    } catch (err) {
      console.error('Failed to fetch unit data', err);
    }
  };

  useEffect(() => {
    fetchUnitData();
  }, [unitId]);

  const handleEditSave = async (updatedUnit: UnitDto) => {
    try {
      await unitsService.updateUnit(updatedUnit.id, { 
        name: updatedUnit.name, 
        description: updatedUnit.description 
      });
      setShowEditDialog(false);
      fetchUnitData();
    } catch (err) {
      console.error('Failed to update unit', err);
    }
  };

  if (!unit) return null;

  return (
    <DetailView>
      <DetailViewHeader 
        title={`Measurement Unit ${unit.id}`} 
        onBack={() => onClose(unitId)} 
        breadcrumbs={breadcrumbs} 
      />
      <DetailViewContent>
        <div className="page-container">
          <DetailContainer>
            <DetailColumn>
              <DetailItem label="Name" value={unit.name} />
              <DetailItem label="Description" value={unit.description || "-"} />
            </DetailColumn>
          </DetailContainer>

          <div className="action-buttons" style={{ marginTop: '1.5rem', display: 'flex', gap: '1rem' }}>
            <button onClick={() => setShowEditDialog(true)} className="action-button edit-button">Edit</button>
          </div>
        </div>
      </DetailViewContent>

      {showEditDialog && (
        <MeasurementUnitDialog 
          open={true} 
          unitData={unit} 
          onSave={handleEditSave}
          onClose={() => setShowEditDialog(false)} 
        />
      )}
    </DetailView>
  );
};

export default MeasurementUnitsDetailView;
