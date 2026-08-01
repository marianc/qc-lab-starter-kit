namespace QCLab.Client.Dtos;

public class ControlCodeDto
{
    public long Id { get; set; }
    public long MaterialId { get; set; }
    public string Code { get; set; } = string.Empty;
    public bool IsReceptionReceived { get; set; }
}

public class ControlCodeSelectionDto
{
    public long Id { get; set; }
    public string Code { get; set; } = string.Empty;
}

public class CreateControlCodeDto
{
    public long MaterialId { get; set; }
    public required string Code { get; set; }
}
