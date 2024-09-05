## Using the Provided Script

This script automates the creation of a Google Cloud Workload Identity Pool, allowing a GitHub Actions workflow to authenticate as a Google Cloud service account without managing long-lived service account keys.

<walkthrough-project-setup></walkthrough-project-setup>

Try running a command now:

```bash
./bootstrap-wif.sh -p '<walkthrough-project-id/>' -s 'safecloud-bootstrap' -r 'EPAM-SP/client-contoso-gcp' 
```

**Tip**: Click the copy button on the side of the code box to paste the command in the Cloud Shell terminal to run it.

<walkthrough-pin-section-icon></walkthrough-pin-section-icon>
Please copy and save "workload_identity_provider" and "service_account" values returned by script


