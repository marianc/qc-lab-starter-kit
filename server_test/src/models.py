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
        UniqueConstraint('name', name='categories_name_key')
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True)
    name: Mapped[str] = mapped_column(String(50), nullable=False)
    code: Mapped[str] = mapped_column(String(3), nullable=False)
    date_created: Mapped[datetime.datetime] = mapped_column(DateTime(True), nullable=False)
    is_obsolete: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    description: Mapped[Optional[str]] = mapped_column(Text)
    date_obsolete: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True))
    comments_obsolete: Mapped[Optional[str]] = mapped_column(Text)

    test: Mapped[list['Tests']] = relationship('Tests', secondary='category_tests', back_populates='category')
    receptions: Mapped[list['Receptions']] = relationship('Receptions', back_populates='category')


class Equipments(Base):
    __tablename__ = 'equipments'
    __table_args__ = (
        PrimaryKeyConstraint('id', name='equipment_pkey'),
        UniqueConstraint('equipment_code', name='equipment_equipment_code_key')
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True)
    equipment_code: Mapped[str] = mapped_column(String(50), nullable=False)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    serial_number: Mapped[str] = mapped_column(String(100), nullable=False)
    status: Mapped[str] = mapped_column(String(20), nullable=False, server_default=text("'Active'::character varying"))
    date_created: Mapped[datetime.datetime] = mapped_column(DateTime(True), nullable=False, server_default=text('clock_timestamp()'))
    manufacturer: Mapped[Optional[str]] = mapped_column(String(100))
    model: Mapped[Optional[str]] = mapped_column(String(100))
    location: Mapped[Optional[str]] = mapped_column(String(100))
    calibration_interval_days: Mapped[Optional[int]] = mapped_column(Integer, server_default=text('365'))
    next_calibration_due: Mapped[Optional[datetime.date]] = mapped_column(Date)

    test: Mapped[list['Tests']] = relationship('Tests', secondary='test_equipments', back_populates='equipment')
    measurement: Mapped[list['Measurements']] = relationship('Measurements', secondary='measurement_equipments', back_populates='equipment')
    equipment_calibrations: Mapped[list['EquipmentCalibrations']] = relationship('EquipmentCalibrations', back_populates='equipment')


class FormGroups(Base):
    __tablename__ = 'form_groups'
    __table_args__ = (
        PrimaryKeyConstraint('id', name='form_groups_pkey'),
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True)
    name: Mapped[str] = mapped_column(String(50), nullable=False)
    nr_ord: Mapped[int] = mapped_column(BigInteger, nullable=False, server_default=text('0'))
    is_form_validated: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    description: Mapped[Optional[str]] = mapped_column(Text)

    forms: Mapped[list['Forms']] = relationship('Forms', back_populates='form_group')


class Norms(Base):
    __tablename__ = 'norms'
    __table_args__ = (
        PrimaryKeyConstraint('id', name='norms_pkey'),
        UniqueConstraint('name', name='norms_name_key')
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True)
    name: Mapped[str] = mapped_column(String(50), nullable=False)
    date_created: Mapped[datetime.datetime] = mapped_column(DateTime(True), nullable=False)
    is_obsolete: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    description: Mapped[Optional[str]] = mapped_column(Text)
    date_obsolete: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True))
    comments_obsolete: Mapped[Optional[str]] = mapped_column(Text)

    materials: Mapped[list['Materials']] = relationship('Materials', back_populates='norm')
    sops: Mapped[list['Sops']] = relationship('Sops', back_populates='norm')
    tests: Mapped[list['Tests']] = relationship('Tests', back_populates='norm')


class ReagentLotStatuses(Base):
    __tablename__ = 'reagent_lot_statuses'
    __table_args__ = (
        PrimaryKeyConstraint('id', name='reagent_lot_statuses_pkey'),
        UniqueConstraint('name', name='reagent_lot_statuses_name_key')
    )

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    name: Mapped[str] = mapped_column(String(50), nullable=False)

    reagent_lots: Mapped[list['ReagentLots']] = relationship('ReagentLots', back_populates='status')


class ReceptionTypes(Base):
    __tablename__ = 'reception_types'
    __table_args__ = (
        PrimaryKeyConstraint('id', name='reception_types_pkey'),
    )

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    name: Mapped[str] = mapped_column(String(50), nullable=False)

    receptions: Mapped[list['Receptions']] = relationship('Receptions', back_populates='type')


class Units(Base):
    __tablename__ = 'units'
    __table_args__ = (
        PrimaryKeyConstraint('id', name='units_pkey'),
        UniqueConstraint('name', name='units_name_key')
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True)
    name: Mapped[str] = mapped_column(String(50), nullable=False)
    date_created: Mapped[datetime.datetime] = mapped_column(DateTime(True), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text)

    tests: Mapped[list['Tests']] = relationship('Tests', back_populates='unit')
    reagent_lots: Mapped[list['ReagentLots']] = relationship('ReagentLots', back_populates='unit')


