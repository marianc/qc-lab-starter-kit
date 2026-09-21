import React, { useState, useEffect } from 'react';
import MeasurementUnitDialog from '@/components/units/MeasurementUnitDialog';
import MeasurementUnitsDetailView from '@/components/units/MeasurementUnitsDetailView';
import type { UnitDto } from '@/types/unit';
import unitsService from '@/services/unitsService';

const MeasurementUnitsPage: React.FC = () => {
  const [measurementUnits, setMeasurementUnits] = useState<UnitDto[]>([]);
  const [showDialog, setShowDialog] = useState(false);
  const [currentUnit, setCurrentUnit] = useState<UnitDto | null>(null);
  const [selectedUnitId, setSelectedUnitId] = useState<number | null>(null);
  const [isDetailOpen, setIsDetailOpen] = useState(false);
  const [lastEditedUnitId, setLastEditedUnitId] = useState<number | null>(null);

  const fetchMeasurementUnits = async () => {
    try {
      const data = await unitsService.getAllUnits();
      const sorted = [...data].sort((a, b) => a.name.localeCompare(b.name));
      setMeasurementUnits(sorted);
    } catch (err) {
      console.error('Failed to fetch units', err);
    }
  };

  useEffect(() => {
    fetchMeasurementUnits();
  }, []);

  const addNewMeasurementUnit = () => {
    setCurrentUnit({ id: 0, name: '' });
    setShowDialog(true);
  };

  const openDetail = (id: number) => {
    setSelectedUnitId(id);
    setLastEditedUnitId(id);
    setIsDetailOpen(true);
  };

  const handleDetailClose = (savedId?: number | null) => {
    setIsDetailOpen(false);
    setSelectedUnitId(null);
    fetchMeasurementUnits();
    if (savedId) {
      setLastEditedUnitId(savedId);
    }
  };

  const handleSaveMeasurementUnit = async (unitData: UnitDto) => {
    try {
      let savedId = unitData.id;
      if (unitData.id > 0) {
        await unitsService.updateUnit(unitData.id, { 
          name: unitData.name, 
          description: unitData.description 
        });
      } else {
        const result = await unitsService.createUnit({ 
          name: unitData.name, 
          description: unitData.description 
        });
        savedId = result.id;
      }
      setLastEditedUnitId(savedId);
      await fetchMeasurementUnits();
      setShowDialog(false);
      setCurrentUnit(null);
    } catch (err) {
      console.error('Failed to save unit', err);
    }
  };

  const handleUnitUpdated = (updatedUnit: UnitDto) => {
    setMeasurementUnits(prev => prev.map(u => u.id === updatedUnit.id ? updatedUnit : u));
  };

  return (
    <div className="page-container">
      <h1 className="page-title">Measurement Units Management</h1>

      <button onClick={addNewMeasurementUnit} className="action-button primary">Add New Measurement Unit</button>

      <table className="data-table">
        <thead>
          <tr>
            <th>ID</th>
            <th>Name</th>
            <th>Description</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {measurementUnits.map((unit) => (
            <tr key={unit.id} className={unit.id === lastEditedUnitId ? "highlighted-row" : ""}>
              <td>{unit.id}</td>
              <td>{unit.name}</td>
              <td>{unit.description || '-'}</td>
              <td>
                <button onClick={() => openDetail(unit.id)} className="action-button edit-button small-button">Details</button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>

      {isDetailOpen && selectedUnitId !== null && (
        <MeasurementUnitsDetailView 
          unitId={selectedUnitId}
          onClose={handleDetailClose}
          onUnitUpdated={handleUnitUpdated}
          breadcrumbs={["Measurement Units"]} 
        />
      )}

      {showDialog && (
        <MeasurementUnitDialog 
          open={true}
          unitData={currentUnit}
          onSave={handleSaveMeasurementUnit}
          onClose={() => setShowDialog(false)} 
        />
      )}
    </div>
  );
};

export default MeasurementUnitsPage;
