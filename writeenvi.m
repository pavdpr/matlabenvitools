function writeenvi( A, fname, hdr, hdrfname )
% WRITEENVI writes an ENVI image file
%
% DESCRIPTION:
%   Writes an ENVI image file to disk
%
% SYNTAX:
%   writeenvi(A, filename)
%   writeenvi(A, filename, header)
%   writeenvi(A, filename, header, headerfilename)
%
% INPUTS:
%   A: The image ( col x line x band ) Matlab array
%   fname: a string containing the file to write to including any paths and
%       extensions.
%   hdr: A structure containing the header information. If one is not
%       provided, the function makeBasicEnviHeader will be called to make one.
%   fname: a string containing the header filename to write to including any 
%       paths and extensions.
%
% NOTES:
%   - When providing a header, the image will be converted to the data type
%     specified.
%   - Complex data is not properly handled.
%   - It has been reported that the images generated with this function are
%     not readable with the new ENVI. The images were openable with ENVI
%     classic.
% 
% REQUIRED FUNCTIONS:
%   makeBasicEnviHeader.m
%
% LICENSE:
%   The MIT License (MIT)
%
%   Copyright (c) 2013-2015 Rochester Institute of Technology
%
%   Permission is hereby granted, free of charge, to any person obtaining a
%   copy of this software and associated documentation files (the 
%   "Software"), to deal in the Software without restriction, including 
%   without limitation the rights to use, copy, modify, merge, publish, 
%   distribute, sublicense, and/or sell copies of the Software, and to 
%   permit persons to whom the Software is furnished to do so, subject to
%   the following conditions:
%
%   The above copyright notice and this permission notice shall be included
%   in all copies or substantial portions of the Software.
%
%   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
%   OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
%   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
%   IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY 
%   CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
%   TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
%   SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
%
% AUTHOR(S):
%   Paul Romanczyk (par4249 at rit dot edu)
%
% PUBLIC REPOSITORY:
%   http://github.com/pavdpr/matlabenvitools
%
% TODO:
%   - Fix the writing of complex data.
%   - Parse coordinate system string.
%   - Look into why these images are not openable in the new ENVI.
%
% HISTORY:
%   2013-MM-DD:
%       - Initial version.
%   2015-01-24: Formatting update.
%       - Changed tabs to whitespace.
%   2016-03-28: Bug fixes.
%       - Fixed a bug where an error was thrown if an image cube was passed.
%       - Added error checking.
%       - Updated documentation.
%
% REFERENCES:
%   http://www.exelisvis.com/docs/ENVIHeaderFiles.html
%


    if ~ischar( fname )
        error( 'writeenvi:invalidInput', 'fname should be a char string' );
    end
    if nargin < 2
        error( 'writeenvi:invalidInput', 'writeenvi should have at least 2 inputs' );
    end
    if nargin < 3
        hdr = makeBasicEnviHeader( A );
    end
    if nargin < 4
        hdrfname = strcat( fname, '.hdr' );
    end

    s = size( A );
    if ~( ( ismatrix( A ) ) || ( ndims( A ) == 3 ) )
        error( 'writeenvi:invalidA', 'A should have 2 or 3 dimensions' );
    end

    % check for required fields of header
    if ~isfield( hdr, 'bands' )
        switch numel( s )
            case 2
                hdr.bands = 1;
            case 3
                hdr.bands = s( 3 );
        end
    elseif hdr.bands ~= numel( s )
        error('writeenvi:bandMismatch', ...
            'Mismatch between the number of bands in the header and the image.');
    end
    if ~isfield( hdr, 'lines' )
        hdr.lines = s( 2 );
    elseif hdr.lines ~= s( 2 )
        error('writeenvi:lineMismatch', ...
            'Mismatch between the number of lines in the header and the image.');
    end
    if ~isfield( hdr, 'samples' )
        hdr.samples = s( 1 );
    elseif hdr.samples ~= s( 1 )
        error('writeenvi:samplesMismatch', ...
            'Mismatch between the number of samples in the header and the image.');
    end
    if ~isfield( hdr, 'dataType' )
        hdr.dataType = enviGetDataType( A );
    end
    if ~isfield( hdr, 'headerOffset' )
        hdr.headerOffset = 0;
    end
    if ~isfield( hdr, 'interleave' )
        hdr.interleave = 'bsq';
    end
    if ~isfield( hdr, 'byteOrder' )
        hdr.byteOrder = 'ieee-le';
    end

    % write the header
    fid = fopen( hdrfname, 'w' );
    if fid == -1 
        error( 'writeenvi:invalidHeaderFilename', ...
            [ '"' hdrfname '" is not a valid header file' ] );
    end

    fprintf( fid, 'ENVI\n' );
    fields = fieldnames( hdr );
    for i = 1:numel( fields );
        switch fields{ i }
            
            case 'bandNames'
                writeCommaSeparatedString( fid, 'band names', hdr.bandNames );
                
            case 'bands'
                fprintf( fid, 'bands = %d\n', hdr.bands );
                
            case 'bbl'
                writeCommaSeparatedInt( fid, 'bbl', hdr.bbl );
                
            case 'byteOrder'
                if strcmp( hdr.byteOrder, 'ieee-be' )
                    fprintf( fid, 'byte order = 1\n' );
                elseif strcmp( hdr.byteOrder, 'ieee-le' )
                    fprintf( fid, 'byte order = 0\n' );
                else
                    error('writeenvi:invalidByteOrder', ...
                        'Invalid Byte Order');
                end
                
            case 'coordinateSystemString'
                fprintf( fid, 'coordinate system string = {%s}\n', ...
                    hdr.coordinateSystemString );
                
            case 'dataType'
                fprintf( fid, 'data type = %d\n', hdr.dataType );
                
            case 'dataTypeName'
                % extra info added by me, nothing to do!
                
            case 'demBand'
                fprintf( fid, 'dem band = %d\n', hdr.demBand );
                
            case 'demFile'
                fprintf( fid, 'dem file = {%s}\n', hdr.demFile );
                
            case 'description'
                fprintf( fid, 'description = {%s}\n', hdr.description );
                
            case 'fileType'
                fprintf( fid, 'file type = %s\n', hdr.fileType );
                
            case 'geoPoints'
                writeCommaSeparatedDouble( fid, 'geo points', hdr.geoPoints );
                
            case 'headerOffset' 
                fprintf( fid, 'header offset = %d\n', hdr.headerOffset );
                
            case 'interleave'  
                fprintf( fid, 'interleave = %s\n', hdr.interleave );
                
            case 'isComplex'
                % extra info added by me, nothing to do!
                
            case 'lines'     
                fprintf( fid, 'lines = %d\n', hdr.lines );
                
            case 'mapInfo'
                fprintf( fid, 'map info = {%s,%f,%f,%f,%f,%f,%f', ...
                    hdr.mapInfo.projectionName, ...
                    hdr.mapInfo.xReferencePixelLocation, ...
                    hdr.mapInfo.yReferencePixelLocation, ...
                    hdr.mapInfo.pixelEasting, ...
                    hdr.mapInfo.pixelNorthing, ...
                    hdr.mapInfo.xPixelSize, ...
                    hdr.mapInfo.yPixelSize );
                switch hdr.mapInfo.projectionName
                    case 'UTM'
                        fprintf( fid, ',%d,%s,%s,%s', ...
                            hdr.mapInfo.projectionZone, ...
                            hdr.mapInfo.northSouth, ...
                            hdr.mapInfo.datum, ...
                            [ 'units=' hdr.mapInfo.units ] );
                    case 'By WKT String'
                        %nothing to do!
                    otherwise
                        fprintf( fid, ',%s,%s', ...
                            hdr.mapInfo.datum, ...
                            hdr.mapInfo.units );
                end
                fprintf( fid, '}\n' );
            
            case 'other'
                for j = 1:numel( hdr.other )
                    fprintf( fid, '%s = {%s}\n', ...
                        hdr.other( j ).key, hdr.other( j ).value );
                end
                
            case 'samples'
                fprintf( fid, 'samples = %d\n', hdr.samples );
                       
            case 'sensorType'
                fprintf( fid, 'sensor type = {%s}\n', hdr.sensorType );

            case 'wavelength'
                writeCommaSeparatedString( fid, 'wavelength', hdr.wavelength );
                
            case 'wavelengthUnits'
                writeCommaSeparatedString( fid, 'wavelength units', ...
                    hdr.wavelengthUnits );
                
            case 'xStart'
                fprintf( fid, 'x start = %f\n', hdr.xStart );
                
            case 'yStart'
                fprintf( fid, 'y start = %f\n', hdr.yStart );
                
            otherwise
                % I don't quite know how to handle this, but will give it at
                % try
                switch class( hdr.(fields{ i }) )
                    case 'char'
                        fprintf( fid, '%s = {%s}', fields{i}, hdr.( fields{ i } ) );
                    otherwise
                        warning( [ 'I do not know how handle a field in ' ...
                            'the header' ] );
                end
        end
    end
    fclose( fid );

    % make sure A is the right data type
    switch hdr.dataType
        case 1
            A = int8( A );
        case 2
            A = int16( A );
        case 3
            A = int32( A );
        case 4
            A = single( A );
        case 5
            A = double( A );
        case 6
            % single precision complex
            %A = single( A );
            error('writeenvi:complex', ...
                        'Writing complex data is not currently supported');
        case 9
            % double precision complex
            %A = double( A );
            error('writeenvi:complex', ...
                        'Writing complex data is not currently supported');
        case 12
            A = uint16( A );
        case 13
            A = uint32( A );
        case 14 
            A = int64( A );
        case 15
            A = uint64( A );
        otherwise:
            error('writeenvi:invalidDataType', ...
                        'Invalid Data Type');
    end

    % write the envi file
    multibandwrite(A, fname, hdr.interleave, ...
        'precision', convertDataType( hdr.dataType ), ...
        'offset', hdr.headerOffset, ...
        'machfmt', hdr.byteOrder );

