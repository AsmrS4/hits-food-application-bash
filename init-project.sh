#!/bin/bash
set -e  # Остановить при ошибке

echo "=== Starting deployment process ==="

echo "Step 1: Cloning repositories..."
mapfile -t urls < <(sed 's/\r$//' repos.txt)

for url in "${urls[@]}"; do
    if [[ -n "$url" ]]; then
        echo "Cloning: $url"
        git clone "$url" 2>/dev/null || echo "Repository already exists or error occurred"
    fi
done

echo "Repositories cloned successfully!"

echo -e "\n\nStep 2: Building Docker images..."

if [ -d "FoodService" ]; then
    echo "Building cart-image from FoodService..."
    cd FoodService && docker build -t cart-image:latest . && cd ..
else
    echo "ERROR: FoodService directory not found!"
    exit 1
fi

# 2.2 front-1
if [ -d "delivery-website" ]; then
    echo "Building front for clients..."
    cd delivery-website && docker build -t front-client:latest . && cd ..
else
    echo "WARNING: delivery-website directory not found!"
fi

# 2.3 front-2
if [ -d "delivery-website-operator" ]; then
    echo "Building front application for staff..."
    cd delivery-website-operator && docker build -t front-operator:latest . && cd ..
else
    echo "WARNING: delivery-website-operator directory not found!"
fi

# 2.4 hits-food-auth-service (multiple services)
if [ -d "hits-food-auth-service" ]; then
    echo "Building services from hits-food-auth-service..."
    cd hits-food-auth-service

    if [ -f "user-service/Dockerfile" ] || [ -f "Dockerfile" ]; then
        echo "Building user-image..."
        docker build -f user-service/Dockerfile -t user-image:latest .
    else
        echo "WARNING: user-service Dockerfile not found!"
    fi

    if [ -f "orderservice/Dockerfile" ]; then
        echo "Building order-image..."
        docker build -f orderservice/Dockerfile -t order-image:latest .
    else
        echo "WARNING: orderservice Dockerfile not found!"
    fi

    if [ -f "menu/Dockerfile" ]; then
        echo "Building menu-image..."
        docker build -f menu/Dockerfile -t menu-image:latest .
    else
        echo "WARNING: menu Dockerfile not found!"
    fi

    cd ..
else
    echo "ERROR: hits-food-auth-service directory not found!"
    exit 1
fi

echo -e "\n\nAll Docker images built successfully!"

echo -e "\n\nStep 4: Starting services with docker-compose..."

if [ -d "hits-food-auth-service" ]; then
    echo "Starting docker-compose from hits-food-auth-service..."
    cd hits-food-auth-service
    touch .env
    docker-compose up -d
    echo "Services are starting in background..."
    echo "Check status with: docker-compose ps"
    echo "View logs with: docker-compose logs -f"
else
    echo "ERROR: docker-compose.yml not found in hits-food-auth-service!"
    exit 1
fi

echo -e "\n=== Deployment completed successfully! ==="
