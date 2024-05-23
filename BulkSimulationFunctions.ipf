#pragma TextEncoding = "Windows-1252"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#include "ModelCalculationPanel"


//////PARAMATER MODIFYING CODES AND DATA MOVING CODES/////////////
		//all made for two layer model, if layer number changes codes will have to be changed


////////////////////////////-Set Physicsal Model Parameters-//////////////////////////////////
//will not change the values Displayed on the Model Layout Panel

Function SetModel (Idepth,Iarea,Srough,thiccness)
	variable Idepth, Iarea, Srough,thiccness

	SetDataFolder root:Packages:DatabaseXPS:ValidatedModel
	variable/g Island_depth = Idepth
	variable/g Island_area = Iarea
	variable/g Roughness = Srough
	 //layer thickness is saved as 1D wave, and thickness of bulk layer is auto generated. If adding another layer to model need to change Thickness[0] and Thickness[1]
	Make/O/N = 1 Thickness    
	Thickness[0] = thiccness
	
	SetDataFolder root:
	
END 



//////////////////////////-Randomize Physical Model Parameters-//////////////////////////////////

Function RandModel ()

	Setdatafolder root:Packages:DataBaseXPS:ValidatedModel
	
	do
	//assigns random numbers to parameter, igor has many more different random number distrobution functions that you might want to consider as well
		variable/g Island_depth = abs(enoise(5))
		variable/g Island_area = abs(enoise(1))
		variable/g Roughness = abs(enoise(2))
		Make/O/N = 1 Thickness
		Thickness[0] = 20+enoise(5)
	//set conditions so that islands and surface roughness stay on surface:
	while(Roughness>Island_depth || Island_depth>Thickness[0]) 
	
	setdatafolder root:
	
END



/////////////////////////-Set Tougaard Parameters-/////////////////////////////////////
	//requires added code to ILAMPstart.ipf so that Brixias creates TouVars folder on startup 
	//good reference for understanding tou background: Universality Classes of Inelastic Electron Scattering Cross-sections, Sven Tougaard

Function SetTou (B,C,D,Gap,MPW)
	variable B,C,D,Gap,MPW
	
	setdatafolder root:Packages:DatabaseXPS:TouVars
	variable/g Btou = B
	Variable/g Ctou = C
	Variable/g Dtou = D
	Variable/g Gaptou = Gap
	Variable/g MPWtou = MPW
	
	setdatafolder root:
END 



////////////////////////////- Randomize tougaard parameters-//////////////////////////

Function RandTou()
		//also just examples of random parameter distrobution functions, may change 
	Setdatafolder root:Packages:DatabaseXPS:ValidatedModel
	wave MatParams = IMFP_Matrix // Matrix of atomic weight (row 0), Valence e's (row1), density (row2), band gap (row3) for each mat starting with film (col0)
	Setdatafolder root:Packages:DatabaseXPS:TouVars
	variable/g Btou = 800+(600*enoise(1))
	Variable/g Ctou = 300+(200*enoise(1))
	Variable/g Dtou = 1900+(1000*enoise(1))
	Variable/g Gaptou = MatParams[3][0] // sets it to film bandgap
	Variable/g MPWtou = 1.5
	
	setdatafolder root:
	
END



////////////////////////////-Randomize Chemical Shifts-//////////////////////////////
	//chemical shifts are stored as elements of 3D string wave with a lot of other factors, I try not to mess with that wave too much because it can be a pain to fix. So i just duplicate it (dummyMat) to change elements then duplicate the dummy to overwrite the original (if anything goes wrong just delete the dummy)
	
Function RandShifts()

	setdatafolder root:Packages:DatabaseXPS:ValidatedModel:
	
		duplicate /O/T root:Packages:DatabaseXPS:ValidatedModel:LineSelectorMat0, dummyMat0
		dummyMat0[][2][0] = num2str(abs(enoise(6))-1)
		duplicate/O/T root:Packages:DatabaseXPS:ValidatedModel:dummyMat0, LineSelectorMat0
		
		duplicate /O/T root:Packages:DatabaseXPS:ValidatedModel:LineSelectorMat1, dummyMat1
		dummyMat1[][2][0] = num2str(abs(enoise(6))-1)
		duplicate/O/T root:Packages:DatabaseXPS:ValidatedModel:dummyMat1, LineSelectorMat1
		
		setdatafolder root:
	
End



///////////////////////////-Moving simulation results-///////////////////////////////////////

function movestuff (startnum,simnum,place) 
	variable startnum
	variable simnum
	string place
	
	variable i
	for (i=startnum; i<= (startnum+simnum); i+=1)
		string curfile = "ModelResults_"+num2str(i)
		string newname = "Results"+num2str(i)
	 	setdatafolder root:$(curfile)
		movewave root:$(curfile):Broadened_Full_Spectra, root:'place':$(newname)
	
	endfor

