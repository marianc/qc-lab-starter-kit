using Microsoft.EntityFrameworkCore;
using QCLab.Client.Dtos;
using QCLab.Client.Services.Interfaces;
using QCLab.Models;

namespace QCLab.Services;

public class ServerMaterialsService : IMaterialsService
{
    private readonly QualityControlContext _context;

    public ServerMaterialsService(QualityControlContext context)
    {
        _context = context;
    }

    // GET /materials
    public async Task<List<MaterialDto>> GetAllMaterials()
    {
        var materials = await _context.Materials
            .Include(m => m.Norm)
            .OrderBy(m => m.Name)
            .Select(m => new MaterialDto
            {
                Id = m.Id,
                Name = m.Name,
                Code = m.Code,
                Description = m.Description,
                NormId = m.NormId,
                NormName = m.Norm != null ? m.Norm.Name : null,
                IsProduct = m.IsProduct,
                IsRawMaterial = m.IsRawMaterial,
                IsReagent = m.IsReagent,
                IsObsolete = m.IsObsolete,
                DateCreated = m.DateCreated,
                DateObsolete = m.DateObsolete,
                CommentsObsolete = m.CommentsObsolete
            })
            .ToListAsync();

        return materials;
    }

    // GET /materials/with_valid_spec
    public async Task<List<MaterialDto>> GetMaterialsWithValidSpec()
    {
        var materials = await _context.Materials
            .Where(m => m.Specs.Any(s => s.IsSubmitted && !s.IsCancelled))
            .OrderBy(m => m.Name)
            .Select(m => new MaterialDto
            {
                Id = m.Id,
                Name = m.Name,
                Code = m.Code,
                Description = m.Description,
                NormId = m.NormId,
                NormName = m.Norm != null ? m.Norm.Name : null,
                IsProduct = m.IsProduct,
                IsRawMaterial = m.IsRawMaterial,
                IsReagent = m.IsReagent,
                IsObsolete = m.IsObsolete,
                DateCreated = m.DateCreated,
                DateObsolete = m.DateObsolete,
                CommentsObsolete = m.CommentsObsolete
            })
            .ToListAsync();

        return materials;
    }

    // GET /materials/{id}
    public async Task<MaterialDto?> GetMaterial(long id)
    {
        var material = await _context.Materials
            .Include(m => m.Norm)
            .Where(m => m.Id == id)
            .Select(m => new MaterialDto
            {
                Id = m.Id,
                Name = m.Name,
                Code = m.Code,
                Description = m.Description,
                NormId = m.NormId,
                NormName = m.Norm != null ? m.Norm.Name : null,
                IsProduct = m.IsProduct,
                IsRawMaterial = m.IsRawMaterial,
                IsReagent = m.IsReagent,
                IsObsolete = m.IsObsolete,
                DateCreated = m.DateCreated,
                DateObsolete = m.DateObsolete,
                CommentsObsolete = m.CommentsObsolete
            })
            .FirstOrDefaultAsync();

        return material;
    }

    // POST /materials
    public async Task<IdDto> CreateMaterial(CreateMaterialDto dto)
    {
        var material = new Material
        {
            Name = dto.Name,
            Code = dto.Code,
            Description = dto.Description,
            NormId = dto.NormId,
            IsProduct = dto.IsProduct,
            IsRawMaterial = dto.IsRawMaterial,
            IsObsolete = dto.IsObsolete,
            DateCreated = DateTime.UtcNow
        };
        
        _context.Materials.Add(material);
        await _context.SaveChangesAsync();

        return new() { Id = material.Id };
    }

    // PUT /materials/{id}
    public async Task UpdateMaterial(long id, UpdateMaterialDto dto)
    {
        var material = await _context.Materials.FindAsync(id);
        if (material == null) throw new ArgumentException("Material not found");

        material.Name = dto.Name;
        material.Description = dto.Description;
        material.NormId = dto.NormId;
        material.IsProduct = dto.IsProduct;
        material.IsRawMaterial = dto.IsRawMaterial;
        material.IsObsolete = dto.IsObsolete;

        await _context.SaveChangesAsync();
    }

    // PUT /materials/{id}/toggle_obsolete
    public async Task ToggleObsolete(long id, ToggleObsoleteDto dto)
    {
        var material = await _context.Materials.FindAsync(id);
        if (material == null) throw new ArgumentException("Material not found");

        material.IsObsolete = dto.IsObsolete;
        material.DateObsolete = dto.IsObsolete ? DateTime.UtcNow : null;
        material.CommentsObsolete = dto.IsObsolete ? dto.Comments : null;
        await _context.SaveChangesAsync();
    }

    // GET /materials/{id}/tests
    public async Task<List<MaterialTestDto>> GetMaterialTests(long id)
    {
        var tests = await _context.Materials
            .Where(m => m.Id == id)
            .SelectMany(m => m.Tests)
            .Where(t => !t.IsParam)
            .Include(t => t.Type)
            .Select(t => new MaterialTestDto
            {
                Id = t.Id,
                Name = t.Name,
                Code = t.Code,
                TypeId = t.TypeId,
                IsArray = t.IsArray,
                TypeName = t.Type.Name
            })
            .ToListAsync();

        return tests;
    }

    // PUT /materials/{id}/tests
    public async Task UpdateMaterialTests(long id, UpdateMaterialTestsDto dto)
    {
        var material = await _context.Materials.Include(m => m.Tests).FirstOrDefaultAsync(m => m.Id == id);
        if (material == null) throw new ArgumentException("Material not found");

        material.Tests.Clear();

        if (dto.TestIds != null && dto.TestIds.Count > 0)
        {
            var tests = await _context.Tests.Where(t => dto.TestIds.Contains(t.Id)).ToListAsync();
            foreach(var t in tests) material.Tests.Add(t);
        }

        await _context.SaveChangesAsync();
    }

    // GET /materials/{id}/control_codes
    public async Task<List<MaterialControlCodeDto>> GetControlCodes(long id)
    {
        var codes = await _context.ControlCodes
            .Where(cc => cc.MaterialId == id)
            .OrderByDescending(cc => cc.Id)
            .Select(cc => new MaterialControlCodeDto
            {
                Id = cc.Id,
                Code = cc.Code
            })
            .ToListAsync();

        return codes;
    }

    // GET /materials/{id}/control_codes_for_certificate
    public async Task<List<MaterialControlCodeDto>> GetControlCodesForCertificate(long id)
    {
        var codes = await _context.ControlCodes
            .Where(cc => cc.MaterialId == id)
            .Where(cc => cc.Receptions.Any(r => 
                r.TypeId == 1 &&
                r.IsSubmitted &&
                r.IsReceived &&
                r.Reports.Any(rep => rep.IsSubmitted && !rep.IsCancelled)
            ))
            .OrderByDescending(cc => cc.Id)
            .Select(cc => new MaterialControlCodeDto
            {
                Id = cc.Id,
                Code = cc.Code
            })
            .ToListAsync();

        return codes;
    }
}
