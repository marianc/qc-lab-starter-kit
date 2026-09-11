using Microsoft.EntityFrameworkCore;
using QCLab.Client.Dtos;
using QCLab.Client.Services.Interfaces;
using QCLab.Models;

namespace QCLab.Services;

public class ServerReagentsService : IReagentsService
{
    private readonly QualityControlContext _context;

    public ServerReagentsService(QualityControlContext context)
    {
        _context = context;
    }

    // GET /reagents
    public async Task<List<ReagentDto>> GetAllReagents()
    {
        var reagents = await _context.Materials
            .Include(m => m.Norm)
            .Where(m => m.IsReagent)
            .OrderBy(m => m.Name)
            .Select(m => new ReagentDto
            {
                Id = m.Id,
                Name = m.Name,
                Code = m.Code,
                Description = m.Description,
                CasNumber = m.CasNumber,
                NormId = m.NormId,
                NormName = m.Norm != null ? m.Norm.Name : null,
                IsObsolete = m.IsObsolete,
                DateCreated = m.DateCreated,
                DateObsolete = m.DateObsolete,
                CommentsObsolete = m.CommentsObsolete
            })
            .ToListAsync();

        return reagents;
    }

    // GET /reagents/{id}
    public async Task<ReagentDto?> GetReagent(long id)
    {
        var reagent = await _context.Materials
            .Include(m => m.Norm)
            .Where(m => m.Id == id && m.IsReagent)
            .Select(m => new ReagentDto
            {
                Id = m.Id,
                Name = m.Name,
                Code = m.Code,
                Description = m.Description,
                CasNumber = m.CasNumber,
                NormId = m.NormId,
                NormName = m.Norm != null ? m.Norm.Name : null,
                IsObsolete = m.IsObsolete,
                DateCreated = m.DateCreated,
                DateObsolete = m.DateObsolete,
                CommentsObsolete = m.CommentsObsolete
            })
            .FirstOrDefaultAsync();

        return reagent;
    }

    // POST /reagents
    public async Task<IdDto> CreateReagent(CreateReagentDto dto)
    {
        var material = new Material
        {
            Name = dto.Name,
            Code = dto.Code,
            Description = dto.Description,
            CasNumber = dto.CasNumber,
            NormId = dto.NormId,
            IsProduct = false,
            IsRawMaterial = false,
            IsReagent = true,
            IsObsolete = dto.IsObsolete,
            DateCreated = DateTime.UtcNow
        };

        _context.Materials.Add(material);
        await _context.SaveChangesAsync();

        return new IdDto { Id = material.Id };
    }

    // PUT /reagents/{id}
    public async Task UpdateReagent(long id, UpdateReagentDto dto)
    {
        var material = await _context.Materials.FirstOrDefaultAsync(m => m.Id == id && m.IsReagent);
        if (material == null)
        {
            throw new ArgumentException($"Reagent with id {id} not found.");
        }

        material.Name = dto.Name;
        material.Code = dto.Code;
        material.Description = dto.Description;
        material.CasNumber = dto.CasNumber;
        material.NormId = dto.NormId;
        material.IsObsolete = dto.IsObsolete;

        await _context.SaveChangesAsync();
    }

    // PUT /reagents/{id}/toggle_obsolete
    public async Task ToggleObsolete(long id, ToggleObsoleteDto dto)
    {
        var material = await _context.Materials.FirstOrDefaultAsync(m => m.Id == id && m.IsReagent);
        if (material == null)
        {
            throw new ArgumentException($"Reagent with id {id} not found.");
        }

        material.IsObsolete = dto.IsObsolete;
        if (dto.IsObsolete)
        {
            material.DateObsolete = DateTime.UtcNow;
            material.CommentsObsolete = dto.Comments;
        }
        else
        {
            material.DateObsolete = null;
            material.CommentsObsolete = null;
        }

        await _context.SaveChangesAsync();
    }

    // GET /reagents/statuses
    public async Task<List<ReagentLotStatusDto>> GetReagentLotStatuses()
    {
        return await _context.ReagentLotStatuses
            .OrderBy(s => s.Id)
            .Select(s => new ReagentLotStatusDto
            {
                Id = s.Id,
                Name = s.Name
            })
            .ToListAsync();
    }

    // GET /reagent_suppliers
    public async Task<List<ReagentSupplierDto>> GetAllSuppliers()
    {
        return await _context.ReagentSuppliers
            .OrderBy(s => s.Name)
            .Select(s => new ReagentSupplierDto
            {
                Id = s.Id,
                Name = s.Name
            })
            .ToListAsync();
    }

