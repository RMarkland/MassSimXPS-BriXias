#pragma rtGlobals=1		// Use modern global access method.
#pragma hide=1
static StrConstant kPackageName = "ILAMP XPS package"
static StrConstant kPreferencesFileName = "XPSPackagePreferences.bin"
static Constant kPreferencesRecordID = 0

Function CreateAutoSimPanel()
	If(datafolderexists("root:Packages:DatabaseXPS:ModelLayout"))
		DFREF saveDFR = GetDataFolderDFR()	
		setdatafolder root:Packages:DatabaseXPS:ModelLayout
		If(stringmatch(winlist("AutoSimPanel",";","") ,"")==0)
			dowindow/HIDE=0 /F AutoSimPanel
		else
			NVAR IslandDepth=:IslandDepth
			NVAR IslandAreaRatio=:IslandAreaRatio
			NVAR SurfaceRoughness=:SurfaceRoughness
			NVAR OverlayerNumber=:OverlayerNumber
			NVAR NumberMats=:NumberMats
			NVAR NumberSims=:NumberSims
			variable/g MatNumber=1
			SVAR DB_element_list=:DB_element_list
			OverlayerNumber=1
			
			Wave/T list_DB=root:Packages:DatabaseXPS:IMFP:Name_eti
			Wave Layer_thickness=root:Packages:DatabaseXPS:ModelLayout:Layer_thickness
			Wave/T LayerMatDbName=:LayerMatDbName
			wave/T MatNamesMatrix=:MatNamesMatrix
			
			variable i,j	
			Make/O/N=(OverlayerNumber+1) LayerMatDbEntry
			for(i=0;i<overlayerNumber+1;i+=1)
				Grep/Q/INDX/E=LayerMatDbName[i] list_DB
				Wave w_index
				LayerMatDbEntry[i]=W_index[0]+1
			endfor
			
			Make/O/N=(2,NumberMats) MatDbEntryMatrix
			for(i=0;i<2;i+=1)
				for(j=0;j<NumberMats;j+=1)
					Grep/Q/INDX/E=MatNamesMatrix[i][j] list_DB
					Wave w_index
					MatDbEntryMatrix[i][j]=w_index[0]
				endfor
			endfor
			
			OverlayerNumber=1
			Redimension/N=(overlayerNumber), Layer_Thickness
			Layer_Thickness[]=p*5+5
			Dowindow/K AutoSimPanel
			NewPanel /K=3 /W=(100,50,680,400) as "AutoSimPanel"
			ModifyPanel fixedsize=1,cbRGB=(65534,65534,65534),noedit=1,fixedsize=1
			Dowindow/C AutoSimPanel
			//--------------------------------------------------------------------//
