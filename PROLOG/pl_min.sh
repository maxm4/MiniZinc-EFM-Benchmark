for i in {51..55}; do
	prolog -s efm_min.pl -g "efms('covert_palsson_edit_int.json', V, Z)." -t halt > output_min_$i.txt
	prolog -s efm_min_clpq.pl -g "efms('covert_palsson_edit_int.json', V, Z)." -t halt > output_rmin_$i.txt
done
