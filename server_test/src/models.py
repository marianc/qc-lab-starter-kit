from typing import Optional
import datetime
import decimal

from sqlalchemy import ARRAY, BigInteger, Boolean, Column, Date, DateTime, ForeignKeyConstraint, Identity, Index, Integer, Numeric, PrimaryKeyConstraint, String, Table, Text, UniqueConstraint, text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship

class Base(DeclarativeBase):
    pass


class Categories(Base):
    __tablename__ = 'categories'
    __table_args__ = (
        PrimaryKeyConstraint('id', name='categories_pkey'),
        UniqueConstraint('code', name='categories_code_key'),
        UniqueConstraint('name', name='categories_name_key'),
        {'comment': 'Master classification table grouping materials and products into '
                "logical families (e.g., 'Finished Products', 'Active "
                "Pharmaceutical Ingredients', 'Excipients', 'Solvents'). Used for "
                'organizing catalog items and driving ad-hoc Category Verification '
                'sample receptions.'}
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True, comment='Primary key. Unique 64-bit integer identifier for the category.')
    name: Mapped[str] = mapped_column(String(50), nullable=False, comment='Unique name of the material category (3 to 50 characters). Validated for uniqueness on blur in CategoryDialog.tsx.')
    code: Mapped[str] = mapped_column(String(5), nullable=False, comment='Unique 2 to 5 character uppercase alphanumeric classification code (regex /^[A-Z][A-Z0-9]*$/). Validated for uniqueness on the client and server.')
    date_created: Mapped[datetime.datetime] = mapped_column(DateTime(True), nullable=False, comment='Timestamp with time zone when the category was established.')
    is_obsolete: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Soft-deletion flag. When true, prevents the category from being selected in new material definitions or category verification receptions while preserving historical records.')
    description: Mapped[Optional[str]] = mapped_column(Text, comment='Optional extended description of the category scope and materials covered.')
    date_obsolete: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True), comment='Timestamp with time zone when the category was retired. Cleared to NULL if reactivated.')
    comments_obsolete: Mapped[Optional[str]] = mapped_column(Text, comment='Documented reason recorded when retiring the category. Cleared to NULL if reactivated.')

    test: Mapped[list['Tests']] = relationship('Tests', secondary='category_tests', back_populates='category')
    receptions: Mapped[list['Receptions']] = relationship('Receptions', back_populates='category')


class EquipmentCalibrationStatuses(Base):
    __tablename__ = 'equipment_calibration_statuses'
    __table_args__ = (
        PrimaryKeyConstraint('id', name='equipment_calibration_statuses_pkey'),
        UniqueConstraint('name', name='equipment_calibration_statuses_name_key'),
        {'comment': "Lookup catalog for metrological calibration outcomes: 1 = 'Pass' "
                '(metrology results conform fully to manufacturer tolerances and '
                "uncertainty limits), 2 = 'Fail' (out-of-tolerance calibration "
                "requiring instrument repair or retirement), 3 = 'Limited Use' "
                '(calibrated with restricted operational range or derated accuracy '
                'limits).'}
    )

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, comment='Primary key. Unique identifier for the calibration outcome status.')
    name: Mapped[str] = mapped_column(String(50), nullable=False, comment="Unique name of the calibration status ('Pass', 'Fail', 'Limited Use').")

    equipment_calibrations: Mapped[list['EquipmentCalibrations']] = relationship('EquipmentCalibrations', back_populates='status')


class EquipmentStatuses(Base):
    __tablename__ = 'equipment_statuses'
    __table_args__ = (
        PrimaryKeyConstraint('id', name='equipment_statuses_pkey'),
        UniqueConstraint('name', name='equipment_statuses_name_key'),
        {'comment': 'Lookup catalog for operational status of analytical laboratory '
                "instruments: 1 = 'Active' (calibrated, qualified, and authorized "
                "for routine testing), 2 = 'Inactive' (standby or temporarily "
                "decommissioned), 3 = 'Calibration Due' (calibration overdue, "
                "locked from testing), 4 = 'Out of Service' (defective, undergoing "
                'repair, or failed calibration).'}
    )

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, comment='Primary key. Unique identifier for the equipment operational status.')
    name: Mapped[str] = mapped_column(String(50), nullable=False, comment="Unique status name ('Active', 'Inactive', 'Calibration Due', 'Out of Service').")

    equipments: Mapped[list['Equipments']] = relationship('Equipments', back_populates='status')


class FormGroups(Base):
    __tablename__ = 'form_groups'
    __table_args__ = (
        PrimaryKeyConstraint('id', name='form_groups_pkey'),
        {'comment': 'Logical family or category of dynamic analytical worksheet forms '
                "(e.g., 'Dissolution Testing Forms', 'Heavy Metals Assay Forms', "
                "'Loss on Drying Forms'). Controls overarching validation status "
                'across form versions.'}
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True, comment='Primary key. Unique 64-bit integer identifier for the form group.')
    name: Mapped[str] = mapped_column(String(50), nullable=False, comment='Unique name of the form family (3 to 50 characters). Validated for uniqueness via FormGroupDialog.tsx.')
    is_form_validated: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Boolean status flag. Automatically updated to true when any form version within this group achieves validation approval (FormsService.ValidateForm). Signals that test definitions associated with this group are locked from structurally breaking changes.')
    nr_ord: Mapped[int] = mapped_column(BigInteger, nullable=False, server_default=text('0'), comment='Numeric display order index (defaults to 0) controlling grouping sequence in client menus.')
    description: Mapped[Optional[str]] = mapped_column(Text, comment='Optional extended description of the testing domain and analytical methodologies handled by this form group.')

    forms: Mapped[list['Forms']] = relationship('Forms', back_populates='form_group')


class Norms(Base):
    __tablename__ = 'norms'
    __table_args__ = (
        PrimaryKeyConstraint('id', name='norms_pkey'),
        UniqueConstraint('name', name='norms_name_key'),
        {'comment': 'Compendial standards, pharmacopeias, or regulatory references '
                "(e.g., 'USP 43', 'Ph. Eur. 10', 'ISO/IEC 17025', 'ASTM D1298', "
                "'Internal QC Standard'). Provides governing normative authority "
                'for test methods, specifications, and standard operating '
                'procedures (SOPs).'}
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True, comment='Primary key. Unique 64-bit integer identifier for the norm record.')
    name: Mapped[str] = mapped_column(String(50), nullable=False, comment='Unique title or designation of the governing standard (3 to 50 characters). Validated for uniqueness in NormDialog.tsx.')
    date_created: Mapped[datetime.datetime] = mapped_column(DateTime(True), nullable=False, comment='Timestamp with time zone when the norm was registered.')
    is_obsolete: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Soft-deletion flag. When true, prevents associating this norm with new materials, tests, or SOPs.')
    description: Mapped[Optional[str]] = mapped_column(Text, comment='Detailed description of the standard, governing body, publication edition, or scope.')
    date_obsolete: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True), comment='Timestamp with time zone when the norm was marked obsolete. Cleared to NULL if reactivated.')
    comments_obsolete: Mapped[Optional[str]] = mapped_column(Text, comment='Documented justification explaining why the norm is no longer valid or applicable. Cleared to NULL if reactivated.')

    materials: Mapped[list['Materials']] = relationship('Materials', back_populates='norm')
    sops: Mapped[list['Sops']] = relationship('Sops', back_populates='norm')
    tests: Mapped[list['Tests']] = relationship('Tests', back_populates='norm')


class ReagentLotStatuses(Base):
    __tablename__ = 'reagent_lot_statuses'
    __table_args__ = (
        PrimaryKeyConstraint('id', name='reagent_lot_statuses_pkey'),
        UniqueConstraint('name', name='reagent_lot_statuses_name_key'),
        {'comment': 'Lifecycle status lookup table for physical laboratory reagent '
                "lots: 1 = 'Quarantined' (pending incoming inspection or CoA "
                "verification), 2 = 'Active' (approved for use in testing and "
                "production), 3 = 'Expired' (past manufacturer expiration date, "
                "locked from usage), 4 = 'Depleted' (inventory exhausted). Only "
                "lots in 'Active' status can be consumed in measurement worksheets "
                'or used as ingredients in lab preparations.'}
    )

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, comment='Primary key. Numeric identifier corresponding to the reagent lot status.')
    name: Mapped[str] = mapped_column(String(50), nullable=False, comment="Unique name of the lot status ('Quarantined', 'Active', 'Expired', 'Depleted').")

    reagent_lots: Mapped[list['ReagentLots']] = relationship('ReagentLots', back_populates='status')


class ReagentSuppliers(Base):
    __tablename__ = 'reagent_suppliers'
    __table_args__ = (
        PrimaryKeyConstraint('id', name='reagent_suppliers_pkey'),
        UniqueConstraint('name', name='reagent_suppliers_name_key'),
        {'comment': 'Catalog of external commercial vendors, manufacturers, and '
                'distributors of laboratory reagents, solvents, standards, and '
                "chemicals (e.g., 'Merck', 'Sigma-Aldrich', 'Fisher Scientific', "
                "'VWR'). Can be selected from an existing list or created "
                'on-the-fly during supplier lot entry in SupplierLotDialog.tsx.'}
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True, comment='Primary key. Unique 64-bit integer identifier for the reagent supplier.')
    name: Mapped[str] = mapped_column(String(100), nullable=False, comment='Unique name of the supplier company (up to 50 characters). Validated for uniqueness via ReagentsService.ValidateSupplierUniqueness.')

    reagent_supplier_lots: Mapped[list['ReagentSupplierLots']] = relationship('ReagentSupplierLots', back_populates='supplier')


class ReceptionTypes(Base):
    __tablename__ = 'reception_types'
    __table_args__ = (
        PrimaryKeyConstraint('id', name='reception_types_pkey'),
        {'comment': 'Lookup table defining the standard workflows for sample intake '
                "and laboratory login: 1 = 'Certification' (full release testing "
                "against active material specification), 2 = 'Verification' "
                "(custom test subset on an established material), 3 = 'Category "
                "Verification' (ad-hoc testing of unlisted or experimental samples "
                'classified by category).'}
    )

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, comment='Primary key. Numeric identifier of the reception type.')
    name: Mapped[str] = mapped_column(String(50), nullable=False, comment="Unique workflow title ('Certification', 'Verification', 'Category Verification'). Determines client dialog layout (CertificationDialog, VerificationDialog, or CategoryVerificationDialog) and backend test population logic.")

    receptions: Mapped[list['Receptions']] = relationship('Receptions', back_populates='type')


class Units(Base):
    __tablename__ = 'units'
    __table_args__ = (
        PrimaryKeyConstraint('id', name='units_pkey'),
        UniqueConstraint('name', name='units_name_key'),
        {'comment': 'Lookup catalog of units of measurement (UOM) utilized across '
                'analytical test definitions, laboratory equipment, chemical '
                "reagents, and parameter calculations (e.g., 'mg', 'mL', 'g/cm3', "
                "'%', 'pH', '░C', 'rpm', 'AU')."}
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True, comment='Primary key. Unique 64-bit integer identifier for the measurement unit.')
    name: Mapped[str] = mapped_column(String(50), nullable=False, comment="Unique symbol or name of the unit of measure (maximum 50 characters, e.g., 'mg/kg', 'mPa.s', 'Abs'). Displayed alongside test inputs, results, and specification notes.")
    date_created: Mapped[datetime.datetime] = mapped_column(DateTime(True), nullable=False, comment='Timestamp with time zone when the measurement unit record was created in the system.')
    description: Mapped[Optional[str]] = mapped_column(Text, comment="Full descriptive name or context for the measurement unit (e.g., 'Milligrams per kilogram', 'Degrees Celsius').")

    tests: Mapped[list['Tests']] = relationship('Tests', back_populates='unit')
    reagent_lots: Mapped[list['ReagentLots']] = relationship('ReagentLots', back_populates='unit')