//			 RedrawModelLayout2(1)
			//----------------------------------------------------------------------//
			SetDrawEnv fsize= 14
			DrawText 20,30,"Material Number"
	
			TabControl LayerTab,pos={10,30},size={560,150},labelBack=(60000,60000,65534)
			for(i=0;i<NumberMats;i+=1)
				TabControl LayerTab,tabLabel(i)=num2str(i)
			endfor
			TabControl LayerTab,value= 0,proc=ModelTabControl2
			
			Slider MatNumber,pos={72,31},size={300,52},limits={1,NumberMats,1},variable=MatNumber,vert= 0,proc=OverlayerSliderProc2,disable=1 //View disabled but calculations are still needed (don't delete)

			SetVariable IslandDepth,pos={335,192},size={200,24},title="Islands depth (Å)\\S \\M"
			SetVariable IslandDepth,help={"If 0, island will not be considered"}
			SetVariable IslandDepth,limits={0,550,1},value=IslandDepth,proc=set_Island_func2
			SetVariable IslandAreaRatio,pos={335,242},size={200,24},title="Islands Area ratio (%)\\S \\M"
			SetVariable IslandAreaRatio,limits={0,1,0.01},value=IslandAreaRatio,proc=set_Island_func2
			SetVariable SurfaceRoughness,pos={335,292},size={200,24},title="Surface Roughness (RMS, Å)\\S \\M"
			SetVariable SurfaceRoughness,help={"Note: the maximum value is the uppermost layer thickness"}
			SetVariable SurfaceRoughness,limits={0,Layer_thickness[0],1},value=SurfaceRoughness,proc=set_Island_func2
			
			SetVariable NumberMats, pos={20,192}, size={250,24}, title="Number of Materials to Simulate\\S \\M" //
			SetVariable NumberMats, limits={1,20,1}, value=NumberMats, proc=NumberMatControl	
			SetVariable	NumberSims, pos={20,242}, size={250,24}, title="Number of Simulations per Material\\S \\M"
			SetVariable NumberSims, limits={1,10000,1}, value=NumberSims//, Proc=
			//--------------------------------------------------------------------------------------------------------------------------------------------------------------------//	
			CreateDBInput("Film"+num2str(0),"AutoSimPanel",40,75,250,30,"Film (from DB)","DbPopupFuncFilm",MatNamesMatrix[0][0])
			CreateDBInput("Bulk"+num2str(0),"AutoSimPanel",40,110,250,30,"Bulk (from DB)","DbPopupFuncBulk",MatNamesMatrix[1][0])
			SetVariable $"ThicknessLayer"+num2str(0),pos={320,95},size={141,30},title="Thickness (Å)\\S \\M"
			SetVariable $"ThicknessLayer"+num2str(0),limits={0,300,1},value=ThicknessMatrix[0],proc=ThicknessVariableProc2


			struct WMTabControlAction  st
			st.tab=0
			ModelTabControl2(st)
			//---------------------------------------------------------------------------------------------------------------------------//
			Button SIMULATE,pos={20,281},size={235,50},proc=MegaRandomSimulate,title="\\Z18S I M U L A T E",fColor=(65535,65535,65535)


			Setdatafolder saveDFR
		endif
		Setdatafolder saveDFR
	else
		Print "Please, load databases first"
	endif
End

//-----------------------------------------------------Popup Functions--------------------------------------//

Function DbPopupFuncFilm(SvName,SVWin) : PopupMenuControl
	String SvName,SvWin
	
	variable current_tab
	sscanf SvName,"Film%f",current_tab
	wave DBnumbers=root:Packages:DatabaseXPS:ModelLayout:MatDBEntryMatrix
	wave/T DBnames=root:Packages:DatabaseXPS:ModelLayout:MatNamesMatrix
	
	Controlinfo/W=$SvWin $SvName
	DBnames[0][current_tab]=S_value
	string RegularE=S_value+"$"
	wave/T element_list_name=root:Packages:DatabaseXPS:IMFP:name_eti
	Grep/Q/INDX/E=regularE element_list_name
	wave W_index
		
	DBnumbers[0][current_tab]=W_index[0]
//	RedrawModelLayout(0)
end


Function DbPopupFuncBulk(SvName,SVWin) : PopupMenuControl
	String SvName,SvWin
	
	variable current_tab
	sscanf SvName,"Bulk%f",current_tab
	wave DBnumbers=root:Packages:DatabaseXPS:ModelLayout:MatDBEntryMatrix
	wave/T DBnames=root:Packages:DatabaseXPS:ModelLayout:MatNamesMatrix
	
	Controlinfo/W=$SvWin $SvName
	DBnames[1][current_tab]=S_value
	string RegularE=S_value+"$"
	wave/T element_list_name=root:Packages:DatabaseXPS:IMFP:name_eti
	Grep/Q/INDX/E=regularE element_list_name
	wave W_index
		
	DBnumbers[1][current_tab]=W_index[0]
//	RedrawModelLayout(0)
end

//-----------------------------------------------------TabControl functions---------------------------------------------//
Function ModelTabControl2(TC_Struct) : TabControl
	STRUCT WMTabControlAction &TC_Struct
	string nameVarControl,nameSvControl,nameBcontrol, nameSvControl2, nameBcontrol2
	variable i=0
	NVAR NumberMats=root:Packages:DatabaseXPS:ModelLayout:NumberMats
	do
		nameSvControl="Film"+num2str(i)
		nameSvControl2="Bulk"+num2str(i)
		NameBcontrol=nameSvControl+"_but"
		NameBcontrol2=nameSvControl2+"_but"
		
		nameVarControl="ThicknessLayer"+num2str(i)
		If(TC_struct.tab==i)
			SetVariable $nameSvControl,win=AutoSimPanel,disable=0
			SetVariable $nameSvControl2,win=AutoSimPanel,disable=0
			Button $nameBcontrol,win=AutoSimPanel,disable=0
			SetVariable $nameVarControl,win=AutoSimPanel,disable=0
			Button $nameBcontrol2,win=AutoSimPanel,disable=0
		else
			SetVariable $nameSvControl,win=AutoSimPanel,disable=1
			SetVariable $nameSvControl2,win=AutoSimPanel,disable=1
			Button $nameBcontrol,win=AutoSimPanel,disable=1
			SetVariable $nameVarControl,win=AutoSimPanel,disable=1
			Button $nameBcontrol2,win=AutoSimPanel,disable=1

		endif

		i+=1
	while(i<NumberMats)
