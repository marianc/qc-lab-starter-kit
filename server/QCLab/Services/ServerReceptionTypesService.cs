using Microsoft.EntityFrameworkCore;
using QCLab.Client.Dtos;
using QCLab.Client.Services.Interfaces;
using QCLab.Models;

namespace QCLab.Services;

public class ServerReceptionTypesService : IReceptionTypesService
{
    private readonly QualityControlContext _context;

    public ServerReceptionTypesService(QualityControlContext context)
    {
        _context = context;
    }

    // GET /reception_types
    public async Task<List<ReceptionTypeDto>> GetAllReceptionTypes()
    {
        var receptionTypes = await _context.ReceptionTypes
            .Select(rt => new ReceptionTypeDto
            {
                Id = rt.Id,
                Name = rt.Name
            })
            .ToListAsync();

        return receptionTypes;
    }
}
