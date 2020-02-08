docker run -it --network host -e PGPASSWORD=secret postgres:alpine  pg_dump -h localhost -p 5433 -U default default > backup.sql
cat backup.sql | docker run -i --network host -e PGPASSWORD=secret postgres:alpine psql -h localhost -p 5433 -U default