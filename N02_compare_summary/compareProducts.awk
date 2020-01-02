/^os /{os[$2]=$4}
/^ns /{ns[$2]=$4}



END{
    absMin=ENVIRON["absMin"];
    dptMin=ENVIRON["dptMin"];
    oTotal= 0;
    for (br in os){
    osi=os[br];
    ms[br]+=osi*0.5;
    oTotal+=osi;
    }
    nTotal=0;
    for (br in ns){
    nsi=ns[br];
    ms[br]+=nsi*0.5;
    nTotal+=nsi;
    }
    dsTotal=0;
    dsTTotal=0;
    print  "-------------------------------------------------------------";
    print  " or, B       new, B      delta, B   delta, %   deltaJ, %    branch "
    print  "-------------------------------------------------------------";
	
	for(br in ms){
    osi=os[br]; nsi=ns[br];
    dsi=nsi-osi;
    adsi = dsi; if(adsi<0)adsi=-adsi;
    msi=ms[br];
    if (dsi==0 && msi==0){
        dsiR=0;
    } else {
        dsiR=dsi/msi*100;
    }
    dsiT=dsi/oTotal*100;
    dsTotal+=dsi;
    dsTTotal+=dsiT;
 
	adsiR=dsiR; if (adsiR<0)adsiR = -adsiR;
    if (dsiR==200) isNew=1; else isNew=0;
    if (dsiR==-200) isGone=1; else isGone=0;
	
	
##------Step4 output ( one condition )
#	if (isNew!=1&&isGone!=1){
#		printf("%9.0f ->   %9.0f  % 9.0f    % 5.1f  % 4.2f     %s\n", osi, nsi, dsi, dsiR, dsiT, br);
#	} # Step4 condition loop	


##------Step3 output ( two conditions )
	if (adsiR>dptMin||adsi>absMin){
		if (isNew!=1&&isGone!=1){
		printf("%9.0f ->   %9.0f  % 9.0f    % 5.1f  % 4.2f     %s\n", osi, nsi, dsi, dsiR, dsiT, br);
		} else if (isNew==1){
		printf("%9.0f ->   %9.0f  % 9.0f     NEWO  % 4.2f     %s\n", osi, nsi, dsi, dsiT, br);
		} else if (isGone==1){
		printf("%9.0f ->   %9.0f  % 9.0f     OLDO  % 4.2f     %s\n", osi, nsi, dsi, dsiT, br);
		}
	}# Step3 condition loop 
    

	}# for loop
	

    print  "-------------------------------------------------------------";
    printf("%9.0f ->   %9.0f  % 9.0f           % 5.1f     ALL BRANCHES\n", oTotal, nTotal, dsTotal, dsTTotal );
} # End loop
