using QCLab.Client.Dtos;


namespace QCLab.Client.Services.Interfaces
{
    public interface IFormsService
    {
        Task<List<FormDto>> GetAllForms();
        Task<FormDetailDto?> GetForm(long id);
        Task<IdDto> CreateForm(CreateFormDto dto);
        Task UpdateForm(long id, UpdateFormDto dto);
        Task<List<FormParamDto>> GetFormParams(long id);
        Task ReorderFormParams(long id, List<ReorderFormParamDto> reorderedParams);
        Task BatchUpdateFormParams(long id, List<BatchUpdateFormParamDto> paramsData);
        Task<IdDto> AddFormParam(long id, CreateFormParamDto dto);
        Task UpdateFormParam(long id, long testId, UpdateFormParamDto dto);
        Task DeleteFormParam(long id, long testId);
        Task SubmitForm(long id, FormActionDto dto);
        Task ValidateForm(long id, FormActionDto dto);
        Task CancelForm(long id, FormActionDto dto);
        Task ReactivateForm(long id);
        Task<IdDto> DuplicateForm(long id, FormActionDto dto);
        Task ValidateFormula(long formId, long testId, bool isCalculated, string? formula);
        Task ValidateCondition(string condition);
        Task<Dictionary<string, object>> EvaluateFormCalculations(long formId, Dictionary<string, object> measurementData);
    }
}