//	RedrawModelLayout2(0)
End

//--------------------------------------------------------Select Material number----------------------------------------------------------//
Function NumberMatControl(ctrlName,varNum,varStr,varName)
	
	variable varNum
	string ctrlName, varName, varStr
	variable i=0,j=0
	string RegularE, nome1, nome2
	
	setdatafolder root:Packages:DatabaseXPS:ModelLayout
	make/T/O/N=(2,varNum) MatNamesMatrix
	make/O/N=(2,varNum) MatDBEntryMatrix
	make/O/N=(varNum) ThicknessMatrix=5
	Wave/T list_DB=root:Packages:DatabaseXPS:IMFP:Name_eti


	
	for(i=0;i<2;i+=1)
		j=0
		for(j=0;j<varNum;j+=1)
			nome1="Film"+num2str(j)
			nome2="Bulk"+num2str(j)
			if(stringmatch(MatNamesMatrix[i][j],""))
				MatNamesMatrix[i][j]=list_db[i+j]
				MatDBEntryMatrix[i][j]=i+j
			else
				RegularE=MatNamesMatrix[i][j]+"$"
				Grep/Q/INDX/E=RegularE list_DB
				Wave w_index
				MatDBEntryMatrix[i][j]=W_index[0]
			endif
			setvariable $nome1,win=AutoSimPanel,value=_STR:MatNamesMatrix[0][j]
			setvariable $nome2,win=AutoSimPanel,value=_STR:MatNamesMatrix[1][j]
		endfor
			
	endfor
	
	for(i=1;i<varNum;i+=1)
		CreateDBInput("Film"+num2str(i),"AutoSimPanel",40,75,250,30,"Film (from DB)","DbPopupFuncFilm",MatNamesMatrix[0][i])
		CreateDBInput("Bulk"+num2str(i),"AutoSimPanel",40,110,250,30,"Bulk (from DB)","DbPopupFuncBulk",MatNamesMatrix[1][i])
		SetVariable $"ThicknessLayer"+num2str(i),pos={320,95},size={141,30},title="Thickness (Å)\\S \\M"
		SetVariable $"ThicknessLayer"+num2str(i),limits={0,300,1},value=ThicknessMatrix[i],proc=ThicknessVariableProc2
	endfor

	
	i=0
	do	
		TabControl LayerTab,win=AutoSimPanel,tabLabel(i)=num2str(i)
		i+=1
	while(i<varNum)
	TabControl LayerTab,win=AutoSimPanel, value=0
	struct WMTabControlAction  st
	ModelTabControl2(st)

	If(i<21)
		do
			TabControl LayerTab,win=AutoSimPanel,tabLabel(i)=""			
			i+=1
		while(i<21)
	endif



//	RedrawModelLayout2(0)
//	setdatafolder backupFolder
End

