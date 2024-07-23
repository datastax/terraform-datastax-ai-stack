locals {
  components_with_domain = {
    for idx, config in [
      for idx, config in var.components : config
      if local.auto_route53_setup && config.domain != null
    ] : idx => config
  }

  domains      = values(local.components_with_domain)[*].domain
  hosted_zones = try(var.domain_config.hosted_zones, null)

  auto_route53_setup = try(var.domain_config.auto_route53_setup, null) == true

  hosted_zones_lut = {
    for idx, config in var.components : config.name =>
    try(local.hosted_zones[config.name], local.hosted_zones["default"])
    if config.domain != null
  }
}

data "aws_route53_zone" "zones" {
  for_each = local.components_with_domain

  zone_id = local.hosted_zones_lut[each.value["name"]]["zone_id"]
  name    = local.hosted_zones_lut[each.value["name"]]["zone_name"]

  private_zone = local.hosted_zones_lut[each.value["name"]]["zone_name"] != null ? false : null
}

resource "aws_route53_record" "a_records" {
  for_each = local.components_with_domain

  name    = "${each.value["domain"]}."
  type    = "A"
  zone_id = data.aws_route53_zone.zones[each.key].zone_id

  alias {
    name                   = "${module.alb["default"].dns_name}."
    zone_id                = module.alb["default"].zone_id
    evaluate_target_health = true
  }
}

locals {
  dvos = local.auto_route53_setup ? tolist(aws_acm_certificate.service_cert[0].domain_validation_options) : []
}

resource "aws_acm_certificate" "service_cert" {
  count = local.auto_route53_setup ? 1 : 0

  domain_name               = local.domains[0]
  validation_method         = "DNS"
  subject_alternative_names = toset(slice(local.domains, 1, length(local.domains)))

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Project = "datastax"
    Name    = "datastax-service-cert"
  }
}

resource "aws_route53_record" "validation" {
  count = local.auto_route53_setup ? length(local.domains) : 0

  name    = local.dvos[count.index]["resource_record_name"]
  type    = local.dvos[count.index]["resource_record_type"]
  records = [local.dvos[count.index]["resource_record_value"]]

  zone_id = data.aws_route53_zone.zones[count.index].zone_id
  ttl     = 60

  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "certificate_validation" {
  count                   = local.auto_route53_setup ? 1 : 0
  certificate_arn         = aws_acm_certificate.service_cert[0].arn
  validation_record_fqdns = aws_route53_record.validation[*].fqdn
}
