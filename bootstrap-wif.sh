#!/usr/bin/env bash

if [ $# == 0 ]; then
    echo "Usage: $0 -p 'PROJECT_ID' -s 'SERVICE_ACCOUNT_NAME' -r 'GITHUB_ORG/GITHUB_REPO' "
    echo "* -p: GCP Project ID"
    echo "* -s: GCP Service account name"
    echo "* -r: Github organization/repository"

    exit 3
fi

./bootstrap-wif.sh -p 'gcp-lab-host-project' -s 'safecloud-bootstrap' -r 'EPAM-SP/client-contoso-gcp' 

while getopts p:r:s: flag
do
    case "${flag}" in
        p) PROJECT_ID=${OPTARG};;
        r) GH_REPO=${OPTARG};;
        s) SA_NAME=${OPTARG};;
    esac
done

gcloud config set project $PROJECT_ID
ORGANIZATION_ID=$(gcloud projects get-ancestors "${PROJECT_ID}" --format="value(id,type)" | awk '$2 == "organization" {print $1}')
PROJECT_NUMBER=$(gcloud projects list --filter="${PROJECT_ID}" --format="value(PROJECT_NUMBER)")

gcloud iam service-accounts create "${SA_NAME}" \
    --project="${PROJECT_ID}" \
    --description="scld-bootstrap-sa" \
    --display-name="scld-bootstrap-sa"

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


gcloud iam workload-identity-pools create "${SA_NAME}" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --display-name="${SA_NAME}"

gcloud iam workload-identity-pools providers create-oidc "${SA_NAME}" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="${SA_NAME}" \
  --display-name="${SA_NAME}" \
  --attribute-mapping="attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner,google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.aud=assertion.aud" \
  --issuer-uri="https://token.actions.githubusercontent.com"


gcloud iam service-accounts add-iam-policy-binding "${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --project="${PROJECT_ID}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${SA_NAME}/attribute.repository/${GH_REPO}"

echo "workload_identity_provider : 'projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${SA_NAME}/providers/${SA_NAME}'"
echo "service_account : '${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com'"