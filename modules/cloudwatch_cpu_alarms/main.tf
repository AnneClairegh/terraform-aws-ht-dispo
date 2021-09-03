# Création de deux stratégies d'AutoScaling
# pour le scale up et pour le scale down

# Stratégies simple pour le scale up,
# en fonction d'un ajustement (ex : utilisation du CPU)
# de type "ChangeInCapacity"
# qui aura comme valeur "1"
resource "aws_autoscaling_policy" "my-cpu-policy-scaleup" {
	name                   = "my-cpu-policy-scaleup"
	autoscaling_group_name = var.asg_name
	adjustment_type        = "ChangeInCapacity"
	scaling_adjustment     = 1 # The number of instances by which to scale.
	cooldown               = 300 # (Optional) The amount of time, in seconds, after a scaling activity completes and before the next scaling activity can start.
	policy_type            = "SimpleScaling" #  If this value isn't provided, AWS will default to "SimpleScaling."
}

# Stratégies simple pour le scale down
# en fonction d'un ajustement (ex : utilisation du CPU)
# de type "ChangeInCapacity"
# qui aura comme valeur "-1"
resource "aws_autoscaling_policy" "my-cpu-policy-scaledown" {
	name                   = "${var.prefix_name}cpu-policy-scaledown"
	autoscaling_group_name = var.asg_name
	adjustment_type       = "ChangeInCapacity"
	scaling_adjustment     = "-1" # The number of instances by which to scale.
	cooldown               = 300 # (Optional) The amount of time, in seconds, after a scaling activity completes and before the next scaling activity can start.
	policy_type            = "SimpleScaling" #  If this value isn't provided, AWS will default to "SimpleScaling."
	
	# tags = { unsupported argument
	# 	Name = "${var.prefix_name}-scale-down-pol"
	# }
}


# Création de deux alarmes CloudWatch,
# basée sur l'utilisation moyenne du processeur

# Une alarme CloudWatch pour le scale up,
# se basant sur le métrique "CPUUtilization"
# avec seuil d'utilisation supérieur ou égale à 80% d'utilisation du CPU
# pour déclencher le stratégie ASG scale up
resource "aws_cloudwatch_metric_alarm" "my-cpu-alarm-scaleup" {
	alarm_name           = "${var.prefix_name}cpu-scaleup-alarm"
	alarm_description    = "${var.prefix_name}cpu-scaleup-alarm"
	# alarm_description    = "This metric monitors ec2 cpu utilization to scale up the ASG"
	comparison_operator  = "GreaterThanOrEqualToThreshold"
	evaluation_periods   = 2 # (Required) The number of periods over which data is compared to the specified threshold.
	metric_name          = "CPUUtilization" # (Optional) The name for the alarm's associated metric. 
	namespace            = "AWS/EC2" # (Optional) The namespace for the alarm's associated metric. 
	period               = 120 # (Optional) The period in seconds over which the specified statistic is applied.
	statistic            = "Average" # (Optional) The statistic to apply to the alarm's associated metric.
	threshold            = var.max_cpu_percent_alarm # (Optional) The value against which the specified statistic is compared. 

	dimensions           = {
		"AutoScalingGroupName" = var.asg_name
	}

	actions_enabled      = true # (Optional) Indicates whether or not actions should be executed during any changes to the alarm's state. Defaults to true.
	alarm_actions        = [aws_autoscaling_policy.my-cpu-policy-scaleup.arn]
	
	tags = {
		Name = "${var.prefix_name}my-cpu-alarm-scaleup"
	}
}

# Une alarme CloudWatch pour le scale down,
# se basant sur le métrique "CPUUtilization"
# avec seuil d'utilisation  inférieure à 5% d'utilisation du CPU
# pour déclencher la stratégie ASG scale down
resource "aws_cloudwatch_metric_alarm" "my-cpu-scaledown-alarm" {
	alarm_name           = "${var.prefix_name}cpu-scaledown-alarm"
	alarm_description    = "${var.prefix_name}cpu-scaledown-alarm"
	# alarm_description    = "This metric monitors ec2 cpu utilization to scale down the ASG"
	comparison_operator  = "LessThanThreshold"
	evaluation_periods   = 2 # (Required) The number of periods over which data is compared to the specified threshold.
	metric_name          = "CPUUtilization" # (Optional) The name for the alarm's associated metric. 
	namespace            = "AWS/EC2" # (Optional) The namespace for the alarm's associated metric. 
	period               = 120 # (Optional) The period in seconds over which the specified statistic is applied.
	statistic            = "Average" # (Optional) The statistic to apply to the alarm's associated metric.
	threshold            = var.min_cpu_percent_alarm # (Optional) The value against which the specified statistic is compared. 

	dimensions           = {
		"AutoScalingGroupName" = var.asg_name
	}

	actions_enabled      = true
	alarm_actions        = [aws_autoscaling_policy.my-cpu-policy-scaledown.arn]
	
	tags = {
		Name = "${var.prefix_name}my-cpu-alarm-scaledown"
	}
}
