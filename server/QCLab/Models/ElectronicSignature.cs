using System;
using System.Collections.Generic;

namespace QCLab.Models;

/// <summary>
/// Cryptographic electronic signature ledger enforcing 21 CFR Part 11 and EU GMP Annex 11 compliance. Stores legally binding digital signatures executed when laboratory personnel submit, validate, approve, or cancel critical quality documents (forms, specifications, test reports, quality certificates). Includes SHA-256 payload digests and human-readable signature manifests.
/// </summary>
public partial class ElectronicSignature
{
    /// <summary>
    /// Primary key. Unique 64-bit integer identifier for the electronic signature record.
    /// </summary>
    public long Id { get; set; }

    /// <summary>
    /// Monotonically increasing sequence number (defaults to 1) indicating the revision of the signature on a given entity record (e.g., Version 1 for initial submission, Version 2 for revision/approval, Version 3 for cancellation).
    /// </summary>
    public long Version { get; set; }

    /// <summary>
    /// Name of the audited domain entity/table to which the signature applies (e.g., &apos;forms&apos;, &apos;specs&apos;, &apos;reports&apos;, &apos;certificates&apos;).
    /// </summary>
    public string EntityName { get; set; } = null!;

    /// <summary>
    /// Primary key identifier of the specific domain record being digitally signed (e.g., forms.id, specs.id, certificates.id).
    /// </summary>
    public long EntityId { get; set; }

    /// <summary>
    /// Foreign key referencing public.users(id). The authenticated user who entered their credentials and executed the signature.
    /// </summary>
    public long SignerUserId { get; set; }

    /// <summary>
    /// Legally defined statement of intent / meaning of the signature (e.g., &apos;Submission&apos;, &apos;Validation&apos;, &apos;Approval&apos;, &apos;Cancellation&apos;). Specifies the signer&apos;s regulatory responsibility pursuant to 21 CFR § 11.50.
    /// </summary>
    public string SignatureMeaning { get; set; } = null!;

    /// <summary>
    /// Cryptographic timestamp with time zone at the exact instant the signature was sealed. Defaults to clock_timestamp().
    /// </summary>
    public DateTime SigningTimestamp { get; set; }

    /// <summary>
    /// Hex-encoded 64-character SHA-256 cryptographic hash of the canonical JSON representation of the entity state at the moment of signing. Guarantees tamper-evidence and data integrity: any post-signature tampering invalidates the hash verification.
    /// </summary>
    public string PayloadSha256 { get; set; } = null!;

    /// <summary>
    /// Human-readable text manifest summarizing the signed record details, signer full name, user tag, signature meaning, and timestamp. Rendered in the client UI via SignatureManifestBlock.tsx for inspection during audits.
    /// </summary>
    public string SignatureManifestText { get; set; } = null!;

    /// <summary>
    /// Network IPv4/IPv6 client IP address from which the signature action was executed.
    /// </summary>
    public string ClientIp { get; set; } = null!;

    public virtual User SignerUser { get; set; } = null!;
}
