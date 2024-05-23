#pragma rtGlobals=1		// Use modern global access method.
#pragma hide=1
static StrConstant kPackageName = "ILAMP XPS package"
static StrConstant kPreferencesFileName = "XPSPackagePreferences.bin"
static Constant kPreferencesRecordID = 0

Function CreateModelCalculationPanel()
	If(stringmatch(winlist("ModelCalculationPanel",";","") ,"")==0)
		Dowindow/HIDE=0 /F ModelCalculationPanel
	Else
		NVAR MatNumber=root:Packages:DatabaseXPS:ValidatedModel:LayerNumber
		WAVE/T MatName=root:Packages:DatabaseXPS:ValidatedModel:LayerName
		NVAR Photon_Energy=root:Packages:DatabaseXPS:ph_energy
		DFREF saveDFR = GetDataFolderDFR()	
		Setdatafolder root:Packages:DatabaseXPS:ValidatedModel
		string control_name,mat_name1,mat_name2
		variable i,j
		string/G ARXPS_validated_summary=""
	
		Dowindow/K ModelCalculationPanel
		STRUCT GeneralXPSParameterPrefs prefs
		LoadPackagePreferences kPackageName, kPreferencesFileName, kPreferencesRecordID, prefs
		If(V_flag!=0 || V_bytesRead==0 || prefs.version<110)	
			Print "Wrong installation. Please re-install the ILAMP package."
			SetDataFolder saveDFR 
			Return -1
		Endif
		
		String DimensionChooser=stringFromList(4,igorinfo(0))
		Variable ScreenVerticalPixelNum,ScreenHorPixelNum
		Sscanf DimensionChooser,"SCREEN1:DEPTH=32,RECT=%*f,%*f,%f,%f",ScreenHorPixelNum,ScreenVerticalPixelNum //2 panels:large panel or small panel
		If(ScreenVerticalPixelNum>950 && prefs.PanelSizeOpt!=2)//large Panel
			NewPanel/K=3 /W=(round(ScreenHorPixelNum*0.25),round(ScreenHorPixelNum*0.1),round(ScreenHorPixelNum*0.25+767) ,round(ScreenHorPixelNum*0.1+690)) as "Model Calculation Panel"
			ModifyPanel fixedsize=1,cbRGB=(65534,65534,65534),noedit=1
			Dowindow/C ModelCalculationPanel
			GroupBox LineSelectorGroup,pos={10,10},size={550,350},title="\\Z16 XPS Line selector"
			GroupBox LineSelectorGroup,frame=0
			For(i=0;i<MatNumber;i+=1)
				control_name="LineListSelector_"+num2str(i)
				mat_name1="LineSelectorMat"+num2str(i)
				mat_name2="LineSelectorMatSel"+num2str(i)
				ListBox $control_name,win=modelCalculationPanel,pos={40,70},size={490,180},proc=PeakChoserListControl,widths={124,45,51,71,44,65}
				ListBox $control_name,listWave=root:Packages:DatabaseXPS:ValidatedModel:$mat_name1,win=modelCalculationPanel,userColumnResize=1
				ListBox $control_name,selWave=root:Packages:DatabaseXPS:ValidatedModel:$mat_name2,win=modelCalculationPanel
				ListBox $control_name,titleWave=root:Packages:DatabaseXPS:ValidatedModel:LineSelectorLegend,win=modelCalculationPanel
				ListBox $control_name,win=modelCalculationPanel,disable= i == 0 ? 0 : 1
			Endfor
			Button SelectAllLines,pos={40,300},size={143,23},proc=SimulationSelectUnselectButton,title="\\Z14Select/Unselect all"
			Button SelectAllLines,fColor=(65535,65535,65535)
			Button JoinSelectedLines,pos={210,300},size={143,23},proc=LinkingSelectionButton,title="\\Z14Join selected lines"
			Button JoinSelectedLines,fColor=(65535,65535,65535)
			Button RestartLineParameters,pos={40,330},size={143,23},proc=ValidateModel,title="\\Z14Reinitialize"
			Button RestartLineParameters,fColor=(65535,65535,65535)
			
			Button JoinCloseEnergyPair,pos={210,330},size={143,23},title="\\Z14Join close peaks..."
			Button JoinCloseEnergyPair,fColor=(65535,65535,65535),proc=LinkingClosePairButton

			Button UndoPeakOperations,pos={381,303},size={143,46},title="\\Z14Undo"
			Button UndoPeakOperations,fColor=(65535,65535,65535),proc=CalcPanel_save_or_undo
			CalcPanel_save_or_undo("SaveOperation")

			Button OpenModelWindow,pos={571,72},size={173,32},proc=ModelButton,title="\\Z14Visualize the model"
			Button OpenAnalyzerWindow,pos={571,117},size={173,32},proc=Anbutton,title="\\Z14Visualize the geometry"
			Button ModelCalculationGuide,pos={571,30},size={173,32},title="\\Z14Guide\\f01 ?",proc=BrixiasHelp//----------------------------Help
		
			GroupBox SimulationAndFitgroup,pos={10,367},size={749,311},title="Simulate and Fit"
			GroupBox SimulationAndFitgroup,fSize=16

			GroupBox SimulationOutputGroup,pos={21,418},size={254,180},title="\\Z12Output"
			GroupBox SimulationOutputGroup,frame=0
			GroupBox SimulationParamGroup,pos={286,418},size={227,180},title="\\Z12Simulation Parameters"
			GroupBox SimulationParamGroup,frame=0
			GroupBox SimulationRunGroup,pos={525,418},size={221,180},title="\\Z12Run & progress "
			GroupBox SimulationRunGroup,frame=0

			ValDisplay SimulationCurrentEnergy,pos={580,347},size={157,16},title="Photon energy (eV)"
			ValDisplay SimulationCurrentEnergy,font="Arial",fSize=12,frame=5
			ValDisplay SimulationCurrentEnergy,limits={0,0,0},barmisc={0,1000},value=_NUM:Photon_Energy
	
			TabControl ModelTab,pos={25,39},size={520,254},labelBack=(65535,65535,65535)
			TabControl ModelTab,value=0,proc=ModelTabFunc
			For(i=0;i<MatNumber;i+=1)
				TabControl ModelTab,tabLabel(i)=MatName[i]
			Endfor
			tabControl ModelTab,tabLabel(i)=""
			Button AddLineButton,pos={190,260},size={173,23},title="\\Z14Duplicate/split line...",proc=DuplicateSelectionButton,fColor=(65535,65535,65535)
			DrawText 585,177,"Theory approximation level"
			PopupMenu SimulationTypeSelection,pos={201,393},size={315,21},bodyWidth=200,proc=SimulationTypeFunc,title="Simulation task:"
			PopupMenu SimulationTypeSelection,fSize=16
			PopupMenu SimulationTypeSelection,mode=1,popvalue="Single configuration evaluation",value= #"\"Single configuration evaluation;Single configuration full spectra;Angle resolved XPS;Energy dispersive XPS;Deep etching;Layer deposition;\""
			
			PopupMenu SimulationApproxSelector,pos={593,185},size={130,21},bodyWidth=130
			PopupMenu SimulationApproxSelector,fSize=14
			PopupMenu SimulationApproxSelector,mode=(4),value= #"\"Straight line;Approximate;Analytical TA;Monte-Carlo TA\""
			DrawText 595,237,"Parameters summary"
			ListBox ParameterSummary,pos={576,243},size={164,90},proc=ParameterSummaryCalcFunc
			ListBox ParameterSummary,listWave=root:Packages:DatabaseXPS:ValidatedModel:ModelParametersMatrix
			ListBox ParameterSummary,widths={15,5},selWave=root:Packages:DatabaseXPS:ValidatedModel:ModelParametersMatrixSel
			//Single simulation controls
			PopupMenu SimulationOutputOption,pos={33,489},size={210,21},title="Peaks representation:"
			PopupMenu SimulationOutputOption,mode=1,popvalue="Absolute values",value= #"\"Absolute values;Peaks area ratio;Normalized area ratio\""
			PopupMenu SimulationOutputType,pos={33,454},size={96,21},title="Display:",proc=SimulationOutputTypeFunc 
			PopupMenu SimulationOutputType,mode=1,popvalue="Table",value= #"\"Table;Graph;Convoluted spectra graph;None\""
			PopupMenu SimulationOutputEnergy,pos={33,524},size={168,21},title="Output Energy"
			PopupMenu SimulationOutputEnergy,mode=1,popvalue="Kinetic Energy",value= #"\"Kinetic Energy;Binding Energy;\"",disable=2
			CheckBox SimulationMakeNewFolder,pos={33,564},size={178,14},title="Make a new data-folder for results"
			CheckBox SimulationMakeNewFolder,value= 0
			Button RunSimulation,pos={548,454},size={175,60},proc=RunSimulationButton,title="\\Z16Run simulation"
			Button RunSimulation,fColor=(65535,65535,65535),valueColor=(65280,0,0)
			//Progress Bar
			ValDisplay SimulationProgressBar,pos={553,533},size={169,24},bodyWidth=86,title="\\Z14Progress Bar"
			ValDisplay SimulationProgressBar,frame=5,limits={0,1,0},barmisc={0,0},mode= 3
			ValDisplay SimulationProgressBar,value= _NUM:0
			//AR-XPS parameters
			Button SimulationARXPSData,pos={310,449},size={178,53},proc=ARXPSParameterButton,title="Insert AR-XPS parameter..."
			Button SimulationARXPSData,fSize=14,fColor=(65535,65535,65535),disable=1
			//Summary parameters for complex calculations
			TitleBox Simulation_validated_summary,pos={309,518},size={180,60},disable=1
			TitleBox Simulation_validated_summary,fSize=12,frame=2
			TitleBox Simulation_validated_summary,variable= root:Packages:DatabaseXPS:ValidatedModel:ARXPS_validated_summary,anchor= MC,fixedSize=1
			//Energy dispersive XPS
			SetVariable CalcSetStartPhoton,pos={309,450},size={180,24},title="Starting photon (eV)\\S "
			SetVariable CalcSetStartPhoton,limits={200,1500,1},value= _NUM:300,disable=1
			SetVariable CalcSetFinalPhoton,pos={309,487},size={179,24},title="Final photon (eV)     \\S "
			SetVariable CalcSetFinalPhoton,limits={200,1500,1},value= _NUM:1500,disable=1
			SetVariable CalcSetPhotonNum,pos={333,524},size={125,24},title="Number of step\\S "
			SetVariable CalcSetPhotonNum,limits={2,inf,1},value= _NUM:2,disable=1
			//Layer Deposition parameters
			SetVariable SimulationDepositionRate,pos={316,449},size={163,24},title="Dep. rate (Å/step)\\S ",disable=1
			SetVariable SimulationDepositionRate,limits={0,100,1},value= _NUM:2
			SetVariable SimulationDepositionTime,pos={316,488},size={140,24},title="Final thickness (Å)\\S "
			SetVariable SimulationDepositionTime,limits={0,1000,1},value= _NUM:20,disable=1
			//Depth etching parameter
			SetVariable SimulationEtchRate,pos={316,449},size={163,24},title="Etching rate (Å/step)\\S ",disable=1
			SetVariable SimulationEtchRate,limits={0,100,1},value= _NUM:2
			SetVariable SimulationEtchTime,pos={316,488},size={140,24},title="Final depth (Å)\\S "
			SetVariable SimulationEtchTime,limits={0,1000,1},value= _NUM:50,disable=1
			//Full-spectra simulation
			PopupMenu simulationFullSpectraTougaard,pos={260,450},size={205,25},title="DIIMFP:",disable=0
			PopupMenu simulationFullSpectraTougaard,mode=8,popvalue="3 parameter",value= #"\"Universal;Polymer;Silicon;Germanium;Silicon Dioxide;Aluminium;Metals average;3 parameter\""
			PopupMenu simulationFullSpectraTougaard bodyWidth=110
			CheckBox SimulationFullSpectraRebuild,pos={347,490},size={102,14},title="Rebuild loss bkg?"
			CheckBox SimulationFullSpectraRebuild,value= 1,side= 1,disable=0
			SetVariable SimulationFullSpecNumpnts,pos={325,530},size={142,16},title="N° output points"
			SetVariable SimulationFullSpecNumpnts,limits={10000,100,1},value= _NUM:2000,disable=0
			//Fit Group box
			Button SimulationInsertExpData,pos={54,615},size={291,46},proc=InsertExpDataButton,title="Insert & fit experimental data"
			Button SimulationInsertExpData,help={"Fit experimental data with the selected simulation code and peak lines"}
			Button SimulationInsertExpData,fSize=14,fStyle=0,fColor=(65535,65535,65535), disable=2
			//Replot
			Button SimulationReplotResults,pos={415,615},size={291,46},title="Re-plot simulation results"
			Button SimulationReplotResults,help={"Re-plot previous simulation results"},proc=RePlotSimulationResults
			Button SimulationReplotResults,fSize=14,fStyle=0,fColor=(65535,65535,65535)

			Doupdate /W=ModelCalculationPanel /E=1
		else	//-------------------------------------------------------------------------------SMALL PANEL-------------------------------------------------------
			NewPanel/K=3 /W=(round(ScreenHorPixelNum*0.25),round(ScreenHorPixelNum*0.1),round(ScreenHorPixelNum*0.25+575) ,round(ScreenHorPixelNum*0.1+581)) as "Model Calculation Panel"
			ModifyPanel fixedsize=1,cbRGB=(65534,65534,65534),noedit=1
			Dowindow/C ModelCalculationPanel
			GroupBox LineSelectorGroup,pos={5,4},size={433,327},title="\\Z14 XPS Line selector"
			GroupBox LineSelectorGroup,frame=0
			for(i=0;i<MatNumber;i+=1)
				control_name="LineListSelector_"+num2str(i)
				mat_name1="LineSelectorMat"+num2str(i)
				mat_name2="LineSelectorMatSel"+num2str(i)
				ListBox $control_name,win=modelCalculationPanel,pos={26,58},size={391,166},proc=PeakChoserListControl,widths={86,53,62,62,47,90}
				ListBox $control_name,listWave=root:Packages:DatabaseXPS:ValidatedModel:$mat_name1,win=modelCalculationPanel,userColumnResize=1
				ListBox $control_name,selWave=root:Packages:DatabaseXPS:ValidatedModel:$mat_name2,win=modelCalculationPanel,fsize=10
				ListBox $control_name,titleWave=root:Packages:DatabaseXPS:ValidatedModel:LineSelectorLegend,win=modelCalculationPanel
				ListBox $control_name,win=modelCalculationPanel,disable= i == 0 ? 0 : 1
			endfor
			Button SelectAllLines,pos={34,273},size={114,21},proc=SimulationSelectUnselectButton,title="\\Z10Select/Unselect all"
			Button SelectAllLines,fColor=(65535,65535,65535)
			Button JoinSelectedLines,pos={174,272},size={119,21},proc=LinkingSelectionButton,title="\\Z10Join selected lines"
			Button JoinSelectedLines,fColor=(65535,65535,65535)
			Button RestartLineParameters,pos={33,300},size={116,21},proc=ValidateModel,title="\\Z10Reinitialize"
			Button RestartLineParameters,fColor=(65535,65535,65535)
			Button JoinCloseEnergyPair,pos={175,301},size={118,21},proc=LinkingClosePairButton,title="\\Z10Join close peaks..."
			Button JoinCloseEnergyPair,fColor=(65535,65535,65535)
			Button UndoPeakOperations,pos={318,275},size={91,42},proc=CalcPanel_save_or_undo,title="\\Z10Undo"
			Button UndoPeakOperations,fColor=(65535,65535,65535)
			CalcPanel_save_or_undo("SaveOperation")

			Button OpenModelWindow,pos={448,57},size={116,26},proc=ModelButton,title="\\Z10Visualize the model"
			Button OpenAnalyzerWindow,pos={449,91},size={116,26},proc=Anbutton,title="\\Z10Visualize the geometry"
			Button ModelCalculationGuide,pos={447,23},size={118,26},title="\\Z10Guide\\f01 ?",proc=BrixiasHelp
			GroupBox SimulationAndFitgroup,pos={5,337},size={566,237},title="Simulate and Fit"
			GroupBox SimulationAndFitgroup,fSize=14
			GroupBox SimulationOutputGroup,pos={13,381},size={204,150},title="\\Z12Output"
			GroupBox SimulationOutputGroup,frame=0
			GroupBox SimulationParamGroup,pos={224,381},size={193,150},title="\\Z12Simulation Parameters"
			GroupBox SimulationParamGroup,frame=0
			GroupBox SimulationRunGroup,pos={424,381},size={138,150},title="\\Z12Run & progress "
			GroupBox SimulationRunGroup,frame=0
			ValDisplay SimulationCurrentEnergy,pos={450,297},size={110,26},title="   Photon\renergy (eV)"
			ValDisplay SimulationCurrentEnergy,font="Arial",fSize=10,frame=5
			ValDisplay SimulationCurrentEnergy,limits={0,0,0},barmisc={0,1000}
			ValDisplay SimulationCurrentEnergy,value= _NUM:Photon_Energy
	
			TabControl ModelTab,pos={16,31},size={411,233},labelBack=(65535,65535,65535)
			TabControl ModelTab,value=0,proc=ModelTabFunc
			for(i=0;i<MatNumber;i+=1)
				TabControl ModelTab,tabLabel(i)=MatName[i]
			endfor
			TabControl ModelTab,tabLabel(i)=""
			
			Button AddLineButton,pos={147,232},size={137,23},title="\\Z12Duplicate/split line...",proc=DuplicateSelectionButton,fColor=(65535,65535,65535)
			DrawText 585,177,"Theory approximation level"
			//Set to Full Spectra (mode=2)//
			PopupMenu SimulationTypeSelection,pos={154,357},size={277,21},bodyWidth=200,proc=SimulationTypeFunc,title="Simulation task:"
			PopupMenu SimulationTypeSelection,fSize=12
			PopupMenu SimulationTypeSelection,mode=2,popvalue="Single configuration full spectra",value= #"\"Single configuration evaluation;Single configuration full spectra;Angle resolved XPS;Energy dispersive XPS;Deep etching;Layer deposition;\""
			//Set to Monte-Carlo (mode=4)//
			PopupMenu SimulationApproxSelector,pos={446,147},size={119,21},bodyWidth=119
			PopupMenu SimulationApproxSelector,fSize=10
			PopupMenu SimulationApproxSelector,mode=(4),value= #"\"Straight line;Approximate;Analytical TA;Monte-Carlo TA\""
			SetDrawLayer UserBack
			SetDrawEnv fsize= 10
			DrawText 455,141,"Theory approximation"
			SetDrawEnv fsize= 10
			DrawText 457,191,"Parameters summary"
			
			ListBox ParameterSummary,pos={446,196},size={121,87},proc=ParameterSummaryCalcFunc,fsize=10
			ListBox ParameterSummary,listWave=root:Packages:DatabaseXPS:ValidatedModel:ModelParametersMatrix
			ListBox ParameterSummary,widths={15,5},selWave=root:Packages:DatabaseXPS:ValidatedModel:ModelParametersMatrixSel
			
			//Single simulation controls
			PopupMenu SimulationOutputOption,pos={24,435},size={173,21},title="Normalization:", disable=2
			PopupMenu SimulationOutputOption,mode=1,popvalue="Absolute values",value= #"\"Absolute values;Peaks area ratio;Normalized area ratio\""
			PopupMenu SimulationOutputType,pos={24,403},size={96,21},proc=SimulationOutputTypeFunc,title="Display:"
			PopupMenu SimulationOutputType,mode=1,popvalue="Table",value= #"\"Table;Graph;Convoluted spectra graph;None\"", disable=2
			PopupMenu SimulationOutputEnergy,pos={24,472},size={168,21},disable=0,title="Output Energy"
			PopupMenu SimulationOutputEnergy,mode=1,popvalue="Kinetic Energy",value= #"\"Kinetic Energy;Binding Energy;\""
			CheckBox SimulationMakeNewFolder,pos={24,504},size={178,14},title="Make a new data-folder for results"
			CheckBox SimulationMakeNewFolder,fSize=10,value= 0
			Button RunSimulation,pos={440,411},size={108,47},proc=RunSimulationButton,title="\\Z14Run simulation"
			Button RunSimulation,fColor=(65535,65535,65535),valueColor=(65280,0,0)
			//Progress Bar
			ValDisplay SimulationProgressBar,pos={445,476},size={98,17},bodyWidth=98,frame=5
			ValDisplay SimulationProgressBar,limits={0,1,0},barmisc={0,0},mode= 3
			ValDisplay SimulationProgressBar,value= _NUM:0
			//AR-XPS parameters
			Button SimulationARXPSData,pos={242,409},size={159,47},proc=ARXPSParameterButton,title="Insert AR-XPS parameter..."
			Button SimulationARXPSData,fSize=12,fColor=(65535,65535,65535),disable=1
			TitleBox Simulation_validated_summary,pos={234,468},size={174,54},fSize=08
			TitleBox Simulation_validated_summary,frame=2,disable=1
			TitleBox Simulation_validated_summary,variable= root:Packages:DatabaseXPS:ValidatedModel:ARXPS_validated_summary,anchor= MC,fixedSize=1
			//Energy dispersive XPS
			SetVariable CalcSetStartPhoton,pos={234,410},size={171,24},title="Starting photon (eV)\\S "
			SetVariable CalcSetStartPhoton,limits={200,1500,1},value= _NUM:300,disable=1
			SetVariable CalcSetFinalPhoton,pos={234,447},size={170,24},title="Final photon (eV)     \\S "
			SetVariable CalcSetFinalPhoton,limits={200,1500,1},value= _NUM:1500,disable=1
			SetVariable CalcSetPhotonNum,pos={257,484},size={119,24},title="Number of step\\S "
			SetVariable CalcSetPhotonNum,limits={2,inf,1},value= _NUM:2,disable=1
			//Layer Deposition parameters
			SetVariable SimulationDepositionRate,pos={240,415},size={160,24},title="Dep. rate (Å/step)",disable=1
			SetVariable SimulationDepositionRate,limits={0,100,1},value= _NUM:2
			SetVariable SimulationDepositionTime,pos={240,461},size={140,24},title="Final thickness (Å)"
			SetVariable SimulationDepositionTime,limits={0,1000,1},value= _NUM:20,disable=1
			//Depth etching parameter
			SetVariable SimulationEtchRate,pos={240,422},size={163,24},title="Etching rate (Å/step)"
			SetVariable SimulationEtchRate,limits={0,100,1},value= _NUM:2,disable=1
			SetVariable SimulationEtchTime,pos={240,461},size={140,24},title="Final depth (Å)"
			SetVariable SimulationEtchTime,limits={0,1000,1},value= _NUM:50,disable=1
			//Full-spectra simulation //Set to 3 parameter (mode=8)//
			PopupMenu simulationFullSpectraTougaard,pos={241,415},size={152,21},bodyWidth=110,title="DIIMFP:",disable=0
			PopupMenu simulationFullSpectraTougaard,mode=8,popvalue="3 parameter",value= #"\"Universal;Polymer;Silicon;Germanium;Silicon Dioxide;Aluminium;Metals average;3 parameter\""
			CheckBox SimulationFullSpectraRebuild,pos={275,455},size={102,14},title="Rebuild loss bkg?",disable=0
			CheckBox SimulationFullSpectraRebuild,value= 1,side= 1
			SetVariable SimulationFullSpecNumpnts,pos={253,495},size={142,16},title="N° output points",disable=0
			SetVariable SimulationFullSpecNumpnts,limits={10000,100,1},value= _NUM:2000
			//Fit Group box
			Button SimulationInsertExpData,pos={22,538},size={260,26},proc=InsertExpDataButton,title="Insert & fit experimental data"
			Button SimulationInsertExpData,help={"Fit experimental data with the selected simulation code and peak lines"}
			Button SimulationInsertExpData,fSize=12,fStyle=0,fColor=(65535,65535,65535), disable=2
			//Replot
			Button SimulationReplotResults,pos={302,538},size={250,26},proc=RePlotSimulationResults,title="Re-plot simulation results"
			Button SimulationReplotResults,help={"Re-plot previous simulation results"}
			Button SimulationReplotResults,fSize=12,fStyle=0,fColor=(65535,65535,65535)
			Doupdate /W=ModelCalculationPanel /E=1
		endif
		setdatafolder saveDFR
	endif
