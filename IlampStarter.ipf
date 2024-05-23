#pragma rtGlobals=3		// Use modern global access method.
#pragma hide=1
#if(exists("calculateddfxop") && exists("calculateXPSAreaXop") && exists("calculateXPSAreaMSxop"))

#include "AnalyzerParametersSetup"
#include "PeriodicTable for XPSv3d"
#include "ModelLayoutPanel"
#include "ModelCalculationPanel"
#include "ScientaTXTfinal"
#include "VAMAS_loader"
#include "VAMAS_saver"
#include "SimulationExternalPanels"
#include "ExpDataAnalysisPanel"
#include "IMFP_TMFP_panel"
#include "IMFP_TMFP_aux"
#include "ILAMP_Quantification"
#include "IlampPreferences"
#include "BatchOperations"
#include "ILAMP_Pictures"
#include "MatrixOperations"
#include "MatrixOperationPanel"
#include "AutoSimulationPanel"

#if(IgorVersion() >= 6.31)
#include <PopUpWaveSelector>
#else
#include "backup_PopUpWaveSelector"
#endif

#if(IgorVersion() >= 6.31)
#include <Multi-peak fitting 2.0>
#else
#include "backup_Multi-peak fitting 2.0"
#endif
#include "ExtraFitFunctions"

Static StrConstant kPackageName = "ILAMP XPS package"
Static StrConstant kPreferencesFileName = "XPSPackagePreferences.bin"
Static Constant kPreferencesRecordID = 0

Structure GeneralXPSParameterPrefs
	uint32 WelcomeScreenAtStartup
	uint32 WhatToDo
	uint32 version
	double thetaI
	double thetaO
	double PhiO
	uint32 WhatPol
	double ThetaPol
	double Acceptance
	double Trans1
	double Trans2
	double Trans3
	double defaultPhotonEnergy
	double defaultWorkF
	uchar dataDir[100]
	uint32 IgorSerial
	uint32 AutoSaveOpt
	uint32 PanelSizeOpt
	double CompAccuracy
	double CompAccuracyDDF
	uint32 CompDefaultMethod
	double CompLossMult
	double linethickness
EndStructure

Static Function IgorStartOrNewHook (igorApplicationNameStr)
	String igorApplicationNameStr

	variable testS=str2num(igorinfo(5))
	Make/O/N=0 dummy
	Try
		CalculateDDFxop /S=(testS) /M=0 dummy,dummy,dummy,dummy,dummy;abortOnRTE
	Catch
		doalert 0, "Wrong Serial Code. BriXias package can't be loaded."
		killwaves/Z dummy
		Return -1
	Endtry
	Killwaves/Z dummy
	
	STRUCT GeneralXPSParameterPrefs prefs
	LoadPackagePreferences kPackageName, kPreferencesFileName, kPreferencesRecordID, prefs
	If(V_flag!=0 || V_bytesRead==0 || prefs.WelcomeScreenAtStartup==1)
		NewPanel/N=ILAMPWelcomePanel /K=2/W=(100,100,750,360) as "BriXias welcome screen"
		modifypanel fixedsize=1,noedit=1
		ModifyPanel cbRGB=(65534,65534,65534)
		SetDrawLayer UserBack
		SetDrawEnv fname= "Verdana",fsize= 28
		DrawText 43,64,"BriXias Package"
		SetDrawEnv fname= "Verdana"
		DrawText 45,84,"for Igor Pro ® "
		SetDrawEnv linethick= 1.5
		DrawLine 45,100,394,100
		CheckBox ILAMPStartupDontAskMeAgain,pos={349,210},size={268,17},title="Remember this setting at startup"
		CheckBox ILAMPStartupDontAskMeAgain,labelBack=(47872,47872,47872)
		CheckBox ILAMPStartupDontAskMeAgain,font="Verdana",value= 0
		Button ILAMPStartPanelLoadPackage,pos={70,120},size={227,57},title="Load BriXias Package"
		Button ILAMPStartPanelLoadPackage,font="Verdana",fSize=12,fStyle=2
		Button ILAMPStartPanelLoadPackage,fColor=(65535,65535,65535),proc=StartXPSPackageButton
		
		Button ILAMPStartPaneldontLoad,pos={337,120},size={227,57},title="Keep using Igor Pro"
		Button ILAMPStartPaneldontLoad,help={"The XPS package can be loaded at any time within the \"XPS utilities\" menu."}
		Button ILAMPStartPaneldontLoad,font="Verdana",fSize=12,fStyle=2
		Button ILAMPStartPaneldontLoad,fColor=(65535,65535,65535),proc=DontStartXPSPackageButton
		
		Button ILAMPStartPanelGuide,pos={72,201},size={104,35},proc=StartXPSPackageButton,title="BriXias Guide"
		Button ILAMPStartPanelGuide,font="Verdana",fSize=12,fStyle=2
		Button ILAMPStartPanelGuide,fColor=(65535,65535,65535)


		Execute/Z/Q/P "dowindow/K table0"
	else
		if(prefs.WhatToDo==1)
			Load_XPS_Data()
		endif
	endif
	if(IgorVersion() >= 7.0 && ScreenResolution>100)
		execute/Q/Z "setigoroption panelresolution=72"
		print "Panel rescaling just update for high-dpi backward compatibility."
		print "If needed, type 'setigoroption panelresolution=screenresolution' to revert the action."
	endif
