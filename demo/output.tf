# output "vpc_id" {
#   value = module.enterprise-gpts-aws.vpc_id
# }
#
# output "alb_dns_name" {
#   value = module.enterprise-gpts-aws.alb_dns_name
# }

output "project_name" {
  value = module.enterprise-gpts-gcp.project_id
}

output "load_balancer_ip" {
  value = module.enterprise-gpts-gcp.load_balancer_ip
}
