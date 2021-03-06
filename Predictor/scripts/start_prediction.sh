#!/bin/bash
# take statements created by python pipeline and run them (statements are for python tool which prepares statements for actual FARFAR prediction)
# be aware of path to correct folder structure regarding rna_tools

# path to scripts directory - this script will be copied out
source ../../../../scripts/config.py

echo "++Execute prepared statements (rostetta_rna_tools)++"
pwd
if [ -f "prepared_statements.txt" ]; then
	statements=$(<prepared_statements.txt)
	while read -r line; do
		echo "	Currently executed: $line"
		dir=$(echo $line | cut -f 5 -d ' ' | cut -f 2 -d '/' | cut -f 1 -d '.')
		cd $dir
		line="${configPathToRNATools}${line}"
		$line
		cd ..
	done <<< "$statements"

	# this part is specific for metacentrum - scripts which will run tasks which will run later (planed by metacentrum scheduller)
	# there is added a sleep statement to the script which is incremented - reason is that there were collisions in some source file of rosetta 
	# (probably both starting predictions tried to access the same file in the same moment which crashed - those sleeps resolved the problem) 

	currentDirectory=$(pwd)
	echo "++Creating tasks for metacentrum (${currentDirectory})++"
	pwd
	wt=1
	for D in `find ./?* -type d`
	do
		wt=$((wt+10))
		cd "$D"
		path=$(pwd)
		echo 	"#!/bin/bash
	 	  cd $path
	 	  sleep $wt
	 	  source README_FARFAR" > start_script.sh
		echo "$D.pdb:"
		qsub -l select=1:ncpus=4:mem=16gb -l walltime=${configWallTime} start_script.sh
		cd ${currentDirectory}
	done
else
	currentDir=$(pwd)
	echo "ERROR: prepared statements not found in ${currentDir}."
fi
