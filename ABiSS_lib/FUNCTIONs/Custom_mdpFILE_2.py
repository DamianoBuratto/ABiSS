import argparse
import os


def main():
    # This is different from what I was using: NOT IMPLEMENTED
    parser = argparse.ArgumentParser()
    parser.add_argument("file_name", help="Name of the file to be modified")
    parser.add_argument("KEYword", nargs="+", help="List of KEYword and KEYvalue couples")
    args = parser.parse_args()

    # Retrieve the file name without the path
    file_name = os.path.basename(args.file_name)

    # Check if all the KEYwords and KEYvalues are provided
    if len(args.KEYword) % 2 != 0:
        print("Warning: Some KEYword or KEYvalue is missing")
        return

    # Open the file and replace the KEYwords with the KEYvalues
    try:
        with open(args.file_name, "r") as f:
            content = f.read()

        for i in range(0, len(args.KEYword), 2):
            if args.KEYword[i] and args.KEYword[i + 1]:
                content = content.replace(args.KEYword[i], args.KEYword[i + 1])
            else:
                print("Warning: Some KEYword or KEYvalue is empty")

        # Save the modified file in the current directory
        with open(file_name, "w") as f:
            f.write(content)
    except IOError:
        print("Error: File not found or cannot be opened")


if __name__ == "__main__":
    main()
