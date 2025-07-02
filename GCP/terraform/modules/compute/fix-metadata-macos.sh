#!/bin/bash
# Fix for macOS - using perl instead of sed

echo "Fixing compute module metadata syntax for macOS..."

# First, let's check if we're in the right directory
if [[ ! -f "main.tf" ]]; then
    echo "Error: main.tf not found. Make sure you're in the compute module directory"
    exit 1
fi

# Create a backup
cp main.tf main.tf.backup

# Use perl to fix the multi-line ternary operator
perl -i -pe '
if (/metadata = lookup\(each\.value, "os_type", var\.os_type\) == "windows" \?/) {
    $_ .= <> . <>;  # Read next two lines
    s/\n\s*//g;     # Remove newlines and leading spaces
    s/metadata = lookup/  metadata = lookup/;  # Add proper indentation
    $_ .= "\n";     # Add newline at the end
}
' main.tf

# Also update to use clean_windows_metadata and clean_linux_metadata
perl -i -pe 's/merge\(local\.windows_metadata,/merge(local.clean_windows_metadata,/g' main.tf
perl -i -pe 's/merge\(local\.linux_metadata,/merge(local.clean_linux_metadata,/g' main.tf

echo "✅ Fixed metadata syntax!"
echo "Now checking if clean metadata locals exist..."

# Check if we need to add clean metadata locals
if ! grep -q "clean_linux_metadata" main.tf; then
    echo "Adding clean metadata locals..."
    
    # Find the locals block and add the clean metadata definitions
    perl -i -pe '
    if (/^\s*windows_metadata = \{/) {
        $inside_windows = 1;
    }
    if ($inside_windows && /^\s*\}/) {
        $inside_windows = 0;
        $_ .= "\n  # Clean metadata by removing null values\n";
        $_ .= "  clean_linux_metadata = { for k, v in local.linux_metadata : k => v if v != null }\n";
        $_ .= "  clean_windows_metadata = { for k, v in local.windows_metadata : k => v if v != null }\n";
    }
    ' main.tf
fi

echo "✅ All fixes applied!"
echo ""
echo "You can now go back to the prod directory and run terraform init:"
echo "cd ../../environments/prod"
echo "terraform init"
