using Microsoft.EntityFrameworkCore;
using QCLab.Client.Dtos;
using QCLab.Client.Services.Interfaces;
using QCLab.Models;

namespace QCLab.Services;

public class ServerEquipmentsService : IEquipmentsService
{
    private readonly QualityControlContext _context;

    public ServerEquipmentsService(QualityControlContext context)
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

        // Update equipment NextCalibrationDue if calibration interval days is set
        equipment.NextCalibrationDue = dto.ExpirationDate;
        if (dto.ResultStatus == "Pass" && equipment.CalibrationIntervalDays.HasValue)
        {
            // Next calibration due can be set by expiration date or calculation, but ExpirationDate from dto is very explicit
        }

        await _context.SaveChangesAsync();

        return new() { Id = calibration.Id };
    }
}
