for i in {66..70}; do
	prolog -s efm_min_int.pl -g "efms('covert_palsson_edit_int.json', V, Z)." -t halt > output_min_int_$i.txt
	prolog -s efm_int.pl -g "efms('covert_palsson_edit_int.json', V, Z)." -t halt > output_int_$i.txt
done
