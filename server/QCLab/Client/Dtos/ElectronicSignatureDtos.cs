using System;
using System.Collections.Generic;

namespace QCLab.Client.Dtos;

public class ElectronicSignatureDto
{
    public long Id { get; set; }
    public string EntityName { get; set; } = string.Empty;
    public long EntityId { get; set; }
    public long SignerUserId { get; set; }
    public string SignerUserTag { get; set; } = string.Empty;
    public string SignatureMeaning { get; set; } = string.Empty;
    public DateTime SigningTimestamp { get; set; }
    public string PayloadSha256 { get; set; } = string.Empty;
    public string SignatureManifestText { get; set; } = string.Empty;
    public string ClientIp { get; set; } = string.Empty;
    public bool IsValid { get; set; }
}

public class ElectronicSignatureVerificationDto
{
    public bool IsSigned { get; set; }
    public bool IsValid { get; set; }
    public string StatusMessage { get; set; } = string.Empty;
    public List<ElectronicSignatureDto> Signatures { get; set; } = new();
}
