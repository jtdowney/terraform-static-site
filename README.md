# terraform-static-site

Terraform code to spin up a static site using Amazon's S3, CloudFront, Route53, and Certificate Manager.

## Assumptions

* You want HTTPS everywhere
* You want a naked top level domain that serves content
* You want a www subdomain to redirect to the top level domain
* You're ok with SNI for HTTPS (avoids an expensive dedicated IP fee)

## Usage

Required variables:

* AWS Access Key ID and Secret Access Key - These are assumed to be in your environment. If you're on macOS, I highly recommend checking out [envchain](https://github.com/sorah/envchain) for securely storing the environment variables.
* `site_domain` - the naked top level domain to use (e.g. jtdowney.com)
* `certificate_arn` - the ARN from AWS Certificate Manager, this must be requested in the AWS console due to the verification step. You need to add both the top level domain and the www subdomain to the same certificate. Also, the certificate must be in the us-east-1 region or it won't work.

Optional variables:

* `price_class` - [price class for CloudFront](https://www.terraform.io/docs/providers/aws/r/cloudfront_distribution.html#price_class). This defaults to `PriceClass_100`, which is coverage over the US, Canada, and Europe.

Outputs:

* `name_servers` - the name servers from Route53 to configure your domain name with.
* `origin_bucket` - S3 bucket to put your static site content in.