class Users(Base):
    __tablename__ = 'users'
    __table_args__ = (
        PrimaryKeyConstraint('id', name='users_pkey'),
        UniqueConstraint('code', name='users_code_key'),
        UniqueConstraint('email', name='users_email_key'),
        UniqueConstraint('session_id', name='users_session_id_key'),
        UniqueConstraint('tag', name='users_tag_key'),
        {'comment': 'User accounts and role-based access control table for laboratory '
                'personnel, QC managers, and system administrators. Maintains '
                'authentication credentials, session tracking, account security '
                '(lockout, password expiration), and soft-deletion status for GxP '
                'auditability.'}
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True, comment='Primary key. Unique 64-bit integer identifier for each laboratory system user.')
    tag: Mapped[str] = mapped_column(String(12), nullable=False, comment='Unique user login username/handle (3 to 12 characters). Enforced by client regex /^[a-z][a-z0-9_]*[a-z0-9]$/ (must start with a lowercase letter, end with alphanumeric, contain only lowercase letters, digits, or underscores). Used for authentication and audit log displays.')
    code: Mapped[str] = mapped_column(String(3), nullable=False, comment="Unique 2 to 3 uppercase alphanumeric identifier (regex /^[A-Z][A-Z0-9]*$/) representing the user's initials. Displayed on compact laboratory worksheets, test result tags, and sample labels.")
    email: Mapped[str] = mapped_column(String(50), nullable=False, comment='Unique email address of the user (maximum 50 characters). Validated via standard email format rules.')
    is_admin: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Boolean role flag. When true, grants full administrative privileges including user management, role assignments, system settings, and master data configuration.')
    is_lab_pers: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Boolean role flag. When true, identifies the user as Laboratory Personnel, granting authorization to execute sample receptions, input raw measurement readings, prepare reagent lots, and operate worksheets.')
    is_qc_pers: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Boolean role flag. When true, identifies the user as Quality Control Personnel, granting authorization to review, validate, and approve forms, specifications, testing reports, and official quality certificates.')
    must_change_password: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Boolean flag forcing the user to update their password upon next login. Automatically set to true when an administrator creates a user account or executes an administrative password reset via ResetPasswordDialog.tsx.')
    failed_login_attempts: Mapped[int] = mapped_column(Integer, nullable=False, server_default=text('0'), comment='Integer counter tracking consecutive failed login attempts. Reset to 0 upon successful login; used to trigger temporary or administrative account lockout after exceeding maximum allowed thresholds.')
    is_locked: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Boolean flag indicating whether the account is currently locked against login attempts due to repeated authentication failures or manual administrative suspension.')
    date_created: Mapped[datetime.datetime] = mapped_column(DateTime(True), nullable=False, comment='Timestamp with time zone when the user profile was originally registered in the system.')
    is_obsolete: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Soft-deletion flag. Under GxP and 21 CFR Part 11 regulations, user records cannot be physically deleted because they are referenced across audit trails, electronic signatures, and test worksheets. True indicates the user is deactivated.')
    first_name: Mapped[Optional[str]] = mapped_column(String(50), comment="User's given first name (maximum 50 characters).")
    last_name: Mapped[Optional[str]] = mapped_column(String(50), comment="User's family/surname (maximum 50 characters).")
    password_hash: Mapped[Optional[str]] = mapped_column(Text, comment="Secure cryptographic salted hash of the user's authentication password.")
    password_salt: Mapped[Optional[str]] = mapped_column(Text, comment='Cryptographic salt value applied during password hashing to prevent rainbow table attacks.')
    date_password_changed: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True), comment="Timestamp with time zone when the user's password was last modified. Used for password aging policies.")
    lock_expiration: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True), comment='Timestamp with time zone indicating when the temporary account lockout expires and authentication attempts may resume.')
    session_id: Mapped[Optional[str]] = mapped_column(String(255), comment="Unique GUID string representing the user's active session. Stored in the secure HTTP cookie 'QCLabSession_{tenantTag}'. Cleared (set to NULL) upon explicit logout, session expiration, password reset, or account deactivation.")
    date_session_created: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True), comment='Timestamp with time zone when the current session_id was generated upon successful login.')
    date_session_expire: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True), comment='Timestamp with time zone when the current session_id expires (typically 12 hours from generation). Checked by SessionAuthMiddleware.')
    refresh_token: Mapped[Optional[str]] = mapped_column(String, comment='Cryptographic refresh token string used for renewing API sessions.')
    date_obsolete: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True), comment='Timestamp with time zone when the user was marked obsolete / deactivated. Cleared to NULL if reactivated.')
    comments_obsolete: Mapped[Optional[str]] = mapped_column(Text, comment='Mandatory documented explanation recorded when deactivating the user profile. Cleared to NULL if reactivated.')

    audit_logs: Mapped[list['AuditLogs']] = relationship('AuditLogs', back_populates='user')
    electronic_signatures: Mapped[list['ElectronicSignatures']] = relationship('ElectronicSignatures', back_populates='signer_user')
    forms_user_cancelled: Mapped[list['Forms']] = relationship('Forms', foreign_keys='[Forms.user_cancelled_id]', back_populates='user_cancelled')
    forms_user_submitted: Mapped[list['Forms']] = relationship('Forms', foreign_keys='[Forms.user_submitted_id]', back_populates='user_submitted')
    forms_user_validated: Mapped[list['Forms']] = relationship('Forms', foreign_keys='[Forms.user_validated_id]', back_populates='user_validated')
    specs_user_cancelled: Mapped[list['Specs']] = relationship('Specs', foreign_keys='[Specs.user_cancelled_id]', back_populates='user_cancelled')
    specs_user_submitted: Mapped[list['Specs']] = relationship('Specs', foreign_keys='[Specs.user_submitted_id]', back_populates='user_submitted')
    certificates_user_cancelled: Mapped[list['Certificates']] = relationship('Certificates', foreign_keys='[Certificates.user_cancelled_id]', back_populates='user_cancelled')
    certificates_user_submitted: Mapped[list['Certificates']] = relationship('Certificates', foreign_keys='[Certificates.user_submitted_id]', back_populates='user_submitted')
    reagent_lots: Mapped[list['ReagentLots']] = relationship('ReagentLots', back_populates='produced_by_user')
    receptions_user_received: Mapped[list['Receptions']] = relationship('Receptions', foreign_keys='[Receptions.user_received_id]', back_populates='user_received')
    receptions_user_rejected: Mapped[list['Receptions']] = relationship('Receptions', foreign_keys='[Receptions.user_rejected_id]', back_populates='user_rejected')
    receptions_user_submitted: Mapped[list['Receptions']] = relationship('Receptions', foreign_keys='[Receptions.user_submitted_id]', back_populates='user_submitted')
    measurements_user_created: Mapped[list['Measurements']] = relationship('Measurements', foreign_keys='[Measurements.user_created_id]', back_populates='user_created')
    measurements_user_reported: Mapped[list['Measurements']] = relationship('Measurements', foreign_keys='[Measurements.user_reported_id]', back_populates='user_reported')
    measurements_user_updated: Mapped[list['Measurements']] = relationship('Measurements', foreign_keys='[Measurements.user_updated_id]', back_populates='user_updated')
    reports_user_cancelled: Mapped[list['Reports']] = relationship('Reports', foreign_keys='[Reports.user_cancelled_id]', back_populates='user_cancelled')
    reports_user_submitted: Mapped[list['Reports']] = relationship('Reports', foreign_keys='[Reports.user_submitted_id]', back_populates='user_submitted')
    measurement_params_user_created: Mapped[list['MeasurementParams']] = relationship('MeasurementParams', foreign_keys='[MeasurementParams.user_created_id]', back_populates='user_created')
    measurement_params_user_updated: Mapped[list['MeasurementParams']] = relationship('MeasurementParams', foreign_keys='[MeasurementParams.user_updated_id]', back_populates='user_updated')
    measurement_tests_user_created: Mapped[list['MeasurementTests']] = relationship('MeasurementTests', foreign_keys='[MeasurementTests.user_created_id]', back_populates='user_created')
    measurement_tests_user_updated: Mapped[list['MeasurementTests']] = relationship('MeasurementTests', foreign_keys='[MeasurementTests.user_updated_id]', back_populates='user_updated')


class ValueTypes(Base):
    __tablename__ = 'value_types'
    __table_args__ = (
        PrimaryKeyConstraint('id', name='value_types_pkey'),
        {'comment': 'Static foundational reference table defining data types supported '
                "for analytical tests and formula parameters: 1 = 'integer' (whole "
                "numbers), 2 = 'real' (floating point / decimal numbers), 3 = "
                "'boolean' (binary pass/fail / true/false), 4 = 'enum' (discrete "
                'selection options defined in test_enums).'}
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True, comment='Primary key. Unique identifier corresponding to the primitive value type enumeration.')
    name: Mapped[str] = mapped_column(String(50), nullable=False, comment="Unique name of the data type ('integer', 'real', 'boolean', 'enum'). Used by the UI to dynamically render appropriate input controls (number input, checkbox/toggle, or select dropdown) and by the QCFormula engine for type inference.")

    tests: Mapped[list['Tests']] = relationship('Tests', back_populates='type')


class AuditLogs(Base):
    __tablename__ = 'audit_logs'
    __table_args__ = (
        ForeignKeyConstraint(['user_id'], ['users.id'], name='audit_logs_user_id_fkey'),
        PrimaryKeyConstraint('id', name='audit_logs_pkey'),
        {'comment': 'GxP and 21 CFR Part 11 compliant audit trail log table. '
                'Automatically populated via the PostgreSQL trigger function '
                "'process_audit_log()' whenever INSERT, UPDATE, or DELETE "
                'operations occur on critical quality tables (certificates, '
                'certificate_tests, forms, form_params, measurements, '
                'measurement_params, measurement_tests, reports, report_tests, '
                'specs, spec_tests). Application user context and justification '
                'are injected into PostgreSQL session variables '
                "('app.current_user_id' and 'app.reason_for_change') by the server "
                "DbCommandInterceptor 'AuditSessionDbCommandInterceptor'."}
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True, comment='Primary key. Unique synthetic 64-bit integer identifier for each audit trail entry.')
    table_name: Mapped[str] = mapped_column(String(100), nullable=False, comment="Name of the database table where the DML modification took place (e.g., 'measurements', 'forms', 'specs'). Populated automatically by the trigger via TG_TABLE_NAME.")
    action: Mapped[str] = mapped_column(String(10), nullable=False, comment="DML operation type performed on the record: 'INSERT', 'UPDATE', or 'DELETE'. Populated via TG_OP in the audit trigger.")
    user_id: Mapped[int] = mapped_column(BigInteger, nullable=False, comment="Foreign key referencing public.users(id). Identifies the laboratory analyst or QC supervisor who executed the transaction. Sourced from the transaction session variable 'app.current_user_id' set by AuditSessionDbCommandInterceptor.")
    timestamp: Mapped[datetime.datetime] = mapped_column(DateTime(True), nullable=False, server_default=text('clock_timestamp()'), comment='Timestamp with time zone indicating the exact database transaction time when the audit entry was written. Defaults to clock_timestamp() to capture accurate wall-clock execution time.')
    record_keys: Mapped[Optional[dict]] = mapped_column(JSONB, comment='JSONB object capturing the primary key column names and values of the audited record (e.g., {"id": 105} or composite keys like {"form_id": 2, "test_id": 14, "idx": 0}). Enables exact historical row tracking.')
    old_data: Mapped[Optional[dict]] = mapped_column(JSONB, comment='JSONB snapshot of the entire table row before the change occurred. Set to NULL for INSERT actions; contains pre-modification state for UPDATE and DELETE actions.')
    new_data: Mapped[Optional[dict]] = mapped_column(JSONB, comment='JSONB snapshot of the entire table row after the change occurred. Set to NULL for DELETE actions; contains post-modification state for INSERT and UPDATE actions.')
    changed_fields: Mapped[Optional[list[str]]] = mapped_column(ARRAY(Text()), comment='PostgreSQL text array (TEXT[]) listing the column names whose values were modified during an UPDATE operation. Allows rapid filtering and visual highlighting of specific edited fields in the audit viewer (AuditLogsTable.tsx).')
    reason_for_change: Mapped[Optional[str]] = mapped_column(Text, comment="Mandatory user-supplied justification for the modification. Captured in the UI via modal dialogs (e.g. CommentDialog) and transferred into PostgreSQL via the session variable 'app.reason_for_change' to ensure compliance with 21 CFR Part 11 requirements.")
    client_ip: Mapped[Optional[str]] = mapped_column(String(45), comment='Network IP address (IPv4 or IPv6, up to 45 characters) of the client machine that initiated the API request. Captured by ASP.NET Core HttpContextAccessor and recorded for forensic cybersecurity and compliance traceability.')

    user: Mapped['Users'] = relationship('Users', back_populates='audit_logs')


class ElectronicSignatures(Base):
    __tablename__ = 'electronic_signatures'
    __table_args__ = (
        ForeignKeyConstraint(['signer_user_id'], ['users.id'], name='electronic_signatures_signer_user_id_fkey'),
        PrimaryKeyConstraint('id', name='electronic_signatures_pkey'),
        {'comment': 'Cryptographic electronic signature ledger enforcing 21 CFR Part '
                '11 and EU GMP Annex 11 compliance. Stores legally binding digital '
                'signatures executed when laboratory personnel submit, validate, '
                'approve, or cancel critical quality documents (forms, '
                'specifications, test reports, quality certificates). Includes '
                'SHA-256 payload digests and human-readable signature manifests.'}
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True, comment='Primary key. Unique 64-bit integer identifier for the electronic signature record.')
    version: Mapped[int] = mapped_column(BigInteger, nullable=False, server_default=text('1'), comment='Monotonically increasing sequence number (defaults to 1) indicating the revision of the signature on a given entity record (e.g., Version 1 for initial submission, Version 2 for revision/approval, Version 3 for cancellation).')
    entity_name: Mapped[str] = mapped_column(String(50), nullable=False, comment="Name of the audited domain entity/table to which the signature applies (e.g., 'forms', 'specs', 'reports', 'certificates').")
    entity_id: Mapped[int] = mapped_column(BigInteger, nullable=False, comment='Primary key identifier of the specific domain record being digitally signed (e.g., forms.id, specs.id, certificates.id).')
    signer_user_id: Mapped[int] = mapped_column(BigInteger, nullable=False, comment='Foreign key referencing public.users(id). The authenticated user who entered their credentials and executed the signature.')
    signature_meaning: Mapped[str] = mapped_column(String(50), nullable=False, comment="Legally defined statement of intent / meaning of the signature (e.g., 'Submission', 'Validation', 'Approval', 'Cancellation'). Specifies the signer's regulatory responsibility pursuant to 21 CFR º 11.50.")
    signing_timestamp: Mapped[datetime.datetime] = mapped_column(DateTime(True), nullable=False, server_default=text('clock_timestamp()'), comment='Cryptographic timestamp with time zone at the exact instant the signature was sealed. Defaults to clock_timestamp().')
    payload_sha256: Mapped[str] = mapped_column(String(64), nullable=False, comment='Hex-encoded 64-character SHA-256 cryptographic hash of the canonical JSON representation of the entity state at the moment of signing. Guarantees tamper-evidence and data integrity: any post-signature tampering invalidates the hash verification.')
    signature_manifest_text: Mapped[str] = mapped_column(Text, nullable=False, comment='Human-readable text manifest summarizing the signed record details, signer full name, user tag, signature meaning, and timestamp. Rendered in the client UI via SignatureManifestBlock.tsx for inspection during audits.')
    client_ip: Mapped[str] = mapped_column(String(45), nullable=False, comment='Network IPv4/IPv6 client IP address from which the signature action was executed.')

    signer_user: Mapped['Users'] = relationship('Users', back_populates='electronic_signatures')


class Equipments(Base):
    __tablename__ = 'equipments'
    __table_args__ = (
        ForeignKeyConstraint(['status_id'], ['equipment_statuses.id'], name='equipments_status_id_fkey'),
        PrimaryKeyConstraint('id', name='equipment_pkey'),
        UniqueConstraint('equipment_code', name='equipment_equipment_code_key'),
        UniqueConstraint('serial_number', name='equipments_serial_number_key'),
        {'comment': 'Master inventory register of laboratory instruments, analytical '
                'balances, chromatography systems, and spectrophotometers. Tracks '
                'physical location, serial numbers, calibration schedules, and '
                'operational readiness under ISO/IEC 17025 and 21 CFR Part 211.'}
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True, comment='Primary key. Unique 64-bit integer identifier for the equipment asset.')
    equipment_code: Mapped[str] = mapped_column(String(50), nullable=False, comment="Unique laboratory internal asset tag or barcode (2 to 20 characters, e.g., 'BAL-001', 'HPLC-UV-03'). Used on sample worksheets and equipment selection dialogs.")
    name: Mapped[str] = mapped_column(String(100), nullable=False, comment="Descriptive equipment title (2 to 100 characters, e.g., 'Analytical Balance XP205', 'UV-Vis Spectrophotometer Evolution 300').")
    serial_number: Mapped[str] = mapped_column(String(100), nullable=False, comment='Unique manufacturer serial number (maximum 100 characters). Enforces instrument hardware identity.')
    status_id: Mapped[int] = mapped_column(BigInteger, nullable=False, comment="Foreign key referencing public.equipment_statuses(id). Operational state of the instrument. Automatically set to 'Active' when a successful calibration is recorded in EquipmentsService.AddEquipmentCalibration.")
    date_created: Mapped[datetime.datetime] = mapped_column(DateTime(True), nullable=False, server_default=text('clock_timestamp()'), comment='Timestamp with time zone when the equipment asset was registered in the database. Defaults to clock_timestamp().')
    manufacturer: Mapped[Optional[str]] = mapped_column(String(100), comment="Name of the equipment manufacturer or OEM (maximum 100 characters, e.g., 'Mettler Toledo', 'Waters', 'Agilent').")
    model: Mapped[Optional[str]] = mapped_column(String(100), comment="Manufacturer model number or instrument family (maximum 100 characters, e.g., 'Alliance e2695', 'XS204').")
    location: Mapped[Optional[str]] = mapped_column(String(100), comment="Laboratory room, bench, or cleanroom zone where the instrument is installed (maximum 100 characters, e.g., 'QC Phys-Chem Room 204').")
    calibration_interval_days: Mapped[Optional[int]] = mapped_column(Integer, server_default=text('365'), comment='Number of days between required periodic recalibrations (integer, defaults to 365 days / 1 year).')
    next_calibration_due: Mapped[Optional[datetime.date]] = mapped_column(Date, comment='Calendar date when the instrument must next undergo calibration. Automatically updated from the expiration_date of the most recently recorded calibration certificate.')

    status: Mapped['EquipmentStatuses'] = relationship('EquipmentStatuses', back_populates='equipments')
    test: Mapped[list['Tests']] = relationship('Tests', secondary='test_equipments', back_populates='equipment')
    measurement: Mapped[list['Measurements']] = relationship('Measurements', secondary='measurement_equipments', back_populates='equipment')
    equipment_calibrations: Mapped[list['EquipmentCalibrations']] = relationship('EquipmentCalibrations', back_populates='equipment')


