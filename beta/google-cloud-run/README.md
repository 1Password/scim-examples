# WIP

Create secret:

```sh
gcloud secrets create scimsession --data-file=$HOME/scimsession
```

Deploy:

```sh
gcloud run services replace op-scim-bridge-service.yaml &&
  gcloud run services add-iam-policy-binding op-scim-bridge-gcloud-yaml \
    --member="allUsers" \
    --role="roles/run.invoker"
```
