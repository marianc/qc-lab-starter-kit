using Microsoft.EntityFrameworkCore;
using QCLab.Client.Dtos;
using QCLab.Client.Services.Interfaces;
using QCLab.Models;

namespace QCLab.Services;

public class ServerTestsService : ITestsService
{
    private readonly QualityControlContext _context;

    public ServerTestsService(QualityControlContext context)
    {
        _context = context;
    }

    // GET /tests
    public async Task<List<TestDto>> GetAllTests()
    {
        var tests = await _context.Tests
            .Include(t => t.Type)
            .Include(t => t.Unit)
            .Include(t => t.TestEnums.OrderBy(e => e.NrOrd))
            .ToListAsync();

        var testsList = tests.Select(test => new TestDto
        {
            Id = test.Id,
            Name = test.Name,
            Code = test.Code,
            Description = test.Description,
            TypeId = test.TypeId,
            TypeName = test.Type.Name,
            IsArray = test.IsArray,
            IsParam = test.IsParam,
            ForCertification = test.ForCertification,
            ForEnvironmentalControl = test.ForEnvironmentalControl,
            RelativeUncertaintyPct = test.RelativeUncertaintyPct,
            DefaultCoverageFactorK = test.DefaultCoverageFactorK,
            UnitId = test.UnitId,
            UnitName = test.Unit?.Name,
            NormId = test.NormId,
            NormRef = test.NormRef,
            SopId = test.SopId,
            IsFormValidated = test.IsFormValidated,
            NrOrd = test.NrOrd,
            IsObsolete = test.IsObsolete,
            DateCreated = test.DateCreated,
            DateObsolete = test.DateObsolete,
            CommentsObsolete = test.CommentsObsolete,
            Enums = test.TypeId == 4 ? test.TestEnums.Select(e => new TestEnumDto
            {
                TestId = e.TestId,
                Value = e.Value,
                Name = e.Name,
                NrOrd = e.NrOrd
            }).ToList() : null
        }).ToList();

        return testsList;
    }

    public async Task<List<long>> GetCertifiedTestIds()
    {
        return await _context.Tests
            .Where(t => t.ForCertification && !t.IsObsolete)
            .Select(t => t.Id)
            .ToListAsync();
    }

    // GET /tests/check_code_uniqueness
    public async Task<bool> CheckCodeUniqueness(string code, long? id)
    {
        var query = _context.Tests.AsQueryable();
        query = query.Where(t => t.Code == code);
        
        if (id.HasValue)
        {
            query = query.Where(t => t.Id != id.Value);
        }

        var count = await query.CountAsync();
        return count == 0;
    }

    // GET /tests/{id}
    public async Task<TestDto?> GetTest(long id)
    {
        var test = await _context.Tests
            .Include(t => t.Type)
            .Include(t => t.Unit)
            .Include(t => t.TestEnums.OrderBy(e => e.NrOrd))
            .FirstOrDefaultAsync(t => t.Id == id);

        if (test == null) return null;

        return new TestDto
        {
            Id = test.Id,
            Name = test.Name,
            Code = test.Code,
            Description = test.Description,
            TypeId = test.TypeId,
            TypeName = test.Type.Name,
            IsArray = test.IsArray,
            IsParam = test.IsParam,
            ForEnvironmentalControl = test.ForEnvironmentalControl,
            ForCertification = test.ForCertification,
            RelativeUncertaintyPct = test.RelativeUncertaintyPct,
            DefaultCoverageFactorK = test.DefaultCoverageFactorK,
            UnitId = test.UnitId,
            UnitName = test.Unit?.Name,
            NormId = test.NormId,
            NormRef = test.NormRef,
            SopId = test.SopId,
            IsFormValidated = test.IsFormValidated,
            NrOrd = test.NrOrd,
            IsObsolete = test.IsObsolete,
            DateCreated = test.DateCreated,
            DateObsolete = test.DateObsolete,
            CommentsObsolete = test.CommentsObsolete,
            Enums = test.TypeId == 4 ? test.TestEnums.Select(e => new TestEnumDto
            {
                TestId = e.TestId,
                Value = e.Value,
                Name = e.Name,
                NrOrd = e.NrOrd
            }).ToList() : null
        };
    }