class Forms(Base):
    __tablename__ = 'forms'
    __table_args__ = (
        ForeignKeyConstraint(['form_group_id'], ['form_groups.id'], name='forms_form_group_id_fkey'),
        ForeignKeyConstraint(['user_cancelled_id'], ['users.id'], name='forms_user_canceled_id_fkey'),
        ForeignKeyConstraint(['user_submitted_id'], ['users.id'], name='forms_user_submitted_id_fkey'),
        ForeignKeyConstraint(['user_validated_id'], ['users.id'], name='forms_user_validated_id_fkey'),
        PrimaryKeyConstraint('id', name='forms_pkey'),
        {'comment': 'Version-controlled dynamic analytical worksheet templates. '
                'Encapsulates formula calculation graphs, topological evaluation '
                'orders, conditional rules, and software validation datasets. '
                'Enforces GxP lifecycle state progression: Draft -> Submitted -> '
                'Validated -> Cancelled, accompanied by 21 CFR Part 11 electronic '
                'signatures.'}
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True, comment='Primary key. Unique 64-bit integer identifier for the form template.')
    form_group_id: Mapped[int] = mapped_column(BigInteger, nullable=False, comment='Foreign key referencing public.form_groups(id). The parent group / test family to which this form template belongs.')
    version: Mapped[str] = mapped_column(String(50), nullable=False, comment="Version number string (maximum 50 characters, e.g., '1.0', '2.1'). Unique per form group.")
    days_active_for_editing: Mapped[int] = mapped_column(Integer, nullable=False, server_default=text('10'), comment='Grace period in days (integer, defaults to 10) during which a worksheet instance generated from this form remains editable. Once this elapsed time expires following creation, the worksheet automatically becomes locked (is_readonly = true).')
    is_customized: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Boolean flag indicating that this form relies on a dedicated, specialized frontend UI component rather than standard auto-rendered grid layout. In FormDialog.tsx, when checked, custom_nav is mandatory.')
    is_submitted: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Boolean lifecycle flag. True indicates the form template has been finalized and submitted for formal verification.')
    is_validated: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Boolean approval flag. When true, the form is validated for routine production testing. Validation requires that all verification test cases (form_evals) PASS. Approving a form creates an electronic signature, marks form_groups.is_form_validated = true, and locks tests.is_form_validated = true for all referenced tests.')
    is_cancelled: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Boolean lifecycle flag. True indicates the form template was cancelled or superseded. Cancelled forms cannot be selected for new sample receptions or measurements.')
    custom_nav: Mapped[Optional[str]] = mapped_column(Text, comment="Frontend component route or navigation tag (e.g., 'TestingFormA') defining the custom layout renderer. Mandatory if is_customized is true; nullable if standard generic rendering is used.")
    user_submitted_id: Mapped[Optional[int]] = mapped_column(BigInteger, comment='Foreign key referencing public.users(id) (nullable). The form author who submitted the template.')
    date_submitted: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True), comment='Timestamp with time zone when the form was submitted.')
    comments_submitted: Mapped[Optional[str]] = mapped_column(Text, comment='Author notes, design rationale, or change summary recorded at submission.')
    user_validated_id: Mapped[Optional[int]] = mapped_column(BigInteger, comment='Foreign key referencing public.users(id) (nullable). The QC supervisor / system owner who validated and approved the form.')
    date_validated: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True), comment='Timestamp with time zone when validation approval was granted.')
    comments_validated: Mapped[Optional[str]] = mapped_column(Text, comment='Formal validation approval remarks recorded by the QC reviewer.')
    user_cancelled_id: Mapped[Optional[int]] = mapped_column(BigInteger, comment='Foreign key referencing public.users(id) (nullable). The user who cancelled the form template.')
    date_cancelled: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True), comment='Timestamp with time zone when the form was cancelled.')
    comments_cancelled: Mapped[Optional[str]] = mapped_column(Text, comment='Mandatory documented justification explaining why the form was cancelled.')

    form_group: Mapped['FormGroups'] = relationship('FormGroups', back_populates='forms')
    user_cancelled: Mapped[Optional['Users']] = relationship('Users', foreign_keys=[user_cancelled_id], back_populates='forms_user_cancelled')
    user_submitted: Mapped[Optional['Users']] = relationship('Users', foreign_keys=[user_submitted_id], back_populates='forms_user_submitted')
    user_validated: Mapped[Optional['Users']] = relationship('Users', foreign_keys=[user_validated_id], back_populates='forms_user_validated')
    form_evals: Mapped[list['FormEvals']] = relationship('FormEvals', back_populates='form')
    form_params: Mapped[list['FormParams']] = relationship('FormParams', back_populates='form')
    form_condition_evals: Mapped[list['FormConditionEvals']] = relationship('FormConditionEvals', back_populates='form')
    form_eval_params: Mapped[list['FormEvalParams']] = relationship('FormEvalParams', back_populates='form')
    measurements: Mapped[list['Measurements']] = relationship('Measurements', back_populates='form')
    measurement_params: Mapped[list['MeasurementParams']] = relationship('MeasurementParams', back_populates='form')


class Materials(Base):
    __tablename__ = 'materials'
    __table_args__ = (
        ForeignKeyConstraint(['norm_id'], ['norms.id'], name='materials_norm_id_fkey'),
        PrimaryKeyConstraint('id', name='materials_pkey'),
        UniqueConstraint('code', name='materials_code_key'),
        UniqueConstraint('name', name='materials_name_key'),
        {'comment': 'Master item catalog covering manufactured finished products, raw '
                'materials, intermediates, chemical reagents, and certified '
                'reference materials (CRMs). Dictates whether an item undergoes '
                'standard QC release testing, is tracked as a reagent in lab '
                'inventory, or requires strict metrological traceability.'}
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True, comment='Primary key. Unique 64-bit integer identifier for the material.')
    name: Mapped[str] = mapped_column(String(50), nullable=False, comment="Unique descriptive name of the material (3 to 50 characters, e.g., 'Aspirin Active Substance', 'Ethanol 96%', 'Potassium Dichromate CRM'). Validated for uniqueness on the server and client.")
    code: Mapped[str] = mapped_column(String(10), nullable=False, comment='Unique uppercase alphanumeric material code (2 to 10 characters, regex /^[A-Z][A-Z0-9]*$/). Used for inventory identification and batch code generation.')
    is_product: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Boolean flag designating the item as a manufactured finished product eligible for production release and customer Certificate of Analysis generation.')
    is_raw_material: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Boolean flag designating the item as an incoming raw material, active substance, or excipient requiring intake QC verification.')
    is_reagent: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Boolean flag designating the item as a laboratory chemical reagent or volumetric solution. Reagents are filtered out in general views unless the user possesses lab or QC roles (is_lab_pers or is_qc_pers). Managed via ReagentsPage.tsx and reagent_lots.')
    is_certified_reference: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Boolean flag indicating that this material is a Certified Reference Material (CRM) requiring strict metrological traceability and certificate of analysis validation under ISO 17034 / ISO/IEC 17025.')
    date_created: Mapped[datetime.datetime] = mapped_column(DateTime(True), nullable=False, comment='Timestamp with time zone when the material was registered in the database.')
    is_obsolete: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Soft-deletion flag. Set via MaterialsService.ToggleObsolete. When true, prevents initiating new sample receptions or specifications. Setting to true stamps date_obsolete with UTC timestamp and stores comments_obsolete; reactivating clears both fields to NULL.')
    description: Mapped[Optional[str]] = mapped_column(Text, comment='Optional text notes detailing chemical grade, storage conditions, or physical specifications.')
    norm_id: Mapped[Optional[int]] = mapped_column(BigInteger, comment='Foreign key referencing public.norms(id) (nullable). Identifies the primary pharmacopeial monograph or compendial standard governing this material.')
    cas_number: Mapped[Optional[str]] = mapped_column(String(20), comment="Chemical Abstracts Service (CAS) registry number (maximum 20 characters, e.g., '50-78-2' for Acetylsalicylic acid). Used primarily for chemical identification and reagent safety.")
    date_obsolete: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True), comment='Timestamp with time zone when the material was retired. Cleared to NULL if reactivated.')
    comments_obsolete: Mapped[Optional[str]] = mapped_column(Text, comment='Mandatory documented justification explaining why the material was marked obsolete. Cleared to NULL if reactivated.')

    norm: Mapped[Optional['Norms']] = relationship('Norms', back_populates='materials')
    tests_material_tests: Mapped[list['Tests']] = relationship('Tests', secondary='material_tests', back_populates='materials_material_tests')
    tests_test_reagents: Mapped[list['Tests']] = relationship('Tests', secondary='test_reagents', back_populates='materials_test_reagents')
    control_codes: Mapped[list['ControlCodes']] = relationship('ControlCodes', back_populates='material')
    specs: Mapped[list['Specs']] = relationship('Specs', back_populates='material')


class Sops(Base):
    __tablename__ = 'sops'
    __table_args__ = (
        ForeignKeyConstraint(['norm_id'], ['norms.id'], ondelete='CASCADE', name='sops_norm_id_fkey'),
        PrimaryKeyConstraint('id', name='sops_pkey'),
        UniqueConstraint('doc_code', name='sops_doc_code_key'),
        {'comment': 'Standard Operating Procedures (SOPs) defining laboratory test '
                'methods and testing protocols. Optionally linked to a parent norm '
                '(norms). In TestDialog.tsx, choosing a norm filters the SOP '
                'dropdown to show only SOPs that reference that norm.'}
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True, comment='Primary key. Unique 64-bit integer identifier for the SOP.')
    doc_code: Mapped[str] = mapped_column(String(50), nullable=False, comment="Unique official SOP document code (maximum 50 characters, e.g., 'SOP-QC-MET-0042'). Validated for uniqueness via UniquenessChecker.")
    title: Mapped[str] = mapped_column(String(150), nullable=False, comment="Descriptive title of the standard operating procedure (up to 150 characters, e.g., 'Determination of Water Content by Karl Fischer Titration').")
    nr_ord: Mapped[int] = mapped_column(BigInteger, nullable=False, server_default=text('0'), comment='Numeric display and sequence ordering index (defaults to 0).')
    date_created: Mapped[datetime.datetime] = mapped_column(DateTime(True), nullable=False, server_default=text('clock_timestamp()'), comment='Timestamp with time zone when the SOP record was created. Defaults to clock_timestamp().')
    norm_id: Mapped[Optional[int]] = mapped_column(BigInteger, comment='Foreign key referencing public.norms(id) (nullable). Identifies the governing compendial norm or pharmacopeia from which this SOP is derived.')

    norm: Mapped[Optional['Norms']] = relationship('Norms', back_populates='sops')
    sop_versions: Mapped[list['SopVersions']] = relationship('SopVersions', back_populates='sop')
    tests: Mapped[list['Tests']] = relationship('Tests', back_populates='sop')


class ControlCodes(Base):
    __tablename__ = 'control_codes'
    __table_args__ = (
        ForeignKeyConstraint(['material_id'], ['materials.id'], name='control_codes_material_id_fkey'),
        PrimaryKeyConstraint('id', name='control_codes_pkey'),
        UniqueConstraint('material_id', 'code', name='control_codes_material_id_code_key'),
        {'comment': 'Central batch/lot identification and inventory tracking table. '
                'Every physical batch of manufactured product, raw material '
                'delivery, purchased reagent lot, or in-house prepared reagent is '
                'assigned a unique control code linked to its material. Serves as '
                'the primary traceability anchor across sample receptions, testing '
                'worksheets, quality certificates, and reagent genealogy.'}
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True, comment='Primary key. Unique 64-bit integer identifier for the control code record.')
    material_id: Mapped[int] = mapped_column(BigInteger, nullable=False, comment='Foreign key referencing public.materials(id). The specific material, chemical, or product to which this batch/lot belongs.')
    code: Mapped[str] = mapped_column(String(50), nullable=False, comment='Alphanumeric batch/control code string (up to 50 characters). Unique per material. Must contain no whitespace (enforced by regex /^\\S*$/). In sample reception dialogs (CertificationDialog, VerificationDialog), users can select an existing control code or enter a new one, which is verified for uniqueness against the selected material via UniquenessChecker.')
    is_reception_received: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Boolean status flag. Automatically updated from false to true when any sample reception referencing this control code is accepted into the laboratory (ReceptionsService.ReceiveReception). Signals that physical samples of this batch have been received in the lab.')
    date_created: Mapped[datetime.datetime] = mapped_column(DateTime(True), nullable=False, server_default=text('clock_timestamp()'), comment='Timestamp with time zone when the control code was generated. Defaults to clock_timestamp().')

    material: Mapped['Materials'] = relationship('Materials', back_populates='control_codes')
    certificates: Mapped[list['Certificates']] = relationship('Certificates', back_populates='control_code')
    receptions: Mapped[list['Receptions']] = relationship('Receptions', back_populates='control_code')


class EquipmentCalibrations(Base):
    __tablename__ = 'equipment_calibrations'
    __table_args__ = (
        ForeignKeyConstraint(['equipment_id'], ['equipments.id'], ondelete='CASCADE', name='equipment_calibrations_equipment_id_fkey'),
        ForeignKeyConstraint(['status_id'], ['equipment_calibration_statuses.id'], name='equipment_calibrations_status_id_fkey'),
        PrimaryKeyConstraint('id', name='equipment_calibrations_pkey'),
        {'comment': 'Historical calibration log and certificate registry for '
                'laboratory instruments. Adding or updating a calibration '
                'certificate in EquipmentCalibrationDialog.tsx automatically '
                'propagates the expiration_date to equipments.next_calibration_due '
                "and restores the instrument status to 'Active'."}
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True, comment='Primary key. Unique 64-bit integer identifier for the calibration event.')
    equipment_id: Mapped[int] = mapped_column(BigInteger, nullable=False, comment='Foreign key referencing public.equipments(id). The laboratory instrument subjected to calibration.')
    calibration_date: Mapped[datetime.date] = mapped_column(Date, nullable=False, comment='Date when the physical calibration procedure was performed.')
    expiration_date: Mapped[datetime.date] = mapped_column(Date, nullable=False, comment='Date when this calibration certificate expires. Automatically updates equipments.next_calibration_due.')
    certificate_number: Mapped[str] = mapped_column(String(100), nullable=False, comment="Unique external or internal calibration certificate tracking number (maximum 100 characters, e.g., 'CAL-2026-09871').")
    calibrated_by: Mapped[str] = mapped_column(String(100), nullable=False, comment='Name of the accredited metrology calibration service provider or internal calibration technician (maximum 100 characters).')
    status_id: Mapped[int] = mapped_column(BigInteger, nullable=False, comment="Foreign key referencing public.equipment_calibration_statuses(id) (1='Pass', 2='Fail', 3='Limited Use').")
    date_created: Mapped[datetime.datetime] = mapped_column(DateTime(True), nullable=False, server_default=text('clock_timestamp()'), comment='Timestamp with time zone when the calibration record was logged into the system. Defaults to clock_timestamp().')
    reference_standards_used: Mapped[Optional[str]] = mapped_column(Text, comment='Text details of traceable reference standards (e.g., NIST-traceable weights, calibrated quartz cuvettes) utilized during the calibration.')
    expanded_uncertainty: Mapped[Optional[decimal.Decimal]] = mapped_column(Numeric, comment='Expanded measurement uncertainty of the calibration method itself (NUMERIC), as stated on the calibration certificate.')

    equipment: Mapped['Equipments'] = relationship('Equipments', back_populates='equipment_calibrations')
    status: Mapped['EquipmentCalibrationStatuses'] = relationship('EquipmentCalibrationStatuses', back_populates='equipment_calibrations')


class FormEvals(Base):
    __tablename__ = 'form_evals'
    __table_args__ = (
        ForeignKeyConstraint(['form_id'], ['forms.id'], ondelete='CASCADE', name='form_evals_form_id_fkey'),
        PrimaryKeyConstraint('id', name='form_evals_pkey'),
        {'comment': 'Validation benchmark test cases designed to prove the algorithmic '
                'accuracy of form formulas under 21 CFR Part 11 software '
                'verification rules. Before a form template can be validated '
                '(is_validated = true), all defined test cases must evaluate '
                'successfully without errors.'}
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True, comment='Primary key. Unique 64-bit integer identifier for the validation test case.')
    form_id: Mapped[int] = mapped_column(BigInteger, nullable=False, comment='Foreign key referencing public.forms(id). The form template being verified.')
    description: Mapped[Optional[str]] = mapped_column(Text, comment="Descriptive title or test scenario name (e.g., 'Nominal standard weight test case', 'Boundary condition - maximum LOD').")

    form: Mapped['Forms'] = relationship('Forms', back_populates='form_evals')
    form_eval_params: Mapped[list['FormEvalParams']] = relationship('FormEvalParams', back_populates='eval')