End

function StartXPSPackageButton(ctrlname) : buttonControl
	string ctrlname
	strswitch(ctrlname)
		case "ILAMPStartPanelGuide":
			DisplayHelpTopic "BriXias package introduction"
		break
		case "ILAMPStartPanelLoadPackage":
			STRUCT GeneralXPSParameterPrefs prefs
			LoadPackagePreferences kPackageName, kPreferencesFileName, kPreferencesRecordID, prefs
			controlinfo/W= ILAMPWelcomePanel ILAMPStartupDontAskMeAgain
			if(V_Value==1)
				prefs.WelcomeScreenAtStartup=0
				prefs.WhatToDo=1
				SavePackagePreferences/FLSH=1 kPackageName, kPreferencesFileName, kPreferencesRecordID, prefs
			endif
			dowindow/K ILAMPWelcomePanel
			Load_XPS_Data()
		break
	endswitch
end

function DontStartXPSPackageButton(ctrlname) : buttonControl
	string ctrlname
	STRUCT GeneralXPSParameterPrefs prefs
	LoadPackagePreferences kPackageName, kPreferencesFileName, kPreferencesRecordID, prefs
	controlinfo/W= ILAMPWelcomePanel ILAMPStartupDontAskMeAgain
	if(V_Value==1)
		prefs.WelcomeScreenAtStartup=1
		prefs.WhatToDo=2
		SavePackagePreferences/FLSH=1 kPackageName, kPreferencesFileName, kPreferencesRecordID, prefs
	endif
	dowindow/K ILAMPWelcomePanel
end

Menu "XPS utilities",dynamic
	MenuString(0),/Q,Load_XPS_Data()
	MenuString(1),/Q,CreatePeriodicPanel()
	MenuString(2),/Q,CreateAnalyzerSetup_panel() 
	MenuString(3),/Q,CreateIMFP_Panel()
	MenuString(4),/Q,CreateModelLayoutPanel()
	MenuString(5),/Q,CreateAutoSimPanel()//
	MenuString(6),/Q,CreateModelCalculationPanel()
	MenuString(8),/Q,CreateExpDataTaskPanel()
	Submenu "Special data file"
		MenuString(24),/Q,Scienta_Panel()
		MenuString(7),/Q,Create_VAMAS_loader_Panel()
		MenuString(17),/Q,Create_VAMAS_saver_Panel()
		MenuString(9)
		MenuString(23),/Q,ILAMPQ#GeneralLoadAndReverse()
	End
	Submenu "Batch operations"
		MenuString(13),/Q,Create_IndexWaveCreator_Panel()
		MenuString(14),/Q,Create_IndexDisplay_panel()
		MenuString(9)
		MenuString(16),/Q,fStartMultipeakFit2()
		MenuString(15),/Q,Create_BatchFit_Panel()
		MenuString(9)
		MenuString(18),/Q,Create_BatchBKG_panel()
		MenuString(19),/Q,Create_BatchAlign_panel()
	End
	submenu "Matrix operations"
		MenuString(20),/Q,Create_MatrixPack_panel()
		MenuString(21),/Q,Create_MatrixExplode_panel()
		menuString(22),/Q,Create_MatrixOpPanel(0)
	end
	MenuString(9)
	MenuString(10),/Q,Create_ILAMPprefsPanel()
	MenuString(11),/Q,DisplayHelpTopic "BriXias package introduction[BriXias Guide Index]"
	MenuString(12),/Q,IlampShutdown()
