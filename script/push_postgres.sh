docker run -it --network host -e PGPASSWORD=secret postgres:alpine  pg_dump -h 185.148.81.41 -p 5433 -U default default > backup.sql
cat backup.sql | docker run -i --network host -e PGPASSWORD=secret postgres:alpine psql -h 185.148.81.41 -p 5433 -U default