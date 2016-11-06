#!/bin/bash

fw_depends java resin maven mono dsl_platform

source $IROOT/java.installed

echo "Changing the database"
sed -i 's|localhost|'"${DBHOST}"'|g' src/main/resources/hello/revenj.properties

mvn clean compile assembly:single
java -jar target\revenj-undertow-1.0.1-jar-with-dependencies.jar &