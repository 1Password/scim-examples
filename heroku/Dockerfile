FROM 1password/scim:v2.6.2

WORKDIR /op-scim
COPY --chown=opuser:opuser ./heroku-op-scim.sh .
CMD ./heroku-op-scim.sh
