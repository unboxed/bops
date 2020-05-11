variable "region" {
  description = "Region that the instances will be created"
}

/*====
environment specific variables
======*/

variable "staging_database_name" {
  description = "The database name for Staging"
}

variable "staging_database_username" {
  description = "The username for the Staging database"
}

variable "staging_database_password" {
  description = "The user password for the Staging database"
}

variable "staging_secret_key_base" {
  description = "The Rails secret key for production"
}