END



////////////////////////////-Exporting Waves-////////////////////////////////////////////
	//moves simulated specra data file in path specified folder 
	//will need to make/keep track of paths (in Misc tab)
	//exports from RandCalDump folder 
Function/S SaveWaves (pathName, matname)
	string pathName, matname
	string fileNameList = ""
	
	variable i = 0
	do
		Wave/Z w = WaveRefIndexedDFR(root:'RandCalDump':$matname,i)
		if (!WaveExists(w))
			break
		endif
		
		if (WaveType(w)==0)
			i += 1
			continue
		endif 
		
		String fileName = NameofWave(w) + ".dat"
		Save/P = $pathName /U = {1,1,0,0} /J /O w as fileName
		fileNameList += fileName+ ";"
		
		i += 1
	while(1)
	
	return fileNameList
End


///////////////////////////////////SIMULATION CODES///////////////////////////////////////
	 

//////////////////////////- Random Shifts Simulations-///////////////////

//wrote this function to keep track of tougaard parameters during batch simulations 
Function RandTouCal (simnum)
	variable simnum
	NewDataFolder/O RandCalDump
	
	setdatafolder root:Packages:DatabaseXPS:ValidatedModel
	variable/g numCalc = numCalc

	setdatafolder root:Packages:DatabaseXPS:TouVars
	variable/g Btou = 800
	Variable/g Ctou = 300	
	Variable/g Dtou = 1900
	Variable/g Gaptou = 2.4
	Variable/g MPWtou = 1.5
	variable j = 0
	
	
	for (j=0; j<simnum;j+=1) 
		string curfile = "ModelResults_"+num2str(numcalc)
		string newname = num2str(numcalc)+","+num2str(Btou)+","+num2str(Ctou)+","+num2str(Dtou)
		 				
		RandShifts() 
		
		print j, Btou, Ctou, Dtou
	 	RunSimulationButton ("run simulation")
		 
	 	setdatafolder root:$(curfile)
		movewave root:$(curfile):Broadened_Full_Spectra, root:'RandCalDump':$(newname)
	
	
	endfor 	
	

	setdatafolder root:
END 


//////////////////////////////////////- full Random Simulations-/////////////////////////

//this is the general scheme for simulating large batches of spectra. My hope is that only the section of code that defines the parameters for each simulation will need to be changed 

Function RandomSimulate (simnum)
	//this part keeps track of simulation number and folder for dumping sim results
	variable simnum

	wave/T LayerName = root:Packages:DatabaseXPS:ValidatedModel:LayerName	
	string matname = LayerName[0]+"-"+LayerName[1]
	print matname

	//Sets value for numCalc (simulation indexing variable)
	if(datafolderexists("root:RandCalDump")==1)
		setdatafolder root:RandCalDump
		
		if(datafolderexists(matname)==1)
			variable i = 0
			setdatafolder root:RandCalDump:$matname
			do
				if(waveexists($matname+"_"+num2str(i))==0)
					break
				endif
				i+=1
			while(1)
			setdatafolder root:Packages:DatabaseXPS:ValidatedModel
			variable/g numCalc = i+1
		else
			setdatafolder root:Packages:DatabaseXPS:ValidatedModel
			variable/g numCalc = 1
			Setdatafolder root:RandCalDump
			NewDataFolder/O $(matname)
		endif
	else
		setdatafolder root:Packages:DatabaseXPS:ValidatedModel
		variable/g numCalc = 1
		
		Setdatafolder root:
		NewDataFolder/O RandCalDump
		Setdatafolder root:RandCalDump
		NewDataFolder/O $(matname)
	endif
			
	nvar numCalc = root:Packages:DatabaseXPS:ValidatedModel:numCalc
	
	variable j = 0
	
	for (j=0; j<simnum;j+=1) 
		print numCalc
		string curfile = "ModelResults_"+num2str(numCalc-1)
		string newname = matname+"_"+num2str(numCalc-1)
		
	 //defining how parameters are choosen and runs simulation		
		RandModel()
		RandShifts() 
		RandTou()
		
	 	RunSimulationButton ("run simulation")
	 		
	//moves simulation results to dump folder
	
	 	setdatafolder root:$(curfile)
	 	
	 	movewave root:$(curfile):Broadened_Full_Spectra, root:'RandCalDump':$(matname):$(newname)		
		
		numCalc+=1
	endfor
	 	

	setdatafolder root:
	//exports data in dump folder to specified path 
	newpath/C saves, "C:Training Data:"+matname
	SaveWaves("saves",matname) 
	killpath saves
END 

