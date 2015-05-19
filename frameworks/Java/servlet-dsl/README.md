#DSL Servlet Benchmarking Test

This servlet uses precompiled DSL model for endpoint communication.

### DSL model
Data structures are defined in external schema

* [DSL source](src/main/java/dsl/model.dsl)

### JSON Encoding Test
DSL client Java is used for JSON encoding.

* [JSON test source](src/main/java/dsl/JsonServlet.java)

### Data-Store/Database Mapping Test
PostgreSQL JDBC4.1

* [DB test source](src/main/java/dsl/DbServlet.java)
* [Queries test source](src/main/java/dsl/QueriesServlet.java)
* [Updates test source](src/main/java/dsl/UpdateServlet.java)

## Infrastructure Software Versions
The tests were run with:

* [Oracle Java 1.7](https://www.oracle.com/java/)
* [Resin 4.0](http://www.caucho.com/)
* [DSL client Java 1.3](http://github.com/ngs-doo/dsl-client-java)
* [PostgreSQL 9.4](http://www.postgresql.com/)

## Test URLs
### JSON Encoding Test

http://localhost:8080/servlet/json

### Data-Store/Database Mapping Test

http://localhost:8080/servlet/db
http://localhost:8080/servlet/queries?queries=10
http://localhost:8080/servlet/update?queries=10

