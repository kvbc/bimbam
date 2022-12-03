import os
import shutil
import colorama
from colorama import Fore, Style

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
        print(Fore.YELLOW + "No module changes detected, compile anyways? [y/n]: ", end="")
        build = read_yes_or_no()
    else:
        print(Fore.GREEN + "Modules have been updated, compilation is required")

    if build:
        print_section(Fore.YELLOW + "Building the editor...")
        os.system("scons --directory=godot platform=windows tools=yes target=release_debug -j10") # Build the editor
        print_section(Fore.YELLOW + "Building the export template...")
        os.system("scons --directory=godot platform=windows tools=no target=release -j10") # Build the export template
        print_section(Fore.GREEN + "Compilation process finished")

    print(Fore.YELLOW + "Run the editor? [y/n]: ", end="")
    if read_yes_or_no():
        os.system('start "" "godot/bin/godot.windows.opt.tools.64.exe" --editor --path bimbam')

    print(Style.RESET_ALL)