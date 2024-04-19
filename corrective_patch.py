import sys, gzip, shutil

folder = input("Please enter the location of your minizinc-python installation, for example: \n/home/maxime/anaconda3/lib/python3.9/site-packages/minizinc/ \n : ")

new_file = folder + "/instance.py"

with gzip.open('./patchfile/instance.py.gz', 'rb') as f_in:
    with open(new_file, 'wb') as f_out:
        shutil.copyfileobj(f_in, f_out)
        
print(f"{new_file} succesfully written!")
