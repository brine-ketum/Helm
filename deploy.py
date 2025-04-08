# # List of boys in Class A
# boys_in_class_a = ["Brine", "Favour", "Michael", "David", "John"]

# # Print each name
# print("Boys in Class A:")
# for boy in boys_in_class_a:
#     print(boy)
import os

# Get the current working directory
current_dir = os.getcwd()

# List all files and directories in current directory
items = os.listdir(current_dir)

# Print only files
print("Files in current directory:")
for item in items:
    if os.path.isfile(os.path.join(current_dir, item)):
        print(item)