End
//Help
Function BriXiasHelp(ctrlname): buttoncontrol
	string ctrlname
	
	strswitch(ctrlname)
		case "ModelCalculationGuide":
			DisplayHelpTopic/Z "Chapter 5: Model layout and simulation[Simulation Panel Overview]"
		break
		case "ExpDataInsertAndFitGuide":
			DisplayHelpTopic/Z "Chapter 5: Model layout and simulation[Optimization - Single configuration]"
		break
		case "FitPanelHelp":
			DisplayHelpTopic/Z "Chapter 5: Model layout and simulation[Optimization - Single configuration]"
		break
		case "VamasLoadFileHelp":
			DisplayHelpTopic/Z "Chapter 2: Data loading[Importing and exporting VAMAS .vms files]"
		break
		case "VamasSaveFileHelp":
			DisplayHelpTopic/Z "Chapter 2: Data loading[Importing and exporting VAMAS .vms files]"
		break
		case "RemoveBatchBKGGuide":
			DisplayHelpTopic/Z "Chapter 3: Data Analysis[Background Subtraction]"
		break
		case "BatchaAlignBKGGuide":
			DisplayHelpTopic/Z "Chapter 3: Data Analysis[Data rescaling]"
		break
		case "DisplayIndexWaveGuide":
			DisplayHelpTopic/Z "BriXias manual appendix[BriXias extras]"
		break
		case "CreateIndexWaveGuide":
			DisplayHelpTopic/Z "BriXias manual appendix[BriXias extras]"
		break
	endswitch
	
	return 0
end

//Undo button procedures
Function CalcPanel_save_or_undo(ctrlname) : buttonControl
	string ctrlname
	DFREF backupFolder=GetDataFolderDFR()
	setDataFolder root:Packages:DatabaseXPS:ValidatedModel
	
	variable i
	string ref_name,set_name,link_name
	string ref_name_bkp,set_name_bkp,link_name_bkp
	
	NVAR matnumber=root:Packages:DatabaseXPS:ValidatedModel:LayerNumber
	
	strswitch(ctrlname)
		case "SaveOperation":
			for(i=0;i<matnumber;i+=1)
				ref_name="LineSelectorMat"+num2str(i)
				set_name="LineSelectorMatSel"+num2str(i)
				link_name="isLinked"+num2str(i)
		
				ref_name_bkp="LineSelectorMat"+num2str(i)+"_bkp"
				set_name_bkp="LineSelectorMatSel"+num2str(i)+"_bkp"
				link_name_bkp="isLinked"+num2str(i)+"_bkp"
				
				wave mat_sel=root:Packages:DatabaseXPS:ValidatedModel:$set_name
				wave/T mat_name=root:Packages:DatabaseXPS:ValidatedModel:$ref_name
				wave linkwave=root:Packages:DatabaseXPS:ValidatedModel:$link_name
				duplicate/O mat_sel $set_name_bkp
				duplicate/O mat_name $ref_name_bkp
				duplicate/O linkwave $link_name_bkp
			endfor
		break
		case"UndoPeakOperations":
			for(i=0;i<matnumber;i+=1)
				ref_name="LineSelectorMat"+num2str(i)
				set_name="LineSelectorMatSel"+num2str(i)
				link_name="isLinked"+num2str(i)
		
				ref_name_bkp="LineSelectorMat"+num2str(i)+"_bkp"
				set_name_bkp="LineSelectorMatSel"+num2str(i)+"_bkp"
				link_name_bkp="isLinked"+num2str(i)+"_bkp"
				
				wave mat_sel=root:Packages:DatabaseXPS:ValidatedModel:$set_name
				wave/T mat_name=root:Packages:DatabaseXPS:ValidatedModel:$ref_name
				wave linkwave=root:Packages:DatabaseXPS:ValidatedModel:$link_name
			
				wave mat_sel_bkp=root:Packages:DatabaseXPS:ValidatedModel:$set_name_bkp
				wave/T mat_name_bkp=root:Packages:DatabaseXPS:ValidatedModel:$ref_name_bkp
				wave linkwave_bkp=root:Packages:DatabaseXPS:ValidatedModel:$link_name_bkp
				mat_sel=mat_sel_bkp
				mat_name=mat_name_bkp
				linkwave=linkwave_bkp
			endfor
		break
	endswitch
	setDataFolder BackupFolder
end
//------------------------------------------------------ListBox check-------------------------------------------------------------------//
Function ParameterSummaryCalcFunc(LB_Struct) : ListboxControl
	STRUCT WMListboxAction &LB_Struct
	
	DFREF saveDFR = GetDataFolderDFR()	
	setdatafolder root:Packages:DatabaseXPS:ValidatedModel
	string result
	if(LB_struct.eventcode==7 && lb_struct.col>=1)
		result=LB_struct.listwave[LB_struct.row][LB_struct.col]
		LB_struct.listwave[LB_struct.row][LB_struct.col]=num2str(str2num(result))
		
		NVAR matnumber=root:Packages:DatabaseXPS:ValidatedModel:LayerNumber	
		Wave thickness=root:Packages:DatabaseXPS:ValidatedModel:thickness
		NVAR island_area=root:Packages:DatabaseXPS:ValidatedModel:Island_area
		NVAR island_depth=root:Packages:DatabaseXPS:ValidatedModel:Island_depth
		NVAR roughness=root:Packages:DatabaseXPS:ValidatedModel:Roughness
		Variable i,j
		
		i=0
		switch(dimsize(LB_struct.listwave,0)-numpnts(thickness))
		case 1:
			roughness=str2num(LB_struct.listwave[0][1])
			if(roughness<0)
				roughness=0
				LB_struct.listwave[0][1]="0"
			endif
			i=1
		break
		case 2:
			island_area=str2num(LB_struct.listwave[1][1])
			if(island_area>1 || island_area<0)
				island_area=1
				LB_struct.listwave[1][1]="1"
			endif
			island_depth=str2num(LB_struct.listwave[0][1])
			if(island_depth<0)
				island_depth=0
				LB_struct.listwave[0][1]="0"
			endif
			i=2
		break
		case 3:
			island_area=str2num(LB_struct.listwave[2][1])
			if(island_area>1 || island_area<0)
				island_area=1
				LB_struct.listwave[2][1]="1"
			endif
			island_depth=str2num(LB_struct.listwave[1][1])
			if(island_depth<0)
				island_depth=0
				LB_struct.listwave[1][1]="0"
			endif
			roughness=str2num(LB_struct.listwave[0][1])
			if(roughness<0)
				roughness=0
				LB_struct.listwave[0][1]="0"
			endif
			i=3
		break
		endswitch
		j=0
		do
			thickness[j]=str2num(LB_struct.listwave[i][1])
			if(thickness[j]<0)
				thickness[j]=0.01
				LB_struct.listwave[i][1]="0.01"
			endif
			i+=1
			j+=1
		while(i<dimsize(LB_struct.listwave,0))
	endif
	setdatafolder saveDFR	
End

Function PeakChoserListControl(LB_Struct) : ListboxControl
	STRUCT WMListboxAction &LB_Struct
	
	DFREF saveDFR = GetDataFolderDFR()	
	setdatafolder root:Packages:DatabaseXPS:ValidatedModel
	
	string result
	if(LB_struct.col>=1 && lb_struct.eventcode==6)
		CalcPanel_save_or_undo("SaveOperation") //backup
	endif
	if(LB_struct.eventcode==7 && lb_struct.col>=1)
		result=LB_struct.listwave[LB_struct.row][LB_struct.col]
		LB_struct.listwave[LB_struct.row][LB_struct.col][0]=num2str(str2num(result))
	endif
	
	if(LB_struct.eventcode==2 && lb_struct.col==0)
		variable Selresult=LB_struct.selwave[LB_struct.row][0]
		controlinfo/W=ModelCalculationPanel ModelTab
		string namelink="IsLinked"+num2str(V_Value)
		string nameMatSel
		wave currentLink=root:Packages:DatabaseXPS:validatedModel:$namelink
		variable currentLinkValue=currentLink[LB_struct.row]		
		
		variable i,j
		if(currentLinkValue!=0)
			NVAR numLayer=root:Packages:DatabaseXPS:ValidatedModel:LayerNumber
			for(i=0;i<numLayer;i+=1)
				namelink="IsLinked"+num2str(i)
				nameMatSel="LineSelectorMatSel"+num2str(i)
				wave currentLink=root:Packages:DatabaseXPS:validatedModel:$namelink
				wave currentSel=root:Packages:DatabaseXPS:validatedModel:$nameMatSel
				for(j=0;j<numpnts(currentLink);j+=1)
					If(currentLink[j]==currentLinkValue)
						currentSel[j][0]=SelResult
					endif
				endfor
			endfor
		endif
	endif	
	setdatafolder saveDFR
