import os
import shutil
import colorama
from colorama import Fore, Style
import subprocess

GODOT_BRANCH = "3.4.4-stable"
BORDER_FORE = Fore.LIGHTMAGENTA_EX

def are_dirs_equal (a, b):
    for item_name in os.listdir(a):
        a_path = os.path.join(a, item_name)
        b_path = os.path.join(b, item_name)
        if not os.path.exists(b_path):
            return False
        if os.path.isfile(a_path) != os.path.isfile(b_path):
            return False
        if os.path.isdir(a_path):
            if not are_dirs_equal(a_path, b_path):
                return False
        else:
            a_file = open(a_path, "rb")
            b_file = open(b_path, "rb")
            files_equal = a_file.read() == b_file.read()
            a_file.close()
            b_file.close()
            if not files_equal:
                return False
    return True

def remove_dir (dir):
    for item_name in os.listdir(dir):
        item_path = os.path.join(dir, item_name)
        if os.path.isfile(item_path):
            os.remove(item_path)
        else:
            remove_dir(item_path)
    os.rmdir(dir)

def read_yes_or_no ():
    while True:
        inp = input().strip().lower()
        if inp=="y" or inp=="":
            return True
        elif inp=="n":
            return False

def print_section (*args):
    border = "------------------------------------"
    output = BORDER_FORE + border + '\n'
    for line in args:
        output += BORDER_FORE + "| " + Style.RESET_ALL + str(line).capitalize() + '\n'
    print(output + BORDER_FORE + border + Style.RESET_ALL)

if __name__ == "__main__":
    colorama.init()

    print(
f"""{BORDER_FORE}-----------------------------------------------
{BORDER_FORE}|  {Fore.CYAN}                                           {BORDER_FORE}|
{BORDER_FORE}|  {Fore.CYAN} _     _           _                       {BORDER_FORE}|
{BORDER_FORE}|  {Fore.CYAN}| |__ (_)_ __ ___ | |__   __ _ _ __ ___    {BORDER_FORE}|
{BORDER_FORE}|  {Fore.CYAN}| '_ \| | '_ ` _ \| '_ \ / _` | '_ ` _ \   {BORDER_FORE}|
{BORDER_FORE}|  {Fore.CYAN}| |_) | | | | | | | |_) | (_| | | | | | |  {BORDER_FORE}|
{BORDER_FORE}|  {Fore.CYAN}|_.__/|_|_| |_| |_|_.__/ \__,_|_| |_| |_|  {BORDER_FORE}|
{BORDER_FORE}|  {Fore.CYAN}                                           {BORDER_FORE}|
{BORDER_FORE}|  {Fore.CYAN} _           _ _     _                     {BORDER_FORE}|
{BORDER_FORE}|  {Fore.CYAN}| |__  _   _(_) | __| | ___ _ __           {BORDER_FORE}|
{BORDER_FORE}|  {Fore.CYAN}| '_ \| | | | | |/ _` |/ _ \ '__|          {BORDER_FORE}|
{BORDER_FORE}|  {Fore.CYAN}| |_) | |_| | | | (_| |  __/ |             {BORDER_FORE}|
{BORDER_FORE}|  {Fore.CYAN}|_.__/ \__,_|_|_|\__,_|\___|_|             {BORDER_FORE}|
{BORDER_FORE}|  {Fore.CYAN}                                           {BORDER_FORE}|
{BORDER_FORE}|  {Fore.CYAN}                                           {BORDER_FORE}|
{BORDER_FORE}-----------------------------------------------"""
    )

    print(Fore.CYAN + "Choose an option")
    print("0. Exit")
    print("1. Run the game")
    print("2. Run the editor")
    print("3. Export the game")
    print("4. Build and run the game")
    print("5. Build and run the editor")
    print("6. Build and export the game")
    option = ""
    while True:
        print(BORDER_FORE + "> ", end="")
        option = input().strip()
        if option in ["0", "1", "2", "3", "4", "5", "6"]:
            break
    
    if option == "0":
        quit()
    
    if option in "456":
        if not os.path.exists("godot"):
            print_section(Fore.RED + "Godot folder not found, cloning from github...")
            os.system(f"git clone --recursive --branch {GODOT_BRANCH} https://github.com/godotengine/godot.git")
        else:
            print(Fore.GREEN + "Godot folder found")

        print_section(Fore.YELLOW + "Checking for any module changes...")
        any_module_changes = False
        modules_path = "bimbam/Modules"
        for module_name in os.listdir(modules_path):
            module_path = os.path.join(modules_path, module_name)
            if os.path.isdir(module_path):
                godot_module_path = f"godot/modules/{module_name}"
                modules_match = are_dirs_equal(module_path, godot_module_path)
                if not os.path.exists(godot_module_path) or not modules_match:
                    any_module_changes = True
                    print(Fore.YELLOW + f'Updating module "{module_name}" ...')
                    if not modules_match:
                        remove_dir(godot_module_path)
                    shutil.copytree(module_path, godot_module_path)
    
        build = any_module_changes
        if not any_module_changes:
            print(Fore.YELLOW + "No module changes detected, skip compilation? [y/n]: ", end="")
            build = not read_yes_or_no()
        else:
            print(Fore.GREEN + "Modules have been updated, compilation is required")

        if build:
            print_section(Fore.YELLOW + "Building the editor...")
            os.system("scons --directory=godot platform=windows tools=yes target=release_debug -j10") # Build the editor
            print_section(Fore.YELLOW + "Building the export template...")
            os.system("scons --directory=godot platform=windows tools=no target=release -j10") # Build the export template
            print_section(Fore.GREEN + "Compilation process finished")

    if option in "14":
        os.system('start "" "godot/bin/godot.windows.opt.tools.64.exe" --path bimbam')
    elif option in "25":
        os.system('start "" "godot/bin/godot.windows.opt.tools.64.exe" --editor --path bimbam')
    elif option in "36":
        print_section(Fore.YELLOW + "Exporting the game ...")
        # os.system(' "godot/bin/godot.windows.opt.tools.64.exe" --export "Windows Desktop" ../EXPORT.exe --path bimbam')
        subprocess.call(["godot/bin/godot.windows.opt.tools.64.exe", "--export", "Windows Desktop", "../EXPORT.exe", "--path", "bimbam"])
        print_section(Fore.GREEN + "Exporting completed")
        os.system('start "" "EXPORT.exe"')

    print(Style.RESET_ALL)