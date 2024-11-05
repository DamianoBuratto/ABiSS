import pandas as pd
import matplotlib.pyplot as plt
from scipy.stats import linregress
import argparse
import re


# def read_xvg(file_path):
#     # Read the xvg file, skipping lines that start with # or @
#     data = pd.read_csv(file_path, comment='#', sep=r'\s+', skiprows=lambda x: str(x).startswith('@'))
#     # Select only the first two columns
#     data = data.iloc[:, :2]
#     data.columns = ['x', 'y']
#     print(data)
#     return data

def read_xvg(file_path):
    data = []
    with open(file_path) as file:
        for line in file:
            if not line.startswith(('#', '@')):
                # use regular expression to split by multiple spaces
                columns = re.split(r'\s+', line.strip())
                if len(columns) >= 2:
                    data.append([float(columns[0]), float(columns[1])])

    # convert the list of listst to a DataFrame
    data = pd.DataFrame(data, columns=['x', 'y'])
    # print(data)
    return data


def plot_data(data, regression_line=None, output_file=None):
    plt.figure(figsize=(10, 6))
    plt.plot(data['x'], data['y'], label='Data')

    if regression_line is not None:
        x, y = regression_line
        plt.plot(x, y, color='red', linestyle='--', label='Regression Line')

    plt.xlabel('X')
    plt.ylabel('Y')
    plt.title('X-Y Plot')
    plt.legend()
    if output_file:
        plt.savefig(output_file)
        plt.show()


def compute_linear_regression(data, start, end):
    # Select the range of data
    range_data = data.iloc[start:end]
    x = range_data['x']
    y = range_data['y']

    # Perform linear regression
    slope, intercept, r_value, p_value, std_err = linregress(x, y)
    regression_line = (x, slope * x + intercept)
    return slope, regression_line


def compute_linear_regression_min_x(data, min_x):
    # Select the range of data with x > min_x
    range_data = data[data['x'] > min_x]
    x = range_data['x']
    y = range_data['y']

    # Perform linear regression
    slope, intercept, r_value, p_value, std_err = linregress(x, y)
    regression_line = (x, slope * x + intercept)
    return slope, regression_line


def main():
    parser = argparse.ArgumentParser(description='Process and analyze XVG files.')
    parser.add_argument('file', help='Input XVG file')
    parser.add_argument('--plot', help='Output plot file (optional)', default=None)
    parser.add_argument('--start', type=int, help='Start index for linear regression', required=False)
    parser.add_argument('--end', type=int, help='End index for linear regression', required=False)
    parser.add_argument('--min_x', type=float, help='Minimum x value for linear regression', required=False)

    args = parser.parse_args()

    # Read the data from the XVG file
    data = read_xvg(args.file)

    regression_line = None
    slope = None

    # Compute the linear regression slope
    if args.start is not None and args.end is not None:
        slope, regression_line = compute_linear_regression(data, args.start, args.end)
        print(f'Slope of the regression for range [{args.start}:{args.end}]: {slope}')
    elif args.min_x is not None:
        slope, regression_line = compute_linear_regression_min_x(data, args.min_x)
        print(f'Slope of the regression for x > {args.min_x}: {slope}')
    else:
        print('Please provide either start and end indices or a minimum x value for linear regression.')

    # Plot the data if requested
    if args.plot:
        plot_data(data, regression_line, args.plot)


if __name__ == '__main__':
    main()
