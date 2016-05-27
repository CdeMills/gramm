%# GRAMM Implementation of the features from R's ggplot2 (GRAMmar of graphics plots) in Matlab
%#  Pierre Morel 2015 Matlab code
%#  Pascal Dupuis <cdemills@gmail.com> 2016 Octave port

function gramm=gramm(x, varargin)
  %%  gramm Constructor for the class
  %% 
  %%  Example syntax (default arguments): gramm_object=gramm('x',x_variable,'y',y_variable,'color',color_variable)
  %%  This function is used to create a gramm object, and provide
  %%  it with the data that will be plotted. Arguments are given as
  %%  'name',value pairs. The possible arguments are:
  %% 
  %%    - 'x' for the data to plot as abcissa, or the data that
  %%       will be used to construct histograms/density estimates
  %%    - 'y' for the data to plot as ordinate
  %%    - 'color' for the data that determines color (hue)
  %%    - 'lightness' for the data that determines lightness
  %%    - 'linestyle' for the data that determines line style
  %%    - 'size' for the data that determines line/point size
  %%    - 'marker' for the data that determines point shape
  %%    - 'group' for the data that determines groups
  %% 
  %%  The arguments can be of the following type, N being te number
  %%  of observations:
  %%    - color, lightness, linestyle, size or marker can be 1D numerical arrays
  %%      or 1D cell arrays of strings of length N. Note that they are used to
  %%      represent categories.
  %%    - y can be a 1D numerical array of length N. It can also be
  %%      a 2D numerical array of size N*M, or a 1D cell array of
  %%      length N containing arrays of various sizes. In the last
  %%      two cases, all the points from each row of the array/each
  %%      array from the cell will be colored/shaped/etc similarly
  %%      and according to the other aesthetics.
  %%    - x can be a 1D numerical array or a 1D cell array of
  %%      strings of size N (if y is a 1D numerical array). If y is
  %%      a 1D cell array of numerical arrays or a 2D numerical
  %%      array, x can be either a 1D cell array containing
  %%      numerical arrays of the same size, or a 2D numerical
  %%      array of the same size (N*M). It can also be a 1D numerical
  %%      array of size M, in which case the same abcissa will be
  %%      used for every row of y.
  
  if (0 == nargin)
     %# default constructor: create a scalar struct and initialise the
     %# fields in the right order
    gramm = struct ('facet_axes_handles', []);
    gramm.results = []; 
    gramm.aes = [];
    gramm.aes_names =  struct ('x', 'x', ...
                               'y', 'y', ...
                               'z', 'z', ...
                               'color', 'Color', ...
                               'marker', 'Marker', ...
                               'linestyle', 'Line Style', ...
                               'size', 'Size', ...
                               'row', 'Row', ...
                               'column', 'Column', ...
                               'lightness', 'Lightness', ...
                               'group', 'Group');
    gramm.axe_properties = {}; %# Contains the axes properties to be set to each subplot
    gramm.geom =  {};   %# Cell containing successive plotting function handles
    gramm.var_lim =  []; %# Contains the min and max values of variables (minx,maxx,miny,maxy)
  %# Contains the min and max values of variables in sub plots
  %# (minx,maxx,miny,maxy,minc,maxc), c being for the continuous color
  %# values. Each of these is a matrix
  %# corresponding to the facets, used to set axis limits
    gramm.plot_lim = [];
    gramm.xlim_extra =  0.1; %# extend range of XLim (ratio of original XLim width)
    gramm.ylim_extra =  0.1; %# extend range of XLim (ratio of original YLim width)
    gramm.zlim_extra =  0.1;
     %# Structure containing polar-related parameters: is_polar stores
     %# whether to display polar plots, is_polar_closed to  set if the
     %# polar lines must close around the circle, and max_polar_y to
     %# define the limits in radius.
    gramm.polar =  struct ('is_polar', false, ...
                           'is_polar_closed', false);
    gramm.x_factor =  []; %# Is X a categorical variable ?
    gramm.x_ticks =  []; %# Store the ticks used for x
%# store variables used when making multiple gramm plots in the same window:
    gramm.multi =  struct ('orig', [0 0], ...   %# origin (x,y) of the current gramm plot in normalized
                           'size', [1 1], ...   %# size (w,h) of the current gramm plot in normalized values
                           'active', false);
                        %# Stores variables relative to gramm updating
    gramm.updater =  struct ('facet_updated', 0, ...
                             'updated', false, ...
                             'first_draw', true);
    gramm.firstrun = []; %# Is it the first time the plotting function is run
    gramm.result_ind = []; %# current index in the draw loops
    gramm.wrap_ncols = -1; %# After how many columns do we wrap around subplots
    gramm.facet_scale = 'fixed'; %# Do we have independent scales between facets ?
    gramm.facet_space = 'fixed'; %# Do scale axes between facets ?
    gramm.force_ticks = false; %# Do we force ticks on all facets
                         %# structure containing the abline parameters
    gramm.abline =  struct ( 'on', 0, ...
                             'slope', [], ...
                             'intercept', [], ...
                             'xintercept', [], ...
                             'yintercept', [], ...
                             'style', [], ...
                             'fun',[]);
    gramm.datetick_params =  {}; %# cell containng datetick parameters
    gramm.current_row = []; %# What is the currently drawn row of the subplot
    gramm.current_column =  []; %# What is the currently drawn column of the subplot
    gramm.continuous_color = false;  %# Do we use continuous colors (rather than discrete)
                                %# Store the continuous color colormap
    gramm.continuous_color_colormap =  ...
    pa_LCH2RGB ([linspace(0,100,256)'...
                 repmat(100,256,1)...
                       linspace(30,90,256)']);
                                %# Store options for generating colors
    gramm.color_options = ...
    struct ('lightness_range', [85 15],...
            'chroma_range', [30 90],...
            'hue_range', [25 385],...
            'lightness', 65,...
            'chroma', 75,...
            'map','lch');
                          %# Store options for sorting data/categories
    gramm.order_options =  struct ('x', 1, ...
                                   'color', 1, ...
                                   'marker', 1, ...
                                   'linestyle', 1, ...
                                   'size', 1, ...
                                   'row', 1, ...
                                   'column', 1, ...
                                   'lightness', 1);
    gramm.with_legend =  true; %# Do we have a side legend for colors etc. ?
    gramm.legend_y =  0; %# Current y position of the legend text
    gramm.legend_axe_handle =  []; %# Store the handle of the legend axis
    gramm.title_axe_handle =  [];  %# Store the handle of the title axis
    gramm.bigtitle =  '';
    gramm.bigtitle_options =  '';
    gramm.title =  ''; 
    gramm.title_options =  {};         
    gramm.legend_text_handles = []; %# Stores handles of text objects for legend
    gramm.facet_text_handles = []; %# Stores handles of text objects for facet row and column titles
    gramm.title_text_handle = []; %# Stores handle of title text object
    gramm.redraw_cache =  []; %# Cache store for faster redraw() calls
    gramm.parent =  []; 
    gramm.handle_graphics =  [];
    gramm.extra = []; %# Store extra geom-specific info
    gramm = class (gramm, 'gramm');
    return
  end

  if (~isa (x, 'gramm'))
    arglist = {x, varargin{:}};
    gramm = gramm();
  else      
    gramm = x;
    arglist = {varagin{:}};
  end
  gramm.aes = parse_aes (arglist{:}); 
  gramm.handle_graphics = false;
    
end





















