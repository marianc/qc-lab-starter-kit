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

            entity.ToTable("audit_logs");

            entity.Property(e => e.Id)
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.Action)
                .HasMaxLength(10)
                .HasColumnName("action");
            entity.Property(e => e.ChangedFields).HasColumnName("changed_fields");
            entity.Property(e => e.ClientIp)
                .HasMaxLength(45)
                .HasColumnName("client_ip");
            entity.Property(e => e.NewData)
                .HasColumnType("jsonb")
                .HasColumnName("new_data");
            entity.Property(e => e.OldData)
                .HasColumnType("jsonb")
                .HasColumnName("old_data");
            entity.Property(e => e.ReasonForChange).HasColumnName("reason_for_change");
            entity.Property(e => e.RecordKeys)
                .HasColumnType("jsonb")
                .HasColumnName("record_keys");
            entity.Property(e => e.TableName)
                .HasMaxLength(100)
                .HasColumnName("table_name");
            entity.Property(e => e.Timestamp)
                .HasDefaultValueSql("clock_timestamp()")
                .HasColumnName("timestamp");
            entity.Property(e => e.UserId).HasColumnName("user_id");

            entity.HasOne(d => d.User).WithMany(p => p.AuditLogs)
                .HasForeignKey(d => d.UserId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("audit_logs_user_id_fkey");
        });

        modelBuilder.Entity<Category>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("categories_pkey");

            entity.ToTable("categories");

            entity.HasIndex(e => e.Code, "categories_code_key").IsUnique();

            entity.HasIndex(e => e.Name, "categories_name_key").IsUnique();

            entity.Property(e => e.Id)
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.Code)
                .HasMaxLength(3)
                .HasColumnName("code");
            entity.Property(e => e.CommentsObsolete).HasColumnName("comments_obsolete");
            entity.Property(e => e.DateCreated).HasColumnName("date_created");
            entity.Property(e => e.DateObsolete).HasColumnName("date_obsolete");
            entity.Property(e => e.Description).HasColumnName("description");
            entity.Property(e => e.IsObsolete).HasColumnName("is_obsolete");
            entity.Property(e => e.Name)
                .HasMaxLength(50)
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
                        j.ToTable("category_tests");
                        j.IndexerProperty<long>("CategoryId").HasColumnName("category_id");
                        j.IndexerProperty<long>("TestId").HasColumnName("test_id");
                    });
        });

        modelBuilder.Entity<Certificate>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("certificates_pkey");

            entity.ToTable("certificates");

            entity.Property(e => e.Id)
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.CertificateReplacedId).HasColumnName("certificate_replaced_id");
            entity.Property(e => e.CommentsCancelled).HasColumnName("comments_cancelled");
            entity.Property(e => e.CommentsSubmitted).HasColumnName("comments_submitted");
            entity.Property(e => e.ControlCodeId).HasColumnName("control_code_id");
            entity.Property(e => e.DateCancelled).HasColumnName("date_cancelled");
            entity.Property(e => e.DateSubmitted).HasColumnName("date_submitted");
            entity.Property(e => e.IsCancelled).HasColumnName("is_cancelled");
            entity.Property(e => e.IsConformingSpec).HasColumnName("is_conforming_spec");
            entity.Property(e => e.IsConformingUncertainty)
                .HasDefaultValue(true)
                .HasColumnName("is_conforming_uncertainty");
            entity.Property(e => e.IsSubmitted).HasColumnName("is_submitted");
            entity.Property(e => e.SpecId).HasColumnName("spec_id");
            entity.Property(e => e.UserCancelledId).HasColumnName("user_cancelled_id");
            entity.Property(e => e.UserSubmittedId).HasColumnName("user_submitted_id");

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

            entity.ToTable("certificate_tests");

            entity.Property(e => e.CertificateId).HasColumnName("certificate_id");
            entity.Property(e => e.ReportId).HasColumnName("report_id");
            entity.Property(e => e.TestId).HasColumnName("test_id");
            entity.Property(e => e.Idx).HasColumnName("idx");
            entity.Property(e => e.MeasurementId).HasColumnName("measurement_id");
            entity.Property(e => e.CoverageFactorK).HasColumnName("coverage_factor_k");
            entity.Property(e => e.IsConformingSpec).HasColumnName("is_conforming_spec");
            entity.Property(e => e.IsConformingUncertainty)
                .HasDefaultValue(true)
                .HasColumnName("is_conforming_uncertainty");
            entity.Property(e => e.NoteSpec)
                .HasMaxLength(25)
                .HasColumnName("note_spec");
            entity.Property(e => e.TestCount).HasColumnName("test_count");
            entity.Property(e => e.UncertaintyValue).HasColumnName("uncertainty_value");
            entity.Property(e => e.Value).HasColumnName("value");

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

            entity.ToTable("control_codes");

            entity.Property(e => e.Id)
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.Code)
                .HasMaxLength(50)
                .HasColumnName("code");
            entity.Property(e => e.DateCreated)
                .HasDefaultValueSql("clock_timestamp()")
                .HasColumnName("date_created");
            entity.Property(e => e.IsReceptionReceived).HasColumnName("is_reception_received");
            entity.Property(e => e.MaterialId).HasColumnName("material_id");

            entity.HasOne(d => d.Material).WithMany(p => p.ControlCodes)
                .HasForeignKey(d => d.MaterialId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("control_codes_material_id_fkey");
        });

        modelBuilder.Entity<ElectronicSignature>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("electronic_signatures_pkey");

            entity.ToTable("electronic_signatures");

            entity.Property(e => e.Id)
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.ClientIp)
                .HasMaxLength(45)
                .HasColumnName("client_ip");
            entity.Property(e => e.EntityId).HasColumnName("entity_id");
            entity.Property(e => e.EntityName)
                .HasMaxLength(50)
                .HasColumnName("entity_name");
            entity.Property(e => e.PayloadSha256)
                .HasMaxLength(64)
                .HasColumnName("payload_sha256");
            entity.Property(e => e.SignatureManifestText).HasColumnName("signature_manifest_text");
            entity.Property(e => e.SignatureMeaning)
                .HasMaxLength(50)
                .HasColumnName("signature_meaning");
            entity.Property(e => e.SignerUserId).HasColumnName("signer_user_id");
            entity.Property(e => e.SigningTimestamp)
                .HasDefaultValueSql("clock_timestamp()")
                .HasColumnName("signing_timestamp");
            entity.Property(e => e.Version)
                .HasDefaultValue(1L)
                .HasColumnName("version");

            entity.HasOne(d => d.SignerUser).WithMany(p => p.ElectronicSignatures)
                .HasForeignKey(d => d.SignerUserId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("electronic_signatures_signer_user_id_fkey");
        });

        modelBuilder.Entity<Equipment>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("equipment_pkey");

            entity.ToTable("equipments");

            entity.HasIndex(e => e.EquipmentCode, "equipment_equipment_code_key").IsUnique();

            entity.Property(e => e.Id)
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.CalibrationIntervalDays)
                .HasDefaultValue(365)
                .HasColumnName("calibration_interval_days");
            entity.Property(e => e.DateCreated)
                .HasDefaultValueSql("clock_timestamp()")
                .HasColumnName("date_created");
            entity.Property(e => e.EquipmentCode)
                .HasMaxLength(50)
                .HasColumnName("equipment_code");
            entity.Property(e => e.Location)
                .HasMaxLength(100)
                .HasColumnName("location");
            entity.Property(e => e.Manufacturer)
                .HasMaxLength(100)
                .HasColumnName("manufacturer");
            entity.Property(e => e.Model)
                .HasMaxLength(100)
                .HasColumnName("model");
            entity.Property(e => e.Name)
                .HasMaxLength(100)
                .HasColumnName("name");
            entity.Property(e => e.NextCalibrationDue).HasColumnName("next_calibration_due");
            entity.Property(e => e.SerialNumber)
                .HasMaxLength(100)
                .HasColumnName("serial_number");
            entity.Property(e => e.Status)
                .HasMaxLength(20)
                .HasDefaultValueSql("'Active'::character varying")
                .HasColumnName("status");
        });

        modelBuilder.Entity<EquipmentCalibration>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("equipment_calibrations_pkey");

            entity.ToTable("equipment_calibrations");

            entity.Property(e => e.Id)
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.CalibratedBy)
                .HasMaxLength(100)
                .HasColumnName("calibrated_by");
            entity.Property(e => e.CalibrationDate).HasColumnName("calibration_date");
            entity.Property(e => e.CertificateNumber)
                .HasMaxLength(100)
                .HasColumnName("certificate_number");
            entity.Property(e => e.DateCreated)
                .HasDefaultValueSql("clock_timestamp()")
                .HasColumnName("date_created");
            entity.Property(e => e.EquipmentId).HasColumnName("equipment_id");
            entity.Property(e => e.ExpandedUncertainty).HasColumnName("expanded_uncertainty");
            entity.Property(e => e.ExpirationDate).HasColumnName("expiration_date");
            entity.Property(e => e.ReferenceStandardsUsed).HasColumnName("reference_standards_used");
            entity.Property(e => e.ResultStatus)
                .HasMaxLength(20)
                .HasColumnName("result_status");

            entity.HasOne(d => d.Equipment).WithMany(p => p.EquipmentCalibrations)
                .HasForeignKey(d => d.EquipmentId)
                .HasConstraintName("equipment_calibrations_equipment_id_fkey");
        });

        modelBuilder.Entity<Form>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("forms_pkey");

            entity.ToTable("forms");

            entity.Property(e => e.Id)
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.CommentsCancelled).HasColumnName("comments_cancelled");
            entity.Property(e => e.CommentsSubmitted).HasColumnName("comments_submitted");
            entity.Property(e => e.CommentsValidated).HasColumnName("comments_validated");
            entity.Property(e => e.CustomNav).HasColumnName("custom_nav");
            entity.Property(e => e.DateCancelled).HasColumnName("date_cancelled");
            entity.Property(e => e.DateSubmitted).HasColumnName("date_submitted");
            entity.Property(e => e.DateValidated).HasColumnName("date_validated");
            entity.Property(e => e.FormGroupId).HasColumnName("form_group_id");
            entity.Property(e => e.IsCancelled).HasColumnName("is_cancelled");
            entity.Property(e => e.IsCustomized).HasColumnName("is_customized");
            entity.Property(e => e.IsSubmitted).HasColumnName("is_submitted");
            entity.Property(e => e.IsValidated).HasColumnName("is_validated");
            entity.Property(e => e.UserCancelledId).HasColumnName("user_cancelled_id");
            entity.Property(e => e.UserSubmittedId).HasColumnName("user_submitted_id");
            entity.Property(e => e.UserValidatedId).HasColumnName("user_validated_id");
            entity.Property(e => e.Version)
                .HasMaxLength(50)
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

            entity.ToTable("form_condition_evals");

            entity.Property(e => e.Id)
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.ExpectedResult).HasColumnName("expected_result");
            entity.Property(e => e.FormId).HasColumnName("form_id");
            entity.Property(e => e.IsMatch).HasColumnName("is_match");
            entity.Property(e => e.Note)
                .HasMaxLength(20)
                .HasColumnName("note");
            entity.Property(e => e.Result).HasColumnName("result");
            entity.Property(e => e.TestId).HasColumnName("test_id");
            entity.Property(e => e.Value).HasColumnName("value");

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

            entity.ToTable("form_evals");

            entity.Property(e => e.Id)
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.Description).HasColumnName("description");
            entity.Property(e => e.FormId).HasColumnName("form_id");

            entity.HasOne(d => d.Form).WithMany(p => p.FormEvals)
                .HasForeignKey(d => d.FormId)
                .HasConstraintName("form_evals_form_id_fkey");
        });

        modelBuilder.Entity<FormEvalParam>(entity =>
        {
            entity.HasKey(e => new { e.EvalId, e.FormId, e.TestId, e.Idx }).HasName("form_eval_params_pkey");

            entity.ToTable("form_eval_params");

            entity.Property(e => e.EvalId).HasColumnName("eval_id");
            entity.Property(e => e.FormId).HasColumnName("form_id");
            entity.Property(e => e.TestId).HasColumnName("test_id");
            entity.Property(e => e.Idx).HasColumnName("idx");
            entity.Property(e => e.ExpectedValue).HasColumnName("expected_value");
            entity.Property(e => e.IsMatch).HasColumnName("is_match");
            entity.Property(e => e.Value).HasColumnName("value");

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

            entity.ToTable("form_groups");

            entity.Property(e => e.Id)
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.Description).HasColumnName("description");
            entity.Property(e => e.IsFormValidated).HasColumnName("is_form_validated");
            entity.Property(e => e.Name)
                .HasMaxLength(50)
                .HasColumnName("name");
            entity.Property(e => e.NrOrd).HasColumnName("nr_ord");
        });

        modelBuilder.Entity<FormParam>(entity =>
        {
            entity.HasKey(e => new { e.FormId, e.TestId }).HasName("form_params_pkey");

            entity.ToTable("form_params");

            entity.Property(e => e.FormId).HasColumnName("form_id");
            entity.Property(e => e.TestId).HasColumnName("test_id");
            entity.Property(e => e.CodeRelatedArrays)
                .HasMaxLength(50)
                .HasColumnName("code_related_arrays");
            entity.Property(e => e.Condition)
                .HasMaxLength(255)
                .HasColumnName("condition");
            entity.Property(e => e.ConditionNote)
                .HasMaxLength(150)
                .HasColumnName("condition_note");
            entity.Property(e => e.DefaultValue).HasColumnName("default_value");
            entity.Property(e => e.Formula).HasColumnName("formula");
            entity.Property(e => e.FormulaDependencies).HasColumnName("formula_dependencies");
            entity.Property(e => e.HasCondition).HasColumnName("has_condition");
            entity.Property(e => e.IsCalculated).HasColumnName("is_calculated");
            entity.Property(e => e.IsRequired).HasColumnName("is_required");
            entity.Property(e => e.NrOrd).HasColumnName("nr_ord");
            entity.Property(e => e.NrOrdCalc).HasColumnName("nr_ord_calc");

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

            entity.ToTable("materials");

            entity.HasIndex(e => e.Code, "materials_code_key").IsUnique();

            entity.HasIndex(e => e.Name, "materials_name_key").IsUnique();

            entity.Property(e => e.Id)
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.CasNumber)
                .HasMaxLength(20)
                .HasColumnName("cas_number");
            entity.Property(e => e.Code)
                .HasMaxLength(5)
                .HasColumnName("code");
            entity.Property(e => e.CommentsObsolete).HasColumnName("comments_obsolete");
            entity.Property(e => e.DateCreated).HasColumnName("date_created");
            entity.Property(e => e.DateObsolete).HasColumnName("date_obsolete");
            entity.Property(e => e.Description).HasColumnName("description");
            entity.Property(e => e.IsObsolete).HasColumnName("is_obsolete");
            entity.Property(e => e.IsProduct).HasColumnName("is_product");
            entity.Property(e => e.IsRawMaterial).HasColumnName("is_raw_material");
            entity.Property(e => e.IsReagent).HasColumnName("is_reagent");
            entity.Property(e => e.Name)
                .HasMaxLength(50)
                .HasColumnName("name");
            entity.Property(e => e.NormId).HasColumnName("norm_id");

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
                        j.ToTable("material_tests");
                        j.IndexerProperty<long>("MaterialId").HasColumnName("material_id");
                        j.IndexerProperty<long>("TestId").HasColumnName("test_id");
                    });
        });

        modelBuilder.Entity<Measurement>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("measurements_pkey");

            entity.ToTable("measurements");

            entity.Property(e => e.Id)
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.Comments).HasColumnName("comments");
            entity.Property(e => e.DateCreated)
                .HasDefaultValueSql("clock_timestamp()")
                .HasColumnName("date_created");
            entity.Property(e => e.DateReadonly).HasColumnName("date_readonly");
            entity.Property(e => e.DateReported).HasColumnName("date_reported");
            entity.Property(e => e.DateUpdate).HasColumnName("date_update");
            entity.Property(e => e.FormId).HasColumnName("form_id");
            entity.Property(e => e.IsReadonly).HasColumnName("is_readonly");
            entity.Property(e => e.IsReported).HasColumnName("is_reported");
            entity.Property(e => e.ReceptionId).HasColumnName("reception_id");
            entity.Property(e => e.UseDefaultEquipment)
                .HasDefaultValue(true)
                .HasColumnName("use_default_equipment");
            entity.Property(e => e.UserCreatedId)
                .HasDefaultValue(1L)
                .HasColumnName("user_created_id");
            entity.Property(e => e.UserReportedId).HasColumnName("user_reported_id");
            entity.Property(e => e.UserUpdateId).HasColumnName("user_update_id");

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

            entity.HasOne(d => d.UserUpdate).WithMany(p => p.MeasurementUserUpdates)
                .HasForeignKey(d => d.UserUpdateId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("measurements_user_update_id_fkey");

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
                        j.ToTable("measurement_reagent_lots");
                        j.IndexerProperty<long>("MeasurementId").HasColumnName("measurement_id");
                        j.IndexerProperty<long>("ControlCodeId").HasColumnName("control_code_id");
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
                        j.ToTable("measurement_equipments");
                        j.IndexerProperty<long>("MeasurementId").HasColumnName("measurement_id");
                        j.IndexerProperty<long>("EquipmentId").HasColumnName("equipment_id");
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
                        j.ToTable("measurement_sop_versions");
                        j.IndexerProperty<long>("MeasurementId").HasColumnName("measurement_id");
                        j.IndexerProperty<long>("SopVersionId").HasColumnName("sop_version_id");
                    });
        });

        modelBuilder.Entity<MeasurementParam>(entity =>
        {
            entity.HasKey(e => new { e.MeasurementId, e.FormId, e.TestId, e.Idx }).HasName("measurement_params_pkey");

            entity.ToTable("measurement_params");

            entity.Property(e => e.MeasurementId).HasColumnName("measurement_id");
            entity.Property(e => e.FormId).HasColumnName("form_id");
            entity.Property(e => e.TestId).HasColumnName("test_id");
            entity.Property(e => e.Idx).HasColumnName("idx");
            entity.Property(e => e.ConditionValue).HasColumnName("condition_value");
            entity.Property(e => e.Value).HasColumnName("value");

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

            entity.HasOne(d => d.FormParam).WithMany(p => p.MeasurementParams)
                .HasForeignKey(d => new { d.FormId, d.TestId })
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("measurement_params_form_id_test_id_fkey");
        });

        modelBuilder.Entity<MeasurementTest>(entity =>
        {
            entity.HasKey(e => new { e.MeasurementId, e.TestId, e.Idx }).HasName("measurement_tests_pkey");

            entity.ToTable("measurement_tests");

            entity.Property(e => e.MeasurementId).HasColumnName("measurement_id");
            entity.Property(e => e.TestId).HasColumnName("test_id");
            entity.Property(e => e.Idx).HasColumnName("idx");
            entity.Property(e => e.Note)
                .HasMaxLength(20)
                .HasColumnName("note");
            entity.Property(e => e.Value).HasColumnName("value");

            entity.HasOne(d => d.Measurement).WithMany(p => p.MeasurementTests)
                .HasForeignKey(d => d.MeasurementId)
                .HasConstraintName("measurement_tests_measurement_id_fkey");

            entity.HasOne(d => d.Test).WithMany(p => p.MeasurementTests)
                .HasForeignKey(d => d.TestId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("measurement_tests_test_id_fkey");
        });

        modelBuilder.Entity<Norm>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("norms_pkey");

            entity.ToTable("norms");

            entity.HasIndex(e => e.Name, "norms_name_key").IsUnique();

            entity.Property(e => e.Id)
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.CommentsObsolete).HasColumnName("comments_obsolete");
            entity.Property(e => e.DateCreated).HasColumnName("date_created");
            entity.Property(e => e.DateObsolete).HasColumnName("date_obsolete");
            entity.Property(e => e.Description).HasColumnName("description");
            entity.Property(e => e.IsObsolete).HasColumnName("is_obsolete");
            entity.Property(e => e.Name)
                .HasMaxLength(50)
                .HasColumnName("name");
        });

        modelBuilder.Entity<ReagentLot>(entity =>
        {
            entity.HasKey(e => e.ControlCodeId).HasName("reagent_lots_pkey");

            entity.ToTable("reagent_lots");

            entity.Property(e => e.ControlCodeId)
                .ValueGeneratedNever()
                .HasColumnName("control_code_id");
            entity.Property(e => e.ExpirationDate).HasColumnName("expiration_date");
            entity.Property(e => e.IsProduced).HasColumnName("is_produced");
            entity.Property(e => e.ProducedByUserId).HasColumnName("produced_by_user_id");
            entity.Property(e => e.Quantity).HasColumnName("quantity");
            entity.Property(e => e.StatusId)
                .HasDefaultValue(1L)
                .HasColumnName("status_id");
            entity.Property(e => e.UnitId).HasColumnName("unit_id");

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
                        j.ToTable("reagent_production_lots");
                        j.IndexerProperty<long>("ControlCodeId").HasColumnName("control_code_id");
                        j.IndexerProperty<long>("IngredientControlCodeId").HasColumnName("ingredient_control_code_id");
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
                        j.ToTable("reagent_production_lots");
                        j.IndexerProperty<long>("ControlCodeId").HasColumnName("control_code_id");
                        j.IndexerProperty<long>("IngredientControlCodeId").HasColumnName("ingredient_control_code_id");
                    });
        });

        modelBuilder.Entity<ReagentLotStatus>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("reagent_lot_statuses_pkey");

            entity.ToTable("reagent_lot_statuses");

            entity.HasIndex(e => e.Name, "reagent_lot_statuses_name_key").IsUnique();

            entity.Property(e => e.Id)
                .ValueGeneratedNever()
                .HasColumnName("id");
            entity.Property(e => e.Name)
                .HasMaxLength(50)
                .HasColumnName("name");
        });

        modelBuilder.Entity<ReagentSupplier>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("reagent_suppliers_pkey");

            entity.ToTable("reagent_suppliers");

            entity.HasIndex(e => e.Name, "reagent_suppliers_name_key").IsUnique();

            entity.Property(e => e.Id)
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.Name)
                .HasMaxLength(100)
                .HasColumnName("name");
        });

        modelBuilder.Entity<ReagentSupplierLot>(entity =>
        {
            entity.HasKey(e => e.ControlCodeId).HasName("reagent_supplier_lots_pkey");

            entity.ToTable("reagent_supplier_lots");

            entity.Property(e => e.ControlCodeId)
                .ValueGeneratedNever()
                .HasColumnName("control_code_id");
            entity.Property(e => e.CatalogNumber)
                .HasMaxLength(50)
                .HasColumnName("catalog_number");
            entity.Property(e => e.CertificateOfAnalysisRef)
                .HasMaxLength(255)
                .HasColumnName("certificate_of_analysis_ref");
            entity.Property(e => e.Comments)
                .HasMaxLength(100)
                .HasColumnName("comments");
            entity.Property(e => e.ManufacturerLotNumber)
                .HasMaxLength(50)
                .HasColumnName("manufacturer_lot_number");
            entity.Property(e => e.SupplierId).HasColumnName("supplier_id");

            entity.HasOne(d => d.ControlCode).WithOne(p => p.ReagentSupplierLot)
                .HasForeignKey<ReagentSupplierLot>(d => d.ControlCodeId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("reagent_supplier_lots_control_code_id_fkey");

            entity.HasOne(d => d.Supplier).WithMany(p => p.ReagentSupplierLots)
                .HasForeignKey(d => d.SupplierId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("reagent_supplier_lots_supplier_id_fkey");
        });

        modelBuilder.Entity<Reception>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("receptions_pkey");

            entity.ToTable("receptions");

            entity.Property(e => e.Id)
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.CategoryId).HasColumnName("category_id");
            entity.Property(e => e.CommentsReceived).HasColumnName("comments_received");
            entity.Property(e => e.CommentsRejected).HasColumnName("comments_rejected");
            entity.Property(e => e.CommentsSubmitted).HasColumnName("comments_submitted");
            entity.Property(e => e.ControlCodeId).HasColumnName("control_code_id");
            entity.Property(e => e.DateReceived).HasColumnName("date_received");
            entity.Property(e => e.DateRejected).HasColumnName("date_rejected");
            entity.Property(e => e.DateSubmitted).HasColumnName("date_submitted");
            entity.Property(e => e.IsReceived).HasColumnName("is_received");
            entity.Property(e => e.IsRejected).HasColumnName("is_rejected");
            entity.Property(e => e.IsSubmitted).HasColumnName("is_submitted");
            entity.Property(e => e.MaterialName)
                .HasMaxLength(50)
                .HasColumnName("material_name");
            entity.Property(e => e.TypeId).HasColumnName("type_id");
            entity.Property(e => e.UserReceivedId).HasColumnName("user_received_id");
            entity.Property(e => e.UserRejectedId).HasColumnName("user_rejected_id");
            entity.Property(e => e.UserSubmittedId).HasColumnName("user_submitted_id");

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
                        j.ToTable("reception_tests");
                        j.IndexerProperty<long>("ReceptionId").HasColumnName("reception_id");
                        j.IndexerProperty<long>("TestId").HasColumnName("test_id");
                    });
        });

        modelBuilder.Entity<ReceptionType>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("reception_types_pkey");

            entity.ToTable("reception_types");

            entity.Property(e => e.Id)
                .ValueGeneratedNever()
                .HasColumnName("id");
            entity.Property(e => e.Name)
                .HasMaxLength(50)
                .HasColumnName("name");
        });

        modelBuilder.Entity<Report>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("reports_pkey");

            entity.ToTable("reports");

            entity.Property(e => e.Id)
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.CommentsCancelled).HasColumnName("comments_cancelled");
            entity.Property(e => e.CommentsSubmitted).HasColumnName("comments_submitted");
            entity.Property(e => e.DateCancelled).HasColumnName("date_cancelled");
            entity.Property(e => e.DateSubmitted).HasColumnName("date_submitted");
            entity.Property(e => e.IsCancelled).HasColumnName("is_cancelled");
            entity.Property(e => e.IsSubmitted).HasColumnName("is_submitted");
            entity.Property(e => e.ReceptionId).HasColumnName("reception_id");
            entity.Property(e => e.ReportReplacedId).HasColumnName("report_replaced_id");
            entity.Property(e => e.UserCancelledId).HasColumnName("user_cancelled_id");
            entity.Property(e => e.UserSubmittedId).HasColumnName("user_submitted_id");

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

            entity.ToTable("report_tests");

            entity.Property(e => e.ReportId).HasColumnName("report_id");
            entity.Property(e => e.MeasurementId).HasColumnName("measurement_id");
            entity.Property(e => e.TestId).HasColumnName("test_id");
            entity.Property(e => e.Idx).HasColumnName("idx");
            entity.Property(e => e.CoverageFactorK).HasColumnName("coverage_factor_k");
            entity.Property(e => e.UncertaintyValue).HasColumnName("uncertainty_value");
            entity.Property(e => e.Value).HasColumnName("value");

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

            entity.ToTable("sops");

            entity.HasIndex(e => e.DocCode, "sops_doc_code_key").IsUnique();

            entity.Property(e => e.Id)
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.DateCreated)
                .HasDefaultValueSql("clock_timestamp()")
                .HasColumnName("date_created");
            entity.Property(e => e.DocCode)
                .HasMaxLength(50)
                .HasColumnName("doc_code");
            entity.Property(e => e.NormId).HasColumnName("norm_id");
            entity.Property(e => e.Title)
                .HasMaxLength(150)
                .HasColumnName("title");

            entity.HasOne(d => d.Norm).WithMany(p => p.Sops)
                .HasForeignKey(d => d.NormId)
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("sops_norm_id_fkey");
        });

        modelBuilder.Entity<SopVersion>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("sop_versions_pkey");

            entity.ToTable("sop_versions");

            entity.HasIndex(e => e.SopId, "unq_single_active_sop_version")
                .IsUnique()
                .HasFilter("(is_active = true)");

            entity.HasIndex(e => new { e.SopId, e.VersionNumber }, "unq_sop_version_number").IsUnique();

            entity.Property(e => e.Id)
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.Comments).HasColumnName("comments");
            entity.Property(e => e.DateActivated)
                .HasDefaultValueSql("clock_timestamp()")
                .HasColumnName("date_activated");
            entity.Property(e => e.ExternalEdmsId)
                .HasMaxLength(100)
                .HasColumnName("external_edms_id");
            entity.Property(e => e.IsActive)
                .HasDefaultValue(true)
                .HasColumnName("is_active");
            entity.Property(e => e.SopId).HasColumnName("sop_id");
            entity.Property(e => e.VersionNumber)
                .HasMaxLength(20)
                .HasColumnName("version_number");

            entity.HasOne(d => d.Sop).WithMany(p => p.SopVersions)
                .HasForeignKey(d => d.SopId)
                .HasConstraintName("sop_versions_sop_id_fkey");
        });

        modelBuilder.Entity<Spec>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("specs_pkey");

            entity.ToTable("specs");

            entity.Property(e => e.Id)
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.CommentsCancelled).HasColumnName("comments_cancelled");
            entity.Property(e => e.CommentsSubmitted).HasColumnName("comments_submitted");
            entity.Property(e => e.DateCancelled).HasColumnName("date_cancelled");
            entity.Property(e => e.DateSubmitted).HasColumnName("date_submitted");
            entity.Property(e => e.IsCancelled).HasColumnName("is_cancelled");
            entity.Property(e => e.IsSubmitted).HasColumnName("is_submitted");
            entity.Property(e => e.MaterialId).HasColumnName("material_id");
            entity.Property(e => e.SpecReplacedId).HasColumnName("spec_replaced_id");
            entity.Property(e => e.UserCancelledId).HasColumnName("user_cancelled_id");
            entity.Property(e => e.UserSubmittedId).HasColumnName("user_submitted_id");

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

            entity.ToTable("spec_tests");

            entity.Property(e => e.SpecId).HasColumnName("spec_id");
            entity.Property(e => e.TestId).HasColumnName("test_id");
            entity.Property(e => e.Condition)
                .HasMaxLength(255)
                .HasColumnName("condition");
            entity.Property(e => e.Note)
                .HasMaxLength(150)
                .HasColumnName("note");
            entity.Property(e => e.TestFrequency).HasColumnName("test_frequency");
            entity.Property(e => e.UseUncertainty).HasColumnName("use_uncertainty");

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

            entity.ToTable("spec_test_evals");

            entity.Property(e => e.Id)
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.ExpectedResult).HasColumnName("expected_result");
            entity.Property(e => e.IsMatch).HasColumnName("is_match");
            entity.Property(e => e.Note)
                .HasMaxLength(20)
                .HasColumnName("note");
            entity.Property(e => e.Result).HasColumnName("result");
            entity.Property(e => e.SpecId).HasColumnName("spec_id");
            entity.Property(e => e.TestId).HasColumnName("test_id");
            entity.Property(e => e.Value).HasColumnName("value");

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

            entity.ToTable("tests");

            entity.HasIndex(e => e.Code, "tests_code_key").IsUnique();

            entity.HasIndex(e => e.Name, "tests_name_key").IsUnique();

            entity.Property(e => e.Id)
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.Code)
                .HasMaxLength(50)
                .HasColumnName("code");
            entity.Property(e => e.CommentsObsolete).HasColumnName("comments_obsolete");
            entity.Property(e => e.DateCreated).HasColumnName("date_created");
            entity.Property(e => e.DateFormValidated).HasColumnName("date_form_validated");
            entity.Property(e => e.DateObsolete).HasColumnName("date_obsolete");
            entity.Property(e => e.DefaultCoverageFactorK)
                .HasPrecision(3, 1)
                .HasColumnName("default_coverage_factor_k");
            entity.Property(e => e.Description).HasColumnName("description");
            entity.Property(e => e.ForCertification).HasColumnName("for_certification");
            entity.Property(e => e.ForEnvironmentalControl).HasColumnName("for_environmental_control");
            entity.Property(e => e.IsArray).HasColumnName("is_array");
            entity.Property(e => e.IsFormValidated).HasColumnName("is_form_validated");
            entity.Property(e => e.IsObsolete).HasColumnName("is_obsolete");
            entity.Property(e => e.IsParam).HasColumnName("is_param");
            entity.Property(e => e.Name)
                .HasMaxLength(50)
                .HasColumnName("name");
            entity.Property(e => e.NormId).HasColumnName("norm_id");
            entity.Property(e => e.NormRef)
                .HasMaxLength(50)
                .HasColumnName("norm_ref");
            entity.Property(e => e.NrOrd).HasColumnName("nr_ord");
            entity.Property(e => e.RelativeUncertaintyPct)
                .HasPrecision(5, 2)
                .HasColumnName("relative_uncertainty_pct");
            entity.Property(e => e.SopId).HasColumnName("sop_id");
            entity.Property(e => e.TypeId).HasColumnName("type_id");
            entity.Property(e => e.UnitId).HasColumnName("unit_id");

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
                        j.ToTable("test_equipments");
                        j.IndexerProperty<long>("TestId").HasColumnName("test_id");
                        j.IndexerProperty<long>("EquipmentId").HasColumnName("equipment_id");
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
                        j.ToTable("test_reagents");
                        j.IndexerProperty<long>("TestId").HasColumnName("test_id");
                        j.IndexerProperty<long>("MaterialId").HasColumnName("material_id");
                    });
        });

        modelBuilder.Entity<TestEnum>(entity =>
        {
            entity.HasKey(e => new { e.TestId, e.Value }).HasName("test_enums_pkey");

            entity.ToTable("test_enums");

            entity.HasIndex(e => new { e.TestId, e.Name }, "test_enums_test_id_name_key").IsUnique();

            entity.Property(e => e.TestId).HasColumnName("test_id");
            entity.Property(e => e.Value).HasColumnName("value");
            entity.Property(e => e.IsObsolete).HasColumnName("is_obsolete");
            entity.Property(e => e.Name)
                .HasMaxLength(50)
                .HasColumnName("name");
            entity.Property(e => e.NrOrd).HasColumnName("nr_ord");

            entity.HasOne(d => d.Test).WithMany(p => p.TestEnums)
                .HasForeignKey(d => d.TestId)
                .HasConstraintName("test_enums_test_id_fkey");
        });

        modelBuilder.Entity<Unit>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("units_pkey");

            entity.ToTable("units");

            entity.HasIndex(e => e.Name, "units_name_key").IsUnique();

            entity.Property(e => e.Id)
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.DateCreated).HasColumnName("date_created");
            entity.Property(e => e.Description).HasColumnName("description");
            entity.Property(e => e.Name)
                .HasMaxLength(50)
                .HasColumnName("name");
        });

        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("users_pkey");

            entity.ToTable("users");

            entity.HasIndex(e => e.Code, "users_code_key").IsUnique();

            entity.HasIndex(e => e.Email, "users_email_key").IsUnique();

            entity.HasIndex(e => e.SessionId, "users_session_id_key").IsUnique();

            entity.HasIndex(e => e.Tag, "users_tag_key").IsUnique();

            entity.Property(e => e.Id)
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.Code)
                .HasMaxLength(3)
                .HasColumnName("code");
            entity.Property(e => e.CommentsObsolete).HasColumnName("comments_obsolete");
            entity.Property(e => e.DateCreated).HasColumnName("date_created");
            entity.Property(e => e.DateObsolete).HasColumnName("date_obsolete");
            entity.Property(e => e.DatePasswordChanged).HasColumnName("date_password_changed");
            entity.Property(e => e.DateSessionCreated).HasColumnName("date_session_created");
            entity.Property(e => e.DateSessionExpire).HasColumnName("date_session_expire");
            entity.Property(e => e.Email)
                .HasMaxLength(50)
                .HasColumnName("email");
            entity.Property(e => e.FailedLoginAttempts).HasColumnName("failed_login_attempts");
            entity.Property(e => e.FirstName)
                .HasMaxLength(50)
                .HasColumnName("first_name");
            entity.Property(e => e.IsAdmin).HasColumnName("is_admin");
            entity.Property(e => e.IsLabPers).HasColumnName("is_lab_pers");
            entity.Property(e => e.IsLocked).HasColumnName("is_locked");
            entity.Property(e => e.IsObsolete).HasColumnName("is_obsolete");
            entity.Property(e => e.IsQcPers).HasColumnName("is_qc_pers");
            entity.Property(e => e.LastName)
                .HasMaxLength(50)
                .HasColumnName("last_name");
            entity.Property(e => e.LockExpiration).HasColumnName("lock_expiration");
            entity.Property(e => e.MustChangePassword).HasColumnName("must_change_password");
            entity.Property(e => e.PasswordHash).HasColumnName("password_hash");
            entity.Property(e => e.PasswordSalt).HasColumnName("password_salt");
            entity.Property(e => e.RefreshToken)
                .HasColumnType("character varying")
                .HasColumnName("refresh_token");
            entity.Property(e => e.SessionId)
                .HasMaxLength(255)
                .HasColumnName("session_id");
            entity.Property(e => e.Tag)
                .HasMaxLength(12)
                .HasColumnName("tag");
        });

        modelBuilder.Entity<ValueType>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("value_types_pkey");

            entity.ToTable("value_types");

            entity.Property(e => e.Id)
                .UseIdentityAlwaysColumn()
                .HasColumnName("id");
            entity.Property(e => e.Name)
                .HasMaxLength(50)
                .HasColumnName("name");
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
