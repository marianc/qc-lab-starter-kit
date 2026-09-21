using Microsoft.EntityFrameworkCore;
using QCLab.Client.Dtos;
using QCLab.Client.Services.Interfaces;
using QCLab.Models;

namespace QCLab.Services;

public class EquipmentsService : IEquipmentsService
{
    private readonly QualityControlContext _context;

    public EquipmentsService(QualityControlContext context)
    {
        _context = context;
    }

    public async Task<List<EquipmentDto>> GetAllEquipments()
    {
        return await _context.Equipments
            .OrderBy(e => e.EquipmentCode)
            .Select(e => new EquipmentDto
            {
                Id = e.Id,
                EquipmentCode = e.EquipmentCode,
                Name = e.Name,
                Manufacturer = e.Manufacturer,
                Model = e.Model,
                SerialNumber = e.SerialNumber,
                Location = e.Location,
                Status = e.Status,
                CalibrationIntervalDays = e.CalibrationIntervalDays,
                NextCalibrationDue = e.NextCalibrationDue,
                DateCreated = e.DateCreated
            })
            .ToListAsync();
    }

    public async Task<EquipmentDto?> GetEquipment(long id)
    {
        return await _context.Equipments
            .Where(e => e.Id == id)
            .Select(e => new EquipmentDto
            {
                Id = e.Id,
                EquipmentCode = e.EquipmentCode,
                Name = e.Name,
                Manufacturer = e.Manufacturer,
                Model = e.Model,
                SerialNumber = e.SerialNumber,
                Location = e.Location,
                Status = e.Status,
                CalibrationIntervalDays = e.CalibrationIntervalDays,
                NextCalibrationDue = e.NextCalibrationDue,
                DateCreated = e.DateCreated
            })
            .FirstOrDefaultAsync();
    }

    public async Task<IdDto> CreateEquipment(CreateEquipmentDto dto)
    {
        var equipment = new Equipment
        {
            EquipmentCode = dto.EquipmentCode,
            Name = dto.Name,
            Manufacturer = dto.Manufacturer,
            Model = dto.Model,
            SerialNumber = dto.SerialNumber,
            Location = dto.Location,
            Status = dto.Status,
            CalibrationIntervalDays = dto.CalibrationIntervalDays,
            DateCreated = DateTime.UtcNow
        };

        _context.Equipments.Add(equipment);
        await _context.SaveChangesAsync();

        return new() { Id = equipment.Id };
    }

    public async Task UpdateEquipment(long id, UpdateEquipmentDto dto)
    {
        var equipment = await _context.Equipments.FindAsync(id);
        if (equipment == null) throw new ArgumentException("Equipment not found");

        equipment.EquipmentCode = dto.EquipmentCode;
        equipment.Name = dto.Name;
        equipment.Manufacturer = dto.Manufacturer;
        equipment.Model = dto.Model;
        equipment.SerialNumber = dto.SerialNumber;
        equipment.Location = dto.Location;
        equipment.Status = dto.Status;
        equipment.CalibrationIntervalDays = dto.CalibrationIntervalDays;

        await _context.SaveChangesAsync();
    }

    public async Task<List<EquipmentCalibrationDto>> GetEquipmentCalibrations(long equipmentId)
    {
        return await _context.EquipmentCalibrations
            .Where(c => c.EquipmentId == equipmentId)
            .OrderByDescending(c => c.CalibrationDate)
            .Select(c => new EquipmentCalibrationDto
            {
                Id = c.Id,
                EquipmentId = c.EquipmentId,
                CalibrationDate = c.CalibrationDate,
                ExpirationDate = c.ExpirationDate,
                CertificateNumber = c.CertificateNumber,
                CalibratedBy = c.CalibratedBy,
                ResultStatus = c.ResultStatus,
                ReferenceStandardsUsed = c.ReferenceStandardsUsed,
                ExpandedUncertainty = c.ExpandedUncertainty,
                DateCreated = c.DateCreated
            })
            .ToListAsync();
    }

    public async Task<IdDto> AddEquipmentCalibration(long equipmentId, CreateEquipmentCalibrationDto dto)
    {
        var equipment = await _context.Equipments.FindAsync(equipmentId);
        if (equipment == null) throw new ArgumentException("Equipment not found");

        var calibration = new EquipmentCalibration
        {
            EquipmentId = equipmentId,
            CalibrationDate = dto.CalibrationDate,
            ExpirationDate = dto.ExpirationDate,
            CertificateNumber = dto.CertificateNumber,
            CalibratedBy = dto.CalibratedBy,
            ResultStatus = dto.ResultStatus,
            ReferenceStandardsUsed = dto.ReferenceStandardsUsed,
            ExpandedUncertainty = dto.ExpandedUncertainty,
            DateCreated = DateTime.UtcNow
        };

        _context.EquipmentCalibrations.Add(calibration);

        equipment.NextCalibrationDue = dto.ExpirationDate;
        equipment.Status = "Active";

        await _context.SaveChangesAsync();

        return new() { Id = calibration.Id };
    }

    public async Task UpdateEquipmentCalibration(long calibrationId, CreateEquipmentCalibrationDto dto)
    {
        var calibration = await _context.EquipmentCalibrations
            .Include(c => c.Equipment)
            .FirstOrDefaultAsync(c => c.Id == calibrationId);

        if (calibration == null) throw new ArgumentException("Equipment calibration not found");

        calibration.CalibrationDate = dto.CalibrationDate;
        calibration.ExpirationDate = dto.ExpirationDate;
        calibration.CertificateNumber = dto.CertificateNumber;
        calibration.CalibratedBy = dto.CalibratedBy;
        calibration.ResultStatus = dto.ResultStatus;
        calibration.ReferenceStandardsUsed = dto.ReferenceStandardsUsed;
        calibration.ExpandedUncertainty = dto.ExpandedUncertainty;

        if (calibration.Equipment != null)
        {
            calibration.Equipment.NextCalibrationDue = dto.ExpirationDate;
            calibration.Equipment.Status = "Active";
        }

        await _context.SaveChangesAsync();
    }
}
