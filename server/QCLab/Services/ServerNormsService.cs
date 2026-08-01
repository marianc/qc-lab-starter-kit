using Microsoft.EntityFrameworkCore;
using QCLab.Client.Dtos;
using QCLab.Client.Services.Interfaces;
using QCLab.Models;

namespace QCLab.Services;

public class ServerNormsService : INormsService
{
    private readonly QualityControlContext _context;

    public ServerNormsService(QualityControlContext context)
    {
        _context = context;
    }

    // GET /norms
    public async Task<List<NormDto>> GetAllNorms()
    {
        var norms = await _context.Norms
            .Select(n => new NormDto
            {
                Id = n.Id,
                Name = n.Name,
                Description = n.Description,
                IsObsolete = n.IsObsolete,
                DateCreated = n.DateCreated,
                DateObsolete = n.DateObsolete,
                CommentsObsolete = n.CommentsObsolete
            })
            .ToListAsync();

        return norms;
    }

    // GET /norms/{id}
    public async Task<NormDto?> GetNorm(long id)
    {
        var norm = await _context.Norms
            .Where(n => n.Id == id)
            .Select(n => new NormDto
            {
                Id = n.Id,
                Name = n.Name,
                Description = n.Description,
                IsObsolete = n.IsObsolete,
                DateCreated = n.DateCreated,
                DateObsolete = n.DateObsolete,
                CommentsObsolete = n.CommentsObsolete
            })
            .FirstOrDefaultAsync();

        return norm;
    }

    // POST /norms
    public async Task<IdDto> CreateNorm(CreateNormDto dto)
    {
        var norm = new Norm
        {
            Name = dto.Name,
            Description = dto.Description,
            DateCreated = DateTime.UtcNow
        };

        _context.Norms.Add(norm);
        await _context.SaveChangesAsync();

        return new() { Id = norm.Id };
    }

    // PUT /norms/{id}
    public async Task UpdateNorm(long id, UpdateNormDto dto)
    {
        var norm = await _context.Norms.FindAsync(id);
        if (norm == null) throw new ArgumentException("Norm not found");

        norm.Name = dto.Name;
        norm.Description = dto.Description;

        await _context.SaveChangesAsync();
    }

    // PUT /norms/{id}/toggle_obsolete
    public async Task ToggleObsolete(long id, ToggleObsoleteDto dto)
    {
        var norm = await _context.Norms.FindAsync(id);
        if (norm == null) throw new ArgumentException("Norm not found");

        norm.IsObsolete = dto.IsObsolete;
        norm.DateObsolete = dto.IsObsolete ? DateTime.UtcNow : null;
        norm.CommentsObsolete = dto.IsObsolete ? dto.Comments : null;
        await _context.SaveChangesAsync();
    }
}
