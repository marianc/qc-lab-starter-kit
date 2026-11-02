using QCLab.Client.Dtos;

namespace QCLab.Client.Services.Interfaces;

public interface IWorksheetService
{
    Task<List<WorksheetTestItemDto>> CalculateWorksheet(List<WorksheetTestItemDto> items);
    Task<List<WorksheetItemResponseDto>> CalculateWorksheet(List<WorksheetItemRequestDto> items);
    Task<List<WorksheetValuesItemResponseDto>> CalculateValues(List<WorksheetValuesItemRequestDto> items);
    Task<List<WorksheetConformityItemResponseDto>> CalculateConformity(List<WorksheetConformityItemRequestDto> items);
    Task<List<WorksheetTestItemDto>> ImportFormEval(long formEvalId);
    Task<List<FormEvalImportOptionDto>> GetImportableFormEvals();
    void ValidateWorksheetFormula(string? formula, string currentCode, bool isArray, List<WorksheetTestItemDto> items);
}