class Users(Base):
    __tablename__ = 'users'
    __table_args__ = (
        PrimaryKeyConstraint('id', name='users_pkey'),
        UniqueConstraint('code', name='users_code_key'),
        UniqueConstraint('email', name='users_email_key'),
        UniqueConstraint('session_id', name='users_session_id_key'),
        UniqueConstraint('tag', name='users_tag_key')
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True)
    tag: Mapped[str] = mapped_column(String(12), nullable=False)
    code: Mapped[str] = mapped_column(String(3), nullable=False)
    email: Mapped[str] = mapped_column(String(50), nullable=False)
    is_admin: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    is_lab_pers: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    is_qc_pers: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    must_change_password: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    failed_login_attempts: Mapped[int] = mapped_column(Integer, nullable=False, server_default=text('0'))
    is_locked: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    date_created: Mapped[datetime.datetime] = mapped_column(DateTime(True), nullable=False)
    is_obsolete: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    first_name: Mapped[Optional[str]] = mapped_column(String(50))
    last_name: Mapped[Optional[str]] = mapped_column(String(50))
    password_hash: Mapped[Optional[str]] = mapped_column(Text)
    password_salt: Mapped[Optional[str]] = mapped_column(Text)
    date_password_changed: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True))
    lock_expiration: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True))
    session_id: Mapped[Optional[str]] = mapped_column(String(255))
    date_session_created: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True))
    date_session_expire: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True))
    refresh_token: Mapped[Optional[str]] = mapped_column(String)
    date_obsolete: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True))
    comments_obsolete: Mapped[Optional[str]] = mapped_column(Text)

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
    measurements_user_update: Mapped[list['Measurements']] = relationship('Measurements', foreign_keys='[Measurements.user_update_id]', back_populates='user_update')
    reports_user_cancelled: Mapped[list['Reports']] = relationship('Reports', foreign_keys='[Reports.user_cancelled_id]', back_populates='user_cancelled')
    reports_user_submitted: Mapped[list['Reports']] = relationship('Reports', foreign_keys='[Reports.user_submitted_id]', back_populates='user_submitted')


class ValueTypes(Base):
    __tablename__ = 'value_types'
    __table_args__ = (
        PrimaryKeyConstraint('id', name='value_types_pkey'),
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True)
    name: Mapped[str] = mapped_column(String(50), nullable=False)

    tests: Mapped[list['Tests']] = relationship('Tests', back_populates='type')


class AuditLogs(Base):
    __tablename__ = 'audit_logs'
    __table_args__ = (
        ForeignKeyConstraint(['user_id'], ['users.id'], name='audit_logs_user_id_fkey'),
        PrimaryKeyConstraint('id', name='audit_logs_pkey')
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True)
    table_name: Mapped[str] = mapped_column(String(100), nullable=False)
    action: Mapped[str] = mapped_column(String(10), nullable=False)
    user_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    timestamp: Mapped[datetime.datetime] = mapped_column(DateTime(True), nullable=False, server_default=text('clock_timestamp()'))
    record_keys: Mapped[Optional[dict]] = mapped_column(JSONB)
    old_data: Mapped[Optional[dict]] = mapped_column(JSONB)
    new_data: Mapped[Optional[dict]] = mapped_column(JSONB)
    changed_fields: Mapped[Optional[list[str]]] = mapped_column(ARRAY(Text()))
    reason_for_change: Mapped[Optional[str]] = mapped_column(Text)
    client_ip: Mapped[Optional[str]] = mapped_column(String(45))

    user: Mapped['Users'] = relationship('Users', back_populates='audit_logs')


class ElectronicSignatures(Base):
    __tablename__ = 'electronic_signatures'
    __table_args__ = (
        ForeignKeyConstraint(['signer_user_id'], ['users.id'], name='electronic_signatures_signer_user_id_fkey'),
        PrimaryKeyConstraint('id', name='electronic_signatures_pkey')
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True)
    version: Mapped[int] = mapped_column(BigInteger, nullable=False, server_default=text('1'))
    entity_name: Mapped[str] = mapped_column(String(50), nullable=False)
    entity_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    signer_user_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    signature_meaning: Mapped[str] = mapped_column(String(50), nullable=False)
    signing_timestamp: Mapped[datetime.datetime] = mapped_column(DateTime(True), nullable=False, server_default=text('clock_timestamp()'))
    payload_sha256: Mapped[str] = mapped_column(String(64), nullable=False)
    signature_manifest_text: Mapped[str] = mapped_column(Text, nullable=False)
    client_ip: Mapped[str] = mapped_column(String(45), nullable=False)

    signer_user: Mapped['Users'] = relationship('Users', back_populates='electronic_signatures')


class EquipmentCalibrations(Base):
    __tablename__ = 'equipment_calibrations'
    __table_args__ = (
        ForeignKeyConstraint(['equipment_id'], ['equipments.id'], name='equipment_calibrations_equipment_id_fkey'),
        PrimaryKeyConstraint('id', name='equipment_calibrations_pkey')
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True)
    equipment_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    calibration_date: Mapped[datetime.date] = mapped_column(Date, nullable=False)
    expiration_date: Mapped[datetime.date] = mapped_column(Date, nullable=False)
    certificate_number: Mapped[str] = mapped_column(String(100), nullable=False)
    calibrated_by: Mapped[str] = mapped_column(String(100), nullable=False)
    result_status: Mapped[str] = mapped_column(String(20), nullable=False)
    date_created: Mapped[datetime.datetime] = mapped_column(DateTime(True), nullable=False, server_default=text('clock_timestamp()'))
    reference_standards_used: Mapped[Optional[str]] = mapped_column(Text)
    expanded_uncertainty: Mapped[Optional[decimal.Decimal]] = mapped_column(Numeric)

    equipment: Mapped['Equipments'] = relationship('Equipments', back_populates='equipment_calibrations')


