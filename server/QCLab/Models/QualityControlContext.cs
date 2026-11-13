using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;

namespace QCLab.Models;

public partial class QualityControlContext : DbContext
{
    public QualityControlContext()
    {
    }

    public QualityControlContext(DbContextOptions<QualityControlContext> options)
        : base(options)
    {
    }

    public virtual DbSet<AuditLog> AuditLogs { get; set; }

    public virtual DbSet<Category> Categories { get; set; }

    public virtual DbSet<Certificate> Certificates { get; set; }

    public virtual DbSet<CertificateTest> CertificateTests { get; set; }

    public virtual DbSet<ControlCode> ControlCodes { get; set; }

    public virtual DbSet<ElectronicSignature> ElectronicSignatures { get; set; }

    public virtual DbSet<Equipment> Equipments { get; set; }

    public virtual DbSet<EquipmentCalibration> EquipmentCalibrations { get; set; }

    public virtual DbSet<EquipmentCalibrationStatus> EquipmentCalibrationStatuses { get; set; }

    public virtual DbSet<EquipmentStatus> EquipmentStatuses { get; set; }

    public virtual DbSet<Form> Forms { get; set; }

    public virtual DbSet<FormConditionEval> FormConditionEvals { get; set; }

    public virtual DbSet<FormEval> FormEvals { get; set; }

    public virtual DbSet<FormEvalParam> FormEvalParams { get; set; }

    public virtual DbSet<FormGroup> FormGroups { get; set; }

    public virtual DbSet<FormParam> FormParams { get; set; }

    public virtual DbSet<Material> Materials { get; set; }

    public virtual DbSet<Measurement> Measurements { get; set; }

    public virtual DbSet<MeasurementParam> MeasurementParams { get; set; }

    public virtual DbSet<MeasurementTest> MeasurementTests { get; set; }

    public virtual DbSet<Norm> Norms { get; set; }

    public virtual DbSet<ReagentLot> ReagentLots { get; set; }

    public virtual DbSet<ReagentLotStatus> ReagentLotStatuses { get; set; }

    public virtual DbSet<ReagentSupplier> ReagentSuppliers { get; set; }

    public virtual DbSet<ReagentSupplierLot> ReagentSupplierLots { get; set; }

    public virtual DbSet<ReagentSupplierLotCertTest> ReagentSupplierLotCertTests { get; set; }

    public virtual DbSet<Reception> Receptions { get; set; }

    public virtual DbSet<ReceptionType> ReceptionTypes { get; set; }

    public virtual DbSet<Report> Reports { get; set; }

    public virtual DbSet<ReportTest> ReportTests { get; set; }

    public virtual DbSet<Sop> Sops { get; set; }

    public virtual DbSet<SopVersion> SopVersions { get; set; }

    public virtual DbSet<Spec> Specs { get; set; }

    public virtual DbSet<SpecTest> SpecTests { get; set; }

    public virtual DbSet<SpecTestEval> SpecTestEvals { get; set; }

    public virtual DbSet<Test> Tests { get; set; }

    public virtual DbSet<TestEnum> TestEnums { get; set; }

    public virtual DbSet<Unit> Units { get; set; }

    public virtual DbSet<User> Users { get; set; }

    public virtual DbSet<ValueType> ValueTypes { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        // #warning To protect potentially sensitive information in your connection string, you should move it out of source code. You can avoid scaffolding the connection string by using the Name= syntax to read it from configuration - see https://go.microsoft.com/fwlink/?linkid=2131148. For more guidance on storing connection strings, see https://go.microsoft.com/fwlink/?LinkId=723263.
        // optionsBuilder.UseNpgsql("Host=localhost;Username=postgres;Password=Pass@word1;Database=quality_control");
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<AuditLog>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("audit_logs_pkey");

            entity.ToTable("audit_logs", tb => tb.HasComment("GxP and 21 CFR Part 11 compliant audit trail log table. Automatically populated via the PostgreSQL trigger function 'process_audit_log()' whenever INSERT, UPDATE, or DELETE operations occur on critical quality tables (certificates, certificate_tests, forms, form_params, measurements, measurement_params, measurement_tests, reports, report_tests, specs, spec_tests). Application user context and justification are injected into PostgreSQL session variables ('app.current_user_id' and 'app.reason_for_change') by the server DbCommandInterceptor 'AuditSessionDbCommandInterceptor'."));

            entity.Property(e => e.Id)
                .HasComment("Primary key. Unique synthetic 64-bit integer identifier for each audit trail entry.")
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.Action)
                .HasMaxLength(10)
                .HasComment("DML operation type performed on the record: 'INSERT', 'UPDATE', or 'DELETE'. Populated via TG_OP in the audit trigger.")
                .HasColumnName("action");
            entity.Property(e => e.ChangedFields)
                .HasComment("PostgreSQL text array (TEXT[]) listing the column names whose values were modified during an UPDATE operation. Allows rapid filtering and visual highlighting of specific edited fields in the audit viewer (AuditLogsTable.tsx).")
                .HasColumnName("changed_fields");
            entity.Property(e => e.ClientIp)
                .HasMaxLength(45)
                .HasComment("Network IP address (IPv4 or IPv6, up to 45 characters) of the client machine that initiated the API request. Captured by ASP.NET Core HttpContextAccessor and recorded for forensic cybersecurity and compliance traceability.")
                .HasColumnName("client_ip");
            entity.Property(e => e.NewData)
                .HasComment("JSONB snapshot of the entire table row after the change occurred. Set to NULL for DELETE actions; contains post-modification state for INSERT and UPDATE actions.")
                .HasColumnType("jsonb")
                .HasColumnName("new_data");
            entity.Property(e => e.OldData)
                .HasComment("JSONB snapshot of the entire table row before the change occurred. Set to NULL for INSERT actions; contains pre-modification state for UPDATE and DELETE actions.")
                .HasColumnType("jsonb")
                .HasColumnName("old_data");
            entity.Property(e => e.ReasonForChange)
                .HasComment("Mandatory user-supplied justification for the modification. Captured in the UI via modal dialogs (e.g. CommentDialog) and transferred into PostgreSQL via the session variable 'app.reason_for_change' to ensure compliance with 21 CFR Part 11 requirements.")
                .HasColumnName("reason_for_change");
            entity.Property(e => e.RecordKeys)
                .HasComment("JSONB object capturing the primary key column names and values of the audited record (e.g., {\"id\": 105} or composite keys like {\"form_id\": 2, \"test_id\": 14, \"idx\": 0}). Enables exact historical row tracking.")
                .HasColumnType("jsonb")
                .HasColumnName("record_keys");
            entity.Property(e => e.TableName)
                .HasMaxLength(100)
                .HasComment("Name of the database table where the DML modification took place (e.g., 'measurements', 'forms', 'specs'). Populated automatically by the trigger via TG_TABLE_NAME.")
                .HasColumnName("table_name");
            entity.Property(e => e.Timestamp)
                .HasDefaultValueSql("clock_timestamp()")
                .HasComment("Timestamp with time zone indicating the exact database transaction time when the audit entry was written. Defaults to clock_timestamp() to capture accurate wall-clock execution time.")
                .HasColumnName("timestamp");
            entity.Property(e => e.UserId)
                .HasComment("Foreign key referencing public.users(id). Identifies the laboratory analyst or QC supervisor who executed the transaction. Sourced from the transaction session variable 'app.current_user_id' set by AuditSessionDbCommandInterceptor.")
                .HasColumnName("user_id");

