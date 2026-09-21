using System;
using System.Collections.Generic;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using QCLab.Client.Dtos;
using QCLab.Models;

namespace QCLab.Services;

public class ElectronicSignatureService
{
    private readonly QualityControlContext _context;

    public ElectronicSignatureService(QualityControlContext context)
    {
        _context = context;
    }

    public async Task<ElectronicSignatureDto> SignEntityAsync(
        string entityName,
        long entityId,
        long signerUserId,
        string signatureMeaning,
        string clientIp,
        string? customReason = null,
        QualityControlContext? externalContext = null)
    {
        var db = externalContext ?? _context;

        var user = await db.Users.FindAsync(signerUserId)
            ?? throw new ArgumentException($"User with ID {signerUserId} not found.");

        var payloadData = await BuildEntityPayloadDataAsync(entityName, entityId, signatureMeaning, db);
        var jsonOptions = new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
            WriteIndented = false
        };
        var payloadJson = JsonSerializer.Serialize(payloadData, jsonOptions);
        var payloadSha256 = ComputeSha256Hash(payloadJson);

        var timestamp = DateTime.UtcNow;
        var manifestText = $"Digitally Signed by: {user.Tag}\n" +
                           $"Date/Time: {timestamp:yyyy-MM-dd HH:mm:ss} UTC\n" +
                           $"Reason: {signatureMeaning}\n" +
                           $"Entity: {entityName} #{entityId}\n" +
                           $"Status: Verified (SHA-256 Digest Match)";

        var signature = new ElectronicSignature
        {
            EntityName = entityName,
            EntityId = entityId,
            SignerUserId = signerUserId,
            SignatureMeaning = signatureMeaning,
            SigningTimestamp = timestamp,
            PayloadSha256 = payloadSha256,
            SignatureManifestText = manifestText,
            ClientIp = string.IsNullOrWhiteSpace(clientIp) ? "127.0.0.1" : clientIp
        };

        db.ElectronicSignatures.Add(signature);
        await db.SaveChangesAsync();