class Forms(Base):
    __tablename__ = 'forms'
    __table_args__ = (
        ForeignKeyConstraint(['form_group_id'], ['form_groups.id'], name='forms_form_group_id_fkey'),
        ForeignKeyConstraint(['user_cancelled_id'], ['users.id'], name='forms_user_canceled_id_fkey'),
        ForeignKeyConstraint(['user_submitted_id'], ['users.id'], name='forms_user_submitted_id_fkey'),
        ForeignKeyConstraint(['user_validated_id'], ['users.id'], name='forms_user_validated_id_fkey'),
        PrimaryKeyConstraint('id', name='forms_pkey')
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True)
    form_group_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    version: Mapped[str] = mapped_column(String(50), nullable=False)
    is_customized: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    is_submitted: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    is_validated: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    is_cancelled: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    custom_nav: Mapped[Optional[str]] = mapped_column(Text)
    user_submitted_id: Mapped[Optional[int]] = mapped_column(BigInteger)
    date_submitted: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True))
    comments_submitted: Mapped[Optional[str]] = mapped_column(Text)
    user_validated_id: Mapped[Optional[int]] = mapped_column(BigInteger)
    date_validated: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True))
    comments_validated: Mapped[Optional[str]] = mapped_column(Text)
    user_cancelled_id: Mapped[Optional[int]] = mapped_column(BigInteger)
    date_cancelled: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True))
    comments_cancelled: Mapped[Optional[str]] = mapped_column(Text)

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
        UniqueConstraint('name', name='materials_name_key')
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True)
    name: Mapped[str] = mapped_column(String(50), nullable=False)
    code: Mapped[str] = mapped_column(String(5), nullable=False)
    is_product: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    is_raw_material: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    is_reagent: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    date_created: Mapped[datetime.datetime] = mapped_column(DateTime(True), nullable=False)
    is_obsolete: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    description: Mapped[Optional[str]] = mapped_column(Text)
    norm_id: Mapped[Optional[int]] = mapped_column(BigInteger)
    cas_number: Mapped[Optional[str]] = mapped_column(String(20))
    date_obsolete: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True))
    comments_obsolete: Mapped[Optional[str]] = mapped_column(Text)

    norm: Mapped[Optional['Norms']] = relationship('Norms', back_populates='materials')
    tests_material_tests: Mapped[list['Tests']] = relationship('Tests', secondary='material_tests', back_populates='materials_material_tests')
    tests_test_reagents: Mapped[list['Tests']] = relationship('Tests', secondary='test_reagents', back_populates='materials_test_reagents')
    control_codes: Mapped[list['ControlCodes']] = relationship('ControlCodes', back_populates='material')
    specs: Mapped[list['Specs']] = relationship('Specs', back_populates='material')


class Sops(Base):
    __tablename__ = 'sops'
    __table_args__ = (
        ForeignKeyConstraint(['norm_id'], ['norms.id'], name='sops_norm_id_fkey'),
        PrimaryKeyConstraint('id', name='sops_pkey'),
        UniqueConstraint('doc_code', name='sops_doc_code_key')
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True)
    doc_code: Mapped[str] = mapped_column(String(50), nullable=False)
    title: Mapped[str] = mapped_column(String(150), nullable=False)
    date_created: Mapped[datetime.datetime] = mapped_column(DateTime(True), nullable=False, server_default=text('clock_timestamp()'))
    norm_id: Mapped[Optional[int]] = mapped_column(BigInteger)

    norm: Mapped[Optional['Norms']] = relationship('Norms', back_populates='sops')
    sop_versions: Mapped[list['SopVersions']] = relationship('SopVersions', back_populates='sop')
    tests: Mapped[list['Tests']] = relationship('Tests', back_populates='sop')


class ControlCodes(Base):
    __tablename__ = 'control_codes'
    __table_args__ = (
        ForeignKeyConstraint(['material_id'], ['materials.id'], name='control_codes_material_id_fkey'),
        PrimaryKeyConstraint('id', name='control_codes_pkey')
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True)
    material_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    code: Mapped[str] = mapped_column(String(50), nullable=False)
    is_reception_received: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    date_created: Mapped[datetime.datetime] = mapped_column(DateTime(True), nullable=False, server_default=text('clock_timestamp()'))

    material: Mapped['Materials'] = relationship('Materials', back_populates='control_codes')
    certificates: Mapped[list['Certificates']] = relationship('Certificates', back_populates='control_code')
    receptions: Mapped[list['Receptions']] = relationship('Receptions', back_populates='control_code')


class FormEvals(Base):
    __tablename__ = 'form_evals'
    __table_args__ = (
        ForeignKeyConstraint(['form_id'], ['forms.id'], name='form_evals_form_id_fkey'),
        PrimaryKeyConstraint('id', name='form_evals_pkey')
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True)
    form_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text)

    form: Mapped['Forms'] = relationship('Forms', back_populates='form_evals')
    form_eval_params: Mapped[list['FormEvalParams']] = relationship('FormEvalParams', back_populates='eval')


class SopVersions(Base):
    __tablename__ = 'sop_versions'
    __table_args__ = (
        ForeignKeyConstraint(['sop_id'], ['sops.id'], name='sop_versions_sop_id_fkey'),
        PrimaryKeyConstraint('id', name='sop_versions_pkey'),
        UniqueConstraint('sop_id', 'version_number', name='unq_sop_version_number'),
        Index('unq_single_active_sop_version', 'sop_id', postgresql_where='(is_active = true)', unique=True)
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True)
    sop_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    version_number: Mapped[str] = mapped_column(String(20), nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('true'))
    date_activated: Mapped[datetime.datetime] = mapped_column(DateTime(True), nullable=False, server_default=text('clock_timestamp()'))
    external_edms_id: Mapped[Optional[str]] = mapped_column(String(100))
    comments: Mapped[Optional[str]] = mapped_column(Text)

    sop: Mapped['Sops'] = relationship('Sops', back_populates='sop_versions')
    measurement: Mapped[list['Measurements']] = relationship('Measurements', secondary='measurement_sop_versions', back_populates='sop_version')


