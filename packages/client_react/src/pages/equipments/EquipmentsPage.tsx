import React, { useState, useEffect } from 'react';
import EquipmentDetailView from '@/components/equipments/EquipmentDetailView';
import EquipmentDialog from '@/components/equipments/EquipmentDialog';
import styles from './EquipmentsPage.module.css';
import type { EquipmentDto, CreateEquipmentDto, EquipmentStatusDto } from '@/types/equipment';
import type { UserSessionDto } from '@/types/auth';
import authService from '@/services/authService';
import equipmentsService from '@/services/equipmentsService';
import { formatDate } from '@/lib/utils';

const EquipmentsPage: React.FC = () => {
  const [equipments, setEquipments] = useState<EquipmentDto[]>([]);
  const [statuses, setStatuses] = useState<EquipmentStatusDto[]>([]);
  const [currentUser, setCurrentUser] = useState<UserSessionDto | null>(null);
  const [isQCPersonnel, setIsQCPersonnel] = useState(false);
  
  const [statusFilter, setStatusFilter] = useState('');
  const [searchTerm, setSearchTerm] = useState('');

  const [selectedEquipmentId, setSelectedEquipmentId] = useState<number | null>(null);
  const [isDetailOpen, setIsDetailOpen] = useState(false);
  const [showDialog, setShowDialog] = useState(false);
  const [editingEquipment, setEditingEquipment] = useState<EquipmentDto | null>(null);
  const [lastEditedEquipmentId, setLastEditedEquipmentId] = useState<number | null>(null);
  const [currentEquipment, setCurrentEquipment] = useState<EquipmentDto | null>(null);

  useEffect(() => {
    const init = async () => {
      const user = await authService.me();
      setCurrentUser(user);
      if (user) {
        setIsQCPersonnel(user.roles.includes('QcPers'));
        const [data, statusList] = await Promise.all([
          equipmentsService.getAllEquipments(),
          equipmentsService.getEquipmentStatuses()
        ]);
        setEquipments(data);
        setStatuses(statusList);
      }
    };
    init();
  }, []);

  const fetchEquipments = async () => {
    const data = await equipmentsService.getAllEquipments();
    setEquipments(data);
  };

  const filteredEquipments = equipments.filter(eq => {
    const statusMatch = !statusFilter || eq.status === statusFilter;
    const searchMatch = !searchTerm || 
      eq.equipmentCode.toLowerCase().includes(searchTerm.toLowerCase()) ||
      eq.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      eq.serialNumber.toLowerCase().includes(searchTerm.toLowerCase());
    return statusMatch && searchMatch;
  });

  const handleViewDetails = (equipment: EquipmentDto) => {
    setSelectedEquipmentId(equipment.id);
    setCurrentEquipment(equipment);
    setIsDetailOpen(true);
  };

  const handleDetailClose = async (savedId?: number | null) => {
    setIsDetailOpen(false);
    setSelectedEquipmentId(null);
    setCurrentEquipment(null);
    await fetchEquipments();
    if (savedId !== undefined && savedId !== null) {
      setLastEditedEquipmentId(savedId);
    }
  };

  const handleSaveEquipment = async (dto: CreateEquipmentDto) => {
    if (editingEquipment) {
      await equipmentsService.updateEquipment(editingEquipment.id, dto);
      setShowDialog(false);
      setEditingEquipment(null);
      await fetchEquipments();
      setLastEditedEquipmentId(editingEquipment.id);
      
      // Update currentEquipment optimistically without unmounting/remounting or flickering
      const updatedEq: EquipmentDto = {
        ...editingEquipment,
        ...dto,
        id: editingEquipment.id,
        dateCreated: editingEquipment.dateCreated
      };
      setCurrentEquipment(updatedEq);
    } else {
      const res = await equipmentsService.createEquipment(dto);
      setShowDialog(false);
      await fetchEquipments();
      setLastEditedEquipmentId(res.id);
    }
  };

  const handleOpenAdd = () => {
    setEditingEquipment(null);
    setShowDialog(true);
  };

  const handleOpenEdit = (equipment: EquipmentDto) => {
    setEditingEquipment(equipment);
    setShowDialog(true);
  };

  return (
    <div className="page-container">
      <h2 className="page-title">Equipment</h2>
      {isQCPersonnel && (
        <button onClick={handleOpenAdd} className="action-button primary">Add New Equipment</button>
      )}

      <div className={styles.filters}>
        <div className={styles.filterGroup}>
          <label htmlFor="search-filter">Search:</label>
          <input 
            id="search-filter"
            type="text"
            className="form-control"
            placeholder="Code, Name, Serial #"
            value={searchTerm}
            onChange={e => setSearchTerm(e.target.value)}
          />
        </div>
        <div className={styles.filterGroup}>
          <label htmlFor="status-filter">Status:</label>
          <select 
            id="status-filter" 
            className="form-control"
            value={statusFilter} 
            onChange={e => setStatusFilter(e.target.value)}
          >
            <option value="">All</option>
            {statuses.map(st => (
              <option key={st.id} value={st.name}>{st.name}</option>
            ))}
          </select>
        </div>
        <button onClick={fetchEquipments} className="action-button primary filter-apply-button">Refresh</button>
      </div>

      <table className="data-table">
        <thead>
          <tr>
            <th>ID</th>
            <th>Equipment Code</th>
            <th>Name</th>
            <th>Manufacturer / Model</th>
            <th>Serial Number</th>
            <th>Location</th>
            <th>Status</th>
            <th>Next Calibration Due</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {filteredEquipments.length === 0 ? (
            <tr>
              <td colSpan={9} style={{ textAlign: 'center' }}>No equipment found.</td>
            </tr>
          ) : (
            filteredEquipments.map(eq => (
              <tr key={eq.id} className={eq.id === lastEditedEquipmentId ? "highlighted-row" : ""}>
                <td>{eq.id}</td>
                <td>{eq.equipmentCode}</td>
                <td>{eq.name}</td>
                <td>{eq.manufacturer ? `${eq.manufacturer} ${eq.model || ''}` : (eq.model || 'N/A')}</td>
                <td>{eq.serialNumber}</td>
                <td>{eq.location || 'N/A'}</td>
                <td style={{ fontWeight: 'bold' }}>{eq.status}</td>
                <td>{eq.nextCalibrationDue ? formatDate(eq.nextCalibrationDue) : 'N/A'}</td>
                <td>
                  <button onClick={() => handleViewDetails(eq)} className="action-button secondary">
                    Details
                  </button>
                </td>
              </tr>
            ))
          )}
        </tbody>
      </table>

      {isDetailOpen && selectedEquipmentId !== null && (
        <EquipmentDetailView 
          equipmentId={selectedEquipmentId}
          equipmentUpdated={currentEquipment}
          onClose={handleDetailClose}
          onEdit={handleOpenEdit}
        />
      )}

      <EquipmentDialog 
        open={showDialog}
        equipment={editingEquipment}
        onSave={handleSaveEquipment}
        onClose={() => { setShowDialog(false); setEditingEquipment(null); }}
      />
    </div>
  );
};

export default EquipmentsPage;
