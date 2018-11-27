# LDAP Sync

This application syncs data from the campus DB2 datacenter and populates/updates
specific LDAP attributes for Library employees

## Local Development

### Docker
1. Build docker image `docker build -t ldap_sync:latest .`
1. Run image `docker run --rm ldap_sync sh -c "ruby sync.rb"`
1. Run image with environment variables file and write output to a file `docker run --env-file <path_to_environment_variables/ldap_rsync.env> --rm ldap_sync ruby sync.rb >> <path_to_log_file/ldap_sync.log>
