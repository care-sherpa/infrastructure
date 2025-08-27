#!/bin/bash
set -e

# Interactive Google Secret Manager utility
# Supports listing projects, selecting secrets, and managing secret values

DEFAULT_PROJECT="halogen-honor-450420-q9"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if gcloud is authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo -e "${RED}Error: Not authenticated with gcloud. Please run 'gcloud auth login'${NC}"
    exit 1
fi

# Function to select project
select_project() {
    echo -e "${BLUE}=== Select Project ===${NC}"
    echo "1. Use default: $DEFAULT_PROJECT (CareSherpaCorp)"
    echo "2. List all projects and select"
    echo ""
    read -p "Choice (1-2): " project_choice
    
    case $project_choice in
        1)
            PROJECT_ID="$DEFAULT_PROJECT"
            echo -e "${GREEN}Using default project: $PROJECT_ID${NC}"
            ;;
        2)
            echo -e "${BLUE}Available projects:${NC}"
            # Create temporary file to store project list
            temp_projects=$(mktemp)
            gcloud projects list --format="value(projectId)" --filter="name:*caresherpa* OR name:*halogen*" > "$temp_projects"
            
            # Read projects into array
            projects=()
            while IFS= read -r line; do
                [ -n "$line" ] && projects+=("$line")
            done < "$temp_projects"
            rm "$temp_projects"
            
            if [ ${#projects[@]} -eq 0 ]; then
                echo -e "${RED}No Care Sherpa projects found${NC}"
                exit 1
            fi
            
            for i in $(seq 0 $((${#projects[@]}-1))); do
                project_name=$(gcloud projects describe "${projects[$i]}" --format="value(name)" 2>/dev/null || echo "Unknown")
                echo "$((i+1)). ${projects[$i]} ($project_name)"
            done
            
            echo ""
            read -p "Select project (1-${#projects[@]}): " proj_num
            
            if [[ $proj_num -ge 1 && $proj_num -le ${#projects[@]} ]]; then
                PROJECT_ID="${projects[$((proj_num-1))]}"
                echo -e "${GREEN}Selected project: $PROJECT_ID${NC}"
            else
                echo -e "${RED}Invalid selection${NC}"
                exit 1
            fi
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            exit 1
            ;;
    esac
    
    gcloud config set project "$PROJECT_ID"
}

# Function to list and select secret
select_secret() {
    echo ""
    echo -e "${BLUE}=== Select Action ===${NC}"
    echo "1. Create new secret"
    echo "2. View existing secret"
    echo "3. Update existing secret"
    echo ""
    read -p "Choice (1-3): " action_choice
    
    case $action_choice in
        1)
            create_secret
            ;;
        2|3)
            # List existing secrets
            echo -e "${BLUE}Secrets in project $PROJECT_ID:${NC}"
            # Create temporary file to store secrets list
            temp_secrets=$(mktemp)
            gcloud secrets list --format="value(name)" > "$temp_secrets" 2>/dev/null || echo "" > "$temp_secrets"
            
            # Read secrets into array
            secrets=()
            while IFS= read -r line; do
                [ -n "$line" ] && secrets+=("$line")
            done < "$temp_secrets"
            rm "$temp_secrets"
            
            if [ ${#secrets[@]} -eq 0 ]; then
                echo -e "${YELLOW}No secrets found in this project${NC}"
                echo ""
                read -p "Create a new secret? (y/n): " create_new
                if [[ $create_new =~ ^[Yy]$ ]]; then
                    create_secret
                else
                    exit 0
                fi
            else
                for i in $(seq 0 $((${#secrets[@]}-1))); do
                    # Get secret description if available
                    desc=$(gcloud secrets describe "${secrets[$i]}" --format="value(labels.description)" 2>/dev/null || echo "")
                    if [ -n "$desc" ]; then
                        echo "$((i+1)). ${secrets[$i]} ($desc)"
                    else
                        echo "$((i+1)). ${secrets[$i]}"
                    fi
                done
                
                echo "$((${#secrets[@]}+1)). Create new secret"
                echo ""
                read -p "Select secret (1-$((${#secrets[@]}+1))): " secret_num
                
                if [[ $secret_num -ge 1 && $secret_num -le ${#secrets[@]} ]]; then
                    SECRET_NAME="${secrets[$((secret_num-1))]}"
                    if [ "$action_choice" -eq 2 ]; then
                        view_secret
                    else
                        update_secret
                    fi
                elif [ $secret_num -eq $((${#secrets[@]}+1)) ]; then
                    create_secret
                else
                    echo -e "${RED}Invalid selection${NC}"
                    exit 1
                fi
            fi
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            exit 1
            ;;
    esac
}

# Function to create new secret
create_secret() {
    echo ""
    read -p "Enter secret name: " SECRET_NAME
    
    if gcloud secrets describe "$SECRET_NAME" >/dev/null 2>&1; then
        echo -e "${YELLOW}Secret $SECRET_NAME already exists${NC}"
        return
    fi
    
    echo ""
    echo "1. Generate secure password automatically"
    echo "2. Enter password manually"
    read -p "Choice (1-2): " pass_choice
    
    case $pass_choice in
        1)
            SECRET_VALUE=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-20)"!"
            echo -e "${GREEN}Generated secure password${NC}"
            ;;
        2)
            read -s -p "Enter secret value: " SECRET_VALUE
            echo ""
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            exit 1
            ;;
    esac
    
    echo ""
    echo -e "${BLUE}Creating secret: $SECRET_NAME${NC}"
    echo -n "$SECRET_VALUE" | gcloud secrets create "$SECRET_NAME" --data-file=-
    echo -e "${GREEN}✅ Secret created successfully!${NC}"
    
    if [ "$pass_choice" -eq 1 ]; then
        echo ""
        echo -e "${YELLOW}Generated password: $SECRET_VALUE${NC}"
        echo -e "${YELLOW}Save this password securely!${NC}"
    fi
}

# Function to view secret
view_secret() {
    echo ""
    echo -e "${YELLOW}⚠️  You are about to view secret: $SECRET_NAME${NC}"
    echo -e "${YELLOW}⚠️  This will display the secret value on screen${NC}"
    echo ""
    read -p "Are you sure you want to continue? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        echo ""
        echo -e "${BLUE}Secret value for $SECRET_NAME:${NC}"
        echo -e "${GREEN}$(gcloud secrets versions access latest --secret="$SECRET_NAME")${NC}"
        echo ""
        echo -e "${BLUE}To use this in scripts:${NC}"
        echo "export SECRET=\$(gcloud secrets versions access latest --secret=$SECRET_NAME --project=$PROJECT_ID)"
    else
        echo -e "${YELLOW}Operation cancelled${NC}"
    fi
}

# Function to update secret
update_secret() {
    echo ""
    echo -e "${YELLOW}Updating secret: $SECRET_NAME${NC}"
    echo "Current secret exists. Enter new value:"
    read -s -p "New secret value: " NEW_SECRET_VALUE
    echo ""
    
    echo ""
    read -p "Are you sure you want to update this secret? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        echo -n "$NEW_SECRET_VALUE" | gcloud secrets versions add "$SECRET_NAME" --data-file=-
        echo -e "${GREEN}✅ Secret updated successfully!${NC}"
    else
        echo -e "${YELLOW}Update cancelled${NC}"
    fi
}

# Main execution
echo -e "${GREEN}=== Google Secret Manager Utility ===${NC}"
echo ""

select_project
select_secret

echo ""
echo -e "${GREEN}Operation completed!${NC}"