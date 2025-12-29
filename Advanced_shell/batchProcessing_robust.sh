cat > batchProcessing_robust.sh << 'EOF'
#!/bin/bash

# Configuration
MAX_RETRIES=3
RETRY_DELAY=2
REQUEST_DELAY=1

# Create directory
mkdir -p pokemon_data

# List of Pokemon
pokemon_list="bulbasaur ivysaur venusaur charmander charmeleon"

# Function to fetch Pokemon data with retry
fetch_pokemon() {
    local pokemon=$1
    local output_file="pokemon_data/${pokemon}.json"
    local retries=0
    
    while [ $retries -lt $MAX_RETRIES ]; do
        echo "Fetching data for $pokemon... (attempt $((retries + 1))/$MAX_RETRIES)"
        
        http_code=$(curl -s -o "$output_file" -w "%{http_code}" --connect-timeout 10 "https://pokeapi.co/api/v2/pokemon/${pokemon}")
        
        if [ "$http_code" -eq 200 ]; then
            echo "Saved data to $output_file ✅"
            return 0
        else
            echo "Failed! HTTP Status: $http_code"
            retries=$((retries + 1))
            
            if [ $retries -lt $MAX_RETRIES ]; then
                echo "Retrying in ${RETRY_DELAY} seconds..."
                sleep $RETRY_DELAY
            fi
        fi
    done
    
    echo "Failed to fetch $pokemon after $MAX_RETRIES attempts ❌"
    rm -f "$output_file"
    return 1
}

# Process each Pokemon
success_count=0
fail_count=0

for pokemon in $pokemon_list; do
    if fetch_pokemon "$pokemon"; then
        success_count=$((success_count + 1))
    else
        fail_count=$((fail_count + 1))
    fi
    
    echo ""
    sleep $REQUEST_DELAY
done

# Summary
echo "=========================================="
echo "Batch processing complete!"
echo "Successful: $success_count"
echo "Failed: $fail_count"
echo "Total files: $(ls -1 pokemon_data/*.json 2>/dev/null | wc -l)"
echo "=========================================="
EOF

chmod +x batchProcessing_robust.sh
