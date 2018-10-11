@echo off

md session

docker run -it -v "%CD%\session":"/op-scim/session" 1password/scim:latest /op-scim/create-session-docker.sh

move .\session\scimsession .\
rd session