class Specs(Base):
    __tablename__ = 'specs'
    __table_args__ = (
        ForeignKeyConstraint(['material_id'], ['materials.id'], name='specs_material_id_fkey'),
        ForeignKeyConstraint(['spec_replaced_id'], ['specs.id'], name='specs_spec_replaced_id_fkey'),
        ForeignKeyConstraint(['user_cancelled_id'], ['users.id'], name='specs_user_cancelled_id_fkey'),
        ForeignKeyConstraint(['user_submitted_id'], ['users.id'], name='specs_user_submitted_id_fkey'),
        PrimaryKeyConstraint('id', name='specs_pkey')
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True)
    material_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    is_submitted: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    is_cancelled: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    user_submitted_id: Mapped[Optional[int]] = mapped_column(BigInteger)
    date_submitted: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True))
    comments_submitted: Mapped[Optional[str]] = mapped_column(Text)
    spec_replaced_id: Mapped[Optional[int]] = mapped_column(BigInteger)
    user_cancelled_id: Mapped[Optional[int]] = mapped_column(BigInteger)
    date_cancelled: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True))
    comments_cancelled: Mapped[Optional[str]] = mapped_column(Text)

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
        UniqueConstraint('name', name='tests_name_key')
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True)
    name: Mapped[str] = mapped_column(String(50), nullable=False)
    code: Mapped[str] = mapped_column(String(50), nullable=False)
    type_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    is_array: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    is_param: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    for_environmental_control: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    for_certification: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    nr_ord: Mapped[int] = mapped_column(BigInteger, nullable=False, server_default=text('0'))
    is_form_validated: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    date_created: Mapped[datetime.datetime] = mapped_column(DateTime(True), nullable=False)
    is_obsolete: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    description: Mapped[Optional[str]] = mapped_column(Text)
    unit_id: Mapped[Optional[int]] = mapped_column(BigInteger)
    norm_id: Mapped[Optional[int]] = mapped_column(BigInteger)
    norm_ref: Mapped[Optional[str]] = mapped_column(String(50))
    sop_id: Mapped[Optional[int]] = mapped_column(BigInteger)
    relative_uncertainty_pct: Mapped[Optional[decimal.Decimal]] = mapped_column(Numeric(5, 2))
    default_coverage_factor_k: Mapped[Optional[decimal.Decimal]] = mapped_column(Numeric(3, 1))
    date_form_validated: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True))
    date_obsolete: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True))
    comments_obsolete: Mapped[Optional[str]] = mapped_column(Text)

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
    report_tests: Mapped[list['ReportTests']] = relationship('ReportTests', back_populates='test')
    certificate_tests: Mapped[list['CertificateTests']] = relationship('CertificateTests', back_populates='test')


t_category_tests = Table(
    'category_tests', Base.metadata,
    Column('category_id', BigInteger, primary_key=True),
    Column('test_id', BigInteger, primary_key=True),
    ForeignKeyConstraint(['category_id'], ['categories.id'], name='category_tests_category_id_fkey'),
    ForeignKeyConstraint(['test_id'], ['tests.id'], name='category_tests_test_id_fkey'),
    PrimaryKeyConstraint('category_id', 'test_id', name='category_tests_pkey')
)


class Certificates(Base):
    __tablename__ = 'certificates'
    __table_args__ = (
        ForeignKeyConstraint(['certificate_replaced_id'], ['certificates.id'], name='certificates_certificate_replaced_id_fkey'),
        ForeignKeyConstraint(['control_code_id'], ['control_codes.id'], name='certificates_control_code_id_fkey'),
        ForeignKeyConstraint(['spec_id'], ['specs.id'], name='certificates_specs_id_fkey'),
        ForeignKeyConstraint(['user_cancelled_id'], ['users.id'], name='certificates_user_cancelled_id_fkey'),
        ForeignKeyConstraint(['user_submitted_id'], ['users.id'], name='certificates_user_submitted_id_fkey'),
        PrimaryKeyConstraint('id', name='certificates_pkey')
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True)
    control_code_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    spec_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    is_conforming_spec: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    is_conforming_uncertainty: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('true'))
    is_submitted: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    is_cancelled: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    user_submitted_id: Mapped[Optional[int]] = mapped_column(BigInteger)
    date_submitted: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True))
    comments_submitted: Mapped[Optional[str]] = mapped_column(Text)
    certificate_replaced_id: Mapped[Optional[int]] = mapped_column(BigInteger)
    user_cancelled_id: Mapped[Optional[int]] = mapped_column(BigInteger)
    date_cancelled: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True))
    comments_cancelled: Mapped[Optional[str]] = mapped_column(Text)

    certificate_replaced: Mapped[Optional['Certificates']] = relationship('Certificates', remote_side=[id], back_populates='certificate_replaced_reverse')
    certificate_replaced_reverse: Mapped[list['Certificates']] = relationship('Certificates', remote_side=[certificate_replaced_id], back_populates='certificate_replaced')
    control_code: Mapped['ControlCodes'] = relationship('ControlCodes', back_populates='certificates')
    spec: Mapped['Specs'] = relationship('Specs', back_populates='certificates')
    user_cancelled: Mapped[Optional['Users']] = relationship('Users', foreign_keys=[user_cancelled_id], back_populates='certificates_user_cancelled')
    user_submitted: Mapped[Optional['Users']] = relationship('Users', foreign_keys=[user_submitted_id], back_populates='certificates_user_submitted')
    certificate_tests: Mapped[list['CertificateTests']] = relationship('CertificateTests', back_populates='certificate')