class SopVersions(Base):
    __tablename__ = 'sop_versions'
    __table_args__ = (
        ForeignKeyConstraint(['sop_id'], ['sops.id'], ondelete='CASCADE', name='sop_versions_sop_id_fkey'),
        PrimaryKeyConstraint('id', name='sop_versions_pkey'),
        UniqueConstraint('sop_id', 'version_number', name='unq_sop_version_number'),
        Index('unq_single_active_sop_version', 'sop_id', postgresql_where='(is_active = true)', unique=True),
        {'comment': 'Versioned document releases of Standard Operating Procedures '
                '(SOPs). Ensures compliance with document control guidelines by '
                'tracking active versus retired revisions and linking to external '
                'Electronic Document Management Systems (EDMS). Individual test '
                'measurements link to the exact sop_version_id in effect during '
                'execution.'}
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True, comment='Primary key. Unique 64-bit integer identifier for the SOP version revision.')
    sop_id: Mapped[int] = mapped_column(BigInteger, nullable=False, comment='Foreign key referencing public.sops(id). Identifies the parent SOP to which this revision belongs.')
    version_number: Mapped[str] = mapped_column(String(20), nullable=False, comment="Revision string (maximum 20 characters, e.g., '1.0', '2.3', 'Rev C'). Unique per parent SOP.")
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('true'), comment='Boolean flag indicating whether this specific SOP version is currently active and authorized for analytical testing. Worksheet sessions query active SOP versions for logging test execution methods.')
    date_activated: Mapped[datetime.datetime] = mapped_column(DateTime(True), nullable=False, server_default=text('clock_timestamp()'), comment='Timestamp with time zone when this SOP version was officially authorized and released into production. Defaults to clock_timestamp().')
    external_edms_id: Mapped[Optional[str]] = mapped_column(String(100), comment='External document management system identifier or hyperlink (maximum 100 characters) pointing to the controlled document PDF in the EDMS.')
    comments: Mapped[Optional[str]] = mapped_column(Text, comment='Change control summary or revision history notes describing the updates introduced in this version.')

    sop: Mapped['Sops'] = relationship('Sops', back_populates='sop_versions')
    measurement: Mapped[list['Measurements']] = relationship('Measurements', secondary='measurement_sop_versions', back_populates='sop_version')


class Specs(Base):
    __tablename__ = 'specs'
    __table_args__ = (
        ForeignKeyConstraint(['material_id'], ['materials.id'], name='specs_material_id_fkey'),
        ForeignKeyConstraint(['spec_replaced_id'], ['specs.id'], name='specs_spec_replaced_id_fkey'),
        ForeignKeyConstraint(['user_cancelled_id'], ['users.id'], name='specs_user_cancelled_id_fkey'),
        ForeignKeyConstraint(['user_submitted_id'], ['users.id'], name='specs_user_submitted_id_fkey'),
        PrimaryKeyConstraint('id', name='specs_pkey'),
        {'comment': 'Product and material quality specifications. Defines release '
                'limits, compendial monographs, and acceptance criteria used to '
                'judge whether manufactured batches or raw material deliveries '
                'conform to registered quality standards. Governed by formal '
                'submission, replacement/revision, and cancellation lifecycles '
                'with electronic signatures.'}
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True, comment='Primary key. Unique 64-bit integer identifier for the specification.')
    material_id: Mapped[int] = mapped_column(BigInteger, nullable=False, comment='Foreign key referencing public.materials(id). The material or product governed by this specification.')
    is_submitted: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Boolean status flag. True indicates the specification has been approved and activated for release testing. Only submitted and non-cancelled specifications are active for sample receptions and certificate generation.')
    is_cancelled: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Boolean status flag. True indicates this specification has been cancelled or retired.')
    user_submitted_id: Mapped[Optional[int]] = mapped_column(BigInteger, comment='Foreign key referencing public.users(id) (nullable). The QC authority who approved and submitted the specification.')
    date_submitted: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True), comment='Timestamp with time zone when the specification was officially activated.')
    comments_submitted: Mapped[Optional[str]] = mapped_column(Text, comment='Regulatory remarks, change control numbers, or justification recorded at submission.')
    spec_replaced_id: Mapped[Optional[int]] = mapped_column(BigInteger, comment='Foreign key referencing public.specs(id) (nullable). Points to the previous specification version that this new revision supersedes.')
    user_cancelled_id: Mapped[Optional[int]] = mapped_column(BigInteger, comment='Foreign key referencing public.users(id) (nullable). The user who cancelled the specification.')
    date_cancelled: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True), comment='Timestamp with time zone when the specification was cancelled.')
    comments_cancelled: Mapped[Optional[str]] = mapped_column(Text, comment='Mandatory documented explanation explaining why the specification was cancelled.')

    material: Mapped['Materials'] = relationship('Materials', back_populates='specs')
    spec_replaced: Mapped[Optional['Specs']] = relationship('Specs', remote_side=[id], back_populates='spec_replaced_reverse')
    spec_replaced_reverse: Mapped[list['Specs']] = relationship('Specs', remote_side=[spec_replaced_id], back_populates='spec_replaced')
    user_cancelled: Mapped[Optional['Users']] = relationship('Users', foreign_keys=[user_cancelled_id], back_populates='specs_user_cancelled')
    user_submitted: Mapped[Optional['Users']] = relationship('Users', foreign_keys=[user_submitted_id], back_populates='specs_user_submitted')
    certificates: Mapped[list['Certificates']] = relationship('Certificates', back_populates='spec')
    spec_tests: Mapped[list['SpecTests']] = relationship('SpecTests', back_populates='spec')
    spec_test_evals: Mapped[list['SpecTestEvals']] = relationship('SpecTestEvals', back_populates='spec')


class Tests(Base):
    __tablename__ = 'tests'
    __table_args__ = (
        ForeignKeyConstraint(['norm_id'], ['norms.id'], name='tests_norm_id_fkey'),
        ForeignKeyConstraint(['sop_id'], ['sops.id'], name='tests_sop_id_fkey'),
        ForeignKeyConstraint(['type_id'], ['value_types.id'], name='tests_value_type_id_fkey'),
        ForeignKeyConstraint(['unit_id'], ['units.id'], name='tests_unit_id_fkey'),
        PrimaryKeyConstraint('id', name='tests_pkey'),
        UniqueConstraint('code', name='tests_code_key'),
        {'comment': 'Master analytical test definition and calculation parameter '
                'dictionary. Defines physical, chemical, and biological tests, as '
                'well as intermediate variables used in formulas. Controls '
                'measurement data types, replicated array behavior, metrological '
                'uncertainty defaults, CRM requirements, norm/SOP method bindings, '
                'and validation immutability locks.'}
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True, comment='Primary key. Unique 64-bit integer identifier for the test/parameter definition.')
    name: Mapped[str] = mapped_column(String(50), nullable=False, comment="Unique descriptive name of the test (3 to 50 characters, e.g., 'Assay by HPLC', 'Loss on Drying', 'pH at 25░C'). Locked from editing if is_form_validated is true.")
    code: Mapped[str] = mapped_column(String(50), nullable=False, comment="Unique identifier token (2 to 50 characters) used as a mathematical variable in QC formulas (e.g., 'assay', 'lod_wt_loss', 'ph_val'). Must conform to regex /^(?!.*__)[a-zA-Z][a-zA-Z0-9_]*[a-zA-Z0-9]$/ (starts with letter, ends with alphanumeric, only alphanumeric and single underscores). Locked from editing if is_form_validated is true to maintain formula AST parsing validity.")
    type_id: Mapped[int] = mapped_column(BigInteger, nullable=False, comment='Foreign key referencing public.value_types(id). Specifies whether results are stored as integer (1), real (2), boolean (3), or enum (4). Locked from editing if is_form_validated is true.')
    is_array: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Boolean flag indicating whether the test yields multiple replicated measurement determinations (e.g., parallel injections, duplicate titrations) rather than a single scalar value. In formulas, arrays are referenced as [[code]]. In TestDialog.tsx, setting is_array to true automatically resets and disables for_certified_reference. Locked from editing if is_form_validated is true.')
    is_param: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Boolean flag designating this test as an intermediate calculation parameter or raw input (e.g. tare weight, sample mass, dilution factor) rather than a reportable specification test. In TestDialog.tsx, setting is_param to true resets and disables for_certification, for_environmental_control, and for_certified_reference. Locked from editing if is_form_validated is true.')
    for_environmental_control: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Boolean flag designating this test for cleanroom and environmental monitoring (e.g., ambient temperature, relative humidity, air particulates). In TestDialog.tsx, enabling this flag enforces mutual exclusivity by automatically resetting for_certification, for_certified_reference, and is_param to false.')
    for_certification: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Boolean flag indicating that this is a critical specification test that must be reported on official Quality Certificates / Certificates of Analysis (COA). In TestDialog.tsx, checking this box automatically defaults relative_uncertainty_pct to 3.00% and default_coverage_factor_k to 2.0 (if null/0), and resets for_environmental_control and is_param to false. Unchecking it resets uncertainty fields to NULL.')
    for_certified_reference: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Boolean flag enforcing strict metrological traceability. When true, during worksheet execution (SelectCrmDialog.tsx), the analyst cannot manually type an arbitrary numeric value; they must select an active, certified value from a Certified Reference Material (CRM) inventory lot or prior CRM certificate. In TestDialog.tsx, enabling this flag resets and disables is_array, is_param, and for_environmental_control.')
    is_form_validated: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Boolean validation lock. Automatically set to true by FormsService.ValidateForm when any form containing this test is validated and approved. Once true, the client UI disables and server rejects edits to test name, code, type_id, and is_array to guarantee that validated mathematical formulas and calculation ASTs do not become corrupt or broken.')
    nr_ord: Mapped[int] = mapped_column(BigInteger, nullable=False, server_default=text('0'), comment='Default numeric presentation and sorting order index (defaults to 0) used when displaying tests in tables and reports.')
    date_created: Mapped[datetime.datetime] = mapped_column(DateTime(True), nullable=False, comment='Timestamp with time zone when the test was originally registered.')
    is_obsolete: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Soft-deletion flag. Under GxP requirements, test definitions cannot be physically removed if referenced in historical worksheets, specifications, or certificates. When true, hides the test from new templates and specifications.')
    description: Mapped[Optional[str]] = mapped_column(Text, comment='Extended explanatory text describing the test scope, analytical principle, or sampling preparation.')
    relative_uncertainty_pct: Mapped[Optional[decimal.Decimal]] = mapped_column(Numeric(5, 2), comment='Expanded relative measurement uncertainty percentage (NUMERIC(5,2), e.g., 3.00 for ▒3.00%). Used by the reporting engine to calculate absolute expanded measurement uncertainty: U = (value * relative_uncertainty_pct / 100). Editable only when for_certification is true; automatically cleared to NULL when for_certification is false.')
    default_coverage_factor_k: Mapped[Optional[decimal.Decimal]] = mapped_column(Numeric(3, 1), comment='Default coverage factor k (NUMERIC(3,1), typically 2.0 corresponding to approximately 95% level of confidence under a normal distribution). Used in accordance with ISO/IEC 17025 and GUM (Guide to the Expression of Uncertainty in Measurement). Cleared to NULL when for_certification is false.')
    unit_id: Mapped[Optional[int]] = mapped_column(BigInteger, comment="Foreign key referencing public.units(id) (nullable). Identifies the default unit of measure associated with this test's results.")
    norm_id: Mapped[Optional[int]] = mapped_column(BigInteger, comment='Foreign key referencing public.norms(id) (nullable). Identifies the governing compendial standard. In TestDialog.tsx, selecting a norm filters available SOPs to those belonging to that norm, and clearing the norm resets norm_ref to NULL, sop_id to NULL, and empties the SOP list.')
    norm_ref: Mapped[Optional[str]] = mapped_column(String(50), comment="Textual citation (maximum 50 characters) identifying the exact clause, section, or monograph within the governing norm (e.g., 'Ph. Eur. 2.2.3', 'USP <621>'). Enabled in TestDialog.tsx only when norm_id is selected.")
    sop_id: Mapped[Optional[int]] = mapped_column(BigInteger, comment='Foreign key referencing public.sops(id) (nullable). Links the test definition to its approved operating procedure. Filtered by norm_id in the client UI.')
    date_form_validated: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True), comment='Timestamp with time zone when the test definition was locked following form validation approval.')
    date_obsolete: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True), comment='Timestamp with time zone when the test was decommissioned. Cleared to NULL if reactivated.')
    comments_obsolete: Mapped[Optional[str]] = mapped_column(Text, comment='Documented reason recorded when deactivating the test definition. Cleared to NULL if reactivated.')

    category: Mapped[list['Categories']] = relationship('Categories', secondary='category_tests', back_populates='test')
    equipment: Mapped[list['Equipments']] = relationship('Equipments', secondary='test_equipments', back_populates='test')
    materials_material_tests: Mapped[list['Materials']] = relationship('Materials', secondary='material_tests', back_populates='tests_material_tests')
    materials_test_reagents: Mapped[list['Materials']] = relationship('Materials', secondary='test_reagents', back_populates='tests_test_reagents')
    norm: Mapped[Optional['Norms']] = relationship('Norms', back_populates='tests')
    sop: Mapped[Optional['Sops']] = relationship('Sops', back_populates='tests')
    type: Mapped['ValueTypes'] = relationship('ValueTypes', back_populates='tests')
    unit: Mapped[Optional['Units']] = relationship('Units', back_populates='tests')
    form_params: Mapped[list['FormParams']] = relationship('FormParams', back_populates='test')
    reception: Mapped[list['Receptions']] = relationship('Receptions', secondary='reception_tests', back_populates='test')
    spec_tests: Mapped[list['SpecTests']] = relationship('SpecTests', back_populates='test')
    test_enums: Mapped[list['TestEnums']] = relationship('TestEnums', back_populates='test')
    form_condition_evals: Mapped[list['FormConditionEvals']] = relationship('FormConditionEvals', back_populates='test')
    form_eval_params: Mapped[list['FormEvalParams']] = relationship('FormEvalParams', back_populates='test')
    spec_test_evals: Mapped[list['SpecTestEvals']] = relationship('SpecTestEvals', back_populates='test')
    measurement_params: Mapped[list['MeasurementParams']] = relationship('MeasurementParams', back_populates='test')
    measurement_tests: Mapped[list['MeasurementTests']] = relationship('MeasurementTests', back_populates='test')
    reagent_supplier_lot_cert_tests: Mapped[list['ReagentSupplierLotCertTests']] = relationship('ReagentSupplierLotCertTests', back_populates='test')
    report_tests: Mapped[list['ReportTests']] = relationship('ReportTests', back_populates='test')
    certificate_tests: Mapped[list['CertificateTests']] = relationship('CertificateTests', back_populates='test')


t_category_tests = Table(
    'category_tests', Base.metadata,
    Column('category_id', BigInteger, primary_key=True, comment='Primary key and foreign key referencing public.categories(id). The material category receiving the test assignment.'),
    Column('test_id', BigInteger, primary_key=True, comment='Primary key and foreign key referencing public.tests(id). The analytical test assigned to the category.'),
    ForeignKeyConstraint(['category_id'], ['categories.id'], ondelete='CASCADE', name='category_tests_category_id_fkey'),
    ForeignKeyConstraint(['test_id'], ['tests.id'], name='category_tests_test_id_fkey'),
    PrimaryKeyConstraint('category_id', 'test_id', name='category_tests_pkey'),
    comment='Many-to-many junction table associating laboratory test definitions with material categories. Defines the standard battery of tests applicable to an entire category. When creating a Category Verification sample reception (CategoryVerificationDialog.tsx), selecting a category dynamically pre-populates the list of available tests from this table.'
)


