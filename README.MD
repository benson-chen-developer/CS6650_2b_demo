# Product Service on AWS Fargate

A Go (Gin) product API, containerized with Docker and deployed to AWS ECS Fargate with Terraform.
Terraform builds the image, pushes it to ECR, and starts a Fargate task with a public IP.

| Method | Path | Description |
|---|---|---|
| GET | `/products/{productId}` | Fetch a product (IDs `1` and `2` are seeded) |
| POST | `/products/{productId}/details` | Replace an existing product's details |

The API listens on port **8081**.

## Configure AWS credentials

```bash
aws configure                                   
aws configure set aws_session_token <YOUR-SESSION-TOKEN>
```

## Deploy

```bash
cd terraform
terraform init
terraform apply -auto-approve
```

If you are on Apple Silicon use this instead.
I have Fargate running on ARM for my MAC.

```bash
terraform apply -auto-approve -var cpu_architecture=X86_64
```

The default region is `us-east-1` and I have it running on port `8081`. Make sure to change it if needed in variables.tf

## Send requests

You can get the public ip in your ECR under `CS6650L2-cluster`.

**Get a product**
```bash
curl http://$IP:8081/products/1
```
```json
{"product_id":1,"sku":"ABC-123-XYZ","manufacturer":"Apple","category_id":456,"weight":1250,"some_other_id":789}
```

**Product not found** (404)
```bash
curl -i http://$IP:8081/products/999
```
```json
{"error":"NOT_FOUND","message":"Product not found","details":"No product exists with ID 999"}
```

**Invalid ID** (400)
```bash
curl -i http://$IP:8081/products/abc
```
```json
{"error":"INVALID_INPUT","message":"The provided product ID is invalid"}
```

**Update a product** (204 No Content on success). All six fields are required.
```bash
curl -i -X POST http://$IP:8081/products/1/details \
  -H 'Content-Type: application/json' \
  -d '{"product_id":1,"sku":"NEW-SKU","manufacturer":"Acme","category_id":5,"weight":100,"some_other_id":9}'
```

A body with a missing or invalid field returns 400 with details about which rule failed.
Posting to an ID that doesn't exist returns 404.

## Clean up

```bash
cd terraform
terraform destroy -auto-approve
```

If the destroy fails on the ECR repository because it still contains images, delete the images
in the ECR console (or add `force_delete = true` to the repo in `terraform/modules/ecr/main.tf`) and rerun it.
