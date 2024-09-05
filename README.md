
## Run in Cloud Shell

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://shell.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https%3A%2F%2Fgithub.com%2Fepmcseclab%2Fsafecloud-bootstrap&cloudshell_tutorial=tutorial.md)

This script automates the creation of a Google Cloud Workload Identity Pool, allowing a GitHub Actions workflow to authenticate as a Google Cloud service account without managing long-lived service account keys.

#### Step-by-Step Breakdown

1. **Setting Up Input Parameters**:
   - The script accepts three parameters:
     - `-p`: Google Cloud Project ID.
     - `-s`: Service account name to be created.
     - `-r`: GitHub organization/repository.

   ```bash
   while getopts p:r:s: flag
   do
       case "${flag}" in
           p) PROJECT_ID=${OPTARG};;
           r) GH_REPO=${OPTARG};;
           s) SA_NAME=${OPTARG};;
       esac
   done
   ```

2. **Fetching Organization ID and Project Number**:
   - Retrieves the Organization ID and Project Number for the specified project.

   ```bash
   ORGANIZATION_ID=$(gcloud projects get-ancestors "${PROJECT_ID}" | grep organization | awk '{print $1}')
   PROJECT_NUMBER=$(gcloud projects list --filter="${PROJECT_ID}" --format="value(PROJECT_NUMBER)")
   ```

3. **Creating the Service Account**:
   - Creates a new service account named `${SA_NAME}` in the specified project.

   ```bash
   gcloud iam service-accounts create "${SA_NAME}" \
       --project="${PROJECT_ID}" \
       --description="scld-bootstrap-sa" \
       --display-name="scld-bootstrap-sa"
   ```

4. **Assigning IAM Roles to the Service Account**:
   - Grants the service account several IAM roles at the organization level for billing management, resource creation, and organization administration.

   ```bash
   gcloud organizations add-iam-policy-binding "${ORGANIZATION_ID}"\
       --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" --role="roles/billing.admin"
   
   gcloud organizations add-iam-policy-binding "${ORGANIZATION_ID}"\
       --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" --role="roles/orgpolicy.policyAdmin"
   
   gcloud organizations add-iam-policy-binding "${ORGANIZATION_ID}"\
       --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" --role="roles/resourcemanager.folderCreator"
   
   gcloud organizations add-iam-policy-binding "${ORGANIZATION_ID}"\
       --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" --role="roles/resourcemanager.organizationAdmin"
   
   gcloud organizations add-iam-policy-binding "${ORGANIZATION_ID}"\
       --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" --role="roles/resourcemanager.projectCreator"
   
   gcloud organizations add-iam-policy-binding "${ORGANIZATION_ID}"\
       --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" --role="roles/iam.serviceAccountTokenCreator"
   ```

5. **Creating the Workload Identity Pool**:
   - Creates a Workload Identity Pool named `${SA_NAME}` under the specified project.

   ```bash
   gcloud iam workload-identity-pools create "${SA_NAME}" \
     --project="${PROJECT_ID}" \
     --location="global" \
     --display-name="${SA_NAME}"
   ```

6. **Creating the Workload Identity Pool Provider**:
   - An OIDC provider is created within the Workload Identity Pool, configured to trust tokens issued by GitHub Actions, linking it to the specific GitHub repository.

   ```bash
   gcloud iam workload-identity-pools providers create-oidc "${SA_NAME}" \
     --project="${PROJECT_ID}" \
     --location="global" \
     --workload-identity-pool="${SA_NAME}" \
     --display-name="${SA_NAME}" \
     --attribute-mapping="attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner,google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.aud=assertion.aud" \
     --issuer-uri="https://token.actions.githubusercontent.com"
   ```

7. **Binding the Workload Identity Provider to the Service Account**:
   - Grants the service account the `roles/iam.workloadIdentityUser` role, allowing it to be impersonated by the GitHub Actions workflow.

   ```bash
   gcloud iam service-accounts add-iam-policy-binding "${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
     --project="${PROJECT_ID}" \
     --role="roles/iam.workloadIdentityUser" \
     --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${SA_NAME}/attribute.repository/${GH_REPO}"
   ```

