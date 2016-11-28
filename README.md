[![](https://images.microbadger.com/badges/image/rawmind/alpine-postgres.svg)](https://microbadger.com/images/rawmind/alpine-postgres "Get your own image badge on microbadger.com")

alpine-postgres
=============

This image is the postgres base. It comes from [alpine-monit][alpine-monit].

## Build

```
docker build -t rawmind/alpine-postgres:<version> .
```

## Versions

- `9.5.5` [(Dockerfile)](https://github.com/rawmind0/alpine-postgres/blob/9.5.5/Dockerfile)

## Configuration

This image runs [postgres][postgres] with monit. postgres is started with user and group "postgres".

Besides, you can customize the configuration in several ways:

### Default Configuration

Postgres is installed with the default configuration and some parameters can be overrided with env variables:

- POSTGRES_PASSWORD="postgres"		# Password for the postgres user
- POSTGRES_USER="postgres"			# User to create at postgres
- POSTGRES_DB="test"				# DB to create at postgres
- POSTGRES_INITDB_ARGS="-E UTF8"	# Initdb params to create DB
- POSTGRES_START_ARGS="-c listen_addresses='*'"	#DB start args
- POSTGRES_SHUTDOWN_MODE="immediate"			# DB shutdown mode


[alpine-monit]: https://github.com/rawmind0/alpine-monit/
[postgres]: https://www.postgresql.org
