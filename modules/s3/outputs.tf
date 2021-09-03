output "bucket_id" {
    description = "Name (id) of the bucket"
    value = aws_s3_bucket.s3_sources.id
}

output "bucket-region" {
    description = "The AWS region this bucket resides in."
    value = aws_s3_bucket.s3_sources.region
}
