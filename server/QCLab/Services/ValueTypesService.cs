using Microsoft.EntityFrameworkCore;
using QCLab.Client.Dtos;
using QCLab.Client.Services.Interfaces;
using QCLab.Models;

namespace QCLab.Services;

public class ValueTypesService : IValueTypesService
{
    private readonly QualityControlContext _context;

    public ValueTypesService(QualityControlContext context)
    {
        _context = context;
    }

    // GET /value_types
    public async Task<List<ValueTypeDto>> GetAllValueTypes()
    {
        var valueTypes = await _context.ValueTypes
            .Select(vt => new ValueTypeDto
            {
                Id = vt.Id,
                Name = vt.Name
            })
            .ToListAsync();

        return valueTypes;
    }
}