    // GET /reagents/{reagentId}/lots
    public async Task<List<ReagentLotDto>> GetReagentLots(long reagentId)
    {
        var lots = await _context.ReagentLots
            .Include(rl => rl.ControlCode)
            .Include(rl => rl.Status)
            .Include(rl => rl.Unit)
            .Include(rl => rl.ProducedByUser)
            .Include(rl => rl.ReagentSupplierLot).ThenInclude(sl => sl.Supplier)
            .Include(rl => rl.IngredientControlCodes).ThenInclude(ing => ing.ControlCode)
            .Where(rl => rl.ControlCode.MaterialId == reagentId)
            .OrderByDescending(rl => rl.ControlCodeId)
            .ToListAsync();

        return lots.Select(MapToLotDto).ToList();
    }

    // GET /reagent_lots/active
    public async Task<List<ReagentLotDto>> GetAllActiveReagentLots()
    {
        var lots = await _context.ReagentLots
            .Include(rl => rl.ControlCode)
            .Include(rl => rl.Status)
            .Include(rl => rl.Unit)
            .Include(rl => rl.ProducedByUser)
            .Include(rl => rl.ReagentSupplierLot).ThenInclude(sl => sl.Supplier)
            .Include(rl => rl.IngredientControlCodes).ThenInclude(ing => ing.ControlCode)
            .Where(rl => rl.StatusId == 2) // Active
            .OrderByDescending(rl => rl.ControlCodeId)
            .ToListAsync();

        return lots.Select(MapToLotDto).ToList();
    }

    // GET /reagent_lots/{controlCodeId}
    public async Task<ReagentLotDto?> GetReagentLot(long controlCodeId)
    {
        var lot = await _context.ReagentLots
            .Include(rl => rl.ControlCode)
            .Include(rl => rl.Status)
            .Include(rl => rl.Unit)
            .Include(rl => rl.ProducedByUser)
            .Include(rl => rl.ReagentSupplierLot).ThenInclude(sl => sl.Supplier)
            .Include(rl => rl.IngredientControlCodes).ThenInclude(ing => ing.ControlCode)
            .FirstOrDefaultAsync(rl => rl.ControlCodeId == controlCodeId);

        return lot != null ? MapToLotDto(lot) : null;
    }

    // POST /reagents/supplier_lots
    public async Task<IdDto> CreateSupplierLot(CreateSupplierLotDto dto)
    {
        var cc = new ControlCode
        {
            MaterialId = dto.MaterialId,
            Code = dto.ControlCode,
            IsReceptionReceived = false,
            DateCreated = DateTime.UtcNow
        };
        _context.ControlCodes.Add(cc);
        await _context.SaveChangesAsync();

        var lot = new ReagentLot
        {
            ControlCodeId = cc.Id,
            IsProduced = false,
            StatusId = dto.StatusId,
            UnitId = dto.UnitId,
            Quantity = dto.Quantity,
            ExpirationDate = dto.ExpirationDate
        };
        _context.ReagentLots.Add(lot);

        var supplierLot = new ReagentSupplierLot
        {
            ControlCodeId = cc.Id,
            SupplierId = dto.SupplierId,
            CatalogNumber = dto.CatalogNumber,
            ManufacturerLotNumber = dto.ManufacturerLotNumber,
            CertificateOfAnalysisRef = dto.CertificateOfAnalysisRef,
            Comments = dto.Comments
        };
        _context.ReagentSupplierLots.Add(supplierLot);

        await _context.SaveChangesAsync();
        return new IdDto { Id = cc.Id };
    }

    // PUT /reagents/supplier_lots/{controlCodeId}
    public async Task UpdateSupplierLot(long controlCodeId, UpdateSupplierLotDto dto)
    {
        var lot = await _context.ReagentLots
            .Include(rl => rl.ReagentSupplierLot)
            .FirstOrDefaultAsync(rl => rl.ControlCodeId == controlCodeId);

        if (lot == null || lot.IsProduced)
        {
            throw new ArgumentException($"Supplier lot with controlCodeId {controlCodeId} not found.");
        }

        lot.StatusId = dto.StatusId;
        lot.UnitId = dto.UnitId;
        lot.Quantity = dto.Quantity;
        lot.ExpirationDate = dto.ExpirationDate;

        if (lot.ReagentSupplierLot != null)
        {
            lot.ReagentSupplierLot.SupplierId = dto.SupplierId;
            lot.ReagentSupplierLot.CatalogNumber = dto.CatalogNumber;
            lot.ReagentSupplierLot.ManufacturerLotNumber = dto.ManufacturerLotNumber;
            lot.ReagentSupplierLot.CertificateOfAnalysisRef = dto.CertificateOfAnalysisRef;
            lot.ReagentSupplierLot.Comments = dto.Comments;
        }

        await _context.SaveChangesAsync();
    }

