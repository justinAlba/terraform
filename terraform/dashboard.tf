# Dashboard de CloudWatch con las metricas de la Actividad 3 (pruebas de carga).
# Una fila por componente del flujo: API Gateway -> Lambda -> SNS -> SQS -> Lambda.

locals {
  dashboard_name = "${local.name}-pruebas-carga"

  dash_api_id = aws_apigatewayv2_api.api.id
  dash_sqs    = aws_sqs_queue.notifications.name
  dash_dlq    = aws_sqs_queue.notifications_dlq.name
  dash_sns    = aws_sns_topic.notifications.name

  # Propiedades comunes de las graficas de metricas.
  dash_widget = {
    region  = var.aws_region
    view    = "timeSeries"
    stacked = false
    period  = 60
  }
}

resource "aws_cloudwatch_dashboard" "pruebas_carga" {
  dashboard_name = local.dashboard_name

  dashboard_body = jsonencode({
    widgets = [
      # ---------------------------------------------------------- API Gateway
      {
        type       = "text"
        x          = 0
        y          = 0
        width      = 24
        height     = 1
        properties = { markdown = "## API Gateway (HTTP API)" }
      },
      {
        type   = "metric"
        x      = 0
        y      = 1
        width  = 8
        height = 6
        properties = merge(local.dash_widget, {
          title   = "API Gateway - Request Count"
          metrics = [["AWS/ApiGateway", "Count", "ApiId", local.dash_api_id, "Stage", "$default", { stat = "Sum", label = "Requests" }]]
        })
      },
      {
        type   = "metric"
        x      = 8
        y      = 1
        width  = 8
        height = 6
        properties = merge(local.dash_widget, {
          title = "API Gateway - Latency / Integration Latency (ms)"
          metrics = [
            ["AWS/ApiGateway", "Latency", "ApiId", local.dash_api_id, "Stage", "$default", { stat = "Average", label = "Latency avg" }],
            ["AWS/ApiGateway", "Latency", "ApiId", local.dash_api_id, "Stage", "$default", { stat = "p95", label = "Latency p95" }],
            ["AWS/ApiGateway", "IntegrationLatency", "ApiId", local.dash_api_id, "Stage", "$default", { stat = "Average", label = "Integration avg" }],
            ["AWS/ApiGateway", "IntegrationLatency", "ApiId", local.dash_api_id, "Stage", "$default", { stat = "p95", label = "Integration p95" }],
          ]
        })
      },
      {
        type   = "metric"
        x      = 16
        y      = 1
        width  = 8
        height = 6
        properties = merge(local.dash_widget, {
          title = "API Gateway - Error Rate (4XX / 5XX)"
          metrics = [
            ["AWS/ApiGateway", "4xx", "ApiId", local.dash_api_id, "Stage", "$default", { stat = "Sum", label = "4XX" }],
            ["AWS/ApiGateway", "5xx", "ApiId", local.dash_api_id, "Stage", "$default", { stat = "Sum", label = "5XX" }],
          ]
        })
      },

      # ------------------------------------------------------ Lambda principal
      {
        type       = "text"
        x          = 0
        y          = 7
        width      = 24
        height     = 1
        properties = { markdown = "## Lambda principal (${local.lambda_name})" }
      },
      {
        type   = "metric"
        x      = 0
        y      = 8
        width  = 6
        height = 6
        properties = merge(local.dash_widget, {
          title   = "Lambda API - Invocations"
          metrics = [["AWS/Lambda", "Invocations", "FunctionName", local.lambda_name, { stat = "Sum" }]]
        })
      },
      {
        type   = "metric"
        x      = 6
        y      = 8
        width  = 6
        height = 6
        properties = merge(local.dash_widget, {
          title = "Lambda API - Duration (ms)"
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", local.lambda_name, { stat = "Average", label = "avg" }],
            ["AWS/Lambda", "Duration", "FunctionName", local.lambda_name, { stat = "p95", label = "p95" }],
            ["AWS/Lambda", "Duration", "FunctionName", local.lambda_name, { stat = "Maximum", label = "max" }],
          ]
        })
      },
      {
        type   = "metric"
        x      = 12
        y      = 8
        width  = 6
        height = 6
        properties = merge(local.dash_widget, {
          title = "Lambda API - Errors / Throttles"
          metrics = [
            ["AWS/Lambda", "Errors", "FunctionName", local.lambda_name, { stat = "Sum" }],
            ["AWS/Lambda", "Throttles", "FunctionName", local.lambda_name, { stat = "Sum" }],
          ]
        })
      },
      {
        type   = "metric"
        x      = 18
        y      = 8
        width  = 6
        height = 6
        properties = merge(local.dash_widget, {
          title   = "Lambda API - Concurrent Executions"
          metrics = [["AWS/Lambda", "ConcurrentExecutions", "FunctionName", local.lambda_name, { stat = "Maximum" }]]
        })
      },

      # ------------------------------------------------------------ SNS y SQS
      {
        type       = "text"
        x          = 0
        y          = 14
        width      = 24
        height     = 1
        properties = { markdown = "## SNS y SQS" }
      },
      {
        type   = "metric"
        x      = 0
        y      = 15
        width  = 6
        height = 6
        properties = merge(local.dash_widget, {
          title = "SNS - NumberOfMessagesPublished"
          metrics = [
            ["AWS/SNS", "NumberOfMessagesPublished", "TopicName", local.dash_sns, { stat = "Sum", label = "Published" }],
            ["AWS/SNS", "NumberOfNotificationsDelivered", "TopicName", local.dash_sns, { stat = "Sum", label = "Delivered" }],
            ["AWS/SNS", "NumberOfNotificationsFailed", "TopicName", local.dash_sns, { stat = "Sum", label = "Failed" }],
          ]
        })
      },
      {
        type   = "metric"
        x      = 6
        y      = 15
        width  = 6
        height = 6
        properties = merge(local.dash_widget, {
          title = "SQS - NumberOfMessagesSent / Received / Deleted"
          metrics = [
            ["AWS/SQS", "NumberOfMessagesSent", "QueueName", local.dash_sqs, { stat = "Sum", label = "Sent" }],
            ["AWS/SQS", "NumberOfMessagesReceived", "QueueName", local.dash_sqs, { stat = "Sum", label = "Received" }],
            ["AWS/SQS", "NumberOfMessagesDeleted", "QueueName", local.dash_sqs, { stat = "Sum", label = "Deleted" }],
          ]
        })
      },
      {
        type   = "metric"
        x      = 12
        y      = 15
        width  = 6
        height = 6
        properties = merge(local.dash_widget, {
          title   = "SQS - ApproximateNumberOfMessagesVisible"
          metrics = [["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", local.dash_sqs, { stat = "Maximum" }]]
        })
      },
      {
        type   = "metric"
        x      = 18
        y      = 15
        width  = 6
        height = 6
        properties = merge(local.dash_widget, {
          title = "SQS - Edad del mensaje mas antiguo (s) / DLQ"
          metrics = [
            ["AWS/SQS", "ApproximateAgeOfOldestMessage", "QueueName", local.dash_sqs, { stat = "Maximum", label = "Edad max (s)" }],
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", local.dash_dlq, { stat = "Maximum", label = "Mensajes en DLQ", yAxis = "right" }],
          ]
        })
      },

      # -------------------------------------------------- Notification Lambda
      {
        type       = "text"
        x          = 0
        y          = 21
        width      = 24
        height     = 1
        properties = { markdown = "## Notification Lambda (${local.notification_lambda_name})" }
      },
      {
        type   = "metric"
        x      = 0
        y      = 22
        width  = 6
        height = 6
        properties = merge(local.dash_widget, {
          title   = "Notification Lambda - Concurrent Executions"
          metrics = [["AWS/Lambda", "ConcurrentExecutions", "FunctionName", local.notification_lambda_name, { stat = "Maximum" }]]
        })
      },
      {
        type   = "metric"
        x      = 6
        y      = 22
        width  = 6
        height = 6
        properties = merge(local.dash_widget, {
          title = "Notification Lambda - Duration (ms)"
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", local.notification_lambda_name, { stat = "Average", label = "avg" }],
            ["AWS/Lambda", "Duration", "FunctionName", local.notification_lambda_name, { stat = "Maximum", label = "max" }],
          ]
        })
      },
      {
        type   = "metric"
        x      = 12
        y      = 22
        width  = 6
        height = 6
        properties = merge(local.dash_widget, {
          title = "Notification Lambda - Errors / Throttles"
          metrics = [
            ["AWS/Lambda", "Errors", "FunctionName", local.notification_lambda_name, { stat = "Sum" }],
            ["AWS/Lambda", "Throttles", "FunctionName", local.notification_lambda_name, { stat = "Sum" }],
          ]
        })
      },
      {
        type   = "metric"
        x      = 18
        y      = 22
        width  = 6
        height = 6
        properties = merge(local.dash_widget, {
          title   = "Notification Lambda - Invocations"
          metrics = [["AWS/Lambda", "Invocations", "FunctionName", local.notification_lambda_name, { stat = "Sum" }]]
        })
      },

      # ----------------------------------------------------- CloudWatch Logs
      {
        type       = "text"
        x          = 0
        y          = 28
        width      = 24
        height     = 1
        properties = { markdown = "## CloudWatch Logs" }
      },
      {
        type   = "log"
        x      = 0
        y      = 29
        width  = 12
        height = 6
        properties = {
          region = var.aws_region
          title  = "API Gateway - requests por status (access logs)"
          view   = "table"
          query  = "SOURCE '${aws_cloudwatch_log_group.api_gateway.name}' | stats count(*) as requests by status | sort requests desc"
        }
      },
      {
        type   = "log"
        x      = 12
        y      = 29
        width  = 12
        height = 6
        properties = {
          region = var.aws_region
          title  = "Notification Lambda - errores recientes"
          view   = "table"
          query  = "SOURCE '${aws_cloudwatch_log_group.notification_lambda.name}' | filter level = 'ERROR' | fields @timestamp, message | sort @timestamp desc | limit 20"
        }
      },
    ]
  })
}
