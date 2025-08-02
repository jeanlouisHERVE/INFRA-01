# resource "aws_acm_certificate" "wildcard_cert" {
#   domain_name       = "*.secoureo.com"
#   validation_method = "DNS"

#   lifecycle {
#     create_before_destroy = true
#   }

#   tags = {
#     Name = "Wildcard Secoureo Cert"
#   }
# }

# resource "aws_route53_record" "wildcard_cert_validation" {
#   name    = tolist(aws_acm_certificate.wildcard_cert.domain_validation_options)[0].resource_record_name
#   type    = tolist(aws_acm_certificate.wildcard_cert.domain_validation_options)[0].resource_record_type
#   zone_id = var.route53_zone_id
#   records = [tolist(aws_acm_certificate.wildcard_cert.domain_validation_options)[0].resource_record_value]
#   ttl     = 60
# }

# resource "aws_acm_certificate_validation" "wildcard_cert_validation" {
#   certificate_arn         = aws_acm_certificate.wildcard_cert.arn
#   validation_record_fqdns = [aws_route53_record.wildcard_cert_validation.fqdn]
# }