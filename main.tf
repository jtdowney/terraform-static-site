variable "site_domain" {}
variable "certificate_arn" {}
variable "price_class" {
  default = "PriceClass_100"
}

output "name_servers" {
  value = "${aws_route53_zone.zone.name_servers}"
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "origin" {
  bucket = "origin.${var.site_domain}"
  acl = "public-read"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "PublicReadForGetBucketObjects",
    "Effect": "Allow",
    "Principal": "*",
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::origin.${var.site_domain}/*"
  }]
}
EOF

  website {
    index_document = "index.html"
  }
}

resource "aws_s3_bucket" "origin_www" {
  bucket = "origin.www.${var.site_domain}"
  acl = "public-read"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "PublicReadForGetBucketObjects",
    "Effect": "Allow",
    "Principal": "*",
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::origin.www.${var.site_domain}/*"
  }]
}
EOF

  website {
    redirect_all_requests_to = "https://${var.site_domain}"
  }
}

resource "aws_cloudfront_distribution" "distribution" {
  origin {
    domain_name = "${aws_s3_bucket.origin.website_endpoint}"
    origin_id = "origin"

    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    target_origin_id = "origin"
    min_ttl = 0
    default_ttl = 3600
    max_ttl = 86400

    forwarded_values {
      query_string = true
      cookies {
        forward = "none"
      }
    }
  }

  viewer_certificate {
    minimum_protocol_version = "TLSv1"
    acm_certificate_arn = "${var.certificate_arn}"
    ssl_support_method = "sni-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  enabled = true
  aliases = ["${var.site_domain}"]
  price_class = "${var.price_class}"
  default_root_object = "index.html"
}

resource "aws_cloudfront_distribution" "distribution_www" {
  origin {
    domain_name = "${aws_s3_bucket.origin_www.website_endpoint}"
    origin_id = "origin"

    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods = ["GET", "HEAD"]
    viewer_protocol_policy = "allow-all"
    target_origin_id = "origin"
    min_ttl = 0
    default_ttl = 3600
    max_ttl = 86400

    forwarded_values {
      query_string = true
      cookies {
        forward = "none"
      }
    }
  }

  viewer_certificate {
    minimum_protocol_version = "TLSv1"
    acm_certificate_arn = "${var.certificate_arn}"
    ssl_support_method = "sni-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  enabled = true
  aliases = ["www.${var.site_domain}"]
  price_class = "${var.price_class}"
}

resource "aws_route53_zone" "zone" {
  name = "${var.site_domain}"
}

resource "aws_route53_record" "root" {
  zone_id = "${aws_route53_zone.zone.zone_id}"
  name = "${var.site_domain}"
  type = "A"

  alias {
    name = "${aws_cloudfront_distribution.distribution.domain_name}"
    zone_id = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www" {
  zone_id = "${aws_route53_zone.zone.zone_id}"
  name = "www.${var.site_domain}"
  type = "A"

  alias {
    name = "${aws_cloudfront_distribution.distribution_www.domain_name}"
    zone_id = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}
