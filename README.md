# LDAP Sync

This application syncs data from the campus DB2 datacenter and populates/updates
specific LDAP attributes for Library employees

## Local Development

### Docker
1. Build docker image `docker build -t ldap_sync:latest .`
1. Run image `docker run --rm ldap_sync sh -c "ruby sync.rb"`
