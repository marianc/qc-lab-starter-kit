using System.ComponentModel.DataAnnotations;
using System.Net.Http.Json;
using QCLab.Client.Dtos;

namespace QCLab.Client.Validation;

public class FormulaValidatorAttribute : ValidationAttribute
{
    protected override ValidationResult? IsValid(object? value, ValidationContext validationContext)
    {
        var dto = (FormParamDto)validationContext.ObjectInstance;
        
        // 2. The formula is required only if 'is_calculated' field is true
        string? formula = value as string;
        if (dto.IsCalculated && string.IsNullOrWhiteSpace(formula))
        {
            return new ValidationResult("Formula is required for calculated parameters.", new[] { validationContext.MemberName! });
        }

        if (!dto.IsCalculated)
        {
            return ValidationResult.Success;
        }

        // 3. The formula should pass all the formula related tests performed on parent form submission (on the server), 
        // but only for the current formula.
        
        // On the client (WASM), we cannot call async methods synchronously (.Wait() / .Result).
        // The component (FormParamDialog.razor) handles this validation asynchronously on blur and on save.
        var http = validationContext.GetService(typeof(System.Net.Http.HttpClient)) as System.Net.Http.HttpClient;
        if (http != null)
        {
            return ValidationResult.Success;
        }

        // On the server, we can get the service and perform the check.
        var formsService = validationContext.GetService(typeof(QCLab.Client.Services.Interfaces.IFormsService)) as QCLab.Client.Services.Interfaces.IFormsService;
        if (formsService != null)
        {
            try
            {
                // Using .Wait() because IsValid is synchronous. 
                formsService.ValidateFormula(dto.FormId, dto.TestId, dto.IsCalculated, formula).Wait();
                return ValidationResult.Success;
            }
            catch (AggregateException ex)
            {
                return new ValidationResult(ex.InnerException?.Message ?? ex.Message, new[] { validationContext.MemberName! });
            }
            catch (Exception ex)
            {
                return new ValidationResult(ex.Message, new[] { validationContext.MemberName! });
            }
        }

        return ValidationResult.Success;
    }
}