End

Function/S MenuString(i)
	variable i
	string nomeMenu
	variable loaded,validated
	validated=NumVarOrDefault("root:Packages:DatabaseXPS:ModelReady", 0)
	loaded=NumVarOrDefault("root:Packages:DatabaseXPS:data_loaded", 0)
	If(loaded==0)
		switch(i)
			case 0:		
				nomeMenu="Load databases..."
			break
			case 24:		
				nomeMenu="Load Scienta .txt..."
			break
			case 7:		
				nomeMenu="Load VAMAS file..."
			break
			case 8:		
				nomeMenu="Data operations panel..."
			break
			case 9:
				nomeMenu="-"
			break
			case 10:
				nomeMenu="Preferences..."
			break
			case 11:
				nomeMenu="Help..."
			break
			case 13:
				nomeMenu="Generate Index wave..."
			break
			case 14:
				nomeMenu="Display Index wave..."
			break
			case 15:
				nomeMenu="Batch Fitting..."
			break
			case 16:
				nomeMenu="Start multi peak fit..."
			break
			case 17:
				nomeMenu="Export to VAMAS..."
			break
			case 18:
				nomeMenu="Background removal..."
			break
			case 19:
				nomeMenu="Spectra alignment..."
			break
			case 20:
				nomeMenu="Pack spectra into matrix..."
			break
			case 21:
				nomeMenu="Unpack matrix to spectra..."
			break
			case 22:
				nomeMenu="General matrix operation panel..."
			break
			case 23:
				nomeMenu="General text file load and reverse..."
			break
			default:						
				nomeMenu=""
			break				
		endswitch
	else
		switch(i)
			case 0:		
				nomeMenu="Re-load databases..."
			break					
			case 1:		
				nomeMenu="XPS Quantification..."
			break					
			case 2:		
				nomeMenu="Analyzer set-up..."
			break					
			case 3:		
				nomeMenu="IMFP-TMFP database..."
			break					
			case 4:		
				nomeMenu="Model layout..."
			break	
			case 5:
				nomeMenu="AutoSim"
			break
			case 6:
				if(validated==0) 
					nomeMenu=""
				else 
					nomeMenu="Simulation Panel..."
				endif
			break	
			case 24:		
				nomeMenu="Load Scienta txt..."
			break
			case 7:		
				nomeMenu="Load VAMAS file..."
			break
			case 8:		
				nomeMenu="Data operations panel..."
			break	
			case 9:
				nomeMenu="-"
			break
			case 10:
				nomeMenu="Preferences..."
			break
			case 11:
				nomeMenu="Help..."
			break
			case 12:
				nomeMenu="Safely remove the package"
			break
			case 13:
				nomeMenu="Generate Index wave..."
			break
			case 14:
				nomeMenu="Display Index wave..."
			break
			case 15:
				nomeMenu="Batch Fitting..."
			break
			case 16:
				nomeMenu="Start multi peak fit..."
			break
			case 17:
				nomeMenu="Export to VAMAS..."
			break
			case 18:
				nomeMenu="Background removal..."
			break
			case 19:
				nomeMenu="Spectra alignment..."
			break
			case 20:
				nomeMenu="Pack spectra into matrix..."
			break
			case 21:
				nomeMenu="Unpack matrix to spectra..."
			break
			case 22:
				nomeMenu="General matrix operation panel..."
			break
			case 23:
				nomeMenu="General text file load and reverse..."
			break
			default:						
				nomeMenu=""
			break					
		endswitch
	endif
	return nomeMenu
end

Function IlampSaveHookFunc(rN,fileName,path,type,creator,kind)
	Variable rN,kind
	String fileName,path,type,creator
	if(exists("root:Packages:DatabaseXPS:data_loaded"))
		doalert 1,"Remove the BriXias package before file saving?"
		if(V_flag==1)
			IlampShutDown()
		endif
	endif
	return 0	
