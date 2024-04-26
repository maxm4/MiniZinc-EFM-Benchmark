for i in {30..35}; do
	prolog -s efm.pl -g "efms('covert_palsson_edit_int.json', V, Z)." -t halt > output_sat_$i.txt
	prolog -s efm_clpq.pl -g "efms('covert_palsson_edit_int.json', V, Z)." -t halt > output_rat_$i.txt
done
