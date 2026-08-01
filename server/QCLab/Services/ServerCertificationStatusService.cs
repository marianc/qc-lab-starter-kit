using Microsoft.EntityFrameworkCore;
using QCLab.Client.Dtos;
using QCLab.Client.Services.Interfaces;
using QCLab.Models;

namespace QCLab.Services;

public class ServerCertificationStatusService : ICertificationStatusService
{
    private readonly QualityControlContext _context;

    public ServerCertificationStatusService(QualityControlContext context)
    {
        _context = context;
    }

    // GET /certification_status
    public async Task<List<CertificationStatusDto>> GetCertificationStatus()
    {
        // Logic:
        // Find control codes where:
        // 1. Has some receptions with TypeId = 1 (Certification) AND (IsSubmitted OR IsReceived) AND !IsRejected
        // 2. Has NO certificates associated with it.

        var results = await _context.ControlCodes
            .Include(cc => cc.Material)
            .Where(cc => cc.Receptions.Any(r => 
                r.TypeId == 1 && 
                (r.IsSubmitted || r.IsReceived) && 
                !r.IsRejected)
            )
            .Where(cc => !cc.Certificates.Any())
            .OrderByDescending(cc => cc.Id)
            .Select(cc => new CertificationStatusDto
            {
                MaterialId = cc.Material.Id,
                MaterialName = cc.Material.Name,
                ControlCodeId = cc.Id,
                ControlCode = cc.Code,
                Status = cc.Receptions.Any(r => r.TypeId == 1 && !r.IsRejected && r.Reports.Any(rep => rep.IsSubmitted && !rep.IsCancelled)) ? "Reported" :
                         cc.Receptions.Any(r => r.TypeId == 1 && !r.IsRejected && r.IsReceived) ? "Received" : "Submitted"
            })
            .ToListAsync();

        return results;
    }
}
