data "aws_route53_zone" "main" {
  name = "secoureo.com"
}


#create alb to trigger grafana 