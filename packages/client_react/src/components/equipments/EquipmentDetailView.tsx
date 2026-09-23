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
import styles from './EquipmentDetailView.module.css';

interface Props {
  equipmentId: number;
  onClose: (savedId?: number | null) => void;
  onEdit: (equipment: EquipmentDto) => void;
  breadcrumbs?: string[];
  equipmentUpdated?: EquipmentDto | null;
}

const EquipmentDetailView: React.FC<Props> = ({ equipmentId, onClose, onEdit, breadcrumbs = [], equipmentUpdated }) => {
  const [equipment, setEquipment] = useState<EquipmentDto | null>(equipmentUpdated || null);
  const [calibrations, setCalibrations] = useState<EquipmentCalibrationDto[]>([]);
  const [showCalibrationDialog, setShowCalibrationDialog] = useState(false);
  const [editingCalibration, setEditingCalibration] = useState<EquipmentCalibrationDto | null>(null);

  useEffect(() => {
    if (equipmentUpdated) {
      setEquipment(equipmentUpdated);
    }
    loadData();
  }, [equipmentId, equipmentUpdated]);

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

  const handleSaveCalibration = async (dto: CreateEquipmentCalibrationDto) => {
    try {
      if (editingCalibration) {
        await equipmentsService.updateEquipmentCalibration(editingCalibration.id, dto);
      } else {
        await equipmentsService.addEquipmentCalibration(equipmentId, dto);
      }
      setShowCalibrationDialog(false);
      setEditingCalibration(null);
      await loadData();
    } catch (err) {
      console.error('Failed to save equipment calibration', err);
    }
  };

  const handleOpenAddCalibration = () => {
    setEditingCalibration(null);
    setShowCalibrationDialog(true);
  };

  const handleOpenEditCalibration = (calibration: EquipmentCalibrationDto) => {
    setEditingCalibration(calibration);
    setShowCalibrationDialog(true);
  };

  if (!equipment) return null;

  return (
    <DetailView>
      <DetailViewHeader 
        title={`${equipment.equipmentCode} - ${equipment.name}`}
        onBack={() => onClose(equipmentId)}
        breadcrumbs={['Equipment', equipment.equipmentCode]}
      />
      
      <DetailViewContent>
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

        <div className={styles.actionSection}>
          <button onClick={() => onEdit(equipment)} className="action-button primary">
            Edit
          </button>
        </div>

        <div className={styles.calibrationsHeaderSection}>
          <h3 className={styles.calibrationsTitle}>Equipment Calibrations</h3>
          <button onClick={handleOpenAddCalibration} className="action-button primary">
            Add Calibration
          </button>
        </div>

        <div className={styles.tableContainer}>
          <table className="data-table">
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
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {calibrations.length === 0 ? (
                <tr>
                  <td colSpan={9} className={styles.textCenter}>No calibrations recorded.</td>
                </tr>
              ) : (
                calibrations.map(cal => (
                  <tr key={cal.id}>
                    <td>{cal.id}</td>
                    <td>{formatDate(cal.calibrationDate)}</td>
                    <td>{formatDate(cal.expirationDate)}</td>
                    <td>{cal.certificateNumber}</td>
                    <td>{cal.calibratedBy}</td>
                    <td className={cal.resultStatus === 'Pass' ? styles.statusPass : styles.statusFail}>
                      {cal.resultStatus}
                    </td>
                    <td>{cal.referenceStandardsUsed || 'N/A'}</td>
                    <td>{cal.expandedUncertainty !== null && cal.expandedUncertainty !== undefined ? cal.expandedUncertainty : 'N/A'}</td>
                    <td>
                      <button onClick={() => handleOpenEditCalibration(cal)} className="action-button secondary">
                        Edit
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </DetailViewContent>

      <EquipmentCalibrationDialog 
        open={showCalibrationDialog}
        calibration={editingCalibration}
        onSave={handleSaveCalibration}
        onClose={() => { setShowCalibrationDialog(false); setEditingCalibration(null); }}
      />
    </DetailView>
  );
};

export default EquipmentDetailView;
