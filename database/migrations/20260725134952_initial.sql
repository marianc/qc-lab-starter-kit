-- Create "categories" table
CREATE TABLE "public"."categories" (
  "id" bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
  "name" character varying(50) NOT NULL,
  "code" character varying(3) NOT NULL,
  "description" text NULL,
  "date_created" timestamptz NOT NULL,
  "is_obsolete" boolean NOT NULL DEFAULT false,
  "date_obsolete" timestamptz NULL,
  "comments_obsolete" text NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "categories_code_key" UNIQUE ("code"),
  CONSTRAINT "categories_name_key" UNIQUE ("name")
);
-- Create "norms" table
CREATE TABLE "public"."norms" (
  "id" bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
  "name" character varying(50) NOT NULL,
  "description" text NULL,
  "date_created" timestamptz NOT NULL,
  "is_obsolete" boolean NOT NULL DEFAULT false,
  "date_obsolete" timestamptz NULL,
  "comments_obsolete" text NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "norms_name_key" UNIQUE ("name")
);
-- Create "units" table
CREATE TABLE "public"."units" (
  "id" bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
  "name" character varying(50) NOT NULL,
  "description" text NULL,
  "date_created" timestamptz NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "units_name_key" UNIQUE ("name")
);
-- Create "value_types" table
CREATE TABLE "public"."value_types" (
  "id" bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
  "name" character varying(50) NOT NULL,
  CONSTRAINT "form_param_types_pkey" PRIMARY KEY ("id")
);
-- Create "tests" table
CREATE TABLE "public"."tests" (
  "id" bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
  "name" character varying(50) NOT NULL,
  "code" character varying(50) NOT NULL,
  "description" text NULL,
  "type_id" bigint NOT NULL,
  "is_array" boolean NOT NULL DEFAULT false,
  "is_param" boolean NOT NULL DEFAULT false,
  "unit_id" bigint NULL,
  "norm_id" bigint NULL,
  "norm_ref" character varying(50) NULL,
  "for_certification" boolean NOT NULL DEFAULT false,
  "nr_ord" bigint NOT NULL DEFAULT 0,
  "is_form_validated" boolean NOT NULL DEFAULT false,
  "date_created" timestamptz NOT NULL,
  "is_obsolete" boolean NOT NULL DEFAULT false,
  "date_obsolete" timestamptz NULL,
  "comments_obsolete" text NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "tests_code_key" UNIQUE ("code"),
  CONSTRAINT "tests_name_key" UNIQUE ("name"),
  CONSTRAINT "tests_norm_id_fkey" FOREIGN KEY ("norm_id") REFERENCES "public"."norms" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "tests_unit_id_fkey" FOREIGN KEY ("unit_id") REFERENCES "public"."units" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "tests_value_type_id_fkey" FOREIGN KEY ("type_id") REFERENCES "public"."value_types" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create "category_tests" table
CREATE TABLE "public"."category_tests" (
  "category_id" bigint NOT NULL,
  "test_id" bigint NOT NULL,
  PRIMARY KEY ("category_id", "test_id"),
  CONSTRAINT "category_tests_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."categories" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "category_tests_test_id_fkey" FOREIGN KEY ("test_id") REFERENCES "public"."tests" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create "materials" table
CREATE TABLE "public"."materials" (
  "id" bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
  "name" character varying(50) NOT NULL,
  "code" character varying(5) NOT NULL,
  "description" text NULL,
  "norm_id" bigint NULL,
  "is_product" boolean NOT NULL DEFAULT false,
  "is_raw_material" boolean NOT NULL DEFAULT false,
  "date_created" timestamptz NOT NULL,
  "is_obsolete" boolean NOT NULL DEFAULT false,
  "date_obsolete" timestamptz NULL,
  "comments_obsolete" text NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "materials_code_key" UNIQUE ("code"),
  CONSTRAINT "materials_name_key" UNIQUE ("name"),
  CONSTRAINT "materials_norm_id_fkey" FOREIGN KEY ("norm_id") REFERENCES "public"."norms" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create "control_codes" table
CREATE TABLE "public"."control_codes" (
  "id" bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
  "material_id" bigint NOT NULL,
  "code" character varying(50) NOT NULL,
  "is_reception_received" boolean NOT NULL DEFAULT false,
  PRIMARY KEY ("id"),
  CONSTRAINT "control_codes_material_id_fkey" FOREIGN KEY ("material_id") REFERENCES "public"."materials" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create "users" table
CREATE TABLE "public"."users" (
  "id" bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
  "tag" character varying(12) NOT NULL,
  "code" character varying(3) NOT NULL,
  "email" character varying(50) NOT NULL,
  "first_name" character varying(50) NULL,
  "last_name" character varying(50) NULL,
  "is_admin" boolean NOT NULL DEFAULT false,
  "is_lab_pers" boolean NOT NULL DEFAULT false,
  "is_qc_pers" boolean NOT NULL DEFAULT false,
  "password_hash" text NULL,
  "password_salt" text NULL,
  "must_change_password" boolean NOT NULL DEFAULT false,
  "date_password_changed" timestamptz NULL,
  "session_id" character varying(255) NULL,
  "date_session_created" timestamptz NULL,
  "date_session_expire" timestamptz NULL,
  "refresh_token" character varying NULL,
  "date_created" timestamptz NOT NULL,
  "is_obsolete" boolean NOT NULL DEFAULT false,
  "date_obsolete" timestamptz NULL,
  "comments_obsolete" text NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "users_code_key" UNIQUE ("code"),
  CONSTRAINT "users_email_key" UNIQUE ("email"),
  CONSTRAINT "users_session_id_key" UNIQUE ("session_id"),
  CONSTRAINT "users_tag_key" UNIQUE ("tag")
);
-- Create "specs" table
CREATE TABLE "public"."specs" (
  "id" bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
  "material_id" bigint NOT NULL,
  "is_submitted" boolean NOT NULL DEFAULT false,
  "user_submitted_id" bigint NULL,
  "date_submitted" timestamptz NULL,
  "comments_submitted" text NULL,
  "spec_replaced_id" bigint NULL,
  "is_cancelled" boolean NOT NULL DEFAULT false,
  "user_cancelled_id" bigint NULL,
  "date_cancelled" timestamptz NULL,
  "comments_cancelled" text NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "specs_material_id_fkey" FOREIGN KEY ("material_id") REFERENCES "public"."materials" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "specs_spec_replaced_id_fkey" FOREIGN KEY ("spec_replaced_id") REFERENCES "public"."specs" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "specs_user_cancelled_id_fkey" FOREIGN KEY ("user_cancelled_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "specs_user_submitted_id_fkey" FOREIGN KEY ("user_submitted_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create "certificates" table
CREATE TABLE "public"."certificates" (
  "id" bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
  "control_code_id" bigint NOT NULL,
  "spec_id" bigint NOT NULL,
  "is_conforming_spec" boolean NOT NULL DEFAULT false,
  "is_submitted" boolean NOT NULL DEFAULT false,
  "user_submitted_id" bigint NULL,
  "date_submitted" timestamptz NULL,
  "comments_submitted" text NULL,
  "certificate_replaced_id" bigint NULL,
  "is_cancelled" boolean NOT NULL DEFAULT false,
  "user_cancelled_id" bigint NULL,
  "date_cancelled" timestamptz NULL,
  "comments_cancelled" text NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "certificates_certificate_replaced_id_fkey" FOREIGN KEY ("certificate_replaced_id") REFERENCES "public"."certificates" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "certificates_control_code_id_fkey" FOREIGN KEY ("control_code_id") REFERENCES "public"."control_codes" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "certificates_specs_id_fkey" FOREIGN KEY ("spec_id") REFERENCES "public"."specs" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "certificates_user_cancelled_id_fkey" FOREIGN KEY ("user_cancelled_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "certificates_user_submitted_id_fkey" FOREIGN KEY ("user_submitted_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create "form_groups" table
CREATE TABLE "public"."form_groups" (
  "id" bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
  "name" character varying(50) NOT NULL,
  "description" text NULL,
  "nr_ord" bigint NOT NULL DEFAULT 0,
  "is_form_validated" boolean NOT NULL DEFAULT false,
  PRIMARY KEY ("id")
);
-- Create "forms" table
CREATE TABLE "public"."forms" (
  "id" bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
  "form_group_id" bigint NOT NULL,
  "version" character varying(50) NOT NULL,
  "is_customized" boolean NOT NULL DEFAULT false,
  "custom_nav" text NULL,
  "is_submitted" boolean NOT NULL DEFAULT false,
  "user_submitted_id" bigint NULL,
  "date_submitted" timestamptz NULL,
  "comments_submitted" text NULL,
  "is_validated" boolean NOT NULL DEFAULT false,
  "user_validated_id" bigint NULL,
  "date_validated" timestamptz NULL,
  "comments_validated" text NULL,
  "is_cancelled" boolean NOT NULL DEFAULT false,
  "user_cancelled_id" bigint NULL,
  "date_cancelled" timestamptz NULL,
  "comments_cancelled" text NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "forms_form_group_id_fkey" FOREIGN KEY ("form_group_id") REFERENCES "public"."form_groups" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "forms_user_canceled_id_fkey" FOREIGN KEY ("user_cancelled_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "forms_user_submitted_id_fkey" FOREIGN KEY ("user_submitted_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "forms_user_validated_id_fkey" FOREIGN KEY ("user_validated_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create "reception_types" table
CREATE TABLE "public"."reception_types" (
  "id" bigint NOT NULL,
  "name" character varying(50) NOT NULL,
  PRIMARY KEY ("id")
);
-- Create "receptions" table
CREATE TABLE "public"."receptions" (
  "id" bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
  "type_id" bigint NOT NULL,
  "control_code_id" bigint NULL,
  "material_name" character varying(50) NULL,
  "category_id" bigint NULL,
  "is_submitted" boolean NOT NULL DEFAULT false,
  "user_submitted_id" bigint NULL,
  "date_submitted" timestamptz NULL,
  "comments_submitted" text NULL,
  "is_received" boolean NOT NULL DEFAULT false,
  "user_received_id" bigint NULL,
  "date_received" timestamptz NULL,
  "comments_received" text NULL,
  "is_rejected" boolean NOT NULL DEFAULT false,
  "user_rejected_id" bigint NULL,
  "date_rejected" timestamptz NULL,
  "comments_rejected" text NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "receptions_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."categories" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "receptions_control_code_id_fkey" FOREIGN KEY ("control_code_id") REFERENCES "public"."control_codes" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "receptions_reception_type_id_fkey" FOREIGN KEY ("type_id") REFERENCES "public"."reception_types" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "receptions_user_received_id_fkey" FOREIGN KEY ("user_received_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "receptions_user_rejected_id_fkey" FOREIGN KEY ("user_rejected_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "receptions_user_submitted_id_fkey" FOREIGN KEY ("user_submitted_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create "measurements" table
CREATE TABLE "public"."measurements" (
  "id" bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
  "reception_id" bigint NOT NULL,
  "form_id" bigint NULL,
  "comments" text NULL,
  "is_reported" boolean NOT NULL DEFAULT false,
  "user_reported_id" bigint NULL,
  "is_readonly" boolean NOT NULL DEFAULT false,
  "user_update_id" bigint NOT NULL,
  "date_update" timestamptz NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "measurements_form_id_fkey" FOREIGN KEY ("form_id") REFERENCES "public"."forms" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "measurements_reception_id_fkey" FOREIGN KEY ("reception_id") REFERENCES "public"."receptions" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "measurements_user_reported_id_fkey" FOREIGN KEY ("user_reported_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "measurements_user_update_id_fkey" FOREIGN KEY ("user_update_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create "reports" table
CREATE TABLE "public"."reports" (
  "id" bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
  "reception_id" bigint NOT NULL,
  "is_submitted" boolean NOT NULL DEFAULT false,
  "user_submitted_id" bigint NULL,
  "date_submitted" timestamptz NULL,
  "comments_submitted" text NULL,
  "report_replaced_id" bigint NULL,
  "is_cancelled" boolean NOT NULL DEFAULT false,
  "user_cancelled_id" bigint NULL,
  "date_cancelled" timestamptz NULL,
  "comments_cancelled" text NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "reports_reception_id_fkey" FOREIGN KEY ("reception_id") REFERENCES "public"."receptions" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "reports_report_replaced_id_fkey" FOREIGN KEY ("report_replaced_id") REFERENCES "public"."reports" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "reports_user_cancelled_id_fkey" FOREIGN KEY ("user_cancelled_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "reports_user_submitted_id_fkey" FOREIGN KEY ("user_submitted_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create "report_tests" table
CREATE TABLE "public"."report_tests" (
  "report_id" bigint NOT NULL,
  "measurement_id" bigint NOT NULL,
  "test_id" bigint NOT NULL,
  "idx" integer NOT NULL DEFAULT 0,
  "value" real NOT NULL,
  PRIMARY KEY ("report_id", "measurement_id", "test_id", "idx"),
  CONSTRAINT "report_tests_measurement_id_fkey" FOREIGN KEY ("measurement_id") REFERENCES "public"."measurements" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "report_tests_report_id_fkey" FOREIGN KEY ("report_id") REFERENCES "public"."reports" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "report_tests_test_id_fkey" FOREIGN KEY ("test_id") REFERENCES "public"."tests" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create "certificate_tests" table
CREATE TABLE "public"."certificate_tests" (
  "certificate_id" bigint NOT NULL,
  "report_id" bigint NOT NULL,
  "measurement_id" bigint NOT NULL,
  "test_id" bigint NOT NULL,
  "idx" integer NOT NULL DEFAULT 0,
  "value" real NOT NULL,
  "test_count" integer NOT NULL DEFAULT 0,
  "note_spec" character varying(25) NOT NULL,
  "is_conforming_spec" boolean NOT NULL DEFAULT false,
  PRIMARY KEY ("certificate_id", "report_id", "test_id", "idx", "measurement_id"),
  CONSTRAINT "certificate_tests_certificates_id_fkey" FOREIGN KEY ("certificate_id") REFERENCES "public"."certificates" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "certificate_tests_measurement_id_fkey" FOREIGN KEY ("measurement_id") REFERENCES "public"."measurements" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "certificate_tests_report_id_fkey" FOREIGN KEY ("report_id") REFERENCES "public"."reports" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "certificate_tests_report_id_measurement_id_test_id_idx_fkey" FOREIGN KEY ("report_id", "measurement_id", "test_id", "idx") REFERENCES "public"."report_tests" ("report_id", "measurement_id", "test_id", "idx") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "certificate_tests_test_id_fkey" FOREIGN KEY ("test_id") REFERENCES "public"."tests" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create "form_evals" table
CREATE TABLE "public"."form_evals" (
  "id" bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
  "form_id" bigint NOT NULL,
  "description" text NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "form_evals_form_id_fkey" FOREIGN KEY ("form_id") REFERENCES "public"."forms" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create "form_params" table
CREATE TABLE "public"."form_params" (
  "form_id" bigint NOT NULL,
  "test_id" bigint NOT NULL,
  "is_calculated" boolean NOT NULL DEFAULT false,
  "formula" text NULL,
  "formula_dependencies" text NULL,
  "code_related_arrays" character varying(50) NULL,
  "is_required" boolean NOT NULL DEFAULT false,
  "default_value" real NULL,
  "nr_ord" bigint NOT NULL DEFAULT 0,
  "nr_ord_calc" bigint NOT NULL DEFAULT 0,
  PRIMARY KEY ("form_id", "test_id"),
  CONSTRAINT "form_params_form_id_fkey" FOREIGN KEY ("form_id") REFERENCES "public"."forms" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "form_params_test_id_fkey" FOREIGN KEY ("test_id") REFERENCES "public"."tests" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create "form_eval_params" table
CREATE TABLE "public"."form_eval_params" (
  "eval_id" bigint NOT NULL,
  "form_id" bigint NOT NULL,
  "test_id" bigint NOT NULL,
  "idx" integer NOT NULL,
  "value" real NULL,
  "expected_value" real NULL,
  "precision" integer NOT NULL DEFAULT 7,
  "is_match" boolean NOT NULL DEFAULT false,
  PRIMARY KEY ("eval_id", "form_id", "test_id", "idx"),
  CONSTRAINT "form_eval_params_eval_id_fkey" FOREIGN KEY ("eval_id") REFERENCES "public"."form_evals" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "form_eval_params_form_id_fkey" FOREIGN KEY ("form_id") REFERENCES "public"."forms" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "form_eval_params_form_id_test_id_fkey" FOREIGN KEY ("form_id", "test_id") REFERENCES "public"."form_params" ("form_id", "test_id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "form_eval_params_test_id_fkey" FOREIGN KEY ("test_id") REFERENCES "public"."tests" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create "material_tests" table
CREATE TABLE "public"."material_tests" (
  "material_id" bigint NOT NULL,
  "test_id" bigint NOT NULL,
  PRIMARY KEY ("material_id", "test_id"),
  CONSTRAINT "material_tests_material_id_fkey" FOREIGN KEY ("material_id") REFERENCES "public"."materials" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "material_tests_test_id_fkey" FOREIGN KEY ("test_id") REFERENCES "public"."tests" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create "measurement_params" table
CREATE TABLE "public"."measurement_params" (
  "measurement_id" bigint NOT NULL,
  "form_id" bigint NOT NULL,
  "test_id" bigint NOT NULL,
  "idx" integer NOT NULL DEFAULT 0,
  "value" real NOT NULL,
  PRIMARY KEY ("measurement_id", "form_id", "test_id", "idx"),
  CONSTRAINT "measurement_params_form_id_fkey" FOREIGN KEY ("form_id") REFERENCES "public"."forms" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "measurement_params_form_id_test_id_fkey" FOREIGN KEY ("form_id", "test_id") REFERENCES "public"."form_params" ("form_id", "test_id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "measurement_params_measurement_id_fkey" FOREIGN KEY ("measurement_id") REFERENCES "public"."measurements" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "measurement_params_test_id_fkey" FOREIGN KEY ("test_id") REFERENCES "public"."tests" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create "measurement_tests" table
CREATE TABLE "public"."measurement_tests" (
  "measurement_id" bigint NOT NULL,
  "test_id" bigint NOT NULL,
  "idx" integer NOT NULL DEFAULT 0,
  "value" real NOT NULL,
  "note" character varying(20) NULL,
  PRIMARY KEY ("measurement_id", "test_id", "idx"),
  CONSTRAINT "measurement_tests_measurement_id_fkey" FOREIGN KEY ("measurement_id") REFERENCES "public"."measurements" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "measurement_tests_test_id_fkey" FOREIGN KEY ("test_id") REFERENCES "public"."tests" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create "reception_tests" table
CREATE TABLE "public"."reception_tests" (
  "reception_id" bigint NOT NULL,
  "test_id" bigint NOT NULL,
  PRIMARY KEY ("reception_id", "test_id"),
  CONSTRAINT "reception_tests_reception_id_fkey" FOREIGN KEY ("reception_id") REFERENCES "public"."receptions" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "reception_tests_test_id_fkey" FOREIGN KEY ("test_id") REFERENCES "public"."tests" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create "spec_tests" table
CREATE TABLE "public"."spec_tests" (
  "spec_id" bigint NOT NULL,
  "test_id" bigint NOT NULL,
  "test_frequency" integer NOT NULL,
  "condition" character varying(255) NOT NULL,
  "note" character varying(150) NOT NULL,
  PRIMARY KEY ("spec_id", "test_id"),
  CONSTRAINT "spec_tests_specs_id_fkey" FOREIGN KEY ("spec_id") REFERENCES "public"."specs" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "spec_tests_tests_id_fkey" FOREIGN KEY ("test_id") REFERENCES "public"."tests" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create "spec_test_evals" table
CREATE TABLE "public"."spec_test_evals" (
  "id" bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
  "spec_id" bigint NOT NULL,
  "test_id" bigint NOT NULL,
  "value" real NOT NULL,
  "result" real NULL,
  "expected_result" real NOT NULL,
  "is_match" boolean NOT NULL DEFAULT false,
  "note" character varying(20) NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "spec_test_evals_spec_id_fkey" FOREIGN KEY ("spec_id") REFERENCES "public"."specs" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "spec_test_evals_spec_id_test_id_fkey" FOREIGN KEY ("spec_id", "test_id") REFERENCES "public"."spec_tests" ("spec_id", "test_id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "spec_test_evals_test_id_fkey" FOREIGN KEY ("test_id") REFERENCES "public"."tests" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create "test_enums" table
CREATE TABLE "public"."test_enums" (
  "test_id" bigint NOT NULL,
  "value" bigint NOT NULL,
  "name" character varying(50) NOT NULL,
  "nr_ord" bigint NOT NULL DEFAULT 0,
  "is_obsolete" boolean NOT NULL DEFAULT false,
  PRIMARY KEY ("test_id", "value"),
  CONSTRAINT "test_enums_test_id_name_key" UNIQUE ("test_id", "name"),
  CONSTRAINT "test_enums_test_id_fkey" FOREIGN KEY ("test_id") REFERENCES "public"."tests" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
