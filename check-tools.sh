#!/bin/bash

echo "Checking required tools availability..."
echo "========================================"

# Check Java
echo -n "Java: "
if command -v java &> /dev/null; then
    java_version=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2)
    echo "Found - Version: $java_version"
else
    echo "Not found"
fi

# Check Maven
echo -n "Maven: "
if command -v mvn &> /dev/null; then
    mvn_version=$(mvn -version 2>&1 | head -n 1 | cut -d' ' -f3)
    echo "Found - Version: $mvn_version"
else
    echo "Not found"
fi

# Check Node.js
echo -n "Node.js: "
if command -v node &> /dev/null; then
    node_version=$(node --version)
    echo "Found - Version: $node_version"
else
    echo "Not found"
fi

# Check npm
echo -n "npm: "
if command -v npm &> /dev/null; then
    npm_version=$(npm --version)
    echo "Found - Version: $npm_version"
else
    echo "Not found"
fi

# Check Docker
echo -n "Docker: "
if command -v docker &> /dev/null; then
    docker_version=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
    echo "Found - Version: $docker_version"
else
    echo "Not found"
fi

# Check kubectl
echo -n "kubectl: "
if command -v kubectl &> /dev/null; then
    kubectl_version=$(kubectl version --client --short 2>&1 | cut -d' ' -f3)
    echo "Found - Version: $kubectl_version"
else
    echo "Not found"
fi

echo "========================================"
echo "If any tool shows 'Not found', please install it before running the Jenkins pipeline." 