class FormParams(Base):
    __tablename__ = 'form_params'
    __table_args__ = (
        ForeignKeyConstraint(['form_id'], ['forms.id'], name='form_params_form_id_fkey'),
        ForeignKeyConstraint(['test_id'], ['tests.id'], name='form_params_test_id_fkey'),
        PrimaryKeyConstraint('form_id', 'test_id', name='form_params_pkey')
    )

    form_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    test_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    is_calculated: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    has_condition: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    is_required: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    nr_ord: Mapped[int] = mapped_column(BigInteger, nullable=False, server_default=text('0'))
    nr_ord_calc: Mapped[int] = mapped_column(BigInteger, nullable=False, server_default=text('0'))
    formula: Mapped[Optional[str]] = mapped_column(Text)
    formula_dependencies: Mapped[Optional[str]] = mapped_column(Text)
    code_related_arrays: Mapped[Optional[str]] = mapped_column(String(50))
    condition: Mapped[Optional[str]] = mapped_column(String(255))
    condition_note: Mapped[Optional[str]] = mapped_column(String(150))
    default_value: Mapped[Optional[decimal.Decimal]] = mapped_column(Numeric)

    form: Mapped['Forms'] = relationship('Forms', back_populates='form_params')
    test: Mapped['Tests'] = relationship('Tests', back_populates='form_params')
    form_condition_evals: Mapped[list['FormConditionEvals']] = relationship('FormConditionEvals', back_populates='form_params')
    form_eval_params: Mapped[list['FormEvalParams']] = relationship('FormEvalParams', back_populates='form_params')
    measurement_params: Mapped[list['MeasurementParams']] = relationship('MeasurementParams', back_populates='form_params')


t_material_tests = Table(
    'material_tests', Base.metadata,
    Column('material_id', BigInteger, primary_key=True),
    Column('test_id', BigInteger, primary_key=True),
    ForeignKeyConstraint(['material_id'], ['materials.id'], name='material_tests_material_id_fkey'),
    ForeignKeyConstraint(['test_id'], ['tests.id'], name='material_tests_test_id_fkey'),
    PrimaryKeyConstraint('material_id', 'test_id', name='material_tests_pkey')
)


class ReagentLots(ControlCodes):
    __tablename__ = 'reagent_lots'
    __table_args__ = (
        ForeignKeyConstraint(['control_code_id'], ['control_codes.id'], name='reagent_lots_control_code_id_fkey'),
        ForeignKeyConstraint(['produced_by_user_id'], ['users.id'], name='reagent_lots_produced_by_user_id_fkey'),
        ForeignKeyConstraint(['status_id'], ['reagent_lot_statuses.id'], name='reagent_lots_status_id_fkey'),
        ForeignKeyConstraint(['unit_id'], ['units.id'], name='reagent_lots_unit_id_fkey'),
        PrimaryKeyConstraint('control_code_id', name='reagent_lots_pkey')
    )

    control_code_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    is_produced: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    status_id: Mapped[int] = mapped_column(BigInteger, nullable=False, server_default=text('1'))
    quantity: Mapped[decimal.Decimal] = mapped_column(Numeric, nullable=False)
    expiration_date: Mapped[datetime.date] = mapped_column(Date, nullable=False)
    produced_by_user_id: Mapped[Optional[int]] = mapped_column(BigInteger)
    unit_id: Mapped[Optional[int]] = mapped_column(BigInteger)

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
        PrimaryKeyConstraint('id', name='receptions_pkey')
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True)
    type_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    is_submitted: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    is_received: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    is_rejected: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    control_code_id: Mapped[Optional[int]] = mapped_column(BigInteger)
    material_name: Mapped[Optional[str]] = mapped_column(String(50))
    category_id: Mapped[Optional[int]] = mapped_column(BigInteger)
    user_submitted_id: Mapped[Optional[int]] = mapped_column(BigInteger)
    date_submitted: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True))
    comments_submitted: Mapped[Optional[str]] = mapped_column(Text)
    user_received_id: Mapped[Optional[int]] = mapped_column(BigInteger)
    date_received: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True))
    comments_received: Mapped[Optional[str]] = mapped_column(Text)
    user_rejected_id: Mapped[Optional[int]] = mapped_column(BigInteger)
    date_rejected: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True))
    comments_rejected: Mapped[Optional[str]] = mapped_column(Text)

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
        ForeignKeyConstraint(['spec_id'], ['specs.id'], name='spec_tests_specs_id_fkey'),
        ForeignKeyConstraint(['test_id'], ['tests.id'], name='spec_tests_tests_id_fkey'),
        PrimaryKeyConstraint('spec_id', 'test_id', name='spec_tests_pkey')
    )

    spec_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    test_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    condition: Mapped[str] = mapped_column(String(255), nullable=False)
    note: Mapped[str] = mapped_column(String(150), nullable=False)
    use_uncertainty: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    test_frequency: Mapped[int] = mapped_column(Integer, nullable=False)

    spec: Mapped['Specs'] = relationship('Specs', back_populates='spec_tests')
    test: Mapped['Tests'] = relationship('Tests', back_populates='spec_tests')
    spec_test_evals: Mapped[list['SpecTestEvals']] = relationship('SpecTestEvals', back_populates='spec_tests')


class TestEnums(Base):
    __tablename__ = 'test_enums'
    __table_args__ = (
        ForeignKeyConstraint(['test_id'], ['tests.id'], name='test_enums_test_id_fkey'),
        PrimaryKeyConstraint('test_id', 'value', name='test_enums_pkey'),
        UniqueConstraint('test_id', 'name', name='test_enums_test_id_name_key')
    )

    test_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    value: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    name: Mapped[str] = mapped_column(String(50), nullable=False)
    nr_ord: Mapped[int] = mapped_column(BigInteger, nullable=False, server_default=text('0'))
    is_obsolete: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))

    test: Mapped['Tests'] = relationship('Tests', back_populates='test_enums')


t_test_equipments = Table(
    'test_equipments', Base.metadata,
    Column('test_id', BigInteger, primary_key=True),
    Column('equipment_id', BigInteger, primary_key=True),
    ForeignKeyConstraint(['equipment_id'], ['equipments.id'], name='test_equipments_equipment_id_fkey'),
    ForeignKeyConstraint(['test_id'], ['tests.id'], name='test_equipments_test_id_fkey'),
    PrimaryKeyConstraint('test_id', 'equipment_id', name='test_equipments_pkey')
)


