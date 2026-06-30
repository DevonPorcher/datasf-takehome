terraform {
  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "~> 2.17"
    }
  }
}

# Set department_codes from python script that queries snowflake
# Will progrmatically drive role creation, instead of hard coded code list
# Risk of issues if codes were to be changing while this was running
locals {
  department_codes = jsondecode(
    data.external.python_department_codes.result["department_codes"]
  )
}

variable "organization_name" {
  type = string
}

variable "account_name" {
  type = string
}

variable "database_name" {
  type = string
}

variable "schema_name" {
  type = string
}

variable "department_table_name" {
  type = string
}

variable "employee_table_name" {
  type = string
}

variable "private_key_path" {
  type    = string
  default = "~/.ssh/snowflake_tf_snow_key.p8"
}

data "external" "python_department_codes" {
  program = ["python3", "${path.module}/get_department_codes.py"]
}


provider "snowflake" {
  organization_name = var.organization_name
  account_name      = var.account_name
  user              = "TERRAFORM_SVC"
  role              = "USERADMIN"
  warehouse         = "COMPUTE_WH"
  alias             = "useradmin"
  authenticator     = "SNOWFLAKE_JWT"
  private_key       = file(var.private_key_path)
}

provider "snowflake" {
  organization_name = var.organization_name
  account_name      = var.account_name
  user              = "TERRAFORM_SVC"
  role              = "SYSADMIN"
  warehouse         = "COMPUTE_WH"
  alias             = "sysadmin"
  authenticator     = "SNOWFLAKE_JWT"
  private_key       = file(var.private_key_path)
}

# Grant USAGE on the database to PUBLIC
resource "snowflake_grant_privileges_to_account_role" "public_db_usage" {
  provider          = snowflake.useradmin
  privileges        = ["USAGE"]
  account_role_name = "PUBLIC"
  on_account_object {
    object_type = "DATABASE"
    object_name = var.database_name
  }
}

# Grant USAGE on the schema to PUBLIC
resource "snowflake_grant_privileges_to_account_role" "public_schema_usage" {
  provider          = snowflake.useradmin
  privileges        = ["USAGE"]
  account_role_name = "PUBLIC"
  on_schema {
    schema_name = "${var.database_name}.${var.schema_name}"
  }
}

# Grant SELECT on the department compensation table to the role
resource "snowflake_grant_privileges_to_account_role" "public_table_select" {
  provider          = snowflake.sysadmin
  privileges        = ["SELECT"]
  account_role_name = "PUBLIC"
  on_schema_object {
    object_type = "TABLE"
    object_name = "${var.database_name}.${var.schema_name}.${var.department_table_name}"
  }
}


# create LEADERSHIP role
resource "snowflake_account_role" "leadership_role" {
  provider = snowflake.useradmin
  name     = "LEADERSHIP"
  comment  = "Leadership for employee compensation"
}

resource "snowflake_grant_account_role" "grant_leadership_role_to_sysadmin" {
  provider         = snowflake.useradmin
  role_name        = snowflake_account_role.leadership_role.name
  parent_role_name = "SYSADMIN"
}

# Grant SELECT on the employee compensation table to the role
resource "snowflake_grant_privileges_to_account_role" "leadership_table_select" {
  provider          = snowflake.sysadmin
  privileges        = ["SELECT"]
  account_role_name = snowflake_account_role.leadership_role.name
  on_schema_object {
    object_type = "TABLE"
    object_name = "${var.database_name}.${var.schema_name}.${var.employee_table_name}"
  }
}


# Create a DEPARTMENT_HEAD role for each department
resource "snowflake_account_role" "department_head_role" {
  provider = snowflake.useradmin
  for_each = toset(local.department_codes)
  name     = "${each.key}_DEPARTMENT_HEAD"
  comment  = "Read access for the ${each.key} department head"
}

resource "snowflake_grant_account_role" "grant_department_head_role_to_sysadmin" {
  provider         = snowflake.useradmin
  for_each         = toset(local.department_codes)
  role_name        = snowflake_account_role.department_head_role[each.key].name
  parent_role_name = "SYSADMIN"
}

# Grant SELECT on the employee compensation table to the roles
# This grant exposes all rows for every department head role
# Row isolation by department is done by the row access policy managed in dbt
resource "snowflake_grant_privileges_to_account_role" "department_head_table_select" {
  provider          = snowflake.sysadmin
  for_each          = toset(local.department_codes)
  privileges        = ["SELECT"]
  account_role_name = snowflake_account_role.department_head_role[each.key].name
  on_schema_object {
    object_type = "TABLE"
    object_name = "${var.database_name}.${var.schema_name}.${var.employee_table_name}"
  }
}
