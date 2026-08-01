namespace QCLab.Client.Dtos;

public class FormGroupDto
{
    public long Id { get; set; }
    public required string Name { get; set; }
    public string? Description { get; set; }
    public long NrOrd { get; set; }
    public bool IsFormValidated { get; set; }
}

public class CreateFormGroupDto
{
    public required string Name { get; set; }
    public string? Description { get; set; }
    public long NrOrd { get; set; }
}

public class UpdateFormGroupDto
{
    public long? Id { get; set; } // Optional for bulk update
    public required string Name { get; set; }
    public string? Description { get; set; }
    public long NrOrd { get; set; }
}

public class FormSummaryDto
{
    public long Id { get; set; }
    public string? Version { get; set; }
    public bool IsSubmitted { get; set; }
    public bool IsValidated { get; set; }
    public bool IsCancelled { get; set; }
}