t_test_reagents = Table(
    'test_reagents', Base.metadata,
    Column('test_id', BigInteger, primary_key=True),
    Column('material_id', BigInteger, primary_key=True),
    ForeignKeyConstraint(['material_id'], ['materials.id'], name='test_reagents_material_id_fkey'),
    ForeignKeyConstraint(['test_id'], ['tests.id'], ondelete='CASCADE', name='test_reagents_test_id_fkey'),
    PrimaryKeyConstraint('test_id', 'material_id', name='test_reagents_pkey')
)


class FormConditionEvals(Base):
    __tablename__ = 'form_condition_evals'
    __table_args__ = (
        ForeignKeyConstraint(['form_id', 'test_id'], ['form_params.form_id', 'form_params.test_id'], name='form_condition_evals_form_id_test_id_fkey'),
        ForeignKeyConstraint(['form_id'], ['forms.id'], name='form_condition_evals_form_id_fkey'),
        ForeignKeyConstraint(['test_id'], ['tests.id'], name='form_condition_evals_test_id_fkey'),
        PrimaryKeyConstraint('id', name='form_condition_evals_pkey')
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True)
    form_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    test_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    value: Mapped[decimal.Decimal] = mapped_column(Numeric, nullable=False)
    expected_result: Mapped[decimal.Decimal] = mapped_column(Numeric, nullable=False)
    is_match: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    result: Mapped[Optional[decimal.Decimal]] = mapped_column(Numeric)
    note: Mapped[Optional[str]] = mapped_column(String(20))

    form_params: Mapped['FormParams'] = relationship('FormParams', back_populates='form_condition_evals')
    form: Mapped['Forms'] = relationship('Forms', back_populates='form_condition_evals')
    test: Mapped['Tests'] = relationship('Tests', back_populates='form_condition_evals')


class FormEvalParams(Base):
    __tablename__ = 'form_eval_params'
    __table_args__ = (
        ForeignKeyConstraint(['eval_id'], ['form_evals.id'], name='form_eval_params_eval_id_fkey'),
        ForeignKeyConstraint(['form_id', 'test_id'], ['form_params.form_id', 'form_params.test_id'], name='form_eval_params_form_id_test_id_fkey'),
        ForeignKeyConstraint(['form_id'], ['forms.id'], name='form_eval_params_form_id_fkey'),
        ForeignKeyConstraint(['test_id'], ['tests.id'], name='form_eval_params_test_id_fkey'),
        PrimaryKeyConstraint('eval_id', 'form_id', 'test_id', 'idx', name='form_eval_params_pkey')
    )

    eval_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    form_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    test_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    idx: Mapped[int] = mapped_column(Integer, primary_key=True)
    is_match: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    value: Mapped[Optional[decimal.Decimal]] = mapped_column(Numeric)
    expected_value: Mapped[Optional[decimal.Decimal]] = mapped_column(Numeric)

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
        ForeignKeyConstraint(['user_update_id'], ['users.id'], name='measurements_user_update_id_fkey'),
        PrimaryKeyConstraint('id', name='measurements_pkey')
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True)
    reception_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    use_default_equipment: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('true'))
    user_update_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    date_update: Mapped[datetime.datetime] = mapped_column(DateTime(True), nullable=False)
    is_reported: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    is_readonly: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    user_created_id: Mapped[int] = mapped_column(BigInteger, nullable=False, server_default=text('1'))
    date_created: Mapped[datetime.datetime] = mapped_column(DateTime(True), nullable=False, server_default=text('clock_timestamp()'))
    form_id: Mapped[Optional[int]] = mapped_column(BigInteger)
    comments: Mapped[Optional[str]] = mapped_column(Text)
    user_reported_id: Mapped[Optional[int]] = mapped_column(BigInteger)
    date_reported: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True))
    date_readonly: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True))

    equipment: Mapped[list['Equipments']] = relationship('Equipments', secondary='measurement_equipments', back_populates='measurement')
    control_code: Mapped[list['ReagentLots']] = relationship('ReagentLots', secondary='measurement_reagent_lots', back_populates='measurement')
    form: Mapped[Optional['Forms']] = relationship('Forms', back_populates='measurements')
    reception: Mapped['Receptions'] = relationship('Receptions', back_populates='measurements')
    user_created: Mapped['Users'] = relationship('Users', foreign_keys=[user_created_id], back_populates='measurements_user_created')
    user_reported: Mapped[Optional['Users']] = relationship('Users', foreign_keys=[user_reported_id], back_populates='measurements_user_reported')
    user_update: Mapped['Users'] = relationship('Users', foreign_keys=[user_update_id], back_populates='measurements_user_update')
    sop_version: Mapped[list['SopVersions']] = relationship('SopVersions', secondary='measurement_sop_versions', back_populates='measurement')
    measurement_params: Mapped[list['MeasurementParams']] = relationship('MeasurementParams', back_populates='measurement')
    measurement_tests: Mapped[list['MeasurementTests']] = relationship('MeasurementTests', back_populates='measurement')
    report_tests: Mapped[list['ReportTests']] = relationship('ReportTests', back_populates='measurement')
    certificate_tests: Mapped[list['CertificateTests']] = relationship('CertificateTests', back_populates='measurement')


t_reagent_production_lots = Table(
    'reagent_production_lots', Base.metadata,
    Column('control_code_id', BigInteger, primary_key=True),
    Column('ingredient_control_code_id', BigInteger, primary_key=True),
    ForeignKeyConstraint(['control_code_id'], ['reagent_lots.control_code_id'], name='reagent_production_lots_control_code_id_fkey'),
    ForeignKeyConstraint(['ingredient_control_code_id'], ['reagent_lots.control_code_id'], name='reagent_production_lots_ingredient_control_code_id_fkey'),
    PrimaryKeyConstraint('control_code_id', 'ingredient_control_code_id', name='reagent_production_lots_pkey')
)


