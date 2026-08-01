-- Modify "certificate_tests" table
ALTER TABLE "public"."certificate_tests" ALTER COLUMN "value" TYPE numeric;
-- Modify "form_eval_params" table
ALTER TABLE "public"."form_eval_params" ALTER COLUMN "value" TYPE numeric, ALTER COLUMN "expected_value" TYPE numeric, DROP COLUMN "precision";
-- Modify "measurement_params" table
ALTER TABLE "public"."measurement_params" ALTER COLUMN "value" TYPE numeric, ADD COLUMN "condition_value" numeric NULL;
-- Modify "measurement_tests" table
ALTER TABLE "public"."measurement_tests" ALTER COLUMN "value" TYPE numeric;
-- Modify "report_tests" table
ALTER TABLE "public"."report_tests" ALTER COLUMN "value" TYPE numeric;
-- Modify "spec_test_evals" table
ALTER TABLE "public"."spec_test_evals" ALTER COLUMN "value" TYPE numeric, ALTER COLUMN "result" TYPE numeric, ALTER COLUMN "expected_result" TYPE numeric;
-- Rename a constraint from "form_param_types_pkey" to "value_types_pkey"
ALTER TABLE "public"."value_types" RENAME CONSTRAINT "form_param_types_pkey" TO "value_types_pkey";
-- Modify "form_params" table
ALTER TABLE "public"."form_params" ALTER COLUMN "default_value" TYPE numeric, ADD COLUMN "has_condition" boolean NOT NULL DEFAULT false, ADD COLUMN "condition" character varying(255) NULL, ADD COLUMN "condition_note" character varying(150) NULL;
-- Create "form_condition_evals" table
CREATE TABLE "public"."form_condition_evals" (
  "id" bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
  "form_id" bigint NOT NULL,
  "test_id" bigint NOT NULL,
  "value" numeric NOT NULL,
  "result" numeric NULL,
  "expected_result" numeric NOT NULL,
  "is_match" boolean NOT NULL DEFAULT false,
  "note" character varying(20) NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "form_condition_evals_form_id_fkey" FOREIGN KEY ("form_id") REFERENCES "public"."forms" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "form_condition_evals_form_id_test_id_fkey" FOREIGN KEY ("form_id", "test_id") REFERENCES "public"."form_params" ("form_id", "test_id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "form_condition_evals_test_id_fkey" FOREIGN KEY ("test_id") REFERENCES "public"."tests" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