class Certificates(Base):
    __tablename__ = 'certificates'
    __table_args__ = (
        ForeignKeyConstraint(['certificate_replaced_id'], ['certificates.id'], name='certificates_certificate_replaced_id_fkey'),
        ForeignKeyConstraint(['control_code_id'], ['control_codes.id'], name='certificates_control_code_id_fkey'),
        ForeignKeyConstraint(['spec_id'], ['specs.id'], name='certificates_specs_id_fkey'),
        ForeignKeyConstraint(['user_cancelled_id'], ['users.id'], name='certificates_user_cancelled_id_fkey'),
        ForeignKeyConstraint(['user_submitted_id'], ['users.id'], name='certificates_user_submitted_id_fkey'),
        PrimaryKeyConstraint('id', name='certificates_pkey'),
        {'comment': 'Official Quality Certificates / Certificates of Analysis (COA) '
                'issued for a manufactured batch or raw material lot '
                '(control_code_id). Evaluates laboratory test results against the '
                'active specification (spec_id). Computes both direct '
                'specification conformance and uncertainty guard-band conformance '
                '(ISO/IEC 17025 / ILAC-G8). Enforces 21 CFR Part 11 digital '
                'signatures on approval.'}
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True, comment='Primary key. Unique 64-bit integer identifier for the quality certificate.')
    control_code_id: Mapped[int] = mapped_column(BigInteger, nullable=False, comment='Foreign key referencing public.control_codes(id). The batch or inventory lot covered by this certificate.')
    spec_id: Mapped[int] = mapped_column(BigInteger, nullable=False, comment='Foreign key referencing public.specs(id). The active specification used to evaluate batch conformance.')
    is_conforming_spec: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Boolean conformance flag. True indicates that ALL required tests meet specification limits and no mandatory specification tests are missing. Calculated automatically by CertificatesService.CalculateAndSaveCertificateTests.')
    is_conforming_uncertainty: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('true'), comment='Boolean guard-band conformance flag implementing ISO/IEC 17025 / ILAC-G8 decision rules. True indicates that both the lower bound [value - U] and upper bound [value + U] fall within the specification acceptance range for all tests.')
    is_submitted: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Boolean status flag. True indicates the Quality Certificate has been formally approved and released with a 21 CFR Part 11 electronic signature.')
    is_cancelled: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Boolean status flag. True indicates the certificate was officially revoked or cancelled.')
    user_submitted_id: Mapped[Optional[int]] = mapped_column(BigInteger, comment='Foreign key referencing public.users(id) (nullable). The authorized QC manager / Qualified Person who signed and released the certificate.')
    date_submitted: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True), comment='Timestamp with time zone when the certificate was signed and released.')
    comments_submitted: Mapped[Optional[str]] = mapped_column(Text, comment='Quality assurance release disposition notes, authorized deviations, or release comments.')
    certificate_replaced_id: Mapped[Optional[int]] = mapped_column(BigInteger, comment='Foreign key referencing public.certificates(id) (nullable). Points to the previous certificate revision that this document supersedes.')
    user_cancelled_id: Mapped[Optional[int]] = mapped_column(BigInteger, comment='Foreign key referencing public.users(id) (nullable). The user who revoked the certificate.')
    date_cancelled: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True), comment='Timestamp with time zone when the certificate was cancelled.')
    comments_cancelled: Mapped[Optional[str]] = mapped_column(Text, comment='Mandatory documented justification explaining why the quality certificate was revoked.')

    certificate_replaced: Mapped[Optional['Certificates']] = relationship('Certificates', remote_side=[id], back_populates='certificate_replaced_reverse')
    certificate_replaced_reverse: Mapped[list['Certificates']] = relationship('Certificates', remote_side=[certificate_replaced_id], back_populates='certificate_replaced')
    control_code: Mapped['ControlCodes'] = relationship('ControlCodes', back_populates='certificates')
    spec: Mapped['Specs'] = relationship('Specs', back_populates='certificates')
    user_cancelled: Mapped[Optional['Users']] = relationship('Users', foreign_keys=[user_cancelled_id], back_populates='certificates_user_cancelled')
    user_submitted: Mapped[Optional['Users']] = relationship('Users', foreign_keys=[user_submitted_id], back_populates='certificates_user_submitted')
    measurement_params: Mapped[list['MeasurementParams']] = relationship('MeasurementParams', back_populates='certified_reference_certificate')
    certificate_tests: Mapped[list['CertificateTests']] = relationship('CertificateTests', back_populates='certificate')


class FormParams(Base):
    __tablename__ = 'form_params'
    __table_args__ = (
        ForeignKeyConstraint(['form_id'], ['forms.id'], ondelete='CASCADE', name='form_params_form_id_fkey'),
        ForeignKeyConstraint(['test_id'], ['tests.id'], name='form_params_test_id_fkey'),
        PrimaryKeyConstraint('form_id', 'test_id', name='form_params_pkey'),
        {'comment': 'Parameter definitions within a form template. Maps analytical '
                'tests (tests) into form fields as raw inputs or calculated '
                'formulas. Defines mathematical expressions evaluated by '
                'QCFormula, topological evaluation order (nr_ord_calc), array '
                'relationships, and conditional pass/fail criteria.'}
    )

    form_id: Mapped[int] = mapped_column(BigInteger, primary_key=True, comment='Primary key and foreign key referencing public.forms(id). The parent form template.')
    test_id: Mapped[int] = mapped_column(BigInteger, primary_key=True, comment='Primary key and foreign key referencing public.tests(id). The analytical test or parameter mapped to this form field.')
    is_calculated: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Boolean flag indicating whether this parameter is derived via a mathematical formula (true) or entered as a manual raw measurement (false).')
    has_condition: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Boolean flag indicating that this parameter possesses an acceptance rule / condition. In FormParamDialog.tsx, when true, condition and condition_note are mandatory, and at least one condition evaluation verification test case is required.')
    is_required: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Boolean flag specifying whether a value for this parameter is strictly required before the worksheet can be completed.')
    nr_ord_calc: Mapped[int] = mapped_column(BigInteger, nullable=False, server_default=text('0'), comment='Topological calculation sequence order. Derived automatically by resolving the Directed Acyclic Graph (DAG) of formula dependencies. Formulas are evaluated strictly in ascending order of nr_ord_calc to guarantee all dependent inputs are calculated prior to consumption.')
    nr_ord: Mapped[int] = mapped_column(BigInteger, nullable=False, server_default=text('0'), comment='Visual display sequence order controlling the arrangement of parameter input rows in the user interface.')
    formula: Mapped[Optional[str]] = mapped_column(Text, comment="Mathematical expression evaluated by the QCFormula ANTLR engine (e.g., 'ROUND(([tare_plus_sample] - [tare_dry]) / [sample_mass] * 100, 4)'). References scalar parameters as [code] and array parameters as [[code]]. Mandatory if is_calculated is true.")
    formula_dependencies: Mapped[Optional[str]] = mapped_column(Text, comment='Extracted list of test variable codes upon which this formula depends. Populated automatically by the QCFormula dependency resolver.')
    code_related_arrays: Mapped[Optional[str]] = mapped_column(String(50), comment='Test code string (maximum 50 characters) identifying an associated array test if this calculation parameter aggregates or relates to array determinations.')
    condition: Mapped[Optional[str]] = mapped_column(String(255), comment="Boolean condition expression (maximum 255 characters, e.g., '[value] >= 95.0 && [value] <= 105.0'). Validated via FormsService.ValidateCondition.")
    condition_note: Mapped[Optional[str]] = mapped_column(String(150), comment="Human-readable specification note or warning text displayed if the condition is not met (maximum 150 characters, e.g., 'Between 95.0% and 105.0%').")
    default_value: Mapped[Optional[decimal.Decimal]] = mapped_column(Numeric, comment='Default preset numeric value (e.g., 1.000 for standard volume, or 0).')

    form: Mapped['Forms'] = relationship('Forms', back_populates='form_params')
    test: Mapped['Tests'] = relationship('Tests', back_populates='form_params')
    form_condition_evals: Mapped[list['FormConditionEvals']] = relationship('FormConditionEvals', back_populates='form_params')
    form_eval_params: Mapped[list['FormEvalParams']] = relationship('FormEvalParams', back_populates='form_params')
    measurement_params: Mapped[list['MeasurementParams']] = relationship('MeasurementParams', back_populates='form_params')


t_material_tests = Table(
    'material_tests', Base.metadata,
    Column('material_id', BigInteger, primary_key=True, comment='Primary key and foreign key referencing public.materials(id). The material to which the test is assigned.'),
    Column('test_id', BigInteger, primary_key=True, comment='Primary key and foreign key referencing public.tests(id). The analytical test eligible to be performed on the material.'),
    ForeignKeyConstraint(['material_id'], ['materials.id'], ondelete='CASCADE', name='material_tests_material_id_fkey'),
    ForeignKeyConstraint(['test_id'], ['tests.id'], name='material_tests_test_id_fkey'),
    PrimaryKeyConstraint('material_id', 'test_id', name='material_tests_pkey'),
    comment='Many-to-many junction table associating candidate analytical tests with a material. Represents the universe of tests that can be configured on specifications or performed on samples of this material. Restricted to non-parameter tests (is_param = false).'
)


class ReagentLots(ControlCodes):
    __tablename__ = 'reagent_lots'
    __table_args__ = (
        ForeignKeyConstraint(['control_code_id'], ['control_codes.id'], name='reagent_lots_control_code_id_fkey'),
        ForeignKeyConstraint(['produced_by_user_id'], ['users.id'], name='reagent_lots_produced_by_user_id_fkey'),
        ForeignKeyConstraint(['status_id'], ['reagent_lot_statuses.id'], name='reagent_lots_status_id_fkey'),
        ForeignKeyConstraint(['unit_id'], ['units.id'], name='reagent_lots_unit_id_fkey'),
        PrimaryKeyConstraint('control_code_id', name='reagent_lots_pkey'),
        {'comment': 'Core inventory table tracking physical containers and batches of '
                'chemical reagents, volumetric solutions, and standards in the '
                'laboratory. Each lot is identified by a control_code_id. '
                'Differentiates purchased vendor lots from in-house prepared '
                'solutions (is_produced). Enforces expiration date controls and '
                'stock balances.'}
    )

    control_code_id: Mapped[int] = mapped_column(BigInteger, primary_key=True, comment='Primary key and foreign key referencing public.control_codes(id). Serves as the unique tracking lot identifier for this physical batch.')
    is_produced: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Boolean flag distinguishing in-house prepared reagents (true) from commercially purchased supplier lots (false). When true, produced_by_user_id and ingredient relationships in reagent_production_lots are enabled.')
    status_id: Mapped[int] = mapped_column(BigInteger, nullable=False, server_default=text('1'), comment="Foreign key referencing public.reagent_lot_statuses(id) (defaults to 1 = 'Quarantined'). Only lots in status 2 ('Active') can be selected as worksheet consumables or production ingredients.")
    quantity: Mapped[decimal.Decimal] = mapped_column(Numeric, nullable=False, comment='Numeric stock quantity remaining in inventory (e.g., 500.0). Enforced to be non-negative on the client and server.')
    expiration_date: Mapped[datetime.date] = mapped_column(Date, nullable=False, comment='Calendar date when the reagent lot expires. The system blocks using expired lots in analytical testing.')
    produced_by_user_id: Mapped[Optional[int]] = mapped_column(BigInteger, comment='Foreign key referencing public.users(id) (nullable). The laboratory analyst who formulated or prepared the reagent solution. Populated only when is_produced is true.')
    unit_id: Mapped[Optional[int]] = mapped_column(BigInteger, comment="Foreign key referencing public.units(id) (nullable). Specifies the unit of measurement for stock inventory (e.g., 'mL', 'g', 'L').")

    produced_by_user: Mapped[Optional['Users']] = relationship('Users', back_populates='reagent_lots')
    status: Mapped['ReagentLotStatuses'] = relationship('ReagentLotStatuses', back_populates='reagent_lots')
    unit: Mapped[Optional['Units']] = relationship('Units', back_populates='reagent_lots')
    ingredient_control_code: Mapped[list['ReagentLots']] = relationship('ReagentLots', secondary='reagent_production_lots', primaryjoin=lambda: ReagentLots.control_code_id == t_reagent_production_lots.c.control_code_id, secondaryjoin=lambda: ReagentLots.control_code_id == t_reagent_production_lots.c.ingredient_control_code_id, back_populates='control_code')
    control_code: Mapped[list['ReagentLots']] = relationship('ReagentLots', secondary='reagent_production_lots', primaryjoin=lambda: ReagentLots.control_code_id == t_reagent_production_lots.c.ingredient_control_code_id, secondaryjoin=lambda: ReagentLots.control_code_id == t_reagent_production_lots.c.control_code_id, back_populates='ingredient_control_code')
    measurement: Mapped[list['Measurements']] = relationship('Measurements', secondary='measurement_reagent_lots', back_populates='control_code')


class Receptions(Base):
    __tablename__ = 'receptions'
    __table_args__ = (
        ForeignKeyConstraint(['category_id'], ['categories.id'], name='receptions_category_id_fkey'),
        ForeignKeyConstraint(['control_code_id'], ['control_codes.id'], name='receptions_control_code_id_fkey'),
        ForeignKeyConstraint(['type_id'], ['reception_types.id'], name='receptions_reception_type_id_fkey'),
        ForeignKeyConstraint(['user_received_id'], ['users.id'], name='receptions_user_received_id_fkey'),
        ForeignKeyConstraint(['user_rejected_id'], ['users.id'], name='receptions_user_rejected_id_fkey'),
        ForeignKeyConstraint(['user_submitted_id'], ['users.id'], name='receptions_user_submitted_id_fkey'),
        PrimaryKeyConstraint('id', name='receptions_pkey'),
        {'comment': 'Laboratory sample intake, login, and chain-of-custody tracking '
                'table. Captures sample submission, laboratory physical receipt, '
                'or rejection. Drives subsequent measurement worksheet creation, '
                'testing report issuance, and certificate generation.'}
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True, comment='Primary key. Unique 64-bit integer identifier for the sample reception event.')
    type_id: Mapped[int] = mapped_column(BigInteger, nullable=False, comment='Foreign key referencing public.reception_types(id). Specifies whether this reception represents Certification (1), Verification (2), or Category Verification (3).')
    is_submitted: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Boolean status flag. True indicates the sample reception request has been formally submitted by sampling/production personnel.')
    is_received: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Boolean status flag. True indicates the laboratory has physically accepted the sample into custody. Setting this to true automatically marks control_codes.is_reception_received = true (ReceptionsService.ReceiveReception).')
    is_rejected: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Boolean status flag. True indicates the laboratory rejected the sample intake (e.g. broken seal, insufficient volume, incorrect storage temperature). A rejected reception cannot be received and requires a mandatory reason.')
    control_code_id: Mapped[Optional[int]] = mapped_column(BigInteger, comment='Foreign key referencing public.control_codes(id) (nullable). Identifies the physical batch/lot being sampled. Mandatory for Certification and Verification receptions; NULL for Category Verification receptions.')
    material_name: Mapped[Optional[str]] = mapped_column(String(50), comment='Free-text description of the sampled material (maximum 50 characters). Used exclusively for Category Verification receptions (type_id = 3) where the sample does not correspond to a formally registered catalog item in public.materials.')
    category_id: Mapped[Optional[int]] = mapped_column(BigInteger, comment='Foreign key referencing public.categories(id) (nullable). Classifies the sample under an established category for Category Verification receptions (type_id = 3). NULL for standard Certification and Verification receptions.')
    user_submitted_id: Mapped[Optional[int]] = mapped_column(BigInteger, comment='Foreign key referencing public.users(id) (nullable). The user who submitted the sample reception.')
    date_submitted: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True), comment='Timestamp with time zone when the sample reception was formally submitted.')
    comments_submitted: Mapped[Optional[str]] = mapped_column(Text, comment='Optional comments, delivery instructions, or sampling conditions noted by the submitter.')
    user_received_id: Mapped[Optional[int]] = mapped_column(BigInteger, comment='Foreign key referencing public.users(id) (nullable). The laboratory analyst who checked in and accepted the physical sample.')
    date_received: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True), comment='Timestamp with time zone when the laboratory physically received the sample.')
    comments_received: Mapped[Optional[str]] = mapped_column(Text, comment='Laboratory intake notes regarding sample integrity, packaging, seals, or temperature upon arrival.')
    user_rejected_id: Mapped[Optional[int]] = mapped_column(BigInteger, comment='Foreign key referencing public.users(id) (nullable). The laboratory user who executed the sample rejection.')
    date_rejected: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True), comment='Timestamp with time zone when the sample was rejected.')
    comments_rejected: Mapped[Optional[str]] = mapped_column(Text, comment='Mandatory documented justification explaining why the sample was rejected by the laboratory.')

    category: Mapped[Optional['Categories']] = relationship('Categories', back_populates='receptions')
    control_code: Mapped[Optional['ControlCodes']] = relationship('ControlCodes', back_populates='receptions')
    type: Mapped['ReceptionTypes'] = relationship('ReceptionTypes', back_populates='receptions')
    user_received: Mapped[Optional['Users']] = relationship('Users', foreign_keys=[user_received_id], back_populates='receptions_user_received')
    user_rejected: Mapped[Optional['Users']] = relationship('Users', foreign_keys=[user_rejected_id], back_populates='receptions_user_rejected')
    user_submitted: Mapped[Optional['Users']] = relationship('Users', foreign_keys=[user_submitted_id], back_populates='receptions_user_submitted')
    test: Mapped[list['Tests']] = relationship('Tests', secondary='reception_tests', back_populates='reception')
    measurements: Mapped[list['Measurements']] = relationship('Measurements', back_populates='reception')
    reports: Mapped[list['Reports']] = relationship('Reports', back_populates='reception')