End
//--------------------------------------------------------------------------popup menu controls-----------------------------------------------------------
Function SimulationOutputTypeFunc (ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum	// which item is currently selected (1-based)
	String popStr		// contents of current popup item as string
	switch(popNum)
		case 1:
			PopupMenu SimulationOutputOption,win=ModelCalculationPanel,disable=0
			PopupMenu SimulationOutputEnergy,win=ModelCalculationPanel,disable=2
		break
		case 2:
			PopupMenu SimulationOutputOption,win=ModelCalculationPanel,disable=0
			PopupMenu SimulationOutputEnergy,win=ModelCalculationPanel,disable=2
		break
		case 3:
			PopupMenu SimulationOutputOption,win=ModelCalculationPanel,disable=2,popvalue="Absolute values"
			PopupMenu SimulationOutputEnergy,win=ModelCalculationPanel,disable=0
		break
endswitch
End
//----------------------------------------------------------------------type of calculation pop-up-------------------------------------------------------------
Function SimulationTypeFunc (ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum	// which item is currently selected (1-based)
	String popStr		// contents of current popup item as string
switch(popNum)
	case 1:
		TitleBox Simulation_validated_summary,win=ModelCalculationPanel,disable=1
		Button SimulationARXPSData,win=ModelCalculationPanel,disable=1
		Button SimulationInsertExpData,disable=0
		PopupMenu SimulationOutputType,win=ModelCalculationPanel,disable=0
		PopupMenu SimulationOutputOption,win=ModelCalculationPanel,disable=0
		PopupMenu SimulationOutputEnergy,win=ModelCalculationPanel,disable=0
		PopupMenu simulationFullSpectraTougaard,win=ModelCalculationPanel,disable=1
		CheckBox SimulationFullSpectraRebuild,win=ModelCalculationPanel,disable=1
		SetVariable SimulationFullSpecNumpnts,win=ModelCalculationPanel,disable=1
		SetVariable SimulationEtchRate,win=ModelCalculationPanel,disable=1
		SetVariable SimulationEtchTime,win=ModelCalculationPanel,disable=1
		SetVariable SimulationDepositionRate,win=ModelCalculationPanel,disable=1
		SetVariable SimulationDepositionTime,win=ModelCalculationPanel,disable=1
		SetVariable CalcSetStartPhoton,win=ModelCalculationPanel,disable=1
		SetVariable CalcSetFinalPhoton,win=ModelCalculationPanel,disable=1
		SetVariable CalcSetPhotonNum,win=ModelCalculationPanel,disable=1
	break
	case 2:
		TitleBox Simulation_validated_summary,win=ModelCalculationPanel,disable=1
		Button SimulationARXPSData,win=ModelCalculationPanel,disable=1
		Button SimulationInsertExpData,disable=2
		PopupMenu SimulationOutputType,win=ModelCalculationPanel,disable=2,popvalue="Convoluted spectra graph"
		PopupMenu SimulationOutputOption,win=ModelCalculationPanel,disable=2,popvalue="Absolute values"
		PopupMenu SimulationOutputEnergy,win=ModelCalculationPanel,disable=0
		PopupMenu simulationFullSpectraTougaard,win=ModelCalculationPanel,disable=0
		CheckBox SimulationFullSpectraRebuild,win=ModelCalculationPanel,disable=0
		SetVariable SimulationFullSpecNumpnts,win=ModelCalculationPanel,disable=0
		SetVariable SimulationEtchRate,win=ModelCalculationPanel,disable=1
		SetVariable SimulationEtchTime,win=ModelCalculationPanel,disable=1
		SetVariable SimulationDepositionRate,win=ModelCalculationPanel,disable=1
		SetVariable SimulationDepositionTime,win=ModelCalculationPanel,disable=1
		SetVariable CalcSetStartPhoton,win=ModelCalculationPanel,disable=1
		SetVariable CalcSetFinalPhoton,win=ModelCalculationPanel,disable=1
		SetVariable CalcSetPhotonNum,win=ModelCalculationPanel,disable=1
	break
	case 3:
		TitleBox Simulation_validated_summary,win=ModelCalculationPanel,disable=0
		Button SimulationARXPSData,win=ModelCalculationPanel,disable=0
		Button SimulationInsertExpData,disable=0
		PopupMenu SimulationOutputType,win=ModelCalculationPanel,disable=0
		PopupMenu SimulationOutputOption,win=ModelCalculationPanel,disable=0
		PopupMenu SimulationOutputEnergy,win=ModelCalculationPanel,disable=0
		PopupMenu simulationFullSpectraTougaard,win=ModelCalculationPanel,disable=1
		CheckBox SimulationFullSpectraRebuild,win=ModelCalculationPanel,disable=1
		SetVariable SimulationFullSpecNumpnts,win=ModelCalculationPanel,disable=1	
		SetVariable SimulationEtchRate,win=ModelCalculationPanel,disable=1
		SetVariable SimulationEtchTime,win=ModelCalculationPanel,disable=1
		SetVariable SimulationDepositionRate,win=ModelCalculationPanel,disable=1
		SetVariable SimulationDepositionTime,win=ModelCalculationPanel,disable=1
		SetVariable CalcSetStartPhoton,win=ModelCalculationPanel,disable=1
		SetVariable CalcSetFinalPhoton,win=ModelCalculationPanel,disable=1
		SetVariable CalcSetPhotonNum,win=ModelCalculationPanel,disable=1
	break
	case 4:
		TitleBox Simulation_validated_summary,win=ModelCalculationPanel,disable=1
		Button SimulationARXPSData,win=ModelCalculationPanel,disable=1
		Button SimulationInsertExpData,disable=2
		PopupMenu SimulationOutputType,win=ModelCalculationPanel,disable=0
		PopupMenu SimulationOutputOption,win=ModelCalculationPanel,disable=0
		PopupMenu SimulationOutputEnergy,win=ModelCalculationPanel,disable=0
		PopupMenu simulationFullSpectraTougaard,win=ModelCalculationPanel,disable=1
		CheckBox SimulationFullSpectraRebuild,win=ModelCalculationPanel,disable=1
		SetVariable SimulationFullSpecNumpnts,win=ModelCalculationPanel,disable=1
		SetVariable SimulationEtchRate,win=ModelCalculationPanel,disable=1
		SetVariable SimulationEtchTime,win=ModelCalculationPanel,disable=1
		SetVariable SimulationDepositionRate,win=ModelCalculationPanel,disable=1
		SetVariable SimulationDepositionTime,win=ModelCalculationPanel,disable=1
		SetVariable CalcSetStartPhoton,win=ModelCalculationPanel,disable=0
		SetVariable CalcSetFinalPhoton,win=ModelCalculationPanel,disable=0
		SetVariable CalcSetPhotonNum,win=ModelCalculationPanel,disable=0
	break
	case 5:
		TitleBox Simulation_validated_summary,win=ModelCalculationPanel,disable=1
		Button SimulationARXPSData,win=ModelCalculationPanel,disable=1
		Button SimulationInsertExpData,disable=2
		PopupMenu SimulationOutputType,win=ModelCalculationPanel,disable=0
		PopupMenu SimulationOutputOption,win=ModelCalculationPanel,disable=0
		PopupMenu SimulationOutputEnergy,win=ModelCalculationPanel,disable=0
		PopupMenu simulationFullSpectraTougaard,win=ModelCalculationPanel,disable=1
		CheckBox SimulationFullSpectraRebuild,win=ModelCalculationPanel,disable=1
		SetVariable SimulationFullSpecNumpnts,win=ModelCalculationPanel,disable=1
		SetVariable SimulationEtchRate,win=ModelCalculationPanel,disable=0
		SetVariable SimulationEtchTime,win=ModelCalculationPanel,disable=0
		SetVariable SimulationDepositionRate,win=ModelCalculationPanel,disable=1
		SetVariable SimulationDepositionTime,win=ModelCalculationPanel,disable=1
		SetVariable CalcSetStartPhoton,win=ModelCalculationPanel,disable=1
		SetVariable CalcSetFinalPhoton,win=ModelCalculationPanel,disable=1
		SetVariable CalcSetPhotonNum,win=ModelCalculationPanel,disable=1
	break
	case 6:
		TitleBox Simulation_validated_summary,win=ModelCalculationPanel,disable=1
		Button SimulationARXPSData,win=ModelCalculationPanel,disable=1
		Button SimulationInsertExpData,disable=2
		PopupMenu SimulationOutputType,win=ModelCalculationPanel,disable=0
		PopupMenu SimulationOutputOption,win=ModelCalculationPanel,disable=0
		PopupMenu SimulationOutputEnergy,win=ModelCalculationPanel,disable=0
		PopupMenu simulationFullSpectraTougaard,win=ModelCalculationPanel,disable=1
		CheckBox SimulationFullSpectraRebuild,win=ModelCalculationPanel,disable=1
		SetVariable SimulationFullSpecNumpnts,win=ModelCalculationPanel,disable=1
		SetVariable SimulationEtchRate,win=ModelCalculationPanel,disable=1
		SetVariable SimulationEtchTime,win=ModelCalculationPanel,disable=1
		SetVariable SimulationDepositionRate,win=ModelCalculationPanel,disable=0
		SetVariable SimulationDepositionTime,win=ModelCalculationPanel,disable=0
		SetVariable CalcSetStartPhoton,win=ModelCalculationPanel,disable=1
		SetVariable CalcSetFinalPhoton,win=ModelCalculationPanel,disable=1
		SetVariable CalcSetPhotonNum,win=ModelCalculationPanel,disable=1
	break
	default:
		TitleBox Simulation_validated_summary,win=ModelCalculationPanel,disable=1
		Button SimulationARXPSData,win=ModelCalculationPanel,disable=1
		Button SimulationInsertExpData,disable=2
		PopupMenu SimulationOutputType,win=ModelCalculationPanel,disable=0
		PopupMenu SimulationOutputOption,win=ModelCalculationPanel,disable=0
		PopupMenu SimulationOutputEnergy,win=ModelCalculationPanel,disable=0
		PopupMenu simulationFullSpectraTougaard,win=ModelCalculationPanel,disable=1
		CheckBox SimulationFullSpectraRebuild,win=ModelCalculationPanel,disable=1
		SetVariable SimulationFullSpecNumpnts,win=ModelCalculationPanel,disable=1
		SetVariable SimulationEtchRate,win=ModelCalculationPanel,disable=1
		SetVariable SimulationEtchTime,win=ModelCalculationPanel,disable=1
		SetVariable SimulationDepositionRate,win=ModelCalculationPanel,disable=1
		SetVariable SimulationDepositionTime,win=ModelCalculationPanel,disable=1
		SetVariable CalcSetStartPhoton,win=ModelCalculationPanel,disable=1
		SetVariable CalcSetFinalPhoton,win=ModelCalculationPanel,disable=1
		SetVariable CalcSetPhotonNum,win=ModelCalculationPanel,disable=1
	break
	endswitch
End
//------------------------------------
Function ModelTabFunc(TC_Struct) : TabControl
	STRUCT WMTabControlAction &TC_Struct
	NVAR MatNumber=root:Packages:DatabaseXPS:ValidatedModel:LayerNumber
	string control_name,mat_name1,mat_name2
	variable i
	string DimensionChooser=stringFromList(4,igorinfo(0))
	variable ScreenVerticalPixelNum,ScreenHorPixelNum
	sscanf DimensionChooser,"SCREEN1:DEPTH=32,RECT=%*f,%*f,%f,%f",ScreenHorPixelNum,ScreenVerticalPixelNum //2 panels:large panel or small panel
	if(screenVerticalPixelNum>950)	
		for(i=0;i<MatNumber;i+=1)
			control_name="LineListSelector_"+num2str(i)
			mat_name1="LineSelectorMat"+num2str(i)
			mat_name2="LineSelectorMatSel"+num2str(i)
			ListBox $control_name,listWave=root:Packages:DatabaseXPS:ValidatedModel:$mat_name1,win=modelCalculationPanel
			ListBox $control_name,selWave=root:Packages:DatabaseXPS:ValidatedModel:$mat_name2,win=modelCalculationPanel
			ListBox $control_name,titleWave=root:Packages:DatabaseXPS:ValidatedModel:LineSelectorLegend,win=modelCalculationPanel
			ListBox $control_name,widths={10,5,6,6,6},win=modelCalculationPanel,disable= i==TC_struct.tab ? 0 : 1
		endfor
	else
		for(i=0;i<MatNumber;i+=1)
			control_name="LineListSelector_"+num2str(i)
			mat_name1="LineSelectorMat"+num2str(i)
			mat_name2="LineSelectorMatSel"+num2str(i)
			ListBox $control_name,listWave=root:Packages:DatabaseXPS:ValidatedModel:$mat_name1,win=modelCalculationPanel
			ListBox $control_name,selWave=root:Packages:DatabaseXPS:ValidatedModel:$mat_name2,win=modelCalculationPanel
			ListBox $control_name,titleWave=root:Packages:DatabaseXPS:ValidatedModel:LineSelectorLegend,win=modelCalculationPanel
			ListBox $control_name,widths={18,5,6,6,6},win=modelCalculationPanel,disable= i==TC_struct.tab ? 0 : 1
		endfor
	endif
End

Function AnButton(ctrlName) : ButtonControl
	String ctrlName
	DFREF oldDir=GetDataFolderDFR()
	Execute "CreateAnalyzerSetup_panel()"
	setdatafolder olddir 
End

Function ModelButton(ctrlName) : ButtonControl
	String ctrlName
	DFREF oldDir=GetDataFolderDFR()
	Execute "CreateModelLayoutPanel()"
	setdatafolder olddir 
End
//---------------------------------------------------------AR-XPS data button------------------------------------------------------------//
Function ARXPSParameterButton(ctrlName) : ButtonControl
	String ctrlName
	DFREF saveDFR = GetDataFolderDFR()	
	setdatafolder root:Packages:DatabaseXPS:ValidatedModel
	SimulationInsertARXPSPanel()
	setdatafolder saveDFR
End
//------------------------------------------------------Running button main function---------------------------------------------------//
Function RunSimulationButton(ctrlName) : ButtonControl
	String ctrlName
	DFREF saveDFR=getdatafolderDFR()
	string WorkingDir
	setdatafolder root:Packages:DatabaseXPS:ValidatedModel
	variable/G numCalc
	numCalc= numtype(numCalc)==2 || numcalc==0 ? 1 : numCalc
	controlinfo/W=ModelCalculationPanel SimulationMakeNewFolder	
	if(V_value==1)
		workingDir="root:ModelResults_"+num2str(numCalc)
	else
		if(numtype(numCalc)==2)
			workingDir="root:Packages:DatabaseXPS:CalcDump"
		else
			workingDir="root:ModelResults_"+num2str(numCalc-1)
		endif
	endif
	
	newdatafolder/O/S $workingDir
	numCalc= V_value==1? numCalc+1 : numCalc
	
	variable err=simulationParseChosenLines(0)
	if(err==-1)
		doalert 0,"No lines selected"
		setdatafolder SaveDFR
		return 0
	elseif(err==-2)
		doalert 0, "Wrong Serial Code. Not possible to proceed with calculation or fitting. Please re-install package."
		setdatafolder SaveDFR
		return 0
	elseif(err==-3)
		Print "Please note: for fitting purpose, you should select at least one peak for each layer."
	elseif(err == -4)
		Doalert 0,"Please give valid angular parameter trough the 'Insert AR-XPS button first '."
		Setdatafolder saveDFR
		Return 0
	endif
	
	controlinfo/W=modelCalculationPanel SimulationOutputType	
	variable DisplayType=V_value
	
	controlinfo/W=modelCalculationPanel SimulationOutputOption
	variable WhatToShow=V_value
	
	controlinfo/W=modelCalculationPanel SimulationOutputEnergy
	variable DataScaling=V_value
	
	controlinfo/W=ModelCalculationPanel SimulationApproxSelector
	variable theory=V_Value-1
	
	controlinfo/W=ModelCalculationPanel SimulationTypeSelection
	variable/G calc_type=V_value
	switch(calc_type)
		case 1:
			SimulateSingleCalculation(theory)
			DisplaySimulationResults(calc_type,displayType,WhatToShow,DataScaling,NumCalc)
		break
		case 2:
			controlinfo/W=ModelCalculationPanel simulationFullSpectraTougaard
			variable Tou_type=V_value
			controlinfo/W=ModelCalculationPanel simulationFullSpectraRebuild
			SimulateFullSpectraCalculation(Tou_type,V_value)
			//DisplaySimulationResults(calc_type,displayType,WhatToShow,DataScaling,NumCalc)
		break
		case 3:
			SimulateARXPSCalculation(theory)
			DisplaySimulationResults(calc_type,displayType,WhatToShow,DataScaling,NumCalc)
		break
		case 4:
			SimulateEDXPSCalculation(theory)
			DisplaySimulationResults(calc_type,displayType,WhatToShow,DataScaling,NumCalc)
		break
		case 5:
			SimulateDepEtchCalculation(theory)
			DisplaySimulationResults(calc_type,displayType,WhatToShow,DataScaling,NumCalc)
		break
		case 6:
			SimulateLayerDepCalculation(theory)
			DisplaySimulationResults(calc_type,displayType,WhatToShow,DataScaling,NumCalc)
		break
	endswitch
//	doalert 0,"Simulation done; results are stored in the '"+workingDir+"' directory."
	setdatafolder saveDFR		
End

Function RePlotSimulationResults(ctrlName) : ButtonControl
	string CtrlName
	
	string CompleteDataFolderList=stringByKey("FOLDERS",DataFolderDir(1), ":", ";")
	string ValidDataFolderList="",ValidDataCalcType="",ValidDataFolderNum="",aux1
	string CalcTypeList="Single configuration;Full spectra;AR-XPS;ED-XPS;Depth profile;Layer deposition;"
	variable i,current_num
	
	for(i=0;i<ItemsInList(CompleteDataFolderList,",");i+=1)
		aux1=stringFromList(i,CompleteDataFolderList,",")
		If(stringmatch(aux1,"ModelResults_*"))
			sscanf aux1,"ModelResults_%f",current_num
			if(exists(":"+aux1+":Calc_Type"))
				NVAR CalcType=:$(aux1):Calc_Type
				ValidDataFolderList+="folder n°:"+num2str(current_num)+" - type:" + stringFromList(Calctype-1,CalcTypeList,";")+";"
				ValidDataCalcType+=num2str(Calctype)+";"
				ValidDataFolderNum+=num2str(current_Num)+";"
			endif
		endif
	endfor
	
	if(itemsInList(ValidDataFolderList,";")==0)
		doalert 0,"Valid simulation results (subfolders) can't be found in the current data folder."
		return -1
	endif
	
	Variable WhatFolderSelection=1
	Variable WhatToShow=1
	Variable WhatDisplayType=1
	Variable WhatScaling=1
	
	Prompt WhatFolderSelection,"Simulation folder:",popup,ValidDataFolderList
	Prompt WhatDisplayType,"Display:",popup,"Table;Graph;Convoluted spectra;"
	Prompt WhatToShow,"Data normalization:",popup,"Absolute values;Normalized values;Normalized to cross section;"
	Prompt WhatScaling,"Energy scaling",popup,"Kinetic Energy;Binding energy;"
	DoPrompt "Plotting parameters",WhatFolderSelection,WhatDisplayType,WhatToShow,WhatScaling
	
	If(V_flag)
		return-1
	endif
	
	String currentFolder=":ModelResults_"+stringFromList(WhatfolderSelection-1,ValidDataFolderNum)
	Variable Ctype=str2num(stringFromList(WhatFolderSelection-1,ValidDataCalcType))
	Variable NumCalc=str2num(stringFromList(WhatFolderSelection-1,ValidDataFolderNum))	
	
	DFREF BackupFolder=GetDataFolderDFR()
	SetDatafolder CurrentFolder
		DisplaySimulationResults(Ctype,WhatDisplayType,WhatToShow,WhatScaling,NumCalc)
	SetDataFolder backupFolder
end
//------------------------------------------------------Button Control for experimental and fitting procedures----------------------------------//
function InsertExpDataButton(ctrlName) : ButtonControl
	String ctrlName
	DFREF saveDFR = GetDataFolderDFR()	
	Newdatafolder/O/S root:Packages:DatabaseXPS:FitDump
	
	Variable err=0
	Controlinfo/W=ModelCalculationPanel SimulationTypeSelection
	Switch(V_value)
		Case 1:
			err=simulationParseChosenLines(1)
			break
		Case 3:
			err=simulationParseChosenLines(2)
			break
		Default:
			SetDataFolder saveDFR
			return -1
			break
	Endswitch
	
	If(err == -1)
		Doalert 0,"No lines selected."
		Setdatafolder saveDFR
		Return -1
	Endif
	If(err == -2)
		Doalert 0,"Please select at least one XPS line for each layer."
		Setdatafolder saveDFR
		Return -1
	Endif
	
	Controlinfo/W=ModelCalculationPanel SimulationTypeSelection
	
	Switch(V_value)
		case 1:
			InsertExpDataSingleConf()
			break
		case 3:
			InsertExpDataARXPS()
			break
	endswitch
	Dowindow/Hide=1 ModelCalculationPanel
	Setdatafolder saveDFR
end

//-------------------------------------------------------------------------------------------line parser before every kind of calculation---------------------------------------------------------------//
Function SimulationParseChosenLines(ExpDataCheck)
	Variable ExpDataCheck
	NVAR matnumber=root:Packages:DatabaseXPS:ValidatedModel:LayerNumber
	NVAR photon_energy=root:Packages:DatabaseXPS:ph_energy
	NVAR work_f=root:Packages:DatabaseXPS:work_f
	Make/T/O/N=1 PeakName
	Make/O/N=1 PeakLayer,PeakCross,PeakMultiplier,PeakAsy,PeakKineticEnergy,PeakBindingEnergy,PeakTheoArea,PeakTheoAreaRatio,PeakLinks,PeakTheoNormRatio,PeakCode,PeakW,PeakGL
	
	STRUCT GeneralXPSParameterPrefs prefs
	LoadPackagePreferences kPackageName, kPreferencesFileName, kPreferencesRecordID, prefs
	If(V_flag!=0 || V_bytesRead==0 || prefs.version<110)	
		Print "Trouble while loading preferences. Please re-install the ILAMP package."
		Return -1
	Endif
	
	Make/O/N=0 dummy
	Try
		CalculateDDFxop /S=(prefs.IgorSerial) /M=0 dummy,dummy,dummy,dummy,dummy;abortOnRTE
	Catch
		Killwaves/Z dummy
		Return -2
	Endtry
	Killwaves/Z dummy
	
	Variable/G Accuracy = prefs.CompAccuracy
	variable i,j,k,EachLevelCount=0,CurrentLevelCount=0
	
	Controlinfo/W=ModelCalculationPanel SimulationTypeSelection
	Switch(V_value)
		Case 2:
			Variable/G LossMult=prefs.CompLossMult
		Break
		Case 3:
			If(ExpDataCheck!=2)
				wave ARXPS_ref_angle=root:Packages:DatabaseXPS:ValidatedModel:ARXPS_angle
				If(!WaveExists(ARXPS_ref_angle))
					Button RunSimulation,win=ModelCalculationPanel,disable=2
					return -4
				Endif
				variable ARXPS_iteration=numpnts(ARXPS_ref_angle)
				make/O/N=(ARXPS_iteration) ARXPS_angle
				ARXPS_angle[]=ARXPS_ref_angle[p]
				make/O/N=(1,ARXPS_iteration) PeakTheoArea,PeakTheoAreaRatio,PeakTheoNormRatio
			Else
				make/O/N=1 PeakTheoArea,PeakTheoAreaRatio,PeakTheoNormRatio
			Endif			
		Break
		Case 4://ED-XPS
			Controlinfo/W=ModelCalculationPanel CalcSetStartPhoton
			Variable startPh=V_value
			Controlinfo/W=ModelCalculationPanel CalcSetFinalPhoton
			Variable EndPh=V_value
			Controlinfo/W=ModelCalculationPanel CalcSetPhotonNum
			Variable PhStepNum=V_value
			Make/O/N=(PhStepNum) EDXPS_photon
			EDXPS_photon[]=startPh+(endPh-startPh)/(PhStepNum-1)*p
			Make/O/N=(1,PhStepNum) PeakTheoArea,PeakTheoAreaRatio,PeakTheoNormRatio
		Break
		case 5://Depth eching aux waves
			controlinfo/W=ModelCalculationPanel SimulationEtchRate
			variable LayerEtchRate=V_value
			controlinfo/W=ModelCalculationPanel SimulationEtchTime
			variable layerEtchTime=V_value,dummyVar
			wave thickness=root:Packages:DatabaseXPS:ValidatedModel:Thickness
			make/O/N=(numpnts(thickness),round(layerEtchTime/layerEtchRate)) LayerEtch_matrix
			make/O/N=(round(layerEtchTime/layerEtchRate)) Etching_Depth
			Etching_Depth[]=p*LayerEtchRate
			dummyVar=0
			for(i=0;i<dimsize(etching_depth,0);i+=1)				
				LayerEtch_matrix[][i] = p <= dummyVar ?  thickness[p]-Etching_Depth[i]: thickness[p]
				LayerEtch_matrix[][i] += p==dummyVar ? SumBrixias(thickness,dummyVar) : 0
				LayerEtch_matrix[][i] = LayerEtch_matrix[p][i] < 0 ? 0 : LayerEtch_matrix[p][i]
				if(LayerEtch_matrix[dummyVar][i] <=0  )
					dummyVar+=1
				endif
			endfor
			make/O/N=(1,numpnts(Etching_Depth)) PeakTheoArea,PeakTheoAreaRatio,PeakTheoNormRatio
		break
		case 6://Layer deposition aux wave
			controlinfo/W=ModelCalculationPanel SimulationDepositionRate
			variable LayerDepRate=V_value
			controlinfo/W=ModelCalculationPanel SimulationDepositionTime
			variable layerDepTime=V_value
			wave thickness=root:Packages:DatabaseXPS:ValidatedModel:Thickness
			make/O/N=(numpnts(thickness),round(layerDepTime/layerDepRate)) LayerDep_Thick
			make/O/N=(round(layerDepTime/layerDepRate)) Layer_Deposition_Thickness
			LayerDep_Thick[][]=thickness[p]
			LayerDep_Thick[0][]=q*LayerDepRate
			Layer_Deposition_Thickness[]=p*LayerDepRate
			make/O/N=(1,numpnts(layer_deposition_Thickness)) PeakTheoArea,PeakTheoAreaRatio,PeakTheoNormRatio
		break
	Endswitch
	
	
	string r_name,ref_name,link_name
	for(i=0;i<matnumber;i+=1)
		r_name="LineSelectorMat"+num2str(i)
		ref_name="LineSelectorMatSel"+num2str(i)
		link_name="IsLinked"+num2str(i)
		
		wave/T mat_line=root:Packages:DatabaseXPS:ValidatedModel:$r_name
		wave mat_sel=root:Packages:DatabaseXPS:ValidatedModel:$ref_name
		wave linklabel=root:Packages:DatabaseXPS:ValidatedModel:$link_name
		CurrentLevelCount=0
		for(j=0;j<dimsize(mat_line,0);j+=1)
			if(mat_sel[j][0]==48)
				CurrentLevelCount=1 		
				insertpoints 0,1,PeakName,peakCode
				insertpoints 0,1,PeakLayer,PeakCross,PeakMultiplier,PeakAsy,PeakKineticEnergy,PeakBindingEnergy,PeakTheoArea,PeakTheoAreaRatio,PeakLinks,PeakTheoNormRatio,peakW,peakGL
				PeakName[0]=mat_line[j][0][0]
				PeakCode[0]=str2num(mat_line[j][0][1])
				PeakLayer[0]=i
				PeakW[0]=str2num(mat_line[j][3][0])
				PeakGL[0]=str2num(mat_line[j][4][0])
				PeakCross[0]=str2num(mat_line[j][3][1])
				PeakAsy[0]=str2num(mat_line[j][4][1])
				PeakMultiplier[0]=str2num(mat_line[j][5][0])
				PeakBindingEnergy[0]=str2num(mat_line[j][1])+str2num(mat_line[j][2][0])
				PeakKineticEnergy[0]=photon_energy-work_f-PeakBindingEnergy[0]
				PeakLinks[0]=linklabel[j]
			endif
		endfor
		EachLevelCount+=CurrentLevelCount
	endfor
	Deletepoints/M=0  (numpnts(PeakName)-1),1,peakCode,PeakName,PeakLayer,PeakCross,PeakMultiplier,PeakAsy,PeakKineticEnergy,PeakBindingEnergy,PeakTheoArea,PeakTheoAreaRatio,PeakTheoNormRatio,PeakLinks,peakW,peakGL
	
	Variable currentlink,linksum,LinkposKE,linkPosBe,linkcross,linkedPeakNum
	String NameLinks="",LineLinks=""
	LinkedPeakNum=0
	If(expDataCheck==1) //create the form for the insertion of experimental data after linking the peaks, single calculation
		For(i=0;i<numpnts(PeakCross);i+=1)
			If( PeakLinks[i] != 0 )
				CurrentLink = PeakLinks[i]
				If (StringMatch ("",ListMatch( LineLinks, num2str(CurrentLink) ,";" )) == 1 )
					LineLinks+=num2str(CurrentLink)+";"
					NameLinks+=PeakName[i]+";"
				Endif
			Else
				NameLinks += PeakName[i]+";"
				LineLinks += "0;"
			Endif
		Endfor
		//For(i=0;i<numpnts(PeakCross);i+=1)  --------------------- OLD LINKER ------------------------ due to Gabry Problems ----------------------
		//	linksum=0
		//	If(PeakLinks[i]!=0)
		//		currentlink=PeakLinks[i]
		//		linkposKe=PeakKineticEnergy[i]*PeakCross[i]
		//		linkposBe=PeakBindingEnergy[i]*PeakCross[i]
		//		linkcross=PeakCross[i]
		//		For(j=i+1;j<numpnts(PeakCross);j+=1)		
		//			If(currentLink==peakLinks[j])
		//				linkcross+=PeakCross[j]
		//				linkposKe+=PeakKineticEnergy[j]*PeakCross[j]
		//				linkposBe+=PeakBindingEnergy[j]*PeakCross[j]	
		//				Deletepoints j,1,PeakName,PeakLayer,PeakCross,PeakMultiplier,PeakAsy,PeakKineticEnergy,PeakBindingEnergy,PeakTheoArea,PeakTheoAreaRatio,PeakLinks,PeakTheoNormRatio
		//				j-=1
		//			Endif
		//		Endfor
		//		PeakCross[i]=linkcross
		//		PeakKineticEnergy[i]=linkposKe/linkcross
		//		PeakBindingEnergy[i]=linkposBe/linkcross
		//	Endif
		//Endfor
		
		Make/T/O/N=(ItemsInList(NameLinks,";"),4,2) ExpDataInsertionMatrix
		Make/O/N=(ItemsInList(NameLinks,";"), 4) ExpDataInsertionMatrixSelector
		Make/T/O/N=4 ExpDataInsertionMatrixTitle
		ExpDataInsertionMatrix[][0]= StringFromList(p,NameLinks,";")
		ExpDataInsertionMatrixSelector[][0]=0
		ExpDataInsertionMatrix[][1]=num2str(0)
		ExpDataInsertionMatrixSelector[][1]=2
		ExpDataInsertionMatrix[][2]=num2str(0)
		ExpDataInsertionMatrixSelector[][2]=2
		For(j=0;j<ItemsInList(NameLinks,";");j+=1)
			If(str2num(StringFromList(j,LineLinks,";"))!=0)
				ExpDataInsertionMatrix[j][3][0]="Yes"
				ExpDataInsertionMatrix[j][3][1]=StringFromList(j,LineLinks,";")
			Else
				ExpDataInsertionMatrix[j][3][0]="No"
				ExpDataInsertionMatrix[j][3][1]="0"
			Endif
		Endfor
		ExpDataInsertionMatrixSelector[][3]=0
		ExpDataInsertionMatrixTitle[0]="XPS line"
		ExpDataInsertionMatrixTitle[1]="Exp. Area"
		ExpDataInsertionMatrixTitle[2]="Sigma"		
		ExpDataInsertionMatrixTitle[3]="Linked Peak?"
	Endif
	
	If(expDataCheck==2) //create the form for the insertion of experimental data after linking the peaks, ARXPS
		For(i=0;i<numpnts(PeakCross);i+=1)
			If( PeakLinks[i] != 0 )
				CurrentLink = PeakLinks[i]
				If (StringMatch ("",ListMatch( LineLinks, num2str(CurrentLink) ,";" )) == 1 )
					LineLinks+=num2str(CurrentLink)+";"
					NameLinks+=PeakName[i]+";"
				Endif
			Else
				NameLinks += PeakName[i]+";"
				LineLinks += "0;"
			Endif
		Endfor
		//For(i=0;i<numpnts(PeakCross);i+=1)
		//	linksum=0
		//	if(PeakLinks[i]!=0)
		//		currentlink=PeakLinks[i]
		//		linkposKe=PeakKineticEnergy[i]*PeakCross[i]
		//		linkposBe=PeakBindingEnergy[i]*PeakCross[i]
		//		linkcross=PeakCross[i]
		//		for(j=i+1;j<numpnts(PeakCross);j+=1)		
		//			if(currentLink==peakLinks[j])
		//				linkcross+=PeakCross[j]
		//				linkposKe+=PeakKineticEnergy[j]*PeakCross[j]
		//				linkposBe+=PeakBindingEnergy[j]*PeakCross[j]	
		//				deletepoints j,1,PeakName,PeakLayer,PeakCross,PeakMultiplier,PeakAsy,PeakKineticEnergy,PeakBindingEnergy,PeakTheoArea,PeakTheoAreaRatio,PeakLinks,PeakTheoNormRatio
		//				j-=1
		//			endif
		//		endfor
		//		PeakCross[i]=linkcross
		//		PeakKineticEnergy[i]=linkposKe/linkcross
		//		PeakBindingEnergy[i]=linkposBe/linkcross
		//	endif
		//Endfor
		String/G PeakLinksCode=LineLinks
		Make/T/O/N=(ItemsInList(NameLinks,";"),4,2) ExpDataInsertionMatrix
		Make/O/N=(ItemsInList(NameLinks,";"),4) ExpDataInsertionMatrixSelector
		Make/T/O/N=4 ExpDataInsertionMatrixTitle
		ExpDataInsertionMatrix[][0]=StringFromList(p,NameLinks,";")
		ExpDataInsertionMatrixSelector[][0]=0
		ExpDataInsertionMatrix[][1]=num2str(0)
		ExpDataInsertionMatrixSelector[][1]=0
		ExpDataInsertionMatrix[][2]=num2str(0)
		ExpDataInsertionMatrixSelector[][2]=0
		For(j=0;j<ItemsInList(NameLinks,";");j+=1)
			If(str2num(StringFromList(j,LineLinks,";"))!=0)
				ExpDataInsertionMatrix[j][3][0]="Yes"
				ExpDataInsertionMatrix[j][3][1]=StringFromList(j,LineLinks,";")
			Else
				ExpDataInsertionMatrix[j][3][0]="No"
				ExpDataInsertionMatrix[j][3][1]="0"
			Endif
		Endfor
		ExpDataInsertionMatrixSelector[][3]=0
		ExpDataInsertionMatrixTitle[0]="XPS line"
		ExpDataInsertionMatrixTitle[1]="Area wave"
		ExpDataInsertionMatrixTitle[2]="Angle wave"		
		ExpDataInsertionMatrixTitle[3]="Linked Peak?"
	Endif
	
	If(numpnts(peakName)==0)
		return -1
	Else
		If(EachLevelCount<matnumber)
			return -3
		Else
			return 0
		Endif
	Endif
End
static function SumBrixias(onda,num)
	wave onda
	variable num
	
	if(num==0)
		return 0
	else
		return sum(onda,0,num-1)
	endif
end

Function SimulationSelectUnselectButton(ctrlName) : ButtonControl
	String ctrlName
	NVAR matnumber=root:Packages:DatabaseXPS:ValidatedModel:LayerNumber
	variable i,j,setvalue
	
	string ref_name,ref_name_test="LineSelectorMatSel0"
	wave mat_sel=root:Packages:DatabaseXPS:ValidatedModel:$ref_name_test
	setvalue =  mat_sel[0][0]==48 ? 32 : 48
	
	for(i=0;i<matnumber;i+=1)
		ref_name="LineSelectorMatSel"+num2str(i)
		wave mat_sel=root:Packages:DatabaseXPS:ValidatedModel:$ref_name
		mat_sel[][0]=setvalue
	endfor
End
//------------------------------------------------duplicate selected line------------------------------------//
Function DuplicateSelectionButton(ctrlName) : ButtonControl
	String ctrlName
	CalcPanel_save_or_undo("SaveOperation")//backup
	NVAR matnumber=root:Packages:DatabaseXPS:ValidatedModel:LayerNumber
	variable i,j,selectedCell,selcounts=0
	string ref_name,set_name,link_name
	controlinfo/W=ModelCalculationPanel ModelTab
	
	ref_name="LineSelectorMat"+num2str(V_value)
	set_name="LineSelectorMatSel"+num2str(V_value)
	link_name="isLinked"+num2str(V_value)
	wave mat_sel=root:Packages:DatabaseXPS:ValidatedModel:$set_name
	wave/T mat_name=root:Packages:DatabaseXPS:ValidatedModel:$ref_name
	wave linkwave=root:Packages:DatabaseXPS:ValidatedModel:$link_name
	
	for(j=0;j<dimsize(mat_sel,0);j+=1)
		if(mat_sel[j][0]==48)
			selectedCell=j
			selcounts+=1
		endif
	endfor	
	
	if(selcounts!=1)
		doalert 0,"Please select one XPS line only."
		return -1
	endif
	
	variable split=1
	string new_line_name=mat_name[selectedCell][0][0]
	
	prompt split,"New vs old component ratio (1 is for an identical split):"
	prompt new_line_name, "Enter the new name for duplicated line"
	
	doprompt "New component name & ratio",new_line_name,split
	
	if(V_flag==1)
		return -1
	elseif(V_flag==0 && split<0)
		doalert 0,"Only positive values can be accepted for splitting."
		return -1
	endif
		
	insertpoints/M=0 selectedCell+1,1,mat_sel,mat_name,linkwave
	mat_sel[selectedCell+1][]=mat_sel[selectedCell][q]
	mat_name[selectedCell+1][][]= mat_name[selectedCell][q][r]
	mat_name[selectedCell+1][5][0]=num2str(split*str2num(mat_name[selectedCell][5][0]))
	linkwave[selectedCell+1]=0
	mat_name[selectedCell+1][0][0]=new_line_name
End
//------------------------------------------------linking peak func--------------------------------------------//
Function LinkingSelectionButton(ctrlName) : ButtonControl
	String ctrlName
	CalcPanel_save_or_undo("SaveOperation")//backup
	NVAR matnumber=root:Packages:DatabaseXPS:ValidatedModel:LayerNumber
	variable i,j,setvalue
	setvalue=0
	
	string ref_name,set_name,link_name
	variable selcounts=0
	
	for(i=0;i<matnumber;i+=1)
		set_name="LineSelectorMatSel"+num2str(i)
		wave mat_sel=root:Packages:DatabaseXPS:ValidatedModel:$set_name
			for(j=0;j<dimsize(mat_sel,0);j+=1)
			if(mat_sel[j][0]==48)
				selcounts+=1
			endif
		endfor	
	endfor
	
	if(selcounts<2)
		doalert 0,"Please select at least 2 lines "
		return 0
	endif
	
	string name_linked_group
	prompt name_linked_group, "Enter the new name for linked elements"
	doprompt "Linked group name:",name_linked_group
	
	if (V_Flag)
		return -1
	endif
			
	for(i=0;i<matnumber;i+=1)
		link_name="isLinked"+num2str(i)
		wave linkwave=root:Packages:DatabaseXPS:ValidatedModel:$link_name
		setvalue = wavemax(linkwave)>setvalue ? wavemax(linkwave) : setvalue
	endfor
	setvalue+=1
	
	for(i=0;i<matnumber;i+=1)
		ref_name="LineSelectorMat"+num2str(i)
		set_name="LineSelectorMatSel"+num2str(i)
		link_name="isLinked"+num2str(i)
		wave mat_sel=root:Packages:DatabaseXPS:ValidatedModel:$set_name
		wave/T mat_name=root:Packages:DatabaseXPS:ValidatedModel:$ref_name
		wave linkwave=root:Packages:DatabaseXPS:ValidatedModel:$link_name
		
		for(j=0;j<numpnts(linkwave);j+=1)
			if(mat_sel[j][0]==48)
				linkwave[j]=setvalue
				mat_name[j][0][0]+="-"+name_linked_group
			endif
		endfor		
	endfor
End
///-------------------------close energy pair linker----------------------------------
Function LinkingClosePairButton(ctrlName) : ButtonControl
	String ctrlName
	CalcPanel_save_or_undo("SaveOperation")//backup
	NVAR matnumber=root:Packages:DatabaseXPS:ValidatedModel:LayerNumber
	variable i,j,k,l,setvalue
	setvalue=0
	
	string ref_name,set_name,link_name,copy_name
	variable selcounts=0
	variable currentBE,compBE,currentLink,PairFound=0,newPairFound=0,threshold=2
	variable onlyCurrentTab=1
	controlinfo/W=ModelCalculationPanel ModelTab
	Variable CurrentTab=V_value
	
	prompt threshold,"Plese define the peak distance (eV)"
	prompt onlyCurrentTab,"Auto joiner range:",popup,"current layer;every layer;"
	doprompt "Automatic close peaks join...",threshold,onlyCurrentTab
	if(V_flag==1)
		return -1
	elseif(V_flag==0 && threshold <0)
		doAlert 0,"Only a positive energy value can be accepted as valid peak distance."
		return -1
	endif
	DFREF backupFolder=GetDataFolderDFR()
	SetDataFolder root:Packages:DatabaseXPS:ValidatedModel
	
	for(i=0;i<matnumber;i+=1)
		link_name="isLinked"+num2str(i)
		copy_name=Link_name+"_TMP"
		wave linkwave=root:Packages:DatabaseXPS:ValidatedModel:$link_name
		setvalue = wavemax(linkwave)>setvalue ? wavemax(linkwave) : setvalue
		duplicate/O linkwave $copy_name
		wave CopyLink=:$copy_name
		CopyLink=0
	endfor
	setvalue+=1
	
	for(i=0;i<matnumber;i+=1)
		i=onlyCurrentTab==1 ? CurrentTab : i
		ref_name="LineSelectorMat"+num2str(i)
		link_name="isLinked"+num2str(i)
		copy_name=link_name+"_TMP"
		wave/T mat_name=root:Packages:DatabaseXPS:ValidatedModel:$ref_name
		wave linkwave=root:Packages:DatabaseXPS:ValidatedModel:$link_name
		wave copyLink=:$copy_name
		
		for(j=0;j<numpnts(linkwave);j+=1)
			if(NewPairFound)
				linkwave[j-1]=setValue
				CopyLink[j-1]=1
				newPairFound=0
				setValue+=1		
			endif
			PairFound=0
			currentBE=str2num(Mat_Name[j][1][0])+str2num(Mat_Name[j][2][0])
			currentLink=linkwave[j]
					
			for(k=0;k<matnumber;k+=1)
				k=onlyCurrentTab==1 ? CurrentTab : k
				ref_name="LineSelectorMat"+num2str(k)
				link_name="isLinked"+num2str(k)
				copy_name=link_name+"_TMP"
				wave/T mat_Rname=root:Packages:DatabaseXPS:ValidatedModel:$ref_name
				wave linkwaveR=root:Packages:DatabaseXPS:ValidatedModel:$link_name
				wave copyLinkR=:$copy_name
				for(l=0;l<numpnts(linkwaveR);l+=1)
					compBE=str2num(Mat_RName[l][1][0])+str2num(Mat_RName[l][2][0])
					if((currentLink==linkwaveR[l] && currentLink!=0 ) || (abs(currentBE-compBE)<threshold && !(l== j && k==i)))
						PairFound=1
						linkwaveR[l]=1000
						copyLinkR[l]=1
					endif	
				endfor
				if(onlyCurrentTab==1)
					break;
				endif	
			endfor
			newPairFound=PairFound
			if(NewPairFound)
				for(k=0;k<matnumber;k+=1)
					k=onlyCurrentTab==1 ? CurrentTab : k
					link_name="isLinked"+num2str(k)
					wave linkwaveR=root:Packages:DatabaseXPS:ValidatedModel:$link_name
					for(l=0;l<numpnts(linkwaveR);l+=1)
						if(linkwaveR[l]==1000)		
							linkwaveR[l]=setValue
						endif	
					endfor		
					if(onlyCurrentTab==1)
						break;
					endif
				endfor		
			endif
		endfor
		if(onlyCurrentTab==1)
			break;
		endif
	endfor
	//Linker normalization
	for(i=0;i<matnumber;i+=1)
		link_name="isLinked"+num2str(i)
		wave linkwave=root:Packages:DatabaseXPS:ValidatedModel:$link_name
		for(j=0;j<numpnts(linkwave);j+=1)
			if(linkwave[j]>0)
				setvalue= linkwave[j]<setvalue ? linkwave[j] : setvalue
			endif
		endfor
	endfor
	Setvalue-=1
	for(i=0;i<matnumber;i+=1)
		link_name="isLinked"+num2str(i)
		wave linkwave=root:Packages:DatabaseXPS:ValidatedModel:$link_name
		linkwave[]-= linkwave[p]!=0 ? setvalue : 0
	endfor
	//Name adjuster post-processing
	for(i=0;i<matnumber;i+=1)
		ref_name="LineSelectorMat"+num2str(i)
		link_name="isLinked"+num2str(i)
		copy_name=link_name+"_TMP"
		wave/T mat_name=root:Packages:DatabaseXPS:ValidatedModel:$ref_name
		wave linkwave=root:Packages:DatabaseXPS:ValidatedModel:$link_name
		wave copyLink=:$copy_name
		for(j=0;j<numpnts(linkwave);j+=1)
			if(copylink[j]==1)
				mat_name[j][0][0]+="-AL"+num2str(linkwave[j])
			endif	
		endfor
	endfor
	//kill Link copy for naming convention
	for(i=0;i<matnumber;i+=1)
		link_name="isLinked"+num2str(i)
		copy_name=Link_name+"_TMP"
		wave CopyLink=:$copy_name
		killwaves/Z copyLink
	endfor
	setdataFolder BackupFolder		
End
///------------------------------------------------------------------------------------------------Simulation Main Functions!!!-----------------------------------------------------///
Function SimulateSingleCalculation(theory)
	variable theory
	WAVE angleE=root:Packages:DatabaseXPS:Analyzer:vecOut
	NVAR pol=root:Packages:DatabaseXPS:Analyzer:Polarization_type
	NVAR acceptance=root:Packages:DatabaseXPS:Analyzer:Acceptance
	NVAR island_area=root:Packages:DatabaseXPS:ValidatedModel:Island_area
	NVAR island_depth=root:Packages:DatabaseXPS:ValidatedModel:Island_depth
	NVAR matnumber=root:Packages:DatabaseXPS:ValidatedModel:LayerNumber
	NVAR roughness=root:Packages:DatabaseXPS:ValidatedModel:Roughness
	WAVE IMFP_mat=root:Packages:DatabaseXPS:ValidatedModel:IMFP_Matrix
	WAVE thickness=root:Packages:DatabaseXPS:ValidatedModel:Thickness
	NVAR accuracy=:accuracy

	variable i,j,k,numlines
	string aux1,aux2
	
	if(pol==1)
		Wave AngleHnu=root:Packages:DatabaseXPS:Analyzer:vecIn
	else
		Wave AngleHnu=root:Packages:DatabaseXPS:Analyzer:vecPol
	endif
	
	wave PeakLayer,PeakCross,PeakMultiplier,PeakAsy,PeakKineticEnergy,PeakBindingEnergy,PeakTheoArea,PeakTheoAreaRatio,PeakLinks,PeakTheoNormRatio,PeakW,PeakGL
	wave/T PeakName
	
	make/O/N=(matnumber) W_IMFP,W_TMFP
	numlines=numpnts(PeakName)
	
	ValDisplay SimulationProgressBar,win=ModelCalculationPanel ,value=_NUM:0
	DoUpdate /W=ProgressPanel
	
	for(i=0;i<numlines;i+=1)///---------------------Main calculation cycle--------------------------------------------------////
		W_IMFP[]=IMFP(IMFP_mat[0][p],IMFP_mat[1][p],IMFP_mat[2][p],IMFP_mat[3][p],PeakKineticEnergy[i])
		for(k=0;k<matnumber;k+=1)
			aux1="TMFP_Parameter_Layer_"+num2str(k)
			wave TMFP_param=root:Packages:DatabaseXPS:ValidatedModel:$aux1
			W_TMFP[k]=TMFP(TMFP_param,IMFP_mat[2][k],PeakKineticEnergy[i])
		endfor
		W_TMFP[]=W_IMFP[p]>W_TMFP[p] ? W_IMFP[p] + 0.01 : W_TMFP[p]
		
		if(pol==1)
			CalculateXPSAreaXop/A=(PeakAsy[i]) /T=(accuracy) /M=(theory) /K=(acceptance) /R=(roughness) /I={Island_area,Island_depth} W_IMFP,W_TMFP,thickness,AngleE,AngleHnu
		else
			CalculateXPSAreaXop/A=(PeakAsy[i]) /T=(accuracy) /M=(theory) /K=(acceptance) /P /R=(roughness) /I={Island_area,Island_depth} W_IMFP,W_TMFP,thickness,AngleE,AngleHnu
		endif
		wave W_Results
		
		PeakTheoArea[i]=peakMultiplier[i]*PeakCross[i]*W_Results[peakLayer[i]]
		ValDisplay SimulationProgressBar,win=ModelCalculationPanel ,value=_NUM:(i/numlines)
		DoUpdate /W=ProgressPanel
	endfor
	ValDisplay SimulationProgressBar,win=ModelCalculationPanel ,value=_NUM:(i/numlines)
	DoUpdate /W=ProgressPanel
	//---------------------------------------------------------Summing linked peaks--------------------------------------------------
	variable currentlink,linksum,LinkposKE,linkPosBe,linkcross
	
	for(i=0;i<numpnts(PeakCross);i+=1)
		linksum=0
		if(PeakLinks[i]!=0)
			currentlink=PeakLinks[i]
			linksum=PeakTheoArea[i]
			linkposKe=PeakKineticEnergy[i]*PeakTheoArea[i]
			linkposBe=PeakBindingEnergy[i]*PeakTheoArea[i]
			linkcross=PeakCross[i]
			for(j=i+1;j<numpnts(PeakCross);j+=1)		
				if(currentLink==peakLinks[j])
					linksum+=PeakTheoArea[j]
					linkcross+=PeakCross[j]
					linkposKe+=PeakKineticEnergy[j]*PeakTheoArea[j]
					linkposBe+=PeakBindingEnergy[j]*PeakTheoArea[j]	
					deletepoints j,1,PeakName,PeakLayer,PeakCross,PeakMultiplier,PeakAsy,PeakKineticEnergy,PeakBindingEnergy,PeakTheoArea,PeakTheoAreaRatio,PeakLinks,PeakTheoNormRatio,peakW,peakGL
					j-=1
				endif
			endfor
			PeakTheoArea[i]=linkSum
			PeakCross[i]=linkcross
			PeakKineticEnergy[i]=linkposKe>0 && linksum>0 ? linkposKe/linksum : PeakKineticEnergy[i]
			PeakBindingEnergy[i]=linkposBe> 0 && linksum>0 ? linkposBe/linksum : PeakBindingEnergy[i]
		endif
	endfor
	
	//---------------------------------------------------------Normalized results---------------------------------------------///
	variable total_sum=sum(PeakTheoArea)
	PeakTheoAreaRatio[]=PeakTheoArea[p]/total_sum
	PeakTheoNormRatio[]=PeakTheoArea[p]/PeakCross[p]
	
	total_sum=sum(PeakTheoNormRatio)
	PeakTheoNormRatio[]=PeakTheoNormRatio[p]/total_sum
end
//--------------------------------------------------------------------------------------Simulate full spectra------------------------------------------------------------------------
Function SimulateFullSpectraCalculation(tou_type,rebuild)
	variable tou_type,rebuild
	WAVE angleE=root:Packages:DatabaseXPS:Analyzer:vecOut
	NVAR pol=root:Packages:DatabaseXPS:Analyzer:Polarization_type
	NVAR acceptance=root:Packages:DatabaseXPS:Analyzer:Acceptance
	NVAR island_area=root:Packages:DatabaseXPS:ValidatedModel:Island_area
	NVAR island_depth=root:Packages:DatabaseXPS:ValidatedModel:Island_depth
	NVAR matnumber=root:Packages:DatabaseXPS:ValidatedModel:LayerNumber
	NVAR roughness=root:Packages:DatabaseXPS:ValidatedModel:Roughness
	WAVE IMFP_mat=root:Packages:DatabaseXPS:ValidatedModel:IMFP_Matrix
	WAVE thickness=root:Packages:DatabaseXPS:ValidatedModel:Thickness
	NVAR accuracy=:accuracy
	
	variable i,j,k,numlines
	string aux1,aux2
	
	if(pol==1)
		Wave AngleHnu=root:Packages:DatabaseXPS:Analyzer:vecIn
	else
		Wave AngleHnu=root:Packages:DatabaseXPS:Analyzer:vecPol
	endif
	
	wave PeakLayer,PeakCross,PeakMultiplier,PeakAsy,PeakKineticEnergy,PeakBindingEnergy,PeakTheoArea,PeakTheoAreaRatio,PeakLinks,PeakTheoNormRatio,peakW,peakGL
	wave/T PeakName
	make/O/N=(matnumber) W_IMFP,W_TMFP
	numlines=numpnts(PeakName)
	make/O/N=(numlines,15) MultipleScatteringMat
	
	ValDisplay SimulationProgressBar,win=ModelCalculationPanel ,value=_NUM:0
	DoUpdate /W=ProgressPanel
	variable warning=0
	for(i=0;i<numlines;i+=1)///-------------------------------------------------------Main calculation cycle---------------------------------------------------------------////
		warning=0
		W_IMFP[]=IMFP(IMFP_mat[0][p],IMFP_mat[1][p],IMFP_mat[2][p],IMFP_mat[3][p],PeakKineticEnergy[i])
		for(k=0;k<matnumber;k+=1)
			aux1="TMFP_Parameter_Layer_"+num2str(k)
			wave TMFP_param=root:Packages:DatabaseXPS:ValidatedModel:$aux1
			W_TMFP[k]=TMFP(TMFP_param,IMFP_mat[2][k],PeakKineticEnergy[i])
			if(W_TMFP[k]<W_IMFP[k])
				warning=1
				Print "Impossible to calcolate line n°:",i,". Too low kinetic energy."
			endif
		endfor
		
		if(!warning)
			if(pol==1)
				CalculateXPSAreaMSXop/A=(PeakAsy[i]) /T=(accuracy) /K=(acceptance) /R=(roughness) /I={Island_area,Island_depth} W_IMFP,W_TMFP,thickness,AngleE,AngleHnu
			else
				CalculateXPSAreaMSXop/A=(PeakAsy[i]) /T=(accuracy) /K=(acceptance) /P /R=(roughness) /I={Island_area,Island_depth} W_IMFP,W_TMFP,thickness,AngleE,AngleHnu
			endif
		
			wave W_Results
			PeakTheoArea[i]=peakMultiplier[i]*PeakCross[i]*W_Results[peakLayer[i]][0]
			MultipleScatteringMat[i][]=peakMultiplier[i]*PeakCross[i]*W_Results[peakLayer[i]][q]
		else
			PeakTheoArea[i]=0
			MultipleScatteringMat[i][]=0
			
		endif
		ValDisplay SimulationProgressBar,win=ModelCalculationPanel ,value=_NUM:(i/numlines)
		DoUpdate /W=ProgressPanel
	endfor
	ValDisplay SimulationProgressBar,win=ModelCalculationPanel ,value=_NUM:(i/numlines)
	DoUpdate /W=ProgressPanel
	//---------------------------------------------------------Summing linked peaks--------------------------------------------------
	variable currentlink,linksum,LinkposKE,linkPosBe,linkcross
	make/N=15 tempLinkSum
	for(i=0;i<numpnts(PeakCross);i+=1)
		linksum=0
		if(PeakLinks[i]!=0)
			currentlink=PeakLinks[i]
			linksum=PeakTheoArea[i]
			linkposKe=PeakKineticEnergy[i]*PeakTheoArea[i]
			linkposBe=PeakBindingEnergy[i]*PeakTheoArea[i]
			linkcross=PeakCross[i]
			tempLinkSum[]=MultipleScatteringMat[i][p]
			for(j=i+1;j<numpnts(PeakCross);j+=1)		
				if(currentLink==peakLinks[j])
					linksum+=PeakTheoArea[j]
					linkcross+=PeakCross[j]
					linkposKe+=PeakKineticEnergy[j]*PeakTheoArea[j]
					linkposBe+=PeakBindingEnergy[j]*PeakTheoArea[j]
					tempLinkSum[]=tempLinkSum[p]+MultipleScatteringMat[j][p]	
					deletepoints j,1,PeakName,PeakLayer,PeakCross,PeakMultiplier,PeakAsy,PeakKineticEnergy,PeakBindingEnergy,PeakTheoArea,PeakTheoAreaRatio,PeakLinks,PeakTheoNormRatio,peakW,peakGL
					deletepoints j,1,MultipleScatteringMat
					j-=1
				endif
			endfor
			PeakTheoArea[i]=linkSum
			PeakCross[i]=linkcross
			PeakKineticEnergy[i]=linkposKe>0 && linksum>0 ? linkposKe/linksum : PeakKineticEnergy[i]
			PeakBindingEnergy[i]=linkposBe> 0 && linksum>0 ? linkposBe/linksum : PeakBindingEnergy[i]
			MultipleScatteringMat[i][]=tempLinkSum[q]
		endif
	endfor
	killwaves tempLinkSum
//---------------------------------------------------------Normalized results---------------------------------------------///
	variable total_sum=sum(PeakTheoArea)
	PeakTheoAreaRatio[]=PeakTheoArea[p]/total_sum
	PeakTheoNormRatio[]=PeakTheoArea[p]/PeakCross[p]
	
	total_sum=sum(PeakTheoNormRatio)
	PeakTheoNormRatio[]=PeakTheoNormRatio[p]/total_sum
	generate_loss_func(tou_type,rebuild)
	
	//--------Edit--------making Broadened_Full_Spectra-----//
	
	NVAR lossMult=:lossMult
//	ControlInfo/W=ModelCalculationPanel SimulationFullSpecNumpnts
	make/O/N=(2000) Broadened_Full_Spectra=0
	wavestats/Q PeakKineticEnergy
	setscale/I x,(V_min-300),(V_max+250),"Kinetic Energy (eV)",Broadened_Full_Spectra //Changed lims from v-120, v+50
	broadVoigtSpectra(PeakKineticEnergy,PeakTheoArea,PeakW,PeakGL,broadened_Full_Spectra)
	for(i=0;i<numpnts(peakName);i+=1)
		for(j=1;j<15;j+=1)
			Broadened_Full_spectra[]+=lossMult*5*interp2D(LossSpectraMat,pnt2x(Broadened_Full_spectra,p)+1500-PeakKineticEnergy[i],j)*MultipleScatteringMat[i][j]
		endfor	
	endfor
	Broadened_Full_Spectra*=5	
end
//------------------------------------------------------generating the loss function--------------------------------------
function generate_loss_func(tou_type,rebuild)
	variable tou_type,rebuild
	variable i,j
	string nome1,nome2
	if(waveexists(:LossSpectraMat)!=1 || rebuild==1 )
		make/D/O/N=(3000,15) LossSpectraMat
		if(tou_type==8)
			NVAR B=root:Packages:DatabaseXPS:TouVars:Btou
			NVAR C=root:Packages:DatabaseXPS:TouVars:Ctou
			NVAR D=root:Packages:DatabaseXPS:TouVars:Dtou
			NVAR MainPWidth=root:Packages:DatabaseXPS:TouVars:MPWtou
			NVAR gap=root:Packages:DatabaseXPS:TouVars:Gaptou
//			variable B=3286,C=1643,D=1,MainPWidth=1.5,Gap=0
//			Prompt B, "B: "				
//			Prompt C, "C: "
//			Prompt D, "D: "
//			Prompt Gap,"Gap: "
//			Prompt MainPWidth, "Elastic peak width:  " 
//			DoPrompt "3 Parameter Tougaard cross section", B,C,D,Gap,MainPWidth
//			if (V_Flag)
//				wave SavedLossMat=root:Packages:DatabaseXPS:AuxData:DefaultLossSpectraMat
//				lossSpectraMat[][]=SavedLossMat[p][q][0]
//				return -1								// User canceled
//			endif
			make/O/N=3000 test0,test1,test2,test3,test4,test5,test6,test7,test8,test9,test10,test11,test12,test13,test14
			test0[]=Gauss(p,1500,MainPWidth)
			duplicate/O test0 temp
			j=0
			LossSpectraMat[][0]=temp[p]
			do
				nome1="test"+num2str(j)
				nome2="test"+num2str(j+1)
				i=0
				do 
					wave w1 = $nome1
					wave w2 = $nome2
					temp[]=B*p/((C+(p-gap)^2)^2+(p-gap)^2*D)*w1[p+i]
					w2[i]=area(temp)
					i+=1
				while(i<3000)
				i=area(w2)
				w2/=i
				LossSpectraMat[][j+1]=w2[p]
				j+=1
			while(j<14)
			killwaves test0,test1,test2,test3,test4,test5,test6,test7,test8,test9,test10,test11,test12,test13,test14,temp
		else
			wave SavedLossMat=root:Packages:DatabaseXPS:AuxData:DefaultLossSpectraMat
			lossSpectraMat[][]=SavedLossMat[p-3][q][tou_type-1]
		endif
	endif
end


//-------------------------------------------------------------------------ARXPS main function----------------------------------------------------------------------------
Function SimulateARXPSCalculation(theory)
	variable theory
	WAVE anglematrix=root:Packages:DatabaseXPS:ValidatedModel:ARXPS_Versor
	NVAR pol=root:Packages:DatabaseXPS:Analyzer:Polarization_type
	NVAR acceptance=root:Packages:DatabaseXPS:Analyzer:Acceptance
	NVAR island_area=root:Packages:DatabaseXPS:ValidatedModel:Island_area
	NVAR island_depth=root:Packages:DatabaseXPS:ValidatedModel:Island_depth
	NVAR matnumber=root:Packages:DatabaseXPS:ValidatedModel:LayerNumber
	NVAR roughness=root:Packages:DatabaseXPS:ValidatedModel:Roughness
	WAVE IMFP_mat=root:Packages:DatabaseXPS:ValidatedModel:IMFP_Matrix
	WAVE thickness=root:Packages:DatabaseXPS:ValidatedModel:Thickness
	SVAR angleName=root:Packages:DatabaseXPS:ValidatedModel:ARXPS_type
	NVAR accuracy=:accuracy
	
	variable i,j,k,numlines,numangles,angle
	string aux1,aux2
	
	wave PeakLayer,PeakCross,PeakMultiplier,PeakAsy,PeakKineticEnergy,PeakBindingEnergy,PeakTheoArea,PeakTheoAreaRatio,PeakLinks,PeakTheoNormRatio,peakW,peakGL
	wave/T PeakName
	wave ARXPS_angle
	
	make/O/N=(matnumber) W_IMFP,W_TMFP
	make/O/N=3 angleE,angleHnu
	
	numlines=numpnts(PeakName)
	numangles=numpnts(ARXPS_angle)
	ValDisplay SimulationProgressBar,win=ModelCalculationPanel ,value=_NUM:(0)
	DoUpdate /W=ProgressPanel
	for(angle=0;angle<numangles;angle+=1)
	
		angleE[]=anglematrix[angle][p]
		angleHnu[]=anglematrix[angle][p+3]
		
		for(i=0;i<numlines;i+=1)///---------------------Main calculation cycle--------------------------------------------------////
			W_IMFP[]=IMFP(IMFP_mat[0][p],IMFP_mat[1][p],IMFP_mat[2][p],IMFP_mat[3][p],PeakKineticEnergy[i])
			for(k=0;k<matnumber;k+=1)
				aux1="TMFP_Parameter_Layer_"+num2str(k)
				wave TMFP_param=root:Packages:DatabaseXPS:ValidatedModel:$aux1
				W_TMFP[k]=TMFP(TMFP_param,IMFP_mat[2][k],PeakKineticEnergy[i])
			endfor
			W_TMFP[]=W_IMFP[p]>W_TMFP[p] ? W_IMFP[p] + 0.01 : W_TMFP[p]
			if(pol==1)
				CalculateXPSAreaXop/A=(PeakAsy[i]) /T=(accuracy) /M=(theory) /K=(acceptance) /R=(roughness) /I={Island_area,Island_depth} W_IMFP,W_TMFP,thickness,AngleE,AngleHnu
			else
				CalculateXPSAreaXop/A=(PeakAsy[i]) /T=(accuracy) /M=(theory) /K=(acceptance) /P /R=(roughness) /I={Island_area,Island_depth} W_IMFP,W_TMFP,thickness,AngleE,AngleHnu
			endif
			wave/D W_Results
			PeakTheoArea[i][angle]=peakMultiplier[i]*PeakCross[i]*W_Results[peakLayer[i]]
			endfor
	ValDisplay SimulationProgressBar,win=ModelCalculationPanel ,value=_NUM:(angle/numangles)
	DoUpdate /W=ProgressPanel
	
	endfor
	ValDisplay SimulationProgressBar,win=ModelCalculationPanel ,value=_NUM:(angle/numangles)
	DoUpdate /W=ProgressPanel
	//---------------------------------------------------------Summing linked peaks--------------------------------------------------
	variable currentlink,LinkposKE,linkPosBe,linkcross
	make/O/N=(numangles) linksum
	
	for(i=0;i<numpnts(PeakCross);i+=1)
		linksum=0
		if(PeakLinks[i]!=0)
			currentlink=PeakLinks[i]
				linkcross=PeakCross[i]
				linksum[]=PeakTheoArea[i][p]
				linkposKe=PeakKineticEnergy[i]*PeakTheoArea[i]
				linkposBe=PeakBindingEnergy[i]*PeakTheoArea[i]
				for(j=i+1;j<numpnts(PeakCross);j+=1)		
					if(currentLink==peakLinks[j])
					linkcross+=peakCross[j]
						linksum[]+=PeakTheoArea[j][p]
						linkposKe+=PeakKineticEnergy[j]*PeakTheoArea[j]
						linkposBe+=PeakBindingEnergy[j]*PeakTheoArea[j]	
						deletepoints j,1,PeakName,PeakLayer,PeakCross,PeakMultiplier,PeakAsy,PeakKineticEnergy,PeakBindingEnergy,PeakTheoArea,PeakTheoAreaRatio,PeakLinks,PeakTheoNormRatio,peakW,peakGL
						j-=1
					endif
				endfor
				PeakCross[i]=linkcross
				PeakTheoArea[i][]=linkSum[q]
				PeakKineticEnergy[i]=linkposKe>0 && linksum[0]>0 ? linkposKe/linksum[0] : PeakKineticEnergy[i]
				PeakBindingEnergy[i]=linkposBe> 0 && linksum[0]>0 ? linkposBe/linksum[0] : PeakBindingEnergy[i]
		endif
	endfor
	duplicate/O linksum,total_sum
	total_sum=0
	//---------------------------------------------------------Normalized results---------------------------------------------//
	For(i=0;i<Dimsize(PeakCross,0);i+=1)
		total_sum[]+=PeakTheoArea[i][p]
	Endfor
	
	PeakTheoAreaRatio[][]=PeakTheoArea[p][q]/total_sum[q]
	PeakTheoNormRatio[][]=PeakTheoArea[p][q]/PeakCross[p]
	
	for(i=0;i<i<Dimsize(PeakCross,0);i+=1)
		total_sum[]+=PeakTheoNormRatio[i][p]
	endfor
	PeakTheoNormRatio[][]=PeakTheoNormRatio[p][q]/total_sum[q]
	//--------------------------------------------------------Single Spectra----------------------------------------------------//
	Newdatafolder/O/S SingleSpectra
	string running_name,final_name
	For(i=0;i<numpnts(PeakName);i+=1)
		running_name="Peak_"+num2str(i)+"Area"
		make/O/N=(numangles) $running_name
		Wave SingleAreaWave=$running_name
		
		running_name="Peak_"+num2str(i)+"Area_Ratio"
		make/O/N=(numangles) $running_name
		Wave SingleAreaRatioWave=$running_name
		
		running_name="Peak_"+num2str(i)+"Normalized_Area"
		make/O/N=(numangles) $running_name
		Wave SingleAreaNormWave=$running_name
		
		SingleAreaWave[]=PeakTheoArea[i][p]
		SingleAreaRatioWave[]=PeakTheoAreaRatio[i][p]
		SingleAreaNormWave[]=PeakTheoNormRatio[i][p]
	Endfor
	//-----------------------------------------------------Rename single spectra-------------------------------------------//
	For(i=0;i<numpnts(PeakName);i+=1)
		running_name="Peak_"+num2str(i)+"Area"
		Wave SingleAreaWave=$running_name
		running_name="Peak_"+num2str(i)+"Area_Ratio"
		Wave SingleAreaRatioWave=$running_name
		running_name="Peak_"+num2str(i)+"Normalized_Area"
		Wave SingleAreaNormWave=$running_name
		
		final_name=Peakname[i]+" A"
		duplicate/O singleAreaWave,$final_name
		killwaves singleAreaWave
		
		final_name=Peakname[i]+" AR"
		duplicate/O singleAreaRatioWave,$final_name
		killwaves singleAreaRatioWave
		final_name=Peakname[i]+" NAR"
		duplicate/O SingleAreaNormWave,$final_name
		killwaves singleAreaNormWave
	Endfor
	setdatafolder ::
	duplicate/O ARXPS_angle,$angleName
	killwaves ARXPS_angle
	killwaves total_sum,linksum,angleE,angleHnu,W_imfp,W_tmfp
end
//------------------------------
Function SimulateDepEtchCalculation(theory)
	variable theory

	WAVE angleE=root:Packages:DatabaseXPS:Analyzer:vecOut
	NVAR pol=root:Packages:DatabaseXPS:Analyzer:Polarization_type
	NVAR acceptance=root:Packages:DatabaseXPS:Analyzer:Acceptance
	NVAR island_area=root:Packages:DatabaseXPS:ValidatedModel:Island_area
	NVAR island_depth=root:Packages:DatabaseXPS:ValidatedModel:Island_depth
	NVAR matnumber=root:Packages:DatabaseXPS:ValidatedModel:LayerNumber
	NVAR roughness=root:Packages:DatabaseXPS:ValidatedModel:Roughness
	WAVE IMFP_mat=root:Packages:DatabaseXPS:ValidatedModel:IMFP_Matrix
	WAVE ThickMat=:LayerEtch_matrix
	WAVE EtchDepth=:Etching_Depth
	NVAR accuracy=:accuracy
	If(pol==1)
		Wave AngleHnu=root:Packages:DatabaseXPS:Analyzer:vecIn
	else
		Wave AngleHnu=root:Packages:DatabaseXPS:Analyzer:vecPol
	endif
	
	string aux1,aux2
	
	wave PeakLayer,PeakCross,PeakMultiplier,PeakAsy,PeakKineticEnergy,PeakBindingEnergy,PeakTheoArea,PeakTheoAreaRatio,PeakLinks,PeakTheoNormRatio,peakW,peakGL
	wave/T PeakName
	variable currentDepthIndex,CurrentIsArea,CurrentIsDepth,layerShift,numlines,numetch	,i,j,k
	numlines=numpnts(PeakName)
	numEtch=numpnts(EtchDepth)
		
	ValDisplay SimulationProgressBar,win=ModelCalculationPanel ,value=_NUM:(0)
	DoUpdate /W=ProgressPanel
	Make/O/N=(matnumber-1) thickness
	Make/O/N=(matnumber) W_IMFP,W_TMFP
	
	For(currentDepthIndex=0;currentDepthIndex<numEtch;currentDepthIndex+=1)
		thickness[]=thickmat[p][currentDepthIndex]
		CurrentIsDepth=island_depth-etchDepth[currentDepthIndex]
		currentIsArea=Island_area
		If(CurrentIsDepth<0)
			CurrentIsDepth=0
			CurrentIsArea=1
		endif	
		
		layerShift=0
		for(i=0;i<matnumber-1;i+=1)
			if(thickness[i]==0)
				layershift+=1
			else
				break
			endif
		endfor
		for(i=0;i<numlines;i+=1)///---------------------Main calculation cycle--------------------------------------------------////
			if(peakLayer[i]>=layerShift)
				W_IMFP[]=IMFP(IMFP_mat[0][p],IMFP_mat[1][p],IMFP_mat[2][p],IMFP_mat[3][p],PeakKineticEnergy[i])
				
				for(k=0;k<matnumber;k+=1)
					aux1="TMFP_Parameter_Layer_"+num2str(k)
					wave TMFP_param=root:Packages:DatabaseXPS:ValidatedModel:$aux1
					W_TMFP[k]=TMFP(TMFP_param,IMFP_mat[2][k],PeakKineticEnergy[i])
				endfor
				W_TMFP[]=W_IMFP[p]>W_TMFP[p] ? W_IMFP[p] + 0.01 : W_TMFP[p]
				
				if(pol==1)
					CalculateXPSAreaXop/A=(PeakAsy[i]) /T=(accuracy) /M=(theory) /K=(acceptance) /I={currentIsArea,Currentisdepth} W_IMFP,W_TMFP,Thickness,AngleE,AngleHnu
				else
					CalculateXPSAreaXop/A=(PeakAsy[i]) /T=(accuracy) /M=(theory) /K=(acceptance) /P /I={currentIsArea,Currentisdepth} W_IMFP,W_TMFP,Thickness,AngleE,AngleHnu
				endif
				wave W_Results
				PeakTheoArea[i][currentDepthIndex]=peakMultiplier[i]*PeakCross[i]*W_Results[peakLayer[i]]
			else
				PeakTheoArea[i][currentDepthIndex]=0
			endif
		endfor
		ValDisplay SimulationProgressBar,win=ModelCalculationPanel ,value=_NUM:(currentDepthIndex/numEtch)
		DoUpdate /W=ProgressPanel
	endfor
	ValDisplay SimulationProgressBar,win=ModelCalculationPanel ,value=_NUM:(currentDepthIndex/numEtch)
	DoUpdate /W=ProgressPanel
	
	//---------------------------------------------------------Summing linked peaks--------------------------------------------------
	variable currentlink,LinkposKE,linkPosBe,linkcross
	make/O/N=(numEtch) linksum
	
	for(i=0;i<numpnts(PeakCross);i+=1)
		linksum=0
		if(PeakLinks[i]!=0)
			currentlink=PeakLinks[i]
				linkcross=PeakCross[i]
				linksum[]=PeakTheoArea[i][p]
				linkposKe=PeakKineticEnergy[i]*PeakTheoArea[i]
				linkposBe=PeakBindingEnergy[i]*PeakTheoArea[i]
				for(j=i+1;j<numpnts(PeakCross);j+=1)		
					if(currentLink==peakLinks[j])
					linkcross+=peakCross[j]
						linksum[]+=PeakTheoArea[j][p]
						linkposKe+=PeakKineticEnergy[j]*PeakTheoArea[j]
						linkposBe+=PeakBindingEnergy[j]*PeakTheoArea[j]	
						deletepoints j,1,PeakName,PeakLayer,PeakCross,PeakMultiplier,PeakAsy,PeakKineticEnergy,PeakBindingEnergy,PeakTheoArea,PeakTheoAreaRatio,PeakLinks,PeakTheoNormRatio,peakW,peakGL
						j-=1
					endif
				endfor
				PeakCross[i]=linkcross
				PeakTheoArea[i][]=linkSum[q]
				PeakKineticEnergy[i]=linkposKe>0 && linksum[0]>0 ? linkposKe/linksum[0] : PeakKineticEnergy[i]
				PeakBindingEnergy[i]=linkposBe> 0 && linksum[0]>0 ? linkposBe/linksum[0] : PeakBindingEnergy[i]
		endif
	endfor
	duplicate/O linksum,total_sum
	//---------------------------------------------------------Normalized results---------------------------------------------//
	for(i=0;i<dimsize(PeakCross,0);i+=1)
		total_sum[]+=PeakTheoArea[i][p]
	endfor
	
	PeakTheoAreaRatio[][]=PeakTheoArea[p][q]/total_sum[q]
	PeakTheoNormRatio[][]=PeakTheoArea[p][q]/PeakCross[p]
	
	for(i=0;i<dimsize(PeakCross,0);i+=1)
		total_sum[]+=PeakTheoNormRatio[i][p]
	endfor
	PeakTheoNormRatio[][]=PeakTheoNormRatio[p][q]/total_sum[q]
	//--------------------------------------------------------Single Spectra----------------------------------------------------//
	newdatafolder/O/S SingleSpectra
	string running_name,final_name
	for(i=0;i<numpnts(PeakName);i+=1)
		running_name="Peak_"+num2str(i)+"Area"
		make/O/N=(numEtch) $running_name
		Wave SingleAreaWave=$running_name
		
		running_name="Peak_"+num2str(i)+"Area_Ratio"
		make/O/N=(numEtch) $running_name
		Wave SingleAreaRatioWave=$running_name
		
		running_name="Peak_"+num2str(i)+"Normalized_Area"
		make/O/N=(numEtch) $running_name
		Wave SingleAreaNormWave=$running_name
		
		SingleAreaWave[]=PeakTheoArea[i][p]
		SingleAreaRatioWave[]=PeakTheoAreaRatio[i][p]
		SingleAreaNormWave[]=PeakTheoNormRatio[i][p]
	endfor
	//-----------------------------------------------------Rename single spectra-------------------------------------------//
	for(i=0;i<numpnts(PeakName);i+=1)
		running_name="Peak_"+num2str(i)+"Area"
		Wave SingleAreaWave=$running_name
		running_name="Peak_"+num2str(i)+"Area_Ratio"
		Wave SingleAreaRatioWave=$running_name
		running_name="Peak_"+num2str(i)+"Normalized_Area"
		Wave SingleAreaNormWave=$running_name
		
		final_name=Peakname[i]+" A"
		duplicate/O singleAreaWave,$final_name
		killwaves singleAreaWave
		final_name=Peakname[i]+" AR"
		duplicate/O singleAreaRatioWave,$final_name
		killwaves singleAreaRatioWave
		final_name=Peakname[i]+" NAR"
		duplicate/O SingleAreaNormWave,$final_name
		killwaves singleAreaNormWave
	endfor
	setdatafolder ::
	killwaves/Z total_sum,linksum,W_imfp,W_tmfp
end
//-------------------------------------------------------------------Layer Deposition Main function----------------------------------------------------------------
Function SimulateLayerDepCalculation(theory)
	variable theory

	WAVE angleE=root:Packages:DatabaseXPS:Analyzer:vecOut
	WAVE thickmatrix=:LayerDep_Thick
	WAVE thickwave=:Layer_Deposition_Thickness
	NVAR pol=root:Packages:DatabaseXPS:Analyzer:Polarization_type
	NVAR acceptance=root:Packages:DatabaseXPS:Analyzer:Acceptance
	NVAR island_area=root:Packages:DatabaseXPS:ValidatedModel:Island_area
	NVAR island_depth=root:Packages:DatabaseXPS:ValidatedModel:Island_depth
	NVAR matnumber=root:Packages:DatabaseXPS:ValidatedModel:LayerNumber
	NVAR roughness=root:Packages:DatabaseXPS:ValidatedModel:Roughness
	WAVE IMFP_mat=root:Packages:DatabaseXPS:ValidatedModel:IMFP_Matrix
	WAVE StartThick=root:Packages:DatabaseXPS:ValidatedModel:Thickness
	NVAR accuracy=:accuracy
	
	if(pol==1)
		Wave AngleHnu=root:Packages:DatabaseXPS:Analyzer:vecIn
	else
		Wave AngleHnu=root:Packages:DatabaseXPS:Analyzer:vecPol
	endif
	make/O/N=(numpnts(StartThick)) thickness,SumStartThick
	SumStartThick[]=sum(StartThick,0,p)
	
	variable i,j,k,numlines,numthick,currentThick
	variable islandStart=0
	for(i=0;i<numpnts(startthick);i+=1)
		if(SumStartthick[i]==island_depth)
			islandStart+=startThick[i]
		endif
	endfor
	variable real_island_depth
	
	killwaves sumStartThick		
	
	string aux1,aux2
	
	wave PeakLayer,PeakCross,PeakMultiplier,PeakAsy,PeakKineticEnergy,PeakBindingEnergy,PeakTheoArea,PeakTheoAreaRatio,PeakLinks,PeakTheoNormRatio,peakW,peakGL
	wave/T PeakName
		
	make/O/N=(matnumber) W_IMFP,W_TMFP
	
	numlines=numpnts(PeakName)
	numthick=numpnts(thickwave)
		
	ValDisplay SimulationProgressBar,win=ModelCalculationPanel ,value=_NUM:(0)
	DoUpdate /W=ProgressPanel
	for(currentThick=0;currentThick<numThick;currentThick+=1)
		thickness[]=thickmatrix[p][currentThick]
		for(i=0;i<numlines;i+=1)///---------------------Main calculation cycle--------------------------------------------------////
			If(island_Area<1)
			 	real_island_depth=islandStart+thickwave[currentThick]
			endif
			W_IMFP[]=IMFP(IMFP_mat[0][p],IMFP_mat[1][p],IMFP_mat[2][p],IMFP_mat[3][p],PeakKineticEnergy[i])
			for(k=0;k<matnumber;k+=1)
				aux1="TMFP_Parameter_Layer_"+num2str(k)
				wave TMFP_param=root:Packages:DatabaseXPS:ValidatedModel:$aux1
				W_TMFP[k]=TMFP(TMFP_param,IMFP_mat[2][k],PeakKineticEnergy[i])
			endfor
			W_TMFP[]=W_IMFP[p]>W_TMFP[p] ? W_IMFP[p] + 0.01 : W_TMFP[p]
			
			if(pol==1)
				CalculateXPSAreaXop/A=(PeakAsy[i]) /T=(accuracy) /M=(theory) /K=(acceptance) /R=(roughness) /I={Island_area,real_island_depth} W_IMFP,W_TMFP,thickness,AngleE,AngleHnu
			else
				CalculateXPSAreaXop/A=(PeakAsy[i]) /T=(accuracy) /M=(theory) /K=(acceptance) /P /R=(roughness) /I={Island_area,real_island_depth} W_IMFP,W_TMFP,thickness,AngleE,AngleHnu
			endif
			wave W_Results
			PeakTheoArea[i][currentThick]=peakMultiplier[i]*PeakCross[i]*W_Results[peakLayer[i]]
			endfor
		ValDisplay SimulationProgressBar,win=ModelCalculationPanel ,value=_NUM:(currentThick/numthick)
		DoUpdate /W=ProgressPanel
	
	Endfor
	ValDisplay SimulationProgressBar,win=ModelCalculationPanel ,value=_NUM:(currentThick/numthick)
	DoUpdate /W=ProgressPanel
	
	//---------------------------------------------------------Summing linked peaks--------------------------------------------------
	variable currentlink,LinkposKE,linkPosBe,linkcross
	make/O/N=(numthick) linksum
	
	for(i=0;i<numpnts(PeakCross);i+=1)
		linksum=0
		if(PeakLinks[i]!=0)
			currentlink=PeakLinks[i]
			linkcross=PeakCross[i]
			linksum[]=PeakTheoArea[i][p]
			linkposKe=PeakKineticEnergy[i]*PeakTheoArea[i]
			linkposBe=PeakBindingEnergy[i]*PeakTheoArea[i]
			for(j=i+1;j<numpnts(PeakCross);j+=1)		
				if(currentLink==peakLinks[j])
					linkcross+=peakCross[j]
					linksum[]+=PeakTheoArea[j][p]
					linkposKe+=PeakKineticEnergy[j]*PeakTheoArea[j]
					linkposBe+=PeakBindingEnergy[j]*PeakTheoArea[j]	
					deletepoints j,1,PeakName,PeakLayer,PeakCross,PeakMultiplier,PeakAsy,PeakKineticEnergy,PeakBindingEnergy,PeakTheoArea,PeakTheoAreaRatio,PeakLinks,PeakTheoNormRatio,peakW,peakGL
					j-=1
				endif
			endfor
			PeakCross[i]=linkcross
			PeakTheoArea[i][]=linkSum[q]
			PeakKineticEnergy[i]=linkposKe>0 ? linkposKe/linksum[0] : PeakKineticEnergy[i]
			PeakBindingEnergy[i]=linkposBe> 0 ? linkposBe/linksum[0] : PeakBindingEnergy[i]
		endif
	endfor
	duplicate/O linksum,total_sum
	total_sum=0
	//---------------------------------------------------------Normalized results---------------------------------------------//
	for(i=0;i<dimsize(PeakCross,0);i+=1)
		total_sum[]+=PeakTheoArea[i][p]
	endfor
	
	PeakTheoAreaRatio[][]=PeakTheoArea[p][q]/total_sum[q]
	PeakTheoNormRatio[][]=PeakTheoArea[p][q]/PeakCross[p]
	
	for(i=0;i<dimsize(PeakCross,0);i+=1)
		total_sum[]+=PeakTheoNormRatio[i][p]
	endfor
	PeakTheoNormRatio[][]=PeakTheoNormRatio[p][q]/total_sum[q]
	//--------------------------------------------------------Single Spectra----------------------------------------------------//
	newdatafolder/O/S SingleSpectra
	string running_name,final_name
	for(i=0;i<numpnts(PeakName);i+=1)
		running_name="Peak_"+num2str(i)+"Area"
		make/O/N=(numthick) $running_name
		Wave SingleAreaWave=$running_name
		
		running_name="Peak_"+num2str(i)+"Area_Ratio"
		make/O/N=(numthick) $running_name
		Wave SingleAreaRatioWave=$running_name
		
		running_name="Peak_"+num2str(i)+"Normalized_Area"
		make/O/N=(numthick) $running_name
		Wave SingleAreaNormWave=$running_name
		
		SingleAreaWave[]=PeakTheoArea[i][p]
		SingleAreaRatioWave[]=PeakTheoAreaRatio[i][p]
		SingleAreaNormWave[]=PeakTheoNormRatio[i][p]
	endfor
	//-----------------------------------------------------Rename single spectra-------------------------------------------//
	for(i=0;i<numpnts(PeakName);i+=1)
		running_name="Peak_"+num2str(i)+"Area"
		Wave SingleAreaWave=$running_name
		running_name="Peak_"+num2str(i)+"Area_Ratio"
		Wave SingleAreaRatioWave=$running_name
		running_name="Peak_"+num2str(i)+"Normalized_Area"
		Wave SingleAreaNormWave=$running_name
		
		final_name=Peakname[i]+" A"
		duplicate/O singleAreaWave,$final_name
		killwaves singleAreaWave
		final_name=Peakname[i]+" AR"
		duplicate/O singleAreaRatioWave,$final_name
		killwaves singleAreaRatioWave
		final_name=Peakname[i]+" NAR"
		duplicate/O SingleAreaNormWave,$final_name
		killwaves singleAreaNormWave
	endfor
	setdatafolder ::
	killwaves thickness
	killwaves total_sum,linksum,W_imfp,W_tmfp
end
//-------------------------------------------------------------------EDXPS Main function----------------------------------------------------------------
Function SimulateEDXPSCalculation(theory)
	variable theory

	WAVE angleE=root:Packages:DatabaseXPS:Analyzer:vecOut
	NVAR pol=root:Packages:DatabaseXPS:Analyzer:Polarization_type
	NVAR acceptance=root:Packages:DatabaseXPS:Analyzer:Acceptance
	NVAR island_area=root:Packages:DatabaseXPS:ValidatedModel:Island_area
	NVAR island_depth=root:Packages:DatabaseXPS:ValidatedModel:Island_depth
	NVAR matnumber=root:Packages:DatabaseXPS:ValidatedModel:LayerNumber
	NVAR roughness=root:Packages:DatabaseXPS:ValidatedModel:Roughness
	WAVE IMFP_mat=root:Packages:DatabaseXPS:ValidatedModel:IMFP_Matrix
	WAVE thickness=root:Packages:DatabaseXPS:ValidatedModel:Thickness
	NVAR workF=root:Packages:DatabaseXPS:work_f
	NVAR accuracy=:accuracy
	
	if(pol==1)
		Wave AngleHnu=root:Packages:DatabaseXPS:Analyzer:vecIn
	else
		Wave AngleHnu=root:Packages:DatabaseXPS:Analyzer:vecPol
	endif
	
	string aux1,aux2
	wave PeakLayer,PeakMultiplier,PeakKineticEnergy,PeakBindingEnergy,PeakTheoArea,PeakTheoAreaRatio,PeakLinks,PeakTheoNormRatio,PeakCode,peakW,peakGL
	wave/T PeakName
	make/O/N=(matnumber) W_IMFP,W_TMFP
	
	WAVE PhotonWave=:EDXPS_photon
	
	variable numlines=numpnts(PeakName)
	variable numPh=numpnts(PhotonWave)
	variable currentPhIndex,currentPh,i,j,k,currentCross,CurrentAsy
	make/O/N=(numlines,NumPh) KEmatrix
	
	ValDisplay SimulationProgressBar,win=ModelCalculationPanel ,value=_NUM:(0)
	DoUpdate /W=ProgressPanel
	for(currentPhIndex=0;currentPhIndex<numPh;currentPhIndex+=1)
		currentPh=PhotonWave[currentPhIndex]
		for(i=0;i<numlines;i+=1)///---------------------Main calculation cycle--------------------------------------------------////
			KeMatrix[i][currentPhIndex]=currentPh-PeakBindingEnergy[i]-workF
			if(KeMatrix[i][currentPhIndex]<0)
				PeakTheoArea[i][currentPhIndex]=0
			else
				W_IMFP[]=IMFP(IMFP_mat[0][p],IMFP_mat[1][p],IMFP_mat[2][p],IMFP_mat[3][p],KeMatrix[i][currentPhIndex])
				for(k=0;k<matnumber;k+=1)
					aux1="TMFP_Parameter_Layer_"+num2str(k)
					wave TMFP_param=root:Packages:DatabaseXPS:ValidatedModel:$aux1
					W_TMFP[k]=TMFP(TMFP_param,IMFP_mat[2][k],KeMatrix[i][currentPhIndex])
				endfor
				W_TMFP[]=W_IMFP[p]>W_TMFP[p] ? W_IMFP[p] + 0.01 : W_TMFP[p]
				
				currentCross=CrossSec(PeakCode[i],currentPh,0)
				currentAsy=CrossSec(PeakCode[i],currentPh,1)
				
				if(pol==1)
					CalculateXPSAreaXop/A=(CurrentAsy) /T=(accuracy) /M=(theory) /K=(acceptance) /R=(roughness) /I={Island_area,island_depth} W_IMFP,W_TMFP,thickness,AngleE,AngleHnu
				else
					CalculateXPSAreaXop/A=(CurrentAsy) /T=(accuracy) /M=(theory) /K=(acceptance) /P /R=(roughness) /I={Island_area,island_depth} W_IMFP,W_TMFP,thickness,AngleE,AngleHnu
				endif
				wave W_Results
				PeakTheoArea[i][currentPhIndex]=peakMultiplier[i]*currentCross*W_Results[peakLayer[i]]//*(-1.220+67.52*KeMatrix[i][currentPhIndex]^-0.274)
				PeakTheoNormRatio[i][currentPhIndex]=peakMultiplier[i]*W_Results[peakLayer[i]]//*(-1.220+67.52*KeMatrix[i][currentPhIndex]^-0.274)
			endif
		endfor
		ValDisplay SimulationProgressBar,win=ModelCalculationPanel ,value=_NUM:(currentPhIndex/numPh)
		DoUpdate /W=ProgressPanel
	endfor
	ValDisplay SimulationProgressBar,win=ModelCalculationPanel ,value=_NUM:(currentPhIndex/numPh)
	DoUpdate /W=ProgressPanel
	
	//---------------------------------------------------------Summing linked peaks--------------------------------------------------
	variable currentlink,LinkposKE,linkPosBe
	make/O/N=(numPh) linksum,linksum2
	
	for(i=0;i<numpnts(PeakBindingEnergy);i+=1)
		linksum=0
		if(PeakLinks[i]!=0)
			currentlink=PeakLinks[i]
			linksum[]=PeakTheoArea[i][p]
			linksum2[]=PeakTheoNormRatio[i][p]
			linkposBe=PeakBindingEnergy[i]*PeakTheoArea[i]
			for(j=i+1;j<numpnts(PeakBindingEnergy);j+=1)		
				if(currentLink==peakLinks[j])
					linksum[]+=PeakTheoArea[j][p]
					linksum2[]+=PeakTheoNormRatio[j][p]
					linkposBe+=PeakBindingEnergy[j]*PeakTheoArea[j]
					deletepoints j,1,peakCode,KEmatrix,PeakName,PeakLayer,PeakMultiplier,PeakKineticEnergy,PeakBindingEnergy,PeakTheoArea,PeakTheoAreaRatio,PeakLinks,PeakTheoNormRatio,peakW,peakGL
					j-=1
				endif
			endfor
			PeakTheoArea[i][]=linkSum[q]
			PeakTheoNormRatio[i][]=linkSum2[q]
			PeakBindingEnergy[i]=linkposBe/linksum[0]
		endif
	endfor
	KEmatrix[][]=PhotonWave[q]-PeakBindingEnergy[p]-WorkF
	
	duplicate/O linksum,total_sum
	total_sum=0
	//---------------------------------------------------------Normalized results---------------------------------------------//
	for(i=0;i<dimsize(peakTheoArea,0);i+=1)
		total_sum[]+=PeakTheoArea[i][p]
	endfor
	
	PeakTheoAreaRatio[][]=PeakTheoArea[p][q]/total_sum[q]
	total_sum=0
	for(i=0;i<dimsize(peakTheoArea,0);i+=1)
		total_sum[]+=PeakTheoNormRatio[i][p]
	endfor
	PeakTheoNormRatio[][]=PeakTheoNormRatio[p][q]/total_sum[q]
	//--------------------------------------------------------Single Spectra----------------------------------------------------//
	newdatafolder/O/S SingleSpectra
	string running_name,final_name
	for(i=0;i<numpnts(PeakName);i+=1)
		running_name="Peak_"+num2str(i)+"Area"
		make/O/N=(numPh) $running_name
		Wave SingleAreaWave=$running_name
		
		running_name="Peak_"+num2str(i)+"Area_Ratio"
		make/O/N=(numPh) $running_name
		Wave SingleAreaRatioWave=$running_name
		
		running_name="Peak_"+num2str(i)+"Normalized_Area"
		make/O/N=(numPh) $running_name
		Wave SingleAreaNormWave=$running_name
		
		SingleAreaWave[]=PeakTheoArea[i][p]
		SingleAreaRatioWave[]=PeakTheoAreaRatio[i][p]
		SingleAreaNormWave[]=PeakTheoNormRatio[i][p]
	endfor
	//-----------------------------------------------------Rename single spectra-------------------------------------------//
	for(i=0;i<numpnts(PeakName);i+=1)
		running_name="Peak_"+num2str(i)+"Area"
		Wave SingleAreaWave=$running_name
		running_name="Peak_"+num2str(i)+"Area_Ratio"
		Wave SingleAreaRatioWave=$running_name
		running_name="Peak_"+num2str(i)+"Normalized_Area"
		Wave SingleAreaNormWave=$running_name
		
		final_name=Peakname[i]+" A"
		duplicate/O singleAreaWave,$final_name
		killwaves singleAreaWave
		final_name=Peakname[i]+" AR"
		duplicate/O singleAreaRatioWave,$final_name
		killwaves singleAreaRatioWave
		final_name=Peakname[i]+" NAR"
		duplicate/O SingleAreaNormWave,$final_name
		killwaves singleAreaNormWave
	endfor
	setdatafolder ::
	Killwaves total_sum,linksum,linksum2,W_imfp,W_tmfp
end
//------------------------------------------------------------Important: DISPLAY RESULTS ROUTINE-----------------------------------------------------------------
function DisplaySimulationResults(code,displayType,WhatToShow,DataScaling,FolderNum)
	variable code
	variable DisplayType
	variable WhatToShow
	variable DataScaling
	variable FolderNum
	variable i,j,k
	NVAR ph_energy=root:Packages:DatabaseXPS:ph_energy
	NVAR work_f=root:Packages:DatabaseXPS:work_f
	String wave_energy_str,AxisXlabel
	String aux1
	String display_name="SimRes_"+num2str(FolderNum)+"_"+num2str(DisplayType)
	String display_window=display_name
	If(DisplayType<=3)
		Dowindow/K $display_window
	endif
	Wave TraceColor=root:Packages:DatabaseXPS:AuxData:LineColorTable
	STRUCT GeneralXPSParameterPrefs prefs
	LoadPackagePreferences kPackageName, kPreferencesFileName, kPreferencesRecordID, prefs
	If(V_flag!=0 || V_bytesRead==0 || prefs.version<110)	
		print "Wrong installation. Please re-install the ILAMP package."
		return -1;
	endif
	variable lineThick=prefs.linethickness
	
	Switch(code)
		case 1:
			switch(DisplayType)
				case 1://----------------------table--------------------------
					Edit/W=(0,0,400,400) PeakName,PeakTheoArea,PeakTheoAreaRatio,PeakTheoNormRatio as "Simulation Results"
					ModifyTable format(Point)=1,alignment(PeakName)=1,sigDigits(PeakName)=4,width(PeakName)=96
					ModifyTable alignment(PeakTheoAreaRatio)=1,sigDigits(PeakTheoAreaRatio)=4,width(PeakTheoAreaRatio)=110
					ModifyTable alignment(PeakTheoArea)=1,sigDigits(PeakTheoArea)=4,width(PeakTheoArea)=76
					ModifyTable alignment(PeakTheoNormRatio)=1,sigDigits(PeakTheoNormRatio)=4,width(PeakTheoNormRatio)=122
					ModifyTable showParts=0x66
					break
				case 2://----------------------graph--------------------------
					switch(WhatToShow)
						case 1:
							display_name="PeakTheoArea"		
							break
						case 2:
							display_name="PeakTheoAreaRatio"
							break
						case 3:
							display_name="PeakTheoNormRatio"
							break
					endswitch
					Display /W=(0,0,400,400) $display_name,$display_name as "Simulation results chart"
					ModifyGraph mode($display_name)=5,mode($display_name#1)=3
					ModifyGraph rgb($display_name#1)=(0,0,0)
					ModifyGraph msize($display_name#1)=4
					ModifyGraph hbFill($display_name)=5
					ModifyGraph useNegPat($display_name)=1
					ModifyGraph useBarStrokeRGB($display_name)=1
					ModifyGraph textMarker($display_name#1)={PeakName,"default",1,90,0,0.00,0.00}
					ModifyGraph grid(left)=1
					ModifyGraph tick(left)=2,tick(bottom)=3
					ModifyGraph mirror=1
					ModifyGraph minor(left)=1
					ModifyGraph noLabel(bottom)=2
					ModifyGraph lblMargin(left)=10
					ModifyGraph gridHair(left)=3
					ModifyGraph lblLatPos(left)=-12
					switch(WhatToShow)
						case 1:
							Label left "Peak Intensity (arb. units)"
							SetAxis left 0,wavemax($display_name)*1.5
							break
						case 2:
							Label left "Normalized peak area ratio"
							SetAxis left 0,1
							break
						case 3:
							Label left "Normalized to cross sec. peak area ratio"
							SetAxis left 0,1
							break
					endswitch
					break
				case 3://_ spectra
					wave peakW=:peakW
					wave peakGL=:peakGL
					if(DataScaling== 1) 
						wave_energy_str="PeakKineticEnergy"
						aux1="Kinetic Energy"
					else
						wave_energy_str="PeakBindingEnergy"
						aux1="Binding Energy"
					endif
					WAVE wave_energy=:$wave_energy_str
					make/O/N=1000 Broadened_spectra
					wavestats/Q wave_energy
					setscale/I x,(V_min-10),(V_max+10),aux1,Broadened_Spectra
					broadVoigtSpectra(wave_energy,PeakTheoArea,PeakW,PeakGL,broadened_Spectra)
				
					Display /W=(0,0,400,400) PeakTheoArea vs wave_energy as "Simulation results graph"
					AppendToGraph Broadened_spectra
					ModifyGraph mode(PeakTheoArea)=8
					ModifyGraph lSize(Broadened_spectra)=lineThick
					ModifyGraph rgb(PeakTheoArea)=(65280,0,0),rgb(Broadened_spectra)=(0,0,0)
					ModifyGraph msize(PeakTheoArea)=3
					ModifyGraph textMarker(PeakTheoArea)={PeakName,"default",0,0,2,0.00,0.00}
					ModifyGraph tick=2
					ModifyGraph mirror=1
					ModifyGraph minor=1
					ModifyGraph lblMargin(left)=3
					ModifyGraph axOffset(left)=-4.28571
					Label left "Intensity (arb. units)"
					Label bottom Aux1+"(eV)"
					If(DataScaling==2)
						SetAxis/A/R bottom		
					endif
					break
				endswitch
				break 
			case 2://----------------------------------------------------------------full XPS spectra with loss functions-complete spectra only
				wave/T PeakName=:PeakName
				WAVE wave_energy=:PeakKineticEnergy
				wave PeakIntensityMat=:MultipleScatteringMat
				wave LossMatrix=:LossSpectraMat
				wave peakW=:peakW
				wave peakGL=:peakGL
				NVAR lossMult=:lossMult
				ControlInfo/W=ModelCalculationPanel SimulationFullSpecNumpnts
				make/O/N=(V_value) Broadened_Full_Spectra=0
				wavestats/Q wave_energy
				setscale/I x,(V_min-300),(V_max+250),"Kinetic Energy (eV)",Broadened_Full_Spectra //changed from v-120,v+50
				broadVoigtSpectra(wave_energy,PeakTheoArea,PeakW,PeakGL,broadened_Full_Spectra)
				for(i=0;i<numpnts(peakName);i+=1)
					for(j=1;j<15;j+=1)
						Broadened_Full_spectra[]+=lossMult*5*interp2D(LossMatrix,pnt2x(Broadened_Full_spectra,p)+1500-wave_energy[i],j)*PeakIntensityMat[i][j]
					endfor
				endfor
				Broadened_Full_Spectra*=5		
				if(DataScaling== 1) 
					Display /W=(55.5,103.25,498.75,390.5) Broadened_Full_Spectra
					AppendToGraph PeakTheoArea vs PeakKineticEnergy
					ModifyGraph mode(PeakTheoArea)=8
					ModifyGraph lSize(Broadened_Full_Spectra)=lineThick
					ModifyGraph rgb(Broadened_Full_Spectra)=(65280,16384,16384),rgb(PeakTheoArea)=(0,0,0)
					ModifyGraph textMarker(PeakTheoArea)={:PeakName,"default",0,0,2,0.00,0.00}
					ModifyGraph tick=2
					ModifyGraph mirror=1
					ModifyGraph minor=1
					ModifyGraph lblMargin(left)=13
					ModifyGraph axOffset(left)=-3.28571
					Label left "Intensity (arb.units)"
				else
					setscale/I x,(ph_energy-work_f-(V_min-120)),(ph_energy-work_f-(V_max+50)),"Binding Energy (eV)",Broadened_Full_Spectra
					Display /W=(55.5,103.25,498.75,390.5) Broadened_Full_Spectra
					AppendToGraph PeakTheoArea vs PeakBindingEnergy
					ModifyGraph mode(PeakTheoArea)=8
					ModifyGraph lSize(Broadened_Full_Spectra)=lineThick
					ModifyGraph rgb(Broadened_Full_Spectra)=(65280,16384,16384),rgb(PeakTheoArea)=(0,0,0)
					ModifyGraph textMarker(PeakTheoArea)={:PeakName,"default",0,0,2,0.00,0.00}
					ModifyGraph tick=2
					ModifyGraph mirror=1
					ModifyGraph minor=1
					ModifyGraph lblMargin(left)=13
					ModifyGraph axOffset(left)=-3.28571
					Label left "Intensity (arb.units)"		
				endif
				string fulllist = WinList("*", ";","WIN:1")  			
//    			killWindow
				break
		case 3://---------------------------------------------------------------------------------------ARXPS visualization--------------------------------------------------------
			wave/T PeakName=:PeakName
			SVAR axisname=root:Packages:DatabaseXPS:ValidatedModel:ARXPS_type
			switch(DisplayType)	
				case 1:// Table with arxps data
					Edit/W=(10,10,410,410):$axisname as "ARXPS simulation results "
					for(i=0;i<numpnts(PeakName);i+=1)		
						switch(whatToShow)
							case 1:
								display_name=peakName[i]+" A"
								break
							case 2:
								display_name=peakName[i]+" AR"
								break
							case 3:
								display_name=peakName[i]+" NAR"
								break
						endswitch
						AppendToTable :SingleSpectra:$display_name
					endfor
					ModifyTable format(Point)=1
					ModifyTable showParts=0xF2
					break
				case 2:// Graph with ARXPS data
					display/W=(10,10,410,410) as "ARXPS simulation results "
					for(i=0;i<numpnts(PeakName);i+=1)		
						switch(whatToShow)
							case 1:
								display_name=peakName[i]+" A"
								break
							case 2:
								display_name=peakName[i]+" AR"
								break
							case 3:
								display_name=peakName[i]+" NAR"
								break
						endswitch
						AppendToGraph :SingleSpectra:$display_name vs :$axisname
						ModifyGraph rgb($display_name)=(TraceColor[i][0],TraceColor[i][1],TraceColor[i][2])
					endfor
					ModifyGraph lsize=lineThick
					ModifyGraph tick=2
					ModifyGraph mirror=1
					ModifyGraph minor=1
					ModifyGraph notation=1
					Label left "Intensity (arb. units)"
					Label bottom axisname
					legend		
					break
				case 3:///--------------------------------------------------------------------------------------------ARXPS with broadened spectra
					wave peakW=:peakW
					wave peakGL=:peakGL
					if(DataScaling== 1) 
						wave_energy_str="PeakKineticEnergy"
						axisXlabel="Kinetic Energy (eV)"
					else
						wave_energy_str="PeakBindingEnergy"
						axisXlabel="Binding Energy (eV)"
					endif
					WAVE wave_energy=:$wave_energy_str
					wavestats/Q wave_energy
					wave source_matrix=:PeakTheoAreaRatio
				
					display/W=(10,10,410,410) as "ARXPS simulation results"
					wave arpesXvariable=:$axisname
					for(i=0;i<numpnts($axisname);i+=1)		
						display_name = "Spectra_at_"+num2str(arpesXvariable[i])+"°"
						make/O/N=1000 $display_name
						make/O/N=(dimsize(source_matrix,0)) PeakIntFinal	
						PeakIntFinal[]=source_matrix[p][i]
						setscale/I x,(V_min-15),(V_max+15),$display_name
						broadVoigtSpectra(wave_energy,PeakIntFinal,PeakW,PeakGL,$display_name)
						appendToGraph :$display_name
						ModifyGraph rgb($display_name)=(TraceColor[i][0],TraceColor[i][1],TraceColor[i][2]),lSize=1.0
					endfor
					PeakIntFinal[]=source_matrix[p][0]
					ModifyGraph tick=2
					ModifyGraph mirror=1
					ModifyGraph minor=1
					ModifyGraph notation=1
					Label left "Intensity (arb. units)"
					Label bottom axisXlabel
					legend				
					AppendToGraph PeakIntFinal vs wave_energy
					ModifyGraph mode(PeakIntFinal)=8
					ModifyGraph textMarker(PeakIntFinal)={:PeakName,"default",0,0,2,0.00,0.00}
					break
			endswitch
			break
		case 4:// ED-XPS
			wave/T PeakName=:PeakName
			String Photonaxisname="Photon Energy (eV)"
			switch(DisplayType)	
				case 1:// Table with simple data
					Edit/W=(10,10,410,410):EDXPS_photon as "ED-XPS Data Table"
					for(i=0;i<numpnts(PeakName);i+=1)		
						switch(whatToShow)
							case 1:
								display_name=peakName[i]+" A"
								break
							case 2:
								display_name=peakName[i]+" AR"
								break
							case 3:
								display_name=peakName[i]+" NAR"
								break
						endswitch
						AppendToTable :SingleSpectra:$display_name
					endfor
					ModifyTable format(Point)=1
					ModifyTable showParts=0xF2
					break
				case 2:// Graph with ED-XPS data
					display/W=(10,10,410,410) as "ED-XPS simulation results"
					for(i=0;i<numpnts(PeakName);i+=1)		
						switch(whatToShow)
							case 1:
								display_name=peakName[i]+" A"
								break
							case 2:
								display_name=peakName[i]+" AR"
								break
							case 3:
								display_name=peakName[i]+" NAR"
								break
						endswitch
						AppendToGraph :SingleSpectra:$display_name vs :EDXPS_photon
						ModifyGraph rgb($display_name)=(TraceColor[i][0],TraceColor[i][1],TraceColor[i][2])
					endfor
					ModifyGraph lsize=lineThick
					ModifyGraph tick=2
					ModifyGraph mirror=1
					ModifyGraph minor=1
					ModifyGraph notation=1
					Label left "Intensity (arb. units)"
					Label bottom "Photon Energy (eV)"
					legend		
					break
				case 3:///--------------------------------------------------------------------------------------------ED-XPS with broadened spectra
					variable currentEnergyScaling=DataScaling
					wave peakW=:peakW
					wave peakGL=:peakGL
					if(V_value== 1) 
						wave_energy_str="KEmatrix"
						axisXlabel="Kinetic Energy (eV)"
					else
						wave_energy_str="PeakBindingEnergy"
						axisXlabel="Binding Energy (eV)"
					endif
					WAVE wave_energy=:$wave_energy_str
					wavestats/Q wave_energy	
					wave source_matrix=:PeakTheoAreaRatio
				
					display/W=(10,10,410,410) as "ED-XPS simulation results"
					wave EDXPS_Xvariable=:EDXPS_photon
					for(i=0;i<numpnts(EDXPS_Xvariable);i+=1)		
						display_name = "PhotonEnergy_"+num2str(EDXPS_Xvariable[i])+"_eV"
						make/O/N=5000 $display_name
						make/O/N=(dimsize(source_matrix,0)) PeakIntFinal	
						make/O/N=(dimsize(wave_Energy,0)) PeakPosFinal
						PeakIntFinal[]=source_matrix[p][i]
						setscale/I x,(V_min-15),(V_max+15),$display_name
						if(currentEnergyScaling == 1) 
							peakPosFinal[]=wave_energy[p][i]
						else
							peakPosFinal[]=wave_energy[p]
						endif
						// --- Aggiunta Ad Hoc --- ELIMINARE -----
						//duplicate/O PeakW peakW_new
						//peakW_new[]=peakW[p]+0.01*i
						// --- ELIMINARE!!!
						broadVoigtSpectra(peakPosFinal,PeakIntFinal,PeakW,PeakGL,$display_name)
						AppendToGraph :$display_name
						ModifyGraph rgb($display_name)=(TraceColor[i][0],TraceColor[i][1],TraceColor[i][2]),lSize=1.0
					endfor
					ModifyGraph tick=2
					ModifyGraph mirror=1
					ModifyGraph minor=1
					ModifyGraph notation=1
					Label left "Intensity (arb. units)"
					Label bottom axisXlabel
					legend				
					AppendToGraph PeakIntFinal vs PeakPosFinal
					ModifyGraph mode(PeakIntFinal)=8
					ModifyGraph textMarker(PeakIntFinal)={:PeakName,"default",0,0,2,0.00,0.00}
					break
			endswitch
		break
		case 5:// Etching simulation visualization
			wave/T PeakName=:PeakName
			switch(DisplayType)	
				case 1:// Table with simple data
					Edit/W=(10,10,410,410):Etching_Depth as "Etching simulation results"
					for(i=0;i<numpnts(PeakName);i+=1)		
						switch(whatToShow)
							case 1:
								display_name=peakName[i]+" A"
							break
							case 2:
								display_name=peakName[i]+" AR"
							break
							case 3:
								display_name=peakName[i]+" NAR"
							break
						endswitch
						AppendToTable :SingleSpectra:$display_name
					endfor
					ModifyTable format(Point)=1
					ModifyTable showParts=0xF2
					break
				case 2:// Graph with Layer deposition data
					display/W=(10,10,410,410) as "Etching simulation results"
					for(i=0;i<numpnts(PeakName);i+=1)		
						switch(whatToShow)
							case 1:
								display_name=peakName[i]+" A"
							break
							case 2:
								display_name=peakName[i]+" AR"
							break
							case 3:
								display_name=peakName[i]+" NAR"
							break
						endswitch
						AppendToGraph :SingleSpectra:$display_name vs :Etching_Depth
						ModifyGraph rgb($display_name)=(abs(enoise(65535)),abs(enoise(65535)),abs(enoise(65535)))
					endfor
					ModifyGraph lsize=lineThick
					ModifyGraph tick=2
					ModifyGraph mirror=1
					ModifyGraph minor=1
					ModifyGraph notation=1
					Label left "Intensity (arb. units)"
					Label bottom "Etching depth (Å)"
					legend		
				break
				case 3:///--------------------------------------------------------------------------------------------Etching with broadened spectra
					wave peakW=:peakW
					wave peakGL=:peakGL
					if(DataScaling== 1) 
						wave_energy_str="PeakKineticEnergy"
						axisXlabel="Kinetic Energy (eV)"
					else
						wave_energy_str="PeakBindingEnergy"
						axisXlabel="Binding Energy (eV)"
					endif
					WAVE wave_energy=:$wave_energy_str
					wavestats/Q wave_energy
					wave source_matrix=:PeakTheoAreaRatio
					display/W=(10,10,410,410) as "Etching simulation results"
					wave arpesXvariable=:Etching_depth
					for(i=0;i<numpnts(arpesXvariable);i+=1)		
						display_name = "Depth_"+num2str(arpesXvariable[i])+"Å"
						make/O/N=1000 $display_name
						make/O/N=(dimsize(source_matrix,0)) PeakIntFinal	
						PeakIntFinal[]=source_matrix[p][i]
						setscale/I x,(V_min-15),(V_max+15),$display_name
						//broadGaussSpectra(wave_energy,PeakIntFinal,1,$display_name)
						broadVoigtSpectra(wave_energy,PeakIntFinal,PeakW,PeakGL,$display_name)
						appendToGraph :$display_name
						ModifyGraph rgb($display_name)=(TraceColor[i][0],TraceColor[i][1],TraceColor[i][2]),lSize=1.0
					endfor
					PeakIntFinal[]=source_matrix[p][0]
					ModifyGraph tick=2
					ModifyGraph mirror=1
					ModifyGraph minor=1
					ModifyGraph notation=1
					Label left "Intensity (arb. units)"
					Label bottom AxisXlabel
					legend				
					AppendToGraph PeakIntFinal vs wave_energy
					ModifyGraph mode(PeakIntFinal)=8
					ModifyGraph textMarker(PeakIntFinal)={:PeakName,"default",0,0,2,0.00,0.00}
					break
			endswitch
			break
		case 6:// Layer Deposition Routine visualization
			wave/T PeakName=:PeakName
			String DepAxisName="Thickness(Å)"
			switch(DisplayType)	
				case 1:// Table with simple data
					Edit/W=(10,10,410,410):Layer_Deposition_Thickness as "Layer deposition simulation results "
					for(i=0;i<numpnts(PeakName);i+=1)		
						switch(whatToShow)
							case 1:
								display_name=peakName[i]+" A"
								break
							case 2:
								display_name=peakName[i]+" AR"
								break
							case 3:
								display_name=peakName[i]+" NAR"
								break
						endswitch
						AppendToTable :SingleSpectra:$display_name
					endfor
					ModifyTable format(Point)=1
					ModifyTable showParts=0xF2
					break
				case 2:// Graph with Layer deposition data
					display/W=(10,10,410,410) as "Layer deposition simulation results"
					for(i=0;i<numpnts(PeakName);i+=1)		
						switch(whatToShow)
							case 1:
								display_name=peakName[i]+" A"
								break
							case 2:
								display_name=peakName[i]+" AR"
								break
							case 3:
								display_name=peakName[i]+" NAR"
								break
						endswitch
						AppendToGraph :SingleSpectra:$display_name vs :Layer_Deposition_Thickness
						ModifyGraph rgb($display_name)=(TraceColor[i][0],TraceColor[i][1],TraceColor[i][2])
					endfor
					ModifyGraph lsize=lineThick
					ModifyGraph tick=2
					ModifyGraph mirror=1
					ModifyGraph minor=1
					ModifyGraph notation=1
					Label left "Intensity (arb. units)"
					Label bottom "Overlayer thickness (Å)"
					Legend		
					break
				case 3:///--------------------------------------------------------------------------------------------Layer Dep with broadened spectra
					wave peakW=:peakW
					wave peakGL=:peakGL
					if(DataScaling== 1) 
						wave_energy_str="PeakKineticEnergy"
						axisXlabel="Kinetic Energy (eV)"
					else
						wave_energy_str="PeakBindingEnergy"
						axisXlabel="Binding Energy (eV)"
					endif
					WAVE wave_energy=:$wave_energy_str
					wavestats/Q wave_energy
					WAVE source_matrix=:PeakTheoAreaRatio
					
					display/W=(10,10,410,410) as "Layer deposition simulation results"
					wave arpesXvariable=:Layer_Deposition_Thickness
					for(i=0;i<numpnts(arpesXvariable);i+=1)		
						display_name = "Spectra_at_"+num2str(arpesXvariable[i])+"Å"
						make/O/N=1000 $display_name
						wave DisplayWave=$display_name
						make/O/N=(dimsize(source_matrix,0)) PeakIntFinal	
						PeakIntFinal[]=source_matrix[p][i]
						setscale/I x,(V_min-15),(V_max+15),displayWave
						//broadGaussSpectra(wave_energy,PeakIntFinal,1,DisplayWave)
						broadVoigtSpectra(wave_energy,PeakIntFinal,PeakW,PeakGL,DisplayWave)
						appendToGraph DisplayWave
						ModifyGraph rgb($display_name)=(TraceColor[i][0],TraceColor[i][1],TraceColor[i][2]),lSize=1.0
					endfor
					PeakIntFinal[]=source_matrix[p][0]
					ModifyGraph tick=2
					ModifyGraph mirror=1
					ModifyGraph minor=1
					ModifyGraph notation=1
					Label left "Intensity (arb. units)"
					Label bottom AxisXlabel
					legend				
					AppendToGraph PeakIntFinal vs wave_energy
					ModifyGraph mode(PeakIntFinal)=8
					ModifyGraph textMarker(PeakIntFinal)={:PeakName,"default",0,0,2,0.00,0.00}
					break
			endswitch
			break
	endswitch
	if(DisplayType<=3)
		dowindow/C $display_window
	endif
end

//----------------------------------------------------------------------------------------- Auxiliary Broadening/Angular functions---------------------------------------------------------------
static function broadGaussSpectra(lista_x,lista_y,width,target_wave)
	wave lista_x,lista_y
	variable width
	wave target_wave
	target_wave=0
	variable i,j,length=numpnts(target_wave),numpicchi=numpnts(lista_x)

	for(i=0;i<length;i+=1)
		for(j=0;j<numpicchi;j+=1)
			target_wave[i]+=5*lista_y[j]*Gauss(pnt2x(target_wave,i),lista_x[j],width)		
		endfor
	endfor
end

Static function broadVoigtSpectra(lista_x,lista_y,waveW,waveGL,target_wave)
	wave lista_x,lista_y
	wave waveW,waveGL
	wave target_wave
	target_wave=0
	variable i,j,length=numpnts(target_wave),numpicchi=numpnts(lista_x)

	for(i=0;i<length;i+=1)
		for(j=0;j<numpicchi;j+=1)
			target_wave[i]+=5*lista_y[j]*(waveGL[j]*Gauss(pnt2x(target_wave,i),lista_x[j],WaveW[j]) + (1-waveGL[j])*1/Pi*WaveW[j]/( (pnt2x(target_wave,i)-lista_x[j])^2+WaveW[j]^2) )		
		endfor
	endfor
End

Function SimulationAngleEvaluation(thetaI,thetaO,phiO)
	variable thetai,thetao,phio
	make/O/N=3 tvecIn,tvecOut,tempwave,tVecPol
	make/O/N=(3,3) MatPol
	NVAR thetaPol=root:Packages:DatabaseXPS:Analyzer:thetaPol
	NVAR polType=root:Packages:DatabaseXPS:Analyzer:Polarization_type
	tvecIn={1*Sin(thetaI/180*Pi),0,Cos(thetaI/180*Pi)}
	tvecOut={Cos(PhiO/180*Pi)*Sin(thetaO/180*Pi),Sin(PhiO/180*Pi)*Sin(thetaO/180*Pi),Cos(thetaO/180*Pi)}
	tempWave={Cos(thetaPol/180*Pi),Sin(thetaPol/180*Pi),0}
	MatrixOp/O tVecPol = (MatPol x tempwave )
	Killwaves tempwave
End 

//----------------------------------------------------------------------------------------Auxiliary FITTING function--------------------------------------------------------------------//
Structure ILAMP_SingleIntFit
	wave W_coeff
	wave waveY
	wave waveX
	variable TheoryLevel
	variable ApproxLevel
	variable FixedIslandDepth
	variable FixIslandTo
Endstructure

Function FitSingleConfiguration(s) : fitFunc
	struct ILAMP_SingleIntFit &s
	DFREF backupFolder=GetDataFolderDFR()
	SetDataFolder root:Packages:DatabaseXPS:FitDump
	
	variable theory=s.TheoryLevel
	variable i,j,k,numlines
	string aux1
	
	WAVE IMFP_mat=root:Packages:DatabaseXPS:ValidatedModel:IMFP_Matrix
	NVAR matnumber=root:Packages:DatabaseXPS:ValidatedModel:LayerNumber
	WAVE angleE=root:Packages:DatabaseXPS:Analyzer:vecOut
	NVAR pol=root:Packages:DatabaseXPS:Analyzer:Polarization_type
	NVAR acceptance=root:Packages:DatabaseXPS:Analyzer:Acceptance
	Make/O/N=(matnumber-1) thickness
	variable island_area=1
	variable island_depth=0
	variable roughness=0
	i=0
	Switch(numpnts(s.w_coeff)-numpnts(thickness))
		Case 1:
			roughness=s.w_coeff[0]
			i=1
		break
		Case 2:
			island_area=s.w_coeff[1]
			island_depth=s.w_coeff[0]
			i=2
		break
		Case 3:
			island_area=s.w_coeff[2]
			island_depth=s.w_coeff[1]
			roughness=s.w_coeff[0]
			i=3
		break
	Endswitch
	j=0	
	Do
		thickness[j]=s.W_coeff[i]
		i+=1
		j+=1
	While(i<numpnts(s.W_coeff))
	
	If(pol==1)
		Wave AngleHnu=root:Packages:DatabaseXPS:Analyzer:vecIn
	Else
		Wave AngleHnu=root:Packages:DatabaseXPS:Analyzer:vecPol
	Endif
	
	If(s.FixedIslandDepth)
		island_depth=sum(thickness,0,s.FixIslandTo-1)
	Endif
	
	Switch(numpnts(s.w_coeff)-numpnts(thickness))
		case 2:
			s.w_coeff[0]=island_depth
		break
		case 3:
			s.w_coeff[1]=island_depth
		break
	Endswitch
	
	Wave PeakLayer,PeakCross,PeakMultiplier,PeakAsy,PeakKineticEnergy,PeakBindingEnergy,PeakTheoArea,PeakTheoAreaRatio,PeakLinks
	Wave/T PeakName
	Make/O/N=(matnumber) W_IMFP,W_TMFP
	numlines=numpnts(PeakName)
	For(i=0;i<numlines;i+=1)  // ------------------------ Main calculation cycle ------------------------ //
		W_IMFP[]=IMFP(IMFP_mat[0][p],IMFP_mat[1][p],IMFP_mat[2][p],IMFP_mat[3][p],PeakKineticEnergy[i])
		For(k=0;k<matnumber;k+=1)
			aux1="TMFP_Parameter_Layer_"+num2str(k)
			wave TMFP_param=root:Packages:DatabaseXPS:ValidatedModel:$aux1
			W_TMFP[k]=TMFP(TMFP_param,IMFP_mat[2][k],PeakKineticEnergy[i])
		Endfor
		
		If(pol==1)
			CalculateXPSAreaXop/A=(PeakAsy[i]) /T=(s.ApproxLevel) /M=(theory) /K=(acceptance) /R=(roughness) /I={Island_area,Island_depth} W_IMFP,W_TMFP,thickness,AngleE,AngleHnu
		Else
			CalculateXPSAreaXop/A=(PeakAsy[i]) /T=(s.ApproxLevel) /M=(theory) /K=(acceptance) /P /R=(roughness) /I={Island_area,Island_depth} W_IMFP,W_TMFP,thickness,AngleE,AngleHnu
		Endif
		Wave W_Results
		PeakTheoArea[i]=peakMultiplier[i]*PeakCross[i]*W_Results[peakLayer[i]]
	Endfor
	// ------------------------------------------- Results Linker ---------------------------------------------- //
	Variable CurrentLink,total_sum=Sum(PeakTheoArea),index
	PeakTheoAreaRatio[]=PeakTheoArea[p]/total_sum
	String LineLinks=""
	index=0
	s.Wavey[]=0
	For(i=0; i<numLines; i+=1)
		If(PeakLinks[i] != 0)
			CurrentLink = PeakLinks[i]
			If(StringMatch("", ListMatch(LineLinks, num2str(CurrentLink) ,";" )) == 1)
				s.Wavey[index] += PeakTheoArea[i]/total_sum
				For(k=i+1; k<numLines; k+=1)
					If(PeakLinks[k] == CurrentLink)
						s.Wavey[index] += PeakTheoArea[k]/total_sum
					Endif
				Endfor
				LineLinks+=num2str(CurrentLink)+";"
				Index +=1
			Endif
		Else
			LineLinks += "0;"
			s.Wavey[index] = PeakTheoArea[i]/total_sum
			Index += 1
		Endif
	Endfor
	// ------------------------------------------- | oooo oooo | ---------------------------------------------- //
	SetDataFolder backupFolder
End

Structure ILAMP_ARXPSFit
	wave W_coeff
	wave WaveY
	wave WaveX
	variable TheoryLevel
	variable ApproxLevel
	variable FixedIslandDepth
	variable FixIslandTo
	wave FullArpesAngle
	wave DataDim
	wave TotalDim
	variable DataNum
	variable Normtype
	variable SourceNorm
	variable SameDataLength
	String LinkCodes
Endstructure

Function FitArPesConfiguration(s) : fitFunc
	Struct ILAMP_ARXPSFit &s
	DFREF backupFolder=GetDataFolderDFR()
	SetDataFolder root:Packages:DatabaseXPS:FitDump
	
	Variable theory=s.TheoryLevel
	Variable i,j,k,numlines,numTotPoint
	String aux1
	
	WAVE IMFP_mat=root:Packages:DatabaseXPS:ValidatedModel:IMFP_Matrix
	NVAR matnumber=root:Packages:DatabaseXPS:ValidatedModel:LayerNumber
	NVAR pol=root:Packages:DatabaseXPS:Analyzer:Polarization_type
	NVAR acceptance=root:Packages:DatabaseXPS:Analyzer:Acceptance
	Make/O/N=(matnumber-1) thickness
	variable island_area=1
	variable island_depth=0
	variable roughness=0
	i=0
	switch(numpnts(s.w_coeff)-numpnts(thickness)-1)
		case 1:
			roughness=s.w_coeff[0]
			i=1
		break
		case 2:
			island_area=s.w_coeff[1]
			island_depth=s.w_coeff[0]
			i=2
		break
		case 3:
			island_area=s.w_coeff[2]
			island_depth=s.w_coeff[1]
			roughness=s.w_coeff[0]
			i=3
		break
	endswitch
	j=0	
	do
		thickness[j]=s.W_coeff[i]
		i+=1
		j+=1
	while(i<numpnts(s.W_coeff)-1)
	variable common_multiplier=s.W_Coeff[numpnts(s.W_coeff)-1]
	
	make/O/N=3 AngleHnu
	make/O/N=3 AngleE
	
	If(s.FixedIslandDepth)
		island_depth=sum(thickness,0,s.FixIslandTo-1)
	Endif
	Switch(numpnts(s.w_coeff)-numpnts(thickness)-1)
		case 2:
			s.w_coeff[0]=island_depth
		break
		case 3:
			s.w_coeff[1]=island_depth
		break
	Endswitch
	Island_area=island_area>1 ? 1 : island_area
	
	Wave PeakLayer,PeakCross,PeakMultiplier,PeakAsy,PeakKineticEnergy,PeakBindingEnergy,PeakTheoArea,PeakTheoAreaRatio,PeakLinks
	Wave/T PeakName
	Make/O/N=(matnumber) W_IMFP,W_TMFP
	Numlines=numpnts(PeakName)
	NumTotPoint=numpnts(s.waveX)
	Variable currentPeak=0,total_sum=0
	s.TotalDim[]=Sum(S.DataDim,0,p)
	
	Variable CurrentLink,index // Extra variables for linking //
	String LineLinks="",CompleteLinks="",LocalList=""
	s.Wavey[]=0
	
	For(k=0;k<numlines;k+=1)
		If(PeakLinks[k]!=0)
			CurrentLink = PeakLinks[k]
			If(StringMatch ("",ListMatch( LineLinks, num2str(CurrentLink) ,";" )) == 1 )
				LineLinks+=num2str(CurrentLink)+";"
				CompleteLinks+=num2str(k)
				For(j=k+1;j<numlines;j+=1)
					If(PeakLinks[j]==PeakLinks[k])
						CompleteLinks+=","+num2str(j)
					Endif	
				Endfor
				CompleteLinks+=";"
			Endif
		Else
			CompleteLinks+=num2str(k)+";"
			LineLinks += "0;"
		Endif
	Endfor
			
	If(s.SameDataLength)
		For(i=0;i<s.DataDim[0];i+=1)
			AngleHnu[]=s.FullArpesAngle[i][3+p]
			AngleE[]=s.FullArpesAngle[i][p]
			For(j=0;j<numLines;j+=1)
				W_IMFP[]=IMFP(IMFP_mat[0][p],IMFP_mat[1][p],IMFP_mat[2][p],IMFP_mat[3][p],PeakKineticEnergy[j])
				For(k=0;k<matnumber;k+=1)
					aux1="TMFP_Parameter_Layer_"+num2str(k)
					Wave TMFP_param=root:Packages:DatabaseXPS:ValidatedModel:$aux1
					W_TMFP[k]=TMFP(TMFP_param,IMFP_mat[2][k],PeakKineticEnergy[j])
				Endfor
				If(pol==1)
					CalculateXPSAreaXop/A=(PeakAsy[j]) /T=(s.ApproxLevel) /M=(theory) /K=(acceptance) /R=(roughness) /I={Island_area,Island_depth} W_IMFP,W_TMFP,thickness,AngleE,AngleHnu
				Else
					CalculateXPSAreaXop/A=(PeakAsy[j]) /T=(s.ApproxLevel) /M=(theory) /K=(acceptance) /P /R=(roughness) /I={Island_area,Island_depth} W_IMFP,W_TMFP,thickness,AngleE,AngleHnu
				Endif
				Wave W_Results
				PeakTheoArea[j]=peakMultiplier[j]*PeakCross[j]*W_Results[peakLayer[j]]
			Endfor
			
			// ------------------------------------------- Results Linker ---------------------------------------------- //
			Index=0
			LineLinks=""
			Total_sum=Sum(PeakTheoArea)
			PeakTheoAreaRatio[]=PeakTheoArea[p]/total_sum
			
			If(s.normtype-2>0)
				Total_sum=0
				LocalList=StringFromList(s.normtype-3,CompleteLinks,";")
				for(k=0;k<itemsInList(LocalList,",");k+=1)
					j=Str2num(StringFromList(k,LocalList,","))
					Total_sum+=PeakTheoArea[j]
				endfor
				PeakTheoAreaRatio[]=PeakTheoArea[p]/total_sum
			Endif
							
			For(j=0; j<numLines; j+=1)
				If(PeakLinks[j] != 0)
					CurrentLink = PeakLinks[j]
					If(StringMatch("", ListMatch(LineLinks, num2str(CurrentLink) ,";" )) == 1)// ----------- Linked Peaks (non joined) -----------
						Switch(s.normType)
							Case 1:
								S.Wavey[i+s.DataDim[0]*index]=common_multiplier*PeakTheoArea[j]
								If(s.SourceNorm)
									s.Wavey[i+s.DataDim[0]*index]*=Cos(AngleE[2])
								Endif
							Break
							Default:
								S.Wavey[i+s.DataDim[0]*index]=PeakTheoAreaRatio[j]
							Break
						Endswitch
						For(k=j+1; k<numLines; k+=1)
							If(PeakLinks[k] == CurrentLink)
								Switch(s.normType)
									Case 1:
										If(s.SourceNorm)
											S.Wavey[i+s.DataDim[0]*index]+=common_multiplier*PeakTheoArea[k]*Cos(AngleE[2])
										Else
											S.Wavey[i+s.DataDim[0]*index]+=common_multiplier*PeakTheoArea[k]
										Endif
									Break
									Default:
										S.Wavey[i+s.DataDim[0]*index]+=PeakTheoAreaRatio[k]
									Break
								Endswitch
							Endif
						Endfor
						LineLinks+=num2str(CurrentLink)+";"
						Index +=1
					Endif
				Else // -------------- Non Linked Peaks --------------
					Switch(s.normType)
						Case 1:
							If(s.SourceNorm)
								S.Wavey[i+s.DataDim[0]*index]=common_multiplier*PeakTheoArea[j]*Cos(AngleE[2])
							Else
								s.Wavey[i+s.DataDim[0]*index]=common_multiplier*PeakTheoArea[j]
							Endif
						Break
						Default:
							S.Wavey[i+s.DataDim[0]*index]=PeakTheoAreaRatio[j]
						Break
					Endswitch
					linelinks+="0;"
					Index+=1
				Endif
			Endfor
		Endfor // ---------------------------------- End of angular position cycle
	Else
		For(i=0;i<numTotPoint;i+=1)  //---------------------Unevenly scaled angular ARXPS calculation cycle-------------------------------------------------- //
			currentPeak=0 //find the current X level
			For(k=0;k<s.DataNum;k+=1)
				if(i>=s.TotalDim[k])
					currentPeak+=1
				endif
			Endfor
			AngleHnu[]=s.FullArpesAngle[i][3+p]
			AngleE[]=s.FullArpesAngle[i][p]
			For(j=0;j<numLines;j+=1)
				W_IMFP[]=IMFP(IMFP_mat[0][p],IMFP_mat[1][p],IMFP_mat[2][p],IMFP_mat[3][p],PeakKineticEnergy[j])
				for(k=0;k<matnumber;k+=1)
					aux1="TMFP_Parameter_Layer_"+num2str(k)
					wave TMFP_param=root:Packages:DatabaseXPS:ValidatedModel:$aux1
					W_TMFP[k]=TMFP(TMFP_param,IMFP_mat[2][k],PeakKineticEnergy[j])
				endfor
				if(pol==1)
					CalculateXPSAreaXop/A=(PeakAsy[j]) /T=(s.ApproxLevel) /M=(theory) /K=(acceptance) /R=(roughness) /I={Island_area,Island_depth} W_IMFP,W_TMFP,thickness,AngleE,AngleHnu
				else
					CalculateXPSAreaXop/A=(PeakAsy[j]) /T=(s.ApproxLevel) /M=(theory) /K=(acceptance) /P /R=(roughness) /I={Island_area,Island_depth} W_IMFP,W_TMFP,thickness,AngleE,AngleHnu
				endif
				wave W_Results
				PeakTheoArea[j]=peakMultiplier[j]*PeakCross[j]*W_Results[peakLayer[j]]
			Endfor
			
			Index=0
			LineLinks=""
			Total_sum=Sum(PeakTheoArea)
			PeakTheoAreaRatio[]=PeakTheoArea[p]/total_sum
			
			If(s.normtype-2>0)
				Total_sum=0
				LocalList=StringFromList(s.normtype-3,CompleteLinks,";")
				for(k=0;k<itemsInList(LocalList,",");k+=1)
					j=Str2num(StringFromList(k,LocalList,","))
					Total_sum+=PeakTheoArea[j]
				endfor
				PeakTheoAreaRatio[]=PeakTheoArea[p]/total_sum
			Endif
			
			
			CurrentLink = Str2Num(StringFromList(currentPeak,s.linkCodes,";")) 
			LocalList=StringFromList(currentPeak,CompleteLinks,";")
			for(k=0;k<itemsInList(LocalList,",");k+=1)
				j=Str2num(StringFromList(k,LocalList,","))
				Switch(s.normType)
					Case 1:
						If(s.SourceNorm)
							S.Wavey[i]+=common_multiplier*PeakTheoArea[j]*Cos(AngleE[2])
						Else
							S.Wavey[i]+=common_multiplier*PeakTheoArea[j]
						Endif
					Break
					Default:
						S.Wavey[i]+=PeakTheoAreaRatio[j]
					Break
				Endswitch
			Endfor	
		Endfor
	Endif
	SetDataFolder backupFolder
End