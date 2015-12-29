#!/bin/bash

fw_depends java8 resin maven mono

source $IROOT/java8.installed

echo "Cleaning up..."
rm -rf $TROOT/tmp $TROOT/model $TROOT/revenj.java $TROOT/dsl-clc.jar

echo "Download DSL compiler client"
wget -O $TROOT/dsl-clc.jar https://github.com/ngs-doo/dsl-compiler-client/releases/download/1.5.0/dsl-clc.jar

echo "Compiling the server model, and downloading dependencies..."
java -jar $TROOT/dsl-clc.jar \
	temp=$TROOT/tmp/ \
	force \
	dsl=$TROOT/src \
	manual-json \
	namespace=dsl \
	revenj.java=$TROOT/model/gen-model.jar \
	no-prompt \
	download

echo "Adding model to local Maven repository..."
mvn deploy:deploy-file \
	-Durl=file://model \
	-Dfile=model/gen-model.jar \
	-DgroupId=dsl \
	-DartifactId=gen-model \
	-Dpackaging=jar \
	-Dversion=1.0

echo "Changing the database"
cat $TROOT/web.xml | sed 's/localhost/'$DBHOST'/g' > $TROOT/src/main/webapp/WEB-INF/web.xml
	
mvn clean compile war:war
rm -rf $RESIN_HOME/webapps/*
cp target/revenj.war $RESIN_HOME/webapps/
JAVA_EXE=$JAVA_HOME/bin/java resinctl start
