import React, { useState, useEffect } from 'react';
import { 
  DetailView, 
  DetailViewHeader, 
  DetailViewContent, 
  DetailContainer, 
  DetailColumn, 
  DetailItem 
} from '@/components/common/ui';
import EquipmentCalibrationDialog from './EquipmentCalibrationDialog';
import equipmentsService from '@/services/equipmentsService';
import type { EquipmentDto, EquipmentCalibrationDto, CreateEquipmentCalibrationDto } from '@/types/equipment';
import { formatDate } from '@/lib/utils';

interface Props {
  equipmentId: number;
  onClose: (savedId?: number | null) => void;
  onEdit: (equipment: EquipmentDto) => void;
  breadcrumbs?: string[];
}

const EquipmentDetailView: React.FC<Props> = ({ equipmentId, onClose, onEdit, breadcrumbs = [] }) => {
  const [equipment, setEquipment] = useState<EquipmentDto | null>(null);
  const [calibrations, setCalibrations] = useState<EquipmentCalibrationDto[]>([]);
  const [showCalibrationDialog, setShowCalibrationDialog] = useState(false);

  useEffect(() => {
    loadData();
  }, [equipmentId]);

  const loadData = async () => {
    try {
      const [eqData, calData] = await Promise.all([
        equipmentsService.getEquipment(equipmentId),
        equipmentsService.getEquipmentCalibrations(equipmentId)
      ]);
      setEquipment(eqData);
      setCalibrations(calData);
    } catch (err) {
      console.error('Failed to load equipment details', err);
    }
  };

  const handleAddCalibration = async (dto: CreateEquipmentCalibrationDto) => {
    try {
      await equipmentsService.addEquipmentCalibration(equipmentId, dto);
      setShowCalibrationDialog(false);
      await loadData();
      onClose(equipmentId);
    } catch (err) {
      console.error('Failed to add equipment calibration', err);
    }
  };

  if (!equipment) return null;

  return (
    <DetailView>
      <DetailViewHeader 
        title={`${equipment.equipmentCode} - ${equipment.name}`}
        onBack={() => onClose()}
        breadcrumbs={['Equipment', equipment.equipmentCode]}
      />
      
      <DetailViewContent>
        <div style={{ marginBottom: '1.5rem' }}>
          <button onClick={() => onEdit(equipment)} className="action-button primary" style={{ marginRight: '0.5rem' }}>
            Edit Equipment
          </button>
        </div>

        <DetailContainer>
          <DetailColumn>
            <DetailItem label="Equipment Code" value={equipment.equipmentCode} />
            <DetailItem label="Name" value={equipment.name} />
            <DetailItem label="Manufacturer" value={equipment.manufacturer || 'N/A'} />
            <DetailItem label="Model" value={equipment.model || 'N/A'} />
          </DetailColumn>
          <DetailColumn>
            <DetailItem label="Serial Number" value={equipment.serialNumber} />
            <DetailItem label="Location" value={equipment.location || 'N/A'} />
            <DetailItem label="Status" value={equipment.status} />
            <DetailItem label="Calibration Interval (Days)" value={equipment.calibrationIntervalDays?.toString() || 'N/A'} />
            <DetailItem label="Next Calibration Due" value={equipment.nextCalibrationDue ? formatDate(equipment.nextCalibrationDue) : 'N/A'} />
          </DetailColumn>
        </DetailContainer>

        <div style={{ marginTop: '2rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <h3 style={{ margin: 0 }}>Equipment Calibrations</h3>
          <button onClick={() => setShowCalibrationDialog(true)} className="action-button primary">
            Add Calibration
          </button>
        </div>

        <table className="data-table" style={{ marginTop: '1rem' }}>
          <thead>
            <tr>
              <th>ID</th>
              <th>Calibration Date</th>
              <th>Expiration Date</th>
              <th>Certificate No.</th>
              <th>Calibrated By</th>
              <th>Status</th>
              <th>Ref. Standards</th>
              <th>Uncertainty</th>
            </tr>
          </thead>
          <tbody>
            {calibrations.length === 0 ? (
              <tr>
                <td colSpan={8} style={{ textAlign: 'center' }}>No calibrations recorded.</td>
              </tr>
            ) : (
              calibrations.map(cal => (
                <tr key={cal.id}>
                  <td>{cal.id}</td>
                  <td>{formatDate(cal.calibrationDate)}</td>
                  <td>{formatDate(cal.expirationDate)}</td>
                  <td>{cal.certificateNumber}</td>
                  <td>{cal.calibratedBy}</td>
                  <td style={{ color: cal.resultStatus === 'Pass' ? 'green' : 'red', fontWeight: 'bold' }}>
                    {cal.resultStatus}
                  </td>
                  <td>{cal.referenceStandardsUsed || 'N/A'}</td>
                  <td>{cal.expandedUncertainty !== null && cal.expandedUncertainty !== undefined ? cal.expandedUncertainty : 'N/A'}</td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </DetailViewContent>

      <EquipmentCalibrationDialog 
        open={showCalibrationDialog}
        onSave={handleAddCalibration}
        onClose={() => setShowCalibrationDialog(false)}
      />
    </DetailView>
  );
};

export default EquipmentDetailView;
