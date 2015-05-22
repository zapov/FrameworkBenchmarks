#!/bin/bash

. ${IROOT}/mono.installed

echo "Cleaning up..."
rm -rf $TROOT/exe $TROOT/tmp dsl-clc.jar

echo "Download DSL compiler client"
wget https://github.com/ngs-doo/dsl-compiler-client/releases/download/1.3.0/dsl-clc.jar

echo "Setting up the directories"
mkdir -p $TROOT/exe $TROOT/tmp

echo "Compiling the server model, and downloading dependencies..."
java -jar $TROOT/dsl-clc.jar \
    temp=$TROOT/tmp/ \
    dsl=$TROOT/Revenj.Bench \
    manual-json \
    revenj=$TROOT/exe/ServerModel.dll \
    no-prompt \
    compiler \
    dependencies:revenj=$TROOT/exe \
    download

echo "Compiling the benchmark project..."
xbuild $TROOT/Revenj.Bench/Revenj.Bench.csproj /t:Rebuild /p:Configuration=Release

echo "Copying the configuration template"
cat $TROOT/Revenj.Http.exe.config.template | sed 's|\(ConnectionString.*server=\)localhost|\1'"${DBHOST}"'|' > $TROOT/exe/Revenj.Http.exe.config

echo "Running the Revenj instance"
mono $TROOT/exe/Revenj.Http.exe
sleep 5
