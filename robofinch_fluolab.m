function robofinch_fluolab(FILE,PARAMETER_FILE,varargin)

if nargin<2, PARAMETER_FILE=[]; end

save_dir='robofluolab';
colors='jet';
blanking=[.2 .2];
normalize='m';
dff=1;
classify_trials='ttl';
channel=1;
daf_level=.05;
trial_cut=2;
newfs=400;
tau=.1;
detrend_win=.3;
detrend_method='p';
save_file='robofluolab.mat';
ylimits=[.2 .7];
nmads=100;
win_size=20;
win_overlap=19;
padding=[];
param_names=who('-regexp','^[a-z]');

% parameter are all values that begin with lowercase letters

nparams=length(varargin);

if mod(nparams,2)>0
	error('Parameters must be specified as parameter/value pairs');
end



% scan for intan_frontend files, prefix songdet1

for i=1:2:nparams
	switch lower(varargin{i})
		case 'colors'
			colors=varargin{i+1};
		case 'blanking'
			blanking=varargin{i+1};
		case 'normalize'
			normalize=varargin{i+1};
		case 'dff'
			dff=varargin{i+1};
		case 'classify_trials'
			classify_trials=varargin{i+1};
		case 'save_dir'
			save_dir=varargin{i+1};
		case 'channel'
			channel=varargin{i+1};
		case 'daf_level'
			daf_level=varargin{i+1};
		case 'trial_cut'
			trial_cut=varargin{i+1};
		case 'newfs'
			newfs=varargin{i+1};
		case 'tau'
			tau=varargin{i+1};
		case 'detrend_win'
			detrend_win=varargin{i+1};
		case 'ylimits'
			ylimits=varargin{i+1};
		case 'detrend_method'
			detrend_method=varargin{i+1};
		case 'nmads'
			nmads=varargin{i+1};
		case 'win_size'
			win_size=varargin{i+1};
		case 'win_overlap'
			win_overlap=varargin{i+1};
		case 'padding'
			padding=varargin{i+1};
	end
end

% if a parameter file is provided, use new parameter


PARAMETER_FILE

if ~isempty(PARAMETER_FILE)

	for i=1:length(PARAMETER_FILE)

		tmp=robofinch_read_config(PARAMETER_FILE{i});
		new_param_names=fieldnames(tmp);

		for j=1:length(new_param_names)
			if any(strcmp(param_names,new_param_names{j}))

				% map variable to the current workspace

				disp(['Setting parameter ' new_param_names{j} ' to:  ' num2str(tmp.(new_param_names{j}))]);
				feval(@()assignin('caller',new_param_names{j},tmp.(new_param_names{j})));
			end
		end
	end

end


load(FILE,'adc','ttl','audio','file_datenum');
[path,file,ext]=fileparts(FILE);

if isempty(ttl.data) | ~isfield(ttl,'data')
	classify_trials='s';
	ttl=[];
end

[raw,regress,trials]=fluolab_fb_proc(adc,audio,ttl,'blanking',blanking,'normalize',normalize,'dff',dff,'classify_trials',classify_trials,...
	'channel',channel,'daf_level',daf_level,'trial_cut',trial_cut,'newfs',newfs,'tau',tau,'detrend_win',detrend_win,'detrend_method',detrend_method,...
	'nmads',nmads,'padding',padding);

if isempty(raw)
	warning('Fluo analysis could not complete, skipping plotting...');
	return;
end

if isempty(trials.fluo_include.all)
	warning('Found no trials skipping...');
	return;
end

%tmp=ttl;
%tmp.data=tmp.data(:,trials.include);
%raw=fluolab_fb_proc_window(raw,tmp,'blanking',blanking);
%trials.all_class=fluolab_classify_trials(ttl.data,ttl.fs);

fignums=fluolab_fb_plots(audio,raw,ttl,trials,'visible','off','blanking',blanking,'colors',colors,...
	'ylimits',ylimits,'datenums',file_datenum,'win_size',win_size,'win_overlap',win_overlap); %
fig_names=fieldnames(fignums);

for i=1:length(fig_names)

	% save figs

	if ~isempty(save_dir) & ~exist(fullfile(path,save_dir),'dir')
		mkdir(fullfile(path,save_dir))
	end

	markolab_multi_fig_save(fignums.(fig_names{i}),fullfile(path,save_dir),fig_names{i},'eps,png,fig');
	close([fignums.(fig_names{i})]);

end

save(fullfile(path,save_dir,save_file),'raw','regress','trials');

