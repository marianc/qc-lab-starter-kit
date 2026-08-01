using QCLab.Client.Dtos;

namespace QCLab.Client.Services.Interfaces;

public interface IFormEvalsService
{
    Task<List<FormEvalDto>> GetFormEvals(long formId);
    Task<FormEvalDto?> GetFormEval(long id);
    Task<IdDto> CreateFormEval(CreateFormEvalDto dto);
    Task UpdateFormEval(long id, UpdateFormEvalDto dto);
    Task DeleteFormEval(long id);
    Task<FormEvalDto> CalculateFormEval(long id);
}
