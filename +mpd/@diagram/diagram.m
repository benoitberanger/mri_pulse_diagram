classdef diagram < handle
    
    properties( SetAccess = public )
        
        color_rf      = 'red'
        color_grad_ss = 'blue'
        color_grad_pe = 'magenta'
        color_grad_ro = 'blue'
        color_adc     = 'green'
        
        n_lob_sinc    = 2 % very approximatif
        n_points      = 100
        n_pe_line     = 5
        
    end % properties
    
    properties( SetAccess = protected )
        
        element_array = {}
        
        fig
        ax
        
        channel_type  = {'RF', 'G_SS', 'G_PE', 'G_RO', 'ADC'}
        
    end % properties
    
    methods
        
        function add_element(self, element_array)
            for i = 1 : numel(element_array)
                self.element_array{end+1} = element_array{i};
                element_array{i}.diagram = self; % copy a pointer
            end
        end % function
        
        function Draw( self )
            
            % checks
            for el = 1 : length(self.element_array)
                assert(~isempty(self.element_array{el}.name    ), 'Element #%d have no name, please set it.', el)
                assert(~isempty(self.element_array{el}.onset   ), '%s.onset empty'   , self.element_array{el}.name)
                assert(~isempty(self.element_array{el}.middle  ), '%s.middle empty'  , self.element_array{el}.name)
                assert(~isempty(self.element_array{el}.offset  ), '%s.offset empty'  , self.element_array{el}.name)
                assert(~isempty(self.element_array{el}.duration), '%s.duration empty', self.element_array{el}.name)
            end
            
            % get first and last timepoint
            t_min = 0;
            t_max = 0;
            for el = 1 : length(self.element_array)
                t_min = min(t_min, self.element_array{el}.onset );
                t_max = max(t_max, self.element_array{el}.offset);
            end
            
            % open fig
            self.fig = figure();
            self.fig.Color = [1 1 1]; % white background
            
            nChan = length(self.channel_type);
            y_space = 1/nChan;
            
            % set axes, from bottom to top
            for a = nChan : -1 : 1
                
                % create axes, the place holder hor each curve type == channel
                ax(a) = axes(self.fig); %#ok<LAXES>
                hold(ax(a), 'on')
                
                ax(a).OuterPosition = [0.00 (nChan-a)*y_space+0.00 1.00 y_space*1.00];
                ax(a).InnerPosition = [0.05 (nChan-a)*y_space+0.01 0.95 y_space*0.90];
                
                X = [t_min t_max];
                Y = [0     0    ];
                
                % seperate objects & plot curves
                switch self.channel_type{a}
                    
                    
                    case 'RF' %--------------------------------------------
                        
                        is_obj = cellfun(@(x) isa(x,'mpd.rf_pulse'), self.element_array);
                        where_obj = find(is_obj);
                        
                        for i = 1 : numel(where_obj)
                            obj = self.element_array{where_obj(i)};
                            t = linspace(obj.onset, obj.offset, self.n_points);
                            y = sinc( 2*pi*(self.n_lob_sinc)*(-self.n_points/2 : +self.n_points/2-1)/self.n_points );
                            plot( ax(a), ...
                                t, ...
                                y*obj.magnitude,...
                                'Color',self.color_rf)
                        end
                        
                    case 'G_SS' %------------------------------------------
                        
                        is_obj = cellfun(@(x) isa(x,'mpd.gradient'), self.element_array);
                        where_obj = find(is_obj);
                        where_obj = where_obj( cellfun(@(x) strcmp(x.type, mpd.grad_type.slice_selection), self.element_array(where_obj)) );
                        
                        for i = 1 : numel(where_obj)
                            obj = self.element_array{where_obj(i)};
                            plot( ax(a), ...
                                [obj.onset  obj.onset+obj.dur_ramp_up  obj.onset+obj.dur_ramp_up+obj.dur_flattop  obj.offset] , ...
                                [0          obj.magnitude              obj.magnitude                              0          ], ...
                                'Color',self.color_grad_ss)
                        end
                        
                    case 'G_PE' %------------------------------------------
                        
                        is_obj = cellfun(@(x) isa(x,'mpd.gradient'), self.element_array);
                        where_obj = find(is_obj);
                        where_obj = where_obj( cellfun(@(x) strcmp(x.type, mpd.grad_type.phase_encoding), self.element_array(where_obj)) );
                        
                        for i = 1 : numel(where_obj)
                            obj = self.element_array{where_obj(i)};
                            for line = -self.n_pe_line : self.n_pe_line
                                plot( ax(a), ...
                                    [obj.onset  obj.onset+obj.dur_ramp_up  obj.onset+obj.dur_ramp_up+obj.dur_flattop  obj.offset]                         , ...
                                    [0          obj.magnitude              obj.magnitude                              0          ] * (line/self.n_pe_line), ...
                                    'Color',self.color_grad_pe)
                            end
                        end
                        
                        
                    case 'G_RO' %------------------------------------------
                        
                        is_obj = cellfun(@(x) isa(x,'mpd.gradient'), self.element_array);
                        where_obj = find(is_obj);
                        where_obj = where_obj( cellfun(@(x) strcmp(x.type, mpd.grad_type.readout       ), self.element_array(where_obj)) );
                        
                        for i = 1 : numel(where_obj)
                            obj = self.element_array{where_obj(i)};
                            plot( ax(a), ...
                                [obj.onset  obj.onset+obj.dur_ramp_up  obj.onset+obj.dur_ramp_up+obj.dur_flattop  obj.offset] , ...
                                [0          obj.magnitude              obj.magnitude                              0          ], ...
                                'Color',self.color_grad_ro)
                        end
                        
                    case 'ADC'
                        
                        is_obj = cellfun(@(x) isa(x,'mpd.adc')     , self.element_array);
                        where_obj = find(is_obj);
                        
                        for i = 1 : numel(where_obj)
                            obj = self.element_array{where_obj(i)};
                            plot( ax(a), ...
                                [obj.onset obj.onset     obj.offset     obj.offset], ...
                                [0         obj.magnitude obj.magnitude  0         ], ...
                                'Color',self.color_adc)
                        end
                        
                end % switch
                
                plot(ax(a), [t_min t_max], [0 0], 'Color', 'black', 'Linewidth', 0.5, 'LineStyle', ':')
                
                % make visal ajusments so each axes looks cleaner
                ax(a).YLabel.Interpreter = 'none';
                ax(a).YLabel.String      = self.channel_type{a};
                ax(a).XAxis.Color        = ax(a).Parent.Color;
                ax(a).YAxis.Color        = ax(a).Parent.Color;
                ax(a).YLabel.Color       = [0 0 0];
                ax(a).YLim               = [-1 +1];
                
            end % for
            
            linkaxes(ax,'x')
            self.ax = ax; %#ok<*PROP>
            
        end % function
        
    end % methods
    
end % classdef
