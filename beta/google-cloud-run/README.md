# WIP

Create secret:

```sh
gcloud secrets create scimsession --data-file=$HOME/scimsession
```

Deploy:

```sh
curl --silent --show-error \
  https://raw.githubusercontent.com/1Password/scim-examples/solutions/pike/google-cloud-run/beta/google-cloud-run/op-scim-bridge-service.yaml |
  gcloud run services replace /dev/stdin &&
  gcloud run services add-iam-policy-binding op-scim-bridge \
    --member="allUsers" \
    --role="roles/run.invoker"
```
