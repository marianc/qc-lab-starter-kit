using System;
using System.Collections.Generic;

namespace QCLab.Models;

public partial class ElectronicSignature
{
    public long Id { get; set; }

    public string EntityName { get; set; } = null!;

    public long EntityId { get; set; }

    public long SignerUserId { get; set; }

    public string SignatureMeaning { get; set; } = null!;

    public DateTime SigningTimestamp { get; set; }

    public string PayloadSha256 { get; set; } = null!;

    public string SignatureManifestText { get; set; } = null!;

    public string ClientIp { get; set; } = null!;

    public virtual User SignerUser { get; set; } = null!;
}
