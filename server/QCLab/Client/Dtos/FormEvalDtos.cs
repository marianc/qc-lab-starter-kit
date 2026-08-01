namespace QCLab.Client.Dtos;

public class FormEvalDto
{
    public long Id { get; set; }
    public long FormId { get; set; }
    public string? Description { get; set; }
    public Dictionary<string, object?> MeasurementData { get; set; } = new();
    public Dictionary<string, object?> CalculatedResults { get; set; } = new();
    public Dictionary<string, EvalResultDto> ExpectedResults { get; set; } = new();
}

public class EvalResultDto
{
    public object? Value { get; set; }
    public object? IsMatch { get; set; }
}

public class CreateFormEvalDto
{
    public long FormId { get; set; }
    public string? Description { get; set; }
}

public class UpdateFormEvalDto
{
    public string? Description { get; set; }
    public Dictionary<string, object?> MeasurementData { get; set; } = new();
    public Dictionary<string, object?> ExpectedResults { get; set; } = new();
}