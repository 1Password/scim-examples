#!/bin/sh

OP_DIR="${HOME}/.op"
OP_SESSION_FILE="${OP_DIR}/scimsession"

mkdir -p "${OP_DIR}"
echo "${OP_SESSION}" > "${OP_SESSION_FILE}"

./op-scim \
		--port="${PORT}" \
		--redis-url="${OP_REDIS_URL}" \
		--session="${OP_SESSION_FILE}"
