#!/usr/bin/env bash

set -euo pipefail

# Cores para output
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m"

echo -e "${BLUE}Starting deployment...${NC}"

# Check for Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed. Please install Docker and try again.${NC}"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo -e "${RED}Error: Docker is not running. Please start Docker and try again.${NC}"
    exit 1
fi

# Check for .env file
if [ ! -f .env ]; then
    echo -e "${RED}Error: .env file not found! A .env file with production secrets is required.${NC}"
    echo -e "${YELLOW}Please create one based on the instructions in the README.${NC}"
    exit 1
fi

# Check for placeholder secret
if grep -q "CHANGE_THIS_TO_A_VERY_SECURE_RANDOM_STRING" .env; then
    echo -e "${RED}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!${NC}"
    echo -e "${RED}!!! 보안 경고 !!!${NC}"
    echo -e "${RED}!!! Por favor, altere o ACCESS_TOKEN_SECRET no arquivo .env para uma string aleatória e segura antes de ir para a produção.${NC}"
    echo -e "${RED}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!${NC}"
    echo -e "${YELLOW}Deployment will continue in 10 seconds... Press Ctrl+C to cancel.${NC}"
    sleep 10
fi

echo -e "${BLUE}Building and starting services...${NC}"
docker compose -f docker-compose.prod.yml up -d --build --remove-orphans

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Deployment successful!${NC}"
    echo -e "Your application should be available at http://localhost"
    echo -e "Backend API is available at http://localhost:4000"
else
    echo -e "${RED}Deployment failed. Check the logs above for errors.${NC}"
fi
