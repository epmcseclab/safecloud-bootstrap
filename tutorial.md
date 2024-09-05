## Using the Provided Script

This script automates the creation of a Google Cloud Workload Identity Pool, allowing a GitHub Actions workflow to authenticate as a Google Cloud service account without managing long-lived service account keys.

<walkthrough-project-setup></walkthrough-project-setup>

Try running a command now:

```bash
./bootstrap-wif.sh -p '<walkthrough-project-id/>' -s 'safecloud-bootstrap' -r 'EPAM-SP/client-contoso-gcp' 
```

**Tip**: Click the copy button on the side of the code box to paste the command in the Cloud Shell terminal to run it.


echo "workload_identity_provider : 'projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${SA_NAME}/providers/${SA_NAME}'"
echo "service_account : '${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com'"


