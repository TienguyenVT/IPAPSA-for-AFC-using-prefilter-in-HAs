import numpy as np
import matplotlib.pyplot as plt

#select 1 : APA  / purple
#select 2 : NLMS / red
#select 3 : IPNLMS / black
#select 4 : IPAPA / blue

dir = 'D:\\De_tai_sinh_vien\\code_chuan\\figure\\'

my_list = []

def reset_variables():
    global my_list
    my_list = []

def plot_one_misalignment(t, m, select):
    fig, ax = plt.subplots()
    colors = ['purple', 'red', 'black', 'blue']
    labels = ['APA', 'NLMS', 'IPNLMS', 'IPAPA']
    
    ax.plot(t, m, color=colors[select-1], linewidth=0.5, label=labels[select-1])
    ax.set_xlabel('Time (seconds)', fontsize=10, fontweight='bold')
    ax.set_ylabel('Misalignment', fontsize=10, fontweight='bold')
    ax.legend(loc='upper right')

    # Set the origin (0,0) to align with the bottom-left corner
    ax.spines['left'].set_position(('data', 0))
    ax.spines['bottom'].set_position(('data', -25))
    ax.spines['right'].set_color('none')
    ax.spines['top'].set_color('none')
    ax.xaxis.set_ticks_position('bottom')
    ax.yaxis.set_ticks_position('left')

    # Ensure the axes start from 0 on x-axis and include -8 on y-axis
    ax.set_xlim(left=0)
    ax.set_ylim(bottom=-25)

    # Increase the tick frequency on the x-axis
    ax.set_xticks(np.arange(0, max(t) + 0.1, step=0.1))  # Adjust the step value to 0.1

    # Save the figure
    plt.savefig(f'{dir}{labels[select-1]}.png')
    plt.close(fig)  # Close the figure to free up memory


#select 1 : APA  / purple
#select 2 : NLMS / red
#select 3 : IPNLMS / black
#select 4 : IPAPA / blue

def plot_misalignment(t, m_list):
    fig, ax = plt.subplots()
    base_colors = ['purple', 'red', 'black', 'blue']
    base_labels = ['APA', 'NLMS', 'IPNLMS', 'IPAPA']

    # Extend colors and labels if m_list is longer than base lists
    colors = (base_colors * (len(m_list) // len(base_colors) + 1))[:len(m_list)]
    labels = (base_labels * (len(m_list) // len(base_labels) + 1))[:len(m_list)]

    for i, m in enumerate(m_list):
        ax.plot(t, m, color=colors[i], linewidth=0.3)

    ax.set_xlabel('Time (seconds)', fontsize=10, fontweight='bold')
    ax.set_ylabel('Misalignment', fontsize=10, fontweight='bold')

    # Set the origin (0,0) to align with the bottom-left corner
    ax.spines['left'].set_position(('data', 0))
    ax.spines['bottom'].set_position(('data', -25))
    ax.spines['right'].set_color('none')
    ax.spines['top'].set_color('none')
    ax.xaxis.set_ticks_position('bottom')
    ax.yaxis.set_ticks_position('left')

    # Ensure the axes start from 0 on x-axis and include -8 on y-axis
    ax.set_xlim(left=0)
    ax.set_ylim(bottom=-25)

    # Increase the tick frequency on the x-axis
    ax.set_xticks(np.arange(0, max(t) + 0.1, step=0.1))  # Adjust the step value to 0.1

    # Extend colors and labels if m_list is longer than base lists
    labels = (base_labels * (len(m_list) // len(base_labels) + 1))[:len(m_list)]
    # Add legend with dynamic labels
    handles = [plt.Line2D([0], [0], color=color, linewidth=0.3) for color in colors]
    # Move NLMS to the top and APA to the second position
    sorted_labels = ['NLMS', 'APA'] + [label for label in labels if label not in ['NLMS', 'APA']]
    sorted_handles = [handles[labels.index(label)] for label in sorted_labels]
    ax.legend(sorted_handles, sorted_labels, loc='upper right')

    # Save the figure
    plt.savefig(f'{dir}combined_plot.png')
    # plt.show()

def show_figure(file_path):
    def on_key(event):
        if event.key == 'q':
            plt.close(event.canvas.figure)

    plt.close('all')  # Đóng tất cả các hình trước đó
    img = plt.imread(file_path)
    fig, ax = plt.subplots()
    ax.imshow(img)
    ax.axis('off')  # Hiển thị các trục
    fig.canvas.mpl_connect('key_press_event', on_key)
    plt.show()