class SpecTests(Base):
    __tablename__ = 'spec_tests'
    __table_args__ = (
        ForeignKeyConstraint(['spec_id'], ['specs.id'], ondelete='CASCADE', name='spec_tests_specs_id_fkey'),
        ForeignKeyConstraint(['test_id'], ['tests.id'], name='spec_tests_tests_id_fkey'),
        PrimaryKeyConstraint('spec_id', 'test_id', name='spec_tests_pkey'),
        {'comment': 'Acceptance limits and testing criteria for each analytical test '
                'within a specification. Encapsulates executable boolean condition '
                'formulas, human-readable specification notes, testing frequency, '
                'and ISO/IEC 17025 measurement uncertainty guard-band evaluation '
                'rules.'}
    )

    spec_id: Mapped[int] = mapped_column(BigInteger, primary_key=True, comment='Primary key and foreign key referencing public.specs(id). The parent specification.')
    test_id: Mapped[int] = mapped_column(BigInteger, primary_key=True, comment='Primary key and foreign key referencing public.tests(id). The analytical test evaluated under this specification.')
    condition: Mapped[str] = mapped_column(String(255), nullable=False, comment="Executable boolean expression string (maximum 255 characters, e.g., '[value] >= 98.0 && [value] <= 102.0', '[value] == 1'). Validated on blur in SpecTestDialog.tsx via SpecificationsService.ValidateCondition. Evaluated during certificate generation.")
    note: Mapped[str] = mapped_column(String(150), nullable=False, comment="Human-readable specification limit text (maximum 150 characters, e.g., '98.0% - 102.0%', 'Clear colorless liquid', 'NMT 0.5%'). Printed on analytical test reports and Quality Certificates.")
    use_uncertainty: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Boolean flag implementing ISO/IEC 17025 / ILAC-G8 decision rules. When true, certificate evaluation takes expanded measurement uncertainty into account by verifying that both the lower bound [value - U] and upper bound [value + U] satisfy the condition.')
    test_frequency: Mapped[int] = mapped_column(Integer, nullable=False, comment='Integer testing frequency rule (e.g., 1 indicates testing is performed on every batch; 5 indicates skip-lot testing every 5 batches).')

    spec: Mapped['Specs'] = relationship('Specs', back_populates='spec_tests')
    test: Mapped['Tests'] = relationship('Tests', back_populates='spec_tests')
    spec_test_evals: Mapped[list['SpecTestEvals']] = relationship('SpecTestEvals', back_populates='spec_tests')


class TestEnums(Base):
    __tablename__ = 'test_enums'
    __table_args__ = (
        ForeignKeyConstraint(['test_id'], ['tests.id'], ondelete='CASCADE', name='test_enums_test_id_fkey'),
        PrimaryKeyConstraint('test_id', 'value', name='test_enums_pkey'),
        UniqueConstraint('test_id', 'name', name='test_enums_test_id_name_key'),
        {'comment': 'Discrete lookup choice options for enum-type analytical tests '
                '(value_types.id = 4). When creating a new enum test in '
                'TestDialog.tsx, the analyst must supply at least two unique items '
                '(parsed from enumListString by newline, comma, or semicolon). '
                'Individual items can be added or edited via TestEnumDialog.tsx.'}
    )

    test_id: Mapped[int] = mapped_column(BigInteger, primary_key=True, comment='Primary key and foreign key referencing public.tests(id). The parent test to which this enumeration item belongs.')
    value: Mapped[int] = mapped_column(BigInteger, primary_key=True, comment="Primary key. Integer numeric code stored in measurement tables (measurement_tests.value, measurement_params.value) when this enum option is selected (e.g., 1 for 'Clear', 2 for 'Slightly Opalescent', 3 for 'Turbid').")
    name: Mapped[str] = mapped_column(String(50), nullable=False, comment="Human-readable display label (1 to 50 characters, e.g., 'Conforms', 'Positive', 'Clear colorless liquid') shown in dropdowns and printed on analytical certificates.")
    nr_ord: Mapped[int] = mapped_column(BigInteger, nullable=False, server_default=text('0'), comment='Numeric display order index (defaults to 0) controlling the sequence of options in client select menus.')
    is_obsolete: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Soft-deletion flag. When true, hides this enum option from future selection while preserving historical test result interpretation.')

    test: Mapped['Tests'] = relationship('Tests', back_populates='test_enums')


t_test_equipments = Table(
    'test_equipments', Base.metadata,
    Column('test_id', BigInteger, primary_key=True, comment='Primary key and foreign key referencing public.tests(id). The analytical test requiring instrument allocation.'),
    Column('equipment_id', BigInteger, primary_key=True, comment='Primary key and foreign key referencing public.equipments(id). The laboratory instrument authorized for executing this test.'),
    ForeignKeyConstraint(['equipment_id'], ['equipments.id'], name='test_equipments_equipment_id_fkey'),
    ForeignKeyConstraint(['test_id'], ['tests.id'], ondelete='CASCADE', name='test_equipments_test_id_fkey'),
    PrimaryKeyConstraint('test_id', 'equipment_id', name='test_equipments_pkey'),
    comment='Many-to-many junction table associating laboratory test definitions with required or default equipment models (equipments). When creating a measurement worksheet, tests automatically identify eligible instruments based on these assignments.'
)


t_test_reagents = Table(
    'test_reagents', Base.metadata,
    Column('test_id', BigInteger, primary_key=True, comment='Primary key and foreign key referencing public.tests(id). The analytical test that consumes the reagent.'),
    Column('material_id', BigInteger, primary_key=True, comment='Primary key and foreign key referencing public.materials(id). The chemical reagent material required for this test.'),
    ForeignKeyConstraint(['material_id'], ['materials.id'], name='test_reagents_material_id_fkey'),
    ForeignKeyConstraint(['test_id'], ['tests.id'], ondelete='CASCADE', name='test_reagents_test_id_fkey'),
    PrimaryKeyConstraint('test_id', 'material_id', name='test_reagents_pkey'),
    comment='Many-to-many junction table associating analytical tests with consumable chemical reagents or volumetric solutions (materials where is_reagent = true). Specifies which chemical reagents are consumed during test execution and drives reagent lot traceability on worksheets.'
)


class FormConditionEvals(Base):
    __tablename__ = 'form_condition_evals'
    __table_args__ = (
        ForeignKeyConstraint(['form_id', 'test_id'], ['form_params.form_id', 'form_params.test_id'], ondelete='CASCADE', name='form_condition_evals_form_id_test_id_fkey'),
        ForeignKeyConstraint(['form_id'], ['forms.id'], ondelete='CASCADE', name='form_condition_evals_form_id_fkey'),
        ForeignKeyConstraint(['test_id'], ['tests.id'], name='form_condition_evals_test_id_fkey'),
        PrimaryKeyConstraint('id', name='form_condition_evals_pkey'),
        {'comment': 'Benchmark test cases verifying parameter condition logic '
                '(form_params.condition). Validates that conditional acceptance '
                'rules correctly yield 1 (pass) or 0 (fail) against known test '
                'input values.'}
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True, comment='Primary key. Unique 64-bit integer identifier for the condition evaluation test row.')
    form_id: Mapped[int] = mapped_column(BigInteger, nullable=False, comment='Foreign key referencing public.forms(id). The parent form template.')
    test_id: Mapped[int] = mapped_column(BigInteger, nullable=False, comment='Foreign key referencing public.tests(id). The parameter whose condition is being verified.')
    value: Mapped[decimal.Decimal] = mapped_column(Numeric, nullable=False, comment='Test input value passed into the condition expression.')
    expected_result: Mapped[decimal.Decimal] = mapped_column(Numeric, nullable=False, comment='Expected outcome (1 for pass, 0 for fail) specified by the form author.')
    is_match: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Boolean flag. True indicates result matches expected_result.')
    result: Mapped[Optional[decimal.Decimal]] = mapped_column(Numeric, comment='Actual boolean outcome evaluated by the rule engine (1 for true/conforming, 0 for false/non-conforming).')
    note: Mapped[Optional[str]] = mapped_column(String(20), comment="Short explanation of the test condition boundary (maximum 20 characters, e.g., 'Upper limit', 'Nominal pass').")

    form_params: Mapped['FormParams'] = relationship('FormParams', back_populates='form_condition_evals')
    form: Mapped['Forms'] = relationship('Forms', back_populates='form_condition_evals')
    test: Mapped['Tests'] = relationship('Tests', back_populates='form_condition_evals')


class FormEvalParams(Base):
    __tablename__ = 'form_eval_params'
    __table_args__ = (
        ForeignKeyConstraint(['eval_id'], ['form_evals.id'], ondelete='CASCADE', name='form_eval_params_eval_id_fkey'),
        ForeignKeyConstraint(['form_id', 'test_id'], ['form_params.form_id', 'form_params.test_id'], ondelete='CASCADE', name='form_eval_params_form_id_test_id_fkey'),
        ForeignKeyConstraint(['form_id'], ['forms.id'], ondelete='CASCADE', name='form_eval_params_form_id_fkey'),
        ForeignKeyConstraint(['test_id'], ['tests.id'], name='form_eval_params_test_id_fkey'),
        PrimaryKeyConstraint('eval_id', 'form_id', 'test_id', 'idx', name='form_eval_params_pkey'),
        {'comment': 'Input variables and expected calculated outputs for form '
                'validation test cases (form_evals). During form verification, the '
                'QCFormula engine calculates the actual results for all formulas '
                'and compares them against expected_value. If all match, is_match '
                'is stamped true.'}
    )

    eval_id: Mapped[int] = mapped_column(BigInteger, primary_key=True, comment='Primary key and foreign key referencing public.form_evals(id). The parent validation test case.')
    form_id: Mapped[int] = mapped_column(BigInteger, primary_key=True, comment='Foreign key referencing public.forms(id). The form template.')
    test_id: Mapped[int] = mapped_column(BigInteger, primary_key=True, comment='Foreign key referencing public.tests(id). The parameter under test.')
    idx: Mapped[int] = mapped_column(Integer, primary_key=True, comment='Primary key. Array determination index (0 for scalar parameters, 0..N for replicated array values).')
    is_match: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Boolean verification flag. True indicates the calculated formula result matches expected_value within tolerance.')
    value: Mapped[Optional[decimal.Decimal]] = mapped_column(Numeric, comment='Input test value (for manual parameters) or engine-calculated result (for formula parameters).')
    expected_value: Mapped[Optional[decimal.Decimal]] = mapped_column(Numeric, comment='Authoritative pre-calculated benchmark value. Used to verify formula accuracy.')

    eval: Mapped['FormEvals'] = relationship('FormEvals', back_populates='form_eval_params')
    form_params: Mapped['FormParams'] = relationship('FormParams', back_populates='form_eval_params')
    form: Mapped['Forms'] = relationship('Forms', back_populates='form_eval_params')
    test: Mapped['Tests'] = relationship('Tests', back_populates='form_eval_params')


class Measurements(Base):
    __tablename__ = 'measurements'
    __table_args__ = (
        ForeignKeyConstraint(['form_id'], ['forms.id'], name='measurements_form_id_fkey'),
        ForeignKeyConstraint(['reception_id'], ['receptions.id'], name='measurements_reception_id_fkey'),
        ForeignKeyConstraint(['user_created_id'], ['users.id'], name='measurements_user_created_id_fkey'),
        ForeignKeyConstraint(['user_reported_id'], ['users.id'], name='measurements_user_reported_id_fkey'),
        ForeignKeyConstraint(['user_updated_id'], ['users.id'], name='measurements_user_updated_id_fkey'),
        PrimaryKeyConstraint('id', name='measurements_pkey'),
        {'comment': 'Laboratory testing worksheet execution sessions. Records raw '
                'observations, formula evaluations, and test results for a sample '
                'reception. Captures exact instrument serial numbers, chemical '
                'reagent lots, and SOP revisions used during execution. Enforces '
                'automatic read-only locking upon report inclusion or expiration '
                'of form editing days.'}
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True, comment='Primary key. Unique 64-bit integer identifier for the measurement worksheet session.')
    reception_id: Mapped[int] = mapped_column(BigInteger, nullable=False, comment='Foreign key referencing public.receptions(id). The sample reception being analyzed.')
    use_default_equipment: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('true'), comment='Boolean flag (defaults to true). When true, the worksheet utilizes the standard instruments defined in test_equipments; when false, analyst custom-selects specific instrument assets stored in measurement_equipments.')
    is_reported: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Boolean status flag. True indicates that the test results from this worksheet have been included into a formal submitted test report (reports). Prevents subsequent tampering with raw data.')
    is_readonly: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Boolean lock flag (defaults to false). Automatically set to true when results are reported or after forms.days_active_for_editing has elapsed. Locks all child measurement_tests and measurement_params from modification.')
    user_created_id: Mapped[int] = mapped_column(BigInteger, nullable=False, comment='Foreign key referencing public.users(id). The laboratory analyst who initiated the measurement worksheet.')
    date_created: Mapped[datetime.datetime] = mapped_column(DateTime(True), nullable=False, server_default=text('clock_timestamp()'), comment='Timestamp with time zone when the worksheet session was created. Defaults to clock_timestamp().')
    form_id: Mapped[Optional[int]] = mapped_column(BigInteger, comment='Foreign key referencing public.forms(id) (nullable). The structured dynamic form template used for executing calculations, if applicable.')
    comments: Mapped[Optional[str]] = mapped_column(Text, comment='Analyst bench notes, environmental conditions, or procedural observations recorded during worksheet execution.')
    user_reported_id: Mapped[Optional[int]] = mapped_column(BigInteger, comment='Foreign key referencing public.users(id) (nullable). The user who incorporated this measurement session into a test report.')
    date_reported: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True), comment='Timestamp with time zone when the results were reported.')
    date_readonly: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True), comment='Timestamp with time zone when the worksheet was transitioned to read-only status.')
    user_updated_id: Mapped[Optional[int]] = mapped_column(BigInteger, comment='Foreign key referencing public.users(id) (nullable). The user who performed the most recent edit.')
    date_updated: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True), comment='Timestamp with time zone of the most recent worksheet modification.')

    equipment: Mapped[list['Equipments']] = relationship('Equipments', secondary='measurement_equipments', back_populates='measurement')
    control_code: Mapped[list['ReagentLots']] = relationship('ReagentLots', secondary='measurement_reagent_lots', back_populates='measurement')
    form: Mapped[Optional['Forms']] = relationship('Forms', back_populates='measurements')
    reception: Mapped['Receptions'] = relationship('Receptions', back_populates='measurements')
    user_created: Mapped['Users'] = relationship('Users', foreign_keys=[user_created_id], back_populates='measurements_user_created')
    user_reported: Mapped[Optional['Users']] = relationship('Users', foreign_keys=[user_reported_id], back_populates='measurements_user_reported')
    user_updated: Mapped[Optional['Users']] = relationship('Users', foreign_keys=[user_updated_id], back_populates='measurements_user_updated')
    sop_version: Mapped[list['SopVersions']] = relationship('SopVersions', secondary='measurement_sop_versions', back_populates='measurement')
    measurement_params: Mapped[list['MeasurementParams']] = relationship('MeasurementParams', back_populates='measurement')
    measurement_tests: Mapped[list['MeasurementTests']] = relationship('MeasurementTests', back_populates='measurement')
    report_tests: Mapped[list['ReportTests']] = relationship('ReportTests', back_populates='measurement')
    certificate_tests: Mapped[list['CertificateTests']] = relationship('CertificateTests', back_populates='measurement')


