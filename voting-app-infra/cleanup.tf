# ============================================================
# SNS Topic — notification channel.
# Budgets needs somewhere to send the alert, same concept
# as before. One topic, can have multiple subscribers.
# ============================================================
resource "aws_sns_topic" "billing_alert" {
  name = "billing-alert-topic"
}

# ============================================================
# SNS Subscription — your email receives the alert.
# After apply, AWS sends a confirmation email.
# You MUST click confirm or alerts won't arrive.
# ============================================================
resource "aws_sns_topic_subscription" "billing_email" {
  topic_arn = aws_sns_topic.billing_alert.arn
  protocol  = "email"
  endpoint  = "abdelmonaemmedhat@gmail.com"   # <-- change this
}

# ============================================================
# AWS Budget — tracks your monthly spend.
# limit_amount = $ per month
# time_unit    = MONTHLY resets every month automatically
# cost_types   = what to include in the calculation:
#   - include_tax: yes, include VAT/tax
#   - include_support: yes, include support plan cost
#   - include_other_subscription: yes, include everything
# ============================================================
resource "aws_budgets_budget" "monthly" {
  name         = "monthly-2usd-budget"
  budget_type  = "COST"
  limit_amount = "2"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_types {
    include_tax                = true
    include_support            = true
    include_other_subscription = true
    include_upfront            = true
    include_recurring          = true
    include_refund             = false
    include_credit            = false
    use_blended                = false
  }

  # ============================================================
  # Notification 1 — actual spend hits 80% of $5 = $4
  # comparison_operator: GREATER_THAN
  # notification_type: ACTUAL = real charges so far this month
  # threshold_type: PERCENTAGE
  # ============================================================
  notification {
    comparison_operator        = "GREATER_THAN"
    notification_type          = "ACTUAL"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    subscriber_sns_topic_arns  = [aws_sns_topic.billing_alert.arn]
  }

  # ============================================================
  # Notification 2 — actual spend hits 100% of $5
  # ============================================================
  notification {
    comparison_operator        = "GREATER_THAN"
    notification_type          = "ACTUAL"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    subscriber_sns_topic_arns  = [aws_sns_topic.billing_alert.arn]
  }

  # ============================================================
  # Notification 3 — FORECASTED spend will exceed $5
  # AWS looks at your usage trend and predicts end-of-month cost.
  # This warns you BEFORE you actually hit the limit.
  # ============================================================
  notification {
    comparison_operator        = "GREATER_THAN"
    notification_type          = "FORECASTED"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    subscriber_sns_topic_arns  = [aws_sns_topic.billing_alert.arn]
  }
}


resource "aws_sns_topic_policy" "billing_alert" {
  arn = aws_sns_topic.billing_alert.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowBudgetsPublish"
      Effect    = "Allow"
      Principal = {
        Service = "budgets.amazonaws.com"
      }
      Action   = "SNS:Publish"
      Resource = aws_sns_topic.billing_alert.arn
    }]
  })
}