class ReagentSupplierLots(ReagentLots):
    __tablename__ = 'reagent_supplier_lots'
    __table_args__ = (
        ForeignKeyConstraint(['control_code_id'], ['reagent_lots.control_code_id'], name='reagent_supplier_lots_control_code_id_fkey'),
        PrimaryKeyConstraint('control_code_id', name='reagent_supplier_lots_pkey')
    )

    control_code_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    manufacturer_lot_number: Mapped[str] = mapped_column(String(50), nullable=False)
    catalog_number: Mapped[Optional[str]] = mapped_column(String(50))
    supplier: Mapped[Optional[str]] = mapped_column(String(100))
    certificate_of_analysis_ref: Mapped[Optional[str]] = mapped_column(String(255))


t_reception_tests = Table(
    'reception_tests', Base.metadata,
    Column('reception_id', BigInteger, primary_key=True),
    Column('test_id', BigInteger, primary_key=True),
    ForeignKeyConstraint(['reception_id'], ['receptions.id'], name='reception_tests_reception_id_fkey'),
    ForeignKeyConstraint(['test_id'], ['tests.id'], name='reception_tests_test_id_fkey'),
    PrimaryKeyConstraint('reception_id', 'test_id', name='reception_tests_pkey')
)


class Reports(Base):
    __tablename__ = 'reports'
    __table_args__ = (
        ForeignKeyConstraint(['reception_id'], ['receptions.id'], name='reports_reception_id_fkey'),
        ForeignKeyConstraint(['report_replaced_id'], ['reports.id'], name='reports_report_replaced_id_fkey'),
        ForeignKeyConstraint(['user_cancelled_id'], ['users.id'], name='reports_user_cancelled_id_fkey'),
        ForeignKeyConstraint(['user_submitted_id'], ['users.id'], name='reports_user_submitted_id_fkey'),
        PrimaryKeyConstraint('id', name='reports_pkey')
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True)
    reception_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    is_submitted: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    is_cancelled: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    user_submitted_id: Mapped[Optional[int]] = mapped_column(BigInteger)
    date_submitted: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True))
    comments_submitted: Mapped[Optional[str]] = mapped_column(Text)
    report_replaced_id: Mapped[Optional[int]] = mapped_column(BigInteger)
    user_cancelled_id: Mapped[Optional[int]] = mapped_column(BigInteger)
    date_cancelled: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True))
    comments_cancelled: Mapped[Optional[str]] = mapped_column(Text)

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
        ForeignKeyConstraint(['spec_id', 'test_id'], ['spec_tests.spec_id', 'spec_tests.test_id'], name='spec_test_evals_spec_id_test_id_fkey'),
        ForeignKeyConstraint(['spec_id'], ['specs.id'], name='spec_test_evals_spec_id_fkey'),
        ForeignKeyConstraint(['test_id'], ['tests.id'], name='spec_test_evals_test_id_fkey'),
        PrimaryKeyConstraint('id', name='spec_test_evals_pkey')
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), primary_key=True)
    spec_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    test_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    value: Mapped[decimal.Decimal] = mapped_column(Numeric, nullable=False)
    expected_result: Mapped[decimal.Decimal] = mapped_column(Numeric, nullable=False)
    is_match: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    result: Mapped[Optional[decimal.Decimal]] = mapped_column(Numeric)
    note: Mapped[Optional[str]] = mapped_column(String(20))

    spec_tests: Mapped['SpecTests'] = relationship('SpecTests', back_populates='spec_test_evals')
    spec: Mapped['Specs'] = relationship('Specs', back_populates='spec_test_evals')
    test: Mapped['Tests'] = relationship('Tests', back_populates='spec_test_evals')


t_measurement_equipments = Table(
    'measurement_equipments', Base.metadata,
    Column('measurement_id', BigInteger, primary_key=True),
    Column('equipment_id', BigInteger, primary_key=True),
    ForeignKeyConstraint(['equipment_id'], ['equipments.id'], name='measurement_equipments_equipment_id_fkey'),
    ForeignKeyConstraint(['measurement_id'], ['measurements.id'], name='measurement_equipments_measurement_id_fkey'),
    PrimaryKeyConstraint('measurement_id', 'equipment_id', name='measurement_equipments_pkey')
)


class MeasurementParams(Base):
    __tablename__ = 'measurement_params'
    __table_args__ = (
        ForeignKeyConstraint(['form_id', 'test_id'], ['form_params.form_id', 'form_params.test_id'], name='measurement_params_form_id_test_id_fkey'),
        ForeignKeyConstraint(['form_id'], ['forms.id'], name='measurement_params_form_id_fkey'),
        ForeignKeyConstraint(['measurement_id'], ['measurements.id'], name='measurement_params_measurement_id_fkey'),
        ForeignKeyConstraint(['test_id'], ['tests.id'], name='measurement_params_test_id_fkey'),
        PrimaryKeyConstraint('measurement_id', 'form_id', 'test_id', 'idx', name='measurement_params_pkey')
    )

    measurement_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    form_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    test_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    idx: Mapped[int] = mapped_column(Integer, primary_key=True, server_default=text('0'))
    value: Mapped[decimal.Decimal] = mapped_column(Numeric, nullable=False)
    condition_value: Mapped[Optional[decimal.Decimal]] = mapped_column(Numeric)

    form_params: Mapped['FormParams'] = relationship('FormParams', back_populates='measurement_params')
    form: Mapped['Forms'] = relationship('Forms', back_populates='measurement_params')
    measurement: Mapped['Measurements'] = relationship('Measurements', back_populates='measurement_params')
    test: Mapped['Tests'] = relationship('Tests', back_populates='measurement_params')


