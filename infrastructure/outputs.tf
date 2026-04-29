output "kubernetes_service_endpoint" {
  value = kubernetes_service.proyecto_final_service.status.0.load_balancer.0.ingress.0.hostname
}