end

function writeCommaSeparatedInt( fid, key, v )
    fprintf( fid, '%s = {%d', key, v( 1 ) );
    for i = 2:numel( v )
        fprintf( fid, ',%d', v( i ) );
    end
    fprintf( fid, '}\n' );
end

function writeCommaSeparatedDouble( fid, key, v )
fprintf( fid, '%s = {%f', key, v( 1 ) );
    for i = 2:numel( v )
        fprintf( fid, ',%f', v( i ) );
    end
    fprintf( fid, '}\n' );
end

function writeCommaSeparatedString( fid, key, v )
fprintf( fid, '%s = {%s', key, v{ 1 } );
    for i = 2:numel( v )
        fprintf( fid, ',%s', v{ i } );
    end
    fprintf( fid, '}\n' );
end

function [ dataType, iscplx ] = enviGetDataType( A )
    iscplx = false;
    switch class( A )
        case 'uint8'
            dataType = 1;
        case 'int16'
            dataType = 2;
        case 'int32'
            dataType = 3;
        case 'single'
            if isreal( A )
                dataType = 4;
            else
                dataType = 6;
                iscplx = true;
            end
        case 'float32' % same as single
            if isreal( A )
                dataType = 4;
            else
                dataType = 6;
                iscplx = true;
            end
        case 'double'
            if isreal( A )
                dataType = 5;
            else
                dataType = 9;
                
                iscplx = true;
            end
        case 'float64' % same as double
            if isreal( A )
                dataType = 5;
            else
                dataType = 9;
                
                iscplx = true;
            end
        case 'uint16'
            dataType = 12;
        case 'uint32'
            dataType = 13;
        case 'int64'
            dataType = 14;
        case 'uint64'
            dataType = 15;
        otherwise
            error( 'writeenvi:enviGetDataType:invalidDataType', ...
                [ class( A ) ' is not a valid envi data type' ] );
    end
end

function [ dataTypeName, isComplex ] = convertDataType( dataType )
    isComplex = false;
    switch dataType
        case 1
            dataTypeName = 'uint8';
        case 2
            dataTypeName = 'int16';
        case 3
            dataTypeName = 'int32';
        case 4
            dataTypeName = 'float32';
        case 5
            dataTypeName = 'float64';
        case 6
            dataTypeName = 'float32';
            isComplex = true;
        case 9
            dataTypeName = 'float64';
            isComplex = true;
        case 12
            dataTypeName = 'uint16';
        case 13
            dataTypeName = 'uint32';
        case 14
            dataTypeName = 'int64';
        case 15
            dataTypeName = 'uint64';
        otherwise
             error( 'writeenvi:convertDataType:unknownDataType', ...
                 'Unknown image data type');
    end
end