    // GET /tests/{id}/enums
    public async Task<List<TestEnumDto>> GetTestEnums(long id)
    {
        var enums = await _context.TestEnums
            .Where(e => e.TestId == id)
            .OrderBy(e => e.NrOrd)
            .Select(e => new TestEnumDto 
            {
                TestId = e.TestId,
                Value = e.Value,
                Name = e.Name,
                NrOrd = e.NrOrd
            })
            .ToListAsync();

        return enums;
    }

    // POST /tests/{id}/enums
    public async Task<IdDto> AddTestEnum(long id, CreateTestEnumDto newEnum)
    {
        var enumEntity = new TestEnum
        {
            TestId = id,
            Value = newEnum.Value,
            Name = newEnum.Name,
            NrOrd = newEnum.NrOrd
        };

        _context.TestEnums.Add(enumEntity);
        await _context.SaveChangesAsync();

        return new() { Id = enumEntity.TestId }; // Returning IdDto, assuming TestId is the relevant ID.
    }

    // PUT /tests/{id}/enums/reorder
    public async Task ReorderTestEnums(long id, List<ReorderTestEnumDto> enumsData)
    {
        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            foreach (var item in enumsData)
            {
                var enumItem = await _context.TestEnums.FirstOrDefaultAsync(e => e.TestId == id && e.Value == item.Value);
                if (enumItem != null)
                {
                    enumItem.NrOrd = item.NrOrd;
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

    // PUT /tests/{id}/enums/{enum_id}
    public async Task UpdateTestEnum(long id, long enumId, UpdateTestEnumDto enumData)
    {
        var enumItem = await _context.TestEnums.FirstOrDefaultAsync(e => e.TestId == id && e.Value == enumId);
        if (enumItem == null) throw new ArgumentException("Enum not found");

        if (enumItem.Value != enumData.Value)
        {
            var newEnum = new TestEnum
            {
                TestId = id,
                Value = enumData.Value,
                Name = enumData.Name,
                NrOrd = enumData.NrOrd,
                IsObsolete = enumItem.IsObsolete
            };
            _context.TestEnums.Add(newEnum);
            _context.TestEnums.Remove(enumItem);
        }
        else
        {
            enumItem.Name = enumData.Name;
            enumItem.NrOrd = enumData.NrOrd;
        }

        await _context.SaveChangesAsync();
    }

    // DELETE /tests/{id}/enums/{enum_id}
    public async Task DeleteTestEnum(long id, long enumId)
    {
        var enumItem = await _context.TestEnums.FirstOrDefaultAsync(e => e.TestId == id && e.Value == enumId);
        if (enumItem != null)
        {
            _context.TestEnums.Remove(enumItem);
            await _context.SaveChangesAsync();
        }
    }

    // POST /tests
    public async Task<IdDto> CreateTest(CreateTestDto newTest)
    {
        var test = new Test
        {
            Name = newTest.Name,
            Code = newTest.Code,
            Description = newTest.Description,
            TypeId = newTest.TypeId,
            IsArray = newTest.IsArray,
            IsParam = newTest.IsParam,
            ForCertification = newTest.ForCertification,
            ForEnvironmentalControl = newTest.IsParam ? false : newTest.ForEnvironmentalControl,
            RelativeUncertaintyPct = newTest.ForCertification ? newTest.RelativeUncertaintyPct : null,
            DefaultCoverageFactorK = newTest.ForCertification ? newTest.DefaultCoverageFactorK : null,
            UnitId = newTest.UnitId,
            NormId = newTest.NormId,
            NormRef = newTest.NormRef,
            SopId = newTest.SopId,
            NrOrd = newTest.NrOrd,
            IsObsolete = newTest.IsObsolete,
            DateCreated = DateTime.UtcNow
        };

        if (newTest.TypeId == 4 && newTest.Enums != null && newTest.Enums.Count > 0)
        {
            foreach (var e in newTest.Enums)
            {
                test.TestEnums.Add(new TestEnum
                {
                    Value = e.Value,
                    Name = e.Name,
                    NrOrd = e.NrOrd
                });
            }
        }

        _context.Tests.Add(test);
        await _context.SaveChangesAsync();

        return new() { Id = test.Id };
    }

    // PUT /tests/reorder
    public async Task ReorderTests(List<ReorderTestDto> testsData)
    {
        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            foreach (var item in testsData)
            {
                var test = await _context.Tests.FindAsync(item.Id);
                if (test != null)
                {
                    test.NrOrd = item.NrOrd;
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

    // PUT /tests/{id}
    public async Task UpdateTest(long id, UpdateTestDto testData)
    {
        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            var test = await _context.Tests.Include(t => t.TestEnums).FirstOrDefaultAsync(t => t.Id == id);
            if (test == null) throw new ArgumentException("Test not found");

            test.Name = testData.Name;
            test.Code = testData.Code;
            test.Description = testData.Description;
            test.TypeId = testData.TypeId;
            test.IsArray = testData.IsArray;
            test.IsParam = testData.IsParam;
            test.ForCertification = testData.ForCertification;
            test.ForEnvironmentalControl = testData.IsParam ? false : testData.ForEnvironmentalControl;
            test.RelativeUncertaintyPct = testData.ForCertification ? testData.RelativeUncertaintyPct : null;
            test.DefaultCoverageFactorK = testData.ForCertification ? testData.DefaultCoverageFactorK : null;
            test.UnitId = testData.UnitId;
            test.NormId = testData.NormId;
            test.NormRef = testData.NormRef;
            test.SopId = testData.SopId;
            test.NrOrd = testData.NrOrd;
            test.IsObsolete = testData.IsObsolete;

            if (test.TypeId != 4)
            {
                _context.TestEnums.RemoveRange(test.TestEnums);
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
    public async Task ToggleObsolete(long id, ToggleObsoleteDto dto)
    {
        var test = await _context.Tests.FindAsync(id);
        if (test == null) throw new ArgumentException("Test not found");

        test.IsObsolete = dto.IsObsolete;
        test.DateObsolete = dto.IsObsolete ? DateTime.UtcNow : null;
        test.CommentsObsolete = dto.IsObsolete ? dto.Comments : null;
        await _context.SaveChangesAsync();
    }

    public async Task<List<TestEquipmentDto>> GetTestEquipments(long id)
    {
        var equipments = await _context.Tests
            .Where(t => t.Id == id)
            .SelectMany(t => t.Equipment)
            .Select(e => new TestEquipmentDto
            {
                Id = e.Id,
                EquipmentCode = e.EquipmentCode,
                Name = e.Name,
                SerialNumber = e.SerialNumber,
                Status = e.Status
            })
            .ToListAsync();

        return equipments;
    }

    public async Task UpdateTestEquipments(long id, UpdateTestEquipmentsDto dto)
    {
        var test = await _context.Tests.Include(t => t.Equipment).FirstOrDefaultAsync(t => t.Id == id);
        if (test == null) throw new ArgumentException("Test not found");

        test.Equipment.Clear();

        if (dto.EquipmentIds != null && dto.EquipmentIds.Count > 0)
        {
            var equipments = await _context.Equipments.Where(e => dto.EquipmentIds.Contains(e.Id)).ToListAsync();
            foreach (var eq in equipments) test.Equipment.Add(eq);
        }

        await _context.SaveChangesAsync();
    }

    public async Task<List<TestReagentDto>> GetTestReagents(long id)
    {
        var reagents = await _context.Tests
            .Where(t => t.Id == id)
            .SelectMany(t => t.MaterialsNavigation)
            .Select(m => new TestReagentDto
            {
                Id = m.Id,
                Code = m.Code,
                Name = m.Name,
                CasNumber = m.CasNumber
            })
            .ToListAsync();

        return reagents;
    }

    public async Task UpdateTestReagents(long id, UpdateTestReagentsDto dto)
    {
        var test = await _context.Tests.Include(t => t.MaterialsNavigation).FirstOrDefaultAsync(t => t.Id == id);
        if (test == null) throw new ArgumentException("Test not found");

        test.MaterialsNavigation.Clear();

        if (dto.MaterialIds != null && dto.MaterialIds.Count > 0)
        {
            var materials = await _context.Materials.Where(m => dto.MaterialIds.Contains(m.Id)).ToListAsync();
            foreach (var mat in materials) test.MaterialsNavigation.Add(mat);
        }

        await _context.SaveChangesAsync();
    }
}