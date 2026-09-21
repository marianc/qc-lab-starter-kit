using Microsoft.EntityFrameworkCore;
using QCLab.Client.Dtos;
using QCLab.Client.Services.Interfaces;
using QCLab.Models;

namespace QCLab.Services;

public class UnitsService : IUnitsService
{
    private readonly QualityControlContext _context;

    public UnitsService(QualityControlContext context)
    {
        _context = context;
    }

    // GET /units
    public async Task<List<UnitDto>> GetAllUnits()
    {
        var units = await _context.Units
            .Select(u => new UnitDto
            {
                Id = u.Id,
                Name = u.Name,
                Description = u.Description
            })
            .ToListAsync();

        return units;
    }

    // GET /units/{id}
    public async Task<UnitDto?> GetUnit(long id)
    {
        var unit = await _context.Units.FindAsync(id);

        if (unit == null) return null;

        return new UnitDto 
        { 
            Id = unit.Id, 
            Name = unit.Name,
            Description = unit.Description
        };
    }

    // POST /units
    public async Task<IdDto> CreateUnit(CreateUnitDto dto)
    {
        var unit = new Unit
        {
            Name = dto.Name,
            Description = dto.Description,
            DateCreated = DateTime.UtcNow
        };

        _context.Units.Add(unit);
        await _context.SaveChangesAsync();

        return new() { Id = unit.Id };
    }

    // PUT /units/{id}
    public async Task UpdateUnit(long id, UpdateUnitDto dto)
    {
        var unit = await _context.Units.FindAsync(id);
        if (unit == null) throw new ArgumentException("Unit not found");

        unit.Name = dto.Name;
        unit.Description = dto.Description;

        await _context.SaveChangesAsync();
    }
}