t_measurement_reagent_lots = Table(
    'measurement_reagent_lots', Base.metadata,
    Column('measurement_id', BigInteger, primary_key=True),
    Column('control_code_id', BigInteger, primary_key=True),
    ForeignKeyConstraint(['control_code_id'], ['reagent_lots.control_code_id'], name='measurement_reagent_lots_control_code_id_fkey'),
    ForeignKeyConstraint(['measurement_id'], ['measurements.id'], ondelete='CASCADE', name='measurement_reagent_lots_measurement_id_fkey'),
    PrimaryKeyConstraint('measurement_id', 'control_code_id', name='measurement_reagent_lots_pkey')
)


t_measurement_sop_versions = Table(
    'measurement_sop_versions', Base.metadata,
    Column('measurement_id', BigInteger, primary_key=True),
    Column('sop_version_id', BigInteger, primary_key=True),
    ForeignKeyConstraint(['measurement_id'], ['measurements.id'], ondelete='CASCADE', name='measurement_sop_versions_measurement_id_fkey'),
    ForeignKeyConstraint(['sop_version_id'], ['sop_versions.id'], name='measurement_sop_versions_sop_version_id_fkey'),
    PrimaryKeyConstraint('measurement_id', 'sop_version_id', name='measurement_sop_versions_pkey')
)


class MeasurementTests(Base):
    __tablename__ = 'measurement_tests'
    __table_args__ = (
        ForeignKeyConstraint(['measurement_id'], ['measurements.id'], name='measurement_tests_measurement_id_fkey'),
        ForeignKeyConstraint(['test_id'], ['tests.id'], name='measurement_tests_test_id_fkey'),
        PrimaryKeyConstraint('measurement_id', 'test_id', 'idx', name='measurement_tests_pkey')
    )

    measurement_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    test_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    idx: Mapped[int] = mapped_column(Integer, primary_key=True, server_default=text('0'))
    value: Mapped[decimal.Decimal] = mapped_column(Numeric, nullable=False)
    note: Mapped[Optional[str]] = mapped_column(String(20))

    measurement: Mapped['Measurements'] = relationship('Measurements', back_populates='measurement_tests')
    test: Mapped['Tests'] = relationship('Tests', back_populates='measurement_tests')


class ReportTests(Base):
    __tablename__ = 'report_tests'
    __table_args__ = (
        ForeignKeyConstraint(['measurement_id'], ['measurements.id'], name='report_tests_measurement_id_fkey'),
        ForeignKeyConstraint(['report_id'], ['reports.id'], name='report_tests_report_id_fkey'),
        ForeignKeyConstraint(['test_id'], ['tests.id'], name='report_tests_test_id_fkey'),
        PrimaryKeyConstraint('report_id', 'measurement_id', 'test_id', 'idx', name='report_tests_pkey')
    )

    report_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    measurement_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    test_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    idx: Mapped[int] = mapped_column(Integer, primary_key=True, server_default=text('0'))
    value: Mapped[decimal.Decimal] = mapped_column(Numeric, nullable=False)
    uncertainty_value: Mapped[Optional[decimal.Decimal]] = mapped_column(Numeric)
    coverage_factor_k: Mapped[Optional[decimal.Decimal]] = mapped_column(Numeric)

    measurement: Mapped['Measurements'] = relationship('Measurements', back_populates='report_tests')
    report: Mapped['Reports'] = relationship('Reports', back_populates='report_tests')
    test: Mapped['Tests'] = relationship('Tests', back_populates='report_tests')
    certificate_tests: Mapped[list['CertificateTests']] = relationship('CertificateTests', back_populates='report_tests')


class CertificateTests(Base):
    __tablename__ = 'certificate_tests'
    __table_args__ = (
        ForeignKeyConstraint(['certificate_id'], ['certificates.id'], name='certificate_tests_certificates_id_fkey'),
        ForeignKeyConstraint(['measurement_id'], ['measurements.id'], name='certificate_tests_measurement_id_fkey'),
        ForeignKeyConstraint(['report_id', 'measurement_id', 'test_id', 'idx'], ['report_tests.report_id', 'report_tests.measurement_id', 'report_tests.test_id', 'report_tests.idx'], name='certificate_tests_report_id_measurement_id_test_id_idx_fkey'),
        ForeignKeyConstraint(['report_id'], ['reports.id'], name='certificate_tests_report_id_fkey'),
        ForeignKeyConstraint(['test_id'], ['tests.id'], name='certificate_tests_test_id_fkey'),
        PrimaryKeyConstraint('certificate_id', 'report_id', 'test_id', 'idx', 'measurement_id', name='certificate_tests_pkey')
    )

    certificate_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    report_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    measurement_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    test_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    idx: Mapped[int] = mapped_column(Integer, primary_key=True, server_default=text('0'))
    value: Mapped[decimal.Decimal] = mapped_column(Numeric, nullable=False)
    is_conforming_spec: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    is_conforming_uncertainty: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('true'))
    note_spec: Mapped[str] = mapped_column(String(25), nullable=False)
    test_count: Mapped[int] = mapped_column(Integer, nullable=False, server_default=text('0'))
    uncertainty_value: Mapped[Optional[decimal.Decimal]] = mapped_column(Numeric)
    coverage_factor_k: Mapped[Optional[decimal.Decimal]] = mapped_column(Numeric)

    certificate: Mapped['Certificates'] = relationship('Certificates', back_populates='certificate_tests')
    measurement: Mapped['Measurements'] = relationship('Measurements', back_populates='certificate_tests')
    report_tests: Mapped['ReportTests'] = relationship('ReportTests', back_populates='certificate_tests')
    report: Mapped['Reports'] = relationship('Reports', back_populates='certificate_tests')
    test: Mapped['Tests'] = relationship('Tests', back_populates='certificate_tests')