end

Function Load_XPS_Data()// Package start-up
	STRUCT GeneralXPSParameterPrefs prefs
	LoadPackagePreferences kPackageName, kPreferencesFileName, kPreferencesRecordID, prefs
	If(V_flag!=0 || V_bytesRead==0 || prefs.version<110)	
		print "Wrong installation. Please re-install the BriXias package"
		return -1;
	endif
	if(prefs.AutoSaveOpt)
		SetIgorHook /L BeforeExperimentSaveHook=IlampSaveHookFunc
	endif
	dowindow/K ILAMPWelcomePanel
	string percorso=prefs.dataDir
	NewPath Database_Folder percorso
	DFREF saveDFR = GetDataFolderDFR()
	
	newdatafolder/O/S root:Packages
	newdatafolder/O/S root:Packages:DatabaseXPS
	variable/G data_loaded=1
	Variable/g ph_energy,work_f,bar_multi,active_graph_scale
	string/g lista_scelte=""
	string/g active_graph=""

	ph_energy=1253.6
	work_f=5
	bar_multi=0.3
	active_graph_scale=1
	Variable/G ModelReady=0
	
	make/o/n=1 pos_peaks,Be_peaks,Xs_peaks,Xs_peaks_au
	make/o/n=0 pos_peaks_Au,Be_peaks_Au
	make/o/n=1/T Name_peaks_Au
	make/o/n=1/T Name_peaks
	make/o/n=0/T Graph_labels
	make/o/n=0 temp_calcolo
	make/T/o/n=1 temp_nomi_calcolo
	make/o/n=0 temp_Xs,graph_int,graph_pos
	
	newdatafolder/O/S root:Packages:DatabaseXPS:AnalysisDump
	newdatafolder/O/S root:Packages:DatabaseXPS:XPSLevels
	loaddata/O/P=database_folder "dataxpsTable.pxp"
	loaddata/O/P=database_folder "dataAugerFull.pxp"
	newdatafolder/O/S root:Packages:DatabaseXPS:CrossSec
	loaddata/O/P=database_folder "dataYehLindau.pxp"
	newdatafolder/O/S root:Packages:DatabaseXPS:CrossSec:TMY
	loaddata/O/P=database_folder "NefCompleteTable.pxp"
	newdatafolder/O/S root:Packages:DatabaseXPS:TMFP
	loaddata/O/P=database_folder "DataTMFP.pxp"
	newdatafolder/O/S root:Packages:DatabaseXPS:IMFP
	loaddata/O/P=database_folder "DataIMFP.pxp"
	newdatafolder/O/S root:Packages:DatabaseXPS:Analyzer
	loaddata/O/P=database_folder "TransFuncDB.pxp"
	loaddata/O/P=database_folder "TransFuncRetriever.pxp"
	LoadPackagePreferences kPackageName, kPreferencesFileName, kPreferencesRecordID, prefs
	variable/G asymmetryAngle
	variable/G Polarization_type
	variable/G thetaI
	variable/G thetaO
	variable/G PhiO
	variable/G thetaPol
	variable/G acceptance
	variable result 
	If(V_flag!=0 || V_bytesRead==0)	//default numerical values
		asymmetryAngle=54.74/180*Pi
		Polarization_type=1
		thetaI=54.74
		thetaO=0
		PhiO=180
		thetaPol=0
		Acceptance=10
		make/O/N=3 vecIn,vecOut,VecPol
		vecIn={1*Sin(thetaI/180*Pi),0,Cos(thetaI/180*Pi)}
		vecOut={Cos(PhiO/180*Pi)*Sin(thetaO/180*Pi),Sin(PhiO/180*Pi)*Sin(thetaO/180*Pi),Cos(thetaO/180*Pi)}
		vecPol={Cos(thetaPol/180*Pi),Sin(thetaPol/180*Pi),0}
		make/O/N=3 TransCoeff
		TransCoeff[]= p==0 ? 1 : 0
		prefs.version=100
		prefs.thetaI=thetaI
		prefs.thetaO=thetaO
		prefs.PhiO=PhiO
		prefs.WhatPol=polarization_type
		prefs.ThetaPol=thetaPol
		prefs.Acceptance=Acceptance
		prefs.Trans1=TransCoeff[0]
		prefs.Trans2=TransCoeff[1]
		prefs.Trans3=TransCoeff[2]
		prefs.DefaultPhotonEnergy=1253.6
		prefs.DefaultWorkF=5.0
		prefs.IgorSerial=str2num(IgorInfo(5))
		prefs.AutoSaveOpt=1
		prefs.PanelSizeOpt=2
		prefs.CompAccuracy=4
		prefs.CompAccuracyDDF=6
		prefs.CompDefaultMethod=2
		prefs.CompLossMult=1
		prefs.linethickness=1
		SavePackagePreferences/FLSH=1 kPackageName, kPreferencesFileName, kPreferencesRecordID, prefs
		if(V_flag==0) 
	 		Print "Default preferences stored."
		endif
	else
		Print "default preferences loaded"
		Polarization_type=prefs.WhatPol
		thetaI=prefs.ThetaI
		thetaO=prefs.thetaO
		PhiO=prefs.phiO
		thetaPol=prefs.thetaPol
		Acceptance=prefs.Acceptance
		asymmetryAngle=54.74/180*Pi
		
		make/O/N=3 vecIn,vecOut,VecPol
		vecIn={1*Sin(thetaI/180*Pi),0,Cos(thetaI/180*Pi)}
		vecOut={Cos(PhiO/180*Pi)*Sin(thetaO/180*Pi),Sin(PhiO/180*Pi)*Sin(thetaO/180*Pi),Cos(thetaO/180*Pi)}
		vecPol={Cos(thetaPol/180*Pi),Sin(thetaPol/180*Pi),0}
		
		make/O/N=3 temp_pol
		make/O/N=(3,3) matPol
		If(polarization_Type==1)
			result = matrixDot(VecIn,VecOut)
			asymmetryAngle=Acos(result)
		else
			MatPol={{Cos(thetaI/180*Pi),0,-Sin(thetaI/180*Pi)},{0,1,0},{Sin(thetaI/180*Pi),0,Cos(ThetaI/180*Pi)}}
			///O result = (MatPol x VecPol ) . VecOut
			//MatrixOp/O temp_pol = (MatPol x VecPol )
			MatrixMultiply MatPol,VecPol
			wave M_product
			result = matrixDot(M_product,VecOut)
			VecPol=temp_pol 
			asymmetryAngle=Acos(result)
			If(numtype(asymmetryAngle)==2)
				asymmetryAngle=Pi
			endif
		endif
		killwaves temp_pol,matpol
		
		make/O/N=3 TransCoeff
		TransCoeff[0]=prefs.Trans1
		TransCoeff[1]=prefs.Trans2
		TransCoeff[2]=prefs.Trans3
	endif
	
	newdatafolder/O/S root:Packages:DatabaseXPS:ModelLayout
	Variable/G IslandDepth=0
	Variable/G IslandAreaRatio=1
	Variable/G SurfaceRoughness=0
	Variable/G OverlayerNumber=1
	Variable/G NumberMats=1
	Variable/G NumberSims=1

	String/G DB_element_list
	Make/O/N=(OverlayerNumber) Layer_thickness
	make/O/N=(OverlayerNumber+1) LayerMatDbEntry
	make/T/O/N=(OverlayerNumber+1) LayerMatDbName
	make/O/N=(2,NumberMats) MatDBEntryMatrix
	make/T/O/N=(2,NumberMats) MatNamesMatrix
	make/O/N=(NumberMats) ThicknessMatrix=5
	wave/T list_DB=root:Packages:DatabaseXPS:IMFP:Name_eti
	LayerMatDbEntry[]=p+1
	LayerMatDbName[]=list_Db[p]
	Layer_thickness[0]=10
	MatNamesMatrix[][0]=list_Db[p]
	MatDBEntryMatrix[][0]=p+1
	
	newdatafolder/O/S root:Packages:DatabaseXPS:AuxData
	loaddata/O/P=database_folder "HTable.pxp"
	loaddata/O/P=database_folder "ColorTable.pxp"
	newdatafolder/O/S root:Packages:DatabaseXPS:ValidatedModel
	newdatafolder/O/S root:Packages:DatabaseXPS:TouVars
	variable/G Btou = 800
	variable/G Ctou = 300
	variable/G Dtou = 1900
	variable/G MPWtou = 1.5
	variable/G Gaptou = 0
	KillPath Database_Folder

	SetDataFolder saveDFR
	// active panel window killer
	dowindow/K ScientaTxtLoader
	dowindow/K PeriodicTable
	dowindow/K AnalyzerSetupPanel
	dowindow/K IMFP_TMFP_panel
	dowindow/K ModelLayoutPanel
	dowindow/K ModelCalculationPanel
	dowindow/K expdatataskPanel
	dowindow/K AutoTFFitWindow
	dowindow/K TransFuncManagerPanel
	dowindow/K TFCalibrationAreaPanel
	dowindow/K ILAMPQuantification
	dowindow/K MaterialDbTable
	dowindow/K ILAMPtouBKG
	dowindow/K IlampPrefs
	dowindow/K ElementProfileGraph
	dowindow/K DDF_Test_Graph
	dowindow/K IMFP_TMFP_Graph
	dowindow/K VMSLoaderPanel
	dowindow/K InsertExpDataSinglePanel
	dowindow/K ARXPSSimulationPanel
	dowindow/K ExpDataFitPanel
	dowindow/K lineBook
	dowindow/K IndexDisplayPanel
	dowindow/K IndexWaveCreatorPanel
	dowindow/K BatchFitPanel
	dowindow/K BatchBKGPanel
	dowindow/K BatchAlignPanel
	dowindow/K MatrixExplodePanel
	dowindow/K MatrixPackPanel
	dowindow/K BriXias_MatrixOpPanel
	dowindow/K VMSsaverPanel 
	// TMY enabled by default since version 1.38
	enableTMY(1)
	//
