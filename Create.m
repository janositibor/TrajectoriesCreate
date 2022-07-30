clear;
clc;
close all;

Shutter_framenumber=100;
Mean=0;

numoftrajectories=1000;
numofframes=10;
D_expected=0.05;
pixel=0.16; %.16 microm
frametime=34; %34ms
MotionBlur='YES';
Measurement_Error=100; %gaussian measurement error=100nm

file = matlab.desktop.editor.getActiveFilename;
[MainDir,name,ext] = fileparts(file);
ParametersNameandPath=strcat(MainDir,'/params.mat');
if exist(ParametersNameandPath, 'file')==2
	load(ParametersNameandPath);
end

prompt = {'Number of trajectories:','Length of trajectories:','Diffusion coefficient (um2/s):','Localization error (nm)','Pixel size (um):','Frame length (ms):'};
dlgtitle = 'Input parameters';
dims = [1 35];
definput = {num2str(numoftrajectories),num2str(numofframes),num2str(D_expected),num2str(Measurement_Error),num2str(pixel),num2str(frametime)};

disp('Please, define parameters for 2D trajectory creation!');
answer = inputdlg(prompt,dlgtitle,dims,definput);
	
LinesToSkip=str2num(answer{1});
delimiterIn=answer{2};
RAW_data_extension=answer{3};

numoftrajectories=str2num(answer{1});
numofframes=str2num(answer{2});
D_expected=str2num(answer{3});
Measurement_Error=str2num(answer{4});
pixel=str2num(answer{5}); %.16 microm
frametime=str2num(answer{6})/1000; %34ms


Sigma=(sqrt(2*D_expected*frametime))/pixel;
Sigma_shutter=(sqrt(2*D_expected*frametime/Shutter_framenumber))/pixel;

Error_Sigma=(Measurement_Error/1000)/pixel; 

OldMotionBlur=MotionBlur;
MotionBlur = questdlg('Is there motion blur?', 'Choose type of exposure!','YES','NO',OldMotionBlur);
if strcmp(MotionBlur,'YES')
	disp('There will be motion blur!');
	dirac=0;
else
	disp('It will be idealistic!');
	dirac=1;
end

for h=1:numoftrajectories
	n=1:numofframes;
	x_error = normrnd(Mean,Error_Sigma,1,numofframes);
	y_error = normrnd(Mean,Error_Sigma,1,numofframes);
		
	if(dirac>0)
		mbFlag='Dirac';
		dx = normrnd(Mean,Sigma,1,numofframes);
		dy = normrnd(Mean,Sigma,1,numofframes);
		
		x_withouterror=cumsum(dx);
		y_withouterror=cumsum(dy);
	else
		mbFlag='MotionBlur';
		m1=normrnd(Mean,Sigma_shutter,Shutter_framenumber,numofframes);
		m2=normrnd(Mean,Sigma_shutter,Shutter_framenumber,numofframes);
		
		m1_cumsum=cumsum(m1);
		m2_cumsum=cumsum(m2);
		
		x_real=cumsum(m1_cumsum(Shutter_framenumber,:));
		y_real=cumsum(m2_cumsum(Shutter_framenumber,:));
		
		x_offset=[0 x_real(1:end-1)];
		y_offset=[0 y_real(1:end-1)];
		
		dx=mean(m1_cumsum,1);
		dy=mean(m2_cumsum,1);
		
		
		x_withouterror=x_offset+dx;
		y_withouterror=y_offset+dy;
	end
	
	x=x_withouterror+x_error;
	y=y_withouterror+y_error;
	Output=[n;x;y];
	Filename=strcat(MainDir,'/data/Traj_N=',num2str(numofframes),'_D=',num2str(D_expected),'_Error=',num2str(Measurement_Error),'_',mbFlag,'_No.',num2str(h-1,'%.3d'),'.dat');
							
	fid = fopen(Filename,'w');
		%fprintf(fid,'No.\tx\ty\n');
		fprintf(fid,'%.4d %.3f %.3f\n',Output);
	fclose(fid);
end
frametime=1000*frametime;
save(strcat(MainDir,'/params.mat'),'numoftrajectories','numofframes','D_expected','Measurement_Error','pixel','frametime','MotionBlur');