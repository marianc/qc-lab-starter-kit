using QCLab.Client.Dtos;

namespace QCLab.Client.Services.Interfaces
{
    public interface IFormGroupsService
    {
        Task<List<FormGroupDto>> GetAllFormGroups();
        Task<FormGroupDto?> GetFormGroup(long id);
        Task<IdDto> CreateFormGroup(CreateFormGroupDto dto);
        Task UpdateFormGroup(long id, UpdateFormGroupDto dto);
        Task BulkUpdateFormGroups(List<UpdateFormGroupDto> dtos);
        Task DeleteFormGroup(long id);
        Task<List<FormSummaryDto>> GetFormsByGroup(long id);
    }
}