t_reagent_production_lots = Table(
    'reagent_production_lots', Base.metadata,
    Column('control_code_id', BigInteger, primary_key=True, comment='Primary key and foreign key referencing public.control_codes(id). Identifies the newly prepared/produced child reagent lot.'),
    Column('ingredient_control_code_id', BigInteger, primary_key=True, comment='Primary key and foreign key referencing public.control_codes(id). Identifies an active parent reagent lot consumed as an ingredient.'),
    ForeignKeyConstraint(['control_code_id'], ['reagent_lots.control_code_id'], name='reagent_production_lots_control_code_id_fkey'),
    ForeignKeyConstraint(['ingredient_control_code_id'], ['reagent_lots.control_code_id'], name='reagent_production_lots_ingredient_control_code_id_fkey'),
    PrimaryKeyConstraint('control_code_id', 'ingredient_control_code_id', name='reagent_production_lots_pkey'),
    comment='Genealogy / Bill of Materials (BOM) junction table tracking internal laboratory reagent preparation. Associates an in-house produced reagent lot with the parent ingredient reagent lots consumed in its preparation. In ProductionLotDialog.tsx, circular dependencies (selecting the lot itself as an ingredient) are strictly prevented, and only active lots (status_id = 2) are eligible for selection.'
)


class ReagentSupplierLots(ReagentLots):
    __tablename__ = 'reagent_supplier_lots'
    __table_args__ = (
        ForeignKeyConstraint(['control_code_id'], ['reagent_lots.control_code_id'], name='reagent_supplier_lots_control_code_id_fkey'),
        ForeignKeyConstraint(['supplier_id'], ['reagent_suppliers.id'], name='reagent_supplier_lots_supplier_id_fkey'),
        PrimaryKeyConstraint('control_code_id', name='reagent_supplier_lots_pkey'),
        {'comment': 'Specialization table for commercially purchased reagent lots '
                '(reagent_lots where is_produced = false). Maintains manufacturer '
                'traceability, vendor catalog numbers, manufacturer batch numbers, '
                'and Certificate of Analysis (CoA) references. Locked into '
                'read-only mode once utilized in certified worksheets.'}
    )

    control_code_id: Mapped[int] = mapped_column(BigInteger, primary_key=True, comment='Primary key and foreign key referencing public.control_codes(id) (and implicitly public.reagent_lots). Unique lot identifier.')
    supplier_id: Mapped[int] = mapped_column(BigInteger, nullable=False, comment='Foreign key referencing public.reagent_suppliers(id). Identifies the vendor or manufacturer who supplied the batch. In SupplierLotDialog.tsx, user can either select an existing supplier or input a new one, which creates a new supplier record.')
    manufacturer_lot_number: Mapped[str] = mapped_column(String(50), nullable=False, comment='Original manufacturer production lot number printed on the container label (maximum 50 characters).')
    is_readonly: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Boolean lock flag (defaults to false). Automatically set to true when the lot is consumed in approved/submitted testing worksheets or quality certificates to guarantee immutable historical records.')
    catalog_number: Mapped[Optional[str]] = mapped_column(String(50), comment="Vendor catalog or product article number (maximum 50 characters, e.g., '1.00014.1000').")
    certificate_of_analysis_ref: Mapped[Optional[str]] = mapped_column(String(255), comment="Reference identifier, document number, or URL to the manufacturer's Certificate of Analysis (maximum 255 characters).")
    comments: Mapped[Optional[str]] = mapped_column(String(255), comment='Optional comments, container condition, or receiving notes (maximum 255 characters).')
    date_readonly: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True), comment='Timestamp with time zone when the record was locked against modifications.')

    supplier: Mapped['ReagentSuppliers'] = relationship('ReagentSuppliers', back_populates='reagent_supplier_lots')
    measurement_params: Mapped[list['MeasurementParams']] = relationship('MeasurementParams', back_populates='certified_reference_control_code')


t_reception_tests = Table(
    'reception_tests', Base.metadata,
    Column('reception_id', BigInteger, primary_key=True, comment='Primary key and foreign key referencing public.receptions(id). The sample reception receiving the test assignments.'),
    Column('test_id', BigInteger, primary_key=True, comment='Primary key and foreign key referencing public.tests(id). The analytical test scheduled to be performed on the sample.'),
    ForeignKeyConstraint(['reception_id'], ['receptions.id'], name='reception_tests_reception_id_fkey'),
    ForeignKeyConstraint(['test_id'], ['tests.id'], name='reception_tests_test_id_fkey'),
    PrimaryKeyConstraint('reception_id', 'test_id', name='reception_tests_pkey'),
    comment="Many-to-many junction table recording the analytical tests assigned to a specific sample reception. For Certification receptions, populated automatically with all active tests from the material's submitted specification; for Verification receptions, populated from user selection in VerificationDialog.tsx; for Category Verification, populated from category_tests in CategoryVerificationDialog.tsx."
)


class Reports(Base):
    __tablename__ = 'reports'
    __table_args__ = (
        ForeignKeyConstraint(['reception_id'], ['receptions.id'], name='reports_reception_id_fkey'),
        ForeignKeyConstraint(['report_replaced_id'], ['reports.id'], name='reports_report_replaced_id_fkey'),
        ForeignKeyConstraint(['user_cancelled_id'], ['users.id'], name='reports_user_cancelled_id_fkey'),
        ForeignKeyConstraint(['user_submitted_id'], ['users.id'], name='reports_user_submitted_id_fkey'),
        PrimaryKeyConstraint('id', name='reports_pkey'),
        {'comment': 'Formal analytical Testing Reports compiling completed laboratory '
                "measurements for a sample reception. Serves as the laboratory's "
                'technical release document before final quality certification. '
                'Governed by formal submission, revision/replacement, and '
                'cancellation lifecycles with electronic signatures.'}
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True, comment='Primary key. Unique 64-bit integer identifier for the testing report.')
    reception_id: Mapped[int] = mapped_column(BigInteger, nullable=False, comment='Foreign key referencing public.receptions(id). The sample reception for which this test report is generated.')
    is_submitted: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Boolean status flag. True indicates the test report has been formally signed and submitted by authorized lab personnel. Submitting a report automatically transitions underlying measurements to read-only status.')
    is_cancelled: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Boolean status flag. True indicates the report was officially invalidated or cancelled.')
    user_submitted_id: Mapped[Optional[int]] = mapped_column(BigInteger, comment='Foreign key referencing public.users(id) (nullable). The laboratory user who submitted the test report.')
    date_submitted: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True), comment='Timestamp with time zone when the test report was submitted.')
    comments_submitted: Mapped[Optional[str]] = mapped_column(Text, comment='Technical comments, summary of findings, or analytical caveats recorded at report submission.')
    report_replaced_id: Mapped[Optional[int]] = mapped_column(BigInteger, comment='Foreign key referencing public.reports(id) (nullable). Points to the earlier report revision that this report replaces / amends.')
    user_cancelled_id: Mapped[Optional[int]] = mapped_column(BigInteger, comment='Foreign key referencing public.users(id) (nullable). The user who cancelled the test report.')
    date_cancelled: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True), comment='Timestamp with time zone when the report was cancelled.')
    comments_cancelled: Mapped[Optional[str]] = mapped_column(Text, comment='Mandatory documented justification explaining why the test report was cancelled.')

    reception: Mapped['Receptions'] = relationship('Receptions', back_populates='reports')
    report_replaced: Mapped[Optional['Reports']] = relationship('Reports', remote_side=[id], back_populates='report_replaced_reverse')
    report_replaced_reverse: Mapped[list['Reports']] = relationship('Reports', remote_side=[report_replaced_id], back_populates='report_replaced')
    user_cancelled: Mapped[Optional['Users']] = relationship('Users', foreign_keys=[user_cancelled_id], back_populates='reports_user_cancelled')
    user_submitted: Mapped[Optional['Users']] = relationship('Users', foreign_keys=[user_submitted_id], back_populates='reports_user_submitted')
    report_tests: Mapped[list['ReportTests']] = relationship('ReportTests', back_populates='report')
    certificate_tests: Mapped[list['CertificateTests']] = relationship('CertificateTests', back_populates='report')


class SpecTestEvals(Base):
    __tablename__ = 'spec_test_evals'
    __table_args__ = (
        ForeignKeyConstraint(['spec_id', 'test_id'], ['spec_tests.spec_id', 'spec_tests.test_id'], ondelete='CASCADE', name='spec_test_evals_spec_id_test_id_fkey'),
        ForeignKeyConstraint(['spec_id'], ['specs.id'], name='spec_test_evals_spec_id_fkey'),
        ForeignKeyConstraint(['test_id'], ['tests.id'], name='spec_test_evals_test_id_fkey'),
        PrimaryKeyConstraint('id', name='spec_test_evals_pkey'),
        {'comment': 'Verification benchmark test cases for specification test '
                'conditions (spec_tests.condition). In SpecTestDialog.tsx, authors '
                'define test values and expected results (1=pass, 0=fail). The '
                'backend recalculates and verifies all cases to guarantee formula '
                'correctness before specification activation.'}
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True, comment='Primary key. Unique 64-bit integer identifier for the evaluation test row.')
    spec_id: Mapped[int] = mapped_column(BigInteger, nullable=False, comment='Foreign key referencing public.specs(id). The parent specification.')
    test_id: Mapped[int] = mapped_column(BigInteger, nullable=False, comment='Foreign key referencing public.tests(id). The test being verified.')
    value: Mapped[decimal.Decimal] = mapped_column(Numeric, nullable=False, comment='Test input value passed into the specification condition expression.')
    expected_result: Mapped[decimal.Decimal] = mapped_column(Numeric, nullable=False, comment='Expected outcome (1 for pass, 0 for fail) defined by the specification author.')
    is_match: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Boolean flag. True indicates result matches expected_result.')
    result: Mapped[Optional[decimal.Decimal]] = mapped_column(Numeric, comment='Actual boolean result evaluated by the rule engine (1 for conforming, 0 for non-conforming).')
    note: Mapped[Optional[str]] = mapped_column(String(20), comment="Short descriptive note explaining the test scenario (maximum 20 characters, e.g., 'Lower limit fail', 'Target pass').")

    spec_tests: Mapped['SpecTests'] = relationship('SpecTests', back_populates='spec_test_evals')
    spec: Mapped['Specs'] = relationship('Specs', back_populates='spec_test_evals')
    test: Mapped['Tests'] = relationship('Tests', back_populates='spec_test_evals')


t_measurement_equipments = Table(
    'measurement_equipments', Base.metadata,
    Column('measurement_id', BigInteger, primary_key=True, comment='Primary key and foreign key referencing public.measurements(id). The testing worksheet session.'),
    Column('equipment_id', BigInteger, primary_key=True, comment='Primary key and foreign key referencing public.equipments(id). The instrument utilized during the test.'),
    ForeignKeyConstraint(['equipment_id'], ['equipments.id'], name='measurement_equipments_equipment_id_fkey'),
    ForeignKeyConstraint(['measurement_id'], ['measurements.id'], ondelete='CASCADE', name='measurement_equipments_measurement_id_fkey'),
    PrimaryKeyConstraint('measurement_id', 'equipment_id', name='measurement_equipments_pkey'),
    comment='Many-to-many junction table logging the specific laboratory instruments and balances (equipments) utilized during a measurement worksheet session. Guarantees complete hardware traceability for ISO/IEC 17025 audits.'
)


class MeasurementParams(Base):
    __tablename__ = 'measurement_params'
    __table_args__ = (
        ForeignKeyConstraint(['certified_reference_certificate_id'], ['certificates.id'], name='measurement_params_certified_reference_certificate_id_fkey'),
        ForeignKeyConstraint(['certified_reference_control_code_id'], ['reagent_supplier_lots.control_code_id'], name='measurement_params_certified_reference_control_code_id_fkey'),
        ForeignKeyConstraint(['form_id', 'test_id'], ['form_params.form_id', 'form_params.test_id'], name='measurement_params_form_id_test_id_fkey'),
        ForeignKeyConstraint(['form_id'], ['forms.id'], name='measurement_params_form_id_fkey'),
        ForeignKeyConstraint(['measurement_id'], ['measurements.id'], ondelete='CASCADE', name='measurement_params_measurement_id_fkey'),
        ForeignKeyConstraint(['test_id'], ['tests.id'], name='measurement_params_test_id_fkey'),
        ForeignKeyConstraint(['user_created_id'], ['users.id'], name='measurement_params_user_created_id_fkey'),
        ForeignKeyConstraint(['user_updated_id'], ['users.id'], name='measurement_params_user_updated_id_fkey'),
        PrimaryKeyConstraint('measurement_id', 'form_id', 'test_id', 'idx', name='measurement_params_pkey'),
        {'comment': 'Intermediate calculation variables and raw parameter inputs '
                'captured during dynamic form worksheet execution. Maintains '
                'parameter-level acceptance status (is_conforming_condition) and '
                'metrological links to Certified Reference Materials (CRMs).'}
    )

    measurement_id: Mapped[int] = mapped_column(BigInteger, primary_key=True, comment='Primary key and foreign key referencing public.measurements(id). The parent worksheet session.')
    form_id: Mapped[int] = mapped_column(BigInteger, primary_key=True, comment='Primary key and foreign key referencing public.forms(id). The active form template.')
    test_id: Mapped[int] = mapped_column(BigInteger, primary_key=True, comment='Primary key and foreign key referencing public.tests(id). The specific parameter test definition.')
    idx: Mapped[int] = mapped_column(Integer, primary_key=True, server_default=text('0'), comment='Primary key. Array determination index (0 for scalar parameters, 0..N for array inputs).')
    value: Mapped[decimal.Decimal] = mapped_column(Numeric, nullable=False, comment='Input raw measurement value or formula-calculated intermediate result.')
    is_conforming_condition: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Boolean status flag. True indicates the parameter satisfies the conditional acceptance rule defined in form_params.condition.')
    user_created_id: Mapped[int] = mapped_column(BigInteger, nullable=False, comment='Foreign key referencing public.users(id). The user who originally recorded the parameter.')
    date_created: Mapped[datetime.datetime] = mapped_column(DateTime(True), nullable=False, server_default=text('clock_timestamp()'), comment='Timestamp with time zone when the parameter was created. Defaults to clock_timestamp().')
    certified_reference_certificate_id: Mapped[Optional[int]] = mapped_column(BigInteger, comment='Foreign key referencing public.certificates(id) (nullable). Populated when this parameter value is calibrated against or sourced from an internal Quality Certificate for a certified reference batch via SelectCrmDialog.tsx.')
    certified_reference_control_code_id: Mapped[Optional[int]] = mapped_column(BigInteger, comment='Foreign key referencing public.control_codes(id) (nullable). Populated when this parameter value is sourced from a supplier CRM reagent lot Certificate of Analysis (reagent_supplier_lot_cert_tests) via SelectCrmDialog.tsx.')
    user_updated_id: Mapped[Optional[int]] = mapped_column(BigInteger, comment='Foreign key referencing public.users(id) (nullable). The user who last edited this parameter value.')
    date_updated: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True), comment='Timestamp with time zone of the most recent parameter edit.')

    certified_reference_certificate: Mapped[Optional['Certificates']] = relationship('Certificates', back_populates='measurement_params')
    certified_reference_control_code: Mapped[Optional['ReagentSupplierLots']] = relationship('ReagentSupplierLots', back_populates='measurement_params')
    form_params: Mapped['FormParams'] = relationship('FormParams', back_populates='measurement_params')
    form: Mapped['Forms'] = relationship('Forms', back_populates='measurement_params')
    measurement: Mapped['Measurements'] = relationship('Measurements', back_populates='measurement_params')
    test: Mapped['Tests'] = relationship('Tests', back_populates='measurement_params')
    user_created: Mapped['Users'] = relationship('Users', foreign_keys=[user_created_id], back_populates='measurement_params_user_created')
    user_updated: Mapped[Optional['Users']] = relationship('Users', foreign_keys=[user_updated_id], back_populates='measurement_params_user_updated')


