
resource "kubernetes_deployment" "proyecto_final" {
  metadata {
    name      = "proyecto-final"
    namespace = var.grupo
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "proyecto-final"
      }
    }
    template {
      metadata {
        labels = {
          app = "proyecto-final"
        }
      }
      spec {
        container {
          name              = "langflow"
          image             = "langflowai/langflow:latest"
          image_pull_policy = "Always"
          port {
            container_port = 7860
          }
          env {
            name  = "AWS_DEFAULT_REGION"
            value = var.aws_region
          }
          # Al estar en el mismo pod, se usa localhost para conectar a Postgres
          env {
            name  = "LANGFLOW_DATABASE_URL"
            value = "postgresql://langflow:langflow@localhost:5432/langflow"
          }
          env {
            name  = "LANGFLOW_CONFIG_DIR"
            value = "app/langflow"
          }
          volume_mount {
            name       = "logs"
            mount_path = "/var/log/app/ambassador-app"
          }
        }
        container {
          name              = "ambassador-nginx"
          image             = "${data.terraform_remote_state.base.outputs.proyecto_final_ecr_repository_url}:nginx-ambassador-grupo2-latest"
          image_pull_policy = "Always"
          port {
            container_port = 8080
          }
          volume_mount {
            name       = "logs"
            mount_path = "/var/log/app"
          }
        }
        container {
          name              = "postgres"
          image             = "postgres:16"
          image_pull_policy = "IfNotPresent"
          env {
            name  = "POSTGRES_USER"
            value = "langflow"
          }
          env {
            name  = "POSTGRES_PASSWORD"
            value = "langflow"
          }
          env {
            name  = "POSTGRES_DB"
            value = "langflow"
          }
          port {
            container_port = 5432
          }
          volume_mount {
            name       = "postgres-data"
            mount_path = "/var/lib/postgresql/data"
          }
        }
        volume {
          name = "logs"
          empty_dir {}
        }
        volume {
          name = "postgres-data"
          empty_dir {}  
        }
      }
    }
  }
  provider = kubernetes._internal
}

resource "kubernetes_service" "proyecto_final_service" {
  metadata {
    name      = "proyecto-final-service"
    namespace = var.grupo
  }
  spec {
    selector = {
      app = "proyecto-final"
    }
    type = "LoadBalancer"
    port {
      name        = "langflow"
      port        = 80
      target_port = 7860
    }
    # port {
    #   name        = "ambassador"
    #   port        = 8080
    #   target_port = 8080
    # }
    # port {
    #   name        = "postgres"
    #   port        = 5432
    #   target_port = 5432
    # }
  }
  provider = kubernetes._internal
}