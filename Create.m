clear;
clc;
close all;

Shutter_lepesszam=100;
Mean=0;

hanytrajektoria=1;
lepesszam=50;
D_vart=0.15;
pixel=0.16; %.16 microm
frametime=0.034; %34ms
MotionBlur='YES';
Meresi_Hiba=100; %gaussian measurement error=100nm

if exist('params.mat', 'file')==2
	load('params.mat');
end
	
prompt = {'Number of trajectories:','Length of trajectories:','Diffusion coefficient (um2/s):','Localization error (nm)','Pixel size (um):','Frame length (ms):'};
dlgtitle = 'Input parameters';
dims = [1 35];
definput = {num2str(hanytrajektoria),num2str(lepesszam),num2str(D_vart),num2str(Meresi_Hiba),num2str(pixel),num2str(frametime)};

disp('Please, define parameters for 2D trajectory creation!');
answer = inputdlg(prompt,dlgtitle,dims,definput);
	
LinesToSkip=str2num(answer{1});
delimiterIn=answer{2};
RAW_data_extension=answer{3};

hanytrajektoria=str2num(answer{1});
lepesszam=str2num(answer{2});
D_vart=str2num(answer{3});
Meresi_Hiba=str2num(answer{4});
pixel=str2num(answer{5}); %.16 microm
frametime=str2num(answer{6}); %34ms

Sigma=(sqrt(2*D_vart*frametime))/pixel;
Sigma_shutter=(sqrt(2*D_vart*frametime/Shutter_lepesszam))/pixel;

Hiba_Sigma=(Meresi_Hiba/1000)/pixel; 

OldMotionBlur=MotionBlur;
MotionBlur = questdlg('Is there motion blur?', 'Choose type of exposure!','YES','NO',OldMotionBlur);
% Handle response
		
if strcmp(MotionBlur,'YES')
	disp('There will be motion blur!');
	dirac=0;
else
	disp('It will be idealistic!');
	dirac=1;
end

for h=1:hanytrajektoria
	n=1:lepesszam;
	x_hiba = normrnd(Mean,Hiba_Sigma,1,lepesszam);
	y_hiba = normrnd(Mean,Hiba_Sigma,1,lepesszam);
		
	if(dirac>0)
		mbFlag='Dirac';
		dx = normrnd(Mean,Sigma,1,lepesszam);
		dy = normrnd(Mean,Sigma,1,lepesszam);
		
		x_hiba_nelkul=cumsum(dx);
		y_hiba_nelkul=cumsum(dy);
	else
		mbFlag='MotionBlur';
		m1=normrnd(Mean,Sigma_shutter,Shutter_lepesszam,lepesszam);
		m2=normrnd(Mean,Sigma_shutter,Shutter_lepesszam,lepesszam);
		
		m1_cumsum=cumsum(m1);
		m2_cumsum=cumsum(m2);
		
		x_valodi=cumsum(m1_cumsum(Shutter_lepesszam,:));
		y_valodi=cumsum(m2_cumsum(Shutter_lepesszam,:));
		
		x_offset=x_valodi(1:end);
		y_offset=y_valodi(1:end);
		
		dx=mean(m1_cumsum,1);
		dy=mean(m2_cumsum,1);
		
		
		x_hiba_nelkul=x_offset+dx;
		y_hiba_nelkul=y_offset+dy;
	end
	
	x=x_hiba_nelkul+x_hiba;
	y=y_hiba_nelkul+y_hiba;
	Output=[n;x;y];
	Filename=strcat('data/Traj_N=',num2str(lepesszam),'_D=',num2str(D_vart),'_Error=',num2str(Meresi_Hiba),'_',mbFlag,'_No.',num2str(h,'%.4d'),'.dat');
							
	fid = fopen(Filename,'w');
		%fprintf(fid,'No.\tx\ty\n');
		fprintf(fid,'%.4d %.3f %.3f\n',Output);
	fclose(fid);
	if mod(h,2500)==0
		close all;
		h2 = figure(2);
		ax2 = axes('Parent', h2);
		plot(ax2, (pixel)*x,(pixel)*y,'blue','linewidth',2 )
		xlabel(ax2, '\it x \rm({\mu}m)');
		ylabel(ax2, '\it y \rm({\mu}m)');
		title(strcat('Two dimensional trajectory, No.',num2str(h,'%.3d')));
		textbox_szoveg = {
			strcat('\rm \sigma=',num2str(Sigma*pixel),'{\mu}m');
			strcat('\it T\rm=',num2str(frametime),'s');
			strcat('\it D\rm=',num2str(D_vart),'{\mu}m^2/s');
			};
		annotation('textbox',[0.2 0.70 0.95 0.2], 'String',textbox_szoveg,'LineStyle','none');
			
		Traj_nev=strcat('Traj_N=',num2str(lepesszam),'_D=',num2str(D_vart),'_Error=',num2str(Meresi_Hiba),'_',mbFlag,' _No.',num2str(h,'%.4d'),'.png');
		saveas(gcf,Traj_nev);
		
		for i=1:lepesszam
			%i=i
			sd2(i)=0;
			for j=1:lepesszam-i
				sd2(i)=sd2(i)+((x(j)-x(j+i))^2+(y(j)-y(j+i))^2);
			end	
			%Szumma=sd2(i);
			%Hanybol=lepesszam+1-i;
			sd2(i)=(sd2(i))/(lepesszam+1-i);
		end	

		f3=figure(3);
		ax3 = axes('Parent', f3);
		plot((pixel^2)*sd2,'blue','linewidth',2 )
		
		xlabel(ax3, 'Distance in steps');
		ylabel(ax3, 'Mean Square Displacement ({\mu}m^2)');
		
		title(strcat('MSD, No.',num2str(h,'%.3d')));
		textbox_szoveg = {
			strcat('\it N\rm=',num2str(lepesszam));
			strcat('\rm \sigma=',num2str(Sigma*pixel),'{\mu}m');
			strcat('\it T\rm=',num2str(frametime),'s');
			strcat('\it D\rm=',num2str(D_vart),'{\mu}m^2/s');
			};
		annotation('textbox',[0.2 0.70 0.95 0.2], 'String',textbox_szoveg,'LineStyle','none');
		
		sd2_nev=strcat('MSD_n=',num2str(lepesszam),'_No.',num2str(h,'%.3d'),'.png');
		saveas(gcf,sd2_nev);
	end
end

save('params.mat','hanytrajektoria','lepesszam','D_vart','Meresi_Hiba','pixel','frametime','MotionBlur');
	