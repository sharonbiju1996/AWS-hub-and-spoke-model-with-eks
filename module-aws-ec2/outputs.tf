output "cache_mq_instance_id" {
  description = "Instance ID for Redis + RabbitMQ EC2"
  value       = aws_instance.cache_mq.id
}

output "mongo_instance_id" {
  description = "Instance ID for MongoDB EC2"
  value       = aws_instance.mongo.id
}

output "cache_mq_private_ip" {
  description = "Private IP address of Redis + RabbitMQ EC2"
  value       = aws_instance.cache_mq.private_ip
}

output "mongo_private_ip" {
  description = "Private IP address of MongoDB EC2"
  value       = aws_instance.mongo.private_ip
}

output "cache_mq_sg_id" {
  description = "Security group ID for cache + mq instance"
  value       = aws_security_group.cache_mq_sg.id
}

output "mongo_sg_id" {
  description = "Security group ID for mongo instance"
  value       = aws_security_group.mongo_sg.id
}

# Add these outputs to your existing outputs.tf

