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
            .Include(e => e.Status)
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
                StatusId = e.StatusId,
                Status = e.Status != null ? e.Status.Name : string.Empty,
                CalibrationIntervalDays = e.CalibrationIntervalDays,
                NextCalibrationDue = e.NextCalibrationDue,
                DateCreated = e.DateCreated
            })
            .ToListAsync();
    }

    public async Task<EquipmentDto?> GetEquipment(long id)
    {
        return await _context.Equipments
            .Include(e => e.Status)
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
                StatusId = e.StatusId,
                Status = e.Status != null ? e.Status.Name : string.Empty,
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
            StatusId = dto.StatusId,
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
        equipment.StatusId = dto.StatusId;
        equipment.CalibrationIntervalDays = dto.CalibrationIntervalDays;

        await _context.SaveChangesAsync();
    }

    public async Task<List<EquipmentCalibrationDto>> GetEquipmentCalibrations(long equipmentId)
    {
        return await _context.EquipmentCalibrations
            .Include(c => c.Status)
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
                StatusId = c.StatusId,
                ResultStatus = c.Status != null ? c.Status.Name : string.Empty,
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
            StatusId = dto.StatusId,
            ReferenceStandardsUsed = dto.ReferenceStandardsUsed,
            ExpandedUncertainty = dto.ExpandedUncertainty,
            DateCreated = DateTime.UtcNow
        };

        _context.EquipmentCalibrations.Add(calibration);

        equipment.NextCalibrationDue = dto.ExpirationDate;
        // Assuming status id 1 is 'Active' or similar, or leave status as is / set active if appropriate.
        // Let's check if there's an 'Active' status in equipment_statuses.
        var activeStatus = await _context.EquipmentStatuses.FirstOrDefaultAsync(s => s.Name == "Active");
        if (activeStatus != null)
        {
            equipment.StatusId = activeStatus.Id;
        }

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
        calibration.StatusId = dto.StatusId;
        calibration.ReferenceStandardsUsed = dto.ReferenceStandardsUsed;
        calibration.ExpandedUncertainty = dto.ExpandedUncertainty;

        if (calibration.Equipment != null)
        {
            calibration.Equipment.NextCalibrationDue = dto.ExpirationDate;
            var activeStatus = await _context.EquipmentStatuses.FirstOrDefaultAsync(s => s.Name == "Active");
            if (activeStatus != null)
            {
                calibration.Equipment.StatusId = activeStatus.Id;
            }
        }

        await _context.SaveChangesAsync();
    }

    public async Task<List<EquipmentStatusDto>> GetEquipmentStatuses()
    {
        return await _context.EquipmentStatuses
            .OrderBy(s => s.Id)
            .Select(s => new EquipmentStatusDto
            {
                Id = s.Id,
                Name = s.Name
            })
            .ToListAsync();
    }

    public async Task<List<EquipmentCalibrationStatusDto>> GetEquipmentCalibrationStatuses()
    {
        return await _context.EquipmentCalibrationStatuses
            .OrderBy(s => s.Id)
            .Select(s => new EquipmentCalibrationStatusDto
            {
                Id = s.Id,
                Name = s.Name
            })
            .ToListAsync();
    }
}
