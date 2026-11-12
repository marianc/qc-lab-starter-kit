using System;
using System.Collections.Generic;

namespace QCLab.Models;

/// <summary>
/// Laboratory testing worksheet execution sessions. Records raw observations, formula evaluations, and test results for a sample reception. Captures exact instrument serial numbers, chemical reagent lots, and SOP revisions used during execution. Enforces automatic read-only locking upon report inclusion or expiration of form editing days.
/// </summary>
public partial class Measurement
{
    /// <summary>
    /// Primary key. Unique 64-bit integer identifier for the measurement worksheet session.
    /// </summary>
    public long Id { get; set; }

    /// <summary>
    /// Foreign key referencing public.receptions(id). The sample reception being analyzed.
    /// </summary>
    public long ReceptionId { get; set; }

    /// <summary>
    /// Foreign key referencing public.forms(id) (nullable). The structured dynamic form template used for executing calculations, if applicable.
    /// </summary>
    public long? FormId { get; set; }

    /// <summary>
    /// Analyst bench notes, environmental conditions, or procedural observations recorded during worksheet execution.
    /// </summary>
    public string? Comments { get; set; }

    /// <summary>
    /// Boolean flag (defaults to true). When true, the worksheet utilizes the standard instruments defined in test_equipments; when false, analyst custom-selects specific instrument assets stored in measurement_equipments.
    /// </summary>
    public bool UseDefaultEquipment { get; set; }

    /// <summary>
    /// Boolean status flag. True indicates that the test results from this worksheet have been included into a formal submitted test report (reports). Prevents subsequent tampering with raw data.
    /// </summary>
    public bool IsReported { get; set; }

    /// <summary>
    /// Foreign key referencing public.users(id) (nullable). The user who incorporated this measurement session into a test report.
    /// </summary>
    public long? UserReportedId { get; set; }

    /// <summary>
    /// Timestamp with time zone when the results were reported.
    /// </summary>
    public DateTime? DateReported { get; set; }

    /// <summary>
    /// Boolean lock flag (defaults to false). Automatically set to true when results are reported or after forms.days_active_for_editing has elapsed. Locks all child measurement_tests and measurement_params from modification.
    /// </summary>
    public bool IsReadonly { get; set; }

    /// <summary>
    /// Timestamp with time zone when the worksheet was transitioned to read-only status.
    /// </summary>
    public DateTime? DateReadonly { get; set; }

    /// <summary>
    /// Foreign key referencing public.users(id) (nullable). The user who performed the most recent edit.
    /// </summary>
    public long? UserUpdatedId { get; set; }

    /// <summary>
    /// Timestamp with time zone of the most recent worksheet modification.
    /// </summary>
    public DateTime? DateUpdated { get; set; }

    /// <summary>
    /// Foreign key referencing public.users(id). The laboratory analyst who initiated the measurement worksheet.
    /// </summary>
    public long UserCreatedId { get; set; }

    /// <summary>
    /// Timestamp with time zone when the worksheet session was created. Defaults to clock_timestamp().
    /// </summary>
    public DateTime DateCreated { get; set; }

    public virtual ICollection<CertificateTest> CertificateTests { get; set; } = new List<CertificateTest>();

    public virtual Form? Form { get; set; }

    public virtual ICollection<MeasurementParam> MeasurementParams { get; set; } = new List<MeasurementParam>();

    public virtual ICollection<MeasurementTest> MeasurementTests { get; set; } = new List<MeasurementTest>();

    public virtual Reception Reception { get; set; } = null!;

    public virtual ICollection<ReportTest> ReportTests { get; set; } = new List<ReportTest>();

    public virtual User UserCreated { get; set; } = null!;

    public virtual User? UserReported { get; set; }

    public virtual User? UserUpdated { get; set; }

    public virtual ICollection<ReagentLot> ControlCodes { get; set; } = new List<ReagentLot>();

    public virtual ICollection<Equipment> Equipment { get; set; } = new List<Equipment>();

    public virtual ICollection<SopVersion> SopVersions { get; set; } = new List<SopVersion>();
}
