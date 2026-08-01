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

    public virtual DbSet<Category> Categories { get; set; }

    public virtual DbSet<Certificate> Certificates { get; set; }

    public virtual DbSet<CertificateTest> CertificateTests { get; set; }

    public virtual DbSet<ControlCode> ControlCodes { get; set; }

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

    public virtual DbSet<Reception> Receptions { get; set; }

    public virtual DbSet<ReceptionType> ReceptionTypes { get; set; }

    public virtual DbSet<Report> Reports { get; set; }

    public virtual DbSet<ReportTest> ReportTests { get; set; }

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
                        .OnDelete(DeleteBehavior.ClientSetNull)
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
            entity.Property(e => e.IsConformingSpec).HasColumnName("is_conforming_spec");
            entity.Property(e => e.NoteSpec)
                .HasMaxLength(25)
                .HasColumnName("note_spec");
            entity.Property(e => e.TestCount).HasColumnName("test_count");
            entity.Property(e => e.Value).HasColumnName("value");

            entity.HasOne(d => d.Certificate).WithMany(p => p.CertificateTests)
                .HasForeignKey(d => d.CertificateId)
                .OnDelete(DeleteBehavior.ClientSetNull)
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
            entity.Property(e => e.IsReceptionReceived).HasColumnName("is_reception_received");
            entity.Property(e => e.MaterialId).HasColumnName("material_id");

            entity.HasOne(d => d.Material).WithMany(p => p.ControlCodes)
                .HasForeignKey(d => d.MaterialId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("control_codes_material_id_fkey");
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
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("form_condition_evals_form_id_fkey");

            entity.HasOne(d => d.Test).WithMany(p => p.FormConditionEvals)
                .HasForeignKey(d => d.TestId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("form_condition_evals_test_id_fkey");

            entity.HasOne(d => d.FormParam).WithMany(p => p.FormConditionEvals)
                .HasForeignKey(d => new { d.FormId, d.TestId })
                .OnDelete(DeleteBehavior.ClientSetNull)
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
                .OnDelete(DeleteBehavior.ClientSetNull)
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
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("form_eval_params_eval_id_fkey");

            entity.HasOne(d => d.Form).WithMany(p => p.FormEvalParams)
                .HasForeignKey(d => d.FormId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("form_eval_params_form_id_fkey");

            entity.HasOne(d => d.Test).WithMany(p => p.FormEvalParams)
                .HasForeignKey(d => d.TestId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("form_eval_params_test_id_fkey");

            entity.HasOne(d => d.FormParam).WithMany(p => p.FormEvalParams)
                .HasForeignKey(d => new { d.FormId, d.TestId })
                .OnDelete(DeleteBehavior.Cascade)
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
                .OnDelete(DeleteBehavior.ClientSetNull)
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
                        .OnDelete(DeleteBehavior.ClientSetNull)
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
            entity.Property(e => e.DateUpdate).HasColumnName("date_update");
            entity.Property(e => e.FormId).HasColumnName("form_id");
            entity.Property(e => e.IsReadonly).HasColumnName("is_readonly");
            entity.Property(e => e.IsReported).HasColumnName("is_reported");
            entity.Property(e => e.ReceptionId).HasColumnName("reception_id");
            entity.Property(e => e.UserReportedId).HasColumnName("user_reported_id");
            entity.Property(e => e.UserUpdateId).HasColumnName("user_update_id");

            entity.HasOne(d => d.Form).WithMany(p => p.Measurements)
                .HasForeignKey(d => d.FormId)
                .HasConstraintName("measurements_form_id_fkey");

            entity.HasOne(d => d.Reception).WithMany(p => p.Measurements)
                .HasForeignKey(d => d.ReceptionId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("measurements_reception_id_fkey");

            entity.HasOne(d => d.UserReported).WithMany(p => p.MeasurementUserReporteds)
                .HasForeignKey(d => d.UserReportedId)
                .HasConstraintName("measurements_user_reported_id_fkey");

            entity.HasOne(d => d.UserUpdate).WithMany(p => p.MeasurementUserUpdates)
                .HasForeignKey(d => d.UserUpdateId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("measurements_user_update_id_fkey");
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
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("measurement_params_measurement_id_fkey");

            entity.HasOne(d => d.Test).WithMany(p => p.MeasurementParams)
                .HasForeignKey(d => d.TestId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("measurement_params_test_id_fkey");

            entity.HasOne(d => d.FormParam).WithMany(p => p.MeasurementParams)
                .HasForeignKey(d => new { d.FormId, d.TestId })
                .OnDelete(DeleteBehavior.Cascade)
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
                .OnDelete(DeleteBehavior.ClientSetNull)
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
            entity.Property(e => e.Value).HasColumnName("value");

            entity.HasOne(d => d.Measurement).WithMany(p => p.ReportTests)
                .HasForeignKey(d => d.MeasurementId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("report_tests_measurement_id_fkey");

            entity.HasOne(d => d.Report).WithMany(p => p.ReportTests)
                .HasForeignKey(d => d.ReportId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("report_tests_report_id_fkey");

            entity.HasOne(d => d.Test).WithMany(p => p.ReportTests)
                .HasForeignKey(d => d.TestId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("report_tests_test_id_fkey");
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

            entity.HasOne(d => d.Spec).WithMany(p => p.SpecTests)
                .HasForeignKey(d => d.SpecId)
                .OnDelete(DeleteBehavior.ClientSetNull)
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
                .OnDelete(DeleteBehavior.ClientSetNull)
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
            entity.Property(e => e.DateObsolete).HasColumnName("date_obsolete");
            entity.Property(e => e.Description).HasColumnName("description");
            entity.Property(e => e.ForCertification).HasColumnName("for_certification");
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
            entity.Property(e => e.TypeId).HasColumnName("type_id");
            entity.Property(e => e.UnitId).HasColumnName("unit_id");

            entity.HasOne(d => d.Norm).WithMany(p => p.Tests)
                .HasForeignKey(d => d.NormId)
                .HasConstraintName("tests_norm_id_fkey");

            entity.HasOne(d => d.Type).WithMany(p => p.Tests)
                .HasForeignKey(d => d.TypeId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("tests_value_type_id_fkey");

            entity.HasOne(d => d.Unit).WithMany(p => p.Tests)
                .HasForeignKey(d => d.UnitId)
                .HasConstraintName("tests_unit_id_fkey");
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
                .OnDelete(DeleteBehavior.ClientSetNull)
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
            entity.Property(e => e.FirstName)
                .HasMaxLength(50)
                .HasColumnName("first_name");
            entity.Property(e => e.IsAdmin).HasColumnName("is_admin");
            entity.Property(e => e.IsLabPers).HasColumnName("is_lab_pers");
            entity.Property(e => e.IsObsolete).HasColumnName("is_obsolete");
            entity.Property(e => e.IsQcPers).HasColumnName("is_qc_pers");
            entity.Property(e => e.LastName)
                .HasMaxLength(50)
                .HasColumnName("last_name");
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
            entity.HasKey(e => e.Id).HasName("form_param_types_pkey");

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
