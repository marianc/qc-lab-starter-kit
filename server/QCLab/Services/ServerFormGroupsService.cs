using Microsoft.EntityFrameworkCore;
using QCLab.Client.Dtos;
using QCLab.Client.Services.Interfaces;
using QCLab.Models;

namespace QCLab.Services;

public class ServerFormGroupsService : IFormGroupsService
{
    private readonly QualityControlContext _context;

    public ServerFormGroupsService(QualityControlContext context)
    {
        _context = context;
    }

    // GET /form_groups
    public async Task<List<FormGroupDto>> GetAllFormGroups()
    {
        var formGroups = await _context.FormGroups
            .OrderBy(fg => fg.NrOrd)
            .Select(fg => new FormGroupDto
            {
                Id = fg.Id,
                Name = fg.Name,
                Description = fg.Description,
                NrOrd = fg.NrOrd,
                IsFormValidated = fg.IsFormValidated
            })
            .ToListAsync();

        return formGroups;
    }

    // GET /form_groups/{id}
    public async Task<FormGroupDto?> GetFormGroup(long id)
    {
        var formGroup = await _context.FormGroups
            .Where(fg => fg.Id == id)
            .Select(fg => new FormGroupDto
            {
                Id = fg.Id,
                Name = fg.Name,
                Description = fg.Description,
                NrOrd = fg.NrOrd,
                IsFormValidated = fg.IsFormValidated
            })
            .FirstOrDefaultAsync();

        return formGroup;
    }

    // POST /form_groups
    public async Task<IdDto> CreateFormGroup(CreateFormGroupDto dto)
    {
        var formGroup = new FormGroup
        {
            Name = dto.Name,
            Description = dto.Description,
            NrOrd = dto.NrOrd
        };

        _context.FormGroups.Add(formGroup);
        await _context.SaveChangesAsync();

        return new() { Id = formGroup.Id };
    }

    // PUT /form_groups/{id}
    public async Task UpdateFormGroup(long id, UpdateFormGroupDto dto)
    {
        var formGroup = await _context.FormGroups.FindAsync(id);
        if (formGroup == null) throw new ArgumentException("Form group not found");

        formGroup.Name = dto.Name;
        formGroup.Description = dto.Description;
        formGroup.NrOrd = dto.NrOrd;

        await _context.SaveChangesAsync();
    }

    // PUT /form_groups (Bulk Update / Reorder)
    public async Task BulkUpdateFormGroups(List<UpdateFormGroupDto> dtos)
    {
        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            foreach (var dto in dtos)
            {
                if (dto.Id.HasValue)
                {
                    var formGroup = await _context.FormGroups.FindAsync(dto.Id.Value);
                    if (formGroup != null)
                    {
                        formGroup.Name = dto.Name;
                        formGroup.Description = dto.Description;
                        formGroup.NrOrd = dto.NrOrd;
                    }
                }
            }
            await _context.SaveChangesAsync();
            await transaction.CommitAsync();
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();
            throw ex;
        }
    }

    // DELETE /form_groups/{id}
    public async Task DeleteFormGroup(long id)
    {
        var formGroup = await _context.FormGroups.FindAsync(id);
        if (formGroup == null) throw new ArgumentException("Form group not found");

        _context.FormGroups.Remove(formGroup);
        await _context.SaveChangesAsync();
    }

    // GET /form_groups/{id}/forms
    public async Task<List<FormSummaryDto>> GetFormsByGroup(long id)
    {
        var forms = await _context.Forms
            .Where(f => f.FormGroupId == id)
            .OrderByDescending(f => f.Id)
            .Select(f => new FormSummaryDto
            {
                Id = f.Id,
                Version = f.Version,
                IsSubmitted = f.IsSubmitted,
                IsValidated = f.IsValidated,
                IsCancelled = f.IsCancelled
            })
            .ToListAsync();

        return forms;
    }
}