//--------------------------------------------------------Select Layer number----------------------------------------------------------//
Function OverlayerSliderProc2(S_Struct) : SliderControl
	STRUCT WMSliderAction &S_Struct
	variable i=0
	DFREF backupFolder=GetdatafolderDFR()
	
	setdatafolder root:Packages:DatabaseXPS:ModelLayout
	variable/G OverlayerNumber=S_struct.Curval

	string nome,nomePopup
	make/O/N=(S_struct.Curval) Layer_thickness
	make/O/N=(S_struct.Curval+1) LayerMatDbEntry
	make/T/O/N=(S_struct.Curval+1) LayerMatDbName
	Wave/T list_DB=root:Packages:DatabaseXPS:IMFP:Name_eti
	string RegularE
	
	for(i=0;i<overlayerNumber+1;i+=1)
		nomePopUp="MaterialLayer"+num2str(i)
		if(stringmatch(LayerMatDbName[i],""))
			LayerMatDbName[i]=list_db[i]
			LayerMatDbEntry[i]=i
		else
			RegularE=LayerMatDbName[i]+"$"
			Grep/Q/INDX/E=RegularE list_DB
			Wave w_index
			LayerMatDbEntry[i]=W_index[0]
		endif
		setvariable $nomePopUp,win=AutoSimPanel, value=_STR:LayerMatDbName[i]
	endfor
	i=0
	Layer_thickness[]=5+p*5