    // POST /reagents/production_lots
    public async Task<IdDto> CreateProductionLot(CreateProductionLotDto dto)
    {
        var cc = new ControlCode
        {
            MaterialId = dto.MaterialId,
            Code = dto.ControlCode,
            IsReceptionReceived = false,
            DateCreated = DateTime.UtcNow
        };
        _context.ControlCodes.Add(cc);
        await _context.SaveChangesAsync();

        var lot = new ReagentLot
        {
            ControlCodeId = cc.Id,
            IsProduced = true,
            ProducedByUserId = dto.ProducedByUserId,
            StatusId = dto.StatusId,
            UnitId = dto.UnitId,
            Quantity = dto.Quantity,
            ExpirationDate = dto.ExpirationDate
        };

        if (dto.IngredientControlCodeIds.Count > 0)
        {
            var ingredients = await _context.ReagentLots
                .Where(r => dto.IngredientControlCodeIds.Contains(r.ControlCodeId))
                .ToListAsync();

            foreach (var ing in ingredients)
            {
                lot.IngredientControlCodes.Add(ing);
            }
        }

        _context.ReagentLots.Add(lot);
        await _context.SaveChangesAsync();

        return new IdDto { Id = cc.Id };
    }

    // PUT /reagents/production_lots/{controlCodeId}
    public async Task UpdateProductionLot(long controlCodeId, UpdateProductionLotDto dto)
    {
        var lot = await _context.ReagentLots
            .Include(rl => rl.IngredientControlCodes)
            .FirstOrDefaultAsync(rl => rl.ControlCodeId == controlCodeId);

        if (lot == null || !lot.IsProduced)
        {
            throw new ArgumentException($"Production lot with controlCodeId {controlCodeId} not found.");
        }

        lot.StatusId = dto.StatusId;
        lot.UnitId = dto.UnitId;
        lot.Quantity = dto.Quantity;
        lot.ExpirationDate = dto.ExpirationDate;
        lot.ProducedByUserId = dto.ProducedByUserId;

        lot.IngredientControlCodes.Clear();
        if (dto.IngredientControlCodeIds.Count > 0)
        {
            var ingredients = await _context.ReagentLots
                .Where(r => dto.IngredientControlCodeIds.Contains(r.ControlCodeId))
                .ToListAsync();

            foreach (var ing in ingredients)
            {
                lot.IngredientControlCodes.Add(ing);
            }
        }

        await _context.SaveChangesAsync();
    }

    private static ReagentLotDto MapToLotDto(ReagentLot rl)
    {
        return new ReagentLotDto
        {
            ControlCodeId = rl.ControlCodeId,
            MaterialId = rl.ControlCode.MaterialId,
            ControlCode = rl.ControlCode.Code,
            IsProduced = rl.IsProduced,
            ProducedByUserId = rl.ProducedByUserId,
            ProducedByUserTag = rl.ProducedByUser != null ? rl.ProducedByUser.Tag : null,
            StatusId = rl.StatusId,
            StatusName = rl.Status != null ? rl.Status.Name : string.Empty,
            UnitId = rl.UnitId,
            UnitName = rl.Unit != null ? rl.Unit.Name : null,
            Quantity = rl.Quantity,
            ExpirationDate = rl.ExpirationDate,
            DateCreated = rl.ControlCode.DateCreated,

            SupplierId = rl.ReagentSupplierLot?.SupplierId,
            SupplierName = rl.ReagentSupplierLot?.Supplier != null ? rl.ReagentSupplierLot.Supplier.Name : null,
            CatalogNumber = rl.ReagentSupplierLot?.CatalogNumber,
            ManufacturerLotNumber = rl.ReagentSupplierLot?.ManufacturerLotNumber ?? string.Empty,
            CertificateOfAnalysisRef = rl.ReagentSupplierLot?.CertificateOfAnalysisRef,
            Comments = rl.ReagentSupplierLot?.Comments,

            IngredientControlCodeIds = rl.IngredientControlCodes.Select(i => i.ControlCodeId).ToList(),
            IngredientControlCodes = rl.IngredientControlCodes.Select(i => i.ControlCode.Code).ToList()
        };
    }
}


