for i in {111..114}; do 
     python benchmark.py covert_palsson_edit.dzn covert_palsson_edit.efmc --minimize results/result_min_$i.txt
     #python benchmark.py covert_palsson_edit.dzn covert_palsson_edit.efmc results/result_sat_$i.txt
done
