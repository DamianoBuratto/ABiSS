import sys
import os


def modify_file(_file_path_name, **_kwargs):
    for key, value in _kwargs.items():
        if not key or not value:
            print("Warning: KEYword or KEYvalue is empty. key='" + str(key) + "' value='" + str(value) + "'")

    # Retrieve the file name without the path
    file_name = os.path.basename(_file_path_name)

    try:
        with open(_file_path_name, "r") as f:
            file_content_lines = f.readlines()
        for i in range(len(file_content_lines)):
            for key, value in _kwargs.items():
                # remove the first char (that is a "-") from every KEY word
                key = key[1:]
                # if i == 0: print("key:" + key + " value:" + value)
                file_content_lines[i] = file_content_lines[i].replace(key, value)
        # remove the lines containing a "KEY_"
        lines = [line for line in file_content_lines if "KEY_" not in line]
        # save the new file
        with open(file_name, "w") as f:
            f.writelines(lines)
    except FileNotFoundError:
        print(f"Error: File {_file_path_name} not found.")


if __name__ == "__main__":
    args = sys.argv[1:]
    if len(args) < 2:
        print("Error: At least one KEYword and one KEYvalue should be provided.")
    else:
        file_path_name = args[0]
        kwargs = dict(zip(args[1::2], args[2::2]))
        modify_file(file_path_name, **kwargs)