8. **Output**:
   - Outputs the details of the created Workload Identity Provider and the associated service account.

   ```bash
   echo "workload_identity_provider : 'projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${SA_NAME}/providers/${SA_NAME}'"
   echo "service_account : '${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com'"
   ```

## `platform_config.yaml`

Fill in a `platform_config.yaml` file in the `environments` directory of your GitHub repository. This file should contain the necessary configuration for the GCP organization setup:

```yaml
common:
  project_id: "YOUR_PROJECT_ID"
  service_account_name: "YOUR_SERVICE_ACCOUNT_NAME"
  github_repo: "YOUR_GITHUB_ORG/YOUR_REPOSITORY"
  billing_account: "YOUR_BILLING_ACCOUNT_ID"
  org_id: "YOUR_ORGANIZATION_ID"
  folder_prefix: "YOUR_FOLDER_PREFIX"
  project_prefix: "YOUR_PROJECT_PREFIX"
  default_region: "YOUR_DEFAULT_REGION"
```

## GitHub Actions Workflow

A GitHub Actions workflow is set up to automate the process. Below is a sample `.github/workflows/org-bootstrap.yml`:


### Setting Up GitHub Actions with Google Cloud Workload Identity Federation

To enable your GitHub Actions workflows to authenticate with Google Cloud using Workload Identity Federation (WIF), you need to configure your GitHub repository with specific secrets. These secrets will store sensitive information, such as the Workload Identity Provider details and the Service Account email, which your workflows will use to authenticate securely.

### Required Secrets

For the GitHub Actions workflow to work correctly with Google Cloud, you must manually add the following secrets to your GitHub repository:

- **`GOOGLE_WIF_PROVIDER`**:
  - Contains the fully qualified identifier for the Workload Identity Provider that you created in Google Cloud.
  - Example value: `projects/1234567890/locations/global/workloadIdentityPools/my-pool/providers/my-provider`

- **`GOOGLE_WIF_SERVICE_ACCOUNT`**:
  - Stores the email address of the Google Cloud Service Account that the GitHub Action will impersonate.
  - Example value: `my-service-account@my-project.iam.gserviceaccount.com`

### Running the Workflow

To run the workflow, navigate to the "Actions" tab in your GitHub repository and manually trigger the `Bootstrap GCP Organization` workflow using the "Run workflow" button.

---

Here's a simplified description of what this GitHub Actions workflow does and its output:


# Workflow Description: Bootstrap GCP Organization

## Overview

This GitHub Actions workflow is designed to bootstrap a Google Cloud Platform (GCP) organization using Terraform and Terragrunt. It allows you to either plan or apply infrastructure changes based on your choice.

## What It Does

1. **Setup**:
   - **Checks out** the repository's code.
   - **Sets up** tools like `yq` (for YAML processing), Terraform, and Terragrunt.
   - **Configures** authentication with Google Cloud using Workload Identity Federation.

2. **Run Terragrunt Commands**:
   - Executes the `terragrunt plan` or `terragrunt apply` command in the `terragrunt/0-bootstrap` directory, depending on the input choice.

3. **Set Up Environment Variables**:
   - Finds and sets the path to the `platform_config.yaml` file.
   - If `apply` is selected, it extracts and sets key output values from Terragrunt commands as environment variables.

4. **Update Configuration**:
   - Updates the `platform_config.yaml` file with the new values obtained from the Terragrunt outputs.
   - Initializes and migrates the state of Terragrunt.

5. **Commit Changes**:
   - Commits the updated `platform_config.yaml` back to the repository with a message indicating that bootstrapping is complete.

## Inputs

- **`command`**: Choose between `plan` or `apply` to control the Terraform/Terragrunt execution mode.

## Outputs

- **For `apply` Command**:
  - **SEED_PROJECT_ID**: The ID of the seed project.
  - **SEED_BUCKET_NAME**: The name of the seed bucket.
  - **SEED_WIF_SA**: The service account used for Workload Identity Federation.
  - **SEED_WIF_PROVIDER**: The Workload Identity Provider name.

These values are used to update the `platform_config.yaml` file and migrate the Terragrunt state.

---