        return new ElectronicSignatureDto
        {
            Id = signature.Id,
            EntityName = signature.EntityName,
            EntityId = signature.EntityId,
            SignerUserId = signature.SignerUserId,
            SignerUserTag = user.Tag,
            SignatureMeaning = signature.SignatureMeaning,
            SigningTimestamp = signature.SigningTimestamp,
            PayloadSha256 = signature.PayloadSha256,
            SignatureManifestText = signature.SignatureManifestText,
            ClientIp = signature.ClientIp,
            IsValid = true
        };
    }

    public async Task<ElectronicSignatureVerificationDto> VerifyEntitySignatureAsync(string entityName, long entityId, QualityControlContext? externalContext = null)
    {
        var db = externalContext ?? _context;

        var signatures = await db.ElectronicSignatures
            .Include(s => s.SignerUser)
            .Where(s => s.EntityName == entityName && s.EntityId == entityId)
            .OrderByDescending(s => s.SigningTimestamp)
            .ToListAsync();

        if (signatures.Count == 0)
        {
            return new ElectronicSignatureVerificationDto
            {
                IsSigned = false,
                IsValid = false,
                StatusMessage = "Not Signed",
                Signatures = new List<ElectronicSignatureDto>()
            };
        }

        var jsonOptions = new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
            WriteIndented = false
        };

        var signatureDtos = new List<ElectronicSignatureDto>();
        bool overallValid = true;

        foreach (var s in signatures)
        {
            var sigPayloadData = await BuildEntityPayloadDataAsync(entityName, entityId, s.SignatureMeaning, db);
            var sigPayloadJson = JsonSerializer.Serialize(sigPayloadData, jsonOptions);
            var sigHash = ComputeSha256Hash(sigPayloadJson);

            bool isValid = string.Equals(s.PayloadSha256, sigHash, StringComparison.OrdinalIgnoreCase);
            if (!isValid) overallValid = false;

            signatureDtos.Add(new ElectronicSignatureDto
            {
                Id = s.Id,
                EntityName = s.EntityName,
                EntityId = s.EntityId,
                SignerUserId = s.SignerUserId,
                SignerUserTag = s.SignerUser?.Tag ?? $"User #{s.SignerUserId}",
                SignatureMeaning = s.SignatureMeaning,
                SigningTimestamp = s.SigningTimestamp,
                PayloadSha256 = s.PayloadSha256,
                SignatureManifestText = s.SignatureManifestText,
                ClientIp = s.ClientIp,
                IsValid = isValid
            });
        }

        return new ElectronicSignatureVerificationDto
        {
            IsSigned = true,
            IsValid = overallValid,
            StatusMessage = overallValid ? "Verified (SHA-256 Digest Match)" : "Warning: Data Modified Post-Signature",
            Signatures = signatureDtos
        };
    }

    private async Task<object> BuildEntityPayloadDataAsync(string entityName, long entityId, string signatureMeaning, QualityControlContext db)
    {
        switch (entityName.ToLower())
        {
            case "reports":
                var report = await db.Reports
                    .AsNoTracking()
                    .Include(r => r.ReportTests)
                    .FirstOrDefaultAsync(r => r.Id == entityId);

                if (report == null) throw new ArgumentException($"Report {entityId} not found.");

                var reportTests = report.ReportTests?
                    .Select(rt => new { rt.TestId, rt.MeasurementId, rt.Idx, rt.Value })
                    .OrderBy(rt => rt.TestId).ThenBy(rt => rt.Idx)
                    .ToList() ?? new();

                bool isCancellation = string.Equals(signatureMeaning, "Cancellation", StringComparison.OrdinalIgnoreCase);

                if (isCancellation)
                {
                    return new
                    {
                        report.Id,
                        report.ReceptionId,
                        report.IsSubmitted,
                        report.UserSubmittedId,
                        DateSubmitted = report.DateSubmitted.HasValue ? report.DateSubmitted.Value.ToString("s") : null,
                        report.CommentsSubmitted,
                        report.IsCancelled,
                        report.UserCancelledId,
                        DateCancelled = report.DateCancelled.HasValue ? report.DateCancelled.Value.ToString("s") : null,
                        report.CommentsCancelled,
                        Tests = reportTests
                    };
                }
                else
                {
                    return new
                    {
                        report.Id,
                        report.ReceptionId,
                        report.IsSubmitted,
                        report.UserSubmittedId,
                        DateSubmitted = report.DateSubmitted.HasValue ? report.DateSubmitted.Value.ToString("s") : null,
                        report.CommentsSubmitted,
                        Tests = reportTests
                    };
                }

            case "certificates":
                var cert = await db.Certificates
                    .AsNoTracking()
                    .Include(c => c.CertificateTests)
                    .FirstOrDefaultAsync(c => c.Id == entityId);
                if (cert == null) throw new ArgumentException($"Certificate {entityId} not found.");

                var certTests = cert.CertificateTests?
                    .Select(ct => new { ct.TestId, ct.ReportId, ct.MeasurementId, ct.Idx, ct.Value })
                    .OrderBy(ct => ct.TestId).ThenBy(ct => ct.Idx)
                    .ToList() ?? new();

                bool isCertCancellation = string.Equals(signatureMeaning, "Cancellation", StringComparison.OrdinalIgnoreCase);

                if (isCertCancellation)
                {
                    return new
                    {
                        cert.Id,
                        cert.ControlCodeId,
                        cert.SpecId,
                        cert.IsConformingSpec,
                        cert.IsSubmitted,
                        cert.UserSubmittedId,
                        DateSubmitted = cert.DateSubmitted.HasValue ? cert.DateSubmitted.Value.ToString("s") : null,
                        cert.CommentsSubmitted,
                        cert.IsCancelled,
                        cert.UserCancelledId,
                        DateCancelled = cert.DateCancelled.HasValue ? cert.DateCancelled.Value.ToString("s") : null,
                        cert.CommentsCancelled,
                        Tests = certTests
                    };
                }
                else
                {
                    return new
                    {
                        cert.Id,
                        cert.ControlCodeId,
                        cert.SpecId,
                        cert.IsConformingSpec,
                        cert.IsSubmitted,
                        cert.UserSubmittedId,
                        DateSubmitted = cert.DateSubmitted.HasValue ? cert.DateSubmitted.Value.ToString("s") : null,
                        cert.CommentsSubmitted,
                        Tests = certTests
                    };
                }

            case "specs":
                var spec = await db.Specs
                    .AsNoTracking()
                    .Include(s => s.SpecTests)
                    .FirstOrDefaultAsync(s => s.Id == entityId);
                if (spec == null) throw new ArgumentException($"Specification {entityId} not found.");

                var specTests = spec.SpecTests?
                    .Select(st => new { st.TestId, st.Condition, st.Note, st.UseUncertainty, st.TestFrequency })
                    .OrderBy(st => st.TestId)
                    .ToList() ?? new();

                bool isSpecCancellation = string.Equals(signatureMeaning, "Cancellation", StringComparison.OrdinalIgnoreCase);

                if (isSpecCancellation)
                {
                    return new
                    {
                        spec.Id,
                        spec.MaterialId,
                        spec.IsSubmitted,
                        spec.UserSubmittedId,
                        DateSubmitted = spec.DateSubmitted.HasValue ? spec.DateSubmitted.Value.ToString("s") : null,
                        spec.CommentsSubmitted,
                        spec.IsCancelled,
                        spec.UserCancelledId,
                        DateCancelled = spec.DateCancelled.HasValue ? spec.DateCancelled.Value.ToString("s") : null,
                        spec.CommentsCancelled,
                        Tests = specTests
                    };
                }
                else
                {
                    return new
                    {
                        spec.Id,
                        spec.MaterialId,
                        spec.IsSubmitted,
                        spec.UserSubmittedId,
                        DateSubmitted = spec.DateSubmitted.HasValue ? spec.DateSubmitted.Value.ToString("s") : null,
                        spec.CommentsSubmitted,
                        Tests = specTests
                    };
                }

            case "forms":
                var form = await db.Forms
                    .AsNoTracking()
                    .Include(f => f.FormParams)
                    .FirstOrDefaultAsync(f => f.Id == entityId);
                if (form == null) throw new ArgumentException($"Form {entityId} not found.");

                var formParams = form.FormParams?
                    .Select(fp => new { fp.TestId, fp.IsCalculated, fp.Formula, fp.CodeRelatedArrays, fp.IsRequired, fp.DefaultValue, fp.NrOrd, fp.NrOrdCalc, fp.HasCondition, fp.Condition, fp.ConditionNote })
                    .OrderBy(fp => fp.NrOrd)
                    .ToList() ?? new();

                bool isFormApproval = string.Equals(signatureMeaning, "Approval", StringComparison.OrdinalIgnoreCase);

                return new
                {
                    form.Id,
                    form.FormGroupId,
                    form.Version,
                    form.IsCustomized,
                    form.IsSubmitted,
                    form.UserSubmittedId,
                    DateSubmitted = form.DateSubmitted.HasValue ? form.DateSubmitted.Value.ToString("s") : null,
                    form.CommentsSubmitted,
                    form.IsValidated,
                    form.UserValidatedId,
                    DateValidated = form.DateValidated.HasValue ? form.DateValidated.Value.ToString("s") : null,
                    form.CommentsValidated,
                    Params = formParams
                };

            default:
                throw new ArgumentException($"Unsupported entity for electronic signature: {entityName}");
        }
    }

    private static string ComputeSha256Hash(string rawData)
    {
        using var sha256 = SHA256.Create();
        var bytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(rawData));
        var builder = new StringBuilder();
        foreach (var b in bytes)
        {
            builder.Append(b.ToString("x2"));
        }
        return builder.ToString();
    }
}
