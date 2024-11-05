BEGIN {
	DeltaG     	    = 0		# column 2
	DeltaG_2s	    = 0
	Coul          	= 0		# column 3
	VdW           	= 0		# column 4
	PolSol        	= 0		# column 5
	NpoSol     	    = 0		# column 6
	Population 	    = 0
	Population_2s	= 0
	ScoreFunct 	    = 0
	ScoreFunct2 	= 0
	Canonical_AVG    = 0
	Canonical_AVG_w  = 0
	MedianDG    	= 0

	# Print the header of the file with the name for every column
	print "# SF1=Coulomb/10-PolarSolvation/10+Non-PolarSolvation*10 "
	print "# SF2=3*Coulomb+PolarSolvation "
	print "# C_AVG=norm(SUM Gi*e^BGi) "
	printf "%-10s \t%13s \t%13s \t%13s \t%13s \t%13s \t%13s \t%13s\n", \
	"#frame", "dG(kJ/mol)", "Coul(kJ/mol)", "VdW(kJ/mol)", "PolSol(kJ/mol)", "NpoSol(kJ/mol)", "SF1", "SF2"
}
{
	Population 		= Population + 1
	DG[Population]	= $2			# array that start from 1
	DeltaG     		= DeltaG + $2
	Coul       		= Coul   + $3
	VdW        		= VdW    + $4
	PolSol     		= PolSol + $5
	NpoSol     		= NpoSol + $6
	ScoreFunct 		= $3/10 - $5/10 + $6*10 +150
	ScoreFunct2 	= 3*$3 + $5
	Canonical_AVG   	= Canonical_AVG + $2 * exp( -1 * int($2 / 2.479) )	# 1KT=2.479KJ/mol
	Canonical_AVG_w 	= Canonical_AVG_w + exp( -1 * int($2 / 2.479) )
	#printf "%-7s%-5.2f   \t", "int$2",int($2)

	printf "%-10s \t%13.3f \t%13.3f \t%13.3f \t%13.3f \t%13.3f \t%13.3f \t%13.3f \n", \
	$1, $2, $3, $4, $5, $6, ScoreFunct, ScoreFunct2
	# printf "%-10s \t%15.3f \t%15.3f \n", "#", Canonical_AVG, Canonical_AVG_w
}
END {
	print "#\n# DATA ANALYSIS "
	DeltaG     	= DeltaG / Population
	Coul       	= Coul   / Population
	VdW        	= VdW    / Population
	PolSol     	= PolSol / Population
	NpoSol     	= NpoSol / Population

	ScoreFunct  	= Coul/10 - PolSol/10 + NpoSol*10
	ScoreFunct2 	= 3*Coul + PolSol
	Canonical_AVG	= Canonical_AVG / Canonical_AVG_w

	# Compute the standard deviations, filter data at 2sigma and compute the new std dev at 2sigma
	stdDG		= 0
	stdDG_2s	= 0
	stdCoul		= 0
	stdVdW		= 0
	stdPolSol	= 0
	stdNpoSol	= 0
	stdSF		= 0
	stdSF2		= 0
	while(getline < inFILE) {
		stdDG		= stdDG 	+ ( $2 - DeltaG )^2
		stdCoul		= stdCoul 	+ ( $3 - Coul )^2
		stdVdW		= stdVdW 	+ ( $4 - VdW )^2
		stdPolSol	= stdPolSol + ( $5 - PolSol )^2
		stdNpoSol	= stdNpoSol + ( $6 - NpoSol )^2
	}
	close(inFILE)
	stdDG		= sqrt( stdDG / (Population-1) )
	stdCoul		= sqrt( stdCoul / (Population-1) )
	stdVdW		= sqrt( stdVdW / (Population-1) )
	stdPolSol	= sqrt( stdPolSol / (Population-1) )
	stdNpoSol	= sqrt( stdNpoSol / (Population-1) )
	stdSF		= ( stdCoul/10 + stdPolSol/10 + stdNpoSol*10 )
	stdSF2		= ( 3*stdCoul + stdPolSol )

	# Compute DeltaG at 2 sigma
	#DeltaG_max=(DeltaG + 2*stdDG)
	#DeltaG_min=(DeltaG - 2*stdDG)
	while(getline < inFILE) {
		# ( ($2 > DeltaG_min) || ($2 < DeltaG_max) ) = sqrt(($2-DeltaG)^2)<2*stdDG
		var=sqrt( ($2 - DeltaG)^2 )
		if ( var<2*stdDG ) {
			DeltaG_2s	= DeltaG_2s     + $2
			Population_2s	= Population_2s + 1
		}
		else {
			printf "%-17s %3i %-20s \n", "# WARNING: frame ", Population_2s+1, "is out of 2 sigma!!"
		}
	}
	close(inFILE)
	DeltaG_2s     	= DeltaG_2s / Population_2s

	# Compute the std dev of DeltaG at 2sigma
	while(getline < inFILE) {
		var=sqrt( ($2 - DeltaG)^2 )
		if ( var<2*stdDG ) {
			stdDG_2s	= stdDG_2s + ( $2 - DeltaG_2s )^2
		}
	}
	close(inFILE)
	stdDG_2s		= sqrt( stdDG_2s / (Population_2s-1) )

	# ORDER ALL THE DeltaG values in order to compute the Median
	print "#\n# Print the first 5 (and the last one) Ordered DeltaG values "
	printf "%-10s \t", "#Ordered DG"
	for(idx1=1; idx1<Population; idx1++){
		for(idx2=2; idx2<=Population; idx2++){
			if( DG[idx2] < DG[idx1] ) {
				flag = DG[idx2]
				DG[idx2] = DG[idx1]
				DG[idx1] = flag
			}
		}
		if (idx1 >= 5) {continue}
		printf "(%3i)%8.3f \t", idx1, DG[idx1]
	}
	printf "... (%3i)%8.3f \n", Population, DG[Population]
	#for(idx1=1; idx1<=Population; idx1++){
	#	printf "(%3i)%8.3f \t", idx1, DG[idx1]
	#}

	MedianDG = MedianDG + DG[_floor_NLine]
	MedianDG = MedianDG + DG[_ceiling_NLine]
	MedianDG = MedianDG / 2

	# Compute the GibbsFreeEnergy using the Potential energy_plot
	# This only start if the PotEnFILE is provided
	Cycles=0
	COP=0; LIG=0; REC=0; DPot=0; DG_pot=0
	if ( PotEnFILE != "none" ) {
		while(getline < PotEnFILE) {
			if ($1=="complex") COP=COP+$2
			if ($1=="ligand") LIG=LIG+$2
			if ($1=="receptor") REC=REC+$2
			Cycles++
		}
		Cycles=Cycles/3
		DPot=(COP-LIG-REC)/Cycles
		DG_pot=DPot+PolSol+NpoSol
		print "#COP="COP" LIG="LIG" REC="REC"Cycles="Cycles" DPot="DPot" DG_pot="DG_pot;
	}

	print "#\n# FINAL RESULTS"
	printf "%-10s \t%13s \t%13s \t%13s \t%13s \t%13s \t%13s \t%13s \t%13s \t%13s \t%13s \t%13s \n", \
	"#frame", "dG(kJ/mol)", "Coul(kJ/mol)", "VdW(kJ/mol)", "PolSol(kJ/mol)", "NpoSol(kJ/mol)", "SF1", "SF2", \
	"C_AVG", "Median DeltaG", "dG_2sigma(Kj/mol)", "dG_PotEn(Kj/mol)"
	printf "%-10s \t%13.1f \t%13.1f \t%13.1f \t%13.1f \t%13.1f \t%13.1f \t%13.1f \t%13.1f \t%13.1f \t%13.1f \t%13.1f \n", \
	"#AVG", DeltaG, Coul, VdW, PolSol, NpoSol, ScoreFunct, ScoreFunct2, Canonical_AVG, MedianDG, DeltaG_2s, DG_pot
	printf "%-10s \t%13.1f \t%13.1f \t%13.1f \t%13.1f \t%13.1f \t%13.1f \t%13.1f \t%13s \t%13s \t%13.1f \t%13s \n", \
	"#STD", stdDG, stdCoul, stdVdW, stdPolSol, stdNpoSol, stdSF, stdSF2, "nan", "nan", stdDG_2s, "nan"
}