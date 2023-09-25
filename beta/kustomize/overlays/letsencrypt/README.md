# Let's Encrypt

## Note

It's very likely that on initial deployment of a Kustomize bridge, you will not set 
this value. Follow the instructions in the main readme for when to edit this overlay.

To use the Let's Encrypt overlay, modify the value of the patch for `OP_TLS_DOMAIN`
contained in `patch-configmap.yaml` to the fully qualified domain name of a public DNS
record that points to the external IP address of the load balancer.