using Microsoft.EntityFrameworkCore;
using QCLab.Client.Dtos;
using QCLab.Client.Services.Interfaces;
using QCLab.Models;

namespace QCLab.Services;

public class ServerSopsService : ISopsService
{
    private readonly QualityControlContext _context;

    public ServerSopsService(QualityControlContext context)
    {
        _context = context;
    }

    public async Task<List<SopDto>> GetSopsByNorm(long normId)
    {
        var sops = await _context.Sops
            .Where(s => s.NormId == normId)
            .Include(s => s.SopVersions)
            .OrderBy(s => s.Id)
            .Select(s => new SopDto
            {
                Id = s.Id,
                DocCode = s.DocCode,
                Title = s.Title,
                NormId = s.NormId,
                DateCreated = s.DateCreated,
                Versions = s.SopVersions
                    .OrderByDescending(v => v.Id)
                    .Select(v => new SopVersionDto
                    {
                        Id = v.Id,
                        SopId = v.SopId,
                        VersionNumber = v.VersionNumber,
                        ExternalEdmsId = v.ExternalEdmsId,
                        IsActive = v.IsActive,
                        DateActivated = v.DateActivated,
                        Comments = v.Comments
                    })
                    .ToList()
            })
            .ToListAsync();

        return sops;
    }

    public async Task<List<SopDto>> GetAllSops()
    {
        var sops = await _context.Sops
            .Include(s => s.SopVersions)
            .OrderBy(s => s.Id)
            .Select(s => new SopDto
            {
                Id = s.Id,
                DocCode = s.DocCode,
                Title = s.Title,
                NormId = s.NormId,
                DateCreated = s.DateCreated,
                Versions = s.SopVersions
                    .OrderByDescending(v => v.Id)
                    .Select(v => new SopVersionDto
                    {
                        Id = v.Id,
                        SopId = v.SopId,
                        VersionNumber = v.VersionNumber,
                        ExternalEdmsId = v.ExternalEdmsId,
                        IsActive = v.IsActive,
                        DateActivated = v.DateActivated,
                        Comments = v.Comments
                    })
                    .ToList()
            })
            .ToListAsync();

        return sops;
    }

    public async Task<SopDto?> GetSop(long id)
    {
        var s = await _context.Sops
            .Where(x => x.Id == id)
            .Include(x => x.SopVersions)
            .FirstOrDefaultAsync();

        if (s == null) return null;

        return new SopDto
        {
            Id = s.Id,
            DocCode = s.DocCode,
            Title = s.Title,
            NormId = s.NormId,
            DateCreated = s.DateCreated,
            Versions = s.SopVersions
                .OrderByDescending(v => v.Id)
                .Select(v => new SopVersionDto
                {
                    Id = v.Id,
                    SopId = v.SopId,
                    VersionNumber = v.VersionNumber,
                    ExternalEdmsId = v.ExternalEdmsId,
                    IsActive = v.IsActive,
                    DateActivated = v.DateActivated,
                    Comments = v.Comments
                })
                .ToList()
        };
    }

    public async Task<IdDto> CreateSop(CreateSopWithVersionDto dto)
    {
        var sop = new Sop
        {
            DocCode = dto.DocCode,
            Title = dto.Title,
            NormId = dto.NormId,
            DateCreated = DateTime.UtcNow
        };

        _context.Sops.Add(sop);
        await _context.SaveChangesAsync();

        var version = new SopVersion
        {
            SopId = sop.Id,
            VersionNumber = dto.VersionNumber,
            ExternalEdmsId = dto.ExternalEdmsId,
            IsActive = false, // Must not be activated initially per requirements ("not be activated")
            DateActivated = DateTime.UtcNow,
            Comments = dto.Comments
        };

        _context.SopVersions.Add(version);
        await _context.SaveChangesAsync();

        return new IdDto { Id = sop.Id };
    }

    public async Task<IdDto> CreateSopVersion(long sopId, UpdateSopVersionDto dto)
    {
        var sop = await _context.Sops.FindAsync(sopId);
        if (sop == null) throw new ArgumentException("SOP not found");

        var version = new SopVersion
        {
            SopId = sopId,
            VersionNumber = dto.VersionNumber,
            ExternalEdmsId = dto.ExternalEdmsId,
            IsActive = false, // Must not be activated initially
            DateActivated = DateTime.UtcNow,
            Comments = dto.Comments
        };

        _context.SopVersions.Add(version);
        await _context.SaveChangesAsync();

        return new IdDto { Id = version.Id };
    }

    public async Task UpdateSopVersion(long versionId, UpdateSopVersionDto dto)
    {
        var version = await _context.SopVersions.FindAsync(versionId);
        if (version == null) throw new ArgumentException("SOP version not found");

        version.VersionNumber = dto.VersionNumber;
        version.ExternalEdmsId = dto.ExternalEdmsId;
        version.Comments = dto.Comments;

        await _context.SaveChangesAsync();
    }

    public async Task ActivateSopVersion(long versionId)
    {
        var version = await _context.SopVersions
            .Include(v => v.Sop)
            .ThenInclude(s => s.SopVersions)
            .FirstOrDefaultAsync(v => v.Id == versionId);

        if (version == null) throw new ArgumentException("SOP version not found");

        // Deactivate all other versions for this SOP
        foreach (var v in version.Sop.SopVersions)
        {
            v.IsActive = (v.Id == versionId);
        }

        version.IsActive = true;
        version.DateActivated = DateTime.UtcNow;

        await _context.SaveChangesAsync();
    }
}
