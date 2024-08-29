## query_wrapper.py
it's a wrapper over sqlite3 queries. Gets info such as all recorded clients in a user's TCC.db and the root TCC.db.
You can also query it to output services used by an app/process/client and vice versa (given a service, which clients use that service?).
Usage:
```bash
./query_wrapper.py -h
```
## compute_services.sh
Gets all(?) services (or TCC policies) gathered from plists and the tccd binary.
Used this as reference: https://www.rainforestqa.com/blog/macos-tcc-db-deep-dive
