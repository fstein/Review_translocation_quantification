var AallROIs;var thresholdmask;var Exptype;var resultstringpath;
macro "Translocation-Quantification Macro" {
	macroname="Translocation-Quantification Macro";
	tmp_version="1-0";
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	temp_dir=getDirectory("temp");
	tmp_file=temp_dir+"Temp file "+macroname+"-Ver"+tmp_version+".txt";
	initial_tool=IJ.getToolName();
	month=month+1;
	if(month<10)smonth="0"+month;
	if(month>=10)smonth=month;
	if(dayOfMonth<10)sdayOfMonth="0"+dayOfMonth;
	if(dayOfMonth>=10)sdayOfMonth=dayOfMonth;
	timestamp=""+year+""+smonth+""+sdayOfMonth+"_"+hour+"h"+minute+"min";
	date=timestamp;
	scwidth=screenWidth;
	scheight=screenHeight;
	plotwidth=round(450*1.5);
	plotheight=round(200*1.5);
	Acolor=newArray("black","red","blue","green","orange","magenta","pink","yellow","darkGray","gray","lightGray");
	Atrch_method=newArray("None","Manually define two pixel classes","built-in 'Subtract background'","use outer rim of each cell","built-in 'Subtract background' - exclude cytosol");
	Segmentationchannel="None";
	Asetmeasure=newArray("mean","modal","median","integrated");
	Ameasure=newArray("Mean","Mode","Median","RawIntDen");
	Atoanalch=newArray(0);
	Achnames=newArray(0);
	if(nImages==0)exit("No open images. Please open images or stacks and try again.");
	Atoanal=newArray(0);
	frames=0;
	for(i=0;i<nImages;i++){
		selectImage(i+1);
		Atoanalch=Array.concat(Atoanalch,getTitle());
		framesi=nSlices;
		if(framesi>frames)frames=framesi;
	};
	Awindownames=Atoanalch;
//###########################################################################
	loadparameter();
	Dialog.create(macroname);
	help="<html><h2>Help for "+macroname+"</h2> <table border='1'><font size='1'>";
	help=help+"<tr> <th>Menu point</th> <th>Possible options</th> <th>Description</th> </tr>";
	//help=help+"<tr> <td></td> <td></td> <td></td></tr>";
	//help=help+"<tr><td rowspan='3'>Type of experiment:</td> <td> Single time point. </td> <td> Explanation </td></tr>";
	//help=help+"<tr> <td> Time series without stimulation. </td> <td> To be chosen if image data set contains multiple time points. No response (amplitude changes) will be calculated. </td></tr>";
	Dialog.addString("Name of experiment:",timestamp);
	if(roiManager("count")==0)Dialog.addChoice("Which channel should be used for cell segmentation?",Atoanalch);
	Dialog.addCheckbox("Time-series data.",parseFloat(List.get("Exptype")));
	Dialog.addMessage("Details to quantify translocation:\nChoose names of two pixel classes (regions of the cell) for which the ratio will be calculated.");
	Dialog.addString("Marker name (e.g. PM):",List.get("Marker_name"));
	Dialog.addString("Background name (e.g. cytosol):",List.get("Background_name"));
	Dialog.addMessage("Details to quantify translocation events: \nChoose the 'Marker' channel (e.g. nucleus or plasma membrane marker) for the channels you want to quantify translocation.\n'Marker' channel is used to classifiy pixels of the chosen channel into 'Marker' and 'background' region by thresholding.");
	for(i=0;i<Atoanalch.length;i++){
		ATransChoice=Array.concat("Ignore channel","Quantify only 'Mean'","No marker channel. Quantify only local events",Atoanalch);//franzi Asegch
		Dialog.addChoice(Atoanalch[i],ATransChoice,List.get("TransChoice"+i));
		//Dialog.addChoice("How to process 'Marker' channel?",Atrch_method,parseFloat(List.get("method_trch_choice"+i)));
	};
	Dialog.addMessage("");
	Dialog.addChoice("How to process 'Marker' channel?",Atrch_method,List.get("method_trch"));
	//Dialog.addChoice("Marker region-Background-ratio should be calculated from which statistical summary?",Ameasure,List.get("Ratio_Measure"));
	Dialog.addNumber("Average compartment width [pixel] where local events take place in the cell:",parseFloat(List.get("radius_trch")));
	Dialog.addMessage("");
	Dialog.addCheckbox("Save results in a text file for down-stream analysis with e.g. R:",parseFloat(List.get("saveRfile")));
	Dialog.addMessage("'Name of experiment' is used as the file name for the result-txt-file.");
	//Dialog.addCheckbox("asdf",parseFloat(List.get("adf")));
	Dialog.addHelp(help);
	Dialog.show();
//***********************************************************************
	origtitle=Dialog.getString();
	if(roiManager("count")==0)Segmentationchannel=Dialog.getChoice();
	Exptype=Dialog.getCheckbox();
	List.set("Marker_name",Dialog.getString());
	List.set("Background_name",Dialog.getString());
	List.set("Exptype",Exptype);
	nooftrch=0;
	for(i=0;i<Atoanalch.length;i++){
		TransChoice=Dialog.getChoice();
		//TransMethod=Dialog.getChoice();
		List.set("TransChoice"+i,TransChoice);
		if(TransChoice=="Quantify only 'Mean'"){
			Achnames=Array.concat(Achnames,Atoanalch[i]);
		};
		if(TransChoice!="Ignore channel"&&TransChoice!="Quantify only 'Mean'"){
			if(TransChoice!="No marker channel. Quantify only local events")compare_channels(TransChoice,Atoanalch[i]);
			Achnames=Array.concat(Achnames,Atoanalch[i]);
			nooftrch++;
			no=Awindownames.length-1;
			POIname=Atoanalch[i];
			List.set("POIchannel"+nooftrch,Atoanalch[i]);
			List.set("POIname"+nooftrch,POIname);
			List.set("Markerchannel"+nooftrch,TransChoice);	
			//List.set("method_trch"+nooftrch,TransMethod);
			if(TransChoice!="No marker channel. Quantify only local events"){
				List.set("POI_marker"+nooftrch,""+POIname+" "+List.get("Marker_name")+"-region");
				List.set("POI_background"+nooftrch,""+POIname+" "+List.get("Background_name")+"-region");
				List.set("POI_ratio"+nooftrch,""+POIname+" "+List.get("Marker_name")+"-"+List.get("Background_name")+"-ratio");
				//Marker region
				no=Awindownames.length;
				Atoanal=Array.concat(Atoanal,no);
				Awindownames=Array.concat(Awindownames,List.get("POI_marker"+nooftrch));
				Achnames=Array.concat(Achnames,""+POIname+" "+List.get("Marker_name")+"-region");
				//Background region
				no=Awindownames.length;
				Atoanal=Array.concat(Atoanal,no);
				Awindownames=Array.concat(Awindownames,List.get("POI_background"+nooftrch));
				Achnames=Array.concat(Achnames,""+POIname+" "+List.get("Background_name")+"-region");
				//Marker region-Background-ratio 
				no=Awindownames.length;
				Atoanal=Array.concat(Atoanal,no);
				Awindownames=Array.concat(Awindownames,List.get("POI_ratio"+nooftrch));
				Achnames=Array.concat(Achnames,""+POIname+" "+List.get("Marker_name")+"-"+List.get("Background_name")+"-ratio");
			};
			if(TransChoice=="No marker channel. Quantify only local events"){
				List.set("Markerchannel"+nooftrch,"None");
				List.set("Localchannel"+nooftrch,"Local "+Atoanalch[i]);	
				no=Awindownames.length;
				Atoanal=Array.concat(Atoanal,no);
				Awindownames=Array.concat(Awindownames,"Local "+Atoanalch[i]);
				Achnames=Array.concat(Achnames,"Local "+POIname);
			};
		};
	};
	List.set("method_trch",Dialog.getChoice());
	//List.set("Ratio_Measure",Dialog.getChoice());
	List.set("radius_trch",Dialog.getNumber());
	List.set("saveRfile",Dialog.getCheckbox());
	saveparameter();
	if(Achnames.length>0){
	 //Save resultsfile
		if(List.get("saveRfile")){
			dir_save=getDirectory("Choose the directory in which the results txt-file will be saved:");
			write_resultstring_header(dir_save,origtitle);
		};
	//Cell segmentation
		thresholdchannel="None";
		thresholdmask="None";	
		run("Colors...", "foreground=white background=black selection=white");
		run("Set Measurements...", "  mean standard redirect=None decimal=3");
		if(!isOpen(Segmentationchannel)){
			Segmentationchannel=Achnames[0];
		};
		selectWindow(Segmentationchannel);
		wait(100);
		if(Exptype==0){
			//roiManager("reset");
			roiManager("Associate", "true");
			thresholdchannel=create_thresholdchannel(Segmentationchannel);
		};
		if(Exptype==1){
			//roiManager("reset");
			roiManager("Associate", "false");
			thresholdchannel=create_thresholdpic(Segmentationchannel);
		};
		if(roiManager("count")==0){
			create_ROIs(thresholdchannel);
		};
		thresholdmask=create_mask_from_ROIs(thresholdchannel);
	//Translocation analysis
		for(tc=1;tc<=nooftrch;tc++){
			if(List.get("Markerchannel"+tc)=="None"){
				create_translocationchannel(List.get("POIchannel"+tc),List.get("Localchannel"+tc),List.get("method_trch"),1);
			};
			if(List.get("Markerchannel"+tc)!="None"){
				calculate_translocationratio(List.get("POIchannel"+tc),List.get("Markerchannel"+tc),List.get("POI_marker"+tc),List.get("POI_background"+tc),List.get("POI_ratio"+tc));
				
			};
		};
		amountrois=roiManager("count");
	//Analysis and plotting of Results
		if(Exptype==0){
			frames=nSlices;
			run("Clear Results");
			amountrois=roiManager("count");
			icAresults=newArray(Achnames.length*amountrois);
			icASliceinfo=newArray(amountrois);
			icASD=newArray(Achnames.length*amountrois);
			icAresultsno=newArray(amountrois);
			if(amountrois>0){
				counter=0;
				for(channelno=0;channelno<Achnames.length;channelno++){
					ex=Achnames[channelno];	
					if(isOpen(ex)){
						setmeasure="mean";
						run("Set Measurements...", " mean standard stack redirect=["+ex+"] decimal=3");
						run("Select None");
						run("Clear Results");
						roiManager("Deselect");
						roiManager("Show All");
						roiManager("Measure");
						selectWindow("Results");
						for (ROIno =0; ROIno < nResults; ROIno++){//amountrois
							icAresults[ROIno+channelno*amountrois]=getResult("Mean", ROIno);
							icASD[ROIno+channelno*amountrois]=getResult("StdDev", ROIno);
							if(channelno==0){
								counter++;
								slice=getResult("Slice", ROIno)-1;
								icASliceinfo[ROIno+channelno*amountrois]=getResult("Slice", ROIno);
								icAresultsno[ROIno]=counter;
							};
						};
						if(List.get("saveRfile"))write_in_resultstring2(origtitle,date,ex,icAresultsno,icASliceinfo,extract_array2(icAresults,channelno,amountrois));
					};
				};
			};
			run("Set Measurements...", "  mean standard redirect=None decimal=3");
			run("Clear Results");
			cASliceinfo=icASliceinfo;
			cAresultsno=icAresultsno;
			mean=newArray(Achnames.length);
			SDmean=newArray(Achnames.length);
			SDEmean=newArray(Achnames.length);
			median=newArray(Achnames.length);
			SDmedian=newArray(Achnames.length);
			minimum=newArray(Achnames.length);
			maximum=newArray(Achnames.length);
			for(channelno=0;channelno<Achnames.length;channelno++){
				ex=Achnames[channelno];
				if(cAresultsno.length>0){
					cAresultsnoname=add_strings_to_array(cAresultsno,"ROI ","");
					PlotRArray(cAresultsnoname,cAresultsno,extract_array2(icAresults,channelno,amountrois),extract_array2(icASD,channelno,amountrois),"Barplot overview of single ROI measurements of "+ex,"ROI","Mean","PM/background quantification");
					print_in_results("ROI No",cAresultsno);
					print_in_results("ROI from slice",cASliceinfo);
					x=extract_array2(icAresults,channelno,amountrois);
					print_in_results("Mean of "+ex,extract_array2(icAresults,channelno,amountrois));
					print_in_results("StdDev of "+ex,extract_array2(icASD,channelno,amountrois));
				};
			};
			for(channelno=0;channelno<Achnames.length;channelno++){
				ex=Achnames[channelno];
				if(cAresultsno.length>0){
					mean[channelno]=calMean(extract_array2(icAresults,channelno,amountrois));
					SDmean[channelno]=calSD(extract_array2(icAresults,channelno,amountrois));
					SDEmean[channelno]=calSDE(extract_array2(icAresults,channelno,amountrois));
				};
				if(cAresultsno.length>3){
					median[channelno]=calMedian(extract_array2(icAresults,channelno,amountrois));
					SDmedian[channelno]=calQuartilsdiff(extract_array2(icAresults,channelno,amountrois));
					minimum[channelno]=calMin(extract_array2(icAresults,channelno,amountrois));
					maximum[channelno]=calMax(extract_array2(icAresults,channelno,amountrois));
				};
				if(cAresultsno.length<=3){
					median[channelno]=0;SDmedian[channelno]=0;minimum[channelno]=0;maximum[channelno]=0;		
				};
				print("Results of "+ex);
				print("Total mean = "+mean[channelno]+" "+fromCharCode(177)+" "+SDmean[channelno]);
				print("Total median = "+median[channelno]+" "+fromCharCode(177)+" "+SDmedian[channelno]);
				print("Total minimum = "+minimum[channelno]);
				print("Total maximum = "+maximum[channelno]);
				print("Total StdErr = "+SDEmean[channelno]);
				print(" ");
			};
			if(cAresultsno.length>0){
				Atitle=newArray(Achnames.length);
				xValues=newArray(Achnames.length);
				for(channelno=0;channelno<Achnames.length;channelno++){
					ex=Achnames[channelno];
					chno=channelno+1;
					xValues[channelno]=chno;
					Atitle[channelno]=ex;
				};
				PlotRArray(Atitle,xValues,mean,SDmean,"Overview Mean of all ROIs","Channel","Mean intensity",List.get("origtitle"));
			};
		};
		if(Exptype==1){
			AallROIs=newArray(frames*amountrois*Achnames.length);
			for(ch=0;ch<Achnames.length;ch++){
				Atime=getFrameArray(Achnames[ch]);
				multimeasureresultsplot(Achnames[ch],"Plot - "+Achnames[ch]+" Mean intensity of all ROIs versus time",""+Achnames[ch]+" Mean intensity",Atime,ch);	
			};
			run("Clear Results");
			for(ch=0;ch<Achnames.length;ch++){
				for(ROIno=0;ROIno<amountrois;ROIno++){
					c=ROIno+1;
					ROI="ROI No "+c;
					print_in_results(""+Achnames[ch]+" "+ROI,extract_array(AallROIs,ROIno,ch,amountrois,frames));
				};
			};
		};
		if(isOpen(thresholdmask)){
			selectWindow(thresholdmask);
			close();
		};
		if(isOpen(thresholdchannel)){
			selectWindow(thresholdchannel);
			wait(100);
			close();
		};
	};
	setTool(initial_tool);
	beep();
	waitForUser("Analysis complete!");
};
function create_mask(channel){
	selectWindow(channel);
	getLocationAndSize(x, y, width, height);
	wait(100);
	frames=nSlices;
	mask="Binary mask of "+channel;
	run("Select None");
	run("Duplicate...", "title=["+mask+"] duplicate range=1-["+frames+"]");		
	resize();
	setLocation(width,0);
	Atlim=threshold_channel(mask,1,List.get("thresholdmethod"),1,List.get("processguieachloop"),"minvalue-"+channel);
	selectWindow(mask);
	wait(100);
	setThreshold(Atlim[0], Atlim[1]);
	run("Convert to Mask", "method=Default background=Default black");
	resetThreshold();
	run("Open","stack");
	run("Close-","stack");
	return mask;
};
function create_ROIs(ithresholdpic){
	if(!isOpen("ROI Manager")){
		run("ROI Manager...");	
		selectWindow("ROI Manager");
		setLocation(scwidth-220,0);
	};
	if(Exptype==0)roiManager("Associate", "true");
	if(Exptype==1)roiManager("Associate", "false");
	roiManager("Centered", "false");
	roiManager("UseNames", "false");
	selectWindow(ithresholdpic);
	wait(100);
	frames=nSlices;
	getLocationAndSize(x, y, width, height);
	setLocation(width,0);
	run("Synchronize Windows");
	thresholdmask=create_mask(ithresholdpic);
	
	create_manual_voronoi(ithresholdpic,thresholdmask);
	if(isOpen("B&C")){//BC=190x340
		selectWindow("B&C");
		setLocation(scwidth-200,scheight-340);	
	};	
	setForegroundColor(0,0,0);
	if(frames==1){
		arrange_and_wait(0,thresholdmask,ithresholdpic,"Please check the binary mask and divide cells with the Pencil Tool if necessary. \nUsage of 'Synchronize Windows' is recommended. Click on 'Synchronize All' in this window to make cell division easier.\nThen press OK.",1,"Pencil Tool");	
	};
	if(frames>1){
		arrange_and_wait(0,thresholdmask,ithresholdpic,"Please check the binary mask channel and divide cells with the Pencil Tool if necessary.\nDon't forget to go through each frame.\nUsage of 'Synchronize Windows' is recommended. Click on 'Synchronize All' in this window to make cell division easier.\nThen press OK.",1,"Pencil Tool");	
	};
	selectWindow(thresholdmask);
	wait(100);
	maxvalue=getmaximumpixel(thresholdmask);
	run("Threshold...");
	setThreshold(1, maxvalue);
	run("Analyze Particles...", "size=[50]-[Infinity] circularity=[0]-[1.00] show=Nothing exclude add stack");
	
	resetThreshold();
	amountrois=roiManager("count");
	
	
	if(isOpen("ROI Manager")){//ROI Manager=220x290
		selectWindow("ROI Manager");
		setLocation(scwidth-220,0);
	};
	roiManager("Deselect");
	roiManager("Show All with labels");	
	resetThreshold();
	run("Synchronize Windows");
	arrange_and_wait(0,thresholdmask,ithresholdpic,"Check your ROIs, delete them (if necessary) or add new one's manually.\nDo all changes in the 'ROI manager' window!\nThen press OK.",1,"oval");	
	amountrois=roiManager("count");
	if(frames==1&&Exptype==1){	
		for(rm=0;rm<amountrois;rm++){
			roiManager("Select", rm);	
			roiManager("Remove Slice Info");
		};
		roiManager("Deselect");
	};
	if(isOpen("Synchronize Windows")){
		selectWindow("Synchronize Windows");
		wait(100);
		run("Close");
	};
};
function create_thresholdchannel(channelname){
	frames=nSlices;
	selectWindow(channelname);	
	wait(100);
	getLocationAndSize(x, y, width, height);
	ithresholdpic="Mask "+channelname;
	run("Select None");
	run("Duplicate...", "title=["+ithresholdpic+"] duplicate range=1-["+frames+"]");
	resize();
	run("Enhance Contrast", "saturated=0.35");
	run("Conversions...", "scale");
	run("8-bit");
	run("Conversions...", " ");
       	run("Median...", "radius=1 stack");
      	run("Fire");
	return ithresholdpic;		
};
function create_thresholdpic(channelname){
	selectWindow(channelname);	
	wait(100);
	getLocationAndSize(x, y, width, height);
	ithresholdpic="Time projection of "+channelname;
	intermediate="Intermediate picture of "+channelname;
	run("Select None");
	run("Duplicate...", "title=["+intermediate+"] duplicate range=1-["+frames+"]");
	resize();
	run("Conversions...", "scale");
	max=getmaximumpixel(channelname);
	selectWindow(intermediate);
	setMinAndMax(0, max);
	run("8-bit");
	run("Conversions...", " ");
       	run("Median...", "radius=1 stack");
      	run("Fire");
	run("Z Project...", "start=1 stop=["+frames+"] projection=[Average Intensity]");
	run("Rename...", "title=["+ithresholdpic+"]");
	resize();		
	if(isOpen(intermediate)){
		selectWindow(intermediate);
		wait(100);
		close();	
	};
	return ithresholdpic;
};
function extract_array(array,ROIno,channelno,amountrois,frames){//[x+y*xmax+z*xmax*ymax]
	if(array.length<channelno*amountrois*frames)exit("Mistake occured. Array is not long enough for multiple dimensions!");
	sarray=newArray(frames);
	for(slice=0;slice<frames;slice++){
		sarray[slice]=array[slice+ROIno*frames+channelno*amountrois*frames];			
	};
	return sarray;
};
function getfromResults(columname,rows){
	Avalues=newArray(rows);
	Array.fill(Avalues,NaN);
	if(rows<=nResults){
		for (y =0; y < rows; y++){
			Avalues[y] = getResult(columname, y);
		};
	};
	return Avalues;
};
function print_in_results(columnname,array){
	if(calMean(array)!=0){
		rows=array.length;
		for(i=0;i<rows;i++){
			setResult (columnname,i,array[i]);
		};
		updateResults();
	};		
};
function multimeasureresultsplot(channel,plotname,yaxis,Atime,channelno){//AallROIs
	if(isOpen(channel)){
		run("Clear Results");
		selectWindow(channel);
		wait(100);
		frames=nSlices;
		run("Set Measurements...", "mean redirect=["+channel+"] decimal=3");
		roiManager("Deselect");
		roiManager("Multi Measure");
		amountrois=roiManager("count");
		ROItraces=newArray(frames*amountrois);
		for(c = 1; c <= amountrois; c++){
			ROIno=c-1;
			value="Mean"+c;
			AROI=getfromResults(value,frames);
			if(List.get("saveRfile"))write_in_resultstring(origtitle,date,channel,AROI,c,frames);
			if(channelno<=Achnames.length){
				for(slice=0;slice<frames;slice++){
					AallROIs[slice+ROIno*frames+channelno*amountrois*frames]=AROI[slice];	
				};	
			};
			for(slice=0;slice<frames;slice++){
				ROItraces[slice+ROIno*frames]=AROI[slice];	
			};
		};
		ROInames=newArray(amountrois);
		AanalROIs=newArray(amountrois);
		for(i=0;i<amountrois;i++){
			ROI=i+1;
			ROInames[i]="ROI "+ROI;	
			AanalROIs[i]=i;
		};
		PlotmultipleArrays(Atime,ROItraces,ROInames,AanalROIs,plotname,"Frame",yaxis);			
		run("Clear Results");
	};
};
function extract_array2(array,channelno,rows){//[x+y*xmax]
	if(array.length<channelno*rows)exit("Mistake occured. Array is not long enough for multiple dimensions!");
	sarray=newArray(rows);
	for(i=0;i<rows;i++){
		sarray[i]=array[i+channelno*rows];	
	};
	return sarray;
};
function PlotmultipleArrays(xValues,yValues,Awindownames,Atoanal,plottitle,xaxis,yaxis){
	Alimits=removeNaN(xValues);
	Array.getStatistics(Alimits, xMin, xMax, mean, stdDev);
	Alimits=removeNaN(yValues);
	Array.getStatistics(Alimits, yMin, yMax, mean, stdDev);
	xMaxorig=xMax;
	xMinorig=xMin;
	xspace=abs(xMin-xMax)*0.05;
	yspace=abs(yMin-yMax)*0.05;
	xMin = xMin-xspace;xMax=xMax+xspace;yMin=yMin-yspace;yMax=yMax+yspace;
	if(plotheight/Atoanal.length<14){
		plotheight=Atoanal.length*14.2;
	};
	stringlengthes=newArray(Atoanal.length);
	for(l=0;l<2;l++){	
		heightofchar=14/plotheight;//*********************************
		widthofchar=7/plotwidth;//*********************************
		begincharheight=1.2*heightofchar;//*********************************
		for(i=0;i<Atoanal.length;i++){
			c=Atoanal[i];
			stringlengthes[i]=lengthOf(Awindownames[c])*widthofchar;		
		};
		stringlength=calMax(stringlengthes);
		textlength=stringlength+4*widthofchar;
		textwidth=1-textlength;//*********************************
		timeswider=textlength+1+widthofchar;//*********************************
		if(l==0)xMax=xMax*timeswider;//*********************************
		linewidth=0.05*xMaxorig;//*********************************
		if(l==0){
			plotwidthnew=timeswider*plotwidth;
			plotwidth=plotwidthnew;
			
		};
	};
	Plot.create(plottitle, xaxis, yaxis);
	Plot.setFrameSize(plotwidth, plotheight);
	Plot.setLineWidth(1);
	Plot.setLimits(xMin, xMax, yMin, yMax);
	col=0;
	for(line=0;line<Atoanal.length;line++){
		channelno=Atoanal[line];
		Aline=extract_array2(yValues,line,frames);
		add_line(xValues,Aline,Acolor[col],Awindownames[channelno],line);
		col++;
		if(col==Acolor.length)col=0;
	};
	//Captions
	setJustification("center");
	Plot.addText(plottitle, 0.5, 0);
	Plot.setLineWidth(1);
	Plot.show();
};
function add_line(xvalues,Aline,color,name,line){
	if(calMean(Aline)!=0){	
		xvalues=Array.trim(xvalues, Aline.length);
		Plot.setColor(color);
		Plot.add("line",xvalues,Aline);
		setJustification("right");
		Plot.addText(""+fromCharCode(9472,9472),1-stringlength-widthofchar,begincharheight+(line*heightofchar));
		Plot.setColor("black");
		Plot.addText(name, 1-0.5*widthofchar, begincharheight+(line*heightofchar));	
	};
};	
function getFrameArray(channel){
	selectWindow(channel);
	wait(100);
	frames=nSlices;
	array=newArray(nSlices);
	for(i=0;i<nSlices;i++){
		array[i]=i+1;
	};
	return array;
};
function compare_channels(ch1,ch2){
	selectWindow(ch1);
	wait(100);
	getDimensions(width_ch1, height_ch1, channels_ch1, slices_ch1, frames_ch1);
	selectWindow(ch2);
	wait(100);
	getDimensions(width_ch2, height_ch2, channels_ch2, slices_ch2, frames_ch2);
	if(width_ch1!=width_ch2||height_ch1!=height_ch2||channels_ch1!=channels_ch2||slices_ch1!=slices_ch2||frames_ch1!=frames_ch2)exit(""+ch1+" and "+ch2+" don't have the same dimensions.\nPlease choose images with the same dimensions.");
};
function create_translocationchannel(channel,translocationchannel,method,loop){
	setBatchMode(true);
	showStatus("Macro is running...");
	selectWindow(channel);
	wait(100);
	Bitdorig=bitDepth();
	wait(100);
	run("Select None");
	roiManager("Deselect");
	if(method!="use outer rim of each cell"){
		selectWindow(channel);
	};
	if(method=="use outer rim of each cell"){
		selectWindow(thresholdmask);
	};
	wait(100);
	run("Duplicate...", "title=["+translocationchannel+"] duplicate range=1-["+nSlices+"]");
	run("Conversions...", " ");
	run("32-bit");
	selectWindow(translocationchannel);
	wait(100);
	if(Bitdorig==8)run("8-bit");
	if(Bitdorig==16)run("16-bit");
	if(Bitdorig!=8&&Bitdorig!=16){
		run("Conversions...", "scale");
		max=getmaximumpixel(translocationchannel);
		setMinAndMax(0, max);
		run("8-bit");
	};
	if(method=="built-in 'Subtract background'"){
		run("Subtract Background...", "rolling=["+List.get("radius_trch")+"] stack");	
	};
	if(method=="use outer rim of each cell"){
		cwidth=round(parseFloat(List.get("radius_trch")));
		run("Options...", "iterations=["+cwidth+"] count=1 black edm=Overwrite");
		//run("Options...", "iterations=["+List.get("radius_trch")+"] count=1 black edm=Overwrite");
		run("Select None");
		selectWindow(translocationchannel);
		wait(100);
		run("Conversions...", "scale");
		max=getmaximumpixel(translocationchannel);
		setMinAndMax(0, max);
		run("8-bit");
		run("Conversions...", " ");
		run("Erode", "stack");
		run("Options...", "iterations=1 count=1 black edm=Overwrite");
		run("Invert", "stack");
		imageCalculator("Multiply stack", translocationchannel,thresholdmask);
	};
	if(method=="built-in 'Subtract background' - exclude cytosol"){
		selectWindow(thresholdmask);
		run("Select None");
		wait(100);
		run("Duplicate...", "title=cytosol duplicate range=1-["+nSlices+"]");
		run("Conversions...", "scale");
		selectWindow("cytosol");
		wait(100);
		max=getmaximumpixel("cytosol");
		setMinAndMax(0, max);
		run("8-bit");
		run("Conversions...", " ");
		cwidth=round(parseFloat(List.get("radius_trch"))*1.5);
		run("Options...", "iterations=["+cwidth+"] count=1 black edm=Overwrite");
		selectWindow("cytosol");
		wait(100);
		run("Erode", "stack");
		run("Options...", "iterations=1 count=1 black edm=Overwrite");
		run("Invert", "stack");
		make_real_binary("cytosol");
		run("8-bit");
		selectWindow(translocationchannel);
		wait(100);
		run("Subtract Background...", "rolling=["+List.get("radius_trch")+"] stack");	
		imageCalculator("Multiply stack", translocationchannel,"cytosol");
		if(isOpen("cytosol")){
			selectWindow("cytosol");
			wait(100);
			if(List.get("savemask")){
				fullpath=dir_save+"cytosolic_part.tif";
				showStatus("Saving... Cytosolic part");
				saveAs("Tiff", fullpath);
			};
			close();
		};
	};
	run("Conversions...", " ");
	selectWindow(translocationchannel);
	wait(100);
	max=get_theor_maxvalue();
	setMinAndMax(0, max);
	run("Median...", "radius=1 stack");
	resize();
	run("32-bit");
	run("Conversions...", " ");
	getLocationAndSize(x, y, width, height);
	if((2*width)<=scwidth)setLocation(width,0);
	maxvalue=get_theor_maxvalue();
	setBatchMode("exit and display");
	selectWindow(translocationchannel);
	wait(100);
	run("Enhance Contrast", "saturated=0.35");
};
function get_theor_maxvalue(){
	Bitd=bitDepth();
	maxvalue=pow(2, Bitd)-1;
	return maxvalue;	
};
function resize(){
	getLocationAndSize(x, y, width, height);
	wratio=height/width;
	hratio=width/height;
	wfactor=(scwidth-220)/scwidth;
	hfactor=(scheight-220)/scheight;
	wspace=screenWidth*wfactor;
	hspace=screenHeight*hfactor;
	if(parseFloat(List.get("chnumber"))>2){
		setLocation(x,y,wspace/2,hspace/2);
	};
	if(parseFloat(List.get("chnumber"))<=2){
		setLocation(x,y,wspace/2,hspace);
	};
};
function calculate_translocationratio(POIchannel,markerchannel,POI_markername,POI_backgroundname,Rationame){
	if(List.get("method_trch")!="Manually define two pixel classes"){
		markermask="Mask of "+markerchannel;
		in_markermask="Inverse of "+markermask;
		if(!isOpen(markermask)){
			create_translocationchannel(markerchannel,markermask,List.get("method_trch"),1);
			transform_to_marker_mask(markermask,"minvalue-"+markerchannel,1,1,List.get("thresholdmethod"),List.get("processguieachloop"));
		};
		selectWindow(markermask);
		if(!isOpen(in_markermask)){
			in_markermask=make_inverse_mask(markermask);
		};
	};
	if(List.get("method_trch")=="Manually define two pixel classes"){
		if(Exptype==0)projectionchannel="Mask "+markerchannel;
		if(Exptype==1)projectionchannel="Time projection of "+markerchannel;
		markermask="Manual Marker mask of "+projectionchannel;
		in_markermask="Manual Background mask of "+projectionchannel;
		if(!isOpen(projectionchannel)){
			if(Exptype==0){
				projectionchannel=create_thresholdchannel(Segmentationchannel);
				selectWindow(projectionchannel);
				wait(100);
				projectionchannel="Mask "+markerchannel;
				run("Rename...", "title=["+projectionchannel+"]");
			};
			if(Exptype==1){
				projectionchannel=create_thresholdpic(Segmentationchannel);
				selectWindow(projectionchannel);
				wait(100);
				projectionchannel="Time projection of "+markerchannel;
				run("Rename...", "title=["+projectionchannel+"]");
			};
		};
		if(!isOpen(markermask)){
			markermask=create_manual_mask(projectionchannel,projectionchannel,"Manual Marker");
		};
		if(!isOpen(in_markermask)){
			in_markermask2=make_inverse_mask(markermask);
			make_real_binary(in_markermask2);
			run("8-bit");
			if(Exptype==0)projectionchannel2="Mask 2 "+markerchannel;
			if(Exptype==1)projectionchannel2="Time projection 2 of "+markerchannel;
			imageCalculator("Multiply create stack",projectionchannel,in_markermask2);
			run("Rename...", "title=["+projectionchannel2+"]");
			in_markermask=create_manual_mask(projectionchannel2,projectionchannel,"Manual Background");
			if(isOpen(projectionchannel2)){
				imageCalculator("Multiply stack",in_markermask,in_markermask2);
				selectWindow(projectionchannel2);
				wait(100);
				close();
			};
			if(isOpen(in_markermask2)){
				selectWindow(in_markermask2);
				wait(100);
				close();
			};
		};
	};
	make_real_binary(markermask);
	make_real_binary(in_markermask);
	selectWindow(POIchannel);
	imageCalculator("Multiply create 32-bit stack",POIchannel,markermask);
	run("Rename...", "title=["+POI_markername+"]");
	run("Fire");
	set_zero_nan(POI_markername);
	imageCalculator("Multiply create stack", POIchannel,in_markermask);
	run("Rename...", "title=["+POI_backgroundname+"]");
	set_zero_nan(POI_backgroundname);
	if(tc==nooftrch){
		if(isOpen(markermask)){
			selectWindow(markermask);
			wait(100);
			close();
		};
	};
	if(tc==nooftrch){
		if(isOpen(in_markermask)){
			selectWindow(in_markermask);
			wait(100);
			close();
		};
	};
	POI_background_mean="Mean "+POI_backgroundname;
	POI_marker_mean="Mean "+POI_markername;
	replace_ROIs_with_mean(POI_backgroundname,POI_background_mean,"Mean");
	replace_ROIs_with_mean(POI_markername,POI_marker_mean,"Mean");
	imageCalculator("Divide create 32-bit stack",POI_marker_mean,POI_background_mean);
	run("Rename...", "title=["+Rationame+"]");
	selectWindow(POI_marker_mean);
	wait(100);
	close();
	selectWindow(POI_background_mean);
	wait(100);
	close();
	setBatchMode("exit and display");
};
function make_inverse_mask(channel){
	selectWindow(channel);
	wait(100);
	inverse="Inverse of "+channel;
	run("Select None");
	run("Duplicate...", "title=["+inverse+"] duplicate range=1-["+nSlices+"]");
	run("Invert", "stack");
	return inverse;	
};
function make_real_binary(channel){
	selectWindow(channel);
	wait(100);
	max=getmaximumpixel(channel);
	run("Divide...", "value="+max+" stack");
	run("32-bit");
	setMinAndMax(0, 1);
};
function replace_ROIs_with_mean(channel,newname,measure){
	selectWindow(channel);
	wait(100);
	run("Select None");
	run("Clear Results");
	for(i=0;i<Ameasure.length;i++){
		if(measure==Ameasure[i])setmeasure=Asetmeasure[i];
	};
	run("Set Measurements...", " "+setmeasure+" redirect=None decimal=3");
	run("Duplicate...", "title=["+newname+"] duplicate range=1-["+nSlices+"]");
	selectWindow(newname);
	wait(100);
	run("32-bit");
	nf=nSlices;
	ROIs=roiManager("count");
	roiManager("Deselect");
	if(Exptype==0){
		roiManager("Associate", "true");
		roiManager("Show All");
		roiManager("Measure");
		for (ROI =0; ROI < nResults; ROI++){
			roiManager("Select", ROI);
			mean=getResult(measure, ROI);
			setColor(mean);
			fill();
		};
	};
	if(Exptype==1){
		roiManager("Associate", "false");
		roiManager("Multi Measure");
		for(i=0;i<nf;i++){
			for(ROI=0;ROI<ROIs;ROI++){
				roiManager("Select", ROI);
				roiManager("Remove Slice Info");
				setSlice(i+1);
				roiManager("Select", ROI);
				ROIname=ROI+1;
				columname=""+measure+ROIname;
				mean=getResult(columname, i);
				setColor(mean);
				fill();
			};
		};
	};
	run("Select None");
	run("Clear Results");
};
function transform_to_marker_mask(channel,minvaluename,rep,thresholding,thresholdmethod,processguieachloop){
	selectWindow(channel);
	wait(100);
	frames=nSlices;
	run("Select None");
	resize();
	getLocationAndSize(x, y, width, height);
	setLocation(width,0);
	Atlim=threshold_channel(channel,thresholding,thresholdmethod,rep,processguieachloop,List.get(minvaluename));
	List.set(minvaluename,Atlim[0]);
	maxvalue=Atlim[1];
	selectWindow(channel);
	wait(100);
	setThreshold(List.get(minvaluename), maxvalue);
	if(List.get("thresholding")==3)run("Convert to Mask", "method="+List.get("thresholdmethod")+" background=Default calculate black");
	if(List.get("thresholding")!=3)run("Convert to Mask", "method=Default background=Default black");
	resetThreshold();
	run("Median...", "radius=1 stack");
	run("Open", "stack");
};
function set_zero_nan(channelname){
        selectWindow(channelname);
        wait(100);
        run("32-bit");
	max=get_theor_maxvalue();
	selectWindow(channelname);
	wait(100);
	setThreshold(1, max);
	run("NaN Background", "stack");
	resetThreshold();
};
function calMean(arrayf){ //Caclulates the Mean value of arrayf
	arrayf=removeNaN(arrayf);
	Array.getStatistics(arrayf,min,max,mean,stdDev);
	return mean;
};
function calSD(arrayf){ //Calculates the Standard Deviation of arrayf
	arrayf=removeNaN(arrayf);
	Array.getStatistics(arrayf,min,max,mean,stdDev);
	if(arrayf.length<=2)stdDev=0;
	return stdDev;
};
function calSDE(array){ //Calculates the Standard Deviation of arrayf
	arrayf=removeNaN(array);
	Array.getStatistics(arrayf,min,max,mean,stdDev);
	if(arrayf.length<=2)return 0;
	sderr=stdDev/sqrt(arrayf.length);
	return sderr;
};
function calMin(array){
	array=removeNaN(array);
	Array.getStatistics(array,min,max,mean,stdDev);
	return min;
};
function calMax(array){
	array=removeNaN(array);
	Array.getStatistics(array,min,max,mean,stdDev);
	return max;	
};
function removeNaN(aA){
	c=0;
	aA=Array.concat(aA);
	while(c<aA.length){
		if(isNaN(aA[c])){
			bA=Array.slice(aA,0,c);
			cA=Array.slice(aA,c+1,aA.length);
			aA=Array.concat(bA,cA);			
		}else c++;
	};
	return aA;
};
function threshold_channel(channel,thresholding,thresholdmethod,rep,processguieachloop,min){
	Atlim=newArray(2);
	selectWindow(channel);
	wait(100);
	lower=min;
	upper=get_theor_maxvalue();
	frames=nSlices;
	getLocationAndSize(x, y, width, height);
	run("Threshold...");
	if(thresholding==1){//manual during the analysis
		run("Threshold...");
		if(isOpen("Threshold")){//295x265
			selectWindow("Threshold");
			setLocation(width,0);	
		};
		arrange_and_wait(1,channel,"Threshold","Please threshold the channel "+channel+" to define signal.\nEverything below the threshold (not coloured in red) will be excluded from the analysis!\nUse the window 'Threshold' to do so. Don't press 'Apply' in this window! Check if you have 'Dark background' ticked.\nThen press OK.",1,"Pencil Tool");	
		selectWindow(channel);
		wait(100);
		getThreshold(lower, upper);
	};
	if(thresholding==3){//Automatic with a predefined thresholding method
		setAutoThreshold(thresholdmethod+" dark stack");
		run("Threshold...");	
		getThreshold(lower, upper);
	};
	selectWindow(channel);
	wait(100);
	setThreshold(lower, upper);
	Atlim[0]=lower;
	Atlim[1]=upper;
	return Atlim;
};
function arrange_and_wait(threshold,channel,channel2,message,updateRM,tool){
	selectWindow(channel);
	wait(100);
	getLocationAndSize(x, y, width, height);
	resetMinAndMax();
	run("Enhance Contrast", "saturated=0.35");
	xorig=x;
	yorig=y;
	worig=width;
	horig=height;
	if(isOpen(channel2)){	
		selectWindow(channel2);
		wait(100);
		getLocationAndSize(x, y, width, height);
		xorig2=x;
		yorig2=y;
		worig2=width;
		horig2=height;
		resetMinAndMax();
		run("Enhance Contrast", "saturated=0.35");
	};
	wfactor=(screenWidth-220)/screenWidth;
	hfactor=(screenHeight-220)/screenHeight;
	wspace=screenWidth*wfactor;
	hspace=screenHeight*hfactor;
	if(isOpen("Synchronize Windows")){
		selectWindow("Synchronize Windows");
		setLocation(wspace/2,hspace);		
	};
	if(isOpen(channel2)){
		selectWindow(channel2);
		setLocation(wspace/2,0);
		roiManager("Show All with labels");
	};
	selectWindow(channel);
	wait(100);
	setLocation(0,0,wspace/2,hspace);	
	getLocationAndSize(x, y, width, height);
	selectWindow(channel);
	wait(100);
	roiManager("Show All with labels");
	if(threshold==1){
		run("Threshold...");
		setAutoThreshold("Triangle dark stack");
		getThreshold(lower, upper);
		setThreshold(lower, upper);
		setThreshold(lower, upper);
	};
	set_Tool(tool);
	waitForUser(message);
	if(isOpen(channel2)){	
		selectWindow(channel2);
		wait(100);
		setLocation(xorig2,yorig2,worig2,horig2);	
		if(updateRM)roiManager("Show All with labels");
	};
	selectWindow(channel);
	wait(100);
	setLocation(xorig,yorig,worig,horig);
	if(updateRM)roiManager("Show All with labels");
};
function set_Tool(tool){
	initial=IJ.getToolName();
	found=0;
	for(i=0;i<=22;i++){
		setTool(i);
		x=IJ.getToolName();
		if(x==tool){
			i=22;
			found=1;
		};
	};
	if(found==0){
		setTool(initial);
	};
};
function getmaximumpixel(channel){
	selectWindow(channel);
	wait(100);
	if(nSlices==1)getStatistics(area, mean, min, max, std, histogram);
	if(nSlices>1)Stack.getStatistics(voxelCount, mean, min, max, stdDev);
	return max;
};
function transform_markermask(channel){
	selectWindow(channel);
	wait(100);
	slices=nSlices;
	for(i=0;i<slices;i++){
		setSlice(i+1);
		run("Select All");
		setBackgroundColor(0, 0, 0);
		run("Clear", "slice");
	};
	replace_ROIs_with_value(channel,255);
};
function replace_ROIs_with_value(channel,value){
	selectWindow(channel);
	wait(100);
	run("Select None");
	run("Clear Results");
	selectWindow(channel);
	wait(100);
	nf=nSlices;
	ROIs=roiManager("count");
	roiManager("Deselect");
	if(Exptype==0){
		roiManager("Associate", "true");
		roiManager("Show All");
		for (ROI =0; ROI < ROIs; ROI++){
			roiManager("Select", ROI);
			setColor(value);
			fill();
		};
	};
	if(Exptype==1){
		roiManager("Associate", "false");
		for(i=0;i<nf;i++){
			for(ROI=0;ROI<ROIs;ROI++){
				roiManager("Select", ROI);
				roiManager("Remove Slice Info");
				setSlice(i+1);
				roiManager("Select", ROI);
				setColor(value);
				fill();
			};
		};
	};
	run("Select None");
	run("Clear Results");
};
function create_manual_voronoi(channel,modifymask){
	mask="Voronoimask of "+channel;
	selectWindow(channel);
	wait(100);
	frames=nSlices;
	run("Duplicate...", "title=["+mask+"] duplicate range=1-["+frames+"]");
	selectWindow(mask);
	run("8-bit");
	run("Fire");
	wait(100);
	run("Divide...", "value=2 stack");
	run("Subtract...", "value=1 stack");
	selectWindow(mask);
	//run("Enhance Contrast", "saturated=0.35");
	setForegroundColor(255, 255, 255);
	color=getValue("foreground.color");
	setColor(color);
	color=color-1;
	getLocationAndSize(x, y, width, height);
	setLocation(0,0);
	setThreshold(color, 255);
	set_Tool("Pencil Tool");
	waitForUser("Please draw a point in each cell with the Pencil Tool in the "+mask+".\nThis is information is used to segment cells. A Pencil Width of 5-10 is recommended.\nThe more accurate you color each cell from the inside, the better the cell segmentation will be.\nThen press OK.");
	setLocation(x,y);
	setBatchMode(true);
	selectWindow(mask);
	wait(100);
	setBatchMode("hide");
	selectWindow(mask);
	wait(100);
	color=getValue("foreground.color");
	color=color-1;
	setThreshold(color, 255);
	run("Convert to Mask", "method=Default background=Dark black");
	run("Voronoi", "stack");
	setThreshold(1, 255);
	run("Convert to Mask", "method=Default background=Dark black");
	run("Invert", "stack");
	run("Divide...", "value=255 stack");
	setMinAndMax(0, 1);
	wait(100);
	imageCalculator("Multiply stack",modifymask, mask);
	if(isOpen(mask)){
		selectWindow(mask);
		wait(100);
		close();
	};
	setBatchMode("exit and display");
};
function create_mask_from_ROIs(channel){
	mask="Binary mask of "+channel;
	selectWindow(channel);
	wait(100);
	frames=nSlices;
	run("Select None");
	run("Duplicate...", "title=["+mask+"] duplicate range=1-["+frames+"]");	
	selectWindow(mask);
	wait(100);
	run("8-bit");	
	transform_markermask(mask);
	resize();
	setLocation(0,0);
	return mask;
};
function write_resultstring_header(dir_save,origtitle){
	resultstringpath=""+dir_save+origtitle+"_dataset.txt";
	if(Exptype==1){
		Aresultstring=newArray("Experiment.ID","Trace.ID","analysis.date","channel","ROI","ROI.ID","total.ROI.number","No.of.frames","time","Mean");
	};
	if(Exptype==0){
		Aresultstring=newArray("Experiment.ID","Measurement.ID","analysis.date","channel","ROI","ROI.ID","ROI.from.slice","total.ROI.number","total.No.of.slices","Mean");
	};
	resultstring=a2resultsline(Aresultstring);
	//print(resultstring);
	//print(Exp_dataset_file,resultstring);
	File.saveString(resultstring,resultstringpath);
	resultstring="";
};
function write_in_resultstring(origtitle,date,channel,array,ROIname,frames){
	resultstring="";
	roino=round(parseFloat(ROIname))-1;
	for(row=0;row<frames;row++){
		Aresultstring=newArray(""+origtitle,origtitle+"."+channel+"."+ROIname,date,channel,ROIname,origtitle+"."+ROIname,amountrois,frames,Atime[row],array[row]);		
		istring=a2resultsline(Aresultstring);
		resultstring+=istring;					
	};
	File.append(resultstring,resultstringpath);
	resultstring="";
};
function write_in_resultstring2(origtitle,date,channel,ROIno,Sliceno,mean){
	resultstring="";
	for(row=0;row<ROIno.length;row++){
		Aresultstring=newArray(origtitle,origtitle+"."+channel+"."+ROIno[row],date,channel,ROIno[row],origtitle+"."+ROIno[row],Sliceno[row],ROIno.length,frames,mean[row]);
		istring=a2resultsline(Aresultstring);
		resultstring+=istring;
	};
	File.append(resultstring,resultstringpath);
	resultstring="";
};
function a2resultsline(array){
	line="";
	for(i=0;i<array.length;i++){
		if(i<(array.length-1))line=line+array[i]+"\t";
		if(i==(array.length-1))line=line+array[i]+"\n";	
	};
	return line;
};
function add_strings_to_array(array,before,after){
	array2=newArray(array.length);
	for(i=0;i<array.length;i++){
		array2[i]=""+before+array[i]+after;		
	};
	return array2;
};
function PlotRArray(Atitle,xValues,yValues,ASD,plottitle,xaxis,yaxis,origtitles){
	if(xValues.length>1&&xValues.length<200){	
		Alimits=removeNaN(xValues);
		Array.getStatistics(Alimits, xMin, xMax, mean, stdDev);
		Alimits=Array.concat(yValues,ASD);
		Alimits=removeNaN(Alimits);
		Alimits=Array.concat(Alimits,0);
		Array.getStatistics(Alimits, yMin, yMax, mean, stdDev);
		Alimits=removeNaN(ASD);
		Array.getStatistics(Alimits, min, Errorbars, mean, stdDev);
		xMaxorig=xMax;
		xMinorig=xMin;
		xspace=abs(xMin-xMax)*0.05;
		if(Errorbars>0)yspace=abs(Errorbars*1.05);
		if(Errorbars==0)yspace=abs(yMin-yMax)*0.05;
		xMin = xMin-xspace-0.4;xMax=xMax+xspace+0.4;yMin=yMin-yspace;yMax=yMax+yspace;
		plotname=plottitle;
		if(plotheight/Atitle.length<14){
			plotheight=Atitle.length*14.2;
		};
		stringlength1=0;
		for(f=0;f<Atitle.length;f++){
			if(lengthOf(Atitle[f])>stringlength1)stringlength1=lengthOf(Atitle[f]);		
		};
		for(l=0;l<2;l++){	
			heightofchar=14/plotheight;
			widthofchar=7/plotwidth;
			begincharheight=1.2*heightofchar;
			stringlength=stringlength1*widthofchar;
			textlength=stringlength+10*widthofchar;
			textwidth=1-textlength;
			timeswider=textlength+1+widthofchar;
			if(l==0)xMax=xMax*timeswider;
			linewidth=0.05*xMaxorig;
			if(l==0){
				plotwidthnew=timeswider*plotwidth;
				plotwidth=plotwidthnew;
			};
		};
		Plot.create(plotname, xaxis, yaxis);
		Plot.setFrameSize(plotwidth, plotheight);
		Plot.setLimits(xMin, xMax, yMin, yMax);
		Plot.setColor("black");
		Plot.drawLine(xMinorig-0.45, 0, xMaxorig+0.45, 0);
		for(i=0;i<xValues.length;i++){
			if(i==0)barwidth=abs((xValues[i+1]-xValues[i]))*0.75;
			if(i>0&&i<xValues.length-2){
				barwidth1=abs(xValues[i+1]-xValues[i]);
				barwidth2=abs(xValues[i]-xValues[i-1]);
				if(barwidth1>=barwidth2)barwidth=barwidth2*0.75;
				if(barwidth2>barwidth1)barwidth=barwidth1*0.75;	
			};
			if(i==xValues.length-1)barwidth=abs((xValues[i]-xValues[i-1]))*0.75;
			drawbar(xValues[i],yValues[i],ASD[i],barwidth);	
		};
		Plot.setColor("black");
		setJustification("right");
		for(i=1;i<=Atitle.length;i++){
			ii=i-1;
			Plot.addText("No: "+i+" - "+Atitle[ii], 1-0.5*widthofchar, begincharheight+(ii*heightofchar));
		};
		setJustification("center");
		Plot.addText(plotname, 0.5, 0);
		Plot.setColor("black");
		Plot.setLineWidth(1);
		setJustification("right");
		Plot.addText(origtitles, 1, 1+2.5*heightofchar);
		setJustification("left");
		Plot.setColor("gray");
		Plot.show();
		//run("Profile Plot Options...", "width="+plotwidth+" height="+plotheight+" minimum=0 maximum=0 interpolate draw");
		function drawbar(x,y,yerr,barwidth){
			Plot.setColor("lightgray");
			Plot.setLineWidth(1);
			//barwidth=0.75;
			rep=500;
			for(i=0;i<rep;i++){
				add=(barwidth/rep)*i;
				Plot.drawLine(x-barwidth/2+add, 0, x-barwidth/2+add, y);	
			};
			Plot.setColor("darkgray");
			Plot.drawLine(x-barwidth/2, 0, x-barwidth/2, y);
			Plot.drawLine(x+barwidth/2, 0, x+barwidth/2, y);
			Plot.drawLine(x-barwidth/2, 0, x+barwidth/2, 0);
			Plot.drawLine(x-barwidth/2, y, x+barwidth/2, y);
			Plot.setColor("black");
			Plot.setLineWidth(1);
			Plot.drawLine(x, y-yerr/2, x, y+yerr/2);
			Plot.drawLine(x-barwidth/3, y-yerr/2, x+barwidth/3, y-yerr/2);
			Plot.drawLine(x-barwidth/3, y+yerr/2, x+barwidth/3, y+yerr/2);
		};
	};
};
function loadparameter(){
	if(!File.exists(tmp_file)){
		tmp_check=false;
	};
	if(File.exists(tmp_file)){
		macroparameter=File.openAsString(tmp_file);
		List.setList(macroparameter);
		tmp_check=true;
	};
	if(!tmp_check){
		List.set("Marker_name","PM");
		List.set("Background_name","cytosol");
		List.set("method_trch",Atrch_method[2]);
		//List.set("Ratio_Measure",Ameasure[0]);
		List.set("radius_trch",7);
		List.set("saveRfile",1);
		List.set("Exptype",1);
	};
};
function saveparameter(){
	macroparameter = List.getList();
	forbidden=indexOf(macroparameter, "\\");
	while(indexOf(macroparameter, "\\")>=0){
		forbidden=indexOf(macroparameter, "\\");
		macroparameter_start=substring(macroparameter,0,forbidden);
		macroparameter_end=substring(macroparameter,forbidden+1,lengthOf(macroparameter));
		macroparameter=macroparameter_start+"/"+macroparameter_end;
	};
	File.saveString(macroparameter,tmp_file);
};
function create_manual_mask(channel,channelname,name){
	mask=""+name+" mask of "+channelname;
	selectWindow(channel);
	wait(100);
	frames=nSlices;
	run("Duplicate...", "title=["+mask+"] duplicate range=1-["+frames+"]");
	selectWindow(mask);
	run("8-bit");
	run("Fire");
	wait(100);
	run("Divide...", "value=2 stack");
	run("Subtract...", "value=1 stack");
	selectWindow(mask);
	//run("Enhance Contrast", "saturated=0.35");
	setForegroundColor(255, 255, 255);
	color=getValue("foreground.color");
	setColor(color);
	color=color-1;
	selectWindow(mask);
	resize();
	getLocationAndSize(x, y, width, height);
	setLocation(0,0);
	setThreshold(color, 255);
	if(isOpen(mask)){
		selectWindow(mask);
		wait(100);
		setBatchMode("show");
	};
	resize();
	set_Tool("Pencil Tool");
	waitForUser("Please manually classify pixels by using the Pencil Tool in the "+mask+".\nThis is information is used to classify "+name+" pixels.\nThen press OK.");
	setLocation(x,y);
	batchmode=is("Batch Mode");
	if(!batchmode){
		setBatchMode(true);
	};
	selectWindow(mask);
	wait(100);
	setBatchMode("hide");
	if(isOpen(channel)){
		selectWindow(channel);
		setBatchMode("hide");
	};
	selectWindow(mask);
	wait(100);
	color=getValue("foreground.color");
	color=color-1;
	setThreshold(color, 255);
	run("Convert to Mask", "method=Default background=Dark black");
	setMinAndMax(0, 255);
	wait(100);
	setBatchMode("exit and display");
	return mask;
};