t_measurement_reagent_lots = Table(
    'measurement_reagent_lots', Base.metadata,
    Column('measurement_id', BigInteger, primary_key=True, comment='Primary key and foreign key referencing public.measurements(id). The testing worksheet session.'),
    Column('control_code_id', BigInteger, primary_key=True, comment='Primary key and foreign key referencing public.control_codes(id). The specific reagent lot consumed during testing.'),
    ForeignKeyConstraint(['control_code_id'], ['reagent_lots.control_code_id'], name='measurement_reagent_lots_control_code_id_fkey'),
    ForeignKeyConstraint(['measurement_id'], ['measurements.id'], ondelete='CASCADE', name='measurement_reagent_lots_measurement_id_fkey'),
    PrimaryKeyConstraint('measurement_id', 'control_code_id', name='measurement_reagent_lots_pkey'),
    comment='Many-to-many junction table recording the chemical reagent lots and volumetric solutions (control_codes) consumed during a measurement worksheet session. Guarantees chemical consumable traceability.'
)


t_measurement_sop_versions = Table(
    'measurement_sop_versions', Base.metadata,
    Column('measurement_id', BigInteger, primary_key=True, comment='Primary key and foreign key referencing public.measurements(id). The testing worksheet session.'),
    Column('sop_version_id', BigInteger, primary_key=True, comment='Primary key and foreign key referencing public.sop_versions(id). The active SOP revision utilized for the test execution.'),
    ForeignKeyConstraint(['measurement_id'], ['measurements.id'], ondelete='CASCADE', name='measurement_sop_versions_measurement_id_fkey'),
    ForeignKeyConstraint(['sop_version_id'], ['sop_versions.id'], name='measurement_sop_versions_sop_version_id_fkey'),
    PrimaryKeyConstraint('measurement_id', 'sop_version_id', name='measurement_sop_versions_pkey'),
    comment='Many-to-many junction table capturing the exact revisions of Standard Operating Procedures (sop_versions) followed by the analyst during execution of a measurement worksheet. Ensures procedural compliance traceability.'
)


class MeasurementTests(Base):
    __tablename__ = 'measurement_tests'
    __table_args__ = (
        ForeignKeyConstraint(['measurement_id'], ['measurements.id'], ondelete='CASCADE', name='measurement_tests_measurement_id_fkey'),
        ForeignKeyConstraint(['test_id'], ['tests.id'], name='measurement_tests_test_id_fkey'),
        ForeignKeyConstraint(['user_created_id'], ['users.id'], name='measurement_tests_user_created_id_fkey'),
        ForeignKeyConstraint(['user_updated_id'], ['users.id'], name='measurement_tests_user_updated_id_fkey'),
        PrimaryKeyConstraint('measurement_id', 'test_id', 'idx', name='measurement_tests_pkey'),
        {'comment': 'Final measured test results recorded during a worksheet session. '
                'Supports both scalar results (idx = 0) and multi-replicate array '
                'results (idx = 0..N). Serves as the raw data source for testing '
                'reports (report_tests) and quality certificates '
                '(certificate_tests).'}
    )

    measurement_id: Mapped[int] = mapped_column(BigInteger, primary_key=True, comment='Primary key and foreign key referencing public.measurements(id). The parent worksheet execution session.')
    test_id: Mapped[int] = mapped_column(BigInteger, primary_key=True, comment='Primary key and foreign key referencing public.tests(id). The analytical test whose result was determined.')
    idx: Mapped[int] = mapped_column(Integer, primary_key=True, server_default=text('0'), comment='Primary key. Numeric replicate index (0 for scalar tests, 0..N for replicated array determinations).')
    value: Mapped[decimal.Decimal] = mapped_column(Numeric, nullable=False, comment='The measured numerical result (or encoded enum key from test_enums). Captured via MeasurementTestDialog.tsx or auto-calculated from form parameters.')
    user_created_id: Mapped[int] = mapped_column(BigInteger, nullable=False, comment='Foreign key referencing public.users(id). The analyst who recorded the initial measurement.')
    date_created: Mapped[datetime.datetime] = mapped_column(DateTime(True), nullable=False, server_default=text('clock_timestamp()'), comment='Timestamp with time zone when the measurement was originally logged. Defaults to clock_timestamp().')
    note: Mapped[Optional[str]] = mapped_column(String(20), comment="Short analyst footnote or qualitative observation (maximum 20 characters, e.g., 'Re-injected', 'Outlier rejected').")
    user_updated_id: Mapped[Optional[int]] = mapped_column(BigInteger, comment='Foreign key referencing public.users(id) (nullable). The user who last updated this test value.')
    date_updated: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True), comment='Timestamp with time zone when this test value was last updated.')

    measurement: Mapped['Measurements'] = relationship('Measurements', back_populates='measurement_tests')
    test: Mapped['Tests'] = relationship('Tests', back_populates='measurement_tests')
    user_created: Mapped['Users'] = relationship('Users', foreign_keys=[user_created_id], back_populates='measurement_tests_user_created')
    user_updated: Mapped[Optional['Users']] = relationship('Users', foreign_keys=[user_updated_id], back_populates='measurement_tests_user_updated')


class ReagentSupplierLotCertTests(ReagentSupplierLots):
    __tablename__ = 'reagent_supplier_lot_cert_tests'
    __table_args__ = (
        ForeignKeyConstraint(['control_code_id'], ['reagent_supplier_lots.control_code_id'], name='reagent_supplier_lot_cert_tests_control_code_id_fkey'),
        ForeignKeyConstraint(['test_id'], ['tests.id'], name='reagent_supplier_lot_cert_tests_test_id_fkey'),
        PrimaryKeyConstraint('control_code_id', name='reagent_supplier_lot_cert_tests_pkey'),
        {'comment': 'Certified reference parameter values transcribed from '
                'manufacturer Certificates of Analysis (CoA) for Certified '
                'Reference Materials (CRMs). Enables strict metrological '
                'traceability under ISO 17034 and ISO/IEC 17025. When executing a '
                'worksheet with CRM-dependent parameters '
                '(tests.for_certified_reference = true), the analyst selects '
                'active values from this table via SelectCrmDialog.tsx.'}
    )

    control_code_id: Mapped[int] = mapped_column(BigInteger, primary_key=True, comment='Primary key and foreign key referencing public.control_codes(id). Identifies the supplier CRM reagent lot.')
    test_id: Mapped[int] = mapped_column(BigInteger, nullable=False, comment='Primary key and foreign key referencing public.tests(id). The analytical property or analyte certified on the supplier CoA.')
    value: Mapped[decimal.Decimal] = mapped_column(Numeric, nullable=False, comment='Certified reference numerical value stated on the manufacturer CoA (e.g., 99.98% purity, 0.1002 N titer).')
    uncertainty_value: Mapped[Optional[decimal.Decimal]] = mapped_column(Numeric, comment='Stated expanded measurement uncertainty U from the manufacturer certificate (e.g., 0.05).')
    coverage_factor_k: Mapped[Optional[decimal.Decimal]] = mapped_column(Numeric, comment='Coverage factor k stated on the certificate (typically 2.0 for approx. 95% confidence interval).')
    traceability_statement: Mapped[Optional[str]] = mapped_column(Text, comment="Formal metrological traceability text transcribed from the CoA (maximum 500 characters, e.g., 'Traceable to NIST SRM 84k').")

    test: Mapped['Tests'] = relationship('Tests', back_populates='reagent_supplier_lot_cert_tests')


class ReportTests(Base):
    __tablename__ = 'report_tests'
    __table_args__ = (
        ForeignKeyConstraint(['measurement_id'], ['measurements.id'], name='report_tests_measurement_id_fkey'),
        ForeignKeyConstraint(['report_id'], ['reports.id'], ondelete='CASCADE', name='report_tests_report_id_fkey'),
        ForeignKeyConstraint(['test_id'], ['tests.id'], name='report_tests_test_id_fkey'),
        PrimaryKeyConstraint('report_id', 'measurement_id', 'test_id', 'idx', name='report_tests_pkey'),
        {'comment': 'Analytical test results included in a formal testing report. '
                'Encapsulates measured values alongside calculated expanded '
                'measurement uncertainties (U) and coverage factors (k) in '
                'compliance with ISO/IEC 17025.'}
    )

    report_id: Mapped[int] = mapped_column(BigInteger, primary_key=True, comment='Primary key and foreign key referencing public.reports(id). The parent testing report.')
    measurement_id: Mapped[int] = mapped_column(BigInteger, primary_key=True, comment='Primary key and foreign key referencing public.measurements(id). The source worksheet from which the measurement was obtained.')
    test_id: Mapped[int] = mapped_column(BigInteger, primary_key=True, comment='Primary key and foreign key referencing public.tests(id). The analytical test evaluated.')
    idx: Mapped[int] = mapped_column(Integer, primary_key=True, server_default=text('0'), comment='Primary key. Determination replicate index (0 for scalar tests, 0..N for replicated arrays).')
    value: Mapped[decimal.Decimal] = mapped_column(Numeric, nullable=False, comment='Reported test value (numerical measurement or enum key).')
    uncertainty_value: Mapped[Optional[decimal.Decimal]] = mapped_column(Numeric, comment='Calculated expanded measurement uncertainty U = (value * relative_uncertainty_pct / 100), as established in test definitions. Defines the boundary of the measurement result at approximately 95% confidence.')
    coverage_factor_k: Mapped[Optional[decimal.Decimal]] = mapped_column(Numeric, comment='Coverage factor k (typically 2.0) applied during uncertainty calculation.')

    measurement: Mapped['Measurements'] = relationship('Measurements', back_populates='report_tests')
    report: Mapped['Reports'] = relationship('Reports', back_populates='report_tests')
    test: Mapped['Tests'] = relationship('Tests', back_populates='report_tests')
    certificate_tests: Mapped[list['CertificateTests']] = relationship('CertificateTests', back_populates='report_tests')


class CertificateTests(Base):
    __tablename__ = 'certificate_tests'
    __table_args__ = (
        ForeignKeyConstraint(['certificate_id'], ['certificates.id'], ondelete='CASCADE', name='certificate_tests_certificates_id_fkey'),
        ForeignKeyConstraint(['measurement_id'], ['measurements.id'], name='certificate_tests_measurement_id_fkey'),
        ForeignKeyConstraint(['report_id', 'measurement_id', 'test_id', 'idx'], ['report_tests.report_id', 'report_tests.measurement_id', 'report_tests.test_id', 'report_tests.idx'], name='certificate_tests_report_id_measurement_id_test_id_idx_fkey'),
        ForeignKeyConstraint(['report_id'], ['reports.id'], name='certificate_tests_report_id_fkey'),
        ForeignKeyConstraint(['test_id'], ['tests.id'], name='certificate_tests_test_id_fkey'),
        PrimaryKeyConstraint('certificate_id', 'report_id', 'test_id', 'idx', 'measurement_id', name='certificate_tests_pkey'),
        {'comment': 'Line-item analytical test evaluations displayed on the Quality '
                'Certificate / Certificate of Analysis (COA). Contains evaluated '
                'test results, expanded uncertainty values, individual '
                'specification compliance flags (is_conforming_spec), guard-band '
                'compliance flags (is_conforming_uncertainty), and snapshots of '
                'specification limits (note_spec).'}
    )

    certificate_id: Mapped[int] = mapped_column(BigInteger, primary_key=True, comment='Primary key and foreign key referencing public.certificates(id). The parent quality certificate.')
    report_id: Mapped[int] = mapped_column(BigInteger, primary_key=True, comment='Primary key and foreign key referencing public.reports(id). The source test report providing the data.')
    measurement_id: Mapped[int] = mapped_column(BigInteger, primary_key=True, comment='Primary key and foreign key referencing public.measurements(id). The raw measurement session.')
    test_id: Mapped[int] = mapped_column(BigInteger, primary_key=True, comment='Primary key and foreign key referencing public.tests(id). The analytical test evaluated.')
    idx: Mapped[int] = mapped_column(Integer, primary_key=True, server_default=text('0'), comment='Primary key. Determination index (0 for scalar, 0..N for replicated arrays).')
    value: Mapped[decimal.Decimal] = mapped_column(Numeric, nullable=False, comment='Certified analytical test result value.')
    is_conforming_spec: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'), comment='Boolean flag. Evaluated by executing the specification condition formula (spec_tests.condition) against the measured value. True if value meets specification limits; false otherwise.')
    is_conforming_uncertainty: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('true'), comment='Boolean flag. Evaluated by checking whether both [value - uncertainty_value] AND [value + uncertainty_value] satisfy the specification condition formula. Enforces ILAC-G8 guard-banding rules for ISO/IEC 17025 accredited reporting.')
    note_spec: Mapped[str] = mapped_column(String(25), nullable=False, comment="Historical snapshot text of the specification acceptance criteria in effect at the time of certification (maximum 25 characters, e.g., '>= 98.0%', 'Clear liquid'). Preserves exact historical limits regardless of future spec revisions.")
    test_count: Mapped[int] = mapped_column(Integer, nullable=False, server_default=text('0'), comment='Integer count of determinations or replicates performed to establish this result (defaults to 0).')
    uncertainty_value: Mapped[Optional[decimal.Decimal]] = mapped_column(Numeric, comment='Expanded measurement uncertainty U associated with the certified result.')
    coverage_factor_k: Mapped[Optional[decimal.Decimal]] = mapped_column(Numeric, comment='Coverage factor k (typically 2.0) applied to the uncertainty estimate.')

    certificate: Mapped['Certificates'] = relationship('Certificates', back_populates='certificate_tests')
    measurement: Mapped['Measurements'] = relationship('Measurements', back_populates='certificate_tests')
    report_tests: Mapped['ReportTests'] = relationship('ReportTests', back_populates='certificate_tests')
    report: Mapped['Reports'] = relationship('Reports', back_populates='certificate_tests')
    test: Mapped['Tests'] = relationship('Tests', back_populates='certificate_tests')
