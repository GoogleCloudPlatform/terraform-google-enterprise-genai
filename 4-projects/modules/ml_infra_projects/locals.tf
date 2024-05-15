locals {
  env_code = element(split("", var.environment), 0)
}