# azure-personal-lz

A personal-scale Azure landing zone in Terraform for one subscription. It sets
up the guardrails only; workloads are added later as new `.tf` files.

## Layout

```
bootstrap/      run once, locally: Terraform state storage + CI/CD identity (OIDC)
landing-zone/   remote state
  governance.tf     mg-personal (with the subscription in it), policies, budget alerts
```

Policies assigned on `mg-personal`:

- Allowed locations (resources and resource groups): Australia East only.
- Network interfaces must not have public IPs.

The budget sends alerts at 50% and 90% of actual spend and at 100% forecast.

## Expected cost

Effectively zero. Management groups, policies and budgets are free. The only
billable things are bootstrap's state storage account and identity, which cost
cents per month.

## First-time setup

Prereqs: Terraform >= 1.9, Azure CLI, `az login` as the subscription Owner.

```sh
# 1. Bootstrap (local state)
cd bootstrap
cp terraform.tfvars.example terraform.tfvars   # fill in, never commit
terraform init && terraform apply

# 2. Landing zone (remote state)
cd ../landing-zone
cp backend.hcl.example backend.hcl             # use the bootstrap output
cp terraform.tfvars.example terraform.tfvars   # fill in, never commit
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

Run the first landing-zone apply yourself: creating the management group and
moving the subscription needs your own tenant permissions. After that, grant
the CI/CD identity Owner on `mg-personal` and let the pipeline take over:

```sh
az role assignment create --assignee <cicd_client_id> --role Owner \
  --scope /providers/Microsoft.Management/managementGroups/mg-personal
```

## GitHub Actions

`.github/workflows/terraform.yml` runs:

- **validate** on every PR and push: `fmt -check` and `validate` for both roots. Needs no Azure access.
- **plan** on PRs, with the plan in the job summary.
- **apply** on merge to `main`, in the `prod` environment.

Plan and apply are skipped until these exist. None of them are secrets, so
they are repository **variables** (Settings > Secrets and variables > Actions > Variables):

| Variable | Value |
|---|---|
| `AZURE_CLIENT_ID` | bootstrap output `cicd_client_id` |
| `AZURE_TENANT_ID` | bootstrap output `tenant_id` |
| `AZURE_SUBSCRIPTION_ID` | your subscription ID |
| `NAME_SUFFIX` | same as in tfvars |
| `BUDGET_CONTACT_EMAILS` | HCL list, e.g. `["you@example.com"]` |

Also create a `prod` environment (Settings > Environments) and add yourself as
a required reviewer, so every apply waits for your click.

## Adding a workload later

Add a new `.tf` file in `landing-zone/` (for example `sql.tf` with its own
resource group). The policies and pipeline already cover it.
