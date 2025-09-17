function xwave_view
    % EXTREMEEVENTVISUALIZERAPP
    % Aplikasi GUI untuk memvisualisasikan data kejadian ekstrem dari file .mat

    % Buat jendela aplikasi
    fig = uifigure('Name', 'Extreme Event Visualizer', 'Position', [100 100 600 300]);

    % Input folder data
    uilabel(fig, 'Text', 'Data Folder:', 'Position', [20 250 100 22]);
    dataFolderField = uieditfield(fig, 'text', 'Position', [120 250 300 22]);
    browseButton = uibutton(fig, 'Text', 'Browse...', 'Position', [430 250 100 22], ...
        'ButtonPushedFcn', @(btn,event) selectFolder());

    % Dropdown tipe data
    uilabel(fig, 'Text', 'Select Data Type:', 'Position', [20 200 120 22]);
    dataTypeDropdown = uidropdown(fig, ...
        'Items', {'ave_intens', 'max_intens', 'duration', 'events'}, ...
        'Position', [150 200 200 22]);

    % Tombol plot
    plotButton = uibutton(fig, 'Text', 'Plot Data', 'Position', [230 140 100 30], ...
        'ButtonPushedFcn', @(btn,event) plotSelectedData());

    % Fungsi memilih folder
    function selectFolder()
        folderName = uigetdir;
        if folderName ~= 0
            dataFolderField.Value = folderName;
        end
    end

    % Fungsi plotting data
       function plotSelectedData()
        dataFolder = dataFolderField.Value;
        selectedDataType = dataTypeDropdown.Value;

        if isempty(dataFolder)
            uialert(fig, 'Please select a data folder.', 'Missing Input');
            return;
        end

        % Nama file berdasarkan dropdown
        filename = fullfile(dataFolder, [selectedDataType '_all.mat']);
        if ~isfile(filename)
            uialert(fig, ['File not found: ' filename], 'File Error');
            return;
        end

        % Load file .mat
        dataStruct = load(filename);
        fieldName = fieldnames(dataStruct);
        rawData = dataStruct.(fieldName{1});

        % Ekstrak lat, lon, value tergantung tipe
        if istable(rawData)
            lat = rawData{:,1};
            lon = rawData{:,2};
            values = rawData{:,3};
        else
            lat = rawData(:,1);
            lon = rawData(:,2);
            values = rawData(:,3);
        end

        % Gridding
        [LON, LAT, griddedData] = xyz2grid(lon, lat, values);

        % Plot
        figure(1); clf
        imagescn(LON, LAT, griddedData);
        colormap(jet(15));
        cb = colorbar;

        % Set colorbar title dan caxis sesuai tipe data
        switch selectedDataType
            case {'ave_intens', 'max_intens'}
                cb.Title.String = "(m)";
                caxis([0 1.5]);
            case 'duration'
                cb.Title.String = "(hour)";
                caxis([0 50]);
            case 'events'
                cb.Title.String = "(events/yr)";
                caxis([0 8]);
        end

        % Tambahkan daratan sebagai fill dari shapefile
        if isfile('landareas.shp')
            land = shaperead('landareas.shp', 'UseGeoCoords', true);
            hold on
            for k = 1:length(land)
                fill(land(k).Lon, land(k).Lat, [0 0 0], 'EdgeColor', 'none');
            end
            hold off
        end

        % Gaya
        xlabel('longitude(^o)');
        ylabel('latitude(^o)');
        set(gca, 'fontsize', 14, 'FontWeight', 'bold', 'linewidth', 2);
        set(gcf, 'Position', [1440 818 651 420]);

        % Simpan hasil
        exportFile = fullfile(dataFolder, ['visual_' selectedDataType '.png']);
        exportgraphics(gcf, exportFile, 'Resolution', 300);
        uialert(fig, ['Visualization saved to: ' exportFile], 'Done');
       end
end
