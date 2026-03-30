import numpy as np
from loader import load_mat_data
from plot import *
from modify import modify
from csv_ import *
from init import init_parameter
from clean import clear_folder

# Define paths
base_path = 'D:\\De_tai_sinh_vien\\code_chuan\\'
sound_path = f'{base_path}sound\\ex_eusipco_2010.mat'
figure_path = f'{base_path}figure\\'
csv_path = f'{base_path}csv\\'

# Parameters
names = ['APA', 'NLMS', 'IPNLMS', 'IPAPA']
x, d, miu, ord, p, dlt, a, h1, N = load_mat_data(sound_path)
t = np.linspace(0, N / 8000, N)

def display_menu(menu_type):
    menus = {
        'main': """
        *----------------------------------------------------*
        | choice a (all)    to run the system                |
        | choice 1 (APA)    to run the system with select  1 |
        | choice 2 (NLMS)   to run the system with select  2 |
        | choice 3 (IPNLMS) to run the system with select  3 |
        | choice 4 (IPAPA)  to run the system with select  4 |
        | choice c to clear the figure and csv folder        |
        | choice s to show the figure                        |
        | choice t to calculate average of misalignment      |
        | choice q to quit the system                        |
        *----------------------------------------------------*
        """,
        'show': """
        *----------------------------------------------------*
        | select 1 to show APA figure                        |
        | select 2 to show NLMS figure                       |
        | select 3 to show IPNLMS figure                     |
        | select 4 to show IPAPA figure                      |
        | select a to show combined figure                   |
        | select q to quit the system                        |
        *----------------------------------------------------*
        """,
        'calculate': """
        *----------------------------------------------------*
        | select 1 to calculate average of APA               |
        | select 2 to calculate average of NLMS              |
        | select 3 to calculate average of IPNLMS            |
        | select 4 to calculate average of IPAPA             |
        | select a to calculate average of all selects       |
        | select q to quit the system                        |
        *----------------------------------------------------*
        """
    }
    print(menus.get(menu_type, ""))

def calculate_average(csv_file, start, end, select):
    avg_misalignment = calculate_average_misalignment(csv_file, start, end, select)
    if avg_misalignment:
        print(f"Average Misalignment for {names[select-1]} from {start} to {end} seconds: {avg_misalignment}")
    else:
        print(f"No misalignment values found for {names[select-1]} in the specified time range.")

def run_select(select):
    clear_folder(figure_path)
    clear_folder(csv_path)
    m, w = modify(x, d, miu, ord, p, dlt, a, h1, select)
    plot_one_misalignment(t, m, select)
    save_misalignment_to_csv(f'{csv_path}misalignment_{names[select-1]}.csv', t, m, select)
    return m, w

def run_all():
    my_list = []
    clear_folder(figure_path)
    clear_folder(csv_path)
    for select in range(1, 5):
        m, _ = modify(x, d, miu, ord, p, dlt, a, h1, select)
        my_list.append(m)
        plot_one_misalignment(t, m, select)
        save_misalignment_to_csv(f'{csv_path}misalignment_{names[select-1]}.csv', t, m, select)
    plot_misalignment(t, my_list)

def main():
    check = 0
    display_menu('main')
    while True:
        choice = input("Do you want to run the system? : ")
        if choice == 'h':
            display_menu('main')
        elif choice in ['1', '2', '3', '4']:
            check = int(choice)
            run_select(check)
        elif choice == 'a':
            check = 5
            run_all()
        elif choice == 'c':
            clear_folder(figure_path)
            clear_folder(csv_path)
            check = 0
            reset_variables()
        elif choice == 's':
            display_menu('show')
            while True:
                show_choice = input("Enter the selection to show: ")
                if show_choice == 'q':
                    break
                elif check and show_choice.isdigit() and int(show_choice) in range(1, 5):
                    show_figure(f'{figure_path}{names[int(show_choice)-1]}.png')
                elif show_choice == 'a' and check == 5:
                    show_figure(f'{figure_path}combined_plot.png')
                else:
                    print("No figure found or invalid selection.")
        elif choice == 't':
            display_menu('calculate')
            while True:
                calc_choice = input("Enter the selection to calculate: ")
                if calc_choice == 'q':
                    break
                elif check and calc_choice.isdigit() and int(calc_choice) in range(1, 5):
                    calculate_average(f'{csv_path}misalignment_{names[int(calc_choice)-1]}.csv', 0.2, 1, int(calc_choice))
                elif calc_choice == 'a' and check == 5:
                    for idx in range(1, 5):
                        calculate_average(f'{csv_path}misalignment_{names[idx-1]}.csv', 0.2, 1, idx)
                else:
                    print("No misalignment values found or invalid selection.")
        elif choice == 'q':
            print("Exiting system.")
            break
