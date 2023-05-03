Overlay file system with detection system integrated.

Installation guide:
1. install requirements.txt from MA/custom/filesystems/python_classifier/
2. run: python3 detection_system.py
3. navigate to rename_fs directory inside MA_custom_filesystems
4. within the folder MA_custom_filesystems, add files into filesystem_dir that should be included within the overlay file system.
5. within MA/custom_filesystems/rename_fs/main.go, change the mountPoint directory to the directory where the overlay fileststem should be run
6. compile the code within rename_fs dir by running "go build" within the directory
7. run the generated binary rename_fs, by running the command: ./rename_fs

If running a Ransomware in the mounted directory is desired, following needs to be configured:
  - for DarkRadiation, adjust the path on line 165 and 171 to the overlay file system path
  - for Roar, change global variables LINUX_STARTDIRS and USER in rwpoc.py to correspond to the path to overlay filesystem
  - Ransomware PoC, has to be run with an argument -e "{path to overlay file system}"