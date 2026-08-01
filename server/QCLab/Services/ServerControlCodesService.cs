using Microsoft.EntityFrameworkCore;
using QCLab.Client.Dtos;
using QCLab.Client.Services.Interfaces;
using QCLab.Models;

namespace QCLab.Services;

public class ServerControlCodesService : IControlCodesService
{
    private readonly QualityControlContext _context;

    public ServerControlCodesService(QualityControlContext context)
    {
        _context = context;
    }

    // GET /control_codes
    public async Task<List<ControlCodeDto>> GetAllControlCodes()
    {
        var controlCodes = await _context.ControlCodes
            .Select(cc => new ControlCodeDto
            {
                Id = cc.Id,
                MaterialId = cc.MaterialId,
                Code = cc.Code,
                IsReceptionReceived = cc.IsReceptionReceived
            })
            .ToListAsync();

        return controlCodes;
    }

    // GET /control_codes/by_material/{material_id}
    public async Task<List<ControlCodeSelectionDto>> GetControlCodesByMaterial(long material_id)
    {
        var controlCodes = await _context.ControlCodes
            .Where(cc => cc.MaterialId == material_id)
            .OrderByDescending(cc => cc.Id)
            .Select(cc => new ControlCodeSelectionDto
            {
                Id = cc.Id,
                Code = cc.Code
            })
            .ToListAsync();
        
        return controlCodes;
    }

    // POST /control_codes
    public async Task<IdDto> CreateControlCode(CreateControlCodeDto dto)
    {
        var controlCode = new ControlCode
        {
            MaterialId = dto.MaterialId,
            Code = dto.Code,
            IsReceptionReceived = false // Default
        };

        _context.ControlCodes.Add(controlCode);
        await _context.SaveChangesAsync();

        return new() { Id = controlCode.Id };
    }
}
