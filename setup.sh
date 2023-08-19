#!/usr/bin/env bash

echo "Cleaning and recreating plugins dir"
rm -rf ./plugins
mkdir ./plugins

echo "Setting up java-debug"

TMP_DIR=$(mktemp -d)

git clone https://github.com/microsoft/java-debug.git ${TMP_DIR}

pushd ${TMP_DIR}
  JAVA_HOME=$JAVA_HOME_17 ./mvnw clean install
popd

cp ${TMP_DIR}/com.microsoft.java.debug.plugin/target/*.jar ./plugins/ 

# rm -rf ${TMP_DIR}

echo "Setting up java-debug-test"

TMP_DIR=$(mktemp -d)

git clone https://github.com/microsoft/vscode-java-test.git ${TMP_DIR}

pushd ${TMP_DIR}
  npm install
  JAVA_HOME=$JAVA_HOME_17 npm run build-plugin
popd

cp ${TMP_DIR}/server/*.jar ./plugins/
# rm -rf ${TMP_DIR}