End
//---------------------------------------------------------LayerThickness Func------------------------------------------------------------//
Function ThicknessVariableProc2(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum	// value of variable as number
	String varStr		// value of variable as string
	String varName	// name of variable
	variable i
	sscanf ctrlName,"ThicknessLayer%f",i
	NVAR lay_num=root:Packages:DatabaseXPS:ModelLayout:OverlayerNumber
	DFREF backupFolder=GEtDataFolderDFR()
	setdatafolder root:Packages:DatabaseXPS:ModelLayout:
	
	variable/G SurfaceRoughness
	If (lay_num>0&&i==0)
		SetVariable SurfaceRoughness,win=AutoSimPanel,disable=0,limits={0,varNum,1}
		if (SurfaceRoughness>varNum)
			SurfaceRoughness=varNum
		endif
	endif
//	RedrawModelLayout2(0)
	setdatafolder backupFolder
End
//--------------------------------------------------------Various SetVariable functions---------------------------------------------------//
Function set_Island_func2(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum	// value of variable as number
	String varStr		// value of variable as string
	String varName	// name of variable
	DFREF backupFolder=GEtDataFolderDFR()
	setdatafolder root:Packages:DatabaseXPS:ModelLayout
//	RedrawModelLayout2(0)
	setdatafolder backupFolder
End

// ----------------------------------------Model Validation--------------------------------------------------------------------------------------------------------- //
Function ValidateModel2 (ctrlName) : ButtonControl
	String ctrlName
	DFREF backupFolder=GetdatafolderDFR()
	
	If(stringmatch(winlist("IMFP_TMFP_panel",";","") ,"")==1)
//		CreateIMFP_Panel()
		dowindow/HIDE=1 /F  IMFP_TMFP_panel
	endif

	variable i,j,k
	NVAR mat_num = root:Packages:DatabaseXPS:ModelLayout:OverlayerNumber
	NVAR is_area =  root:Packages:DatabaseXPS:ModelLayout:IslandAreaRatio
	NVAR is_depth = root:Packages:DatabaseXPS:ModelLayout:IslandDepth
	NVAR rough = root:Packages:DatabaseXPS:ModelLayout:SurfaceRoughness
	Variable mat_num2=mat_num+1
	WAVE/T chosen_mat=root:Packages:DatabaseXPS:ModelLayout:LayerMatDbName
	WAVE Thick=root:Packages:DatabaseXPS:ModelLayout:Layer_thickness

	
	NVAR photon_energy=root:Packages:DatabaseXPS:ph_energy
	Variable ek=photon_energy*0.75
	Variable DDFasy=2
	
	if(stringmatch(ctrlname,"CalculateTestDDF")==1)
		prompt ek,"Electron kinetic energy (100-1500 eV):"
		prompt DDFasy,"XPS line asymmetry (0-2):"
		DoPrompt "Enter test DDF parameters", ek,DDFasy
		if (V_Flag)
			return -1								// User canceled
		endif
		if(ek<100 || ek>1500 ||  DDFasy>2 || DDFasy<0)
			doalert 0,"Wrong DDF test parameters."
		endif
	endif
	
	NVAR NValence = root:Packages:DatabaseXPS:IMFP:NValence
	NVAR energy_gap= root:Packages:DatabaseXPS:IMFP:Energy_gap
	NVAR density = root:Packages:DatabaseXPS:IMFP:MatDensity
	
	string nome_out;
	string nome_mat
	
	setdatafolder root:Packages:DatabaseXPS:ValidatedModel:
	variable/G Island_area=is_area
	variable/G Roughness=rough
	variable/G LayerNumber=mat_num2
	
	make/O/N=(mat_num2-1) Thickness	
	make/T/O/N=(mat_num2) LayerName	
	make/O/N=(mat_num2) TestIMFP,TestTMFP	
	
	Thickness[]=thick[p]
	LayerName[]=chosen_mat[p]
	variable/G Island_depth= is_depth
	
	make/O/N=(4,mat_num2) IMFP_Matrix
	//----------------------- string for elements selection
	string element_name
	wave/T ElementNameList=root:Packages:DatabaseXPS:TMFP:Data_NameZ
	wave/T XPSLineList=root:Packages:DatabaseXPS:XPSLevels:CompleteName
	wave/T XPSElementList=root:Packages:DatabaseXPS:XPSLevels:Element
	wave XPSLineEnergy=root:Packages:DatabaseXPS:XPSLevels:Energy
	wave XPSlineWidth=root:Packages:DatabaseXPS:XPSLevels:Total_Width
	wave XPSlineRatio=root:Packages:DatabaseXPS:XPSLevels:GL_ratio
	//----------------------- string for parameter grouping
	make/O/T/N=(1,2) ModelParametersMatrix
	string param_name
	//----------------------- wave for linking label
	string label_wave_name
	//---------------------------------------------------
	i=0
	do
		nome_mat=chosen_mat[i]
		if(mat_num2>1 &&  i!=mat_num2-1)
			InsertPoints/M=0 0,1,ModelParametersMatrix
			param_name=nome_mat + " thickness(Å)"
			ModelParametersMatrix[0][1]=num2str(thickness[i])
			ModelParametersMatrix[0][0]=param_name
		endif
		IdentifyMaterialName("",0,nome_mat,"") 
		Setdatafolder root:Packages:DatabaseXPS:ValidatedModel:
		NVAR atomic_weight = root:Packages:DatabaseXPS:IMFP:atomic_weight
		nome_out="TMFP_Parameter_Layer_"+num2str(i)
		Wave mat_control=root:Packages:DatabaseXPS:TMFP:material_composition
		Make/O/N=(numpnts(mat_control)) $nome_out
		wave tempw=root:Packages:DatabaseXPS:ValidatedModel:$nome_out
		
		tempw[]=mat_control[p]
		IMFP_Matrix[0][i]=atomic_weight
		IMFP_Matrix[1][i]=NValence
		IMFP_Matrix[2][i]=density
		IMFP_Matrix[3][i]=energy_gap
		
		testIMFP[i]=IMFP(atomic_weight,NValence,density,energy_gap,Ek)	
		testTMFP[i]=TMFP(mat_control,density,Ek)
		//---------------------setting up waves for line selection and linking
		label_wave_name="IsLinked"+num2str(i)
		nome_out="LineSelectorMat"+num2str(i)
		make/T/O/N=(1,6,2) $nome_out
		make/O/N=1 $label_wave_name
		wave labelwave=$label_wave_name
		wave/T CurrentLineSelector=$nome_out
		//---------------------necessary correction for calculate the relative atomic density in atoms/A^3--------//
		variable AtomSum = 0
		for(j=1;j<dimsize(tempw,0);j+=2)
			atomSum+=tempw[j]
		endfor
		//----------routine that retrieve the single XPS line for each element in each layer 
		for(j=0;j<numpnts(tempw)/2;j+=1)
			element_name="(?i)\\b"+elementNameList[tempw[2*j]-1]+"(?i)\\b"
			Grep/Q/INDX/E=element_name XPSElementList
			wave w_index
			if(numpnts(W_index)>0) //if some lines are found
				for(k=0;k<numpnts(W_index);k+=1) //add lines from the DB
					if(XPSLineEnergy[w_index[k]]<photon_energy) //add lines whose BE is less than photon energy
						InsertPoints/M=0 0,1,CurrentLineSelector
						CurrentLineSelector[0][0][1]=num2str(w_index[k])
						CurrentLineSelector[0][0][0]=nome_mat+" - "+XPSLineList[w_index[k]]
						CurrentLineSelector[0][1][0]=num2str(XPSLineEnergy[w_index[k]])
						CurrentLineSelector[0][2][0]=num2str(0)
						CurrentLineSelector[0][3][0]=num2str(XPSlineWidth[w_index[k]])
						CurrentLineSelector[0][4][0]=num2str(XPSlineRatio[w_index[k]])
						CurrentLineSelector[0][3][1]=num2str(CrossSec(w_index[k],photon_energy,0))
						CurrentLineSelector[0][4][1]=num2str(CrossSec(w_index[k],photon_energy,1))
						CurrentLineSelector[0][5][0]=num2str((density * 0.602214/atomic_weight) * tempw[2*j+1]/atomSum)
						//CurrentLineSelector[0][5][0]=num2str(density/atomic_weight*tempw[2*j+1]) - old brixias reference
						InsertPoints/M=0 0,1,labelwave
						labelwave[0]=0
					endif
				endfor
			endif		
		endfor
		deletepoints/M=0 (dimsize(CurrentLineSelector,0)-1),1,CurrentLineSelector
		deletepoints/M=0 (numpnts(labelwave)-1),1,labelwave
		//---------------------set-up matrix for list-box-----------------------------------
		nome_out="LineSelectorMatSel"+num2str(i)
		make/O/N=(dimsize(currentLineSelector,0),dimsize(currentLineSelector,1)) $nome_out
		wave LineSelectorMatSel=$nome_out
		LineSelectorMatSel[][]= q==0 ? (0x20) : (0x02)
		//------------------------------------cycle end------------------------------------	
		i+=1
	while(i<mat_num2)
	
	make/T/O/N=6 LineSelectorLegend
	LineSelectorLegend[0]="Material & XPS line"
	LineSelectorLegend[1]="B.E. (eV)"
	LineSelectorLegend[2]="Chem. shift"
	LineSelectorLegend[3]="Peak width"
	LineSelectorLegend[4]="GL ratio"
	LineSelectorLegend[5]="Atomic den."
	//thedious thickness reverser//
	make/O/N=(dimsize(modelParametersMatrix,0)-1) temp_thick
	make/T/O/N=(dimsize(modelParametersMatrix,0)-1) temp_thick_name
	
	temp_thick[]=str2num(ModelParametersMatrix[p][1])
	temp_thick_name[]=ModelParametersMatrix[p][0]
	reverse temp_thick
	ModelParametersMatrix[][1]=num2str(temp_thick[p])
	j=0
	for(i=numpnts(temp_thick)-1;i>=0;i-=1)
		modelParametersMatrix[i][0]=temp_thick_name[j]
		j+=1
	endfor
	killwaves/Z temp_thick,temp_thick_name
	
	if(island_area<1 && island_depth>0)
		InsertPoints/M=0 0,1,ModelParametersMatrix
		param_name="Island area ratio"
		ModelParametersMatrix[0][1]=num2str(island_area)
		ModelParametersMatrix[0][0]=param_name
			
		InsertPoints/M=0 0,1,ModelParametersMatrix
		param_name="Island depth (Å)"
		ModelParametersMatrix[0][1]=num2str(island_depth)
		ModelParametersMatrix[0][0]=param_name			
	endif
	
	if(roughness>0)
		InsertPoints/M=0 0,1,ModelParametersMatrix
		param_name="Roughness layer(Å)"
		ModelParametersMatrix[0][1]=num2str(roughness)
		ModelParametersMatrix[0][0]=param_name
	endif
	deletepoints/M=0 (dimsize(ModelParametersMatrix,0)-1),1,ModelParametersMatrix
	
	make/O/N=(dimsize(ModelParametersMatrix,0),dimsize(ModelParametersMatrix,1)) ModelParametersMatrixSel
	ModelParametersMatrixSel[][0]=4
	ModelParametersMatrixSel[][1]=2
		
	if(stringmatch(ctrlname,"CalculateTestDDF")==1)
		NVAR pol=root:Packages:DatabaseXPS:Analyzer:Polarization_type
		NVAR acceptance=root:Packages:DatabaseXPS:Analyzer:Acceptance
		STRUCT GeneralXPSParameterPrefs prefs
		LoadPackagePreferences kPackageName, kPreferencesFileName, kPreferencesRecordID, prefs
		If(V_flag!=0 || V_bytesRead==0 || prefs.version<110)	
			print "Wrong installation. Please re-install the ILAMP package"
			return -1;
		endif
		
		if(pol==1)
			Wave AngleE=root:Packages:DatabaseXPS:Analyzer:vecOut
			Wave AngleHnu=root:Packages:DatabaseXPS:Analyzer:vecIn
			CalculateDDFxop/A=(DDFasy)/M=0 /K=(Acceptance) /R=(roughness) /I={Island_area,Island_depth} testIMFP,testTMFP,thickness,AngleE,AngleHnu
			duplicate/O Calculated_DDF test_DDF_SL
			
			CalculateDDFxop/A=(DDFasy)/M=1 /K=(Acceptance) /R=(roughness) /I={Island_area,Island_depth} testIMFP,testTMFP,thickness,AngleE,AngleHnu
			duplicate/O Calculated_DDF test_DDF_Approx_An
			
			CalculateDDFxop/A=(DDFasy)/M=2 /K=(Acceptance) /R=(roughness) /I={Island_area,Island_depth} testIMFP,testTMFP,thickness,AngleE,AngleHnu
			duplicate/O Calculated_DDF test_DDF_Analytical
			
			CalculateDDFxop/A=(DDFasy)/M=3 /K=(Acceptance) /R=(roughness) /T=(prefs.CompAccuracyDDF) /I={Island_area,Island_depth} testIMFP,testTMFP,thickness,AngleE,AngleHnu
			duplicate/O Calculated_DDF test_DDF_MC
		else
			Wave AngleE=root:Packages:DatabaseXPS:Analyzer:vecOut
			Wave AngleHnu=root:Packages:DatabaseXPS:Analyzer:vecPol
			CalculateDDFxop/A=(DDFasy)/M=0 /K=(Acceptance) /P /R=(roughness) /I={Island_area,Island_depth} testIMFP,testTMFP,thickness,AngleE,AngleHnu
			duplicate/O Calculated_DDF test_DDF_SL
			
			CalculateDDFxop/A=(DDFasy)/M=1 /K=(Acceptance) /R=(roughness) /I={Island_area,Island_depth} testIMFP,testTMFP,thickness,AngleE,AngleHnu
			duplicate/O Calculated_DDF test_DDF_Approx_An
			
			CalculateDDFxop/A=(DDFasy)/M=2 /K=(Acceptance) /P /R=(roughness) /I={Island_area,Island_depth} testIMFP,testTMFP,thickness,AngleE,AngleHnu
			duplicate/O Calculated_DDF test_DDF_Analytical
			
			CalculateDDFxop/A=(DDFasy)/M=3 /K=(Acceptance) /P /R=(roughness) /T=(prefs.CompAccuracyDDF) /I={Island_area,Island_depth} testIMFP,testTMFP,thickness,AngleE,AngleHnu
			duplicate/O Calculated_DDF test_DDF_MC
			Killwaves Calculated_DDF
		endif
		variable normMC,normSL,NormTilin,NormApprox
		normSL=area(test_DDF_SL)
		normMC=area(Test_DDF_MC)
		normTilin=area(test_DDF_analytical)
		test_DDF_approx_An[]= numtype(test_DDF_approx_An)==2 ? 0 : test_DDF_approx_An[p]
		NormApprox=area(test_DDF_approx_An)
		test_DDF_SL/=normSL
		test_DDF_MC/=normMC
		test_DDF_analytical/=normTilin
		test_DDF_approx_An/=NormApprox
		
		variable errSL,errAnalytical,errApprox,StartValue=test_DDF_MC[0], numValue=numpnts(test_DDF_MC)
		duplicate/O test_DDF_SL BRItemp
		
		BRItemp[]=(test_DDF_MC[p]-test_DDF_SL[p])^2
		ErrSL	=	Sqrt(1/numValue*sum(BRItemp))/startValue*100	//abs((area(test_DDF_SL,0,50)-area(Test_DDF_MC,0,50))/area(test_DDF_SL,0,50))*100
		
		BRItemp[]=(test_DDF_MC[p]-test_DDF_approx_An[p])^2
		errApprox	=	Sqrt(1/NumValue*sum(BRItemp))/startValue*100		//abs((area(test_DDF_Approx_An,0,50)-area(Test_DDF_MC,0,50))/area(test_DDF_Approx_An,0,50))*100
		
		BRItemp[]=(test_DDF_MC[p]-test_DDF_Analytical[p])^2
		errAnalytical	=	Sqrt(1/NumValue*sum(BRItemp))/startValue*100		//abs((area(test_DDF_analytical,0,50)-area(Test_DDF_MC,0,50))/area(test_DDF_analytical,0,50))*100
		
		killwaves/Z BRItemp
		dowindow/K DDF_Test_Graph
		Display /K=1 /W=(188.25,69.5,711.75,389) test_DDF_SL,test_DDF_Approx_An,test_DDF_Analytical,test_DDF_MC
		dowindow/C DDF_Test_Graph
		ModifyGraph mode(test_DDF_MC)=2
		ModifyGraph lSize=1.2
		ModifyGraph rgb(test_DDF_SL)=(0,0,52224),rgb(test_DDF_MC)=(0,0,0)
		ModifyGraph rgb(test_DDF_Approx_An)=(30464,30464,30464)
		ModifyGraph grid=2
		ModifyGraph tick=2
		ModifyGraph mirror=1
		ModifyGraph minor=1
		ModifyGraph lblMargin(left)=9
		ModifyGraph notation=1
		ModifyGraph mode(test_DDF_MC)=4,marker(test_DDF_MC)=19,msize(test_DDF_MC)=1.5
		ModifyGraph lsize(test_DDF_MC)=1
		ModifyGraph msize(test_DDF_MC)=1.1
		Label left "D.D.F. (arb. units)"
		Label bottom "depth (Å)"
		SetAxis bottom 0,150
		string legendstr
		legendstr="Kinetic energy = "+num2str(eK)+" eV; Asymmetry = 2 \r\r"
		legendstr+="\\s(test_DDF_SL) DDF - Straight-line (ext. error: "+num2str(errSL)+" %) \r"
		legendstr+="\\s(test_DDF_Approx_An) DDF - Analytical Approximation (ext error: "+num2str(errApprox)+" %)\r"
		legendstr+="\\s(test_DDF_Analytical) DDF - Tilin formula (ext error: "+num2str(errAnalytical)+" %)\r"
		legendstr+="\\s(test_DDF_MC) DDF - Monte Carlo calculations "
		Legend/C/N=text0/J/X=16.75/Y=16.24 legendstr
	endif
	
	setdatafolder root:Packages:DatabaseXPS:
	if(stringmatch(ctrlname,"CalculateTestDDF")!=1)
		Variable/G ModelReady=1
//		dowindow/HIDE=1 AutoSimPanel
		If(stringmatch(winlist("ModelCalculationPanel",";","") ,"")==0)
			dowindow/K modelCalculationPanel
			CreateModelCalculationPanel()
		else
		   CreateModelCalculationPanel()
		endif
	endif
	setdatafolder backupFolder
End

/////////////////////////////////////////////////////////////////////////////

//----------------------------The Mega Simulation Function-----------------//
#include "ModelCalculationPanel"
#include "BulkSimulationFunctions"

Function MegaRandomSimulate (ctrlName)
	
	string ctrlName
	
	newpath/C savefolder, "C:Users:reidm:Documents:Training Data"
	
	setdatafolder root:Packages:DatabaseXPS:ModelLayout
	wave/T MatNamesMatrix
	wave ThicknessMatrix
	wave/T LayerMatDbName
	wave Layer_Thickness
	nvar NumberSims
	nvar NumberMats
	
	variable i,j
	
	for(i=0;i<NumberMats;i+=1)
	
		//Validating model
		setdatafolder root:Packages:DatabaseXPS:ModelLayout
//
		Layer_Thickness[0]=ThicknessMatrix[i]
		LayerMatDbName[]=MatNamesMatrix[p][i]
		for(j=0;j<2;j+=1)
			ValidateModel2("Validate Model")
//			
		//Setting up Simulation Settings 
			SimulationSelectUnselectButton("Select All")
//		
			dowindow/HIDE=1 modelCalculationPanel
		endfor

//		
		RandomSimulate(NumberSims)
//		
		killpath savefolder
		
	endfor

END