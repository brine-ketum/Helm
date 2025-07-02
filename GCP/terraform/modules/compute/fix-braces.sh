#!/bin/bash
# Fix extra closing braces in main.tf

# Remove extra brace on line 64 (after disk_size_gb)
sed -i '64s/^[[:space:]]*}$//' main.tf

# Remove extra brace on line 82 (inside dynamic disk)
sed -i '82s/^[[:space:]]*}$//' main.tf

# Remove extra brace on line 175 (after auto_delete in boot_disk)
sed -i '175s/^[[:space:]]*}$//' main.tf

# Remove extra brace on line 189 (inside dynamic attached_disk)
sed -i '189s/^[[:space:]]*}$//' main.tf

echo "Fixed extra braces"
