import csv
import ast
import numpy as np

def save_misalignment_to_csv(csv_file_path, t, misalignments, select):
    with open(csv_file_path, mode='w', newline='') as file:  # Use 'w' mode to write to a new file
        writer = csv.writer(file)
        
        # Write the header
        writer.writerow(['Select', 'Time', 'Misalignment'])
        
        # Write the value of misalignment to the CSV file
        for time, misalignment_value in zip(t, misalignments):
            writer.writerow([select, time, misalignment_value])

def calculate_average_misalignment(csv_file_path, start_time, end_time, select):
    with open(csv_file_path, mode='r', newline='') as file:
        reader = csv.reader(file)
        
        # Skip the header
        next(reader)
        
        # Initialize lists to store time and misalignment values
        times = []
        misalignments = []
        
        # Read the rows and store the values
        for row in reader:
            row_select = int(row[0])
            time = float(row[1])
            misalignment_value = ast.literal_eval(row[2])[0]  # Convert string to float
            
            if row_select == select and start_time <= time <= end_time:
                times.append(time)
                misalignments.append(misalignment_value)
        
        # Calculate the average misalignment
        if misalignments:
            average_misalignment = np.mean(misalignments)
            return average_misalignment
        else:
            return None