            entity.HasOne(d => d.User).WithMany(p => p.AuditLogs)
                .HasForeignKey(d => d.UserId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("audit_logs_user_id_fkey");
        });

        modelBuilder.Entity<Category>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("categories_pkey");

            entity.ToTable("categories", tb => tb.HasComment("Master classification table grouping materials and products into logical families (e.g., 'Finished Products', 'Active Pharmaceutical Ingredients', 'Excipients', 'Solvents'). Used for organizing catalog items and driving ad-hoc Category Verification sample receptions."));

            entity.HasIndex(e => e.Code, "categories_code_key").IsUnique();

            entity.HasIndex(e => e.Name, "categories_name_key").IsUnique();

            entity.Property(e => e.Id)
                .HasComment("Primary key. Unique 64-bit integer identifier for the category.")
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.Code)
                .HasMaxLength(5)
                .HasComment("Unique 2 to 5 character uppercase alphanumeric classification code (regex /^[A-Z][A-Z0-9]*$/). Validated for uniqueness on the client and server.")
                .HasColumnName("code");
            entity.Property(e => e.CommentsObsolete)
                .HasComment("Documented reason recorded when retiring the category. Cleared to NULL if reactivated.")
                .HasColumnName("comments_obsolete");
            entity.Property(e => e.DateCreated)
                .HasComment("Timestamp with time zone when the category was established.")
                .HasColumnName("date_created");
            entity.Property(e => e.DateObsolete)
                .HasComment("Timestamp with time zone when the category was retired. Cleared to NULL if reactivated.")
                .HasColumnName("date_obsolete");
            entity.Property(e => e.Description)
                .HasComment("Optional extended description of the category scope and materials covered.")
                .HasColumnName("description");
            entity.Property(e => e.IsObsolete)
                .HasComment("Soft-deletion flag. When true, prevents the category from being selected in new material definitions or category verification receptions while preserving historical records.")
                .HasColumnName("is_obsolete");
            entity.Property(e => e.Name)
                .HasMaxLength(50)
                .HasComment("Unique name of the material category (3 to 50 characters). Validated for uniqueness on blur in CategoryDialog.tsx.")
                .HasColumnName("name");

            entity.HasMany(d => d.Tests).WithMany(p => p.Categories)
                .UsingEntity<Dictionary<string, object>>(
                    "CategoryTest",
                    r => r.HasOne<Test>().WithMany()
                        .HasForeignKey("TestId")
                        .OnDelete(DeleteBehavior.ClientSetNull)
                        .HasConstraintName("category_tests_test_id_fkey"),
                    l => l.HasOne<Category>().WithMany()
                        .HasForeignKey("CategoryId")
                        .HasConstraintName("category_tests_category_id_fkey"),
                    j =>
                    {
                        j.HasKey("CategoryId", "TestId").HasName("category_tests_pkey");
                        j.ToTable("category_tests", tb => tb.HasComment("Many-to-many junction table associating laboratory test definitions with material categories. Defines the standard battery of tests applicable to an entire category. When creating a Category Verification sample reception (CategoryVerificationDialog.tsx), selecting a category dynamically pre-populates the list of available tests from this table."));
                        j.IndexerProperty<long>("CategoryId")
                            .HasComment("Primary key and foreign key referencing public.categories(id). The material category receiving the test assignment.")
                            .HasColumnName("category_id");
                        j.IndexerProperty<long>("TestId")
                            .HasComment("Primary key and foreign key referencing public.tests(id). The analytical test assigned to the category.")
                            .HasColumnName("test_id");
                    });
        });

        modelBuilder.Entity<Certificate>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("certificates_pkey");

            entity.ToTable("certificates", tb => tb.HasComment("Official Quality Certificates / Certificates of Analysis (COA) issued for a manufactured batch or raw material lot (control_code_id). Evaluates laboratory test results against the active specification (spec_id). Computes both direct specification conformance and uncertainty guard-band conformance (ISO/IEC 17025 / ILAC-G8). Enforces 21 CFR Part 11 digital signatures on approval."));

            entity.Property(e => e.Id)
                .HasComment("Primary key. Unique 64-bit integer identifier for the quality certificate.")
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.CertificateReplacedId)
                .HasComment("Foreign key referencing public.certificates(id) (nullable). Points to the previous certificate revision that this document supersedes.")
                .HasColumnName("certificate_replaced_id");
            entity.Property(e => e.CommentsCancelled)
                .HasComment("Mandatory documented justification explaining why the quality certificate was revoked.")
                .HasColumnName("comments_cancelled");
            entity.Property(e => e.CommentsSubmitted)
                .HasComment("Quality assurance release disposition notes, authorized deviations, or release comments.")
                .HasColumnName("comments_submitted");
            entity.Property(e => e.ControlCodeId)
                .HasComment("Foreign key referencing public.control_codes(id). The batch or inventory lot covered by this certificate.")
                .HasColumnName("control_code_id");
            entity.Property(e => e.DateCancelled)
                .HasComment("Timestamp with time zone when the certificate was cancelled.")
                .HasColumnName("date_cancelled");
            entity.Property(e => e.DateSubmitted)
                .HasComment("Timestamp with time zone when the certificate was signed and released.")
                .HasColumnName("date_submitted");
            entity.Property(e => e.IsCancelled)
                .HasComment("Boolean status flag. True indicates the certificate was officially revoked or cancelled.")
                .HasColumnName("is_cancelled");
            entity.Property(e => e.IsConformingSpec)
                .HasComment("Boolean conformance flag. True indicates that ALL required tests meet specification limits and no mandatory specification tests are missing. Calculated automatically by CertificatesService.CalculateAndSaveCertificateTests.")
                .HasColumnName("is_conforming_spec");
            entity.Property(e => e.IsConformingUncertainty)
                .HasDefaultValue(true)
                .HasComment("Boolean guard-band conformance flag implementing ISO/IEC 17025 / ILAC-G8 decision rules. True indicates that both the lower bound [value - U] and upper bound [value + U] fall within the specification acceptance range for all tests.")
                .HasColumnName("is_conforming_uncertainty");
            entity.Property(e => e.IsSubmitted)
                .HasComment("Boolean status flag. True indicates the Quality Certificate has been formally approved and released with a 21 CFR Part 11 electronic signature.")
                .HasColumnName("is_submitted");
            entity.Property(e => e.SpecId)
                .HasComment("Foreign key referencing public.specs(id). The active specification used to evaluate batch conformance.")
                .HasColumnName("spec_id");
            entity.Property(e => e.UserCancelledId)
                .HasComment("Foreign key referencing public.users(id) (nullable). The user who revoked the certificate.")
                .HasColumnName("user_cancelled_id");
            entity.Property(e => e.UserSubmittedId)
                .HasComment("Foreign key referencing public.users(id) (nullable). The authorized QC manager / Qualified Person who signed and released the certificate.")
                .HasColumnName("user_submitted_id");

            entity.HasOne(d => d.CertificateReplaced).WithMany(p => p.InverseCertificateReplaced)
                .HasForeignKey(d => d.CertificateReplacedId)
                .HasConstraintName("certificates_certificate_replaced_id_fkey");

            entity.HasOne(d => d.ControlCode).WithMany(p => p.Certificates)
                .HasForeignKey(d => d.ControlCodeId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("certificates_control_code_id_fkey");

            entity.HasOne(d => d.Spec).WithMany(p => p.Certificates)
                .HasForeignKey(d => d.SpecId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("certificates_specs_id_fkey");

            entity.HasOne(d => d.UserCancelled).WithMany(p => p.CertificateUserCancelleds)
                .HasForeignKey(d => d.UserCancelledId)
                .HasConstraintName("certificates_user_cancelled_id_fkey");

            entity.HasOne(d => d.UserSubmitted).WithMany(p => p.CertificateUserSubmitteds)
                .HasForeignKey(d => d.UserSubmittedId)
                .HasConstraintName("certificates_user_submitted_id_fkey");
        });

        modelBuilder.Entity<CertificateTest>(entity =>
        {
            entity.HasKey(e => new { e.CertificateId, e.ReportId, e.TestId, e.Idx, e.MeasurementId }).HasName("certificate_tests_pkey");

            entity.ToTable("certificate_tests", tb => tb.HasComment("Line-item analytical test evaluations displayed on the Quality Certificate / Certificate of Analysis (COA). Contains evaluated test results, expanded uncertainty values, individual specification compliance flags (is_conforming_spec), guard-band compliance flags (is_conforming_uncertainty), and snapshots of specification limits (note_spec)."));

            entity.Property(e => e.CertificateId)
                .HasComment("Primary key and foreign key referencing public.certificates(id). The parent quality certificate.")
                .HasColumnName("certificate_id");
            entity.Property(e => e.ReportId)
                .HasComment("Primary key and foreign key referencing public.reports(id). The source test report providing the data.")
                .HasColumnName("report_id");
            entity.Property(e => e.TestId)
                .HasComment("Primary key and foreign key referencing public.tests(id). The analytical test evaluated.")
                .HasColumnName("test_id");
            entity.Property(e => e.Idx)
                .HasComment("Primary key. Determination index (0 for scalar, 0..N for replicated arrays).")
                .HasColumnName("idx");
            entity.Property(e => e.MeasurementId)
                .HasComment("Primary key and foreign key referencing public.measurements(id). The raw measurement session.")
                .HasColumnName("measurement_id");
            entity.Property(e => e.CoverageFactorK)
                .HasComment("Coverage factor k (typically 2.0) applied to the uncertainty estimate.")
                .HasColumnName("coverage_factor_k");
            entity.Property(e => e.IsConformingSpec)
                .HasComment("Boolean flag. Evaluated by executing the specification condition formula (spec_tests.condition) against the measured value. True if value meets specification limits; false otherwise.")
                .HasColumnName("is_conforming_spec");
            entity.Property(e => e.IsConformingUncertainty)
                .HasDefaultValue(true)
                .HasComment("Boolean flag. Evaluated by checking whether both [value - uncertainty_value] AND [value + uncertainty_value] satisfy the specification condition formula. Enforces ILAC-G8 guard-banding rules for ISO/IEC 17025 accredited reporting.")
                .HasColumnName("is_conforming_uncertainty");
            entity.Property(e => e.NoteSpec)
                .HasMaxLength(25)
                .HasComment("Historical snapshot text of the specification acceptance criteria in effect at the time of certification (maximum 25 characters, e.g., '>= 98.0%', 'Clear liquid'). Preserves exact historical limits regardless of future spec revisions.")
                .HasColumnName("note_spec");
            entity.Property(e => e.TestCount)
                .HasComment("Integer count of determinations or replicates performed to establish this result (defaults to 0).")
                .HasColumnName("test_count");
            entity.Property(e => e.UncertaintyValue)
                .HasComment("Expanded measurement uncertainty U associated with the certified result.")
                .HasColumnName("uncertainty_value");
            entity.Property(e => e.Value)
                .HasComment("Certified analytical test result value.")
                .HasColumnName("value");

            entity.HasOne(d => d.Certificate).WithMany(p => p.CertificateTests)
                .HasForeignKey(d => d.CertificateId)
                .HasConstraintName("certificate_tests_certificates_id_fkey");

            entity.HasOne(d => d.Measurement).WithMany(p => p.CertificateTests)
                .HasForeignKey(d => d.MeasurementId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("certificate_tests_measurement_id_fkey");

            entity.HasOne(d => d.Report).WithMany(p => p.CertificateTests)
                .HasForeignKey(d => d.ReportId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("certificate_tests_report_id_fkey");

            entity.HasOne(d => d.Test).WithMany(p => p.CertificateTests)
                .HasForeignKey(d => d.TestId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("certificate_tests_test_id_fkey");

            entity.HasOne(d => d.ReportTest).WithMany(p => p.CertificateTests)
                .HasForeignKey(d => new { d.ReportId, d.MeasurementId, d.TestId, d.Idx })
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("certificate_tests_report_id_measurement_id_test_id_idx_fkey");
        });

        modelBuilder.Entity<ControlCode>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("control_codes_pkey");

            entity.ToTable("control_codes", tb => tb.HasComment("Central batch/lot identification and inventory tracking table. Every physical batch of manufactured product, raw material delivery, purchased reagent lot, or in-house prepared reagent is assigned a unique control code linked to its material. Serves as the primary traceability anchor across sample receptions, testing worksheets, quality certificates, and reagent genealogy."));

            entity.HasIndex(e => new { e.MaterialId, e.Code }, "control_codes_material_id_code_key").IsUnique();

            entity.Property(e => e.Id)
                .HasComment("Primary key. Unique 64-bit integer identifier for the control code record.")
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.Code)
                .HasMaxLength(50)
                .HasComment("Alphanumeric batch/control code string (up to 50 characters). Unique per material. Must contain no whitespace (enforced by regex /^\\S*$/). In sample reception dialogs (CertificationDialog, VerificationDialog), users can select an existing control code or enter a new one, which is verified for uniqueness against the selected material via UniquenessChecker.")
                .HasColumnName("code");
            entity.Property(e => e.DateCreated)
                .HasDefaultValueSql("clock_timestamp()")
                .HasComment("Timestamp with time zone when the control code was generated. Defaults to clock_timestamp().")
                .HasColumnName("date_created");
            entity.Property(e => e.IsReceptionReceived)
                .HasComment("Boolean status flag. Automatically updated from false to true when any sample reception referencing this control code is accepted into the laboratory (ReceptionsService.ReceiveReception). Signals that physical samples of this batch have been received in the lab.")
                .HasColumnName("is_reception_received");
            entity.Property(e => e.MaterialId)
                .HasComment("Foreign key referencing public.materials(id). The specific material, chemical, or product to which this batch/lot belongs.")
                .HasColumnName("material_id");

            entity.HasOne(d => d.Material).WithMany(p => p.ControlCodes)
                .HasForeignKey(d => d.MaterialId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("control_codes_material_id_fkey");
        });

        modelBuilder.Entity<ElectronicSignature>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("electronic_signatures_pkey");

            entity.ToTable("electronic_signatures", tb => tb.HasComment("Cryptographic electronic signature ledger enforcing 21 CFR Part 11 and EU GMP Annex 11 compliance. Stores legally binding digital signatures executed when laboratory personnel submit, validate, approve, or cancel critical quality documents (forms, specifications, test reports, quality certificates). Includes SHA-256 payload digests and human-readable signature manifests."));

            entity.Property(e => e.Id)
                .HasComment("Primary key. Unique 64-bit integer identifier for the electronic signature record.")
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.ClientIp)
                .HasMaxLength(45)
                .HasComment("Network IPv4/IPv6 client IP address from which the signature action was executed.")
                .HasColumnName("client_ip");
            entity.Property(e => e.EntityId)
                .HasComment("Primary key identifier of the specific domain record being digitally signed (e.g., forms.id, specs.id, certificates.id).")
                .HasColumnName("entity_id");
            entity.Property(e => e.EntityName)
                .HasMaxLength(50)
                .HasComment("Name of the audited domain entity/table to which the signature applies (e.g., 'forms', 'specs', 'reports', 'certificates').")
                .HasColumnName("entity_name");
            entity.Property(e => e.PayloadSha256)
                .HasMaxLength(64)
                .HasComment("Hex-encoded 64-character SHA-256 cryptographic hash of the canonical JSON representation of the entity state at the moment of signing. Guarantees tamper-evidence and data integrity: any post-signature tampering invalidates the hash verification.")
                .HasColumnName("payload_sha256");
            entity.Property(e => e.SignatureManifestText)
                .HasComment("Human-readable text manifest summarizing the signed record details, signer full name, user tag, signature meaning, and timestamp. Rendered in the client UI via SignatureManifestBlock.tsx for inspection during audits.")
                .HasColumnName("signature_manifest_text");
            entity.Property(e => e.SignatureMeaning)
                .HasMaxLength(50)
                .HasComment("Legally defined statement of intent / meaning of the signature (e.g., 'Submission', 'Validation', 'Approval', 'Cancellation'). Specifies the signer's regulatory responsibility pursuant to 21 CFR § 11.50.")
                .HasColumnName("signature_meaning");
            entity.Property(e => e.SignerUserId)
                .HasComment("Foreign key referencing public.users(id). The authenticated user who entered their credentials and executed the signature.")
                .HasColumnName("signer_user_id");
            entity.Property(e => e.SigningTimestamp)
                .HasDefaultValueSql("clock_timestamp()")
                .HasComment("Cryptographic timestamp with time zone at the exact instant the signature was sealed. Defaults to clock_timestamp().")
                .HasColumnName("signing_timestamp");
            entity.Property(e => e.Version)
                .HasDefaultValue(1L)
                .HasComment("Monotonically increasing sequence number (defaults to 1) indicating the revision of the signature on a given entity record (e.g., Version 1 for initial submission, Version 2 for revision/approval, Version 3 for cancellation).")
                .HasColumnName("version");

            entity.HasOne(d => d.SignerUser).WithMany(p => p.ElectronicSignatures)
                .HasForeignKey(d => d.SignerUserId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("electronic_signatures_signer_user_id_fkey");
        });

        modelBuilder.Entity<Equipment>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("equipment_pkey");

            entity.ToTable("equipments", tb => tb.HasComment("Master inventory register of laboratory instruments, analytical balances, chromatography systems, and spectrophotometers. Tracks physical location, serial numbers, calibration schedules, and operational readiness under ISO/IEC 17025 and 21 CFR Part 211."));

            entity.HasIndex(e => e.EquipmentCode, "equipment_equipment_code_key").IsUnique();

            entity.HasIndex(e => e.SerialNumber, "equipments_serial_number_key").IsUnique();

            entity.Property(e => e.Id)
                .HasComment("Primary key. Unique 64-bit integer identifier for the equipment asset.")
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.CalibrationIntervalDays)
                .HasDefaultValue(365)
                .HasComment("Number of days between required periodic recalibrations (integer, defaults to 365 days / 1 year).")
                .HasColumnName("calibration_interval_days");
            entity.Property(e => e.DateCreated)
                .HasDefaultValueSql("clock_timestamp()")
                .HasComment("Timestamp with time zone when the equipment asset was registered in the database. Defaults to clock_timestamp().")
                .HasColumnName("date_created");
            entity.Property(e => e.EquipmentCode)
                .HasMaxLength(50)
                .HasComment("Unique laboratory internal asset tag or barcode (2 to 20 characters, e.g., 'BAL-001', 'HPLC-UV-03'). Used on sample worksheets and equipment selection dialogs.")
                .HasColumnName("equipment_code");
            entity.Property(e => e.Location)
                .HasMaxLength(100)
                .HasComment("Laboratory room, bench, or cleanroom zone where the instrument is installed (maximum 100 characters, e.g., 'QC Phys-Chem Room 204').")
                .HasColumnName("location");
            entity.Property(e => e.Manufacturer)
                .HasMaxLength(100)
                .HasComment("Name of the equipment manufacturer or OEM (maximum 100 characters, e.g., 'Mettler Toledo', 'Waters', 'Agilent').")
                .HasColumnName("manufacturer");
            entity.Property(e => e.Model)
                .HasMaxLength(100)
                .HasComment("Manufacturer model number or instrument family (maximum 100 characters, e.g., 'Alliance e2695', 'XS204').")
                .HasColumnName("model");
            entity.Property(e => e.Name)
                .HasMaxLength(100)
                .HasComment("Descriptive equipment title (2 to 100 characters, e.g., 'Analytical Balance XP205', 'UV-Vis Spectrophotometer Evolution 300').")
                .HasColumnName("name");
            entity.Property(e => e.NextCalibrationDue)
                .HasComment("Calendar date when the instrument must next undergo calibration. Automatically updated from the expiration_date of the most recently recorded calibration certificate.")
                .HasColumnName("next_calibration_due");
            entity.Property(e => e.SerialNumber)
                .HasMaxLength(100)
                .HasComment("Unique manufacturer serial number (maximum 100 characters). Enforces instrument hardware identity.")
                .HasColumnName("serial_number");
            entity.Property(e => e.StatusId)
                .HasComment("Foreign key referencing public.equipment_statuses(id). Operational state of the instrument. Automatically set to 'Active' when a successful calibration is recorded in EquipmentsService.AddEquipmentCalibration.")
                .HasColumnName("status_id");

            entity.HasOne(d => d.Status).WithMany(p => p.Equipment)
                .HasForeignKey(d => d.StatusId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("equipments_status_id_fkey");
        });

        modelBuilder.Entity<EquipmentCalibration>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("equipment_calibrations_pkey");

            entity.ToTable("equipment_calibrations", tb => tb.HasComment("Historical calibration log and certificate registry for laboratory instruments. Adding or updating a calibration certificate in EquipmentCalibrationDialog.tsx automatically propagates the expiration_date to equipments.next_calibration_due and restores the instrument status to 'Active'."));

            entity.Property(e => e.Id)
                .HasComment("Primary key. Unique 64-bit integer identifier for the calibration event.")
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.CalibratedBy)
                .HasMaxLength(100)
                .HasComment("Name of the accredited metrology calibration service provider or internal calibration technician (maximum 100 characters).")
                .HasColumnName("calibrated_by");
            entity.Property(e => e.CalibrationDate)
                .HasComment("Date when the physical calibration procedure was performed.")
                .HasColumnName("calibration_date");
            entity.Property(e => e.CertificateNumber)
                .HasMaxLength(100)
                .HasComment("Unique external or internal calibration certificate tracking number (maximum 100 characters, e.g., 'CAL-2026-09871').")
                .HasColumnName("certificate_number");
            entity.Property(e => e.DateCreated)
                .HasDefaultValueSql("clock_timestamp()")
                .HasComment("Timestamp with time zone when the calibration record was logged into the system. Defaults to clock_timestamp().")
                .HasColumnName("date_created");
            entity.Property(e => e.EquipmentId)
                .HasComment("Foreign key referencing public.equipments(id). The laboratory instrument subjected to calibration.")
                .HasColumnName("equipment_id");
            entity.Property(e => e.ExpandedUncertainty)
                .HasComment("Expanded measurement uncertainty of the calibration method itself (NUMERIC), as stated on the calibration certificate.")
                .HasColumnName("expanded_uncertainty");
            entity.Property(e => e.ExpirationDate)
                .HasComment("Date when this calibration certificate expires. Automatically updates equipments.next_calibration_due.")
                .HasColumnName("expiration_date");
            entity.Property(e => e.ReferenceStandardsUsed)
                .HasComment("Text details of traceable reference standards (e.g., NIST-traceable weights, calibrated quartz cuvettes) utilized during the calibration.")
                .HasColumnName("reference_standards_used");
            entity.Property(e => e.StatusId)
                .HasComment("Foreign key referencing public.equipment_calibration_statuses(id) (1='Pass', 2='Fail', 3='Limited Use').")
                .HasColumnName("status_id");

            entity.HasOne(d => d.Equipment).WithMany(p => p.EquipmentCalibrations)
                .HasForeignKey(d => d.EquipmentId)
                .HasConstraintName("equipment_calibrations_equipment_id_fkey");

            entity.HasOne(d => d.Status).WithMany(p => p.EquipmentCalibrations)
                .HasForeignKey(d => d.StatusId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("equipment_calibrations_status_id_fkey");
        });

        modelBuilder.Entity<EquipmentCalibrationStatus>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("equipment_calibration_statuses_pkey");

            entity.ToTable("equipment_calibration_statuses", tb => tb.HasComment("Lookup catalog for metrological calibration outcomes: 1 = 'Pass' (metrology results conform fully to manufacturer tolerances and uncertainty limits), 2 = 'Fail' (out-of-tolerance calibration requiring instrument repair or retirement), 3 = 'Limited Use' (calibrated with restricted operational range or derated accuracy limits)."));

            entity.HasIndex(e => e.Name, "equipment_calibration_statuses_name_key").IsUnique();

            entity.Property(e => e.Id)
                .ValueGeneratedNever()
                .HasComment("Primary key. Unique identifier for the calibration outcome status.")
                .HasColumnName("id");
            entity.Property(e => e.Name)
                .HasMaxLength(50)
                .HasComment("Unique name of the calibration status ('Pass', 'Fail', 'Limited Use').")
                .HasColumnName("name");
        });

        modelBuilder.Entity<EquipmentStatus>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("equipment_statuses_pkey");

            entity.ToTable("equipment_statuses", tb => tb.HasComment("Lookup catalog for operational status of analytical laboratory instruments: 1 = 'Active' (calibrated, qualified, and authorized for routine testing), 2 = 'Inactive' (standby or temporarily decommissioned), 3 = 'Calibration Due' (calibration overdue, locked from testing), 4 = 'Out of Service' (defective, undergoing repair, or failed calibration)."));

            entity.HasIndex(e => e.Name, "equipment_statuses_name_key").IsUnique();

            entity.Property(e => e.Id)
                .ValueGeneratedNever()
                .HasComment("Primary key. Unique identifier for the equipment operational status.")
                .HasColumnName("id");
            entity.Property(e => e.Name)
                .HasMaxLength(50)
                .HasComment("Unique status name ('Active', 'Inactive', 'Calibration Due', 'Out of Service').")
                .HasColumnName("name");
        });

        modelBuilder.Entity<Form>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("forms_pkey");

            entity.ToTable("forms", tb => tb.HasComment("Version-controlled dynamic analytical worksheet templates. Encapsulates formula calculation graphs, topological evaluation orders, conditional rules, and software validation datasets. Enforces GxP lifecycle state progression: Draft -> Submitted -> Validated -> Cancelled, accompanied by 21 CFR Part 11 electronic signatures."));

            entity.Property(e => e.Id)
                .HasComment("Primary key. Unique 64-bit integer identifier for the form template.")
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.CommentsCancelled)
                .HasComment("Mandatory documented justification explaining why the form was cancelled.")
                .HasColumnName("comments_cancelled");
            entity.Property(e => e.CommentsSubmitted)
                .HasComment("Author notes, design rationale, or change summary recorded at submission.")
                .HasColumnName("comments_submitted");
            entity.Property(e => e.CommentsValidated)
                .HasComment("Formal validation approval remarks recorded by the QC reviewer.")
                .HasColumnName("comments_validated");
            entity.Property(e => e.CustomNav)
                .HasComment("Frontend component route or navigation tag (e.g., 'TestingFormA') defining the custom layout renderer. Mandatory if is_customized is true; nullable if standard generic rendering is used.")
                .HasColumnName("custom_nav");
            entity.Property(e => e.DateCancelled)
                .HasComment("Timestamp with time zone when the form was cancelled.")
                .HasColumnName("date_cancelled");
            entity.Property(e => e.DateSubmitted)
                .HasComment("Timestamp with time zone when the form was submitted.")
                .HasColumnName("date_submitted");
            entity.Property(e => e.DateValidated)
                .HasComment("Timestamp with time zone when validation approval was granted.")
                .HasColumnName("date_validated");
            entity.Property(e => e.DaysActiveForEditing)
                .HasDefaultValue(10)
                .HasComment("Grace period in days (integer, defaults to 10) during which a worksheet instance generated from this form remains editable. Once this elapsed time expires following creation, the worksheet automatically becomes locked (is_readonly = true).")
                .HasColumnName("days_active_for_editing");
            entity.Property(e => e.FormGroupId)
                .HasComment("Foreign key referencing public.form_groups(id). The parent group / test family to which this form template belongs.")
                .HasColumnName("form_group_id");
            entity.Property(e => e.IsCancelled)
                .HasComment("Boolean lifecycle flag. True indicates the form template was cancelled or superseded. Cancelled forms cannot be selected for new sample receptions or measurements.")
                .HasColumnName("is_cancelled");
            entity.Property(e => e.IsCustomized)
                .HasComment("Boolean flag indicating that this form relies on a dedicated, specialized frontend UI component rather than standard auto-rendered grid layout. In FormDialog.tsx, when checked, custom_nav is mandatory.")
                .HasColumnName("is_customized");
            entity.Property(e => e.IsSubmitted)
                .HasComment("Boolean lifecycle flag. True indicates the form template has been finalized and submitted for formal verification.")
                .HasColumnName("is_submitted");
            entity.Property(e => e.IsValidated)
                .HasComment("Boolean approval flag. When true, the form is validated for routine production testing. Validation requires that all verification test cases (form_evals) PASS. Approving a form creates an electronic signature, marks form_groups.is_form_validated = true, and locks tests.is_form_validated = true for all referenced tests.")
                .HasColumnName("is_validated");
            entity.Property(e => e.UserCancelledId)
                .HasComment("Foreign key referencing public.users(id) (nullable). The user who cancelled the form template.")
                .HasColumnName("user_cancelled_id");
            entity.Property(e => e.UserSubmittedId)
                .HasComment("Foreign key referencing public.users(id) (nullable). The form author who submitted the template.")
                .HasColumnName("user_submitted_id");
            entity.Property(e => e.UserValidatedId)
                .HasComment("Foreign key referencing public.users(id) (nullable). The QC supervisor / system owner who validated and approved the form.")
                .HasColumnName("user_validated_id");
            entity.Property(e => e.Version)
                .HasMaxLength(50)
                .HasComment("Version number string (maximum 50 characters, e.g., '1.0', '2.1'). Unique per form group.")
                .HasColumnName("version");

            entity.HasOne(d => d.FormGroup).WithMany(p => p.Forms)
                .HasForeignKey(d => d.FormGroupId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("forms_form_group_id_fkey");

            entity.HasOne(d => d.UserCancelled).WithMany(p => p.FormUserCancelleds)
                .HasForeignKey(d => d.UserCancelledId)
                .HasConstraintName("forms_user_canceled_id_fkey");

            entity.HasOne(d => d.UserSubmitted).WithMany(p => p.FormUserSubmitteds)
                .HasForeignKey(d => d.UserSubmittedId)
                .HasConstraintName("forms_user_submitted_id_fkey");

            entity.HasOne(d => d.UserValidated).WithMany(p => p.FormUserValidateds)
                .HasForeignKey(d => d.UserValidatedId)
                .HasConstraintName("forms_user_validated_id_fkey");
        });

        modelBuilder.Entity<FormConditionEval>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("form_condition_evals_pkey");

            entity.ToTable("form_condition_evals", tb => tb.HasComment("Benchmark test cases verifying parameter condition logic (form_params.condition). Validates that conditional acceptance rules correctly yield 1 (pass) or 0 (fail) against known test input values."));

            entity.Property(e => e.Id)
                .HasComment("Primary key. Unique 64-bit integer identifier for the condition evaluation test row.")
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.ExpectedResult)
                .HasComment("Expected outcome (1 for pass, 0 for fail) specified by the form author.")
                .HasColumnName("expected_result");
            entity.Property(e => e.FormId)
                .HasComment("Foreign key referencing public.forms(id). The parent form template.")
                .HasColumnName("form_id");
            entity.Property(e => e.IsMatch)
                .HasComment("Boolean flag. True indicates result matches expected_result.")
                .HasColumnName("is_match");
            entity.Property(e => e.Note)
                .HasMaxLength(20)
                .HasComment("Short explanation of the test condition boundary (maximum 20 characters, e.g., 'Upper limit', 'Nominal pass').")
                .HasColumnName("note");
            entity.Property(e => e.Result)
                .HasComment("Actual boolean outcome evaluated by the rule engine (1 for true/conforming, 0 for false/non-conforming).")
                .HasColumnName("result");
            entity.Property(e => e.TestId)
                .HasComment("Foreign key referencing public.tests(id). The parameter whose condition is being verified.")
                .HasColumnName("test_id");
            entity.Property(e => e.Value)
                .HasComment("Test input value passed into the condition expression.")
                .HasColumnName("value");

            entity.HasOne(d => d.Form).WithMany(p => p.FormConditionEvals)
                .HasForeignKey(d => d.FormId)
                .HasConstraintName("form_condition_evals_form_id_fkey");

            entity.HasOne(d => d.Test).WithMany(p => p.FormConditionEvals)
                .HasForeignKey(d => d.TestId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("form_condition_evals_test_id_fkey");

            entity.HasOne(d => d.FormParam).WithMany(p => p.FormConditionEvals)
                .HasForeignKey(d => new { d.FormId, d.TestId })
                .HasConstraintName("form_condition_evals_form_id_test_id_fkey");
        });

        modelBuilder.Entity<FormEval>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("form_evals_pkey");

            entity.ToTable("form_evals", tb => tb.HasComment("Validation benchmark test cases designed to prove the algorithmic accuracy of form formulas under 21 CFR Part 11 software verification rules. Before a form template can be validated (is_validated = true), all defined test cases must evaluate successfully without errors."));

            entity.Property(e => e.Id)
                .HasComment("Primary key. Unique 64-bit integer identifier for the validation test case.")
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.Description)
                .HasComment("Descriptive title or test scenario name (e.g., 'Nominal standard weight test case', 'Boundary condition - maximum LOD').")
                .HasColumnName("description");
            entity.Property(e => e.FormId)
                .HasComment("Foreign key referencing public.forms(id). The form template being verified.")
                .HasColumnName("form_id");

            entity.HasOne(d => d.Form).WithMany(p => p.FormEvals)
                .HasForeignKey(d => d.FormId)
                .HasConstraintName("form_evals_form_id_fkey");
        });

        modelBuilder.Entity<FormEvalParam>(entity =>
        {
            entity.HasKey(e => new { e.EvalId, e.FormId, e.TestId, e.Idx }).HasName("form_eval_params_pkey");

            entity.ToTable("form_eval_params", tb => tb.HasComment("Input variables and expected calculated outputs for form validation test cases (form_evals). During form verification, the QCFormula engine calculates the actual results for all formulas and compares them against expected_value. If all match, is_match is stamped true."));

            entity.Property(e => e.EvalId)
                .HasComment("Primary key and foreign key referencing public.form_evals(id). The parent validation test case.")
                .HasColumnName("eval_id");
            entity.Property(e => e.FormId)
                .HasComment("Foreign key referencing public.forms(id). The form template.")
                .HasColumnName("form_id");
            entity.Property(e => e.TestId)
                .HasComment("Foreign key referencing public.tests(id). The parameter under test.")
                .HasColumnName("test_id");
            entity.Property(e => e.Idx)
                .HasComment("Primary key. Array determination index (0 for scalar parameters, 0..N for replicated array values).")
                .HasColumnName("idx");
            entity.Property(e => e.ExpectedValue)
                .HasComment("Authoritative pre-calculated benchmark value. Used to verify formula accuracy.")
                .HasColumnName("expected_value");
            entity.Property(e => e.IsMatch)
                .HasComment("Boolean verification flag. True indicates the calculated formula result matches expected_value within tolerance.")
                .HasColumnName("is_match");
            entity.Property(e => e.Value)
                .HasComment("Input test value (for manual parameters) or engine-calculated result (for formula parameters).")
                .HasColumnName("value");

            entity.HasOne(d => d.Eval).WithMany(p => p.FormEvalParams)
                .HasForeignKey(d => d.EvalId)
                .HasConstraintName("form_eval_params_eval_id_fkey");

            entity.HasOne(d => d.Form).WithMany(p => p.FormEvalParams)
                .HasForeignKey(d => d.FormId)
                .HasConstraintName("form_eval_params_form_id_fkey");

            entity.HasOne(d => d.Test).WithMany(p => p.FormEvalParams)
                .HasForeignKey(d => d.TestId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("form_eval_params_test_id_fkey");

            entity.HasOne(d => d.FormParam).WithMany(p => p.FormEvalParams)
                .HasForeignKey(d => new { d.FormId, d.TestId })
                .HasConstraintName("form_eval_params_form_id_test_id_fkey");
        });

        modelBuilder.Entity<FormGroup>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("form_groups_pkey");

            entity.ToTable("form_groups", tb => tb.HasComment("Logical family or category of dynamic analytical worksheet forms (e.g., 'Dissolution Testing Forms', 'Heavy Metals Assay Forms', 'Loss on Drying Forms'). Controls overarching validation status across form versions."));

            entity.Property(e => e.Id)
                .HasComment("Primary key. Unique 64-bit integer identifier for the form group.")
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.Description)
                .HasComment("Optional extended description of the testing domain and analytical methodologies handled by this form group.")
                .HasColumnName("description");
            entity.Property(e => e.IsFormValidated)
                .HasComment("Boolean status flag. Automatically updated to true when any form version within this group achieves validation approval (FormsService.ValidateForm). Signals that test definitions associated with this group are locked from structurally breaking changes.")
                .HasColumnName("is_form_validated");
            entity.Property(e => e.Name)
                .HasMaxLength(50)
                .HasComment("Unique name of the form family (3 to 50 characters). Validated for uniqueness via FormGroupDialog.tsx.")
                .HasColumnName("name");
            entity.Property(e => e.NrOrd)
                .HasComment("Numeric display order index (defaults to 0) controlling grouping sequence in client menus.")
                .HasColumnName("nr_ord");
        });

        modelBuilder.Entity<FormParam>(entity =>
        {
            entity.HasKey(e => new { e.FormId, e.TestId }).HasName("form_params_pkey");

            entity.ToTable("form_params", tb => tb.HasComment("Parameter definitions within a form template. Maps analytical tests (tests) into form fields as raw inputs or calculated formulas. Defines mathematical expressions evaluated by QCFormula, topological evaluation order (nr_ord_calc), array relationships, and conditional pass/fail criteria."));

            entity.Property(e => e.FormId)
                .HasComment("Primary key and foreign key referencing public.forms(id). The parent form template.")
                .HasColumnName("form_id");
            entity.Property(e => e.TestId)
                .HasComment("Primary key and foreign key referencing public.tests(id). The analytical test or parameter mapped to this form field.")
                .HasColumnName("test_id");
            entity.Property(e => e.CodeRelatedArrays)
                .HasMaxLength(50)
                .HasComment("Test code string (maximum 50 characters) identifying an associated array test if this calculation parameter aggregates or relates to array determinations.")
                .HasColumnName("code_related_arrays");
            entity.Property(e => e.Condition)
                .HasMaxLength(255)
                .HasComment("Boolean condition expression (maximum 255 characters, e.g., '[value] >= 95.0 && [value] <= 105.0'). Validated via FormsService.ValidateCondition.")
                .HasColumnName("condition");
            entity.Property(e => e.ConditionNote)
                .HasMaxLength(150)
                .HasComment("Human-readable specification note or warning text displayed if the condition is not met (maximum 150 characters, e.g., 'Between 95.0% and 105.0%').")
                .HasColumnName("condition_note");
            entity.Property(e => e.DefaultValue)
                .HasComment("Default preset numeric value (e.g., 1.000 for standard volume, or 0).")
                .HasColumnName("default_value");
            entity.Property(e => e.Formula)
                .HasComment("Mathematical expression evaluated by the QCFormula ANTLR engine (e.g., 'ROUND(([tare_plus_sample] - [tare_dry]) / [sample_mass] * 100, 4)'). References scalar parameters as [code] and array parameters as [[code]]. Mandatory if is_calculated is true.")
                .HasColumnName("formula");
            entity.Property(e => e.FormulaDependencies)
                .HasComment("Extracted list of test variable codes upon which this formula depends. Populated automatically by the QCFormula dependency resolver.")
                .HasColumnName("formula_dependencies");
            entity.Property(e => e.HasCondition)
                .HasComment("Boolean flag indicating that this parameter possesses an acceptance rule / condition. In FormParamDialog.tsx, when true, condition and condition_note are mandatory, and at least one condition evaluation verification test case is required.")
                .HasColumnName("has_condition");
            entity.Property(e => e.IsCalculated)
                .HasComment("Boolean flag indicating whether this parameter is derived via a mathematical formula (true) or entered as a manual raw measurement (false).")
                .HasColumnName("is_calculated");
            entity.Property(e => e.IsRequired)
                .HasComment("Boolean flag specifying whether a value for this parameter is strictly required before the worksheet can be completed.")
                .HasColumnName("is_required");
            entity.Property(e => e.NrOrd)
                .HasComment("Visual display sequence order controlling the arrangement of parameter input rows in the user interface.")
                .HasColumnName("nr_ord");
            entity.Property(e => e.NrOrdCalc)
                .HasComment("Topological calculation sequence order. Derived automatically by resolving the Directed Acyclic Graph (DAG) of formula dependencies. Formulas are evaluated strictly in ascending order of nr_ord_calc to guarantee all dependent inputs are calculated prior to consumption.")
                .HasColumnName("nr_ord_calc");

            entity.HasOne(d => d.Form).WithMany(p => p.FormParams)
                .HasForeignKey(d => d.FormId)
                .HasConstraintName("form_params_form_id_fkey");

            entity.HasOne(d => d.Test).WithMany(p => p.FormParams)
                .HasForeignKey(d => d.TestId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("form_params_test_id_fkey");
        });

        modelBuilder.Entity<Material>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("materials_pkey");

            entity.ToTable("materials", tb => tb.HasComment("Master item catalog covering manufactured finished products, raw materials, intermediates, chemical reagents, and certified reference materials (CRMs). Dictates whether an item undergoes standard QC release testing, is tracked as a reagent in lab inventory, or requires strict metrological traceability."));

            entity.HasIndex(e => e.Code, "materials_code_key").IsUnique();

            entity.HasIndex(e => e.Name, "materials_name_key").IsUnique();

            entity.Property(e => e.Id)
                .HasComment("Primary key. Unique 64-bit integer identifier for the material.")
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.CasNumber)
                .HasMaxLength(20)
                .HasComment("Chemical Abstracts Service (CAS) registry number (maximum 20 characters, e.g., '50-78-2' for Acetylsalicylic acid). Used primarily for chemical identification and reagent safety.")
                .HasColumnName("cas_number");
            entity.Property(e => e.Code)
                .HasMaxLength(10)
                .HasComment("Unique uppercase alphanumeric material code (2 to 10 characters, regex /^[A-Z][A-Z0-9]*$/). Used for inventory identification and batch code generation.")
                .HasColumnName("code");
            entity.Property(e => e.CommentsObsolete)
                .HasComment("Mandatory documented justification explaining why the material was marked obsolete. Cleared to NULL if reactivated.")
                .HasColumnName("comments_obsolete");
            entity.Property(e => e.DateCreated)
                .HasComment("Timestamp with time zone when the material was registered in the database.")
                .HasColumnName("date_created");
            entity.Property(e => e.DateObsolete)
                .HasComment("Timestamp with time zone when the material was retired. Cleared to NULL if reactivated.")
                .HasColumnName("date_obsolete");
            entity.Property(e => e.Description)
                .HasComment("Optional text notes detailing chemical grade, storage conditions, or physical specifications.")
                .HasColumnName("description");
            entity.Property(e => e.IsCertifiedReference)
                .HasComment("Boolean flag indicating that this material is a Certified Reference Material (CRM) requiring strict metrological traceability and certificate of analysis validation under ISO 17034 / ISO/IEC 17025.")
                .HasColumnName("is_certified_reference");
            entity.Property(e => e.IsObsolete)
                .HasComment("Soft-deletion flag. Set via MaterialsService.ToggleObsolete. When true, prevents initiating new sample receptions or specifications. Setting to true stamps date_obsolete with UTC timestamp and stores comments_obsolete; reactivating clears both fields to NULL.")
                .HasColumnName("is_obsolete");
            entity.Property(e => e.IsProduct)
                .HasComment("Boolean flag designating the item as a manufactured finished product eligible for production release and customer Certificate of Analysis generation.")
                .HasColumnName("is_product");
            entity.Property(e => e.IsRawMaterial)
                .HasComment("Boolean flag designating the item as an incoming raw material, active substance, or excipient requiring intake QC verification.")
                .HasColumnName("is_raw_material");
            entity.Property(e => e.IsReagent)
                .HasComment("Boolean flag designating the item as a laboratory chemical reagent or volumetric solution. Reagents are filtered out in general views unless the user possesses lab or QC roles (is_lab_pers or is_qc_pers). Managed via ReagentsPage.tsx and reagent_lots.")
                .HasColumnName("is_reagent");
            entity.Property(e => e.Name)
                .HasMaxLength(50)
                .HasComment("Unique descriptive name of the material (3 to 50 characters, e.g., 'Aspirin Active Substance', 'Ethanol 96%', 'Potassium Dichromate CRM'). Validated for uniqueness on the server and client.")
                .HasColumnName("name");
            entity.Property(e => e.NormId)
                .HasComment("Foreign key referencing public.norms(id) (nullable). Identifies the primary pharmacopeial monograph or compendial standard governing this material.")
                .HasColumnName("norm_id");

            entity.HasOne(d => d.Norm).WithMany(p => p.Materials)
                .HasForeignKey(d => d.NormId)
                .HasConstraintName("materials_norm_id_fkey");

            entity.HasMany(d => d.Tests).WithMany(p => p.Materials)
                .UsingEntity<Dictionary<string, object>>(
                    "MaterialTest",
                    r => r.HasOne<Test>().WithMany()
                        .HasForeignKey("TestId")
                        .OnDelete(DeleteBehavior.ClientSetNull)
                        .HasConstraintName("material_tests_test_id_fkey"),
                    l => l.HasOne<Material>().WithMany()
                        .HasForeignKey("MaterialId")
                        .HasConstraintName("material_tests_material_id_fkey"),
                    j =>
                    {
                        j.HasKey("MaterialId", "TestId").HasName("material_tests_pkey");
                        j.ToTable("material_tests", tb => tb.HasComment("Many-to-many junction table associating candidate analytical tests with a material. Represents the universe of tests that can be configured on specifications or performed on samples of this material. Restricted to non-parameter tests (is_param = false)."));
                        j.IndexerProperty<long>("MaterialId")
                            .HasComment("Primary key and foreign key referencing public.materials(id). The material to which the test is assigned.")
                            .HasColumnName("material_id");
                        j.IndexerProperty<long>("TestId")
                            .HasComment("Primary key and foreign key referencing public.tests(id). The analytical test eligible to be performed on the material.")
                            .HasColumnName("test_id");
                    });
        });

        modelBuilder.Entity<Measurement>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("measurements_pkey");

            entity.ToTable("measurements", tb => tb.HasComment("Laboratory testing worksheet execution sessions. Records raw observations, formula evaluations, and test results for a sample reception. Captures exact instrument serial numbers, chemical reagent lots, and SOP revisions used during execution. Enforces automatic read-only locking upon report inclusion or expiration of form editing days."));

            entity.Property(e => e.Id)
                .HasComment("Primary key. Unique 64-bit integer identifier for the measurement worksheet session.")
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.Comments)
                .HasComment("Analyst bench notes, environmental conditions, or procedural observations recorded during worksheet execution.")
                .HasColumnName("comments");
            entity.Property(e => e.DateCreated)
                .HasDefaultValueSql("clock_timestamp()")
                .HasComment("Timestamp with time zone when the worksheet session was created. Defaults to clock_timestamp().")
                .HasColumnName("date_created");
            entity.Property(e => e.DateReadonly)
                .HasComment("Timestamp with time zone when the worksheet was transitioned to read-only status.")
                .HasColumnName("date_readonly");
            entity.Property(e => e.DateReported)
                .HasComment("Timestamp with time zone when the results were reported.")
                .HasColumnName("date_reported");
            entity.Property(e => e.DateUpdated)
                .HasComment("Timestamp with time zone of the most recent worksheet modification.")
                .HasColumnName("date_updated");
            entity.Property(e => e.FormId)
                .HasComment("Foreign key referencing public.forms(id) (nullable). The structured dynamic form template used for executing calculations, if applicable.")
                .HasColumnName("form_id");
            entity.Property(e => e.IsReadonly)
                .HasComment("Boolean lock flag (defaults to false). Automatically set to true when results are reported or after forms.days_active_for_editing has elapsed. Locks all child measurement_tests and measurement_params from modification.")
                .HasColumnName("is_readonly");
            entity.Property(e => e.IsReported)
                .HasComment("Boolean status flag. True indicates that the test results from this worksheet have been included into a formal submitted test report (reports). Prevents subsequent tampering with raw data.")
                .HasColumnName("is_reported");
            entity.Property(e => e.ReceptionId)
                .HasComment("Foreign key referencing public.receptions(id). The sample reception being analyzed.")
                .HasColumnName("reception_id");
            entity.Property(e => e.UseDefaultEquipment)
                .HasDefaultValue(true)
                .HasComment("Boolean flag (defaults to true). When true, the worksheet utilizes the standard instruments defined in test_equipments; when false, analyst custom-selects specific instrument assets stored in measurement_equipments.")
                .HasColumnName("use_default_equipment");
            entity.Property(e => e.UserCreatedId)
                .HasComment("Foreign key referencing public.users(id). The laboratory analyst who initiated the measurement worksheet.")
                .HasColumnName("user_created_id");
            entity.Property(e => e.UserReportedId)
                .HasComment("Foreign key referencing public.users(id) (nullable). The user who incorporated this measurement session into a test report.")
                .HasColumnName("user_reported_id");
            entity.Property(e => e.UserUpdatedId)
                .HasComment("Foreign key referencing public.users(id) (nullable). The user who performed the most recent edit.")
                .HasColumnName("user_updated_id");

            entity.HasOne(d => d.Form).WithMany(p => p.Measurements)
                .HasForeignKey(d => d.FormId)
                .HasConstraintName("measurements_form_id_fkey");

            entity.HasOne(d => d.Reception).WithMany(p => p.Measurements)
                .HasForeignKey(d => d.ReceptionId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("measurements_reception_id_fkey");

            entity.HasOne(d => d.UserCreated).WithMany(p => p.MeasurementUserCreateds)
                .HasForeignKey(d => d.UserCreatedId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("measurements_user_created_id_fkey");

            entity.HasOne(d => d.UserReported).WithMany(p => p.MeasurementUserReporteds)
                .HasForeignKey(d => d.UserReportedId)
                .HasConstraintName("measurements_user_reported_id_fkey");

            entity.HasOne(d => d.UserUpdated).WithMany(p => p.MeasurementUserUpdateds)
                .HasForeignKey(d => d.UserUpdatedId)
                .HasConstraintName("measurements_user_updated_id_fkey");

            entity.HasMany(d => d.ControlCodes).WithMany(p => p.Measurements)
                .UsingEntity<Dictionary<string, object>>(
                    "MeasurementReagentLot",
                    r => r.HasOne<ReagentLot>().WithMany()
                        .HasForeignKey("ControlCodeId")
                        .OnDelete(DeleteBehavior.ClientSetNull)
                        .HasConstraintName("measurement_reagent_lots_control_code_id_fkey"),
                    l => l.HasOne<Measurement>().WithMany()
                        .HasForeignKey("MeasurementId")
                        .HasConstraintName("measurement_reagent_lots_measurement_id_fkey"),
                    j =>
                    {
                        j.HasKey("MeasurementId", "ControlCodeId").HasName("measurement_reagent_lots_pkey");
                        j.ToTable("measurement_reagent_lots", tb => tb.HasComment("Many-to-many junction table recording the chemical reagent lots and volumetric solutions (control_codes) consumed during a measurement worksheet session. Guarantees chemical consumable traceability."));
                        j.IndexerProperty<long>("MeasurementId")
                            .HasComment("Primary key and foreign key referencing public.measurements(id). The testing worksheet session.")
                            .HasColumnName("measurement_id");
                        j.IndexerProperty<long>("ControlCodeId")
                            .HasComment("Primary key and foreign key referencing public.control_codes(id). The specific reagent lot consumed during testing.")
                            .HasColumnName("control_code_id");
                    });

            entity.HasMany(d => d.Equipment).WithMany(p => p.Measurements)
                .UsingEntity<Dictionary<string, object>>(
                    "MeasurementEquipment",
                    r => r.HasOne<Equipment>().WithMany()
                        .HasForeignKey("EquipmentId")
                        .OnDelete(DeleteBehavior.ClientSetNull)
                        .HasConstraintName("measurement_equipments_equipment_id_fkey"),
                    l => l.HasOne<Measurement>().WithMany()
                        .HasForeignKey("MeasurementId")
                        .HasConstraintName("measurement_equipments_measurement_id_fkey"),
                    j =>
                    {
                        j.HasKey("MeasurementId", "EquipmentId").HasName("measurement_equipments_pkey");
                        j.ToTable("measurement_equipments", tb => tb.HasComment("Many-to-many junction table logging the specific laboratory instruments and balances (equipments) utilized during a measurement worksheet session. Guarantees complete hardware traceability for ISO/IEC 17025 audits."));
                        j.IndexerProperty<long>("MeasurementId")
                            .HasComment("Primary key and foreign key referencing public.measurements(id). The testing worksheet session.")
                            .HasColumnName("measurement_id");
                        j.IndexerProperty<long>("EquipmentId")
                            .HasComment("Primary key and foreign key referencing public.equipments(id). The instrument utilized during the test.")
                            .HasColumnName("equipment_id");
                    });

            entity.HasMany(d => d.SopVersions).WithMany(p => p.Measurements)
                .UsingEntity<Dictionary<string, object>>(
                    "MeasurementSopVersion",
                    r => r.HasOne<SopVersion>().WithMany()
                        .HasForeignKey("SopVersionId")
                        .OnDelete(DeleteBehavior.ClientSetNull)
                        .HasConstraintName("measurement_sop_versions_sop_version_id_fkey"),
                    l => l.HasOne<Measurement>().WithMany()
                        .HasForeignKey("MeasurementId")
                        .HasConstraintName("measurement_sop_versions_measurement_id_fkey"),
                    j =>
                    {
                        j.HasKey("MeasurementId", "SopVersionId").HasName("measurement_sop_versions_pkey");
                        j.ToTable("measurement_sop_versions", tb => tb.HasComment("Many-to-many junction table capturing the exact revisions of Standard Operating Procedures (sop_versions) followed by the analyst during execution of a measurement worksheet. Ensures procedural compliance traceability."));
                        j.IndexerProperty<long>("MeasurementId")
                            .HasComment("Primary key and foreign key referencing public.measurements(id). The testing worksheet session.")
                            .HasColumnName("measurement_id");
                        j.IndexerProperty<long>("SopVersionId")
                            .HasComment("Primary key and foreign key referencing public.sop_versions(id). The active SOP revision utilized for the test execution.")
                            .HasColumnName("sop_version_id");
                    });
        });

        modelBuilder.Entity<MeasurementParam>(entity =>
        {
            entity.HasKey(e => new { e.MeasurementId, e.FormId, e.TestId, e.Idx }).HasName("measurement_params_pkey");

            entity.ToTable("measurement_params", tb => tb.HasComment("Intermediate calculation variables and raw parameter inputs captured during dynamic form worksheet execution. Maintains parameter-level acceptance status (is_conforming_condition) and metrological links to Certified Reference Materials (CRMs)."));

            entity.Property(e => e.MeasurementId)
                .HasComment("Primary key and foreign key referencing public.measurements(id). The parent worksheet session.")
                .HasColumnName("measurement_id");
            entity.Property(e => e.FormId)
                .HasComment("Primary key and foreign key referencing public.forms(id). The active form template.")
                .HasColumnName("form_id");
            entity.Property(e => e.TestId)
                .HasComment("Primary key and foreign key referencing public.tests(id). The specific parameter test definition.")
                .HasColumnName("test_id");
            entity.Property(e => e.Idx)
                .HasComment("Primary key. Array determination index (0 for scalar parameters, 0..N for array inputs).")
                .HasColumnName("idx");
            entity.Property(e => e.CertifiedReferenceCertificateId)
                .HasComment("Foreign key referencing public.certificates(id) (nullable). Populated when this parameter value is calibrated against or sourced from an internal Quality Certificate for a certified reference batch via SelectCrmDialog.tsx.")
                .HasColumnName("certified_reference_certificate_id");
            entity.Property(e => e.CertifiedReferenceControlCodeId)
                .HasComment("Foreign key referencing public.control_codes(id) (nullable). Populated when this parameter value is sourced from a supplier CRM reagent lot Certificate of Analysis (reagent_supplier_lot_cert_tests) via SelectCrmDialog.tsx.")
                .HasColumnName("certified_reference_control_code_id");
            entity.Property(e => e.DateCreated)
                .HasDefaultValueSql("clock_timestamp()")
                .HasComment("Timestamp with time zone when the parameter was created. Defaults to clock_timestamp().")
                .HasColumnName("date_created");
            entity.Property(e => e.DateUpdated)
                .HasComment("Timestamp with time zone of the most recent parameter edit.")
                .HasColumnName("date_updated");
            entity.Property(e => e.IsConformingCondition)
                .HasComment("Boolean status flag. True indicates the parameter satisfies the conditional acceptance rule defined in form_params.condition.")
                .HasColumnName("is_conforming_condition");
            entity.Property(e => e.UserCreatedId)
                .HasComment("Foreign key referencing public.users(id). The user who originally recorded the parameter.")
                .HasColumnName("user_created_id");
            entity.Property(e => e.UserUpdatedId)
                .HasComment("Foreign key referencing public.users(id) (nullable). The user who last edited this parameter value.")
                .HasColumnName("user_updated_id");
            entity.Property(e => e.Value)
                .HasComment("Input raw measurement value or formula-calculated intermediate result.")
                .HasColumnName("value");

            entity.HasOne(d => d.CertifiedReferenceCertificate).WithMany(p => p.MeasurementParams)
                .HasForeignKey(d => d.CertifiedReferenceCertificateId)
                .HasConstraintName("measurement_params_certified_reference_certificate_id_fkey");

            entity.HasOne(d => d.CertifiedReferenceControlCode).WithMany(p => p.MeasurementParams)
                .HasForeignKey(d => d.CertifiedReferenceControlCodeId)
                .HasConstraintName("measurement_params_certified_reference_control_code_id_fkey");

            entity.HasOne(d => d.Form).WithMany(p => p.MeasurementParams)
                .HasForeignKey(d => d.FormId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("measurement_params_form_id_fkey");

            entity.HasOne(d => d.Measurement).WithMany(p => p.MeasurementParams)
                .HasForeignKey(d => d.MeasurementId)
                .HasConstraintName("measurement_params_measurement_id_fkey");

            entity.HasOne(d => d.Test).WithMany(p => p.MeasurementParams)
                .HasForeignKey(d => d.TestId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("measurement_params_test_id_fkey");

            entity.HasOne(d => d.UserCreated).WithMany(p => p.MeasurementParamUserCreateds)
                .HasForeignKey(d => d.UserCreatedId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("measurement_params_user_created_id_fkey");

            entity.HasOne(d => d.UserUpdated).WithMany(p => p.MeasurementParamUserUpdateds)
                .HasForeignKey(d => d.UserUpdatedId)
                .HasConstraintName("measurement_params_user_updated_id_fkey");

            entity.HasOne(d => d.FormParam).WithMany(p => p.MeasurementParams)
                .HasForeignKey(d => new { d.FormId, d.TestId })
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("measurement_params_form_id_test_id_fkey");
        });

        modelBuilder.Entity<MeasurementTest>(entity =>
        {
            entity.HasKey(e => new { e.MeasurementId, e.TestId, e.Idx }).HasName("measurement_tests_pkey");

            entity.ToTable("measurement_tests", tb => tb.HasComment("Final measured test results recorded during a worksheet session. Supports both scalar results (idx = 0) and multi-replicate array results (idx = 0..N). Serves as the raw data source for testing reports (report_tests) and quality certificates (certificate_tests)."));

            entity.Property(e => e.MeasurementId)
                .HasComment("Primary key and foreign key referencing public.measurements(id). The parent worksheet execution session.")
                .HasColumnName("measurement_id");
            entity.Property(e => e.TestId)
                .HasComment("Primary key and foreign key referencing public.tests(id). The analytical test whose result was determined.")
                .HasColumnName("test_id");
            entity.Property(e => e.Idx)
                .HasComment("Primary key. Numeric replicate index (0 for scalar tests, 0..N for replicated array determinations).")
                .HasColumnName("idx");
            entity.Property(e => e.DateCreated)
                .HasDefaultValueSql("clock_timestamp()")
                .HasComment("Timestamp with time zone when the measurement was originally logged. Defaults to clock_timestamp().")
                .HasColumnName("date_created");
            entity.Property(e => e.DateUpdated)
                .HasComment("Timestamp with time zone when this test value was last updated.")
                .HasColumnName("date_updated");
            entity.Property(e => e.Note)
                .HasMaxLength(20)
                .HasComment("Short analyst footnote or qualitative observation (maximum 20 characters, e.g., 'Re-injected', 'Outlier rejected').")
                .HasColumnName("note");
            entity.Property(e => e.UserCreatedId)
                .HasComment("Foreign key referencing public.users(id). The analyst who recorded the initial measurement.")
                .HasColumnName("user_created_id");
            entity.Property(e => e.UserUpdatedId)
                .HasComment("Foreign key referencing public.users(id) (nullable). The user who last updated this test value.")
                .HasColumnName("user_updated_id");
            entity.Property(e => e.Value)
                .HasComment("The measured numerical result (or encoded enum key from test_enums). Captured via MeasurementTestDialog.tsx or auto-calculated from form parameters.")
                .HasColumnName("value");

            entity.HasOne(d => d.Measurement).WithMany(p => p.MeasurementTests)
                .HasForeignKey(d => d.MeasurementId)
                .HasConstraintName("measurement_tests_measurement_id_fkey");

            entity.HasOne(d => d.Test).WithMany(p => p.MeasurementTests)
                .HasForeignKey(d => d.TestId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("measurement_tests_test_id_fkey");

            entity.HasOne(d => d.UserCreated).WithMany(p => p.MeasurementTestUserCreateds)
                .HasForeignKey(d => d.UserCreatedId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("measurement_tests_user_created_id_fkey");

            entity.HasOne(d => d.UserUpdated).WithMany(p => p.MeasurementTestUserUpdateds)
                .HasForeignKey(d => d.UserUpdatedId)
                .HasConstraintName("measurement_tests_user_updated_id_fkey");
        });

        modelBuilder.Entity<Norm>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("norms_pkey");

            entity.ToTable("norms", tb => tb.HasComment("Compendial standards, pharmacopeias, or regulatory references (e.g., 'USP 43', 'Ph. Eur. 10', 'ISO/IEC 17025', 'ASTM D1298', 'Internal QC Standard'). Provides governing normative authority for test methods, specifications, and standard operating procedures (SOPs)."));

            entity.HasIndex(e => e.Name, "norms_name_key").IsUnique();

            entity.Property(e => e.Id)
                .HasComment("Primary key. Unique 64-bit integer identifier for the norm record.")
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.CommentsObsolete)
                .HasComment("Documented justification explaining why the norm is no longer valid or applicable. Cleared to NULL if reactivated.")
                .HasColumnName("comments_obsolete");
            entity.Property(e => e.DateCreated)
                .HasComment("Timestamp with time zone when the norm was registered.")
                .HasColumnName("date_created");
            entity.Property(e => e.DateObsolete)
                .HasComment("Timestamp with time zone when the norm was marked obsolete. Cleared to NULL if reactivated.")
                .HasColumnName("date_obsolete");
            entity.Property(e => e.Description)
                .HasComment("Detailed description of the standard, governing body, publication edition, or scope.")
                .HasColumnName("description");
            entity.Property(e => e.IsObsolete)
                .HasComment("Soft-deletion flag. When true, prevents associating this norm with new materials, tests, or SOPs.")
                .HasColumnName("is_obsolete");
            entity.Property(e => e.Name)
                .HasMaxLength(50)
                .HasComment("Unique title or designation of the governing standard (3 to 50 characters). Validated for uniqueness in NormDialog.tsx.")
                .HasColumnName("name");
        });

        modelBuilder.Entity<ReagentLot>(entity =>
        {
            entity.HasKey(e => e.ControlCodeId).HasName("reagent_lots_pkey");

            entity.ToTable("reagent_lots", tb => tb.HasComment("Core inventory table tracking physical containers and batches of chemical reagents, volumetric solutions, and standards in the laboratory. Each lot is identified by a control_code_id. Differentiates purchased vendor lots from in-house prepared solutions (is_produced). Enforces expiration date controls and stock balances."));

            entity.Property(e => e.ControlCodeId)
                .ValueGeneratedNever()
                .HasComment("Primary key and foreign key referencing public.control_codes(id). Serves as the unique tracking lot identifier for this physical batch.")
                .HasColumnName("control_code_id");
            entity.Property(e => e.ExpirationDate)
                .HasComment("Calendar date when the reagent lot expires. The system blocks using expired lots in analytical testing.")
                .HasColumnName("expiration_date");
            entity.Property(e => e.IsProduced)
                .HasComment("Boolean flag distinguishing in-house prepared reagents (true) from commercially purchased supplier lots (false). When true, produced_by_user_id and ingredient relationships in reagent_production_lots are enabled.")
                .HasColumnName("is_produced");
            entity.Property(e => e.ProducedByUserId)
                .HasComment("Foreign key referencing public.users(id) (nullable). The laboratory analyst who formulated or prepared the reagent solution. Populated only when is_produced is true.")
                .HasColumnName("produced_by_user_id");
            entity.Property(e => e.Quantity)
                .HasComment("Numeric stock quantity remaining in inventory (e.g., 500.0). Enforced to be non-negative on the client and server.")
                .HasColumnName("quantity");
            entity.Property(e => e.StatusId)
                .HasDefaultValue(1L)
                .HasComment("Foreign key referencing public.reagent_lot_statuses(id) (defaults to 1 = 'Quarantined'). Only lots in status 2 ('Active') can be selected as worksheet consumables or production ingredients.")
                .HasColumnName("status_id");
            entity.Property(e => e.UnitId)
                .HasComment("Foreign key referencing public.units(id) (nullable). Specifies the unit of measurement for stock inventory (e.g., 'mL', 'g', 'L').")
                .HasColumnName("unit_id");

            entity.HasOne(d => d.ControlCode).WithOne(p => p.ReagentLot)
                .HasForeignKey<ReagentLot>(d => d.ControlCodeId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("reagent_lots_control_code_id_fkey");

            entity.HasOne(d => d.ProducedByUser).WithMany(p => p.ReagentLots)
                .HasForeignKey(d => d.ProducedByUserId)
                .HasConstraintName("reagent_lots_produced_by_user_id_fkey");

            entity.HasOne(d => d.Status).WithMany(p => p.ReagentLots)
                .HasForeignKey(d => d.StatusId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("reagent_lots_status_id_fkey");

            entity.HasOne(d => d.Unit).WithMany(p => p.ReagentLots)
                .HasForeignKey(d => d.UnitId)
                .HasConstraintName("reagent_lots_unit_id_fkey");

            entity.HasMany(d => d.ControlCodes).WithMany(p => p.IngredientControlCodes)
                .UsingEntity<Dictionary<string, object>>(
                    "ReagentProductionLot",
                    r => r.HasOne<ReagentLot>().WithMany()
                        .HasForeignKey("ControlCodeId")
                        .OnDelete(DeleteBehavior.ClientSetNull)
                        .HasConstraintName("reagent_production_lots_control_code_id_fkey"),
                    l => l.HasOne<ReagentLot>().WithMany()
                        .HasForeignKey("IngredientControlCodeId")
                        .OnDelete(DeleteBehavior.ClientSetNull)
                        .HasConstraintName("reagent_production_lots_ingredient_control_code_id_fkey"),
                    j =>
                    {
                        j.HasKey("ControlCodeId", "IngredientControlCodeId").HasName("reagent_production_lots_pkey");
                        j.ToTable("reagent_production_lots", tb => tb.HasComment("Genealogy / Bill of Materials (BOM) junction table tracking internal laboratory reagent preparation. Associates an in-house produced reagent lot with the parent ingredient reagent lots consumed in its preparation. In ProductionLotDialog.tsx, circular dependencies (selecting the lot itself as an ingredient) are strictly prevented, and only active lots (status_id = 2) are eligible for selection."));
                        j.IndexerProperty<long>("ControlCodeId")
                            .HasComment("Primary key and foreign key referencing public.control_codes(id). Identifies the newly prepared/produced child reagent lot.")
                            .HasColumnName("control_code_id");
                        j.IndexerProperty<long>("IngredientControlCodeId")
                            .HasComment("Primary key and foreign key referencing public.control_codes(id). Identifies an active parent reagent lot consumed as an ingredient.")
                            .HasColumnName("ingredient_control_code_id");
                    });

            entity.HasMany(d => d.IngredientControlCodes).WithMany(p => p.ControlCodes)
                .UsingEntity<Dictionary<string, object>>(
                    "ReagentProductionLot",
                    r => r.HasOne<ReagentLot>().WithMany()
                        .HasForeignKey("IngredientControlCodeId")
                        .OnDelete(DeleteBehavior.ClientSetNull)
                        .HasConstraintName("reagent_production_lots_ingredient_control_code_id_fkey"),
                    l => l.HasOne<ReagentLot>().WithMany()
                        .HasForeignKey("ControlCodeId")
                        .OnDelete(DeleteBehavior.ClientSetNull)
                        .HasConstraintName("reagent_production_lots_control_code_id_fkey"),
                    j =>
                    {
                        j.HasKey("ControlCodeId", "IngredientControlCodeId").HasName("reagent_production_lots_pkey");
                        j.ToTable("reagent_production_lots", tb => tb.HasComment("Genealogy / Bill of Materials (BOM) junction table tracking internal laboratory reagent preparation. Associates an in-house produced reagent lot with the parent ingredient reagent lots consumed in its preparation. In ProductionLotDialog.tsx, circular dependencies (selecting the lot itself as an ingredient) are strictly prevented, and only active lots (status_id = 2) are eligible for selection."));
                        j.IndexerProperty<long>("ControlCodeId")
                            .HasComment("Primary key and foreign key referencing public.control_codes(id). Identifies the newly prepared/produced child reagent lot.")
                            .HasColumnName("control_code_id");
                        j.IndexerProperty<long>("IngredientControlCodeId")
                            .HasComment("Primary key and foreign key referencing public.control_codes(id). Identifies an active parent reagent lot consumed as an ingredient.")
                            .HasColumnName("ingredient_control_code_id");
                    });
        });

        modelBuilder.Entity<ReagentLotStatus>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("reagent_lot_statuses_pkey");

            entity.ToTable("reagent_lot_statuses", tb => tb.HasComment("Lifecycle status lookup table for physical laboratory reagent lots: 1 = 'Quarantined' (pending incoming inspection or CoA verification), 2 = 'Active' (approved for use in testing and production), 3 = 'Expired' (past manufacturer expiration date, locked from usage), 4 = 'Depleted' (inventory exhausted). Only lots in 'Active' status can be consumed in measurement worksheets or used as ingredients in lab preparations."));

            entity.HasIndex(e => e.Name, "reagent_lot_statuses_name_key").IsUnique();

            entity.Property(e => e.Id)
                .ValueGeneratedNever()
                .HasComment("Primary key. Numeric identifier corresponding to the reagent lot status.")
                .HasColumnName("id");
            entity.Property(e => e.Name)
                .HasMaxLength(50)
                .HasComment("Unique name of the lot status ('Quarantined', 'Active', 'Expired', 'Depleted').")
                .HasColumnName("name");
        });

        modelBuilder.Entity<ReagentSupplier>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("reagent_suppliers_pkey");

            entity.ToTable("reagent_suppliers", tb => tb.HasComment("Catalog of external commercial vendors, manufacturers, and distributors of laboratory reagents, solvents, standards, and chemicals (e.g., 'Merck', 'Sigma-Aldrich', 'Fisher Scientific', 'VWR'). Can be selected from an existing list or created on-the-fly during supplier lot entry in SupplierLotDialog.tsx."));

            entity.HasIndex(e => e.Name, "reagent_suppliers_name_key").IsUnique();

            entity.Property(e => e.Id)
                .HasComment("Primary key. Unique 64-bit integer identifier for the reagent supplier.")
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.Name)
                .HasMaxLength(100)
                .HasComment("Unique name of the supplier company (up to 50 characters). Validated for uniqueness via ReagentsService.ValidateSupplierUniqueness.")
                .HasColumnName("name");
        });

        modelBuilder.Entity<ReagentSupplierLot>(entity =>
        {
            entity.HasKey(e => e.ControlCodeId).HasName("reagent_supplier_lots_pkey");

            entity.ToTable("reagent_supplier_lots", tb => tb.HasComment("Specialization table for commercially purchased reagent lots (reagent_lots where is_produced = false). Maintains manufacturer traceability, vendor catalog numbers, manufacturer batch numbers, and Certificate of Analysis (CoA) references. Locked into read-only mode once utilized in certified worksheets."));

            entity.Property(e => e.ControlCodeId)
                .ValueGeneratedNever()
                .HasComment("Primary key and foreign key referencing public.control_codes(id) (and implicitly public.reagent_lots). Unique lot identifier.")
                .HasColumnName("control_code_id");
            entity.Property(e => e.CatalogNumber)
                .HasMaxLength(50)
                .HasComment("Vendor catalog or product article number (maximum 50 characters, e.g., '1.00014.1000').")
                .HasColumnName("catalog_number");
            entity.Property(e => e.CertificateOfAnalysisRef)
                .HasMaxLength(255)
                .HasComment("Reference identifier, document number, or URL to the manufacturer's Certificate of Analysis (maximum 255 characters).")
                .HasColumnName("certificate_of_analysis_ref");
            entity.Property(e => e.Comments)
                .HasMaxLength(255)
                .HasComment("Optional comments, container condition, or receiving notes (maximum 255 characters).")
                .HasColumnName("comments");
            entity.Property(e => e.DateReadonly)
                .HasComment("Timestamp with time zone when the record was locked against modifications.")
                .HasColumnName("date_readonly");
            entity.Property(e => e.IsReadonly)
                .HasComment("Boolean lock flag (defaults to false). Automatically set to true when the lot is consumed in approved/submitted testing worksheets or quality certificates to guarantee immutable historical records.")
                .HasColumnName("is_readonly");
            entity.Property(e => e.ManufacturerLotNumber)
                .HasMaxLength(50)
                .HasComment("Original manufacturer production lot number printed on the container label (maximum 50 characters).")
                .HasColumnName("manufacturer_lot_number");
            entity.Property(e => e.SupplierId)
                .HasComment("Foreign key referencing public.reagent_suppliers(id). Identifies the vendor or manufacturer who supplied the batch. In SupplierLotDialog.tsx, user can either select an existing supplier or input a new one, which creates a new supplier record.")
                .HasColumnName("supplier_id");

            entity.HasOne(d => d.ControlCode).WithOne(p => p.ReagentSupplierLot)
                .HasForeignKey<ReagentSupplierLot>(d => d.ControlCodeId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("reagent_supplier_lots_control_code_id_fkey");

            entity.HasOne(d => d.Supplier).WithMany(p => p.ReagentSupplierLots)
                .HasForeignKey(d => d.SupplierId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("reagent_supplier_lots_supplier_id_fkey");
        });

        modelBuilder.Entity<ReagentSupplierLotCertTest>(entity =>
        {
            entity.HasKey(e => e.ControlCodeId).HasName("reagent_supplier_lot_cert_tests_pkey");

            entity.ToTable("reagent_supplier_lot_cert_tests", tb => tb.HasComment("Certified reference parameter values transcribed from manufacturer Certificates of Analysis (CoA) for Certified Reference Materials (CRMs). Enables strict metrological traceability under ISO 17034 and ISO/IEC 17025. When executing a worksheet with CRM-dependent parameters (tests.for_certified_reference = true), the analyst selects active values from this table via SelectCrmDialog.tsx."));

            entity.Property(e => e.ControlCodeId)
                .ValueGeneratedNever()
                .HasComment("Primary key and foreign key referencing public.control_codes(id). Identifies the supplier CRM reagent lot.")
                .HasColumnName("control_code_id");
            entity.Property(e => e.CoverageFactorK)
                .HasComment("Coverage factor k stated on the certificate (typically 2.0 for approx. 95% confidence interval).")
                .HasColumnName("coverage_factor_k");
            entity.Property(e => e.TestId)
                .HasComment("Primary key and foreign key referencing public.tests(id). The analytical property or analyte certified on the supplier CoA.")
                .HasColumnName("test_id");
            entity.Property(e => e.TraceabilityStatement)
                .HasComment("Formal metrological traceability text transcribed from the CoA (maximum 500 characters, e.g., 'Traceable to NIST SRM 84k').")
                .HasColumnName("traceability_statement");
            entity.Property(e => e.UncertaintyValue)
                .HasComment("Stated expanded measurement uncertainty U from the manufacturer certificate (e.g., 0.05).")
                .HasColumnName("uncertainty_value");
            entity.Property(e => e.Value)
                .HasComment("Certified reference numerical value stated on the manufacturer CoA (e.g., 99.98% purity, 0.1002 N titer).")
                .HasColumnName("value");

            entity.HasOne(d => d.ControlCode).WithOne(p => p.ReagentSupplierLotCertTest)
                .HasForeignKey<ReagentSupplierLotCertTest>(d => d.ControlCodeId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("reagent_supplier_lot_cert_tests_control_code_id_fkey");

            entity.HasOne(d => d.Test).WithMany(p => p.ReagentSupplierLotCertTests)
                .HasForeignKey(d => d.TestId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("reagent_supplier_lot_cert_tests_test_id_fkey");
        });

        modelBuilder.Entity<Reception>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("receptions_pkey");

            entity.ToTable("receptions", tb => tb.HasComment("Laboratory sample intake, login, and chain-of-custody tracking table. Captures sample submission, laboratory physical receipt, or rejection. Drives subsequent measurement worksheet creation, testing report issuance, and certificate generation."));

            entity.Property(e => e.Id)
                .HasComment("Primary key. Unique 64-bit integer identifier for the sample reception event.")
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.CategoryId)
                .HasComment("Foreign key referencing public.categories(id) (nullable). Classifies the sample under an established category for Category Verification receptions (type_id = 3). NULL for standard Certification and Verification receptions.")
                .HasColumnName("category_id");
            entity.Property(e => e.CommentsReceived)
                .HasComment("Laboratory intake notes regarding sample integrity, packaging, seals, or temperature upon arrival.")
                .HasColumnName("comments_received");
            entity.Property(e => e.CommentsRejected)
                .HasComment("Mandatory documented justification explaining why the sample was rejected by the laboratory.")
                .HasColumnName("comments_rejected");
            entity.Property(e => e.CommentsSubmitted)
                .HasComment("Optional comments, delivery instructions, or sampling conditions noted by the submitter.")
                .HasColumnName("comments_submitted");
            entity.Property(e => e.ControlCodeId)
                .HasComment("Foreign key referencing public.control_codes(id) (nullable). Identifies the physical batch/lot being sampled. Mandatory for Certification and Verification receptions; NULL for Category Verification receptions.")
                .HasColumnName("control_code_id");
            entity.Property(e => e.DateReceived)
                .HasComment("Timestamp with time zone when the laboratory physically received the sample.")
                .HasColumnName("date_received");
            entity.Property(e => e.DateRejected)
                .HasComment("Timestamp with time zone when the sample was rejected.")
                .HasColumnName("date_rejected");
            entity.Property(e => e.DateSubmitted)
                .HasComment("Timestamp with time zone when the sample reception was formally submitted.")
                .HasColumnName("date_submitted");
            entity.Property(e => e.IsReceived)
                .HasComment("Boolean status flag. True indicates the laboratory has physically accepted the sample into custody. Setting this to true automatically marks control_codes.is_reception_received = true (ReceptionsService.ReceiveReception).")
                .HasColumnName("is_received");
            entity.Property(e => e.IsRejected)
                .HasComment("Boolean status flag. True indicates the laboratory rejected the sample intake (e.g. broken seal, insufficient volume, incorrect storage temperature). A rejected reception cannot be received and requires a mandatory reason.")
                .HasColumnName("is_rejected");
            entity.Property(e => e.IsSubmitted)
                .HasComment("Boolean status flag. True indicates the sample reception request has been formally submitted by sampling/production personnel.")
                .HasColumnName("is_submitted");
            entity.Property(e => e.MaterialName)
                .HasMaxLength(50)
                .HasComment("Free-text description of the sampled material (maximum 50 characters). Used exclusively for Category Verification receptions (type_id = 3) where the sample does not correspond to a formally registered catalog item in public.materials.")
                .HasColumnName("material_name");
            entity.Property(e => e.TypeId)
                .HasComment("Foreign key referencing public.reception_types(id). Specifies whether this reception represents Certification (1), Verification (2), or Category Verification (3).")
                .HasColumnName("type_id");
            entity.Property(e => e.UserReceivedId)
                .HasComment("Foreign key referencing public.users(id) (nullable). The laboratory analyst who checked in and accepted the physical sample.")
                .HasColumnName("user_received_id");
            entity.Property(e => e.UserRejectedId)
                .HasComment("Foreign key referencing public.users(id) (nullable). The laboratory user who executed the sample rejection.")
                .HasColumnName("user_rejected_id");
            entity.Property(e => e.UserSubmittedId)
                .HasComment("Foreign key referencing public.users(id) (nullable). The user who submitted the sample reception.")
                .HasColumnName("user_submitted_id");

            entity.HasOne(d => d.Category).WithMany(p => p.Receptions)
                .HasForeignKey(d => d.CategoryId)
                .HasConstraintName("receptions_category_id_fkey");

            entity.HasOne(d => d.ControlCode).WithMany(p => p.Receptions)
                .HasForeignKey(d => d.ControlCodeId)
                .HasConstraintName("receptions_control_code_id_fkey");

            entity.HasOne(d => d.Type).WithMany(p => p.Receptions)
                .HasForeignKey(d => d.TypeId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("receptions_reception_type_id_fkey");

            entity.HasOne(d => d.UserReceived).WithMany(p => p.ReceptionUserReceiveds)
                .HasForeignKey(d => d.UserReceivedId)
                .HasConstraintName("receptions_user_received_id_fkey");

            entity.HasOne(d => d.UserRejected).WithMany(p => p.ReceptionUserRejecteds)
                .HasForeignKey(d => d.UserRejectedId)
                .HasConstraintName("receptions_user_rejected_id_fkey");

            entity.HasOne(d => d.UserSubmitted).WithMany(p => p.ReceptionUserSubmitteds)
                .HasForeignKey(d => d.UserSubmittedId)
                .HasConstraintName("receptions_user_submitted_id_fkey");

            entity.HasMany(d => d.Tests).WithMany(p => p.Receptions)
                .UsingEntity<Dictionary<string, object>>(
                    "ReceptionTest",
                    r => r.HasOne<Test>().WithMany()
                        .HasForeignKey("TestId")
                        .OnDelete(DeleteBehavior.ClientSetNull)
                        .HasConstraintName("reception_tests_test_id_fkey"),
                    l => l.HasOne<Reception>().WithMany()
                        .HasForeignKey("ReceptionId")
                        .OnDelete(DeleteBehavior.ClientSetNull)
                        .HasConstraintName("reception_tests_reception_id_fkey"),
                    j =>
                    {
                        j.HasKey("ReceptionId", "TestId").HasName("reception_tests_pkey");
                        j.ToTable("reception_tests", tb => tb.HasComment("Many-to-many junction table recording the analytical tests assigned to a specific sample reception. For Certification receptions, populated automatically with all active tests from the material's submitted specification; for Verification receptions, populated from user selection in VerificationDialog.tsx; for Category Verification, populated from category_tests in CategoryVerificationDialog.tsx."));
                        j.IndexerProperty<long>("ReceptionId")
                            .HasComment("Primary key and foreign key referencing public.receptions(id). The sample reception receiving the test assignments.")
                            .HasColumnName("reception_id");
                        j.IndexerProperty<long>("TestId")
                            .HasComment("Primary key and foreign key referencing public.tests(id). The analytical test scheduled to be performed on the sample.")
                            .HasColumnName("test_id");
                    });
        });

        modelBuilder.Entity<ReceptionType>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("reception_types_pkey");

            entity.ToTable("reception_types", tb => tb.HasComment("Lookup table defining the standard workflows for sample intake and laboratory login: 1 = 'Certification' (full release testing against active material specification), 2 = 'Verification' (custom test subset on an established material), 3 = 'Category Verification' (ad-hoc testing of unlisted or experimental samples classified by category)."));

            entity.Property(e => e.Id)
                .ValueGeneratedNever()
                .HasComment("Primary key. Numeric identifier of the reception type.")
                .HasColumnName("id");
            entity.Property(e => e.Name)
                .HasMaxLength(50)
                .HasComment("Unique workflow title ('Certification', 'Verification', 'Category Verification'). Determines client dialog layout (CertificationDialog, VerificationDialog, or CategoryVerificationDialog) and backend test population logic.")
                .HasColumnName("name");
        });

        modelBuilder.Entity<Report>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("reports_pkey");

            entity.ToTable("reports", tb => tb.HasComment("Formal analytical Testing Reports compiling completed laboratory measurements for a sample reception. Serves as the laboratory's technical release document before final quality certification. Governed by formal submission, revision/replacement, and cancellation lifecycles with electronic signatures."));

            entity.Property(e => e.Id)
                .HasComment("Primary key. Unique 64-bit integer identifier for the testing report.")
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.CommentsCancelled)
                .HasComment("Mandatory documented justification explaining why the test report was cancelled.")
                .HasColumnName("comments_cancelled");
            entity.Property(e => e.CommentsSubmitted)
                .HasComment("Technical comments, summary of findings, or analytical caveats recorded at report submission.")
                .HasColumnName("comments_submitted");
            entity.Property(e => e.DateCancelled)
                .HasComment("Timestamp with time zone when the report was cancelled.")
                .HasColumnName("date_cancelled");
            entity.Property(e => e.DateSubmitted)
                .HasComment("Timestamp with time zone when the test report was submitted.")
                .HasColumnName("date_submitted");
            entity.Property(e => e.IsCancelled)
                .HasComment("Boolean status flag. True indicates the report was officially invalidated or cancelled.")
                .HasColumnName("is_cancelled");
            entity.Property(e => e.IsSubmitted)
                .HasComment("Boolean status flag. True indicates the test report has been formally signed and submitted by authorized lab personnel. Submitting a report automatically transitions underlying measurements to read-only status.")
                .HasColumnName("is_submitted");
            entity.Property(e => e.ReceptionId)
                .HasComment("Foreign key referencing public.receptions(id). The sample reception for which this test report is generated.")
                .HasColumnName("reception_id");
            entity.Property(e => e.ReportReplacedId)
                .HasComment("Foreign key referencing public.reports(id) (nullable). Points to the earlier report revision that this report replaces / amends.")
                .HasColumnName("report_replaced_id");
            entity.Property(e => e.UserCancelledId)
                .HasComment("Foreign key referencing public.users(id) (nullable). The user who cancelled the test report.")
                .HasColumnName("user_cancelled_id");
            entity.Property(e => e.UserSubmittedId)
                .HasComment("Foreign key referencing public.users(id) (nullable). The laboratory user who submitted the test report.")
                .HasColumnName("user_submitted_id");

            entity.HasOne(d => d.Reception).WithMany(p => p.Reports)
                .HasForeignKey(d => d.ReceptionId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("reports_reception_id_fkey");

            entity.HasOne(d => d.ReportReplaced).WithMany(p => p.InverseReportReplaced)
                .HasForeignKey(d => d.ReportReplacedId)
                .HasConstraintName("reports_report_replaced_id_fkey");

            entity.HasOne(d => d.UserCancelled).WithMany(p => p.ReportUserCancelleds)
                .HasForeignKey(d => d.UserCancelledId)
                .HasConstraintName("reports_user_cancelled_id_fkey");

            entity.HasOne(d => d.UserSubmitted).WithMany(p => p.ReportUserSubmitteds)
                .HasForeignKey(d => d.UserSubmittedId)
                .HasConstraintName("reports_user_submitted_id_fkey");
        });

        modelBuilder.Entity<ReportTest>(entity =>
        {
            entity.HasKey(e => new { e.ReportId, e.MeasurementId, e.TestId, e.Idx }).HasName("report_tests_pkey");

            entity.ToTable("report_tests", tb => tb.HasComment("Analytical test results included in a formal testing report. Encapsulates measured values alongside calculated expanded measurement uncertainties (U) and coverage factors (k) in compliance with ISO/IEC 17025."));

            entity.Property(e => e.ReportId)
                .HasComment("Primary key and foreign key referencing public.reports(id). The parent testing report.")
                .HasColumnName("report_id");
            entity.Property(e => e.MeasurementId)
                .HasComment("Primary key and foreign key referencing public.measurements(id). The source worksheet from which the measurement was obtained.")
                .HasColumnName("measurement_id");
            entity.Property(e => e.TestId)
                .HasComment("Primary key and foreign key referencing public.tests(id). The analytical test evaluated.")
                .HasColumnName("test_id");
            entity.Property(e => e.Idx)
                .HasComment("Primary key. Determination replicate index (0 for scalar tests, 0..N for replicated arrays).")
                .HasColumnName("idx");
            entity.Property(e => e.CoverageFactorK)
                .HasComment("Coverage factor k (typically 2.0) applied during uncertainty calculation.")
                .HasColumnName("coverage_factor_k");
            entity.Property(e => e.UncertaintyValue)
                .HasComment("Calculated expanded measurement uncertainty U = (value * relative_uncertainty_pct / 100), as established in test definitions. Defines the boundary of the measurement result at approximately 95% confidence.")
                .HasColumnName("uncertainty_value");
            entity.Property(e => e.Value)
                .HasComment("Reported test value (numerical measurement or enum key).")
                .HasColumnName("value");

            entity.HasOne(d => d.Measurement).WithMany(p => p.ReportTests)
                .HasForeignKey(d => d.MeasurementId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("report_tests_measurement_id_fkey");

            entity.HasOne(d => d.Report).WithMany(p => p.ReportTests)
                .HasForeignKey(d => d.ReportId)
                .HasConstraintName("report_tests_report_id_fkey");

            entity.HasOne(d => d.Test).WithMany(p => p.ReportTests)
                .HasForeignKey(d => d.TestId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("report_tests_test_id_fkey");
        });

        modelBuilder.Entity<Sop>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("sops_pkey");

            entity.ToTable("sops", tb => tb.HasComment("Standard Operating Procedures (SOPs) defining laboratory test methods and testing protocols. Optionally linked to a parent norm (norms). In TestDialog.tsx, choosing a norm filters the SOP dropdown to show only SOPs that reference that norm."));

            entity.HasIndex(e => e.DocCode, "sops_doc_code_key").IsUnique();

            entity.Property(e => e.Id)
                .HasComment("Primary key. Unique 64-bit integer identifier for the SOP.")
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.DateCreated)
                .HasDefaultValueSql("clock_timestamp()")
                .HasComment("Timestamp with time zone when the SOP record was created. Defaults to clock_timestamp().")
                .HasColumnName("date_created");
            entity.Property(e => e.DocCode)
                .HasMaxLength(50)
                .HasComment("Unique official SOP document code (maximum 50 characters, e.g., 'SOP-QC-MET-0042'). Validated for uniqueness via UniquenessChecker.")
                .HasColumnName("doc_code");
            entity.Property(e => e.NormId)
                .HasComment("Foreign key referencing public.norms(id) (nullable). Identifies the governing compendial norm or pharmacopeia from which this SOP is derived.")
                .HasColumnName("norm_id");
            entity.Property(e => e.NrOrd)
                .HasComment("Numeric display and sequence ordering index (defaults to 0).")
                .HasColumnName("nr_ord");
            entity.Property(e => e.Title)
                .HasMaxLength(150)
                .HasComment("Descriptive title of the standard operating procedure (up to 150 characters, e.g., 'Determination of Water Content by Karl Fischer Titration').")
                .HasColumnName("title");

            entity.HasOne(d => d.Norm).WithMany(p => p.Sops)
                .HasForeignKey(d => d.NormId)
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("sops_norm_id_fkey");
        });

        modelBuilder.Entity<SopVersion>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("sop_versions_pkey");

            entity.ToTable("sop_versions", tb => tb.HasComment("Versioned document releases of Standard Operating Procedures (SOPs). Ensures compliance with document control guidelines by tracking active versus retired revisions and linking to external Electronic Document Management Systems (EDMS). Individual test measurements link to the exact sop_version_id in effect during execution."));

            entity.HasIndex(e => e.SopId, "unq_single_active_sop_version")
                .IsUnique()
                .HasFilter("(is_active = true)");

            entity.HasIndex(e => new { e.SopId, e.VersionNumber }, "unq_sop_version_number").IsUnique();

            entity.Property(e => e.Id)
                .HasComment("Primary key. Unique 64-bit integer identifier for the SOP version revision.")
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.Comments)
                .HasComment("Change control summary or revision history notes describing the updates introduced in this version.")
                .HasColumnName("comments");
            entity.Property(e => e.DateActivated)
                .HasDefaultValueSql("clock_timestamp()")
                .HasComment("Timestamp with time zone when this SOP version was officially authorized and released into production. Defaults to clock_timestamp().")
                .HasColumnName("date_activated");
            entity.Property(e => e.ExternalEdmsId)
                .HasMaxLength(100)
                .HasComment("External document management system identifier or hyperlink (maximum 100 characters) pointing to the controlled document PDF in the EDMS.")
                .HasColumnName("external_edms_id");
            entity.Property(e => e.IsActive)
                .HasDefaultValue(true)
                .HasComment("Boolean flag indicating whether this specific SOP version is currently active and authorized for analytical testing. Worksheet sessions query active SOP versions for logging test execution methods.")
                .HasColumnName("is_active");
            entity.Property(e => e.SopId)
                .HasComment("Foreign key referencing public.sops(id). Identifies the parent SOP to which this revision belongs.")
                .HasColumnName("sop_id");
            entity.Property(e => e.VersionNumber)
                .HasMaxLength(20)
                .HasComment("Revision string (maximum 20 characters, e.g., '1.0', '2.3', 'Rev C'). Unique per parent SOP.")
                .HasColumnName("version_number");

            entity.HasOne(d => d.Sop).WithMany(p => p.SopVersions)
                .HasForeignKey(d => d.SopId)
                .HasConstraintName("sop_versions_sop_id_fkey");
        });

        modelBuilder.Entity<Spec>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("specs_pkey");

            entity.ToTable("specs", tb => tb.HasComment("Product and material quality specifications. Defines release limits, compendial monographs, and acceptance criteria used to judge whether manufactured batches or raw material deliveries conform to registered quality standards. Governed by formal submission, replacement/revision, and cancellation lifecycles with electronic signatures."));

            entity.Property(e => e.Id)
                .HasComment("Primary key. Unique 64-bit integer identifier for the specification.")
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.CommentsCancelled)
                .HasComment("Mandatory documented explanation explaining why the specification was cancelled.")
                .HasColumnName("comments_cancelled");
            entity.Property(e => e.CommentsSubmitted)
                .HasComment("Regulatory remarks, change control numbers, or justification recorded at submission.")
                .HasColumnName("comments_submitted");
            entity.Property(e => e.DateCancelled)
                .HasComment("Timestamp with time zone when the specification was cancelled.")
                .HasColumnName("date_cancelled");
            entity.Property(e => e.DateSubmitted)
                .HasComment("Timestamp with time zone when the specification was officially activated.")
                .HasColumnName("date_submitted");
            entity.Property(e => e.IsCancelled)
                .HasComment("Boolean status flag. True indicates this specification has been cancelled or retired.")
                .HasColumnName("is_cancelled");
            entity.Property(e => e.IsSubmitted)
                .HasComment("Boolean status flag. True indicates the specification has been approved and activated for release testing. Only submitted and non-cancelled specifications are active for sample receptions and certificate generation.")
                .HasColumnName("is_submitted");
            entity.Property(e => e.MaterialId)
                .HasComment("Foreign key referencing public.materials(id). The material or product governed by this specification.")
                .HasColumnName("material_id");
            entity.Property(e => e.SpecReplacedId)
                .HasComment("Foreign key referencing public.specs(id) (nullable). Points to the previous specification version that this new revision supersedes.")
                .HasColumnName("spec_replaced_id");
            entity.Property(e => e.UserCancelledId)
                .HasComment("Foreign key referencing public.users(id) (nullable). The user who cancelled the specification.")
                .HasColumnName("user_cancelled_id");
            entity.Property(e => e.UserSubmittedId)
                .HasComment("Foreign key referencing public.users(id) (nullable). The QC authority who approved and submitted the specification.")
                .HasColumnName("user_submitted_id");

            entity.HasOne(d => d.Material).WithMany(p => p.Specs)
                .HasForeignKey(d => d.MaterialId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("specs_material_id_fkey");

            entity.HasOne(d => d.SpecReplaced).WithMany(p => p.InverseSpecReplaced)
                .HasForeignKey(d => d.SpecReplacedId)
                .HasConstraintName("specs_spec_replaced_id_fkey");

            entity.HasOne(d => d.UserCancelled).WithMany(p => p.SpecUserCancelleds)
                .HasForeignKey(d => d.UserCancelledId)
                .HasConstraintName("specs_user_cancelled_id_fkey");

            entity.HasOne(d => d.UserSubmitted).WithMany(p => p.SpecUserSubmitteds)
                .HasForeignKey(d => d.UserSubmittedId)
                .HasConstraintName("specs_user_submitted_id_fkey");
        });

        modelBuilder.Entity<SpecTest>(entity =>
        {
            entity.HasKey(e => new { e.SpecId, e.TestId }).HasName("spec_tests_pkey");

            entity.ToTable("spec_tests", tb => tb.HasComment("Acceptance limits and testing criteria for each analytical test within a specification. Encapsulates executable boolean condition formulas, human-readable specification notes, testing frequency, and ISO/IEC 17025 measurement uncertainty guard-band evaluation rules."));

            entity.Property(e => e.SpecId)
                .HasComment("Primary key and foreign key referencing public.specs(id). The parent specification.")
                .HasColumnName("spec_id");
            entity.Property(e => e.TestId)
                .HasComment("Primary key and foreign key referencing public.tests(id). The analytical test evaluated under this specification.")
                .HasColumnName("test_id");
            entity.Property(e => e.Condition)
                .HasMaxLength(255)
                .HasComment("Executable boolean expression string (maximum 255 characters, e.g., '[value] >= 98.0 && [value] <= 102.0', '[value] == 1'). Validated on blur in SpecTestDialog.tsx via SpecificationsService.ValidateCondition. Evaluated during certificate generation.")
                .HasColumnName("condition");
            entity.Property(e => e.Note)
                .HasMaxLength(150)
                .HasComment("Human-readable specification limit text (maximum 150 characters, e.g., '98.0% - 102.0%', 'Clear colorless liquid', 'NMT 0.5%'). Printed on analytical test reports and Quality Certificates.")
                .HasColumnName("note");
            entity.Property(e => e.TestFrequency)
                .HasComment("Integer testing frequency rule (e.g., 1 indicates testing is performed on every batch; 5 indicates skip-lot testing every 5 batches).")
                .HasColumnName("test_frequency");
            entity.Property(e => e.UseUncertainty)
                .HasComment("Boolean flag implementing ISO/IEC 17025 / ILAC-G8 decision rules. When true, certificate evaluation takes expanded measurement uncertainty into account by verifying that both the lower bound [value - U] and upper bound [value + U] satisfy the condition.")
                .HasColumnName("use_uncertainty");

            entity.HasOne(d => d.Spec).WithMany(p => p.SpecTests)
                .HasForeignKey(d => d.SpecId)
                .HasConstraintName("spec_tests_specs_id_fkey");

            entity.HasOne(d => d.Test).WithMany(p => p.SpecTests)
                .HasForeignKey(d => d.TestId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("spec_tests_tests_id_fkey");
        });

        modelBuilder.Entity<SpecTestEval>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("spec_test_evals_pkey");

            entity.ToTable("spec_test_evals", tb => tb.HasComment("Verification benchmark test cases for specification test conditions (spec_tests.condition). In SpecTestDialog.tsx, authors define test values and expected results (1=pass, 0=fail). The backend recalculates and verifies all cases to guarantee formula correctness before specification activation."));

            entity.Property(e => e.Id)
                .HasComment("Primary key. Unique 64-bit integer identifier for the evaluation test row.")
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.ExpectedResult)
                .HasComment("Expected outcome (1 for pass, 0 for fail) defined by the specification author.")
                .HasColumnName("expected_result");
            entity.Property(e => e.IsMatch)
                .HasComment("Boolean flag. True indicates result matches expected_result.")
                .HasColumnName("is_match");
            entity.Property(e => e.Note)
                .HasMaxLength(20)
                .HasComment("Short descriptive note explaining the test scenario (maximum 20 characters, e.g., 'Lower limit fail', 'Target pass').")
                .HasColumnName("note");
            entity.Property(e => e.Result)
                .HasComment("Actual boolean result evaluated by the rule engine (1 for conforming, 0 for non-conforming).")
                .HasColumnName("result");
            entity.Property(e => e.SpecId)
                .HasComment("Foreign key referencing public.specs(id). The parent specification.")
                .HasColumnName("spec_id");
            entity.Property(e => e.TestId)
                .HasComment("Foreign key referencing public.tests(id). The test being verified.")
                .HasColumnName("test_id");
            entity.Property(e => e.Value)
                .HasComment("Test input value passed into the specification condition expression.")
                .HasColumnName("value");

            entity.HasOne(d => d.Spec).WithMany(p => p.SpecTestEvals)
                .HasForeignKey(d => d.SpecId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("spec_test_evals_spec_id_fkey");

            entity.HasOne(d => d.Test).WithMany(p => p.SpecTestEvals)
                .HasForeignKey(d => d.TestId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("spec_test_evals_test_id_fkey");

            entity.HasOne(d => d.SpecTest).WithMany(p => p.SpecTestEvals)
                .HasForeignKey(d => new { d.SpecId, d.TestId })
                .HasConstraintName("spec_test_evals_spec_id_test_id_fkey");
        });

        modelBuilder.Entity<Test>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("tests_pkey");

            entity.ToTable("tests", tb => tb.HasComment("Master analytical test definition and calculation parameter dictionary. Defines physical, chemical, and biological tests, as well as intermediate variables used in formulas. Controls measurement data types, replicated array behavior, metrological uncertainty defaults, CRM requirements, norm/SOP method bindings, and validation immutability locks."));

            entity.HasIndex(e => e.Code, "tests_code_key").IsUnique();

            entity.Property(e => e.Id)
                .HasComment("Primary key. Unique 64-bit integer identifier for the test/parameter definition.")
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.Code)
                .HasMaxLength(50)
                .HasComment("Unique identifier token (2 to 50 characters) used as a mathematical variable in QC formulas (e.g., 'assay', 'lod_wt_loss', 'ph_val'). Must conform to regex /^(?!.*__)[a-zA-Z][a-zA-Z0-9_]*[a-zA-Z0-9]$/ (starts with letter, ends with alphanumeric, only alphanumeric and single underscores). Locked from editing if is_form_validated is true to maintain formula AST parsing validity.")
                .HasColumnName("code");
            entity.Property(e => e.CommentsObsolete)
                .HasComment("Documented reason recorded when deactivating the test definition. Cleared to NULL if reactivated.")
                .HasColumnName("comments_obsolete");
            entity.Property(e => e.DateCreated)
                .HasComment("Timestamp with time zone when the test was originally registered.")
                .HasColumnName("date_created");
            entity.Property(e => e.DateFormValidated)
                .HasComment("Timestamp with time zone when the test definition was locked following form validation approval.")
                .HasColumnName("date_form_validated");
            entity.Property(e => e.DateObsolete)
                .HasComment("Timestamp with time zone when the test was decommissioned. Cleared to NULL if reactivated.")
                .HasColumnName("date_obsolete");
            entity.Property(e => e.DefaultCoverageFactorK)
                .HasPrecision(3, 1)
                .HasComment("Default coverage factor k (NUMERIC(3,1), typically 2.0 corresponding to approximately 95% level of confidence under a normal distribution). Used in accordance with ISO/IEC 17025 and GUM (Guide to the Expression of Uncertainty in Measurement). Cleared to NULL when for_certification is false.")
                .HasColumnName("default_coverage_factor_k");
            entity.Property(e => e.Description)
                .HasComment("Extended explanatory text describing the test scope, analytical principle, or sampling preparation.")
                .HasColumnName("description");
            entity.Property(e => e.ForCertification)
                .HasComment("Boolean flag indicating that this is a critical specification test that must be reported on official Quality Certificates / Certificates of Analysis (COA). In TestDialog.tsx, checking this box automatically defaults relative_uncertainty_pct to 3.00% and default_coverage_factor_k to 2.0 (if null/0), and resets for_environmental_control and is_param to false. Unchecking it resets uncertainty fields to NULL.")
                .HasColumnName("for_certification");
            entity.Property(e => e.ForCertifiedReference)
                .HasComment("Boolean flag enforcing strict metrological traceability. When true, during worksheet execution (SelectCrmDialog.tsx), the analyst cannot manually type an arbitrary numeric value; they must select an active, certified value from a Certified Reference Material (CRM) inventory lot or prior CRM certificate. In TestDialog.tsx, enabling this flag resets and disables is_array, is_param, and for_environmental_control.")
                .HasColumnName("for_certified_reference");
            entity.Property(e => e.ForEnvironmentalControl)
                .HasComment("Boolean flag designating this test for cleanroom and environmental monitoring (e.g., ambient temperature, relative humidity, air particulates). In TestDialog.tsx, enabling this flag enforces that is_param is always set to true, and resets for_certification and for_certified_reference to false.")
                .HasColumnName("for_environmental_control");
            entity.Property(e => e.IsArray)
                .HasComment("Boolean flag indicating whether the test yields multiple replicated measurement determinations (e.g., parallel injections, duplicate titrations) rather than a single scalar value. In formulas, arrays are referenced as [[code]]. In TestDialog.tsx, setting is_array to true automatically resets and disables for_certified_reference. Locked from editing if is_form_validated is true.")
                .HasColumnName("is_array");
            entity.Property(e => e.IsFormValidated)
                .HasComment("Boolean validation lock. Automatically set to true by FormsService.ValidateForm when any form containing this test is validated and approved. Once true, the client UI disables and server rejects edits to test name, code, type_id, and is_array to guarantee that validated mathematical formulas and calculation ASTs do not become corrupt or broken.")
                .HasColumnName("is_form_validated");
            entity.Property(e => e.IsObsolete)
                .HasComment("Soft-deletion flag. Under GxP requirements, test definitions cannot be physically removed if referenced in historical worksheets, specifications, or certificates. When true, hides the test from new templates and specifications.")
                .HasColumnName("is_obsolete");
            entity.Property(e => e.IsParam)
                .HasComment("Boolean flag designating this test as an intermediate calculation parameter or raw input (e.g. tare weight, sample mass, dilution factor) rather than a reportable specification test. In TestDialog.tsx, setting is_param to true resets and disables for_certification and for_certified_reference; when for_environmental_control is true, is_param is always set to true. Locked from editing if is_form_validated is true.")
                .HasColumnName("is_param");
            entity.Property(e => e.Name)
                .HasMaxLength(50)
                .HasComment("Unique descriptive name of the test (3 to 50 characters, e.g., 'Assay by HPLC', 'Loss on Drying', 'pH at 25°C'). Locked from editing if is_form_validated is true.")
                .HasColumnName("name");
            entity.Property(e => e.NormId)
                .HasComment("Foreign key referencing public.norms(id) (nullable). Identifies the governing compendial standard. In TestDialog.tsx, selecting a norm filters available SOPs to those belonging to that norm, and clearing the norm resets norm_ref to NULL, sop_id to NULL, and empties the SOP list.")
                .HasColumnName("norm_id");
            entity.Property(e => e.NormRef)
                .HasMaxLength(50)
                .HasComment("Textual citation (maximum 50 characters) identifying the exact clause, section, or monograph within the governing norm (e.g., 'Ph. Eur. 2.2.3', 'USP <621>'). Enabled in TestDialog.tsx only when norm_id is selected.")
                .HasColumnName("norm_ref");
            entity.Property(e => e.NrOrd)
                .HasComment("Default numeric presentation and sorting order index (defaults to 0) used when displaying tests in tables and reports.")
                .HasColumnName("nr_ord");
            entity.Property(e => e.RelativeUncertaintyPct)
                .HasPrecision(5, 2)
                .HasComment("Expanded relative measurement uncertainty percentage (NUMERIC(5,2), e.g., 3.00 for ±3.00%). Used by the reporting engine to calculate absolute expanded measurement uncertainty: U = (value * relative_uncertainty_pct / 100). Editable only when for_certification is true; automatically cleared to NULL when for_certification is false.")
                .HasColumnName("relative_uncertainty_pct");
            entity.Property(e => e.SopId)
                .HasComment("Foreign key referencing public.sops(id) (nullable). Links the test definition to its approved operating procedure. Filtered by norm_id in the client UI.")
                .HasColumnName("sop_id");
            entity.Property(e => e.TypeId)
                .HasComment("Foreign key referencing public.value_types(id). Specifies whether results are stored as integer (1), real (2), boolean (3), or enum (4). Locked from editing if is_form_validated is true.")
                .HasColumnName("type_id");
            entity.Property(e => e.UnitId)
                .HasComment("Foreign key referencing public.units(id) (nullable). Identifies the default unit of measure associated with this test's results.")
                .HasColumnName("unit_id");

            entity.HasOne(d => d.Norm).WithMany(p => p.Tests)
                .HasForeignKey(d => d.NormId)
                .HasConstraintName("tests_norm_id_fkey");

            entity.HasOne(d => d.Sop).WithMany(p => p.Tests)
                .HasForeignKey(d => d.SopId)
                .HasConstraintName("tests_sop_id_fkey");

            entity.HasOne(d => d.Type).WithMany(p => p.Tests)
                .HasForeignKey(d => d.TypeId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("tests_value_type_id_fkey");

            entity.HasOne(d => d.Unit).WithMany(p => p.Tests)
                .HasForeignKey(d => d.UnitId)
                .HasConstraintName("tests_unit_id_fkey");

            entity.HasMany(d => d.Equipment).WithMany(p => p.Tests)
                .UsingEntity<Dictionary<string, object>>(
                    "TestEquipment",
                    r => r.HasOne<Equipment>().WithMany()
                        .HasForeignKey("EquipmentId")
                        .OnDelete(DeleteBehavior.ClientSetNull)
                        .HasConstraintName("test_equipments_equipment_id_fkey"),
                    l => l.HasOne<Test>().WithMany()
                        .HasForeignKey("TestId")
                        .HasConstraintName("test_equipments_test_id_fkey"),
                    j =>
                    {
                        j.HasKey("TestId", "EquipmentId").HasName("test_equipments_pkey");
                        j.ToTable("test_equipments", tb => tb.HasComment("Many-to-many junction table associating laboratory test definitions with required or default equipment models (equipments). When creating a measurement worksheet, tests automatically identify eligible instruments based on these assignments."));
                        j.IndexerProperty<long>("TestId")
                            .HasComment("Primary key and foreign key referencing public.tests(id). The analytical test requiring instrument allocation.")
                            .HasColumnName("test_id");
                        j.IndexerProperty<long>("EquipmentId")
                            .HasComment("Primary key and foreign key referencing public.equipments(id). The laboratory instrument authorized for executing this test.")
                            .HasColumnName("equipment_id");
                    });

            entity.HasMany(d => d.MaterialsNavigation).WithMany(p => p.TestsNavigation)
                .UsingEntity<Dictionary<string, object>>(
                    "TestReagent",
                    r => r.HasOne<Material>().WithMany()
                        .HasForeignKey("MaterialId")
                        .OnDelete(DeleteBehavior.ClientSetNull)
                        .HasConstraintName("test_reagents_material_id_fkey"),
                    l => l.HasOne<Test>().WithMany()
                        .HasForeignKey("TestId")
                        .HasConstraintName("test_reagents_test_id_fkey"),
                    j =>
                    {
                        j.HasKey("TestId", "MaterialId").HasName("test_reagents_pkey");
                        j.ToTable("test_reagents", tb => tb.HasComment("Many-to-many junction table associating analytical tests with consumable chemical reagents or volumetric solutions (materials where is_reagent = true). Specifies which chemical reagents are consumed during test execution and drives reagent lot traceability on worksheets."));
                        j.IndexerProperty<long>("TestId")
                            .HasComment("Primary key and foreign key referencing public.tests(id). The analytical test that consumes the reagent.")
                            .HasColumnName("test_id");
                        j.IndexerProperty<long>("MaterialId")
                            .HasComment("Primary key and foreign key referencing public.materials(id). The chemical reagent material required for this test.")
                            .HasColumnName("material_id");
                    });
        });

        modelBuilder.Entity<TestEnum>(entity =>
        {
            entity.HasKey(e => new { e.TestId, e.Value }).HasName("test_enums_pkey");

            entity.ToTable("test_enums", tb => tb.HasComment("Discrete lookup choice options for enum-type analytical tests (value_types.id = 4). When creating a new enum test in TestDialog.tsx, the analyst must supply at least two unique items (parsed from enumListString by newline, comma, or semicolon). Individual items can be added or edited via TestEnumDialog.tsx."));

            entity.HasIndex(e => new { e.TestId, e.Name }, "test_enums_test_id_name_key").IsUnique();

            entity.Property(e => e.TestId)
                .HasComment("Primary key and foreign key referencing public.tests(id). The parent test to which this enumeration item belongs.")
                .HasColumnName("test_id");
            entity.Property(e => e.Value)
                .HasComment("Primary key. Integer numeric code stored in measurement tables (measurement_tests.value, measurement_params.value) when this enum option is selected (e.g., 1 for 'Clear', 2 for 'Slightly Opalescent', 3 for 'Turbid').")
                .HasColumnName("value");
            entity.Property(e => e.IsObsolete)
                .HasComment("Soft-deletion flag. When true, hides this enum option from future selection while preserving historical test result interpretation.")
                .HasColumnName("is_obsolete");
            entity.Property(e => e.Name)
                .HasMaxLength(50)
                .HasComment("Human-readable display label (1 to 50 characters, e.g., 'Conforms', 'Positive', 'Clear colorless liquid') shown in dropdowns and printed on analytical certificates.")
                .HasColumnName("name");
            entity.Property(e => e.NrOrd)
                .HasComment("Numeric display order index (defaults to 0) controlling the sequence of options in client select menus.")
                .HasColumnName("nr_ord");

            entity.HasOne(d => d.Test).WithMany(p => p.TestEnums)
                .HasForeignKey(d => d.TestId)
                .HasConstraintName("test_enums_test_id_fkey");
        });

        modelBuilder.Entity<Unit>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("units_pkey");

            entity.ToTable("units", tb => tb.HasComment("Lookup catalog of units of measurement (UOM) utilized across analytical test definitions, laboratory equipment, chemical reagents, and parameter calculations (e.g., 'mg', 'mL', 'g/cm3', '%', 'pH', '°C', 'rpm', 'AU')."));

            entity.HasIndex(e => e.Name, "units_name_key").IsUnique();

            entity.Property(e => e.Id)
                .HasComment("Primary key. Unique 64-bit integer identifier for the measurement unit.")
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.DateCreated)
                .HasComment("Timestamp with time zone when the measurement unit record was created in the system.")
                .HasColumnName("date_created");
            entity.Property(e => e.Description)
                .HasComment("Full descriptive name or context for the measurement unit (e.g., 'Milligrams per kilogram', 'Degrees Celsius').")
                .HasColumnName("description");
            entity.Property(e => e.Name)
                .HasMaxLength(50)
                .HasComment("Unique symbol or name of the unit of measure (maximum 50 characters, e.g., 'mg/kg', 'mPa.s', 'Abs'). Displayed alongside test inputs, results, and specification notes.")
                .HasColumnName("name");
        });

        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("users_pkey");

            entity.ToTable("users", tb => tb.HasComment("User accounts and role-based access control table for laboratory personnel, QC managers, and system administrators. Maintains authentication credentials, session tracking, account security (lockout, password expiration), and soft-deletion status for GxP auditability."));

            entity.HasIndex(e => e.Code, "users_code_key").IsUnique();

            entity.HasIndex(e => e.Email, "users_email_key").IsUnique();

            entity.HasIndex(e => e.SessionId, "users_session_id_key").IsUnique();

            entity.HasIndex(e => e.Tag, "users_tag_key").IsUnique();

            entity.Property(e => e.Id)
                .HasComment("Primary key. Unique 64-bit integer identifier for each laboratory system user.")
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.Code)
                .HasMaxLength(3)
                .HasComment("Unique 2 to 3 uppercase alphanumeric identifier (regex /^[A-Z][A-Z0-9]*$/) representing the user's initials. Displayed on compact laboratory worksheets, test result tags, and sample labels.")
                .HasColumnName("code");
            entity.Property(e => e.CommentsObsolete)
                .HasComment("Mandatory documented explanation recorded when deactivating the user profile. Cleared to NULL if reactivated.")
                .HasColumnName("comments_obsolete");
            entity.Property(e => e.DateCreated)
                .HasComment("Timestamp with time zone when the user profile was originally registered in the system.")
                .HasColumnName("date_created");
            entity.Property(e => e.DateObsolete)
                .HasComment("Timestamp with time zone when the user was marked obsolete / deactivated. Cleared to NULL if reactivated.")
                .HasColumnName("date_obsolete");
            entity.Property(e => e.DatePasswordChanged)
                .HasComment("Timestamp with time zone when the user's password was last modified. Used for password aging policies.")
                .HasColumnName("date_password_changed");
            entity.Property(e => e.DateSessionCreated)
                .HasComment("Timestamp with time zone when the current session_id was generated upon successful login.")
                .HasColumnName("date_session_created");
            entity.Property(e => e.DateSessionExpire)
                .HasComment("Timestamp with time zone when the current session_id expires (typically 12 hours from generation). Checked by SessionAuthMiddleware.")
                .HasColumnName("date_session_expire");
            entity.Property(e => e.Email)
                .HasMaxLength(50)
                .HasComment("Unique email address of the user (maximum 50 characters). Validated via standard email format rules.")
                .HasColumnName("email");
            entity.Property(e => e.FailedLoginAttempts)
                .HasComment("Integer counter tracking consecutive failed login attempts. Reset to 0 upon successful login; used to trigger temporary or administrative account lockout after exceeding maximum allowed thresholds.")
                .HasColumnName("failed_login_attempts");
            entity.Property(e => e.FirstName)
                .HasMaxLength(50)
                .HasComment("User's given first name (maximum 50 characters).")
                .HasColumnName("first_name");
            entity.Property(e => e.IsAdmin)
                .HasComment("Boolean role flag. When true, grants full administrative privileges including user management, role assignments, system settings, and master data configuration.")
                .HasColumnName("is_admin");
            entity.Property(e => e.IsLabPers)
                .HasComment("Boolean role flag. When true, identifies the user as Laboratory Personnel, granting authorization to execute sample receptions, input raw measurement readings, prepare reagent lots, and operate worksheets.")
                .HasColumnName("is_lab_pers");
            entity.Property(e => e.IsLocked)
                .HasComment("Boolean flag indicating whether the account is currently locked against login attempts due to repeated authentication failures or manual administrative suspension.")
                .HasColumnName("is_locked");
            entity.Property(e => e.IsObsolete)
                .HasComment("Soft-deletion flag. Under GxP and 21 CFR Part 11 regulations, user records cannot be physically deleted because they are referenced across audit trails, electronic signatures, and test worksheets. True indicates the user is deactivated.")
                .HasColumnName("is_obsolete");
            entity.Property(e => e.IsQcPers)
                .HasComment("Boolean role flag. When true, identifies the user as Quality Control Personnel, granting authorization to review, validate, and approve forms, specifications, testing reports, and official quality certificates.")
                .HasColumnName("is_qc_pers");
            entity.Property(e => e.LastName)
                .HasMaxLength(50)
                .HasComment("User's family/surname (maximum 50 characters).")
                .HasColumnName("last_name");
            entity.Property(e => e.LockExpiration)
                .HasComment("Timestamp with time zone indicating when the temporary account lockout expires and authentication attempts may resume.")
                .HasColumnName("lock_expiration");
            entity.Property(e => e.MustChangePassword)
                .HasComment("Boolean flag forcing the user to update their password upon next login. Automatically set to true when an administrator creates a user account or executes an administrative password reset via ResetPasswordDialog.tsx.")
                .HasColumnName("must_change_password");
            entity.Property(e => e.PasswordHash)
                .HasComment("Secure cryptographic salted hash of the user's authentication password.")
                .HasColumnName("password_hash");
            entity.Property(e => e.PasswordSalt)
                .HasComment("Cryptographic salt value applied during password hashing to prevent rainbow table attacks.")
                .HasColumnName("password_salt");
            entity.Property(e => e.RefreshToken)
                .HasComment("Cryptographic refresh token string used for renewing API sessions.")
                .HasColumnType("character varying")
                .HasColumnName("refresh_token");
            entity.Property(e => e.SessionId)
                .HasMaxLength(255)
                .HasComment("Unique GUID string representing the user's active session. Stored in the secure HTTP cookie 'QCLabSession_{tenantTag}'. Cleared (set to NULL) upon explicit logout, session expiration, password reset, or account deactivation.")
                .HasColumnName("session_id");
            entity.Property(e => e.Tag)
                .HasMaxLength(12)
                .HasComment("Unique user login username/handle (3 to 12 characters). Enforced by client regex /^[a-z][a-z0-9_]*[a-z0-9]$/ (must start with a lowercase letter, end with alphanumeric, contain only lowercase letters, digits, or underscores). Used for authentication and audit log displays.")
                .HasColumnName("tag");
        });

        modelBuilder.Entity<ValueType>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("value_types_pkey");

            entity.ToTable("value_types", tb => tb.HasComment("Static foundational reference table defining data types supported for analytical tests and formula parameters: 1 = 'integer' (whole numbers), 2 = 'real' (floating point / decimal numbers), 3 = 'boolean' (binary pass/fail / true/false), 4 = 'enum' (discrete selection options defined in test_enums)."));

            entity.Property(e => e.Id)
                .HasComment("Primary key. Unique identifier corresponding to the primitive value type enumeration.")
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.Name)
                .HasMaxLength(50)
                .HasComment("Unique name of the data type ('integer', 'real', 'boolean', 'enum'). Used by the UI to dynamically render appropriate input controls (number input, checkbox/toggle, or select dropdown) and by the QCFormula engine for type inference.")
                .HasColumnName("name");
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
