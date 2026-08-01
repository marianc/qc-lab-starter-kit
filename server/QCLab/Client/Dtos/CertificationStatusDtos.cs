namespace QCLab.Client.Dtos;

public class CertificationStatusDto
{
    public long MaterialId { get; set; }
    public string MaterialName { get; set; } = string.Empty;
    public long ControlCodeId { get; set; }
    public string ControlCode { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
}