End

Function IlampShutDown()
	NVAR data_loaded=root:Packages:DatabaseXPS:Data_loaded
	data_loaded=0
	
	dowindow/K ScientaTxtLoader
	dowindow/K PeriodicTable
	dowindow/K AnalyzerSetupPanel
	dowindow/K IMFP_TMFP_panel
	dowindow/K ModelLayoutPanel
	dowindow/K ModelCalculationPanel
	dowindow/K expdatataskPanel
	dowindow/K TransFuncManagerPanel
	dowindow/K AutoTFFitWindow
	dowindow/K TFCalibrationAreaPanel
	dowindow/K ILAMPQuantification
	dowindow/K MaterialDbTable
	dowindow/K ILAMPtouBKG
	dowindow/K IlampPrefs
	dowindow/K ElementProfileGraph
	dowindow/K DDF_Test_Graph
	dowindow/K IMFP_TMFP_Graph
	dowindow/K VMSLoaderPanel
	dowindow/K InsertExpDataSinglePanel
	dowindow/K ARXPSSimulationPanel
	dowindow/K ExpDataFitPanel
	dowindow/K lineBook
	dowindow/K IndexDisplayPanel
	dowindow/K IndexWaveCreatorPanel
	dowindow/K BatchFitPanel
	dowindow/K BatchBKGPanel
	dowindow/K BatchAlignPanel
	dowindow/K MatrixPackPanel
	dowindow/K MatrixExplodePanel
	dowindow/K BriXias_MatrixOpPanel
	dowindow/K VMSsaverPanel 
	
	KillDataFolder/Z root:Packages:DatabaseXPS
	if(V_flag!=0)
		Print "Some data in the DatabaseXPS folder is still in use. Only some databases will be removed."
		KillDataFolder/Z root:Packages:DatabaseXPS:AuxData
		KillDataFolder/Z root:Packages:DatabaseXPS:CrossSec:TMY
		KillDataFolder/Z root:Packages:DatabaseXPS:CrossSec
		KillDataFolder/Z root:Packages:DatabaseXPS:XPSLevels
		KillDataFolder/Z root:Packages:DatabaseXPS:TMFP
		KillDataFolder/Z root:Packages:DatabaseXPS:IMFP
	endif
	SetIgorHook /K BeforeExperimentSaveHook=IlampSaveHookFunc
end

#endif